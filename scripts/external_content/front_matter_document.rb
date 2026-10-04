# frozen_string_literal: true

require "date"
require "yaml"

module PFCL
  module ExternalContent
    class SourceError < StandardError; end

    Document = Data.define(:frontmatter, :body, :source_path)

    module FrontMatterDocument
      FRONTMATTER = /\A---\s*\r?\n(.*?)\r?\n---\s*(?:\r?\n|\z)/m

      module_function

      def read(path)
        content = File.read(path, encoding: "UTF-8")
        match = FRONTMATTER.match(content)
        raise SourceError, "#{path}: missing or unterminated YAML frontmatter" unless match

        fields = YAML.safe_load(match[1], permitted_classes: [Date], aliases: false) || {}
        raise SourceError, "#{path}: frontmatter must be a mapping" unless fields.is_a?(Hash)

        Document.new(frontmatter: fields, body: content[match.end(0)..].to_s, source_path: path)
      rescue Psych::SyntaxError, Date::Error => e
        raise SourceError, "#{path}: invalid YAML frontmatter: #{e.message}"
      rescue Errno::ENOENT, Errno::EACCES => e
        raise SourceError, "#{path}: #{e.message}"
      end
    end
  end
end
