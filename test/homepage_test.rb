# frozen_string_literal: true

require "minitest/autorun"

class HomepageTest < Minitest::Test
  def setup
    @content = File.read(File.expand_path("../index.md", __dir__))
  end

  def test_homepage_section_ordering
    welcome_pos = @content.index("## Welcome")
    news_pos = @content.index("## News &amp; updates")
    projects_pos = @content.index("## Selected projects looking for students")
    labs_pos = @content.index("## Research groups")

    refute_nil welcome_pos, "Expected '## Welcome' section in index.md"
    refute_nil news_pos, "Expected '## News &amp; updates' section in index.md"
    refute_nil projects_pos, "Expected '## Selected projects looking for students' section in index.md"
    refute_nil labs_pos, "Expected '## Research groups' section in index.md"

    assert projects_pos > welcome_pos, "Selected projects looking for students should appear after Welcome"
    assert news_pos > projects_pos, "News & updates should appear after Selected projects looking for students"
    assert labs_pos > news_pos, "Research groups should appear after News & updates"
    refute_includes @content, "carousel.html", "Homepage should not include carousel"
  end

  def test_news_cta_button_present
    assert_includes @content, "{{ '/news/' | relative_url }}", "Homepage should include a link to /news/"
    assert_includes @content, "All news &amp; updates", "Homepage should include 'All news & updates' button text"
  end

  def test_homepage_includes_project_card
    assert_includes @content, "project_card.html", "Homepage must use project_card.html"
  end

  def test_homepage_includes_inquiry_modal
    assert_includes @content, "pfcl-project-modal", "Homepage must include inquiry modal"
  end

  def test_project_section_uses_only_native_available_projects_and_is_fully_conditional
    assert_match(/available_projects.*where:.*published.*where:.*recruitment_status.*available/m, @content)
    assert_match(/available_projects.*where_exp:.*external.*!=\s*true/m, @content)
    condition = @content.index("{% if available_projects.size > 0 %}")
    heading = @content.index("## Selected projects looking for students")
    modal = @content.index("pfcl-project-modal")
    script = @content.index("assets/js/projects.js")
    closing = @content.index("{% endif %}", script)

    refute_nil condition
    assert_operator heading, :>, condition
    assert_operator modal, :>, condition
    assert_operator script, :>, condition
    assert_operator closing, :>, script
  end

  def test_welcome_buttons_removed
    refute_includes @content, "Available student projects", "Welcome CTA button 'Available student projects' should be removed"
  end

  def test_homepage_has_section_dividers
    divider_count = @content.scan('<hr class="pfcl-section-divider">').length
    assert_equal 3, divider_count, "Expected 3 section dividers separating the homepage sections"
  end
end
