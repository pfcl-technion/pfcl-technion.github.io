# PFCL Website v2 Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the PFCL website from scratch on branch `v2-rebuild` — Jekyll + bulma-clean-theme styled after ANPL, WordPress-style data-driven footer, real names/titles only, bracketed placeholders everywhere else.

**Architecture:** Jekyll 4.3 static site using the `bulma-clean-theme` 1.3.1 gem (no vendoring); site-level overrides in `_layouts/`, `_includes/`, `_sass/`. Collections (`_labs`, `_team`, `_projects`, `_news`) are data-only (`output: false`); pages render directory views. A standalone Ruby validator + minitest suite gate CI; development runs in Docker (Ruby 3.3, Bookworm).

**Tech Stack:** Jekyll 4.3.x, bulma-clean-theme 1.3.1, Liquid, Sass, vanilla JS (progressive enhancement), Ruby minitest, Docker/compose, GitHub Actions → GitHub Pages.

**Spec:** `docs/superpowers/specs/2026-09-07-pfcl-website-v2-rebuild-design.md` (amends `docs/superpowers/specs/2026-08-27-pfcl-website-foundation-design.md`, which stays normative for schemas, IA, validation, deployment, boundaries)

## Global Constraints

- Branch: `v2-rebuild` (orphan). Never touch DNS, Pages settings, or `pfcl.technion.ac.il`.
- URL: `https://philadelphia-flight-control-laboratory.github.io`, baseurl `/pfcl-technion.github.io`.
- Jekyll `~> 4.3`, `bulma-clean-theme ~> 1.3.1` — as gems, never vendored.
- No fabricated content: real names/titles/course numbers/contact details only; everything else as `[Descriptive placeholder — …]` markers. No invented emails, phones, dates, bios, URLs.
- `references/` stays untracked (gitignored, excluded from Jekyll).
- Never read/link the internal Obsidian vault; never hand-edit `_data/generated/updates.json`.
- Attribution: a constituent lab's material is never presented as PFCL-authored; imported items keep `canonical_url` + `source_name`.
- Collection schemas exactly per the 2026-08-27 spec (field names/enum values below are normative):
  - `_labs` required: `title, slug, kind, leader_names, summary, active, order`; `kind ∈ {research-group, teaching-lab, shared-facility}`; optional `short_name, logo, hero_image, email, website, research_topics`.
  - `_team` required: `title, slug, role, category, lab_ids, active, order`; `category ∈ {leadership, faculty, research-staff, lab-staff, visiting, emeritus}`; optional `image, email, phone, website, bio`.
  - `_projects` required: `title, slug, lab_ids, recruitment_status, project_types, student_levels, advisor_names, summary, contact_email, published, updated_at, featured, show_on_showcase`; `recruitment_status ∈ {available, ongoing, completed}`; `project_types ⊆ {research, experimental, software, hardware, teaching}`; `student_levels ⊆ {undergraduate, masters, phd}`; optional `image, skills, duration, application_url, canonical_url, display_weight`.
  - `_news` required: `title, date, lab_id, category, excerpt, canonical_url, source_name, featured, show_on_showcase`; `category ∈ {news, event, publication, project, award, position, research-highlight}`.
  - `lab_ids` values must be an existing `_labs` slug or the reserved `pfcl`.
- Slugs: lowercase ASCII `^[a-z0-9]+(-[a-z0-9]+)*$`, unique per collection.
- Slugs/content stable identifiers are preserved once created.
- Accessibility: WCAG 2.2 AA, keyboard navigable, works without JS, `prefers-reduced-motion` respected.
- Docker is the dev environment; all verification commands run through `docker compose run --rm site …`.
- Commits: conventional-commit style, end message body with `Co-Authored-By: Claude Code <noreply@anthropic.com>`.

**Execution note (2026-09-07):** user waived review checkpoints — proceed through all tasks without pausing for approval. Final deliverable: pushed branch + draft PR (do **not** merge).

---

### Task 1: Repository foundation and first green build

**Files:**
- Create: `.gitignore`, `Gemfile`, `Dockerfile`, `compose.yml`, `.devcontainer/devcontainer.json`, `_config.yml`, `assets/css/app.scss`, `_sass/pfcl.scss`, `index.md` (temporary minimal)
- Produced for later tasks: working Docker toolchain; `_config.yml` keys consumed everywhere; `assets/css/app.scss` sass entry.

**Interfaces:**
- Produces: `_config.yml` with `url`, `baseurl`, collections config, `exclude` list; sass entry that later tasks append to (`_sass/pfcl.scss`).

- [ ] **Step 1: Create `.gitignore`**

```gitignore
_site/
.sass-cache/
.jekyll-cache/
.jekyll-metadata
vendor/
.bundle/
node_modules/
.DS_Store
*.log
.claude/
references/
```

- [ ] **Step 2: Create `Gemfile`**

```ruby
source "https://rubygems.org"

ruby ">= 3.2.0"

gem "jekyll", "~> 4.3.4"
gem "bulma-clean-theme", "~> 1.3.1"
gem "webrick", "~> 1.8"

group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.17"
  gem "jekyll-seo-tag", "~> 2.8"
  gem "jekyll-sitemap", "~> 1.4"
end

group :test do
  gem "minitest", "~> 5.20"
end
```

- [ ] **Step 3: Create `Dockerfile`**

```dockerfile
FROM ruby:3.3-slim-bookworm

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends build-essential git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /site

ENV BUNDLE_PATH=/bundle

RUN gem install bundler

EXPOSE 4000

CMD ["sh", "-c", "bundle check || bundle install && bundle exec jekyll serve --host 0.0.0.0 --port 4000 --livereload"]
```

- [ ] **Step 4: Create `compose.yml`**

```yaml
services:
  site:
    build: .
    ports:
      - "4000:4000"
    volumes:
      - .:/site
      - bundle_cache:/bundle
volumes:
  bundle_cache:
```

- [ ] **Step 5: Create `.devcontainer/devcontainer.json`**

```json
{
  "name": "PFCL Website",
  "dockerComposeFile": ["../compose.yml"],
  "service": "site",
  "workspaceFolder": "/site",
  "overrideCommand": true,
  "postStartCommand": "bundle check || bundle install",
  "forwardPorts": [4000],
  "customizations": {
    "vscode": {
      "extensions": ["shopify.ruby-lsp", "DavidAnson.vscode-markdownlint"]
    }
  }
}
```

- [ ] **Step 6: Create `_config.yml`**

```yaml
title: Philadelphia Flight Control Laboratory
tagline: Faculty of Aerospace Engineering, Technion
description: >-
  [Placeholder: one-to-two sentence site description for search engines about
  the Philadelphia Flight Control Laboratory.]
lang: en
email: pfcl@technion.ac.il

url: https://philadelphia-flight-control-laboratory.github.io
baseurl: /pfcl-technion.github.io
permalink: pretty

theme: bulma-clean-theme

fixed_navbar: top
theme_color: '#eeeeee'
favicon: /assets/images/PFCL-2.png
hide_share_buttons: true

plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap

markdown: kramdown
kramdown:
  input: GFM
  hard_wrap: false

sass:
  style: compressed
  source_dir: _sass

collections:
  labs:
    output: false
  team:
    output: false
  projects:
    output: false
  news:
    output: false

defaults:
  - scope:
      path: ""
      type: "pages"
    values:
      layout: "page"
      show_sidebar: false

exclude:
  - Gemfile
  - Gemfile.lock
  - Dockerfile
  - compose.yml
  - .devcontainer
  - scripts
  - test
  - docs
  - references
  - AGENTS.md
  - README.md
  - vendor
  - node_modules
```

- [ ] **Step 7: Create `assets/css/app.scss`**

```scss
---
---

// Theme base (imports Bulma + theme partials from the gem)
@import "main";
// PFCL overrides
@import "pfcl";
```

- [ ] **Step 8: Create `_sass/pfcl.scss`** (starter; later tasks append)

```scss
// PFCL custom styles (v2 rebuild). Imported after the theme's main.scss,
// so Bulma variables ($light, $border, $grey-light, $primary) are in scope.

.pfcl-navbar-title {
  font-weight: 600;
  margin-left: 0.5rem;
  white-space: nowrap;
}

.pfcl-placeholder {
  background: $light;
  border: 1px dashed $border;
  border-radius: 0.25rem;
  padding: 0.75rem 1rem;
  color: $grey-light;
}
```

- [ ] **Step 9: Create temporary `index.md`**

```markdown
---
layout: page
title: Home
---

[Placeholder: PFCL homepage — full section structure is built in Task 5.]
```

- [ ] **Step 10: Build and verify**

Run: `docker compose run --rm site sh -c "bundle check || bundle install"`
Run: `docker compose run --rm site bundle exec jekyll build --trace`
Expected: build succeeds; `_site/index.html` exists; commit the generated `Gemfile.lock`.

- [ ] **Step 11: Commit**

```bash
git add .gitignore Gemfile Gemfile.lock Dockerfile compose.yml .devcontainer _config.yml assets _sass index.md
git commit -m "feat: v2 foundation — docker toolchain, jekyll config, sass entry"
```

---

### Task 2: Content validator (TDD)

**Files:**
- Create: `scripts/validate_content.rb`
- Test: `test/content_validation_test.rb`

**Interfaces:**
- Produces: class `ContentValidator` — `ContentValidator.new(site_dir)` → `#validate` returns self, `#errors` returns `Array<String>` like `_labs/anpl.md: missing required field 'summary'`; exit code 1 when errors exist. Used by CI (Task 6) and every later task's verification.

- [ ] **Step 1: Write the failing tests**

Create `test/content_validation_test.rb`:

```ruby
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

    # a fully valid external item passes (lab anpl exists in this fixture? no —
    # so also assert lab check fires when only the lab is wrong)
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
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb`
Expected: LoadError — no such file `scripts/validate_content`.

- [ ] **Step 3: Implement `scripts/validate_content.rb`**

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# Validates PFCL collection frontmatter and generated update data.
# Usage: ruby scripts/validate_content.rb [site_dir]
# Exits 1 and prints one "ERROR <file>: <problem>" line per problem.

require "yaml"
require "json"
require "date"

class ContentValidator
  REQUIRED_FIELDS = {
    "labs" => %w[title slug kind leader_names summary active order],
    "team" => %w[title slug role category lab_ids active order],
    "projects" => %w[title slug lab_ids recruitment_status project_types student_levels
                    advisor_names summary contact_email published updated_at featured show_on_showcase],
    "news" => %w[title date lab_id category excerpt canonical_url source_name featured show_on_showcase]
  }.freeze

  LAB_KINDS = %w[research-group teaching-lab shared-facility].freeze
  TEAM_CATEGORIES = %w[leadership faculty research-staff lab-staff visiting emeritus].freeze
  RECRUITMENT_STATUSES = %w[available ongoing completed].freeze
  PROJECT_TYPES = %w[research experimental software hardware teaching].freeze
  STUDENT_LEVELS = %w[undergraduate masters phd].freeze
  NEWS_CATEGORIES = %w[news event publication project award position research-highlight].freeze
  RESERVED_LAB_ID = "pfcl"
  UPDATE_REQUIRED_KEYS = %w[id title published_at lab_id category excerpt canonical_url
                            source_name featured show_on_showcase display_weight].freeze

  SLUG_RE = /\A[a-z0-9]+(-[a-z0-9]+)*\z/.freeze
  DATE_RE = /\A\d{4}-\d{2}-\d{2}\z/.freeze

  attr_reader :errors

  def initialize(site_dir)
    @site_dir = site_dir
    @errors = []
    @lab_slugs = []
  end

  def validate
    # First pass: labs, to learn the known lab slugs for lab_ids checks.
    validate_collection("labs")
    known_labs = @lab_slugs + [RESERVED_LAB_ID]
    validate_collection("team", known_labs)
    validate_collection("projects", known_labs)
    validate_collection("news", known_labs)
    validate_updates(known_labs)
    self
  end

  private

  def validate_collection(name, known_labs = nil)
    dir = File.join(@site_dir, "_#{name}")
    return unless Dir.exist?(dir)

    slugs = {}
    Dir.glob(File.join(dir, "**", "*.md")).sort.each do |path|
      rel = relative_path(path)
      doc = read_document(path, rel)
      next unless doc

      fields = doc
      REQUIRED_FIELDS[name].each do |field|
        error(rel, "missing required field '#{field}'") unless present?(fields[field])
      end

      slug = fields["slug"].to_s
      if present?(fields["slug"]) && slug !~ SLUG_RE
        error(rel, "slug '#{slug}' must be lowercase ASCII letters, digits, hyphens")
      end
      if slugs.key?(slug)
        error(rel, "duplicate slug '#{slug}' (also in #{slugs[slug]})")
      else
        slugs[slug] = rel
      end
      @lab_slugs << slug if name == "labs"

      case name
      when "labs"
        check_enum(rel, fields, "kind", LAB_KINDS)
        check_string_list(rel, fields, "leader_names")
        check_url(rel, fields, "website")
      when "team"
        check_enum(rel, fields, "category", TEAM_CATEGORIES)
        check_string_list(rel, fields, "lab_ids", known_labs)
      when "projects"
        check_enum(rel, fields, "recruitment_status", RECRUITMENT_STATUSES)
        check_string_list(rel, fields, "lab_ids", known_labs)
        check_string_list(rel, fields, "project_types", PROJECT_TYPES)
        check_string_list(rel, fields, "student_levels", STUDENT_LEVELS)
        check_string_list(rel, fields, "advisor_names")
        check_url(rel, fields, "application_url")
        check_url(rel, fields, "canonical_url")
        check_date(rel, fields, "updated_at")
        if fields["recruitment_status"] == "available" &&
           !present?(fields["contact_email"]) && !present?(fields["application_url"])
          error(rel, "available project needs a public contact path (contact_email or application_url)")
        end
      when "news"
        check_enum(rel, fields, "category", NEWS_CATEGORIES)
        check_lab_id(rel, fields, "lab_id", known_labs)
        check_date(rel, fields, "date")
        check_canonical(rel, fields)
      end
    end
  end

  def validate_updates(known_labs)
    path = File.join(@site_dir, "_data", "generated", "updates.json")
    return unless File.exist?(path)

    rel = relative_path(path)
    begin
      items = JSON.parse(File.read(path))
    rescue JSON::ParserError => e
      error(rel, "invalid JSON: #{e.message}")
      return
    end
    return error(rel, "expected an array, got #{items.class}") unless items.is_a?(Array)

    items.each_with_index do |item, i|
      prefix = "#{rel}[#{i}]"
      UPDATE_REQUIRED_KEYS.each do |key|
        error(prefix, "missing required key '#{key}'") unless item.key?(key)
      end
      next unless item.is_a?(Hash)

      lab_id = item["lab_id"].to_s
      unless known_labs.include?(lab_id)
        error(prefix, "unknown lab_id '#{lab_id}'")
      end
      unless valid_url?(item["canonical_url"])
        error(prefix, "canonical_url must be an http(s) URL")
      end
      if lab_id != RESERVED_LAB_ID && !present?(item["source_name"])
        error(prefix, "imported item needs source_name attribution")
      end
      begin
        DateTime.parse(item["published_at"].to_s)
      rescue Date::Error, ArgumentError, TypeError
        error(prefix, "published_at must be ISO-8601")
      end
      unless item["display_weight"].is_a?(Numeric)
        error(prefix, "display_weight must be numeric")
      end
    end
  end

  def read_document(path, rel)
    content = File.read(path, encoding: "UTF-8")
    unless content.start_with?("---")
      error(rel, "missing YAML frontmatter")
      return nil
    end
    parts = content.split(/^---\s*$/)
    return error(rel, "unterminated YAML frontmatter") if parts.length < 3

    begin
      fields = YAML.safe_load(parts[1], permitted_classes: [Date], aliases: false) || {}
    rescue Psych::SyntaxError => e
      error(rel, "invalid YAML: #{e.message}")
      return nil
    end
    fields.is_a?(Hash) ? fields : (error(rel, "frontmatter must be a mapping"); nil)
  end

  def check_enum(rel, fields, field, allowed)
    value = fields[field]
    return unless present?(value)

    error(rel, "#{field} '#{value}' not allowed (use one of: #{allowed.join(', ')})") unless allowed.include?(value.to_s)
  end

  def check_string_list(rel, fields, field, allowed_values = nil)
    value = fields[field]
    return unless value.is_a?(Array)

    value.each do |entry|
      unless entry.is_a?(String) && !entry.strip.empty?
        error(rel, "#{field} entries must be non-empty strings")
        next
      end
      if allowed_values && !allowed_values.include?(entry)
        error(rel, "unknown lab_id '#{entry}'") if field == "lab_ids"
        error(rel, "#{field} entry '#{entry}' not allowed") if field != "lab_ids" && !allowed_values.include?(entry)
      end
    end
  end

  def check_lab_id(rel, fields, field, known_labs)
    value = fields[field]
    return unless present?(value)

    error(rel, "unknown lab_id '#{value}'") unless known_labs.include?(value.to_s)
  end

  def check_url(rel, fields, field)
    value = fields[field]
    return unless present?(value)

    error(rel, "#{field} must be an http(s) URL") unless valid_url?(value)
  end

  def check_date(rel, fields, field)
    value = fields[field]
    return unless present?(value)

    return error(rel, "#{field} must be formatted YYYY-MM-DD") if value.to_s !~ DATE_RE

    Date.parse(value.to_s)
  rescue ArgumentError
    error(rel, "#{field} '#{value}' is not a real calendar date")
  end

  def check_canonical(rel, fields)
    value = fields["canonical_url"]
    return unless present?(value)

    local_ok = fields["lab_id"].to_s == RESERVED_LAB_ID && value.to_s.start_with?("/")
    error(rel, "canonical_url must be an http(s) URL (or a local /path for lab_id 'pfcl')") unless local_ok || valid_url?(value)
  end

  def valid_url?(value)
    value.is_a?(String) && value.match?(%r{\Ahttps?://\S+\z})
  end

  def present?(value)
    !(value.nil? || value.to_s.strip.empty?)
  end

  def error(rel, message)
    @errors << "#{rel}: #{message}"
  end

  def relative_path(path)
    path.delete_prefix("#{@site_dir}/")
  end
end

if $PROGRAM_NAME == __FILE__
  validator = ContentValidator.new(ARGV[0] || ".")
  validator.validate
  if validator.errors.empty?
    puts "Content validation passed."
  else
    validator.errors.each { |e| warn "ERROR #{e}" }
    warn "#{validator.errors.size} content validation error(s)."
    exit 1
  end
end
```

- [ ] **Step 4: Run tests, verify they pass**

Run: `docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb`
Expected: `0 failures, 0 errors, 0 skips` (8 tests). Fix implementation issues if any test fails — do not weaken assertions.

- [ ] **Step 5: Run validator against the site (should pass with no collections yet)**

Run: `docker compose run --rm site bundle exec ruby scripts/validate_content.rb`
Expected: `Content validation passed.`

- [ ] **Step 6: Commit**

```bash
git add scripts/validate_content.rb test/content_validation_test.rb
git commit -m "feat: content validator with full test suite (TDD)"
```

---

### Task 3: Data files and seed collections

**Files:**
- Create: `_data/navigation.yml`, `_data/taxonomies.yml`, `_data/footer.yml`, `_data/generated/updates.json`
- Create: `_labs/anpl.md`, `_labs/connect.md`, `_labs/casy.md`, `_labs/idan-group.md`, `_labs/ben-asher-group.md`, `_labs/oshman-group.md`, `_labs/flight-control-teaching-lab.md`
- Create: `_team/daniel-zelazo.md`, `_team/vadim-indelman.md`, `_team/tal-shima.md`, `_team/moshe-idan.md`, `_team/yossi-ben-asher.md`, `_team/yaakov-oshman.md`, `_team/ruslan-arhipov.md`, `_team/arthur-grunwald.md`
- Create: `_news/2026-09-07-welcome-to-the-new-pfcl-website.md`

**Interfaces:**
- Consumes: validator from Task 2.
- Produces: `site.data.navigation` (theme navbar format: top-level list of `{name, link, dropdown: [{name, link}]}`); `site.data.footer` (`{menus: [{title, links: [{name, url}]}], contact: {email, phone, youtube}, logos_heading, logos: [{name, url, image}], copyright}`); `site.data.taxonomies.team_categories` (`[{id, label}]`); `site.labs`, `site.team`, `site.news` documents consumed by Task 4/5 includes. Lab slugs: `anpl, connect, casy, idan-group, ben-asher-group, oshman-group, flight-control-teaching-lab`.

- [ ] **Step 1: Create `_data/navigation.yml`**

```yaml
- name: Home
  link: /
- name: About
  link: /about/
  dropdown:
    - name: About PFCL
      link: /about/
    - name: History
      link: /history/
    - name: PFCL Dedication
      link: /dedication/
    - name: Team
      link: /team/
- name: Research Groups
  link: /labs/
- name: Student Projects
  link: /projects/
- name: Teaching Labs
  link: /teaching/
- name: News
  link: /news/
- name: Media
  link: /media/
- name: Contact
  link: /contact/
```

- [ ] **Step 2: Create `_data/taxonomies.yml`**

```yaml
team_categories:
  - id: leadership
    label: Leadership
  - id: faculty
    label: Faculty
  - id: research-staff
    label: Research Staff
  - id: lab-staff
    label: Lab Staff
  - id: visiting
    label: Visiting
  - id: emeritus
    label: Emeritus
```

- [ ] **Step 3: Create `_data/footer.yml`**

```yaml
menus:
  - title: About
    links:
      - name: About PFCL
        url: /about/
      - name: History
        url: /history/
      - name: PFCL Dedication
        url: /dedication/
      - name: Team
        url: /team/
  - title: Research & Teaching
    links:
      - name: Research Groups
        url: /labs/
      - name: Teaching Labs
        url: /teaching/
      - name: News
        url: /news/
      - name: Media
        url: /media/
  - title: For Students
    links:
      - name: Student Projects
        url: /projects/
      - name: Contact
        url: /contact/

contact:
  email: pfcl@technion.ac.il
  phone: "+972-4-829-3820"
  youtube: "" # [Placeholder: YouTube channel URL — supply before enabling]

logos_heading: Partners

logos:
  - name: Technion - Israel Institute of Technology
    url: https://www.technion.ac.il/
    image: # [Placeholder: logo image path once asset is supplied]
  - name: Faculty of Aerospace Engineering
    url: https://aerospace.technion.ac.il/
    image: # [Placeholder: logo image path once asset is supplied]

copyright: "© 2026 Philadelphia Flight Control Laboratory — Technion"
```

- [ ] **Step 4: Create `_data/generated/updates.json`**

```json
[]
```

- [ ] **Step 5: Create the seven `_labs` documents**

`_labs/connect.md`:
```markdown
---
title: Cooperative Networks and Controls Lab
short_name: ConNeCt
slug: connect
kind: research-group
leader_names:
  - Daniel Zelazo
summary: "[Placeholder: one-paragraph summary of the ConNeCt lab — networked and multi-agent systems, graph theory and control.]"
active: true
order: 10
---
```

`_labs/anpl.md`:
```markdown
---
title: Autonomous Navigation and Perception Lab
short_name: ANPL
slug: anpl
kind: research-group
leader_names:
  - Vadim Indelman
summary: "[Placeholder: one-paragraph summary of ANPL — single and multi-robot autonomous navigation and perception in uncertain environments.]"
website: https://anpl-technion.github.io/
active: true
order: 20
---
```

`_labs/casy.md`:
```markdown
---
title: Cooperative Autonomous Systems Lab
short_name: CASY
slug: casy
kind: research-group
leader_names:
  - Tal Shima
summary: "[Placeholder: one-paragraph summary of CASY — cooperative team mission planning, motion planning, and guidance.]"
active: true
order: 30
---
```

`_labs/idan-group.md`:
```markdown
---
title: Idan Group
short_name: Idan Group
slug: idan-group
kind: research-group
leader_names:
  - Moshe Idan
summary: "[Placeholder: one-paragraph summary of the Idan Group — estimation and control of stochastic systems, low-cost avionics.]"
active: true
order: 40
---
```

`_labs/ben-asher-group.md`:
```markdown
---
title: Ben-Asher Group
short_name: Ben-Asher Group
slug: ben-asher-group
kind: research-group
leader_names:
  - Yossi Ben-Asher
summary: "[Placeholder: one-paragraph summary of the Ben-Asher Group — optimal control theory from the Calculus of Variations point of view.]"
active: true
order: 50
---
```

`_labs/oshman-group.md`:
```markdown
---
title: Oshman Group
short_name: Oshman Group
slug: oshman-group
kind: research-group
leader_names:
  - Yaakov Oshman
summary: "[Placeholder: one-paragraph summary of the Oshman Group — information fusion, optimal estimation and control for aerospace systems.]"
active: true
order: 60
---
```

`_labs/flight-control-teaching-lab.md`:
```markdown
---
title: Flight Control Teaching Laboratories
short_name: Teaching Labs
slug: flight-control-teaching-lab
kind: teaching-lab
leader_names:
  - Ruslan Arhipov
summary: "[Placeholder: one-paragraph summary of the teaching laboratories — control education for Aerospace and Mechanical Engineering students.]"
active: true
order: 90
---
```

- [ ] **Step 6: Create the eight `_team` documents**

Common shape (no emails, phones, or bios — unverified). Each body is a single placeholder line.

`_team/daniel-zelazo.md`:
```markdown
---
title: Daniel Zelazo
slug: daniel-zelazo
role: Professor
category: faculty
lab_ids: [connect]
active: true
order: 10
---

[Placeholder: short bio for Daniel Zelazo.]
```

`_team/vadim-indelman.md`: same shape — `role: Associate Professor`, `lab_ids: [anpl]`, `order: 20`.
`_team/tal-shima.md`: `role: Professor`, `lab_ids: [casy]`, `order: 30`.
`_team/moshe-idan.md`: `role: Professor`, `lab_ids: [idan-group]`, `order: 40`.
`_team/yossi-ben-asher.md`: `role: Professor`, `lab_ids: [ben-asher-group]`, `order: 50`.
`_team/yaakov-oshman.md`: `role: Professor Emeritus`, `category: emeritus`, `lab_ids: [oshman-group]`, `order: 60`.
`_team/ruslan-arhipov.md`: `role: Lab Engineer`, `category: lab-staff`, `lab_ids: [flight-control-teaching-lab]`, `order: 70`.
`_team/arthur-grunwald.md`: `role: Associate Professor (Ret.)`, `category: emeritus`, `lab_ids: [pfcl]`, `order: 80`.

- [ ] **Step 7: Create the seed `_news` item**

`_news/2026-09-07-welcome-to-the-new-pfcl-website.md`:
```markdown
---
title: Welcome to the new PFCL website
date: 2026-09-07
lab_id: pfcl
category: news
excerpt: "[Placeholder: one-sentence announcement of the new PFCL website.]"
canonical_url: /news/
source_name: PFCL
featured: false
show_on_showcase: true
---

[Placeholder: welcome news item — replace or delete in the content phase.]
```

- [ ] **Step 8: Validate and build**

Run: `docker compose run --rm site bundle exec ruby scripts/validate_content.rb`
Expected: `Content validation passed.`
Run: `docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb`
Expected: all pass.
Run: `docker compose run --rm site bundle exec jekyll build --trace`
Expected: green.

- [ ] **Step 9: Commit**

```bash
git add _data _labs _team _news
git commit -m "feat: navigation, footer and taxonomy data; seed labs, team, news"
```

---

### Task 4: Presentation overrides (header, footer, cards, feed, carousel)

**Files:**
- Create: `_includes/header.html`, `_includes/footer.html`, `_includes/lab_card.html`, `_includes/team_card.html`, `_includes/news_feed.html`, `_includes/carousel.html`, `_includes/project_filters.html`
- Create: `assets/js/projects.js`
- Create: `assets/images/` (restore authentic PFCL logo PNGs from `archive/v1-antigravity`)
- Modify: `_sass/pfcl.scss` (append styles)

**Interfaces:**
- Consumes: `site.data.navigation`, `site.data.footer`, `site.data.taxonomies`, `site.labs|team|news`, `site.data.generated.updates` (Tasks 1+3).
- Produces: include API used by Task 5 pages —
  - `{% include lab_card.html lab=<lab> %}`
  - `{% include team_card.html person=<person> %}`
  - `{% include news_feed.html limit=<n> %}` (0 or omitted = all items)
  - `{% include carousel.html %}` (reads `page.carousel` list of `{caption}`)
  - `{% include project_filters.html %}` (renders selects; pairs with `assets/js/projects.js` and `data-project-*` attributes)

- [ ] **Step 1: Restore logo assets from the archive**

Run: `git checkout archive/v1-antigravity -- assets/images/`
Expected: `assets/images/PFCL-1.png`, `PFCL-2.png`, `PFCL-3.png`, `PFCL.jpg` present (authentic lab logos, restored not fabricated).

- [ ] **Step 2: Create `_includes/header.html`** (theme override — brand logo + navigation data)

```html
<nav class="navbar is-primary {% if site.fixed_navbar %} is-fixed-{{ site.fixed_navbar }}{% endif %}" x-data="{ openNav: false }">
    <div class="container">
        <div class="navbar-brand">
            <a href="{{ site.baseurl }}/" class="navbar-item pfcl-navbar-brand">
                <img src="{{ '/assets/images/PFCL-2.png' | relative_url }}" alt="PFCL emblem" height="28">
                <span class="pfcl-navbar-title">Philadelphia Flight Control Laboratory</span>
            </a>
            <a role="button" class="navbar-burger burger" aria-label="menu" aria-expanded="false" data-target="navMenu" :class="{ 'is-active': openNav }" x-on:click="openNav = !openNav">
                <span aria-hidden="true"></span>
                <span aria-hidden="true"></span>
                <span aria-hidden="true"></span>
            </a>
        </div>
        <div class="navbar-menu" id="navMenu" :class="{ 'is-active': openNav }">
            <div class="navbar-end">
                <a href="{{ site.baseurl }}/" class="navbar-item {% if page.url == '/' %}is-active{% endif %}">Home</a>
                {% for item in site.data.navigation %}
                    {% if item.dropdown %}
                        <div class="navbar-item has-dropdown is-hoverable">
                            <a href="{{ item.link | relative_url }}" class="navbar-link {% if page.url contains item.link %}is-active{% endif %}">{{ item.name }}</a>
                            <div class="navbar-dropdown">
                                {% for subitem in item.dropdown %}
                                    <a href="{{ subitem.link | relative_url }}" class="navbar-item {% if subitem.link == page.url %}is-active{% endif %}">{{ subitem.name }}</a>
                                {% endfor %}
                            </div>
                        </div>
                    {% else %}
                        <a href="{{ item.link | relative_url }}" class="navbar-item {% if item.link == page.url %}is-active{% endif %}">{{ item.name }}</a>
                    {% endif %}
                {% endfor %}
            </div>
        </div>
    </div>
</nav>
```

- [ ] **Step 3: Create `_includes/footer.html`** (WordPress-pattern 3-zone footer + copyright bar)

```html
<footer class="footer pfcl-footer" role="contentinfo">
    <div class="container">
        <div class="columns is-multiline">
            <div class="column is-6-desktop">
                <div class="columns is-multiline">
                    {% for menu in site.data.footer.menus %}
                        <div class="column is-4-desktop is-6-tablet">
                            <h3 class="title is-6 pfcl-footer-heading">{{ menu.title }}</h3>
                            <ul class="pfcl-footer-list">
                                {% for link in menu.links %}
                                    <li><a href="{{ link.url | relative_url }}">{{ link.name }}</a></li>
                                {% endfor %}
                            </ul>
                        </div>
                    {% endfor %}
                </div>
            </div>
            <div class="column is-3-desktop">
                <h3 class="title is-6 pfcl-footer-heading">Contact</h3>
                <ul class="pfcl-footer-list pfcl-footer-contact">
                    {% assign c = site.data.footer.contact %}
                    {% if c.email != blank %}
                        <li>
                            <span class="icon" aria-hidden="true"><i class="fas fa-envelope"></i></span>
                            <a href="mailto:{{ c.email }}">{{ c.email }}</a>
                        </li>
                    {% endif %}
                    {% if c.phone != blank %}
                        <li>
                            <span class="icon" aria-hidden="true"><i class="fas fa-phone"></i></span>
                            <a href="tel:{{ c.phone }}">{{ c.phone }}</a>
                        </li>
                    {% endif %}
                    {% if c.youtube != blank %}
                        <li class="pfcl-footer-divider">
                            <span class="icon" aria-hidden="true"><i class="fab fa-youtube"></i></span>
                            <a href="{{ c.youtube }}" target="_blank" rel="noopener noreferrer">Visit our channel</a>
                        </li>
                    {% endif %}
                </ul>
            </div>
            <div class="column is-3-desktop">
                <h3 class="title is-6 pfcl-footer-heading">{{ site.data.footer.logos_heading }}</h3>
                <ul class="pfcl-footer-list pfcl-footer-logos">
                    {% for logo in site.data.footer.logos %}
                        <li class="mb-3">
                            <a href="{{ logo.url }}" target="_blank" rel="noopener noreferrer" title="{{ logo.name }}">
                                {% if logo.image != blank %}
                                    <img src="{{ logo.image | relative_url }}" alt="{{ logo.name }}">
                                {% else %}
                                    <span class="pfcl-footer-logo-text">{{ logo.name }}</span>
                                {% endif %}
                            </a>
                        </li>
                    {% endfor %}
                </ul>
            </div>
        </div>
    </div>
</footer>
<section class="pfcl-copyright">
    <div class="container has-text-centered">
        <p>{{ site.data.footer.copyright }}</p>
    </div>
</section>
```

- [ ] **Step 4: Create `_includes/lab_card.html`**

```html
<div class="card pfcl-card">
    <div class="card-content">
        <p class="title is-4">{{ include.lab.title }}</p>
        <p class="subtitle is-6">
            {% if include.lab.short_name %}{{ include.lab.short_name }} — {% endif %}{{ include.lab.leader_names | join: ', ' }}
        </p>
        <div class="content">{{ include.lab.summary }}</div>
        {% if include.lab.website %}
            <a href="{{ include.lab.website }}" target="_blank" rel="noopener noreferrer" class="button is-small is-primary is-outlined">Visit website</a>
        {% endif %}
    </div>
</div>
```

- [ ] **Step 5: Create `_includes/team_card.html`**

```html
<div class="card pfcl-card">
    <div class="card-content">
        <div class="pfcl-team-photo" aria-hidden="true">[Photo]</div>
        <p class="title is-5 mt-3">{{ include.person.title }}</p>
        <p class="subtitle is-6 mb-2">{{ include.person.role }}</p>
        {% assign lab_links = '' | split: '' %}
        {% for id in include.person.lab_ids %}
            {% if id == 'pfcl' %}
                {% assign lab_links = lab_links | push: 'PFCL' %}
            {% else %}
                {% assign member_lab = site.labs | where: 'slug', id | first %}
                {% if member_lab %}{% assign lab_links = lab_links | push: member_lab.short_name %}{% endif %}
            {% endif %}
        {% endfor %}
        {% if lab_links.size > 0 %}
            <p class="is-size-7 has-text-grey">{{ lab_links | join: ' · ' }}</p>
        {% endif %}
    </div>
</div>
```

- [ ] **Step 6: Create `_includes/news_feed.html`** (local `_news` + generated updates, merged, newest first)

```html
{% assign limit = include.limit | default: 0 | plus: 0 %}
{% assign items = '' | split: '' %}
{% for item in site.news %}
    {% assign items = items | push: item %}
{% endfor %}
{% for item in site.data.generated.updates %}
    {% assign items = items | push: item %}
{% endfor %}
{% assign sorted = items | sort: 'date' | reverse %}
{% if sorted.size == 0 %}
    <p class="pfcl-placeholder">[Placeholder: news and updates will be listed here.]</p>
{% else %}
    <ul class="pfcl-news-list">
        {% for item in sorted %}
            {% if limit > 0 and forloop.index > limit %}{% break %}{% endif %}
            {% assign item_date = item.date | default: item.published_at %}
            {% if item.lab_id == 'pfcl' %}
                {% assign source_label = 'PFCL' %}
            {% else %}
                {% assign source_lab = site.labs | where: 'slug', item.lab_id | first %}
                {% assign source_label = item.source_name | default: source_lab.short_name | default: 'PFCL' %}
            {% endif %}
            <li class="pfcl-news-item">
                <p class="pfcl-news-meta is-size-7 has-text-grey">
                    <time datetime="{{ item_date | date_to_xmlschema }}">{{ item_date | date: '%B %-d, %Y' }}</time>
                    — {{ source_label }}
                </p>
                <p class="mb-1">
                    {% if item.url %}
                        <a href="{{ item.url }}">{{ item.title }}</a>
                    {% elsif item.canonical_url and item.lab_id != 'pfcl' %}
                        <a href="{{ item.canonical_url }}" target="_blank" rel="noopener noreferrer">{{ item.title }}</a>
                    {% else %}
                        {{ item.title }}
                    {% endif %}
                </p>
                <p class="is-size-6">{{ item.excerpt }}</p>
            </li>
        {% endfor %}
    </ul>
{% endif %}
```

Note: generated update objects use `published_at`/`canonical_url`; collection docs use `date`. The include normalizes via `item.date | default: item.published_at` and exposes `item.url` (collection permalink, if later enabled) — external items always link to `canonical_url` with attribution, never presented as PFCL-authored.

- [ ] **Step 7: Create `_includes/carousel.html`** (CSS scroll-snap; no JS required)

```html
{% if page.carousel %}
<div class="pfcl-carousel" role="region" aria-label="Laboratory highlights carousel">
    {% for slide in page.carousel %}
    <figure class="pfcl-carousel-slide">
        <div class="pfcl-carousel-frame">{{ slide.caption }}</div>
        <figcaption class="is-size-7 has-text-grey">[Carousel image placeholder — {{ slide.caption }}]</figcaption>
    </figure>
    {% endfor %}
</div>
{% endif %}
```

- [ ] **Step 8: Create `_includes/project_filters.html`**

```html
<div class="pfcl-filters field is-grouped">
    <div class="control">
        <label class="label is-small" for="pfcl-filter-labs">Research group</label>
        <div class="select is-small">
            <select id="pfcl-filter-labs" data-filter="labs">
                <option value="">All groups</option>
                {% for lab in site.labs %}
                    <option value="{{ lab.slug }}">{{ lab.short_name | default: lab.title }}</option>
                {% endfor %}
                <option value="pfcl">PFCL</option>
            </select>
        </div>
    </div>
    <div class="control">
        <label class="label is-small" for="pfcl-filter-status">Status</label>
        <div class="select is-small">
            <select id="pfcl-filter-status" data-filter="status">
                <option value="">All statuses</option>
                <option value="available">Available</option>
                <option value="ongoing">Ongoing</option>
                <option value="completed">Completed</option>
            </select>
        </div>
    </div>
    <div class="control">
        <label class="label is-small" for="pfcl-filter-types">Type</label>
        <div class="select is-small">
            <select id="pfcl-filter-types" data-filter="types">
                <option value="">All types</option>
                <option value="research">Research</option>
                <option value="experimental">Experimental</option>
                <option value="software">Software</option>
                <option value="hardware">Hardware</option>
                <option value="teaching">Teaching</option>
            </select>
        </div>
    </div>
    <div class="control">
        <label class="label is-small" for="pfcl-filter-levels">Student level</label>
        <div class="select is-small">
            <select id="pfcl-filter-levels" data-filter="levels">
                <option value="">All levels</option>
                <option value="undergraduate">Undergraduate</option>
                <option value="masters">Masters</option>
                <option value="phd">PhD</option>
            </select>
        </div>
    </div>
</div>
```

- [ ] **Step 9: Create `assets/js/projects.js`** (progressive enhancement — all cards stay in the DOM)

```javascript
// PFCL student-project filters: hides non-matching cards. The full list
// remains in the HTML, so links work with JavaScript disabled.
(function () {
  "use strict";

  var root = document.querySelector("[data-project-list]");
  if (!root) return;

  var selects = Array.prototype.slice.call(root.querySelectorAll("select[data-filter]"));
  var cards = Array.prototype.slice.call(root.querySelectorAll("[data-project-card]"));

  function cardValues(card, name) {
    return (card.getAttribute("data-" + name) || "").split(/\s+/).filter(Boolean);
  }

  function applyFilters() {
    cards.forEach(function (card) {
      var visible = selects.every(function (select) {
        var value = select.value;
        if (!value) return true;
        return cardValues(card, select.getAttribute("data-filter")).indexOf(value) !== -1;
      });
      card.hidden = !visible;
    });
  }

  selects.forEach(function (select) {
    select.addEventListener("change", applyFilters);
  });
})();
```

- [ ] **Step 10: Append styles to `_sass/pfcl.scss`**

```scss
// ---- Footer (WordPress-pattern three zones + copyright bar) ----
.pfcl-footer {
  padding-bottom: 1.5rem;

  .pfcl-footer-list {
    list-style: none;
    margin: 0;
    padding: 0;

    li + li {
      margin-top: 0.35rem;
    }
  }

  .pfcl-footer-contact li {
    display: flex;
    align-items: baseline;
    gap: 0.5rem;
  }

  .pfcl-footer-divider {
    margin-top: 0.75rem;
    padding-top: 0.75rem;
    border-top: 1px solid $border;
  }

  .pfcl-footer-logo-text {
    font-weight: 600;
  }
}

.pfcl-copyright {
  background: $light;
  border-top: 1px solid $border;
  padding: 0.75rem 0;
  font-size: 0.875rem;
}

// ---- Cards ----
.pfcl-card {
  height: 100%;
  display: flex;
  flex-direction: column;
}

.pfcl-team-photo {
  align-items: center;
  aspect-ratio: 1;
  background: $light;
  border: 1px dashed $border;
  border-radius: 0.25rem;
  color: $grey-light;
  display: flex;
  font-size: 0.875rem;
  justify-content: center;
  max-width: 160px;
}

// ---- Homepage carousel (CSS scroll-snap; JS not required) ----
.pfcl-carousel {
  display: flex;
  gap: 1rem;
  overflow-x: auto;
  padding-bottom: 0.5rem;
  scroll-snap-type: x mandatory;
}

.pfcl-carousel-slide {
  flex: 0 0 72%;
  margin: 0;
  scroll-snap-align: center;
}

.pfcl-carousel-frame {
  align-items: center;
  aspect-ratio: 16 / 9;
  background: $light;
  border: 2px dashed $border;
  border-radius: 0.5rem;
  color: $grey-light;
  display: flex;
  justify-content: center;
  padding: 1rem;
  text-align: center;
}

@media (prefers-reduced-motion: reduce) {
  .pfcl-carousel {
    scroll-behavior: auto;
  }
}

// ---- News feed ----
.pfcl-news-list {
  list-style: none;
  margin: 0;
  padding: 0;
}

.pfcl-news-item {
  border-bottom: 1px solid $border;
  padding: 1rem 0;

  &:last-child {
    border-bottom: 0;
  }
}

// ---- Partner logo row (homepage) ----
.pfcl-partners {
  align-items: center;
  display: flex;
  flex-wrap: wrap;
  gap: 2rem;
  justify-content: center;
}

.pfcl-partner-placeholder {
  align-items: center;
  aspect-ratio: 3 / 1;
  background: $light;
  border: 1px dashed $border;
  border-radius: 0.25rem;
  color: $grey-light;
  display: flex;
  font-size: 0.8rem;
  padding: 0.5rem 1rem;
  text-align: center;
  width: 180px;
}
```

- [ ] **Step 11: Build and verify includes compile**

Run: `docker compose run --rm site bundle exec jekyll build --trace`
Expected: green (includes are not yet referenced by any page except via Task 5 — this step catches Liquid syntax errors only if referenced; so additionally create a temporary probe by referencing them from `index.md`, then revert). Simplest check: proceed to Task 5 and treat its build as the include verification; do not commit until Task 5 builds.

- [ ] **Step 12: Commit**

```bash
git add _includes assets/js assets/images _sass/pfcl.scss
git commit -m "feat: ANPL-style header, WordPress-pattern footer, cards, feed, carousel, filters"
```

---

### Task 5: The eleven route pages

**Files:**
- Modify: `index.md` (full homepage)
- Create: `about.md`, `history.md`, `dedication.md`, `team.md`, `labs.md`, `projects.md`, `teaching.md`, `news.md`, `media.md`, `contact.md`

**Interfaces:**
- Consumes: all Task 4 includes, `site.labs|team|news`, `site.data.taxonomies`.

- [ ] **Step 1: Homepage `index.md`**

```markdown
---
layout: page
title: Philadelphia Flight Control Laboratory
subtitle: Technion – Israel Institute of Technology
hide_hero: false
carousel:
  - caption: Photograph of the PFCL flight testbeds
  - caption: Photograph of researchers operating a quadcopter experiment
  - caption: Research-figure slide — [Placeholder: caption of concept figure]
---

## Welcome

[Placeholder: two-to-three paragraph welcome text describing PFCL — the umbrella facility for Guidance, Navigation, and Control research in the Faculty of Aerospace Engineering, its scope, and its constituent groups.]

<div class="buttons">
  <a href="{{ '/labs/' | relative_url }}" class="button is-primary">Research groups</a>
  <a href="{{ '/projects/' | relative_url }}" class="button is-primary is-outlined">Available student projects</a>
</div>

{% include carousel.html %}

## Research groups

[Placeholder: optional one-line introduction to the groups below.]

<div class="columns is-multiline">
  {% assign labs = site.labs | sort: 'order' %}
  {% for lab in labs %}
    <div class="column is-6-desktop is-12-tablet">
      {% include lab_card.html lab=lab %}
    </div>
  {% endfor %}
</div>

## Selected student projects

<p class="pfcl-placeholder">[Placeholder: teaser list of currently available student projects — fed from the <code>_projects</code> collection.]</p>

## News &amp; updates

{% include news_feed.html limit=4 %}

## Partners

[Placeholder: partner and funding logos.]

<div class="pfcl-partners">
  <div class="pfcl-partner-placeholder">Technion</div>
  <div class="pfcl-partner-placeholder">Faculty of Aerospace Engineering</div>
  <div class="pfcl-partner-placeholder">[Additional partners]</div>
</div>
```

- [ ] **Step 2: `about.md`**

```markdown
---
layout: page
title: About PFCL
subtitle: The umbrella laboratory for GNC research at Technion
---

[Placeholder: concise institutional overview — 2–3 paragraphs about the Philadelphia Flight Control Laboratory.]

## Constituent research groups

[Placeholder: short introduction.]

<div class="columns is-multiline">
  {% assign labs = site.labs | sort: 'order' %}
  {% for lab in labs %}
    <div class="column is-6-desktop is-12-tablet">
      {% include lab_card.html lab=lab %}
    </div>
  {% endfor %}
</div>

## Location

Philadelphia Flight Control Laboratory
Faculty of Aerospace Engineering
Lady Davis Building
Technion – Israel Institute of Technology
Haifa 32000, Israel
```

- [ ] **Step 3: `history.md`**

```markdown
---
layout: page
title: History
subtitle: Five decades of flight control research at Technion
---

[Placeholder: long-form chronological history of the laboratory, with accessible images and captions. Source material: the PFCL history retrospective authored by Assoc. Prof. (Ret.) Arthur Grunwald — to be imported in the content phase.]
```

- [ ] **Step 4: `dedication.md`**

```markdown
---
layout: page
title: PFCL Dedication
subtitle: Philadelphia Chapter and donor recognition
---

[Placeholder: recognition of the Philadelphia Chapter and the donors behind the laboratory. Content to be sourced from the current pfcl.technion.ac.il dedication page during the content phase.]
```

- [ ] **Step 5: `team.md`**

```markdown
---
layout: page
title: Team
subtitle: Faculty, staff, and researchers
---

[Placeholder: optional introduction to the PFCL team.]

{% for cat in site.data.taxonomies.team_categories %}
  {% assign members = site.team | where: 'category', cat.id | sort: 'order' %}
  {% if members.size > 0 %}
    <h2 class="title is-4 mt-5">{{ cat.label }}</h2>
    <div class="columns is-multiline">
      {% for person in members %}
        <div class="column is-4-desktop is-6-tablet">
          {% include team_card.html person=person %}
        </div>
      {% endfor %}
    </div>
  {% endif %}
{% endfor %}
```

- [ ] **Step 6: `labs.md`**

```markdown
---
layout: page
title: Research Groups
subtitle: Constituent research groups and laboratories
permalink: /labs/
---

[Placeholder: introduction to the research groups directory.]

<div class="columns is-multiline">
  {% assign labs = site.labs | sort: 'order' %}
  {% for lab in labs %}
    <div class="column is-6-desktop is-12-tablet">
      {% include lab_card.html lab=lab %}
    </div>
  {% endfor %}
</div>
```

- [ ] **Step 7: `projects.md`**

```markdown
---
layout: page
title: Student Projects
subtitle: Available and ongoing student research projects
permalink: /projects/
---

[Placeholder: introduction for students — how to read statuses and apply.]

<div data-project-list>
  {% include project_filters.html %}

  {% assign projects = site.projects | where: 'published', true | sort: 'order' %}
  {% if projects.size == 0 %}
    <p class="pfcl-placeholder" data-project-empty>[Placeholder: student projects will be listed here once the <code>_projects</code> collection is populated.]</p>
  {% else %}
    <div class="columns is-multiline">
      {% for project in projects %}
        <div class="column is-6-desktop is-12-tablet" data-project-card
             data-labs="{{ project.lab_ids | join: ' ' }}"
             data-status="{{ project.recruitment_status }}"
             data-types="{{ project.project_types | join: ' ' }}"
             data-levels="{{ project.student_levels | join: ' ' }}">
          <div class="card pfcl-card">
            <div class="card-content">
              <p class="title is-5">{{ project.title }}</p>
              <p class="subtitle is-6">{{ project.advisor_names | join: ', ' }}</p>
              <div class="content">{{ project.summary }}</div>
            </div>
          </div>
        </div>
      {% endfor %}
    </div>
  {% endif %}
</div>

<script src="{{ '/assets/js/projects.js' | relative_url }}" defer></script>
```

- [ ] **Step 8: `teaching.md`**

```markdown
---
layout: page
title: Teaching Labs
subtitle: Control education for Aerospace and Mechanical Engineering
permalink: /teaching/
---

[Placeholder: overview of the teaching activity — the PFCL serves both the Faculty of Aerospace Engineering and the Faculty of Mechanical Engineering.]

## Faculty of Aerospace Engineering

- **Dynamic Systems (084737)** — [Placeholder: course and labs description.]
- **Control Theory (084738)** — [Placeholder: course and labs description.]
- **Advanced Control Lab (085705)** — [Placeholder: course description — quadcopter-based control design.]
- **Project 7-8** — [Placeholder: senior design project description.]

## Faculty of Mechanical Engineering

- **Introduction to Control (034040)** — [Placeholder: course description.]
- **Advanced Control and Automation Lab (034406)** — [Placeholder: course description.]
```

- [ ] **Step 9: `news.md`**

```markdown
---
layout: page
title: News
subtitle: PFCL-wide activity feed
permalink: /news/
---

[Placeholder: optional introduction — items from constituent groups are attributed and link to their canonical source.]

{% include news_feed.html %}
```

- [ ] **Step 10: `media.md`**

```markdown
---
layout: page
title: Media
subtitle: Photos and videos from the laboratory
permalink: /media/
---

## Photos

<p class="pfcl-placeholder">[Placeholder: curated photo gallery.]</p>

## Videos

<p class="pfcl-placeholder">[Placeholder: video gallery — link the PFCL YouTube channel.]</p>
```

- [ ] **Step 11: `contact.md`**

```markdown
---
layout: page
title: Contact
subtitle: We'd love to hear from you
permalink: /contact/
---

- Telephone: [+972-4-829-3820](tel:+972-4-829-3820)
- Email: [pfcl@technion.ac.il](mailto:pfcl@technion.ac.il)

## Address

Philadelphia Flight Control Laboratory
Faculty of Aerospace Engineering
Lady Davis Building
Technion – Israel Institute of Technology
Haifa 32000, Israel

## Directions

[Placeholder: directions and embedded map.]
```

- [ ] **Step 12: Build and verify all routes exist at the base path**

Run: `docker compose run --rm site bundle exec jekyll build --trace`
Run (bash): `for p in index.html about/index.html history/index.html dedication/index.html team/index.html labs/index.html projects/index.html teaching/index.html news/index.html media/index.html contact/index.html; do test -f "_site/$p" && echo "OK $p" || echo "MISSING $p"; done`
Expected: all `OK`.
Run: `grep -c "pfcl-footer" _site/index.html` → ≥ 2 (footer + copyright present); `grep -o 'href="[^"]*"' _site/index.html | sort -u` → spot-check that internal links start with `/pfcl-technion.github.io/`.

- [ ] **Step 13: Commit**

```bash
git add index.md about.md history.md dedication.md team.md labs.md projects.md teaching.md news.md media.md contact.md
git commit -m "feat: all eleven route pages with placeholder content and includes"
```

---

### Task 6: CI, deployment workflow, README, AGENTS — final verification and PR

**Files:**
- Create: `.github/workflows/ci.yml`, `.github/workflows/pages.yml`, `README.md`, `AGENTS.md`

**Interfaces:**
- Consumes: validator + tests + build from Tasks 1–5.
- Produces: CI gate on PRs and `main`; Pages deployment on `main`; contributor docs.

- [ ] **Step 1: Create `.github/workflows/ci.yml`**

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build site image
        run: docker compose build

      - name: Install dependencies
        run: docker compose run --rm site sh -c "bundle check || bundle install"

      - name: Validate content
        run: docker compose run --rm site bundle exec ruby scripts/validate_content.rb

      - name: Run tests
        run: docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb

      - name: Build site (production)
        run: docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace
```

- [ ] **Step 2: Create `.github/workflows/pages.yml`**

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build site image
        run: docker compose build

      - name: Install dependencies
        run: docker compose run --rm site sh -c "bundle check || bundle install"

      - name: Validate content
        run: docker compose run --rm site bundle exec ruby scripts/validate_content.rb

      - name: Run tests
        run: docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb

      - name: Build site (production)
        run: docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace

      - name: Configure Pages
        uses: actions/configure-pages@v5

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: _site

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Deploy
        id: deployment
        uses: actions/deploy-pages@v4
```

- [ ] **Step 3: Create `AGENTS.md`**

```markdown
# AGENTS.md

Instructions for AI agents and contributors working on the PFCL website.

## Core rules and boundaries

1. **Inspect before editing.** Read existing schemas, layouts, and files before modifying or adding content.
2. **Umbrella terminology.** PFCL is the umbrella institution; "research group" and "sub-lab" are equivalent terms.
3. **Obsidian vault boundary.** Never read from, link to, or copy files from the internal PFCL Obsidian vault. Public content is authored in this repo or imported via configured public adapters.
4. **No fabricated content.** Only verified names, titles, and contact details. Everything unverified is a bracketed `[Placeholder: …]` marker. Never invent emails, phone numbers, dates, bios, quotes, or statistics.
5. **Preserve frontmatter schemas.** Maintain the strict YAML schemas of `_labs/`, `_team/`, `_projects/`, and `_news/` (see `scripts/validate_content.rb` for the enforced fields and enums).
6. **Stable identifiers.** Never rename slugs; references use identifiers, not display names.
7. **Attribution integrity.** Never present a constituent lab's publication or news as PFCL-authored. Imported items always carry `canonical_url` and `source_name`.
8. **Generated data boundary.** `_data/generated/updates.json` is reserved for the future aggregation deliverable; never hand-edit it once aggregation exists.
9. **No theme vendoring.** `bulma-clean-theme` stays a gem dependency; overrides live only in `_layouts/`, `_includes/`, and `_sass/`.
10. **Verify before claiming completion.** Run the validator, the test suite, and a production Jekyll build (commands in README) before declaring work done.
11. **Accessibility.** The site works without JavaScript; keep WCAG 2.2 AA contrast; respect `prefers-reduced-motion`.
12. **Domain safety.** Never change DNS, GitHub Pages custom-domain settings, organization settings, or anything touching the live `pfcl.technion.ac.il` site without explicit authorization.
```

- [ ] **Step 4: Create `README.md`**

````markdown
# PFCL Website

Source for the Philadelphia Flight Control Laboratory (PFCL) website,
served via GitHub Pages. Jekyll 4 + Bulma Clean Theme (gem), content in
Markdown collections, validated before every build.

## Development (Docker)

```bash
docker compose up --build            # dev server at http://localhost:4000
```

## Verification

Run all three before considering work complete:

```bash
docker compose run --rm site bundle exec ruby scripts/validate_content.rb
docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb
docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace
```

## Structure

| Path | Purpose |
| --- | --- |
| `_labs/` | Constituent research groups and teaching labs |
| `_team/` | Public personnel |
| `_projects/` | Public student-project records |
| `_news/` | PFCL-authored news items |
| `_data/` | Navigation, footer, taxonomies, generated feeds |
| `_includes/`, `_sass/` | Theme overrides and custom styles |
| `scripts/`, `test/` | Content validator and its test suite |
| `docs/superpowers/` | Design specs and implementation plans |

Content rules, attribution requirements, and safety boundaries are in
`AGENTS.md` — read it before editing content.

## Deployment

GitHub Actions builds and deploys `main` to GitHub Pages. Preview URL:
`https://philadelphia-flight-control-laboratory.github.io/pfcl-technion.github.io/`.
The production domain `pfcl.technion.ac.il` is not connected to this
repository; any cutover is a separate, explicitly approved operation.
````

- [ ] **Step 5: Final local verification — everything, in order**

Run: `docker compose run --rm site bundle exec ruby scripts/validate_content.rb` → `Content validation passed.`
Run: `docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb` → all pass.
Run: `docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace` → green.
Run: route existence loop from Task 5 Step 12 → all `OK`.
Run: `grep -R "antigravity\|TODO\|TBD" _site --include="*.html" | wc -l` → 0 (no leaked markers other than intended `[Placeholder:` content markers).
Run: `ruby -e "require 'yaml'; YAML.load_file('.github/workflows/ci.yml'); YAML.load_file('.github/workflows/pages.yml'); puts 'workflow YAML OK'"` (or via container).

- [ ] **Step 6: Commit, push, open draft PR**

```bash
git add .github README.md AGENTS.md
git commit -m "feat: CI and Pages workflows, contributor docs"
git push -u origin v2-rebuild
```

Then open a **draft** PR `v2-rebuild` → `main` with `gh pr create --draft` (body: summary of the rebuild, spec/plan links, note that CI must pass; do not merge — merge is the user's decision).

---

## Self-review checklist (completed during planning)

- **Spec coverage:** url/baseurl fix (T1 `_config.yml`), ANPL presentation (T4/T5), WordPress footer (T3 data + T4 include), content policy (global constraint + all seed docs), seed inventory 7/8/1/0 (T3), empty projects page shell with filters (T5 Step 7), validator behavior incl. attribution and empty-feed resilience (T2), Docker/devcontainer (T1), CI/pages (T6), README/AGENTS (T6), PR-not-direct-merge (T6 Step 6). Foundation-spec routes: all 11 present (T5). Reserved `/showcase/` route intentionally not created (spec: reserved, later deliverable).
- **Placeholder scan:** no "TBD"/"implement later" steps; every code block complete.
- **Type consistency:** include names (`lab_card.html lab=`, `team_card.html person=`, `news_feed.html limit=`, `carousel.html`, `project_filters.html`) and data shapes (`site.data.footer.menus/contact/logos/copyright`, `site.data.navigation` list, `site.data.taxonomies.team_categories`) match across Tasks 3–5. Validator enum sets match `project_filters.html` options and the foundation spec.
