# frozen_string_literal: true

require "bibtex"
require "date"
require "digest"
require "uri"

require_relative "front_matter_document"

module PFCL
  module ExternalContent
    class PublicationAdapter
      SUPPORTED_TYPES = %i[article inproceedings incollection book phdthesis mastersthesis].freeze
      WORK_IN_PROGRESS = /\b(?:submitted|accepted|in[ -]press|forthcoming|to appear)\b/i
      MONTHS = {
        "1" => 1, "01" => 1, "jan" => 1, "january" => 1,
        "2" => 2, "02" => 2, "feb" => 2, "february" => 2,
        "3" => 3, "03" => 3, "mar" => 3, "march" => 3,
        "4" => 4, "04" => 4, "apr" => 4, "april" => 4,
        "5" => 5, "05" => 5, "may" => 5,
        "6" => 6, "06" => 6, "jun" => 6, "june" => 6,
        "7" => 7, "07" => 7, "jul" => 7, "july" => 7,
        "8" => 8, "08" => 8, "aug" => 8, "august" => 8,
        "9" => 9, "09" => 9, "sep" => 9, "sept" => 9, "september" => 9,
        "10" => 10, "oct" => 10, "october" => 10,
        "11" => 11, "nov" => 11, "november" => 11,
        "12" => 12, "dec" => 12, "december" => 12
      }.freeze

      def initialize(source:, root:, revision:, as_of:, warn_io: $stderr)
        @source = source
        @root = File.expand_path(root)
        @revision = revision.to_s
        @as_of = as_of
        @warn_io = warn_io
      end

      def records
        path = configured_path
        bibliography = parse(path)
        entries = bibliography.each.select { |item| item.is_a?(BibTeX::Entry) }
        raise SourceError, "#{path}: publication bibliography is empty" if entries.empty?

        entries.filter_map { |entry| normalize(entry) }
          .sort_by { |record| publication_sort_key(record) }
      rescue SourceError
        raise
      rescue StandardError => e
        raise SourceError, "#{path || configured_path}: invalid BibTeX: #{e.message}"
      end

      private

      def configured_path
        relative = @source.paths.fetch("publications")
        path = File.expand_path(relative, @root)
        root_prefix = "#{@root}#{File::SEPARATOR}"
        unless path.start_with?(root_prefix)
          raise SourceError, "#{relative}: configured publication path escapes source root"
        end

        path
      end

      def parse(path)
        bibliography = BibTeX.open(path)
        unless bibliography.errors.empty?
          details = bibliography.errors.map(&:to_s).join("; ")
          raise SourceError, "#{path}: invalid BibTeX: #{details}"
        end

        bibliography
      rescue Errno::ENOENT, Errno::EACCES => e
        raise SourceError, "#{path}: #{e.message}"
      end

      def normalize(entry)
        unless SUPPORTED_TYPES.include?(entry.type)
          @warn_io.puts "warning: unsupported publication type #{entry.type} for #{entry.key}"
          return nil
        end
        return nil if work_in_progress?(entry)

        year = required_year(entry)
        month = normalized_month(entry)
        return nil if future?(year, month)

        title = required_text(entry, :title)
        authors = normalized_authors(entry)
        doi = normalized_doi(entry)
        arxiv = normalized_arxiv(entry)
        canonical_url = canonical_url(entry, doi, arxiv)

        record = {
          "id" => identity(doi, arxiv, title, year),
          "title" => title,
          "authors" => authors,
          "year" => year,
          "date_precision" => month ? "month" : "year",
          "publication_type" => entry.type.to_s,
          "canonical_url" => canonical_url,
          "lab_ids" => [@source.lab_id],
          "source_names" => [@source.source_name],
          "provenance" => [provenance(entry)]
        }
        record["month"] = month if month
        record["doi"] = doi if doi
        record["arxiv"] = arxiv if arxiv
        venue = venue_for(entry)
        record["venue"] = venue if venue
        record
      end

      def work_in_progress?(entry)
        %i[status note title journal booktitle publisher howpublished].any? do |field|
          text(entry[field])&.match?(WORK_IN_PROGRESS)
        end
      end

      def required_year(entry)
        raw = text(entry[:year])
        unless raw&.match?(/\A\d{4}\z/)
          raise SourceError, "#{configured_path}: publication #{entry.key} has an invalid year"
        end

        raw.to_i
      end

      def normalized_month(entry)
        raw = text(entry[:month])&.downcase
        return nil if raw.nil? || raw.empty?

        month = MONTHS[raw]
        raise SourceError, "#{configured_path}: publication #{entry.key} has an invalid month" unless month

        month
      end

      def required_text(entry, field)
        value = text(entry[field])
        if value.nil? || value.empty?
          raise SourceError, "#{configured_path}: publication #{entry.key} is missing #{field}"
        end

        value
      end

      def normalized_authors(entry)
        names = entry[:author]
        authors = if names.respond_to?(:to_a)
                    names.to_a.map { |name| format_author(name) }.compact
                  else
                    text(names).to_s.split(/\s+and\s+/i).map { |str| format_author(str) }.compact
                  end
        authors.reject!(&:empty?)
        if authors.empty?
          raise SourceError, "#{configured_path}: publication #{entry.key} is missing author"
        end

        authors
      end

      def format_author(name)
        if name.respond_to?(:display_order)
          formatted = text(name.display_order)
          return formatted unless formatted.to_s.empty?
        end

        raw = text(name)
        return nil if raw.nil? || raw.empty?

        if raw.include?(",")
          parsed = BibTeX::Name.parse(raw)
          formatted = text(parsed.display_order) if parsed.respond_to?(:display_order)
          return formatted unless formatted.to_s.empty?
        end

        raw
      end

      def venue_for(entry)
        fields = case entry.type
                 when :article then %i[journal]
                 when :inproceedings, :incollection then %i[booktitle publisher]
                 when :book then %i[publisher]
                 when :phdthesis, :mastersthesis then %i[school]
                 else []
                 end
        fields.filter_map { |field| text(entry[field]) }.find { |value| !value.empty? }
      end

      def normalized_doi(entry)
        value = text(entry[:doi])
        return nil unless value

        value.downcase
          .sub(%r{\Ahttps?://(?:dx\.)?doi\.org/}i, "")
          .sub(/\Adoi:\s*/i, "")
          .strip
          .then { |doi| doi.empty? ? nil : doi }
      end

      def normalized_arxiv(entry)
        explicit = text(entry[:arxiv])
        archive = text(entry[:archiveprefix])
        eprint = text(entry[:eprint])
        value = explicit || (eprint if archive&.casecmp?("arxiv") || eprint&.match?(/\A(?:arxiv:|\d{4}\.\d{4,5})/i))
        return nil unless value

        value = value.downcase
          .sub(%r{\Ahttps?://arxiv\.org/(?:abs|pdf)/}i, "")
          .sub(/\Aarxiv:\s*/i, "")
          .sub(/\.pdf\z/i, "")
          .sub(/v\d+\z/i, "")
          .strip
        value.empty? ? nil : value
      end

      def canonical_url(entry, doi, arxiv)
        return "https://doi.org/#{doi}" if doi

        explicit = safe_external_url(text(entry[:url]))
        return explicit if explicit
        return "https://arxiv.org/abs/#{arxiv}" if arxiv

        @source.publications_url || @source.site_url
      end

      def safe_external_url(value)
        return nil unless value

        uri = URI.parse(value)
        return nil unless %w[http https].include?(uri.scheme) && uri.host
        return nil if uri.path.downcase.end_with?(".pdf")

        value
      rescue URI::InvalidURIError
        nil
      end

      def identity(doi, arxiv, title, year)
        return "publication:doi:#{doi}" if doi
        return "publication:arxiv:#{arxiv}" if arxiv

        normalized_title = title.downcase.gsub(/\s+/, " ").strip
        digest = Digest::SHA256.hexdigest([@source.lab_id, normalized_title, year].join("|"))[0, 20]
        "publication:sha256:#{digest}"
      end

      def provenance(entry)
        {
          "repository" => @source.repository,
          "lab_id" => @source.lab_id,
          "source_name" => @source.source_name,
          "revision" => @revision,
          "source_path" => @source.paths.fetch("publications"),
          "source_key" => entry.key.to_s
        }
      end

      def future?(year, month)
        year > @as_of.year || (year == @as_of.year && month && month > @as_of.month)
      end

      def publication_sort_key(record)
        [-record.fetch("year"), -record.fetch("month", 0), record.fetch("title").downcase, record.fetch("id")]
      end

      def text(value)
        return nil if value.nil?

        decoded = LaTeX.decode(value.to_s)
        decoded.gsub(/[{}]/, "").gsub(/\s+/, " ").strip
      end
    end
  end
end
