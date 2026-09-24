# frozen_string_literal: true

require "minitest/autorun"

class ProjectLayoutTest < Minitest::Test
  def setup
    @template = File.read(File.expand_path("../_layouts/project.html", __dir__))
  end

  def test_project_layout_elements
    assert_includes @template, "pfcl-project-detail-hero", "Must include hero section"
    assert_includes @template, "pfcl-project-detail-meta", "Must include metadata panel"
    assert_includes @template, "pfcl-project-status", "Must include status indicator"
    assert_includes @template, "data-inquiry-btn", "Must include inquiry trigger button"
    assert_includes @template, "{{ content }}", "Must render page content"
  end
end
