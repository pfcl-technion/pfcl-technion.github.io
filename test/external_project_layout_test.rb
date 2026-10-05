# frozen_string_literal: true

require "minitest/autorun"
require "yaml"

class ExternalProjectLayoutTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  EXPECTED = {
    "autonomous-semantic-perception" => "https://anpl-technion.github.io/student-projects/AutonomousViewpoint-DependentSemantic%20Perception/",
    "collaborative-aerial-navigation" => "https://anpl-technion.github.io/student-projects/Collaborative_Multi-Robot_Aerial_Autonomous_Navigation_and%203D_Reconstruction/",
    "robust-risk-averse-decision-making" => "https://anpl-technion.github.io/student-projects/RobustRiskAverseDecisonMaking/"
  }.freeze

  def test_preserved_project_documents_are_minimal_verified_handoffs
    EXPECTED.each do |slug, canonical_url|
      fields = frontmatter(File.join(ROOT, "_projects", "#{slug}.md"))

      assert_equal slug, fields["slug"]
      assert_equal "external_project", fields["layout"]
      assert_equal true, fields["external"]
      assert_equal ["anpl"], fields["lab_ids"]
      assert_equal "ANPL", fields["source_name"]
      assert_equal canonical_url, fields["canonical_url"]
      assert_equal %w[canonical_url external lab_ids layout published slug source_name title], fields.keys.sort
    end
  end

  def test_layout_links_directly_to_source_and_has_visible_no_javascript_fallback
    template = File.read(File.join(ROOT, "_layouts", "external_project.html"))

    assert_includes template, "page.canonical_url | escape"
    assert_includes template, "page.source_name | escape"
    assert_includes template, "View on ANPL"
    assert_match(/target=["']_blank["']/, template)
    assert_match(/rel=["']noopener noreferrer["']/, template)
    assert_match(/original.*listing|listing.*original/i, template)
    refute_match(/data-inquiry-btn|projects\.js/, template)
  rescue Errno::ENOENT
    flunk "_layouts/external_project.html must exist"
  end

  def test_source_checkout_exclusion_does_not_hide_the_external_project_layout
    config = YAML.safe_load_file(File.join(ROOT, "_config.yml"), aliases: false)

    assert_includes config.fetch("exclude"), "external/**"
    refute_includes config.fetch("exclude"), "external"
  end

  private

  def frontmatter(path)
    content = File.read(path)
    yaml = content.match(/\A---\s*\n(.*?)\n---/m)&.captures&.first
    refute_nil yaml, "#{path} must have frontmatter"
    YAML.safe_load(yaml, aliases: false)
  end
end
