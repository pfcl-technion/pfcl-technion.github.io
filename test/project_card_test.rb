# frozen_string_literal: true

require "minitest/autorun"

class ProjectCardTest < Minitest::Test
  def setup
    @template = File.read(File.expand_path("../_includes/project_card.html", __dir__))
  end

  def test_card_elements
    assert_includes @template, "pfcl-project-card", "Must have pfcl-project-card class"
    assert_includes @template, "pfcl-project-thumb", "Must have thumbnail"
    assert_includes @template, "p.url", "Must link to project detail page"
    assert_includes @template, "pfcl-project-tags", "Must have tags"
    assert_includes @template, "data-inquiry-btn", "Must have inquiry trigger"
  end
end
