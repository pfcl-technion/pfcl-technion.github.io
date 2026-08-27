require "minitest/autorun"
require_relative "../scripts/validate_content"

class ContentValidationTest < Minitest::Test
  def setup
    @root_dir = File.expand_path("..", __dir__)
    @validator = ContentValidator.new(@root_dir)
  end

  def test_real_workspace_content_is_valid
    errors = @validator.validate_all
    assert_empty errors, "Workspace content contains validation errors:\n#{errors.join("\n")}"
  end

  def test_missing_required_field_in_lab_fails
    data = { "title" => "Lab Without Slug", "short_name" => "LWS", "kind" => "research-group", "active" => true, "order" => 1 }
    errors = @validator.validate_lab_data(data, "fake_lab.md", ["fake-lab"])
    assert errors.any? { |e| e.include?("missing required field 'slug'") }
  end

  def test_invalid_lab_kind_fails
    data = { "title" => "Lab", "short_name" => "L", "slug" => "lab", "kind" => "invalid-kind", "leader_names" => ["A"], "summary" => "S", "website" => "https://example.com", "active" => true, "order" => 1 }
    errors = @validator.validate_lab_data(data, "fake_lab.md", ["lab"])
    assert errors.any? { |e| e.include?("invalid kind 'invalid-kind'") }
  end

  def test_unknown_lab_id_in_team_fails
    data = { "title" => "Person", "slug" => "person", "role" => "Researcher", "category" => "faculty", "lab_ids" => ["nonexistent-lab"], "active" => true, "order" => 1 }
    errors = @validator.validate_team_data(data, "fake_person.md", ["person"], ["anpl", "pfcl"])
    assert errors.any? { |e| e.include?("references unknown lab_id 'nonexistent-lab'") }
  end

  def test_available_project_without_contact_email_fails
    data = {
      "title" => "Project Without Contact",
      "slug" => "proj-no-contact",
      "lab_ids" => ["anpl"],
      "recruitment_status" => "available",
      "project_types" => ["research"],
      "student_levels" => ["undergraduate"],
      "advisor_names" => ["Advisor"],
      "summary" => "Summary",
      "published" => true,
      "updated_at" => "2026-08-27",
      "featured" => false,
      "show_on_showcase" => true
    }
    errors = @validator.validate_project_data(data, "proj.md", [], ["anpl"])
    assert errors.any? { |e| e.include?("available project must have 'contact_email'") }
  end

  def test_multi_lab_project_with_valid_labs_passes
    data = {
      "title" => "Multi Lab Project",
      "slug" => "multi-lab-proj",
      "lab_ids" => ["anpl", "connect"],
      "recruitment_status" => "available",
      "project_types" => ["research"],
      "student_levels" => ["undergraduate"],
      "advisor_names" => ["Advisor"],
      "summary" => "Summary",
      "contact_email" => "advisor@technion.ac.il",
      "published" => true,
      "updated_at" => "2026-08-27",
      "featured" => false,
      "show_on_showcase" => true
    }
    errors = @validator.validate_project_data(data, "proj.md", [], ["anpl", "connect"])
    assert_empty errors
  end

  def test_empty_generated_updates_passes
    errors = @validator.validate_generated_updates([])
    assert_empty errors
  end

  def test_invalid_generated_updates_item_fails
    bad_items = [{ "title" => "No ID or URL" }]
    errors = @validator.validate_generated_updates(bad_items)
    refute_empty errors
  end
end
