# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "tmpdir"

require_relative "../../scripts/external_content/config"

begin
  require_relative "../../scripts/external_content/anpl_adapter"
rescue LoadError
  # The RED run proves the adapter and parsing helpers are not implemented.
end

class AnplAdapterTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)
  FIXTURE_ROOT = File.join(ROOT, "test", "fixtures", "external", "anpl")
  CONFIG_PATH = File.join(ROOT, "_data", "external_sources.yml")
  REVISION = "a" * 40

  def test_maps_committed_tweet_cache_to_attributed_update
    update = adapter.updates.first

    assert_equal "anpl:x:2097017262284693848", update.fetch("id")
    assert_equal "anpl", update.fetch("lab_id")
    assert_equal "news", update.fetch("category")
    assert_equal "ANPL", update.fetch("source_name")
    assert_equal "@ANPL_Technion", update.fetch("source_account")
    assert_equal "2026-09-07", update.fetch("date")
    assert_equal "2026-09-07T17:40:50Z", update.fetch("published_at")
    assert_equal "day", update.fetch("date_precision")
    assert_equal "https://twitter.com/ANPL_Technion/status/2097017262284693848", update.fetch("canonical_url")
    assert_equal false, update.fetch("featured")
    assert_equal true, update.fetch("show_on_showcase")
    assert_equal 0, update.fetch("display_weight")
    assert_equal(
      {
        "repository" => "anpl-technion/anpl-technion.github.io",
        "revision" => REVISION,
        "source_path" => "_data/tweets.json"
      },
      update.fetch("provenance")
    )
  end

  def test_keeps_expanded_urls_out_of_human_text
    update = adapter.updates.first

    assert_equal ["https://arxiv.org/abs/2602.23073"], update.fetch("expanded_urls")
    refute_includes update.fetch("title"), "t.co"
    refute_includes update.fetch("excerpt"), "t.co"
    assert_operator update.fetch("title").length, :<=, 120
  end

  def test_orders_updates_newest_first
    assert_equal(
      %w[anpl:x:2097017262284693848 anpl:x:2038310187577073944],
      adapter.updates.map { |item| item.fetch("id") }
    )
  end

  def test_maps_project_to_external_metadata_without_invented_fields
    project = adapter.projects.find { |item| item.fetch("title").start_with?("Autonomous") }

    assert_equal "anpl:project:autonomous-viewpoint-dependent-semantic-perception", project.fetch("id")
    assert_equal "autonomous-viewpoint-dependent-semantic-perception", project.fetch("slug")
    assert_equal ["anpl"], project.fetch("lab_ids")
    assert_equal "ANPL", project.fetch("source_name")
    assert_equal true, project.fetch("external")
    assert_equal ["Vadim Indelman"], project.fetch("advisor_names")
    assert_equal [
      "Strong programming skills (preferably Python or C++).",
      "Background in computer vision or robotics is an advantage."
    ], project.fetch("prerequisites")
    assert_equal "1 or 2 semesters", project.fetch("duration")
    assert_equal(
      "https://anpl-technion.github.io/img/student_project/AutonomousViewpointDependentSemanticPerception.png",
      project.fetch("thumbnail")
    )
    assert_equal(
      "https://anpl-technion.github.io/student-projects/AutonomousViewpoint-DependentSemantic%20Perception/",
      project.fetch("canonical_url")
    )
    refute project.key?("recruitment_status")
    refute project.key?("project_type")
    refute project.key?("contact_email")
  end

  def test_strips_source_html_and_scripts
    project = adapter.projects.find { |item| item.fetch("canonical_url").include?("Unsafe%20Project") }

    assert_equal "Safe Project", project.fetch("title")
    assert_equal "Useful project description with documentation.", project.fetch("summary")
    assert_equal ["Safe Advisor"], project.fetch("advisor_names")
    refute_match(/<|>|<script|alert\s*\(/i, project.values_at("title", "summary").join(" "))
  end

  def test_rejects_invalid_tweet_json_and_empty_tweet_cache
    with_fixture_copy do |root|
      tweets_path = File.join(root, "_data", "tweets.json")
      File.write(tweets_path, "{")
      error = assert_raises(source_error_class) { adapter(root).updates }
      assert_includes error.message, "_data/tweets.json"

      File.write(tweets_path, "[]")
      error = assert_raises(source_error_class) { adapter(root).updates }
      assert_includes error.message, "empty"
    end
  end

  def test_rejects_missing_or_empty_project_directory
    with_fixture_copy do |root|
      projects_path = File.join(root, "_student-projects")
      FileUtils.rm_r(projects_path)
      error = assert_raises(source_error_class) { adapter(root).projects }
      assert_includes error.message, "_student-projects"

      Dir.mkdir(projects_path)
      error = assert_raises(source_error_class) { adapter(root).projects }
      assert_includes error.message, "empty"
    end
  end

  def test_rejects_invalid_project_frontmatter
    with_fixture_copy do |root|
      project_path = File.join(root, "_student-projects", "Unsafe Project.md")
      File.write(project_path, "---\ntitle: [unterminated\n---\nBody")

      error = assert_raises(source_error_class) { adapter(root).projects }
      assert_includes error.message, "Unsafe Project.md"
    end
  end

  private

  def adapter(root = FIXTURE_ROOT)
    adapter_class.new(source: source, root: root, revision: REVISION)
  end

  def adapter_class
    assert defined?(PFCL::ExternalContent::AnplAdapter), "PFCL::ExternalContent::AnplAdapter must be defined"
    PFCL::ExternalContent::AnplAdapter
  end

  def source_error_class
    assert defined?(PFCL::ExternalContent::SourceError), "PFCL::ExternalContent::SourceError must be defined"
    PFCL::ExternalContent::SourceError
  end

  def source
    PFCL::ExternalContent::Config.load(CONFIG_PATH).fetch("anpl")
  end

  def with_fixture_copy
    Dir.mktmpdir do |dir|
      root = File.join(dir, "anpl")
      FileUtils.cp_r(FIXTURE_ROOT, root)
      yield root
    end
  end
end
