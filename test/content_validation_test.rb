# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require_relative "../scripts/validate_content"

class ContentValidationTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir("pfcl-validate")
    FileUtils.mkdir_p(File.join(@dir, "_labs"))
    FileUtils.mkdir_p(File.join(@dir, "_team"))
    FileUtils.mkdir_p(File.join(@dir, "_projects"))
    FileUtils.mkdir_p(File.join(@dir, "_news"))
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def test_valid_collections_pass
    write "_labs/anpl.md", <<~YAML
      ---
      title: Autonomous Navigation and Perception Lab
      short_name: ANPL
      slug: anpl
      kind: research-group
      leader_names:
        - Vadim Indelman
      summary: "[Placeholder: one-paragraph summary]"
      website: https://anpl-technion.github.io/
      active: true
      order: 10
      ---
      body
    YAML
    write "_team/lead.md", <<~YAML
      ---
      title: Test Person
      slug: test-person
      role: Professor
      category: faculty
      lab_ids: [anpl]
      active: true
      order: 10
      ---
      body
    YAML
    write "_projects/p1.md", <<~YAML
      ---
      title: Test Project
      slug: test-project
      lab_ids: [anpl]
      recruitment_status: available
      project_type: research
      tags: [software]
      advisor_names: [Test Person]
      summary: "[Placeholder: summary]"
      contact_email: contact@technion.ac.il
      published: true
      updated_at: 2026-09-07
      featured: false
      show_on_showcase: true
      ---
      body
    YAML
    write "_news/n1.md", <<~YAML
      ---
      title: Test News
      date: 2026-09-07
      lab_id: anpl
      category: news
      excerpt: "[Placeholder: excerpt]"
      canonical_url: https://anpl-technion.github.io/item/
      source_name: ANPL
      featured: false
      show_on_showcase: true
      ---
      body
    YAML

    assert_empty validate
  end

  def test_document_without_body_is_valid
    write "_labs/nobody.md", <<~YAML
      ---
      title: No Body
      slug: no-body
      kind: research-group
      leader_names: [X]
      summary: s
      active: true
      order: 10
      ---
    YAML

    assert_empty validate
  end

  def test_missing_required_field_is_reported
    write "_team/no-role.md", <<~YAML
      ---
      title: Someone
      slug: someone
      category: faculty
      lab_ids: [pfcl]
      active: true
      order: 10
      ---
      body
    YAML

    errors = validate
    assert(errors.any? { |e| e.include?("_team/no-role.md") && e.include?("role") })
  end

  def test_unknown_enum_is_reported
    write "_labs/bad.md", <<~YAML
      ---
      title: Bad Lab
      slug: bad-lab
      kind: banana
      leader_names: [X]
      summary: s
      active: true
      order: 10
      ---
      body
    YAML

    assert(validate.any? { |e| e.include?("kind") && e.include?("banana") })
  end

  def test_duplicate_slug_is_reported
    2.times do |i|
      write "_labs/dup#{i}.md", <<~YAML
        ---
        title: Dup #{i}
        slug: duplicate-lab
        kind: research-group
        leader_names: [X]
        summary: s
        active: true
        order: 10
        ---
        body
      YAML
    end

    assert(validate.any? { |e| e.include?("duplicate slug") })
  end

  def test_unknown_lab_reference_is_reported
    write "_team/stray.md", <<~YAML
      ---
      title: Stray
      slug: stray
      role: Researcher
      category: research-staff
      lab_ids: [nonexistent]
      active: true
      order: 10
      ---
      body
    YAML

    assert(validate.any? { |e| e.include?("unknown lab_id") && e.include?("nonexistent") })
  end

  def test_available_project_requires_public_contact
    write "_projects/no-contact.md", <<~YAML
      ---
      title: No Contact
      slug: no-contact
      lab_ids: [pfcl]
      recruitment_status: available
      project_types: [software]
      student_levels: [masters]
      advisor_names: [X]
      summary: s
      contact_email: ""
      published: true
      updated_at: 2026-09-07
      featured: false
      show_on_showcase: true
      ---
      body
    YAML

    assert(validate.any? { |e| e.include?("available") && e.include?("contact") })
  end

  def test_invalid_dates_and_urls_are_reported
    write "_labs/badurl.md", <<~YAML
      ---
      title: Bad URL
      slug: bad-url
      kind: research-group
      leader_names: [X]
      summary: s
      website: ftp://not-a-web-url
      active: true
      order: 10
      ---
      body
    YAML
    write "_news/baddate.md", <<~YAML
      ---
      title: Bad Date
      date: 2026-02-31
      lab_id: pfcl
      category: news
      excerpt: s
      canonical_url: /news/
      source_name: PFCL
      featured: false
      show_on_showcase: true
      ---
      body
    YAML

    assert(validate.any? { |e| e.include?("website") && e.include?("ftp") })
    assert(validate.any? { |e| e.include?("date") })
  end

  def test_generated_updates_feed
    # missing file is fine
    assert_empty validate

    # empty array is fine
    write_json "_data/generated/updates.json", "[]"
    assert_empty validate

    # invalid JSON is an error
    write_json "_data/generated/updates.json", "{ nope"
    assert(validate.any? { |e| e.include?("updates.json") })

    # external item without canonical attribution is an error
    write_json "_data/generated/updates.json", <<~JSON
      [
        {
          "id": "x1",
          "title": "Item",
          "published_at": "2026-09-07T09:00:00Z",
          "lab_id": "anpl",
          "category": "news",
          "excerpt": "text",
          "canonical_url": "",
          "source_name": "",
          "image_url": null,
          "featured": false,
          "show_on_showcase": true,
          "display_weight": 1
        }
      ]
    JSON
    errors = validate
    assert(errors.any? { |e| e.include?("canonical_url") })

    # unknown lab in a feed item is an error
    write_json "_data/generated/updates.json", <<~JSON
      [
        {
          "id": "x1",
          "title": "Item",
          "published_at": "2026-09-07T09:00:00Z",
          "lab_id": "ghost-lab",
          "category": "news",
          "excerpt": "text",
          "canonical_url": "https://example.com/a/",
          "source_name": "Example",
          "image_url": null,
          "featured": false,
          "show_on_showcase": true,
          "display_weight": 1
        }
      ]
    JSON
    assert(validate.any? { |e| e.include?("unknown lab_id") })
  end

  def test_project_thumbnail_validation
    write "_projects/thumb-valid.md", <<~YAML
      ---
      title: Valid Thumb
      slug: valid-thumb
      lab_ids: [pfcl]
      recruitment_status: available
      project_type: research
      tags: [software]
      advisor_names: [X]
      thumbnail: /assets/images/projects/test.jpg
      summary: s
      contact_email: a@b.com
      published: true
      updated_at: 2026-09-07
      featured: false
      show_on_showcase: true
      ---
      body
    YAML
    assert_empty validate

    write "_projects/thumb-bad.md", <<~YAML
      ---
      title: Bad Thumb
      slug: bad-thumb
      lab_ids: [pfcl]
      recruitment_status: available
      project_type: research
      tags: [software]
      advisor_names: [X]
      thumbnail: invalid-path
      summary: s
      contact_email: a@b.com
      published: true
      updated_at: 2026-09-07
      featured: false
      show_on_showcase: true
      ---
      body
    YAML
    assert(validate.any? { |e| e.include?("thumbnail") && e.include?("invalid-path") })
  end

  def test_project_type_validation
    write "_projects/type-bad.md", <<~YAML
      ---
      title: Bad Type
      slug: bad-type
      lab_ids: [pfcl]
      recruitment_status: available
      project_type: software
      advisor_names: [X]
      summary: s
      contact_email: a@b.com
      published: true
      updated_at: 2026-09-07
      featured: false
      show_on_showcase: true
      ---
      body
    YAML
    errors = validate
    assert(errors.any? { |e| e.include?("project_type") })
  end

  def test_project_prerequisites_validation
    write "_projects/prereq-valid.md", <<~YAML
      ---
      title: Valid Prereq
      slug: prereq-valid
      lab_ids: [pfcl]
      recruitment_status: available
      project_type: research
      prerequisites: "Linear Systems (084733)"
      advisor_names: [X]
      summary: s
      contact_email: a@b.com
      published: true
      updated_at: 2026-09-07
      featured: false
      show_on_showcase: true
      ---
      body
    YAML
    assert_empty validate

    write "_projects/prereq-bad.md", <<~YAML
      ---
      title: Bad Prereq
      slug: prereq-bad
      lab_ids: [pfcl]
      recruitment_status: available
      project_type: research
      prerequisites: 12345
      advisor_names: [X]
      summary: s
      contact_email: a@b.com
      published: true
      updated_at: 2026-09-07
      featured: false
      show_on_showcase: true
      ---
      body
    YAML
    assert(validate.any? { |e| e.include?("prerequisites must be a string or list of strings") })
  end

  def test_project_duration_validation
    write "_projects/duration-valid.md", <<~YAML
      ---
      title: Valid Duration
      slug: duration-valid
      lab_ids: [pfcl]
      recruitment_status: available
      project_type: research
      duration: "1–2 Semesters"
      advisor_names: [X]
      summary: s
      contact_email: a@b.com
      published: true
      updated_at: 2026-09-07
      featured: false
      show_on_showcase: true
      ---
      body
    YAML
    assert_empty validate

    write "_projects/duration-bad.md", <<~YAML
      ---
      title: Bad Duration
      slug: duration-bad
      lab_ids: [pfcl]
      recruitment_status: available
      project_type: research
      duration: 123
      advisor_names: [X]
      summary: s
      contact_email: a@b.com
      published: true
      updated_at: 2026-09-07
      featured: false
      show_on_showcase: true
      ---
      body
    YAML
    assert(validate.any? { |e| e.include?("duration must be a string") })
  end

  def test_empty_and_valid_generated_catalogs_pass
    seed_anpl_lab
    write_json "_data/generated/updates.json", JSON.pretty_generate([valid_generated_update])
    write_json "_data/generated/publications.json", JSON.pretty_generate([valid_generated_publication])
    write_json "_data/generated/projects.json", JSON.pretty_generate([valid_generated_project])
    assert_empty validate

    %w[updates publications projects].each do |name|
      write_json "_data/generated/#{name}.json", "[]"
    end
    assert_empty validate
  end

  def test_generated_catalogs_reject_duplicate_ids_with_indexed_errors
    seed_anpl_lab
    records = {
      "updates" => valid_generated_update,
      "publications" => valid_generated_publication,
      "projects" => valid_generated_project
    }

    records.each do |name, record|
      write_json "_data/generated/#{name}.json", JSON.pretty_generate([record, record])
      errors = validate
      assert(errors.any? { |e| e.include?("#{name}.json[1]") && e.include?("duplicate id") }, name)
      write_json "_data/generated/#{name}.json", "[]"
    end
  end

  def test_generated_update_rejects_bad_attribution_url_lab_and_provenance
    seed_anpl_lab
    update = valid_generated_update.merge(
      "lab_id" => "ghost",
      "canonical_url" => "ftp://example.test/item",
      "source_name" => "",
      "provenance" => {}
    )
    write_json "_data/generated/updates.json", JSON.pretty_generate([update])

    errors = validate
    assert(errors.any? { |e| e.include?("updates.json[0]") && e.include?("unknown lab_id") })
    assert(errors.any? { |e| e.include?("updates.json[0]") && e.include?("canonical_url") })
    assert(errors.any? { |e| e.include?("updates.json[0]") && e.include?("source_name") })
    assert(errors.any? { |e| e.include?("updates.json[0]") && e.include?("provenance") })
  end

  def test_generated_updates_enforce_precision_and_sort_date_agreement
    seed_anpl_lab
    cases = [
      valid_generated_update.merge("date" => "2026-09", "published_at" => "2026-09-08"),
      valid_generated_update.merge("date_precision" => "month", "date" => "2026-09-01", "published_at" => "2026-09-08"),
      valid_generated_update.merge("date" => "2026-09-08", "published_at" => "2026-09-09T10:00:00Z")
    ]
    write_json "_data/generated/updates.json", JSON.pretty_generate(cases)

    errors = validate
    assert(errors.any? { |e| e.include?("updates.json[0]") && e.include?("YYYY-MM-DD") })
    assert(errors.any? { |e| e.include?("updates.json[1]") && e.include?("YYYY-MM") })
    assert(errors.any? { |e| e.include?("updates.json[2]") && e.include?("disagree") })
  end

  def test_generated_publications_reject_unknown_labs_missing_attribution_and_pdf_leakage
    seed_anpl_lab
    invalid = valid_generated_publication.merge(
      "lab_ids" => ["ghost"],
      "source_names" => [],
      "canonical_url" => "https://example.test/paper.pdf",
      "pdf" => "/Publications/paper.pdf",
      "provenance" => []
    )
    write_json "_data/generated/publications.json", JSON.pretty_generate([invalid])

    errors = validate
    assert(errors.any? { |e| e.include?("publications.json[0]") && e.include?("unknown lab_id") })
    assert(errors.any? { |e| e.include?("publications.json[0]") && e.include?("source_names") })
    assert(errors.any? { |e| e.include?("publications.json[0]") && e.include?("provenance") })
    assert(errors.any? { |e| e.include?("publications.json[0]") && e.include?("PDF") })
  end

  def test_generated_publications_reject_source_relative_publication_links
    seed_anpl_lab
    publication = valid_generated_publication.merge("source_url" => "/Publications/paper")
    write_json "_data/generated/publications.json", JSON.pretty_generate([publication])

    assert(validate.any? { |e| e.include?("publications.json[0]") && e.include?("PDF") })
  end

  def test_generated_projects_require_anpl_external_metadata_without_inferred_fields
    seed_anpl_lab
    invalid = valid_generated_project.merge(
      "external" => false,
      "lab_ids" => ["pfcl"],
      "recruitment_status" => "completed",
      "project_type" => "research",
      "contact_email" => "invented@example.test"
    )
    write_json "_data/generated/projects.json", JSON.pretty_generate([invalid])

    errors = validate
    assert(errors.any? { |e| e.include?("projects.json[0]") && e.include?("external") })
    assert(errors.any? { |e| e.include?("projects.json[0]") && e.include?("only ANPL") })
    assert(errors.any? { |e| e.include?("projects.json[0]") && e.include?("recruitment_status must be 'available'") })
    assert(errors.any? { |e| e.include?("projects.json[0]") && e.include?("inferred field") })
  end

  def test_external_project_handoffs_accept_only_the_minimal_schema_and_preserved_slugs
    seed_anpl_lab
    %w[autonomous-semantic-perception collaborative-aerial-navigation robust-risk-averse-decision-making].each do |slug|
      write "_projects/#{slug}.md", <<~YAML
        ---
        layout: project
        title: External project
        slug: #{slug}
        lab_ids: [anpl]
        external: true
        canonical_url: https://anpl-technion.github.io/student-projects/source/
        source_name: ANPL
        published: true
        ---
      YAML
    end

    assert_empty validate
  end

  def test_external_project_handoffs_reject_native_or_unapproved_fields
    seed_anpl_lab
    write "_projects/external.md", <<~YAML
      ---
      title: External project
      slug: external-project
      lab_ids: [anpl]
      external: true
      canonical_url: https://anpl-technion.github.io/student-projects/source/
      source_name: ANPL
      published: true
      recruitment_status: available
      contact_email: invented@example.test
      ---
    YAML

    errors = validate
    assert(errors.any? { |e| e.include?("_projects/external.md") && e.include?("not allowed") })
  end

  private

  def seed_anpl_lab
    write "_labs/anpl.md", <<~YAML
      ---
      title: Autonomous Navigation and Perception Lab
      slug: anpl
      kind: research-group
      leader_names: [Vadim Indelman]
      summary: Research group
      active: true
      order: 10
      ---
    YAML
  end

  def provenance
    {
      "repository" => "anpl-technion/anpl-technion.github.io",
      "lab_id" => "anpl",
      "source_name" => "ANPL",
      "revision" => "a" * 40,
      "source_path" => "source/item"
    }
  end

  def valid_generated_update
    {
      "id" => "anpl:x:1",
      "title" => "Update",
      "date" => "2026-09-08",
      "published_at" => "2026-09-08T10:00:00Z",
      "date_precision" => "day",
      "lab_id" => "anpl",
      "category" => "news",
      "excerpt" => "Summary",
      "canonical_url" => "https://example.test/update",
      "source_name" => "ANPL",
      "featured" => false,
      "show_on_showcase" => true,
      "display_weight" => 0,
      "provenance" => provenance
    }
  end

  def valid_generated_publication
    {
      "id" => "publication:doi:10.1000/test",
      "title" => "Publication",
      "authors" => ["Researcher, Ada"],
      "year" => 2026,
      "month" => 9,
      "date_precision" => "month",
      "publication_type" => "article",
      "canonical_url" => "https://doi.org/10.1000/test",
      "lab_ids" => ["anpl"],
      "source_names" => ["ANPL"],
      "provenance" => [provenance.merge("source_key" => "Test2026")]
    }
  end

  def valid_generated_project
    {
      "id" => "anpl:project:test",
      "slug" => "test",
      "title" => "Project",
      "summary" => "Summary",
      "lab_ids" => ["anpl"],
      "source_name" => "ANPL",
      "external" => true,
      "recruitment_status" => "available",
      "thumbnail" => "https://anpl-technion.github.io/image.png",
      "canonical_url" => "https://anpl-technion.github.io/student-projects/test/",
      "provenance" => provenance
    }
  end

  def validate
    validator = ContentValidator.new(@dir)
    validator.validate
    validator.errors
  end

  def write(rel, content)
    path = File.join(@dir, rel)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def write_json(rel, content)
    write(rel, content)
  end
end
