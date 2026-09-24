# frozen_string_literal: true

require "minitest/autorun"

class HomepageTest < Minitest::Test
  def setup
    @content = File.read(File.expand_path("../index.md", __dir__))
  end

  def test_homepage_section_ordering
    welcome_pos = @content.index("## Welcome")
    carousel_pos = @content.index("{% include carousel.html %}")
    news_pos = @content.index("## News &amp; updates")
    labs_pos = @content.index("## Research groups")
    projects_pos = @content.index("## Selected student projects")

    refute_nil welcome_pos, "Expected '## Welcome' section in index.md"
    refute_nil carousel_pos, "Expected carousel include in index.md"
    refute_nil news_pos, "Expected '## News &amp; updates' section in index.md"
    refute_nil labs_pos, "Expected '## Research groups' section in index.md"
    refute_nil projects_pos, "Expected '## Selected student projects' section in index.md"

    assert carousel_pos > welcome_pos, "Carousel should appear after Welcome"
    assert news_pos > carousel_pos, "News & updates should appear after Carousel"
    assert labs_pos > news_pos, "Research groups should appear after News & updates"
    assert projects_pos > labs_pos, "Selected student projects should appear after Research groups"
  end

  def test_news_cta_button_present
    assert_includes @content, "{{ '/news/' | relative_url }}", "Homepage should include a link to /news/"
    assert_includes @content, "All news &amp; updates", "Homepage should include 'All news & updates' button text"
  end
end
