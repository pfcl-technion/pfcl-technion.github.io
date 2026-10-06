# frozen_string_literal: true

require "cgi"
require "date"
require "json"

require_relative "config"
require_relative "front_matter_document"
require_relative "plain_text"

module PFCL
  module ExternalContent
    class AnplAdapter
      EXCERPT_LIMIT = 280

      def initialize(source:, root:, revision:)
        @source = source
        @root = File.expand_path(root)
        @revision = revision
      end

      def updates
        configured_path = @source.paths.fetch("news")
        path = absolute_source_path(configured_path)
        raise SourceError, "#{configured_path}: source file is missing" unless File.file?(path)

        items = JSON.parse(File.read(path, encoding: "UTF-8"))
        raise SourceError, "#{configured_path}: expected a JSON array" unless items.is_a?(Array)
        raise SourceError, "#{configured_path}: source collection is empty" if items.empty?

        items.map { |item| normalize_tweet(item, configured_path) }
             .sort_by { |item| [item.fetch("published_at"), item.fetch("id")] }
             .reverse
      rescue JSON::ParserError => e
        raise SourceError, "#{configured_path}: invalid JSON: #{e.message}"
      rescue KeyError, Date::Error, TypeError => e
        raise SourceError, "#{configured_path}: invalid tweet record: #{e.message}"
      end

      def projects
        configured_path = @source.paths.fetch("projects")
        directory = absolute_source_path(configured_path)
        raise SourceError, "#{configured_path}: source directory is missing" unless Dir.exist?(directory)

        paths = Dir.glob(File.join(directory, "*.md")).sort
        raise SourceError, "#{configured_path}: source collection is empty" if paths.empty?

        paths.map { |path| normalize_project(path, configured_path) }
             .sort_by { |project| [project.fetch("title").downcase, project.fetch("id")] }
      end

      private

      def normalize_tweet(item, configured_path)
        id = required_string(item, "id")
        text = required_string(item, "text")
        timestamp = DateTime.iso8601(required_string(item, "created_at"))
        clean_text = PlainText.from_markdown(text)

        {
          "id" => "anpl:x:#{id}",
          "content_type" => "social",
          "title" => clean_text,
          "date" => timestamp.strftime("%Y-%m-%d"),
          "published_at" => timestamp.new_offset(0).strftime("%Y-%m-%dT%H:%M:%SZ"),
          "date_precision" => "day",
          "lab_id" => @source.lab_id,
          "category" => "news",
          "excerpt" => clean_text,
          "canonical_url" => required_string(item, "link"),
          "source_name" => @source.source_name,
          "source_account" => item["handle"].to_s.empty? ? item["account"].to_s : item["handle"].to_s,
          "expanded_urls" => expanded_urls(item),
          "featured" => false,
          "show_on_showcase" => true,
          "display_weight" => 0,
          "provenance" => provenance(configured_path)
        }
      end

      def normalize_project(path, configured_directory)
        document = FrontMatterDocument.read(path)
        title = PlainText.from_markdown(document.frontmatter["title"])
        raise SourceError, "#{path}: project title is missing" if title.empty?

        basename = File.basename(path, ".md")
        relative_path = "#{configured_directory}/#{File.basename(path)}"
        slug = slugify(title)
        summary = project_summary(document.body)
        raise SourceError, "#{path}: project summary is missing" if summary.empty?

        project = {
          "id" => "anpl:project:#{slug}",
          "slug" => slug,
          "title" => title,
          "summary" => summary,
          "lab_ids" => [@source.lab_id],
          "source_name" => @source.source_name,
          "external" => true,
          "recruitment_status" => "available",
          "thumbnail" => thumbnail_url(document.frontmatter["image"]),
          "canonical_url" => "#{@source.site_url}/student-projects/#{url_segment(basename)}/",
          "provenance" => provenance(relative_path)
        }

        advisors = section_bullets(document.body, "Academic supervisor").map do |line|
          PlainText.from_markdown(line)
                   .sub(/\A(?:Assoc\.\s+Prof\.|Prof\.|Dr\.)\s*/i, "")
                   .sub(/\s*\(?email\)?\s*\z/i, "")
                   .strip
        end.reject(&:empty?)
        prerequisites = section_bullets(document.body, "Prerequisites").map do |line|
          PlainText.from_markdown(line)
        end.reject(&:empty?)
        duration = document.body[/^\s*Duration:\s*(.+?)\s*$/i, 1]

        project["advisor_names"] = advisors unless advisors.empty?
        project["prerequisites"] = prerequisites unless prerequisites.empty?
        project["duration"] = PlainText.from_markdown(duration) if duration
        project
      end

      def project_summary(body)
        body.split(/^\s*\#{1,6}\s+[^\r\n]*(?:\r?\n|\z)/).each do |section|
          summary = PlainText.from_markdown(section, max_length: EXCERPT_LIMIT)
          return summary unless summary.empty?
        end
        ""
      end

      def section_bullets(body, heading)
        section = body[/^\s*\#{1,6}\s+#{Regexp.escape(heading)}:?\s*$\r?\n(.*?)(?=^\s*\#{1,6}\s+|\z)/mi, 1]
        return [] unless section

        section.lines.filter_map do |line|
          match = line.match(/^\s*[-+*]\s+(.+?)\s*$/)
          match && match[1]
        end
      end

      def thumbnail_url(value)
        image = value.to_s.strip
        return "/assets/images/project_default.jpg" if image.empty?
        return image if image.match?(%r{\Ahttps?://}i)

        "#{@source.site_url}/#{image.sub(%r{\A/+}, '')}"
      end

      def expanded_urls(item)
        Array(item["urls"]).filter_map do |entry|
          next unless entry.is_a?(Hash)

          url = entry["expanded_url"].to_s
          url if url.match?(%r{\Ahttps?://}i)
        end.uniq.sort
      end

      def required_string(item, key)
        value = item.fetch(key)
        raise KeyError, "#{key} must be a non-empty string" unless value.is_a?(String) && !value.strip.empty?

        value
      end

      def provenance(source_path)
        {
          "repository" => @source.repository,
          "revision" => @revision,
          "source_path" => source_path.tr("\\", "/")
        }
      end

      def absolute_source_path(configured_path)
        File.join(@root, *configured_path.split("/"))
      end

      def url_segment(value)
        CGI.escape(value).gsub("+", "%20")
      end

      def slugify(value)
        value.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
      end
    end
  end
end
