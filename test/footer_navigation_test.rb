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

  private

  def footer_link(navigation_item)
    {
      "name" => navigation_item.fetch("name"),
      "url" => navigation_item.fetch("link")
    }
  end
end
