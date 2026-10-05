# frozen_string_literal: true

require "cgi"
require "date"

require_relative "config"
require_relative "front_matter_document"
require_relative "plain_text"

module PFCL
  module ExternalContent
    class ConnectAdapter
      def initialize(source:, root:, revision:)
        @source = source
        @root = File.expand_path(root)
        @revision = revision
      end

      def updates
        configured_path = @source.paths.fetch("news")
        directory = File.join(@root, *configured_path.split("/"))
        raise SourceError, "#{configured_path}: source directory is missing" unless Dir.exist?(directory)

        paths = Dir.glob(File.join(directory, "*.md")).sort
        raise SourceError, "#{configured_path}: source collection is empty" if paths.empty?

        paths.map { |path| normalize_news(path, configured_path) }
             .sort_by { |item| [item.fetch("date"), item.fetch("id")] }
             .reverse
      end

      private

      def normalize_news(path, configured_directory)
        document = FrontMatterDocument.read(path)
        title = required_plain_text(document.frontmatter, "title", path)
        excerpt = required_plain_text(document.frontmatter, "description", path)
        date = normalize_date(document.frontmatter["date"], path)
        stem = File.basename(path, ".md")
        relative_path = "#{configured_directory}/#{File.basename(path)}"

        {
          "id" => "connect:news:#{stem}",
          "title" => title,
          "date" => date.iso8601,
          "published_at" => date.iso8601,
          "date_precision" => "day",
          "lab_id" => @source.lab_id,
          "category" => "news",
          "excerpt" => excerpt,
          "canonical_url" => "#{@source.site_url}/news/#{url_segment(stem)}",
          "source_name" => @source.source_name,
          "featured" => false,
          "show_on_showcase" => true,
          "display_weight" => 0,
          "provenance" => {
            "repository" => @source.repository,
            "revision" => @revision,
            "source_path" => relative_path
          }
        }
      end

      def required_plain_text(fields, key, path)
        value = PlainText.from_markdown(fields[key])
        raise SourceError, "#{path}: required frontmatter '#{key}' is missing" if value.empty?

        value
      end

      def normalize_date(value, path)
        case value
        when Date
          value
        when String
          Date.iso8601(value)
        else
          raise SourceError, "#{path}: date must be YYYY-MM-DD"
        end
      rescue Date::Error
        raise SourceError, "#{path}: date must be a real YYYY-MM-DD date"
      end

      def url_segment(value)
        CGI.escape(value).gsub("+", "%20")
      end
    end
  end
end
