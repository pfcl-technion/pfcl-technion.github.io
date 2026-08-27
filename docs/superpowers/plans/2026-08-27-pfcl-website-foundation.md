# PFCL Website Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Jekyll-based static website foundation for the Philadelphia Flight Control Laboratory (PFCL) with containerized dev environment, strict frontmatter schemas, Ruby validation and tests, accessible Bulma styling, client-side project filtering, and GitHub Actions CI/Pages preview deployment.

**Architecture:** A static site powered by Jekyll 4.x with `bulma-clean-theme` 1.3.1 (Bulma 1.x), containerized with Ruby 3.3 Bookworm, using strict YAML frontmatter collections (`_labs`, `_team`, `_projects`, `_news`), a Ruby validator script (`scripts/validate_content.rb`) and test suite (`test/content_validation_test.rb`), custom Sass layered over the theme with WCAG 2.2 AA contrast, progressive client-side filtering, and automated GitHub Actions CI & Pages workflows.

**Tech Stack:** Jekyll 4.3.4, Bulma Clean Theme 1.3.1, Bulma 1.x Sass, Ruby 3.3, Docker & Docker Compose, Dev Container, GitHub Actions, Vanilla JS (progressive enhancement).

## Global Constraints

- The internal PFCL Obsidian vault is context only; never read, linked, or published by website code or automation.
- Public content lives in this repository or is imported from configured public lab sites in the later aggregation deliverable.
- Attribute all imported materials to originating research groups with canonical source links.
- Do not fork or copy historical files from ANPL or ConNect repositories.
- Use Jekyll 4.3+ (`jekyll ~> 4.3.4`) and Bulma Clean Theme 1.3.1 (`bulma-clean-theme ~> 1.3.1`).
- GitHub Pages deployed via GitHub Actions workflow (`pages.yml`).
- Keep `pfcl.technion.ac.il` untouched; deploy preview under `https://philadelphia-flight-control-laboratory.github.io/pfcl-technion.github.io/` with `baseurl: /pfcl-technion.github.io`.
- All collection documents must pass `scripts/validate_content.rb` before Jekyll build.
- Progressive enhancement: all content and links must work without JavaScript; project filters hide/show static HTML cards.
- WCAG 2.2 AA accessibility: visible focus states, hierarchical headings, alt text on images, reduced-motion compliance.

---

### Task 1: Scaffolding, Container Environment & Jekyll Configuration

**Files:**
- Create: `Gemfile`
- Create: `Dockerfile`
- Create: `compose.yml`
- Create: `.devcontainer/devcontainer.json`
- Create: `_config.yml`
- Create: `_config.preview.yml`
- Create: `.gitignore`
- Create: `.dockerignore`

**Interfaces:**
- Consumes: None (initial setup)
- Produces: Working Jekyll 4.x environment configuration with defined collections (`labs`, `team`, `projects`, `news`), markdown processor settings, baseurl settings for local and preview, and Docker/Dev Container recipes.

- [ ] **Step 1: Create Gemfile and Gemfile lock dependencies**

```ruby
# Gemfile
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
  gem "rake", "~> 13.1"
end
```

- [ ] **Step 2: Create Dockerfile, compose.yml, and .devcontainer/devcontainer.json**

```dockerfile
# Dockerfile
FROM ruby:3.3-bookworm

RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
      build-essential \
      git \
      curl \
      nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY Gemfile Gemfile.lock* ./
RUN bundle config set --local path "vendor/bundle" && \
    bundle install

EXPOSE 4000 35729

CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--port", "4000", "--livereload"]
```

```yaml
# compose.yml
services:
  site:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - .:/workspace
      - bundle_cache:/workspace/vendor/bundle
    ports:
      - "4000:4000"
      - "35729:35729"
    environment:
      - JEKYLL_ENV=development
    command: bundle exec jekyll serve --host 0.0.0.0 --port 4000 --livereload --force_polling

volumes:
  bundle_cache:
```

```json
// .devcontainer/devcontainer.json
{
  "name": "PFCL Website",
  "dockerComposeFile": "../compose.yml",
  "service": "site",
  "workspaceFolder": "/workspace",
  "customizations": {
    "vscode": {
      "extensions": [
        "rebornix.Ruby",
        "sibiraj-s.vscode-scss-formatter",
        "DavidAnson.vscode-markdownlint"
      ]
    }
  },
  "forwardPorts": [4000, 35729]
}
```

```text
# .gitignore
_site/
.sass-cache/
.jekyll-cache/
.jekyll-metadata
vendor/
.bundle/
node_modules/
.DS_Store
*.log
```

```text
# .dockerignore
_site/
.git/
.sass-cache/
.jekyll-cache/
vendor/bundle/
```

- [ ] **Step 3: Create _config.yml and _config.preview.yml**

```yaml
# _config.yml
title: "Philadelphia Flight Control Laboratory"
tagline: "Aerospace Systems, Autonomous Flight & Navigation Research"
description: "The Philadelphia Flight Control Laboratory (PFCL) at the Technion Faculty of Aerospace Engineering is the umbrella research facility for autonomous navigation, perception, control, and aerospace systems."
email: "pfcl@technion.ac.il"
url: "https://pfcl-technion.github.io"
baseurl: ""

theme: "bulma-clean-theme"

plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap

collections:
  labs:
    output: true
    permalink: /labs/:slug/
  team:
    output: true
    permalink: /team/:slug/
  projects:
    output: true
    permalink: /projects/:slug/
  news:
    output: true
    permalink: /news/:year/:month/:day/:slug/

defaults:
  - scope:
      path: ""
      type: "labs"
    values:
      layout: "lab"
  - scope:
      path: ""
      type: "team"
    values:
      layout: "page"
  - scope:
      path: ""
      type: "projects"
    values:
      layout: "project"
  - scope:
      path: ""
      type: "news"
    values:
      layout: "page"

sass:
  style: compressed
  sass_dir: _sass

markdown: kramdown
kramdown:
  input: GFM
  hard_wrap: false
  syntax_highlighter: rouge

include:
  - _data
```

```yaml
# _config.preview.yml
url: "https://philadelphia-flight-control-laboratory.github.io"
baseurl: "/pfcl-technion.github.io"
```

- [ ] **Step 4: Commit environment scaffolding**

```bash
git add Gemfile Dockerfile compose.yml .devcontainer/devcontainer.json _config.yml _config.preview.yml .gitignore .dockerignore
git commit -m "chore: scaffold Jekyll environment and configuration"
```

---

### Task 2: Content Schemas, Taxonomies, Reserved Contracts & Seed Data

**Files:**
- Create: `_data/taxonomies.yml`
- Create: `_data/navigation.yml`
- Create: `_data/generated/updates.json`
- Create: `_labs/anpl.md`
- Create: `_labs/connect.md`
- Create: `_labs/casy.md`
- Create: `_labs/flight-control-teaching-lab.md`
- Create: `_team/vadim-indelman.md`
- Create: `_team/tal-shima.md`
- Create: `_team/ruslan-arhipov.md`
- Create: `_projects/multi-uav-active-slam.md`
- Create: `_projects/cooperative-evasion-guidance.md`
- Create: `_news/2026-08-27-pfcl-website-launched.md`

**Interfaces:**
- Consumes: `_config.yml` collection definitions
- Produces: Seed content adhering strictly to YAML frontmatter schema definitions for validation tests.

- [ ] **Step 1: Create _data/taxonomies.yml and _data/navigation.yml**

```yaml
# _data/taxonomies.yml
lab_kinds:
  - id: research-group
    label: "Research Group"
    description: "Principal research laboratory or group within PFCL"
  - id: teaching-lab
    label: "Teaching Laboratory"
    description: "Laboratory supporting undergraduate and graduate coursework and teaching experiments"
  - id: shared-facility
    label: "Shared Facility"
    description: "Shared infrastructure, flight testing areas, and equipment"

team_categories:
  - id: leadership
    label: "Leadership & Directors"
    order: 1
  - id: faculty
    label: "Faculty Members"
    order: 2
  - id: research-staff
    label: "Research Scientists & Postdocs"
    order: 3
  - id: lab-staff
    label: "Lab Engineers & Technical Staff"
    order: 4
  - id: visiting
    label: "Visiting Researchers"
    order: 5
  - id: emeritus
    label: "Emeritus Faculty"
    order: 6

recruitment_statuses:
  - id: available
    label: "Available / Recruiting"
    badge_class: "is-success"
  - id: ongoing
    label: "Ongoing"
    badge_class: "is-info"
  - id: completed
    label: "Completed"
    badge_class: "is-light"

project_types:
  - id: research
    label: "Theoretical & Algorithmic Research"
  - id: experimental
    label: "Flight Testing & Experimental"
  - id: software
    label: "Software & Simulation"
  - id: hardware
    label: "Avionics & Hardware Design"
  - id: teaching
    label: "Teaching & Capstone"

student_levels:
  - id: undergraduate
    label: "Undergraduate (B.Sc.)"
  - id: master
    label: "Master (M.Sc.)"
  - id: phd
    label: "Doctoral (Ph.D.)"

news_categories:
  - id: news
    label: "News"
  - id: event
    label: "Event & Seminar"
  - id: publication
    label: "Publication Highlight"
  - id: project
    label: "Project Update"
  - id: award
    label: "Award & Honor"
  - id: position
    label: "Open Position"
  - id: research-highlight
    label: "Research Highlight"
```

```yaml
# _data/navigation.yml
main:
  - title: "Home"
    url: "/"
  - title: "About"
    url: "/about/"
    children:
      - title: "About PFCL"
        url: "/about/"
      - title: "History"
        url: "/history/"
      - title: "PFCL Dedication"
        url: "/dedication/"
      - title: "Team"
        url: "/team/"
  - title: "Research Groups"
    url: "/labs/"
  - title: "Student Projects"
    url: "/projects/"
  - title: "Teaching Labs"
    url: "/teaching/"
  - title: "News"
    url: "/news/"
  - title: "Media"
    url: "/media/"
  - title: "Contact"
    url: "/contact/"

footer:
  - title: "Faculty of Aerospace Engineering"
    url: "https://aerospace.technion.ac.il"
  - title: "Technion - Israel Institute of Technology"
    url: "https://www.technion.ac.il"
  - title: "ANPL"
    url: "https://anpl-technion.github.io/"
```

- [ ] **Step 2: Create _data/generated/updates.json reserved contract**

```json
[]
```

- [ ] **Step 3: Create seed collections for _labs, _team, _projects, and _news**

```markdown
---
title: Autonomous Navigation and Perception Lab
short_name: ANPL
slug: anpl
kind: research-group
leader_names:
  - Vadim Indelman
summary: ANPL conducts fundamental and applied research in autonomous navigation, perception, simultaneous localization and mapping (SLAM), planning under uncertainty, and multi-robot systems.
website: https://anpl-technion.github.io/
email: vadim.indelman@technion.ac.il
active: true
order: 10
research_topics:
  - SLAM and State Estimation
  - Decision Making under Uncertainty
  - Active Perception and Information Acquisition
  - Multi-Robot Cooperative Navigation
---

The Autonomous Navigation and Perception Laboratory (ANPL) investigates advanced algorithmic solutions for autonomous systems operating in GPS-denied and uncertain environments.
```

```markdown
---
title: Control and Navigation Systems Laboratory
short_name: ConNect
slug: connect
kind: research-group
leader_names:
  - Tal Shima
summary: ConNect focuses on guidance, navigation, and control (GNC) of autonomous flight vehicles, cooperative missile defense, differential games, and interceptor guidance algorithms.
website: https://connect.net.technion.ac.il/
active: true
order: 20
research_topics:
  - Advanced Guidance Laws
  - Cooperative Control of Interceptors
  - Differential Games in Flight Mechanics
  - Autonomous Flight Vehicle Control
---

The Control and Navigation Systems Laboratory (ConNect) develops novel guidance and control architectures for aerospace systems.
```

```markdown
---
title: Complex Autonomous Systems Laboratory
short_name: CASY
slug: casy
kind: research-group
leader_names:
  - Nahum Shimkin
summary: CASY conducts research into decision-making, game-theoretic control, distributed multi-agent systems, and reinforcement learning for autonomous aerospace agents.
website: https://aerospace.technion.ac.il/person/nahum-shimkin/
active: true
order: 30
research_topics:
  - Multi-Agent Decision Making
  - Reinforcement Learning for Control
  - Game Theory in Autonomous Systems
---

CASY focuses on mathematical and algorithmic foundations of complex autonomous systems.
```

```markdown
---
title: Flight Control Teaching Laboratory
short_name: Flight Control Teaching Lab
slug: flight-control-teaching-lab
kind: teaching-lab
leader_names:
  - Ruslan Arhipov
summary: The Flight Control Teaching Laboratory supports undergraduate aerospace laboratory experiments in aerodynamics, flight mechanics, PID/state-space attitude control, and drone test benches.
website: https://aerospace.technion.ac.il/
active: true
order: 40
research_topics:
  - Undergraduate Flight Dynamics Labs
  - Quadrotor Testbed Control Experiments
  - Hardware-in-the-Loop Simulation
---

This teaching lab hosts core undergraduate experimental courses in flight dynamics and control.
```

```markdown
---
title: Prof. Vadim Indelman
slug: vadim-indelman
role: Associate Professor & PFCL Director
category: leadership
lab_ids:
  - anpl
  - pfcl
email: vadim.indelman@technion.ac.il
website: https://anpl-technion.github.io/
active: true
order: 10
bio: Vadim Indelman is an Associate Professor at the Faculty of Aerospace Engineering and Director of the Philadelphia Flight Control Laboratory.
---
```

```markdown
---
title: Prof. Tal Shima
slug: tal-shima
role: Professor & Head of ConNect Lab
category: faculty
lab_ids:
  - connect
email: tal.shima@technion.ac.il
website: https://connect.net.technion.ac.il/
active: true
order: 20
bio: Tal Shima is a Professor of Aerospace Engineering specializing in guidance, control, and multi-agent differential games.
---
```

```markdown
---
title: Ruslan Arhipov
slug: ruslan-arhipov
role: Flight Control Laboratory Engineer & Manager
category: lab-staff
lab_ids:
  - pfcl
  - flight-control-teaching-lab
email: sarchi@technion.ac.il
active: true
order: 30
bio: Ruslan Arhipov manages the PFCL experimental facilities, avionics infrastructure, and teaching laboratories.
---
```

```markdown
---
title: Multi-UAV Active SLAM in GPS-Denied Environments
slug: multi-uav-active-slam
lab_ids:
  - anpl
recruitment_status: available
project_types:
  - research
  - experimental
student_levels:
  - undergraduate
  - master
advisor_names:
  - Prof. Vadim Indelman
summary: Develop active SLAM strategies for a team of autonomous quadrotors exploring unknown environments with communication constraints.
contact_email: vadim.indelman@technion.ac.il
published: true
updated_at: 2026-08-27
featured: true
show_on_showcase: true
duration: 1-2 semesters
skills:
  - ROS / ROS2
  - C++ / Python
  - Optimization & Linear Algebra
---

This project tackles active perception and cooperative mapping under uncertainty.
```

```markdown
---
title: Cooperative Evasion Guidance Laws for Aerial Vehicles
slug: cooperative-evasion-guidance
lab_ids:
  - connect
recruitment_status: available
project_types:
  - research
  - software
student_levels:
  - undergraduate
advisor_names:
  - Prof. Tal Shima
summary: Formulate differential-game guidance algorithms for multi-agent aerial evasion against pursuers.
contact_email: tal.shima@technion.ac.il
published: true
updated_at: 2026-08-27
featured: false
show_on_showcase: true
duration: 2 semesters
skills:
  - MATLAB / Simulink
  - Optimal Control
---

Investigate cooperative pursuit-evasion game formulation with simulation validation.
```

```markdown
---
title: PFCL Launches New Web Platform and Project Showcase
date: 2026-08-27
lab_id: pfcl
category: news
excerpt: The Philadelphia Flight Control Laboratory has unveiled its new institutional web platform, presenting unified research activities, teaching facilities, and student projects.
canonical_url: https://philadelphia-flight-control-laboratory.github.io/pfcl-technion.github.io/news/2026/08/27/pfcl-website-launched/
source_name: PFCL
featured: true
show_on_showcase: true
---

The new PFCL website provides students and researchers with a single window into all flight control, autonomous navigation, and aerospace systems research groups at the Technion.
```

- [ ] **Step 4: Commit seed data and taxonomies**

```bash
git add _data _labs _team _projects _news
git commit -m "feat: add taxonomies, reserved data contracts, and seed content collections"
```

---

### Task 3: Content Validator Script & Comprehensive Test Suite

**Files:**
- Create: `scripts/validate_content.rb`
- Create: `test/content_validation_test.rb`

**Interfaces:**
- Consumes: YAML frontmatter from `_labs/`, `_team/`, `_projects/`, `_news/`, `_data/taxonomies.yml`, and `_data/generated/updates.json`
- Produces: Executable validation script exiting with 0 on success or >0 with descriptive errors on validation failure; Minitest test suite covering all positive and negative constraints.

- [ ] **Step 1: Write test suite covering validation rules (TDD)**

```ruby
# test/content_validation_test.rb
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
    errors = @validator.validate_project_data(data, "proj.md", ["proj-no-contact"], ["anpl"])
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
    errors = @validator.validate_project_data(data, "proj.md", ["multi-lab-proj"], ["anpl", "connect"])
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
```

- [ ] **Step 2: Implement scripts/validate_content.rb**

```ruby
#!/usr/bin/env ruby
# scripts/validate_content.rb
require "yaml"
require "json"
require "date"
require "uri"

class ContentValidator
  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  SLUG_REGEX = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  ALLOWED_LAB_KINDS = %w[research-group teaching-lab shared-facility].freeze
  ALLOWED_TEAM_CATEGORIES = %w[leadership faculty research-staff lab-staff visiting emeritus].freeze
  ALLOWED_RECRUITMENT_STATUSES = %w[available ongoing completed].freeze
  ALLOWED_PROJECT_TYPES = %w[research experimental software hardware teaching].freeze
  ALLOWED_STUDENT_LEVELS = %w[undergraduate master phd].freeze
  ALLOWED_NEWS_CATEGORIES = %w[news event publication project award position research-highlight].freeze

  def initialize(root_dir = ".")
    @root_dir = File.expand_path(root_dir)
  end

  def run
    errors = validate_all
    if errors.empty?
      puts "Content validation passed successfully."
      exit 0
    else
      warn "Content validation failed with #{errors.size} error(s):"
      errors.each { |err| warn "  - #{err}" }
      exit 1
    end
  end

  def validate_all
    errors = []
    known_lab_slugs = ["pfcl"]

    # 1. Parse and validate _labs
    lab_files = Dir[File.join(@root_dir, "_labs", "*.md")]
    lab_slugs_seen = []
    lab_files.each do |file|
      data = parse_frontmatter(file, errors)
      next unless data
      slug = data["slug"]
      if slug && SLUG_REGEX.match?(slug)
        if lab_slugs_seen.include?(slug)
          errors << "#{file}: duplicate lab slug '#{slug}'"
        else
          lab_slugs_seen << slug
          known_lab_slugs << slug
        end
      end
      errors.concat(validate_lab_data(data, file, lab_slugs_seen))
    end

    # 2. Parse and validate _team
    team_files = Dir[File.join(@root_dir, "_team", "*.md")]
    team_slugs_seen = []
    team_files.each do |file|
      data = parse_frontmatter(file, errors)
      next unless data
      errors.concat(validate_team_data(data, file, team_slugs_seen, known_lab_slugs))
    end

    # 3. Parse and validate _projects
    project_files = Dir[File.join(@root_dir, "_projects", "*.md")]
    project_slugs_seen = []
    project_files.each do |file|
      data = parse_frontmatter(file, errors)
      next unless data
      errors.concat(validate_project_data(data, file, project_slugs_seen, known_lab_slugs))
    end

    # 4. Parse and validate _news
    news_files = Dir[File.join(@root_dir, "_news", "*.md")]
    news_files.each do |file|
      data = parse_frontmatter(file, errors)
      next unless data
      errors.concat(validate_news_data(data, file, known_lab_slugs))
    end

    # 5. Validate generated updates JSON
    updates_path = File.join(@root_dir, "_data", "generated", "updates.json")
    if File.exist?(updates_path)
      begin
        updates_data = JSON.parse(File.read(updates_path))
        errors.concat(validate_generated_updates(updates_data))
      rescue JSON::ParserError => e
        errors << "#{updates_path}: invalid JSON (#{e.message})"
      end
    end

    errors
  end

  def parse_frontmatter(file_path, errors)
    content = File.read(file_path)
    if content =~ /\A(---\s*\n.*?\n?)^(---\s*$\n?)/m
      begin
        YAML.safe_load(Regexp.last_match(1), permitted_classes: [Date, Time])
      rescue => e
        errors << "#{file_path}: YAML parsing error: #{e.message}"
        nil
      end
    else
      errors << "#{file_path}: missing YAML frontmatter"
      nil
    end
  end

  def validate_lab_data(data, file, _seen_slugs)
    errs = []
    req_fields = %w[title short_name slug kind leader_names summary website active order]
    req_fields.each do |f|
      errs << "#{file}: missing required field '#{f}'" if data[f].nil? || (data[f].is_a?(String) && data[f].strip.empty?)
    end
    if data["slug"] && !SLUG_REGEX.match?(data["slug"])
      errs << "#{file}: invalid slug '#{data["slug"]}' (must be lowercase alphanumeric and hyphens)"
    end
    if data["kind"] && !ALLOWED_LAB_KINDS.include?(data["kind"])
      errs << "#{file}: invalid kind '#{data["kind"]}'. Allowed: #{ALLOWED_LAB_KINDS.join(", ")}"
    end
    if data["leader_names"] && !data["leader_names"].is_a?(Array)
      errs << "#{file}: 'leader_names' must be an array"
    end
    if data["website"] && !valid_url?(data["website"])
      errs << "#{file}: invalid website URL '#{data["website"]}'"
    end
    if data["email"] && !valid_email?(data["email"])
      errs << "#{file}: invalid email '#{data["email"]}'"
    end
    errs
  end

  def validate_team_data(data, file, seen_slugs, known_lab_slugs)
    errs = []
    req_fields = %w[title slug role category lab_ids active order]
    req_fields.each do |f|
      errs << "#{file}: missing required field '#{f}'" if data[f].nil? || (data[f].is_a?(String) && data[f].strip.empty?)
    end
    if data["slug"]
      if !SLUG_REGEX.match?(data["slug"])
        errs << "#{file}: invalid slug '#{data["slug"]}'"
      elsif seen_slugs.include?(data["slug"])
        errs << "#{file}: duplicate team slug '#{data["slug"]}'"
      else
        seen_slugs << data["slug"]
      end
    end
    if data["category"] && !ALLOWED_TEAM_CATEGORIES.include?(data["category"])
      errs << "#{file}: invalid category '#{data["category"]}'. Allowed: #{ALLOWED_TEAM_CATEGORIES.join(", ")}"
    end
    if data["lab_ids"]
      if !data["lab_ids"].is_a?(Array) || data["lab_ids"].empty?
        errs << "#{file}: 'lab_ids' must be a non-empty array"
      else
        data["lab_ids"].each do |lab_id|
          unless known_lab_slugs.include?(lab_id)
            errs << "#{file}: references unknown lab_id '#{lab_id}'"
          end
        end
      end
    end
    if data["email"] && !valid_email?(data["email"])
      errs << "#{file}: invalid email '#{data["email"]}'"
    end
    errs
  end

  def validate_project_data(data, file, seen_slugs, known_lab_slugs)
    errs = []
    req_fields = %w[title slug lab_ids recruitment_status project_types student_levels advisor_names summary published updated_at]
    req_fields.each do |f|
      errs << "#{file}: missing required field '#{f}'" if data[f].nil? || (data[f].is_a?(String) && data[f].strip.empty?)
    end
    if data["slug"]
      if !SLUG_REGEX.match?(data["slug"])
        errs << "#{file}: invalid slug '#{data["slug"]}'"
      elsif seen_slugs.include?(data["slug"])
        errs << "#{file}: duplicate project slug '#{data["slug"]}'"
      else
        seen_slugs << data["slug"]
      end
    end
    if data["recruitment_status"] && !ALLOWED_RECRUITMENT_STATUSES.include?(data["recruitment_status"])
      errs << "#{file}: invalid recruitment_status '#{data["recruitment_status"]}'. Allowed: #{ALLOWED_RECRUITMENT_STATUSES.join(", ")}"
    end
    if data["recruitment_status"] == "available"
      if data["contact_email"].nil? || data["contact_email"].strip.empty? || !valid_email?(data["contact_email"])
        errs << "#{file}: available project must have 'contact_email' with a valid email address"
      end
    end
    if data["project_types"]
      if !data["project_types"].is_a?(Array) || data["project_types"].empty?
        errs << "#{file}: 'project_types' must be a non-empty array"
      else
        data["project_types"].each do |pt|
          errs << "#{file}: invalid project_type '#{pt}'" unless ALLOWED_PROJECT_TYPES.include?(pt)
        end
      end
    end
    if data["student_levels"]
      if !data["student_levels"].is_a?(Array) || data["student_levels"].empty?
        errs << "#{file}: 'student_levels' must be a non-empty array"
      else
        data["student_levels"].each do |sl|
          errs << "#{file}: invalid student_level '#{sl}'" unless ALLOWED_STUDENT_LEVELS.include?(sl)
        end
      end
    end
    if data["lab_ids"]
      if !data["lab_ids"].is_a?(Array) || data["lab_ids"].empty?
        errs << "#{file}: 'lab_ids' must be a non-empty array"
      else
        data["lab_ids"].each do |lab_id|
          unless known_lab_slugs.include?(lab_id)
            errs << "#{file}: references unknown lab_id '#{lab_id}'"
          end
        end
      end
    end
    errs
  end

  def validate_news_data(data, file, known_lab_slugs)
    errs = []
    req_fields = %w[title date lab_id category excerpt canonical_url source_name]
    req_fields.each do |f|
      errs << "#{file}: missing required field '#{f}'" if data[f].nil? || (data[f].is_a?(String) && data[f].strip.empty?)
    end
    if data["category"] && !ALLOWED_NEWS_CATEGORIES.include?(data["category"])
      errs << "#{file}: invalid category '#{data["category"]}'. Allowed: #{ALLOWED_NEWS_CATEGORIES.join(", ")}"
    end
    if data["lab_id"] && !known_lab_slugs.include?(data["lab_id"])
      errs << "#{file}: references unknown lab_id '#{data["lab_id"]}'"
    end
    if data["canonical_url"] && !valid_url?(data["canonical_url"])
      errs << "#{file}: invalid canonical_url '#{data["canonical_url"]}'"
    end
    errs
  end

  def validate_generated_updates(updates)
    errs = []
    unless updates.is_a?(Array)
      return ["_data/generated/updates.json: root element must be a JSON array"]
    end
    req_keys = %w[id title published_at lab_id category excerpt canonical_url source_name]
    updates.each_with_index do |item, idx|
      req_keys.each do |k|
        errs << "_data/generated/updates.json[#{idx}]: missing required key '#{k}'" if item[k].nil?
      end
      if item["canonical_url"] && !valid_url?(item["canonical_url"])
        errs << "_data/generated/updates.json[#{idx}]: invalid canonical_url '#{item["canonical_url"]}'"
      end
    end
    errs
  end

  private

  def valid_url?(string)
    uri = URI.parse(string.to_s)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end

  def valid_email?(string)
    EMAIL_REGEX.match?(string.to_s)
  end
end

if __FILE__ == $PROGRAM_NAME
  ContentValidator.new(".").run
end
```

- [ ] **Step 3: Run the test suite and verify**

```bash
ruby -Itest test/content_validation_test.rb
```

- [ ] **Step 4: Commit validator and tests**

```bash
git add scripts/validate_content.rb test/content_validation_test.rb
git commit -m "feat: implement content validator and unit tests"
```

---

### Task 4: SASS Styling, Bulma Theme Layering & Progressive Enhancement

**Files:**
- Create: `_sass/_pfcl_variables.scss`
- Create: `_sass/_pfcl_components.scss`
- Create: `_sass/custom.scss`
- Create: `assets/css/main.scss`
- Create: `assets/js/main.js`

**Interfaces:**
- Consumes: Bulma Clean Theme Sass variables and structure
- Produces: Accessible styling complying with WCAG 2.2 AA (color contrast >= 4.5:1 for body text, >= 3:1 for large headers and UI controls), responsive navbar toggle, card layouts, filter UI styling, and keyboard focus styles.

- [ ] **Step 1: Create _sass/_pfcl_variables.scss and _sass/_pfcl_components.scss**

```scss
// _sass/_pfcl_variables.scss
$pfcl-navy: #002b49;
$pfcl-navy-dark: #001a2c;
$pfcl-blue: #005691;
$pfcl-blue-light: #e8f1f8;
$pfcl-gold: #c69214;
$pfcl-slate: #4a5568;
$pfcl-light-bg: #f8fafc;
$pfcl-border: #cbd5e1;

$primary: $pfcl-navy;
$link: $pfcl-blue;
$family-sans-serif: system-ui, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
```

```scss
// _sass/_pfcl_components.scss
.pfcl-hero {
  background: linear-gradient(135deg, $pfcl-navy 0%, $pfcl-navy-dark 100%);
  color: #ffffff;
  padding: 3.5rem 1.5rem;

  .title {
    color: #ffffff !important;
    font-weight: 700;
    letter-spacing: -0.02em;
  }

  .subtitle {
    color: #e2e8f0 !important;
    max-width: 800px;
  }
}

.pfcl-card {
  height: 100%;
  display: flex;
  flex-direction: column;
  border: 1px solid $pfcl-border;
  border-radius: 6px;
  background-color: #ffffff;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  transition: transform 0.15s ease, box-shadow 0.15s ease;

  &:hover {
    box-shadow: 0 6px 16px rgba(0, 0, 0, 0.08);
    transform: translateY(-2px);
  }

  .card-content {
    flex-grow: 1;
    display: flex;
    flex-direction: column;
  }

  .card-footer {
    margin-top: auto;
    border-top: 1px solid #f1f5f9;
  }
}

.pfcl-badge-group {
  display: flex;
  flex-wrap: wrap;
  gap: 0.35rem;
  margin-bottom: 0.75rem;
}

.pfcl-filter-bar {
  background-color: $pfcl-light-bg;
  border: 1px solid $pfcl-border;
  border-radius: 6px;
  padding: 1.25rem;
  margin-bottom: 2rem;
}

.is-hidden-by-filter {
  display: none !important;
}

@media (prefers-reduced-motion: reduce) {
  .pfcl-card {
    transition: none !important;
    &:hover {
      transform: none !important;
    }
  }
}
```

```scss
// _sass/custom.scss
@import "pfcl_variables";
@import "pfcl_components";

a:focus-visible, button:focus-visible, select:focus-visible, input:focus-visible {
  outline: 3px solid #ffbf47 !important;
  outline-offset: 2px !important;
}
```

- [ ] **Step 2: Create assets/css/main.scss and assets/js/main.js**

```scss
---
---
@import "bulma";
@import "custom";
```

```javascript
// assets/js/main.js
document.addEventListener("DOMContentLoaded", function () {
  // Mobile navbar burger toggle
  const burgers = Array.prototype.slice.call(document.querySelectorAll(".navbar-burger"), 0);
  if (burgers.length > 0) {
    burgers.forEach(function (el) {
      el.addEventListener("click", function () {
        const target = el.dataset.target;
        const targetEl = document.getElementById(target);
        el.classList.toggle("is-active");
        if (targetEl) {
          targetEl.classList.toggle("is-active");
        }
      });
    });
  }

  // Project directory client-side interactive filtering
  const projectCards = document.querySelectorAll(".pfcl-project-item");
  const filterLab = document.getElementById("filter-lab");
  const filterStatus = document.getElementById("filter-status");
  const filterType = document.getElementById("filter-type");
  const filterLevel = document.getElementById("filter-level");
  const countBadge = document.getElementById("filtered-count");

  function applyFilters() {
    if (!projectCards.length) return;

    const selectedLab = filterLab ? filterLab.value : "all";
    const selectedStatus = filterStatus ? filterStatus.value : "all";
    const selectedType = filterType ? filterType.value : "all";
    const selectedLevel = filterLevel ? filterLevel.value : "all";

    let visibleCount = 0;

    projectCards.forEach(function (card) {
      const labs = (card.dataset.labs || "").split(",");
      const status = card.dataset.status || "";
      const types = (card.dataset.types || "").split(",");
      const levels = (card.dataset.levels || "").split(",");

      const matchLab = (selectedLab === "all") || labs.includes(selectedLab);
      const matchStatus = (selectedStatus === "all") || (status === selectedStatus);
      const matchType = (selectedType === "all") || types.includes(selectedType);
      const matchLevel = (selectedLevel === "all") || levels.includes(selectedLevel);

      if (matchLab && matchStatus && matchType && matchLevel) {
        card.classList.remove("is-hidden-by-filter");
        visibleCount++;
      } else {
        card.classList.add("is-hidden-by-filter");
      }
    });

    if (countBadge) {
      countBadge.textContent = visibleCount + " project" + (visibleCount === 1 ? "" : "s") + " matching";
    }
  }

  if (filterLab) filterLab.addEventListener("change", applyFilters);
  if (filterStatus) filterStatus.addEventListener("change", applyFilters);
  if (filterType) filterType.addEventListener("change", applyFilters);
  if (filterLevel) filterLevel.addEventListener("change", applyFilters);

  const resetBtn = document.getElementById("filter-reset-btn");
  if (resetBtn) {
    resetBtn.addEventListener("click", function () {
      if (filterLab) filterLab.value = "all";
      if (filterStatus) filterStatus.value = "all";
      if (filterType) filterType.value = "all";
      if (filterLevel) filterLevel.value = "all";
      applyFilters();
    });
  }
});
```

- [ ] **Step 3: Commit CSS and JS assets**

```bash
git add _sass assets
git commit -m "feat: implement Bulma SCSS layering, accessible styling, and progressive filter script"
```

---

### Task 5: Layouts, Partials & UI Component Includes

**Files:**
- Create: `_includes/header.html`
- Create: `_includes/nav.html`
- Create: `_includes/footer.html`
- Create: `_includes/lab_card.html`
- Create: `_includes/team_card.html`
- Create: `_includes/project_card.html`
- Create: `_includes/news_card.html`
- Create: `_includes/project_filters.html`
- Create: `_layouts/default.html`
- Create: `_layouts/page.html`
- Create: `_layouts/lab.html`
- Create: `_layouts/project.html`

**Interfaces:**
- Consumes: `_data/navigation.yml`, collection items, `assets/css/main.scss`, `assets/js/main.js`
- Produces: Modular, accessible Jekyll layouts and cards supporting header navigation dropdowns, hero headers, breadcrumbs, card grids, and semantic HTML markup.

- [ ] **Step 1: Create navigation and layout includes**

```html
<!-- _includes/nav.html -->
<nav class="navbar is-dark" role="navigation" aria-label="main navigation">
  <div class="container">
    <div class="navbar-brand">
      <a class="navbar-item has-text-weight-bold is-size-5" href="{{ '/' | relative_url }}">
        PFCL
      </a>
      <a role="button" class="navbar-burger" aria-label="menu" aria-expanded="false" data-target="pfclNavbar">
        <span aria-hidden="true"></span>
        <span aria-hidden="true"></span>
        <span aria-hidden="true"></span>
      </a>
    </div>

    <div id="pfclNavbar" class="navbar-menu">
      <div class="navbar-end">
        {% for item in site.data.navigation.main %}
          {% if item.children %}
            <div class="navbar-item has-dropdown is-hoverable">
              <a class="navbar-link">{{ item.title }}</a>
              <div class="navbar-dropdown">
                {% for sub in item.children %}
                  <a class="navbar-item" href="{{ sub.url | relative_url }}">{{ sub.title }}</a>
                {% endfor %}
              </div>
            </div>
          {% else %}
            <a class="navbar-item" href="{{ item.url | relative_url }}">{{ item.title }}</a>
          {% endif %}
        {% endfor %}
      </div>
    </div>
  </div>
</nav>
```

```html
<!-- _includes/header.html -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{% if page.title %}{{ page.title }} | {% endif %}{{ site.title }}</title>
  <meta name="description" content="{{ page.excerpt | default: page.summary | default: site.description | strip_html | strip_newlines | truncate: 160 }}">
  <link rel="stylesheet" href="{{ '/assets/css/main.css' | relative_url }}">
  {% seo %}
</head>
<body class="has-navbar-fixed-top-widescreen">
  {% include nav.html %}
```

```html
<!-- _includes/footer.html -->
  <footer class="footer mt-6" style="background-color: #001a2c; color: #cbd5e1;">
    <div class="container">
      <div class="columns">
        <div class="column is-5">
          <h3 class="title is-5 has-text-white">{{ site.title }}</h3>
          <p class="is-size-6">
            Faculty of Aerospace Engineering<br>
            Technion - Israel Institute of Technology<br>
            Haifa 3200003, Israel
          </p>
          <p class="is-size-7 mt-2">
            Email: <a href="mailto:{{ site.email }}" class="has-text-info-light">{{ site.email }}</a>
          </p>
        </div>
        <div class="column is-4">
          <h4 class="title is-6 has-text-white">Affiliations & Links</h4>
          <ul>
            {% for link in site.data.navigation.footer %}
              <li><a href="{{ link.url }}" class="has-text-info-light" target="_blank" rel="noopener">{{ link.title }}</a></li>
            {% endfor %}
          </ul>
        </div>
        <div class="column is-3">
          <h4 class="title is-6 has-text-white">Quick Routes</h4>
          <ul>
            <li><a href="{{ '/projects/' | relative_url }}" class="has-text-info-light">Student Projects</a></li>
            <li><a href="{{ '/labs/' | relative_url }}" class="has-text-info-light">Research Groups</a></li>
            <li><a href="{{ '/contact/' | relative_url }}" class="has-text-info-light">Contact & Directions</a></li>
          </ul>
        </div>
      </div>
      <div class="content has-text-centered has-text-grey-light is-size-7 mt-5">
        <p>&copy; {{ 'now' | date: "%Y" }} Philadelphia Flight Control Laboratory, Technion. All rights reserved.</p>
      </div>
    </div>
  </footer>
  <script src="{{ '/assets/js/main.js' | relative_url }}"></script>
</body>
</html>
```

- [ ] **Step 2: Create reusable component cards and filter include**

```html
<!-- _includes/lab_card.html -->
<div class="pfcl-card">
  <div class="card-content">
    <div class="pfcl-badge-group">
      <span class="tag is-info is-light">{{ include.lab.kind | replace: "-", " " | capitalize }}</span>
      {% if include.lab.short_name %}
        <span class="tag is-primary is-light has-text-weight-bold">{{ include.lab.short_name }}</span>
      {% endif %}
    </div>
    <h3 class="title is-5 mb-2">
      <a href="{{ include.lab.url | relative_url }}">{{ include.lab.title }}</a>
    </h3>
    <p class="is-size-7 has-text-grey mb-3">
      <strong>Leader:</strong> {{ include.lab.leader_names | join: ", " }}
    </p>
    <p class="is-size-6 mb-4">{{ include.lab.summary }}</p>
    {% if include.lab.research_topics %}
      <div class="tags are-small mt-auto">
        {% for topic in include.lab.research_topics limit:3 %}
          <span class="tag is-rounded">{{ topic }}</span>
        {% endfor %}
      </div>
    {% endif %}
  </div>
  <footer class="card-footer">
    <a href="{{ include.lab.url | relative_url }}" class="card-footer-item">Lab Overview &rarr;</a>
    {% if include.lab.website %}
      <a href="{{ include.lab.website }}" class="card-footer-item" target="_blank" rel="noopener">External Site &nearr;</a>
    {% endif %}
  </footer>
</div>
```

```html
<!-- _includes/project_card.html -->
<div class="pfcl-project-item pfcl-card"
     data-labs="{{ include.project.lab_ids | join: ',' }}"
     data-status="{{ include.project.recruitment_status }}"
     data-types="{{ include.project.project_types | join: ',' }}"
     data-levels="{{ include.project.student_levels | join: ',' }}">
  <div class="card-content">
    <div class="pfcl-badge-group">
      {% if include.project.recruitment_status == "available" %}
        <span class="tag is-success">Recruiting</span>
      {% elsif include.project.recruitment_status == "ongoing" %}
        <span class="tag is-info is-light">Ongoing</span>
      {% else %}
        <span class="tag is-light">Completed</span>
      {% endif %}
      {% for lab_id in include.project.lab_ids %}
        <span class="tag is-dark is-light">{{ lab_id | upcase }}</span>
      {% endfor %}
    </div>
    <h3 class="title is-5 mb-2">
      <a href="{{ include.project.url | relative_url }}">{{ include.project.title }}</a>
    </h3>
    <p class="is-size-7 has-text-grey mb-2">
      <strong>Advisors:</strong> {{ include.project.advisor_names | join: ", " }}
    </p>
    <p class="is-size-6 mb-3">{{ include.project.summary }}</p>
    {% if include.project.skills %}
      <div class="tags are-small mb-3">
        {% for skill in include.project.skills %}
          <span class="tag is-white" style="border: 1px solid #e2e8f0;">{{ skill }}</span>
        {% endfor %}
      </div>
    {% endif %}
  </div>
  <footer class="card-footer">
    <a href="{{ include.project.url | relative_url }}" class="card-footer-item">Details</a>
    {% if include.project.contact_email and include.project.recruitment_status == "available" %}
      <a href="mailto:{{ include.project.contact_email }}?subject=PFCL%20Project%20Inquiry:%20{{ include.project.title | url_encode }}" class="card-footer-item has-text-weight-semibold">Apply / Contact</a>
    {% endif %}
  </footer>
</div>
```

```html
<!-- _includes/team_card.html -->
<div class="pfcl-card">
  <div class="card-content">
    <h3 class="title is-5 mb-1">{{ include.person.title }}</h3>
    <p class="subtitle is-6 has-text-grey mb-2">{{ include.person.role }}</p>
    <div class="pfcl-badge-group">
      {% for lab_id in include.person.lab_ids %}
        <span class="tag is-info is-light">{{ lab_id | upcase }}</span>
      {% endfor %}
    </div>
    {% if include.person.bio %}
      <p class="is-size-6 mt-2">{{ include.person.bio }}</p>
    {% endif %}
  </div>
  {% if include.person.email or include.person.website %}
    <footer class="card-footer">
      {% if include.person.email %}
        <a href="mailto:{{ include.person.email }}" class="card-footer-item is-size-7">Email</a>
      {% endif %}
      {% if include.person.website %}
        <a href="{{ include.person.website }}" class="card-footer-item is-size-7" target="_blank" rel="noopener">Website &nearr;</a>
      {% endif %}
    </footer>
  {% endif %}
</div>
```

```html
<!-- _includes/news_card.html -->
<div class="pfcl-card mb-4">
  <div class="card-content">
    <div class="pfcl-badge-group">
      <span class="tag is-primary is-light">{{ include.item.category | replace: "-", " " | capitalize }}</span>
      <span class="tag is-dark is-light">{{ include.item.source_name | default: include.item.lab_id | upcase }}</span>
      <span class="tag is-light">{{ include.item.date | default: include.item.published_at | date: "%B %d, %Y" }}</span>
    </div>
    <h3 class="title is-5 mb-2">
      {% if include.item.canonical_url %}
        <a href="{{ include.item.canonical_url }}" target="_blank" rel="noopener">{{ include.item.title }} &nearr;</a>
      {% else %}
        <a href="{{ include.item.url | relative_url }}">{{ include.item.title }}</a>
      {% endif %}
    </h3>
    <p class="is-size-6">{{ include.item.excerpt }}</p>
  </div>
</div>
```

```html
<!-- _includes/project_filters.html -->
<div class="pfcl-filter-bar mb-5">
  <div class="columns is-multiline">
    <div class="column is-3">
      <label class="label is-small" for="filter-lab">Research Group</label>
      <div class="select is-small is-fullwidth">
        <select id="filter-lab">
          <option value="all">All Groups & Facilities</option>
          {% for lab in site.labs %}
            <option value="{{ lab.slug }}">{{ lab.short_name | default: lab.title }}</option>
          {% endfor %}
        </select>
      </div>
    </div>
    <div class="column is-3">
      <label class="label is-small" for="filter-status">Status</label>
      <div class="select is-small is-fullwidth">
        <select id="filter-status">
          <option value="all">All Statuses</option>
          <option value="available" selected>Available (Recruiting)</option>
          <option value="ongoing">Ongoing</option>
          <option value="completed">Completed</option>
        </select>
      </div>
    </div>
    <div class="column is-3">
      <label class="label is-small" for="filter-type">Project Type</label>
      <div class="select is-small is-fullwidth">
        <select id="filter-type">
          <option value="all">All Project Types</option>
          {% for pt in site.data.taxonomies.project_types %}
            <option value="{{ pt.id }}">{{ pt.label }}</option>
          {% endfor %}
        </select>
      </div>
    </div>
    <div class="column is-3">
      <label class="label is-small" for="filter-level">Student Level</label>
      <div class="select is-small is-fullwidth">
        <select id="filter-level">
          <option value="all">All Student Levels</option>
          {% for sl in site.data.taxonomies.student_levels %}
            <option value="{{ sl.id }}">{{ sl.label }}</option>
          {% endfor %}
        </select>
      </div>
    </div>
  </div>
  <div class="is-flex is-justify-content-space-between is-align-items-center mt-2">
    <span id="filtered-count" class="is-size-7 has-text-weight-bold has-text-grey">Showing all projects</span>
    <button id="filter-reset-btn" type="button" class="button is-small is-ghost">Reset Filters</button>
  </div>
</div>
```

- [ ] **Step 3: Create base layouts in _layouts/**

```html
<!-- _layouts/default.html -->
{% include header.html %}

{{ content }}

{% include footer.html %}
```

```html
<!-- _layouts/page.html -->
---
layout: default
---
<section class="pfcl-hero hero mb-5">
  <div class="container">
    <h1 class="title is-2">{{ page.title }}</h1>
    {% if page.subtitle %}
      <p class="subtitle is-5">{{ page.subtitle }}</p>
    {% endif %}
  </div>
</section>

<section class="section pt-0">
  <div class="container">
    <div class="content">
      {{ content }}
    </div>
  </div>
</section>
```

```html
<!-- _layouts/lab.html -->
---
layout: default
---
<section class="pfcl-hero hero mb-5">
  <div class="container">
    <div class="pfcl-badge-group mb-2">
      <span class="tag is-info is-light">{{ page.kind | replace: "-", " " | capitalize }}</span>
      {% if page.short_name %}
        <span class="tag is-primary is-light has-text-weight-bold">{{ page.short_name }}</span>
      {% endif %}
    </div>
    <h1 class="title is-2">{{ page.title }}</h1>
    <p class="subtitle is-5"><strong>Leader:</strong> {{ page.leader_names | join: ", " }}</p>
  </div>
</section>

<section class="section pt-0">
  <div class="container">
    <div class="columns">
      <div class="column is-8">
        <div class="content">
          <h3>Overview</h3>
          <p class="is-size-5">{{ page.summary }}</p>
          {{ content }}
        </div>
      </div>
      <div class="column is-4">
        <div class="box">
          <h4 class="title is-6">Group Information</h4>
          {% if page.website %}
            <p class="mb-2"><strong>Website:</strong> <a href="{{ page.website }}" target="_blank" rel="noopener">{{ page.website }}</a></p>
          {% endif %}
          {% if page.email %}
            <p class="mb-2"><strong>Contact:</strong> <a href="mailto:{{ page.email }}">{{ page.email }}</a></p>
          {% endif %}
          {% if page.research_topics %}
            <h5 class="title is-6 mt-4 mb-2">Key Research Topics</h5>
            <div class="tags">
              {% for topic in page.research_topics %}
                <span class="tag is-info is-light">{{ topic }}</span>
              {% endfor %}
            </div>
          {% endif %}
        </div>
      </div>
    </div>
  </div>
</section>
```

```html
<!-- _layouts/project.html -->
---
layout: default
---
<section class="pfcl-hero hero mb-5">
  <div class="container">
    <div class="pfcl-badge-group mb-2">
      {% if page.recruitment_status == "available" %}
        <span class="tag is-success">Recruiting</span>
      {% elsif page.recruitment_status == "ongoing" %}
        <span class="tag is-info is-light">Ongoing</span>
      {% else %}
        <span class="tag is-light">Completed</span>
      {% endif %}
      {% for lab in page.lab_ids %}
        <span class="tag is-dark is-light">{{ lab | upcase }}</span>
      {% endfor %}
    </div>
    <h1 class="title is-2">{{ page.title }}</h1>
    <p class="subtitle is-5"><strong>Advisors:</strong> {{ page.advisor_names | join: ", " }}</p>
  </div>
</section>

<section class="section pt-0">
  <div class="container">
    <div class="columns">
      <div class="column is-8">
        <div class="content">
          <h3>Project Summary</h3>
          <p class="is-size-5">{{ page.summary }}</p>
          {{ content }}
        </div>
      </div>
      <div class="column is-4">
        <div class="box">
          <h4 class="title is-6">Project Metadata</h4>
          <p class="mb-2"><strong>Status:</strong> {{ page.recruitment_status | capitalize }}</p>
          <p class="mb-2"><strong>Student Level:</strong> {{ page.student_levels | join: ", " | capitalize }}</p>
          <p class="mb-2"><strong>Type:</strong> {{ page.project_types | join: ", " | capitalize }}</p>
          {% if page.duration %}
            <p class="mb-2"><strong>Duration:</strong> {{ page.duration }}</p>
          {% endif %}
          {% if page.skills %}
            <h5 class="title is-6 mt-4 mb-2">Required Skills</h5>
            <div class="tags">
              {% for s in page.skills %}
                <span class="tag is-light">{{ s }}</span>
              {% endfor %}
            </div>
          {% endif %}
          {% if page.contact_email and page.recruitment_status == "available" %}
            <hr>
            <a href="mailto:{{ page.contact_email }}?subject=PFCL%20Project%20Application:%20{{ page.title | url_encode }}" class="button is-primary is-fullwidth">Apply for this Project</a>
          {% endif %}
        </div>
      </div>
    </div>
  </div>
</section>
```

- [ ] **Step 4: Commit layouts and includes**

```bash
git add _includes _layouts
git commit -m "feat: implement accessible Jekyll layouts, partials, and card components"
```

---

### Task 6: Core Public Pages & Navigation Routes

**Files:**
- Create: `index.md`
- Create: `about.md`
- Create: `history.md`
- Create: `dedication.md`
- Create: `team.md`
- Create: `labs.md`
- Create: `projects.md`
- Create: `teaching.md`
- Create: `news.md`
- Create: `media.md`
- Create: `contact.md`
- Create: `showcase.md`

**Interfaces:**
- Consumes: Collections `site.labs`, `site.team`, `site.projects`, `site.news`, `site.data.generated.updates`
- Produces: All 12 public routes defined in Information Architecture section of the foundation specification.

- [ ] **Step 1: Create index.md (Homepage)**

```markdown
---
layout: default
title: Home
---

<section class="pfcl-hero hero">
  <div class="container">
    <h1 class="title is-1">Philadelphia Flight Control Laboratory</h1>
    <p class="subtitle is-4 mt-3">
      Advancing autonomous flight, navigation, perception, and aerospace control systems at the Technion Faculty of Aerospace Engineering.
    </p>
    <div class="buttons mt-5">
      <a href="{{ '/projects/' | relative_url }}" class="button is-warning has-text-weight-bold">Explore Available Projects</a>
      <a href="{{ '/labs/' | relative_url }}" class="button is-light is-outlined has-text-weight-bold">Research Groups</a>
    </div>
  </div>
</section>

<section class="section">
  <div class="container">
    <div class="columns is-vcentered mb-6">
      <div class="column is-8">
        <h2 class="title is-3">About the Laboratory</h2>
        <p class="is-size-5 mb-4">
          The Philadelphia Flight Control Laboratory (PFCL) serves as the umbrella facility bringing together cutting-edge research groups, specialized flight testing infrastructure, and hands-on teaching laboratories within the Technion's Faculty of Aerospace Engineering.
        </p>
        <p class="is-size-6">
          Our constituent laboratories pioneer algorithmic and theoretical breakthroughs in autonomous navigation, guidance and control, differential games, multi-robot coordination, and perception in GPS-denied environments.
        </p>
      </div>
      <div class="column is-4 has-text-centered">
        <div class="box has-background-light p-5">
          <p class="heading">Constituent Units</p>
          <p class="title is-1 has-text-primary">{{ site.labs.size }}</p>
          <p class="is-size-7 has-text-grey">Research Groups, Teaching Labs & Facilities</p>
        </div>
      </div>
    </div>

    <!-- Featured Research Groups -->
    <div class="mb-6">
      <div class="is-flex is-justify-content-space-between is-align-items-center mb-4">
        <h2 class="title is-3 mb-0">Research Groups & Facilities</h2>
        <a href="{{ '/labs/' | relative_url }}" class="is-size-6 has-text-weight-semibold">View All &rarr;</a>
      </div>
      <div class="columns is-multiline">
        {% for lab in site.labs limit:3 %}
          <div class="column is-4">
            {% include lab_card.html lab=lab %}
          </div>
        {% endfor %}
      </div>
    </div>

    <!-- Available Student Projects -->
    <div class="mb-6">
      <div class="is-flex is-justify-content-space-between is-align-items-center mb-4">
        <h2 class="title is-3 mb-0">Featured Student Projects</h2>
        <a href="{{ '/projects/' | relative_url }}" class="is-size-6 has-text-weight-semibold">All Projects &rarr;</a>
      </div>
      <div class="columns is-multiline">
        {% assign available_projects = site.projects | where: "recruitment_status", "available" %}
        {% for project in available_projects limit:2 %}
          <div class="column is-6">
            {% include project_card.html project=project %}
          </div>
        {% endfor %}
      </div>
    </div>

    <!-- Recent News & Highlights -->
    <div>
      <div class="is-flex is-justify-content-space-between is-align-items-center mb-4">
        <h2 class="title is-3 mb-0">Latest Updates & News</h2>
        <a href="{{ '/news/' | relative_url }}" class="is-size-6 has-text-weight-semibold">Full News Feed &rarr;</a>
      </div>
      <div class="columns is-multiline">
        {% for item in site.news limit:3 %}
          <div class="column is-12">
            {% include news_card.html item=item %}
          </div>
        {% endfor %}
      </div>
    </div>
  </div>
</section>
```

- [ ] **Step 2: Create institutional pages (about.md, history.md, dedication.md, team.md, contact.md)**

```markdown
---
layout: page
title: About PFCL
subtitle: Institutional overview and research scope
permalink: /about/
---

### Overview

The Philadelphia Flight Control Laboratory (PFCL) is an umbrella research and educational facility located in the Faculty of Aerospace Engineering at the Technion - Israel Institute of Technology.

PFCL unites multiple autonomous flight, guidance, navigation, perception, and control research laboratories under a shared institutional umbrella.

### Mission & Focus

- **Pioneering Research:** Developing state-of-the-art theories and algorithms in autonomous navigation, SLAM, guidance laws, robust control, and multi-agent coordination.
- **Flight Testing & Experimental Facilities:** Providing students and researchers with specialized drone arenas, avionics testbeds, and hardware-in-the-loop simulation tools.
- **Excellence in Education:** Hosting hands-on teaching laboratories and capstone engineering projects for undergraduate and graduate aerospace students.
```

```markdown
---
layout: page
title: History of PFCL
subtitle: Decades of excellence in flight control and aerospace systems
permalink: /history/
---

The Philadelphia Flight Control Laboratory was established to provide the Technion Faculty of Aerospace Engineering with state-of-the-art infrastructure for research and teaching in flight mechanics, automatic control, and avionics.

Over decades of technological evolution—from analog flight simulators and classical control benches to modern multi-rotor autonomous drone arenas and AI-driven navigation systems—PFCL has trained generations of Israeli aerospace engineers and leaders in academia and the aerospace industry.
```

```markdown
---
layout: page
title: PFCL Dedication
subtitle: Honoring the Philadelphia Chapter and our supporters
permalink: /dedication/
---

The Philadelphia Flight Control Laboratory proudly recognizes the enduring generosity and vision of the American Technion Society Philadelphia Chapter and our esteemed donors.

Their commitment to advancing aerospace engineering education and scientific research at the Technion has enabled the creation and ongoing modernization of these laboratories.
```

```markdown
---
layout: page
title: Laboratory Team & Personnel
subtitle: Faculty, researchers, engineers, and staff
permalink: /team/
---

{% for cat in site.data.taxonomies.team_categories %}
  {% assign members = site.team | where: "category", cat.id | sort: "order" %}
  {% if members.size > 0 %}
    <h2 class="title is-4 mt-5 mb-4">{{ cat.label }}</h2>
    <div class="columns is-multiline mb-5">
      {% for person in members %}
        <div class="column is-4">
          {% include team_card.html person=person %}
        </div>
      {% endfor %}
    </div>
  {% endif %}
{% endfor %}
```

```markdown
---
layout: page
title: Contact & Directions
subtitle: Get in touch with the Philadelphia Flight Control Laboratory
permalink: /contact/
---

### Location

**Philadelphia Flight Control Laboratory**  
Faculty of Aerospace Engineering  
Technion - Israel Institute of Technology  
Technion City, Haifa 3200003, Israel  

### Inquiries

- **General Lab Email:** [{{ site.email }}](mailto:{{ site.email }})
- **Director:** Prof. Vadim Indelman ([vadim.indelman@technion.ac.il](mailto:vadim.indelman@technion.ac.il))
- **Laboratory Manager:** Ruslan Arhipov ([sarchi@technion.ac.il](mailto:sarchi@technion.ac.il))

### Student Project Applications

Interested in pursuing a B.Sc., M.Sc., or Ph.D. project? Explore our [Student Projects]({{ '/projects/' | relative_url }}) directory and reach out directly to the advisor listed on the project card.
```

- [ ] **Step 3: Create directory and feed pages (labs.md, projects.md, teaching.md, news.md, media.md, showcase.md)**

```markdown
---
layout: page
title: Research Groups & Units
subtitle: Constituent laboratories and shared facilities
permalink: /labs/
---

<div class="columns is-multiline">
  {% assign sorted_labs = site.labs | sort: "order" %}
  {% for lab in sorted_labs %}
    <div class="column is-6">
      {% include lab_card.html lab=lab %}
    </div>
  {% endfor %}
</div>
```

```markdown
---
layout: page
title: Student Projects
subtitle: Available, ongoing, and completed student research projects
permalink: /projects/
---

{% include project_filters.html %}

<div id="pfcl-project-list" class="columns is-multiline">
  {% assign sorted_projects = site.projects | sort: "updated_at" | reverse %}
  {% for project in sorted_projects %}
    <div class="column is-6">
      {% include project_card.html project=project %}
    </div>
  {% endfor %}
</div>
```

```markdown
---
layout: page
title: Teaching Laboratories
subtitle: Experimental education and student coursework facilities
permalink: /teaching/
---

<p class="is-size-5 mb-5">
  PFCL hosts hands-on teaching laboratories that introduce aerospace engineering students to experimental flight dynamics, automatic attitude control, sensor calibration, and drone piloting.
</p>

<div class="columns is-multiline">
  {% assign teaching_units = site.labs | where: "kind", "teaching-lab" %}
  {% for lab in teaching_units %}
    <div class="column is-6">
      {% include lab_card.html lab=lab %}
    </div>
  {% endfor %}
</div>
```

```markdown
---
layout: page
title: News & Activity Feed
subtitle: Updates, research highlights, and events from PFCL and constituent labs
permalink: /news/
---

<div class="columns is-multiline">
  {% for item in site.news %}
    <div class="column is-12">
      {% include news_card.html item=item %}
    </div>
  {% endfor %}
  {% for item in site.data.generated.updates %}
    <div class="column is-12">
      {% include news_card.html item=item %}
    </div>
  {% endfor %}
</div>
```

```markdown
---
layout: page
title: Media & Gallery
subtitle: Photos, videos, and experimental demonstrations
permalink: /media/
---

<p class="is-size-5 mb-5">
  Explore photos and videos from experimental flight trials, laboratory facilities, and aerospace demonstrations.
</p>

<div class="notification is-light">
  Curated media assets from recent flight tests and lab milestones will appear here.
</div>
```

```markdown
---
layout: page
title: Showcase Preview
subtitle: Full-screen display interface for laboratory monitors
permalink: /showcase/
---

<div class="notification is-info is-light">
  <p class="has-text-weight-bold">TV Showcase Deliverable Interface</p>
  <p>The full-screen TV showcase presentation page is reserved for Deliverable 3. It will consume available projects, local news, and aggregated lab updates with weighted rotation and pause controls.</p>
</div>
```

- [ ] **Step 4: Commit public pages and routes**

```bash
git add index.md about.md history.md dedication.md team.md labs.md projects.md teaching.md news.md media.md contact.md showcase.md
git commit -m "feat: implement all core public navigation routes and pages"
```

---

### Task 7: CI/CD Workflows, Project Safety Rules & Documentation

**Files:**
- Create: `.github/workflows/ci.yml`
- Create: `.github/workflows/pages.yml`
- Create: `AGENTS.md`
- Create: `README.md`

**Interfaces:**
- Consumes: Docker/Ruby validation script, test runner, Jekyll build, preview config
- Produces: Automated GitHub Actions CI workflow, GitHub Pages deployment workflow, repository documentation, and agent governance rules.

- [ ] **Step 1: Create .github/workflows/ci.yml and .github/workflows/pages.yml**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  validate-and-build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.3"
          bundler-cache: true

      - name: Validate content schemas
        run: bundle exec ruby scripts/validate_content.rb

      - name: Run unit tests
        run: bundle exec ruby -Itest test/content_validation_test.rb

      - name: Test Jekyll preview build
        run: bundle exec jekyll build --config _config.yml,_config.preview.yml --trace
        env:
          JEKYLL_ENV: production
```

```yaml
# .github/workflows/pages.yml
name: Deploy GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.3"
          bundler-cache: true

      - name: Validate content
        run: bundle exec ruby scripts/validate_content.rb

      - name: Run unit tests
        run: bundle exec ruby -Itest test/content_validation_test.rb

      - name: Build with preview configuration
        run: bundle exec jekyll build --config _config.yml,_config.preview.yml
        env:
          JEKYLL_ENV: production

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: "_site"

      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

- [ ] **Step 2: Create AGENTS.md**

```markdown
# AGENTS.md

Instructions for AI Agents and Contributors working on the PFCL Website project.

## Core Rules & Boundaries

1. **Inspect Before Editing:** Always inspect existing schemas, layouts, and files before modifying or adding content.
2. **Umbrella Terminology:** Treat PFCL as the umbrella institution. The terms "research group" and "sub-lab" are equivalent.
3. **Obsidian Vault Boundary:** Never read from, link to, or copy files from the internal PFCL Obsidian vault into this repository. Public content is authored in this repo or imported via configured public adapters.
4. **Preserve Frontmatter Schemas:** Maintain strict YAML frontmatter types, lowercase alphanumeric slugs, and required metadata across `_labs/`, `_team/`, `_projects/`, and `_news/`.
5. **Attribution Integrity:** Never present a constituent lab's publication or news as PFCL-authored. Always provide canonical source links and source lab attribution.
6. **Generated Data Boundary:** `_data/generated/updates.json` is reserved for automated aggregation. Never hand-edit items after aggregation is enabled.
7. **Keep Changes Focused:** Avoid vendoring the upstream `bulma-clean-theme` gem. Keep overrides scoped to `_layouts/`, `_includes/`, and `_sass/`.
8. **Run Verification Before Completion:** Always run `bundle exec ruby scripts/validate_content.rb`, `bundle exec ruby -Itest test/content_validation_test.rb`, and `bundle exec jekyll build` before claiming completion.
9. **Accessibility & Progressive Enhancement:** Keep the website functional without JavaScript. Ensure WCAG 2.2 AA color contrast and respect `prefers-reduced-motion`.
10. **Domain Safety:** Do not alter DNS, GitHub Pages custom domain settings, or the live `pfcl.technion.ac.il` site without explicit authorization.
```

- [ ] **Step 3: Create README.md**

```markdown
# Philadelphia Flight Control Laboratory (PFCL) Website

Public website for the Philadelphia Flight Control Laboratory at the Technion - Israel Institute of Technology Faculty of Aerospace Engineering.

## Architecture

- **Static Site Generator:** Jekyll 4.x
- **Theme:** Bulma Clean Theme 1.3.1 (Bulma 1.x)
- **Deployment:** GitHub Pages via GitHub Actions (`pages.yml`)
- **Validation:** Ruby content validator (`scripts/validate_content.rb`)

## Quickstart with Docker Compose

No local Ruby installation is required.

```bash
# Start local development server with livereload
docker compose up --build

# Open in browser: http://localhost:4000
```

## Running Tests and Validation

```bash
# Validate frontmatter content schemas
docker compose run --rm site bundle exec ruby scripts/validate_content.rb

# Run unit tests
docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb

# Build preview site
docker compose run --rm site bundle exec jekyll build --config _config.yml,_config.preview.yml --trace
```

## Content Guidelines

See [AGENTS.md](AGENTS.md) and [docs/superpowers/specs/2026-08-27-pfcl-website-foundation-design.md](docs/superpowers/specs/2026-08-27-pfcl-website-foundation-design.md) for data schemas and contributor guidelines.
```

- [ ] **Step 4: Commit CI workflows and documentation**

```bash
git add .github AGENTS.md README.md
git commit -m "docs: add AGENTS rules, README quickstart, and GitHub Actions CI/Pages workflows"
```

---

### Task 8: End-to-End Validation & Verification

**Files:**
- Execute: `scripts/validate_content.rb`
- Execute: `test/content_validation_test.rb`
- Execute: `jekyll build` (local and preview configs)

- [ ] **Step 1: Execute content validator**
- [ ] **Step 2: Run Minitest test suite**
- [ ] **Step 3: Execute full Jekyll build with preview configuration**
- [ ] **Step 4: Verify generated site structure, links, and assets**
