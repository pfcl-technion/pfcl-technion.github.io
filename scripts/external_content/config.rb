# frozen_string_literal: true

require "pathname"
require "uri"
require "yaml"

module PFCL
  module ExternalContent
    Source = Data.define(
      :id,
      :lab_id,
      :source_name,
      :repository,
      :site_url,
      :publications_url,
      :paths,
      :legacy_project_slugs
    )

    class Config
      REQUIRED_SOURCE_FIELDS = %w[repository site_url lab_id source_name paths].freeze

      def self.load(path)
        raw = YAML.safe_load_file(path, aliases: false)
        sources = raw.is_a?(Hash) ? raw["sources"] : nil
        unless sources.is_a?(Hash) && !sources.empty?
          raise ArgumentError, "external source config must contain a non-empty sources mapping"
        end

        new(sources.to_h { |id, values| [id.to_s, build_source(id.to_s, values)] })
      rescue Psych::SyntaxError => e
        raise ArgumentError, "invalid external source YAML: #{e.message}"
      end

      def self.build_source(id, values)
        raise ArgumentError, "source '#{id}' must be a mapping" unless values.is_a?(Hash)

        REQUIRED_SOURCE_FIELDS.each do |field|
          value = values[field]
          missing = value.nil? || (value.respond_to?(:empty?) && value.empty?)
          raise ArgumentError, "source '#{id}' missing required field '#{field}'" if missing
        end

        %w[repository site_url lab_id source_name].each do |field|
          value = values[field]
          unless value.is_a?(String) && !value.strip.empty?
            raise ArgumentError, "source '#{id}' field '#{field}' must be a non-empty string"
          end
        end

        paths = validate_paths(id, values["paths"])
        legacy_slugs = validate_string_mapping(id, "legacy_project_slugs", values.fetch("legacy_project_slugs", {}))
        publications_url = values["publications_url"]
        validate_http_url(id, "site_url", values["site_url"])
        validate_http_url(id, "publications_url", publications_url) if publications_url

        Source.new(
          id: id.freeze,
          lab_id: values["lab_id"].freeze,
          source_name: values["source_name"].freeze,
          repository: values["repository"].freeze,
          site_url: values["site_url"].sub(%r{/+\z}, "").freeze,
          publications_url: publications_url&.freeze,
          paths: paths,
          legacy_project_slugs: legacy_slugs
        ).freeze
      end
      private_class_method :build_source

      def self.validate_paths(id, paths)
        unless paths.is_a?(Hash) && !paths.empty?
          raise ArgumentError, "source '#{id}' field 'paths' must be a non-empty mapping"
        end

        paths.to_h do |name, value|
          unless value.is_a?(String) && !value.strip.empty?
            raise ArgumentError, "source '#{id}' path '#{name}' must be a non-empty string"
          end

          components = value.tr("\\", "/").split("/")
          absolute = Pathname.new(value).absolute? || value.match?(%r{\A[A-Za-z]:[\\/]})
          if absolute || components.include?("..")
            raise ArgumentError, "source '#{id}' path '#{name}' must be relative and cannot contain '..'"
          end

          [name.to_s.freeze, value.freeze]
        end.freeze
      end
      private_class_method :validate_paths

      def self.validate_string_mapping(id, field, mapping)
        raise ArgumentError, "source '#{id}' field '#{field}' must be a mapping" unless mapping.is_a?(Hash)

        mapping.to_h do |key, value|
          unless key.is_a?(String) && !key.empty? && value.is_a?(String) && !value.empty?
            raise ArgumentError, "source '#{id}' field '#{field}' must map non-empty strings"
          end
          [key.freeze, value.freeze]
        end.freeze
      end
      private_class_method :validate_string_mapping

      def self.validate_http_url(id, field, value)
        uri = URI.parse(value.to_s)
        return if %w[http https].include?(uri.scheme) && uri.host

        raise ArgumentError, "source '#{id}' field '#{field}' must be an http(s) URL"
      rescue URI::InvalidURIError
        raise ArgumentError, "source '#{id}' field '#{field}' must be an http(s) URL"
      end
      private_class_method :validate_http_url

      def initialize(sources)
        @sources = sources.freeze
      end

      def fetch(id)
        @sources.fetch(id.to_s) do
          raise KeyError, "unknown external source '#{id}'"
        end
      end
    end
  end
end
