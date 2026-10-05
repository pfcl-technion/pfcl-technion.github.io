# frozen_string_literal: true

require "cgi"

module PFCL
  module ExternalContent
    module PlainText
      module_function

      def from_markdown(markdown, max_length: nil)
        text = markdown.to_s.dup
        text.gsub!(%r{<(script|style)\b[^>]*>.*?</\1>}mi, " ")
        text.gsub!(/!\[[^\]]*\]\([^)]*\)/m, " ")
        text.gsub!(/\[([^\]]+)\]\([^)]*\)/m, "\\1")
        text.gsub!(%r{https?://\S+}i, " ")
        text.gsub!(%r{</?[^>]+>}, " ")
        text.gsub!(/^\s{0,3}\#{1,6}\s+/, "")
        text.gsub!(/^\s*[-+*]\s+/, "")
        text.gsub!(/[*_`~]/, "")
        text = CGI.unescapeHTML(text).gsub(/\s+/, " ").strip
        max_length ? truncate(text, max_length) : text
      end

      def truncate(text, max_length)
        return text if text.length <= max_length

        prefix = text[0, max_length - 1]
        prefix = prefix.rpartition(" ").first unless prefix.end_with?(" ") || !prefix.include?(" ")
        "#{prefix.rstrip}…"
      end
      private_class_method :truncate
    end
  end
end
