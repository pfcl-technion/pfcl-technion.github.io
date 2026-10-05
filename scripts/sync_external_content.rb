#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "optparse"

require_relative "external_content/runner"

module PFCL
  module ExternalContent
    module SyncCLI
      module_function

      def call(argv, stdout: $stdout, stderr: $stderr)
        root = File.expand_path("..", __dir__)
        options = {
          config_path: File.join(root, "_data", "external_sources.yml"),
          output_dir: File.join(root, "_data", "generated"),
          as_of: Time.now.utc.to_date,
          source_roots: {},
          revisions: {}
        }
        parser = option_parser(options)
        parser.parse!(argv)

        result = Runner.call(**options)
        result.warnings.each { |warning| stderr.puts warning }
        stdout.puts "anpl_revision=#{result.revisions.fetch('anpl')} connect_revision=#{result.revisions.fetch('connect')}"
        stdout.puts result.counts.map { |name, count| "#{name}=#{count}" }.join(" ")
        0
      rescue OptionParser::ParseError, Date::Error, ArgumentError, SourceError, SystemCallError => e
        stderr.puts "external content sync failed: #{e.message}"
        1
      end

      def option_parser(options)
        OptionParser.new do |parser|
          parser.banner = "Usage: sync_external_content.rb [options]"
          parser.on("--config PATH") { |value| options[:config_path] = value }
          parser.on("--anpl-root PATH") { |value| options[:source_roots]["anpl"] = value }
          parser.on("--connect-root PATH") { |value| options[:source_roots]["connect"] = value }
          parser.on("--output-dir PATH") { |value| options[:output_dir] = value }
          parser.on("--as-of YYYY-MM-DD") { |value| options[:as_of] = Date.iso8601(value) }
          parser.on("--anpl-revision SHA") { |value| options[:revisions]["anpl"] = value }
          parser.on("--connect-revision SHA") { |value| options[:revisions]["connect"] = value }
        end
      end
      private_class_method :option_parser
    end
  end
end

exit PFCL::ExternalContent::SyncCLI.call(ARGV) if $PROGRAM_NAME == __FILE__
