# frozen_string_literal: true

require "date"
require "minitest/autorun"
require "stringio"

require_relative "../../scripts/external_content/config"
require_relative "../../scripts/external_content/front_matter_document"

begin
  require_relative "../../scripts/external_content/publication_adapter"
  require_relative "../../scripts/external_content/publication_catalog"
rescue LoadError
  # The RED run proves publication identity and catalog merging are absent.
end

class PublicationCatalogTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)
  FIXTURE_ROOT = File.join(ROOT, "test", "fixtures", "external")
  CONFIG_PATH = File.join(ROOT, "_data", "external_sources.yml")
  AS_OF = Date.new(2026, 10, 4)

  def test_duplicate_source_keys_do_not_drop_distinct_publications
    titles = merged.map { |record| record.fetch("title") }

    assert_includes titles, "First Duplicate-Key Paper"
    assert_includes titles, "Second Duplicate-Key Paper"
  end

  def test_merges_matching_doi_and_arxiv_records_across_labs
    by_id = merged.to_h { |record| [record.fetch("id"), record] }
    doi_record = by_id.fetch("publication:doi:10.1000/shared")
    arxiv_record = by_id.fetch("publication:arxiv:2601.00001")

    [doi_record, arxiv_record].each do |record|
      assert_equal %w[anpl connect], record.fetch("lab_ids")
      assert_equal %w[ANPL ConNeCt], record.fetch("source_names")
      assert_equal 2, record.fetch("provenance").length
    end
  end

  def test_uses_stable_fallback_identity
    record = merged.find { |item| item.fetch("title") == "Year Only Study" }

    assert_equal "publication:sha256:cb9eed57a7add4d9a9eb", record.fetch("id")
  end

  def test_returns_deterministic_newest_first_order
    first = merged
    second = catalog_class.merge(record_sets)

    assert_equal first, second
    sort_keys = first.map do |record|
      [-record.fetch("year"), -record.fetch("month", 0), record.fetch("title").downcase, record.fetch("id")]
    end
    assert_equal sort_keys.sort, sort_keys
  end

  private

  def merged
    @merged ||= catalog_class.merge(record_sets)
  end

  def record_sets
    config = PFCL::ExternalContent::Config.load(CONFIG_PATH)
    %w[anpl connect].map.with_index do |source_id, index|
      adapter_class.new(
        source: config.fetch(source_id),
        root: File.join(FIXTURE_ROOT, source_id),
        revision: (index.zero? ? "c" : "d") * 40,
        as_of: AS_OF,
        warn_io: StringIO.new
      ).records
    end
  end

  def adapter_class
    assert defined?(PFCL::ExternalContent::PublicationAdapter), "PFCL::ExternalContent::PublicationAdapter must be defined"
    PFCL::ExternalContent::PublicationAdapter
  end

  def catalog_class
    assert defined?(PFCL::ExternalContent::PublicationCatalog), "PFCL::ExternalContent::PublicationCatalog must be defined"
    PFCL::ExternalContent::PublicationCatalog
  end
end
