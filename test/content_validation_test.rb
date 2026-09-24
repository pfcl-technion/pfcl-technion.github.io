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
      project_types: [research]
      student_levels: [undergraduate]
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
      project_types: [software]
      student_levels: [masters]
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
      project_types: [software]
      student_levels: [masters]
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

  private

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
