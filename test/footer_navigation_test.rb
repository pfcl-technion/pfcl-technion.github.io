# frozen_string_literal: true

require "minitest/autorun"
require "yaml"

class FooterNavigationTest < Minitest::Test
  def setup
    data_dir = File.expand_path("../_data", __dir__)
    @navigation = YAML.safe_load_file(File.join(data_dir, "navigation.yml"))
    @footer = YAML.safe_load_file(File.join(data_dir, "footer.yml"))
  end

  def test_footer_menus_follow_primary_navigation
    about_index = @navigation.index { |item| item["name"] == "About" }
    about = @navigation.fetch(about_index)

    expected_menus = [
      {
        "title" => "Explore",
        "links" => @navigation.first(about_index).map { |item| footer_link(item) }
      },
      {
        "title" => "About",
        "links" => [footer_link(about).merge("name" => "About PFCL")] +
          about.fetch("dropdown").map { |item| footer_link(item) }
      }
    ]

    assert_equal expected_menus, @footer.fetch("menus")
  end

  def test_publications_follows_research_groups_in_both_navigation_menus
    research_index = @navigation.index { |item| item["name"] == "Research Groups" }
    assert_equal(
      { "name" => "Publications", "link" => "/publications/" },
      @navigation.fetch(research_index + 1)
    )

    explore = @footer.fetch("menus").find { |menu| menu["title"] == "Explore" }
    footer_research_index = explore.fetch("links").index { |item| item["name"] == "Research Groups" }
    assert_equal(
      { "name" => "Publications", "url" => "/publications/" },
      explore.fetch("links").fetch(footer_research_index + 1)
    )
  end

  private

  def footer_link(navigation_item)
    {
      "name" => navigation_item.fetch("name"),
      "url" => navigation_item.fetch("link")
    }
  end
end
