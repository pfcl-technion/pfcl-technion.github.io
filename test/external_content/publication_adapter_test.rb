# frozen_string_literal: true

require "date"
require "fileutils"
require "minitest/autorun"
require "stringio"
require "tmpdir"

require_relative "../../scripts/external_content/config"
require_relative "../../scripts/external_content/front_matter_document"

begin
  require_relative "../../scripts/external_content/publication_adapter"
rescue LoadError
  # The RED run proves publication normalization is not implemented.
end

class PublicationAdapterTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)
  FIXTURE_ROOT = File.join(ROOT, "test", "fixtures", "external", "anpl")
  CONFIG_PATH = File.join(ROOT, "_data", "external_sources.yml")
  REVISION = "c" * 40
  AS_OF = Date.new(2026, 10, 4)

  def setup
    @warnings = StringIO.new
  end

  def test_keeps_only_final_supported_non_future_publications
    records = adapter.records

    assert_equal(
      [
        "Completed Doctoral Thesis",
        "Final Planning Conference Paper",
        "Final Robotics Book",
        "Shared Network Paper",
        "Year Only Study"
      ],
      records.map { |record| record.fetch("title") }.sort
    )
    refute records.any? { |record| record.fetch("title").match?(/Future|Accepted|Forthcoming|In Press|Preprint/) }
  end

  def test_normalizes_months_and_year_precision
    records = adapter.records.to_h { |record| [record.fetch("title"), record] }

    assert_equal 9, records.fetch("Shared Network Paper").fetch("month")
    assert_equal 9, records.fetch("Final Planning Conference Paper").fetch("month")
    assert_equal 9, records.fetch("Completed Doctoral Thesis").fetch("month")
    assert_equal "month", records.fetch("Final Robotics Book").fetch("date_precision")
    refute records.fetch("Year Only Study").key?("month")
    assert_equal "year", records.fetch("Year Only Study").fetch("date_precision")
  end

  def test_uses_canonical_link_priority
    records = adapter.records.to_h { |record| [record.fetch("title"), record] }

    assert_equal "https://doi.org/10.1000/shared", records.fetch("Shared Network Paper").fetch("canonical_url")
    assert_equal "https://arxiv.org/abs/2601.00001", records.fetch("Final Planning Conference Paper").fetch("canonical_url")
    assert_equal "https://publisher.example/books/final-robotics", records.fetch("Final Robotics Book").fetch("canonical_url")
    assert_equal "https://anpl-technion.github.io/publications/", records.fetch("Year Only Study").fetch("canonical_url")
  end

  def test_discards_every_pdf_field_and_pdf_url
    serialized = adapter.records.inspect

    refute_match(/"pdf"/i, serialized)
    refute_match(/\.pdf/i, serialized)
    refute_includes serialized, "/Publications/"
  end

  def test_warns_for_unsupported_types_and_keeps_processing
    adapter.records
    warnings = @warnings.string

    assert_includes warnings, "AnplPreprint"
    assert_includes warnings, "AnplMisc"
    assert_includes warnings, "unsupported"
  end

  def test_fails_the_source_when_bibtex_is_malformed
    Dir.mktmpdir do |dir|
      root = File.join(dir, "anpl")
      FileUtils.cp_r(FIXTURE_ROOT, root)
      path = File.join(root, "_bibliography", "VadimIndelman.bib")
      File.write(path, "@article{broken, title = {unterminated}")

      error = assert_raises(PFCL::ExternalContent::SourceError) { adapter(root).records }
      assert_includes error.message, "VadimIndelman.bib"
    end
  end

  private

  def adapter(root = FIXTURE_ROOT)
    adapter_class.new(
      source: source,
      root: root,
      revision: REVISION,
      as_of: AS_OF,
      warn_io: @warnings
    )
  end

  def adapter_class
    assert defined?(PFCL::ExternalContent::PublicationAdapter), "PFCL::ExternalContent::PublicationAdapter must be defined"
    PFCL::ExternalContent::PublicationAdapter
  end

  def source
    PFCL::ExternalContent::Config.load(CONFIG_PATH).fetch("anpl")
  end
end
