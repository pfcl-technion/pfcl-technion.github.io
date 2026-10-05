# frozen_string_literal: true

module PFCL
  module ExternalContent
    module PublicationCatalog
      module_function

      def merge(record_sets)
        by_id = {}
        record_sets.flatten.each do |record|
          existing = by_id[record.fetch("id")]
          if existing
            merge_record(existing, record)
          else
            by_id[record.fetch("id")] = deep_copy(record)
          end
        end

        by_id.values.each { |record| normalize_merged_arrays(record) }
          .sort_by { |record| sort_key(record) }
      end

      def merge_record(target, incoming)
        %w[lab_ids source_names provenance].each do |field|
          target[field] = target.fetch(field) + incoming.fetch(field)
        end
      end
      private_class_method :merge_record

      def normalize_merged_arrays(record)
        record["lab_ids"] = record.fetch("lab_ids").uniq.sort
        record["source_names"] = record.fetch("source_names").uniq.sort
        record["provenance"] = record.fetch("provenance").uniq.sort_by do |item|
          %w[repository source_path source_key revision].map { |field| item.fetch(field).to_s }
        end
        record
      end
      private_class_method :normalize_merged_arrays

      def sort_key(record)
        [-record.fetch("year"), -record.fetch("month", 0), record.fetch("title").downcase, record.fetch("id")]
      end
      private_class_method :sort_key

      def deep_copy(value)
        Marshal.load(Marshal.dump(value))
      end
      private_class_method :deep_copy
    end
  end
end
