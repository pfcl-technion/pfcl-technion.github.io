# frozen_string_literal: true

require "date"
require "set"

module PFCL
  module ExternalContent
    class Catalog
      NEWS_PUBLICATION_TYPES = %w[article inproceedings incollection book].freeze
      PUBLICATION_LIMIT_PER_LAB = 5

      attr_reader :updates, :publications, :projects

      def initialize(source_updates:, publications:, projects:, as_of:)
        @as_of = as_of
        @publications = publications.sort_by { |record| publication_sort_key(record) }
        @projects = projects.sort_by { |record| [record.fetch("title").downcase, record.fetch("id")] }
        @updates = build_updates(source_updates)
      end

      private

      def build_updates(source_updates)
        blocked = linked_publication_ids(source_updates)
        automatic = publication_updates(blocked)
        (source_updates + automatic).sort_by do |record|
          [record.fetch("date"), record.fetch("id")]
        end.reverse
      end

      def publication_updates(blocked)
        candidates = Hash.new { |hash, lab_id| hash[lab_id] = [] }
        @publications.each do |publication|
          next unless eligible_for_news?(publication)

          publication.fetch("lab_ids").each do |lab_id|
            next if blocked.fetch(lab_id, Set.new).include?(publication.fetch("id"))

            candidates[lab_id] << build_publication_update(publication, lab_id)
          end
        end

        candidates.keys.sort.flat_map do |lab_id|
          candidates.fetch(lab_id)
            .sort_by { |record| [record.fetch("date"), record.fetch("id")] }
            .reverse
            .first(PUBLICATION_LIMIT_PER_LAB)
        end
      end

      def eligible_for_news?(publication)
        return false unless NEWS_PUBLICATION_TYPES.include?(publication.fetch("publication_type"))
        return false unless publication.fetch("date_precision") == "month" && publication["month"]

        publication_month = Date.new(publication.fetch("year"), publication.fetch("month"), 1)
        current_month = Date.new(@as_of.year, @as_of.month, 1)
        publication_month.between?(current_month << 11, current_month)
      end

      def build_publication_update(publication, lab_id)
        index = publication.fetch("lab_ids").index(lab_id) || 0
        source_names = publication.fetch("source_names")
        provenance = publication.fetch("provenance")
        lab_provenance = provenance.find { |item| item["lab_id"] == lab_id } || provenance.fetch(index, provenance.first)
        month = format("%04d-%02d", publication.fetch("year"), publication.fetch("month"))
        venue = publication["venue"]
        excerpt = publication.fetch("authors").join(", ")
        excerpt = "#{excerpt}. #{venue}" if venue && !venue.empty?

        {
          "id" => "publication:update:#{lab_id}:#{publication.fetch('id')}",
          "publication_id" => publication.fetch("id"),
          "title" => publication.fetch("title"),
          "date" => "#{month}-01",
          "published_at" => month,
          "date_precision" => "month",
          "lab_id" => lab_id,
          "category" => "publication",
          "excerpt" => excerpt,
          "canonical_url" => publication.fetch("canonical_url"),
          "source_name" => source_names.fetch(index, source_names.first),
          "featured" => false,
          "show_on_showcase" => true,
          "display_weight" => 0,
          "provenance" => lab_provenance
        }
      end

      def linked_publication_ids(source_updates)
        source_updates.each_with_object(Hash.new { |hash, lab| hash[lab] = Set.new }) do |update, result|
          Array(update["expanded_urls"]).each do |url|
            identifier = publication_id_from_url(url)
            result[update.fetch("lab_id")] << identifier if identifier
          end
        end
      end

      def publication_id_from_url(url)
        value = url.to_s
        if (match = value.match(%r{(?:doi\.org/|\bdoi:)(10\.\d{4,9}/[^?#\s]+)}i))
          "publication:doi:#{match[1].downcase.sub(/[.,;)]+\z/, '')}"
        elsif (match = value.match(%r{arxiv\.org/(?:abs|pdf)/([^?#\s]+)}i))
          arxiv = match[1].sub(/\.pdf\z/i, "").sub(/v\d+\z/i, "").downcase
          "publication:arxiv:#{arxiv}"
        end
      end

      def publication_sort_key(record)
        [-record.fetch("year"), -record.fetch("month", 0), record.fetch("title").downcase, record.fetch("id")]
      end
    end
  end
end
