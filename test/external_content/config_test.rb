# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "yaml"

begin
  require_relative "../../scripts/external_content/config"
rescue LoadError
  # The first RED run proves the configuration interface does not exist yet.
end

class ExternalContentConfigTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)
  CONFIG_PATH = File.join(ROOT, "_data", "external_sources.yml")

  def test_loads_exact_allowlisted_source_paths
    config = config_class.load(CONFIG_PATH)

    assert_equal(
      {
        "news" => "_data/tweets.json",
        "publications" => "_bibliography/VadimIndelman.bib",
        "projects" => "_student-projects"
      },
      config.fetch("anpl").paths
    )
    assert_equal(
      {
        "news" => "_news",
        "publications" => "_bibliography/DZ_Complete.bib"
      },
      config.fetch("connect").paths
    )
  end

  def test_preserves_legacy_pfcl_project_slug_mapping
    source = config_class.load(CONFIG_PATH).fetch("anpl")

    assert_equal(
      {
        "autonomous-semantic-perception" => "AutonomousViewpoint-DependentSemantic Perception.md",
        "collaborative-aerial-navigation" => "Collaborative_Multi-Robot_Aerial_Autonomous_Navigation_and 3D_Reconstruction.md",
        "robust-risk-averse-decision-making" => "RobustRiskAverseDecisonMaking.md"
      },
      source.legacy_project_slugs
    )
  end

  def test_exposes_source_identity_and_urls
    source = config_class.load(CONFIG_PATH).fetch("connect")

    assert_equal "connect", source.id
    assert_equal "connect", source.lab_id
    assert_equal "ConNeCt", source.source_name
    assert_equal "Connect-Lab-Technion/Connect-Lab-Technion.github.io", source.repository
    assert_equal "https://connect-lab-technion.github.io", source.site_url
    assert_equal "https://connect-lab-technion.github.io/publications/", source.publications_url
  end

  def test_rejects_each_missing_required_source_field
    %w[repository site_url lab_id source_name paths].each do |field|
      data = valid_data
      data.fetch("sources").fetch("anpl").delete(field)

      error = assert_raises(ArgumentError) { load_data(data) }
      assert_includes error.message, field
    end
  end

  def test_rejects_unknown_source_id
    config = config_class.load(CONFIG_PATH)

    error = assert_raises(KeyError) { config.fetch("unknown") }
    assert_includes error.message, "unknown"
  end

  def test_rejects_absolute_or_parent_source_paths
    ["../tweets.json", "/tmp/tweets.json", "C:/temp/tweets.json"].each do |unsafe_path|
      data = valid_data
      data.fetch("sources").fetch("anpl").fetch("paths")["news"] = unsafe_path

      error = assert_raises(ArgumentError) { load_data(data) }
      assert_includes error.message, "news"
    end
  end

  private

  def config_class
    assert defined?(PFCL::ExternalContent::Config), "PFCL::ExternalContent::Config must be defined"
    PFCL::ExternalContent::Config
  end

  def valid_data
    {
      "sources" => {
        "anpl" => {
          "lab_id" => "anpl",
          "source_name" => "ANPL",
          "repository" => "anpl-technion/anpl-technion.github.io",
          "site_url" => "https://anpl-technion.github.io",
          "publications_url" => "https://anpl-technion.github.io/publications/",
          "paths" => { "news" => "_data/tweets.json" },
          "legacy_project_slugs" => {}
        }
      }
    }
  end

  def load_data(data)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "sources.yml")
      File.write(path, YAML.dump(data))
      return config_class.load(path)
    end
  end
end
