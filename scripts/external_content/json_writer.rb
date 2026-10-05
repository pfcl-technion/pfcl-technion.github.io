# frozen_string_literal: true

require "fileutils"
require "json"
require "tempfile"

module PFCL
  module ExternalContent
    module JsonWriter
      module_function

      def write(path, value)
        write_all(path => value)
        nil
      end

      def write_all(outputs)
        prepared = prepare(outputs)
        originals = prepared.to_h do |path, _temporary|
          [path, File.file?(path) ? File.binread(path) : nil]
        end
        installed = []

        prepared.each do |path, temporary|
          File.rename(temporary.path, path)
          installed << path
        end
        nil
      rescue StandardError
        rollback(installed || [], originals || {})
        raise
      ensure
        (prepared || {}).each_value do |temporary|
          temporary.close! if temporary
        rescue Errno::ENOENT
          nil
        end
      end

      def prepare(outputs)
        prepared = {}
        outputs.sort_by { |path, _value| path.to_s }.each do |raw_path, value|
          path = File.expand_path(raw_path)
          directory = File.dirname(path)
          FileUtils.mkdir_p(directory)
          temporary = nil
          begin
            temporary = Tempfile.new([".#{File.basename(path)}", ".tmp"], directory, binmode: true)
            temporary.write("#{JSON.pretty_generate(canonicalize(value))}\n")
            temporary.flush
            temporary.fsync
            prepared[path] = temporary
          rescue StandardError
            temporary&.close!
            raise
          end
        end
        prepared
      rescue StandardError
        prepared&.each_value(&:close!)
        raise
      end
      private_class_method :prepare

      def canonicalize(value)
        case value
        when Hash
          value.keys.sort_by(&:to_s).to_h { |key| [key, canonicalize(value.fetch(key))] }
        when Array
          value.map { |item| canonicalize(item) }
        else
          value
        end
      end
      private_class_method :canonicalize

      def rollback(installed, originals)
        installed.reverse_each do |path|
          previous = originals.fetch(path)
          if previous.nil?
            FileUtils.rm_f(path)
          else
            restore = Tempfile.new([".#{File.basename(path)}", ".rollback"], File.dirname(path), binmode: true)
            begin
              restore.write(previous)
              restore.flush
              restore.fsync
              File.rename(restore.path, path)
            ensure
              restore.close!
            end
          end
        end
      end
      private_class_method :rollback
    end
  end
end
