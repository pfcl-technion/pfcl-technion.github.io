# frozen_string_literal: true

require "minitest/autorun"
require "yaml"

class ProjectCardTest < Minitest::Test
  def setup
    @template = File.read(File.expand_path("../_includes/project_card.html", __dir__))
  end

  def test_card_elements
    assert_includes @template, "pfcl-project-card", "Must have pfcl-project-card class"
    assert_includes @template, "pfcl-project-thumb", "Must have thumbnail"
    assert_includes @template, "p.url", "Must link to project detail page"
    assert_includes @template, "pfcl-project-tags", "Must have tags"
    assert_includes @template, "p.project_type", "Must render project_type"
    assert_includes @template, "p.duration", "Must render duration tag when provided"
    refute_includes @template, "student_levels", "Must not reference student_levels"
    assert_includes @template, "data-inquiry-btn", "Must have inquiry trigger"
  end

  def test_external_card_uses_attributed_source_links_without_invented_recruitment_data
    assert_includes @template, "if p.external"
    external_branch = @template[/\{%\s*if p\.external\s*%\}(.*?)\{%\s*else\s*%\}/m, 1].to_s

    external_branch = @template.split(/\{%\s*else\s*%\}\s*<div class="card pfcl-card pfcl-project-card">/, 2).first
    assert_operator external_branch.scan("p.canonical_url").length, :>=, 3
    assert_match(/target=["']_blank["']/, external_branch)
    assert_match(/rel=["']noopener noreferrer["']/, external_branch)
    assert_includes external_branch, "ANPL listing"
    assert_includes external_branch, "View on ANPL"
    %w[p.title p.summary advisor_name tag].each do |expression|
      assert_match(/#{Regexp.escape(expression)}.*\|\s*escape/, external_branch, expression)
    end
    refute_includes external_branch, "pfcl-project-status"
    refute_includes external_branch, "data-inquiry-btn"
    refute_includes external_branch, "site.email"
  end

  def test_native_branch_keeps_detail_and_inquiry_actions
    native_branch = @template[/\{%\s*else\s*%\}(.*?)\{%\s*endif\s*%\}\s*\z/m, 1].to_s

    assert_includes native_branch, "p.url"
    assert_includes native_branch, "pfcl-project-status"
    assert_includes native_branch, "data-inquiry-btn"
  end

  def test_external_advisor_alias_resolves_vadim_to_his_pfcl_team_profile
    aliases = YAML.safe_load_file(File.expand_path("../_data/external_advisor_aliases.yml", __dir__), aliases: false)
    assert_equal "vadim-indelman", aliases.fetch("vadim indelman")

    external_branch = @template[/\{%\s*if p\.external\s*%\}(.*?)\{%\s*else\s*%\}/m, 1].to_s
    external_branch = @template.split(/\{%\s*else\s*%\}\s*<div class="card pfcl-card pfcl-project-card">/, 2).first
    assert_includes external_branch, "site.data.external_advisor_aliases"
    assert_includes external_branch, "advisor_member.photo"
    assert_includes external_branch, "pfcl-project-supervisor"
    assert_includes external_branch, "pfcl-supervisor-avatar-placeholder"
  end
end
