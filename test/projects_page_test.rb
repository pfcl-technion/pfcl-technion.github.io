# frozen_string_literal: true

require "minitest/autorun"

class ProjectsPageTest < Minitest::Test
  def setup
    @content = File.read(File.expand_path("../projects.md", __dir__))
  end

  def test_projects_page_structure
    assert_includes @content, "project_card.html", "projects.md must use project_card.html"
    assert_includes @content, "pfcl-project-modal", "projects.md must have inquiry modal"
    assert_includes @content, "data-modal-close", "Modal must have close triggers"
  end
end
