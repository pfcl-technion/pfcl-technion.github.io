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

  def test_page_merges_native_and_generated_projects_without_handoff_duplicates
    assert_match(/site\.projects.*where_exp:.*external.*!=\s*true/m, @content)
    assert_includes @content, "site.data.generated.projects"
    assert_includes @content, "concat"
    assert_match(/include project_filters\.html projects=projects/, @content)
    assert_match(/data-status=["']\{\{ project\.recruitment_status \| default: ['\"]{2}/, @content)
    assert_match(/data-type=["']\{\{ project\.project_type \| default: ['\"]{2}/, @content)
    refute_match(/data-project-card[^>]*(?:hidden|is-hidden)/m, @content)
  end
end
