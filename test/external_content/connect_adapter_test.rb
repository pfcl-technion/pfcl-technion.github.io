# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "tmpdir"

require_relative "../../scripts/external_content/config"
require_relative "../../scripts/external_content/front_matter_document"
require_relative "../../scripts/external_content/plain_text"

begin
  require_relative "../../scripts/external_content/connect_adapter"
rescue LoadError
  # The RED run proves the source-specific adapter is not implemented.
end

class ConnectAdapterTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)
  FIXTURE_ROOT = File.join(ROOT, "test", "fixtures", "external", "connect")
  CONFIG_PATH = File.join(ROOT, "_data", "external_sources.yml")
  REVISION = "b" * 40

  def test_maps_frontmatter_to_attributed_update
    update = adapter.updates.find { |item| item.fetch("id") == "connect:news:news_8-09-26_no2" }

    assert_equal "Invited Speaker at Rigidity Theory: Structures, Data, and Control", update.fetch("title")
    assert_equal "2026-09-08", update.fetch("date")
    assert_equal "2026-09-08", update.fetch("published_at")
    assert_equal "day", update.fetch("date_precision")
    assert_equal "connect", update.fetch("lab_id")
    assert_equal "news", update.fetch("category")
    assert_equal "ConNeCt", update.fetch("source_name")
    assert_equal "Daniel Zelazo will be an invited speaker at the 2026 Rigidity Workshop.", update.fetch("excerpt")
    assert_equal "https://connect-lab-technion.github.io/news/news_8-09-26_no2/", update.fetch("canonical_url")
    assert_equal false, update.fetch("featured")
    assert_equal true, update.fetch("show_on_showcase")
    assert_equal 0, update.fetch("display_weight")
    assert_equal(
      {
        "repository" => "Connect-Lab-Technion/Connect-Lab-Technion.github.io",
        "revision" => REVISION,
        "source_path" => "_news/news_8-09-26_no2.md"
      },
      update.fetch("provenance")
    )
  end

  def test_orders_same_day_items_by_filename_descending
    assert_equal(
      ["connect:news:news_8-09-26_no2", "connect:news:news_8-09-26", "connect:news:unsafe"],
      adapter.updates.map { |item| item.fetch("id") }
    )
  end

  def test_uses_only_sanitized_frontmatter_not_article_body
    update = adapter.updates.find { |item| item.fetch("id") == "connect:news:unsafe" }
    rendered = update.values_at("title", "excerpt").join(" ")

    assert_equal "Safe News", update.fetch("title")
    assert_equal "Useful summary.", update.fetch("excerpt")
    refute_includes rendered, "BODY_SECRET"
    refute_match(/<|>|alert\s*\(/i, rendered)
  end

  def test_rejects_missing_or_empty_news_directory
    with_fixture_copy do |root|
      news_path = File.join(root, "_news")
      FileUtils.rm_r(news_path)
      error = assert_raises(PFCL::ExternalContent::SourceError) { adapter(root).updates }
      assert_includes error.message, "_news"

      Dir.mkdir(news_path)
      error = assert_raises(PFCL::ExternalContent::SourceError) { adapter(root).updates }
      assert_includes error.message, "empty"
    end
  end

  def test_rejects_invalid_frontmatter_missing_fields_and_invalid_dates
    cases = {
      "invalid YAML" => "---\ntitle: [unterminated\n---\n",
      "missing title" => "---\ndate: 2026-01-01\ndescription: Summary\n---\n",
      "missing description" => "---\ntitle: News\ndate: 2026-01-01\n---\n",
      "invalid date" => "---\ntitle: News\ndate: not-a-date\ndescription: Summary\n---\n"
    }

    cases.each do |label, content|
      with_fixture_copy do |root|
        path = File.join(root, "_news", "unsafe.md")
        File.write(path, content)
        error = assert_raises(PFCL::ExternalContent::SourceError, label) { adapter(root).updates }
        assert_includes error.message, "unsafe.md", label
      end
    end
  end

  private

  def adapter(root = FIXTURE_ROOT)
    adapter_class.new(source: source, root: root, revision: REVISION)
  end

  def adapter_class
    assert defined?(PFCL::ExternalContent::ConnectAdapter), "PFCL::ExternalContent::ConnectAdapter must be defined"
    PFCL::ExternalContent::ConnectAdapter
  end

  def source
    PFCL::ExternalContent::Config.load(CONFIG_PATH).fetch("connect")
  end

  def with_fixture_copy
    Dir.mktmpdir do |dir|
      root = File.join(dir, "connect")
      FileUtils.cp_r(FIXTURE_ROOT, root)
      yield root
    end
  end
end
