# Student Projects Refinements and Homepage Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine the Student Projects feature by removing student level clutter, classifying projects strictly as research or experimental with technical topic tags, hiding research groups with zero projects from the filter menu, and modernizing the homepage selected projects grid.

**Architecture:** Update `scripts/validate_content.rb` and frontmatter documents to use single scalar `project_type: research | experimental` and optional `tags: []`. Enhance `_includes/project_filters.html` in Liquid to filter dropdown labs dynamically against active published projects. Update `_includes/project_card.html` and `_layouts/project.html` to display the new tags and drop student levels. Modernize `index.md` to use the visual cards and inquiry modal.

**Tech Stack:** Jekyll 4, Liquid, Bulma CSS, Vanilla JavaScript, Ruby Minitest, Docker Compose.

## Global Constraints

- Never invent fake personnel, contact details, or dates.
- Retain universal sharp corners (`border-radius: 0 !important;`).
- All interactive features must degrade gracefully without JavaScript (pages and links render statically).
- All 3 verification gates must pass: content validator, test suite, production build.

---

### Task 1: Schema Validator and Project Frontmatter Updates

**Files:**
- Modify: `scripts/validate_content.rb:16-25, 90-104`
- Modify: `_projects/autonomous-semantic-perception.md`
- Modify: `_projects/collaborative-aerial-navigation.md`
- Modify: `_projects/robust-risk-averse-decision-making.md`
- Modify: `test/content_validation_test.rb`

**Interfaces:**
- Consumes: `_projects/*.md` documents.
- Produces: Strict schema validation requiring `project_type: "research" | "experimental"`, optional `tags: [string]`, and no `student_levels`.

- [ ] **Step 1: Write failing unit tests for schema changes**

In `test/content_validation_test.rb`, update `valid_project` fixture and add tests for `project_type` validation:

```ruby
  def valid_project
    {
      "title" => "Sample Project",
      "slug" => "sample-project",
      "lab_ids" => ["anpl"],
      "recruitment_status" => "available",
      "project_type" => "research",
      "tags" => ["software"],
      "advisor_names" => ["Sample Advisor"],
      "summary" => "Sample summary",
      "contact_email" => "advisor@technion.ac.il",
      "published" => true,
      "updated_at" => "2026-09-22",
      "featured" => true,
      "show_on_showcase" => true
    }
  end

  def test_project_type_must_be_research_or_experimental
    doc = valid_project.merge("project_type" => "software")
    write_project("invalid-type.md", doc)
    validator = ContentValidator.new(@dir).validate
    assert validator.errors.any? { |e| e.include?("project_type") }
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb`
Expected: FAIL (missing field or unexpected field).

- [ ] **Step 3: Update `scripts/validate_content.rb`**

1. In `REQUIRED_FIELDS["projects"]`, replace `project_types` and `student_levels` with `project_type`.
2. Define `PROJECT_TYPES = %w[research experimental].freeze`.
3. In `validate_collection("projects")`:
   ```ruby
   check_enum(rel, fields, "recruitment_status", RECRUITMENT_STATUSES)
   check_string_list(rel, fields, "lab_ids", known_labs)
   check_enum(rel, fields, "project_type", PROJECT_TYPES)
   check_string_list(rel, fields, "tags") if fields.key?("tags")
   check_string_list(rel, fields, "advisor_names")
   check_url(rel, fields, "application_url")
   check_url(rel, fields, "canonical_url")
   check_date(rel, fields, "updated_at")
   check_thumbnail(rel, fields, "thumbnail")
   ```

- [ ] **Step 4: Update `_projects/*.md` files**

In `_projects/autonomous-semantic-perception.md`:
```yaml
project_type: research
tags:
  - software
```
(Remove `student_levels` and `project_types`).

In `_projects/collaborative-aerial-navigation.md`:
```yaml
project_type: research
tags:
  - software
  - hardware
```
(Remove `student_levels` and `project_types`).

In `_projects/robust-risk-averse-decision-making.md`:
```yaml
project_type: research
tags:
  - software
```
(Remove `student_levels` and `project_types`).

- [ ] **Step 5: Run tests and validator to verify they pass**

Run:
```bash
docker compose run --rm site bundle exec ruby scripts/validate_content.rb
docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb
```
Expected: PASS (all tests green).

- [ ] **Step 6: Commit changes**

```bash
git add scripts/validate_content.rb test/content_validation_test.rb _projects/
git commit -m "feat(schema): simplify project type to research/experimental and add tags"
```

---

### Task 2: Dynamic Research Group Filtering and Simplified Filter Controls

**Files:**
- Modify: `_includes/project_filters.html`
- Modify: `assets/js/projects.js`
- Modify: `projects.md`

**Interfaces:**
- Consumes: `site.projects` published collection.
- Produces: Dynamic `<select>` showing only research groups with active projects, simplified `Type` select with `Research` and `Experimental`, and removal of student level select.

- [ ] **Step 1: Update `_includes/project_filters.html`**

Update `_includes/project_filters.html`:

```liquid
{% assign published_projects = site.projects | where: "published", true %}
{% assign active_lab_ids = "" | split: "" %}
{% for p in published_projects %}
  {% for lab_id in p.lab_ids %}
    {% unless active_lab_ids contains lab_id %}
      {% assign active_lab_ids = active_lab_ids | push: lab_id %}
    {% endunless %}
  {% endfor %}
{% endfor %}

<div class="pfcl-filters-wrapper mb-5">
  <div class="field is-grouped is-grouped-multiline">
    <div class="control is-expanded">
      <label class="label is-small" for="pfcl-project-search">Search projects</label>
      <div class="control has-icons-left">
        <input class="input is-small" id="pfcl-project-search" type="search" placeholder="Search title, advisor, or keywords...">
        <span class="icon is-small is-left">
          <i class="fas fa-search"></i>
        </span>
      </div>
    </div>
    <div class="control">
      <label class="label is-small" for="pfcl-filter-labs">Research group</label>
      <div class="select is-small">
        <select id="pfcl-filter-labs" data-filter="labs">
          <option value="">All groups</option>
          {% for lab in site.labs %}
            {% if active_lab_ids contains lab.slug %}
              <option value="{{ lab.slug }}">{{ lab.short_name | default: lab.title }}</option>
            {% endif %}
          {% endfor %}
          {% if active_lab_ids contains "pfcl" %}
            <option value="pfcl">PFCL</option>
          {% endif %}
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
      <label class="label is-small" for="pfcl-filter-type">Type</label>
      <div class="select is-small">
        <select id="pfcl-filter-type" data-filter="type">
          <option value="">All types</option>
          <option value="research">Research</option>
          <option value="experimental">Experimental</option>
        </select>
      </div>
    </div>
  </div>
</div>
```

- [ ] **Step 2: Update `projects.md` card wrapper attributes**

In `projects.md`, remove `data-levels` and update `data-types` to `data-type="{{ project.project_type }}"`:

```liquid
<div class="columns is-multiline">
{% for project in projects %}
  <div class="column is-4-desktop is-6-tablet is-12-mobile" data-project-card
       data-labs="{{ project.lab_ids | join: ' ' }}"
       data-status="{{ project.recruitment_status }}"
       data-type="{{ project.project_type }}">
    {% include project_card.html project=project %}
  </div>
{% endfor %}
</div>
```

- [ ] **Step 3: Update `assets/js/projects.js`**

Ensure `projects.js` matches `data-type` cleanly and performs search across all card content.

- [ ] **Step 4: Run tests to verify**

Run: `docker compose run --rm site bundle exec ruby -Itest test/projects_page_test.rb`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add _includes/project_filters.html projects.md assets/js/projects.js
git commit -m "feat(projects): dynamically hide empty groups and simplify filter options"
```

---

### Task 3: Project Card and Detail Page Presentation Updates

**Files:**
- Modify: `_includes/project_card.html`
- Modify: `_layouts/project.html`
- Modify: `test/project_card_test.rb`
- Modify: `test/project_layout_test.rb`

**Interfaces:**
- Consumes: `project.project_type`, `project.tags`.
- Produces: Card and detail view displaying Research Group, Advisor, Project Type badge, technical topic tags, and no student level badges.

- [ ] **Step 1: Update `_includes/project_card.html`**

Update the tag section of `_includes/project_card.html`:

```liquid
    <!-- Footer Tags -->
    <div class="pfcl-project-tags tags mb-3">
      {% for lab_slug in p.lab_ids %}
        {% assign lab = site.labs | where: "slug", lab_slug | first %}
        <span class="tag is-info is-light" title="Research Group">
          <i class="fas fa-flask mr-1"></i>{{ lab.short_name | default: lab_slug | upcase }}
        </span>
      {% endfor %}

      {% for advisor_name in p.advisor_names %}
        <span class="tag is-link is-light" title="Advisor">
          <i class="fas fa-user-tie mr-1"></i>{{ advisor_name }}
        </span>
      {% endfor %}

      <span class="tag is-primary is-light" title="Project Type">
        {{ p.project_type | capitalize }}
      </span>

      {% for tag in p.tags %}
        <span class="tag is-light" title="Topic">
          {{ tag | capitalize }}
        </span>
      {% endfor %}
    </div>
```

- [ ] **Step 2: Update `_layouts/project.html`**

In `_layouts/project.html`, replace Degree Levels & Project Types with Project Type & Topics:

```liquid
        <!-- Project Type & Technical Topics -->
        <div class="mb-5">
          <span class="is-size-7 has-text-grey is-uppercase has-text-weight-bold">Project Type &amp; Topics</span>
          <div class="tags mt-1">
            <span class="tag is-primary is-light">{{ page.project_type | capitalize }}</span>
            {% for tag in page.tags %}
              <span class="tag is-light">{{ tag | capitalize }}</span>
            {% endfor %}
          </div>
        </div>
```

- [ ] **Step 3: Update and run component tests**

Update `test/project_card_test.rb` and `test/project_layout_test.rb`:
- Verify `p.project_type` in card.
- Verify `page.project_type` in layout.
- Assert absence of `student_levels`.

Run:
```bash
docker compose run --rm site bundle exec ruby -Itest test/project_card_test.rb
docker compose run --rm site bundle exec ruby -Itest test/project_layout_test.rb
```
Expected: PASS.

- [ ] **Step 4: Commit changes**

```bash
git add _includes/project_card.html _layouts/project.html test/project_card_test.rb test/project_layout_test.rb
git commit -m "feat(projects): render project type and topic tags without student levels"
```

---

### Task 4: Homepage Selected Projects Grid and Modal Integration

**Files:**
- Modify: `index.md`
- Modify: `test/homepage_test.rb`

**Interfaces:**
- Consumes: `site.projects`, `_includes/project_card.html`.
- Produces: Visual 3-column card grid for selected projects on the homepage with inquiry modal support.

- [ ] **Step 1: Write unit tests in `test/homepage_test.rb`**

Add tests for visual card include and inquiry modal in `test/homepage_test.rb`:

```ruby
  def test_homepage_includes_project_card
    assert_includes @content, "project_card.html", "Homepage must use project_card.html"
  end

  def test_homepage_includes_inquiry_modal
    assert_includes @content, "pfcl-project-modal", "Homepage must include inquiry modal"
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `docker compose run --rm site bundle exec ruby -Itest test/homepage_test.rb`
Expected: FAIL.

- [ ] **Step 3: Update `index.md`**

In `index.md`:
```liquid
## Selected student projects

<div class="columns is-multiline">
{% assign available_projects = site.projects | where: "published", true | where: "recruitment_status", "available" | sort: 'order' %}
{% for project in available_projects limit: 3 %}
  <div class="column is-4-desktop is-6-tablet is-12-mobile">
    {% include project_card.html project=project %}
  </div>
{% endfor %}
</div>

<div class="buttons mt-4">
  <a href="{{ '/projects/' | relative_url }}" class="button is-primary is-outlined">All student projects &rarr;</a>
</div>

<!-- Inquiry Modal -->
<div class="modal" id="pfcl-project-modal" aria-hidden="true">
  <div class="modal-background" data-modal-close></div>
  <div class="modal-card">
    <header class="modal-card-head">
      <p class="modal-card-title is-size-5" id="pfcl-modal-title">Inquire about project</p>
      <button class="delete" aria-label="close" data-modal-close></button>
    </header>
    <section class="modal-card-body">
      {% if site.project_inquiry_form_url and site.project_inquiry_form_url != '' %}
        <iframe id="pfcl-modal-iframe" src="{{ site.project_inquiry_form_url }}" width="100%" height="480" frameborder="0">Loading inquiry form...</iframe>
      {% else %}
        <div class="content">
          <p>Interested in learning more or applying for this project? Reach out to the lab and advisor directly:</p>
          <p id="pfcl-modal-direct-contact"></p>
          <div class="buttons mt-4">
            <a id="pfcl-modal-email-btn" href="mailto:{{ site.email }}" class="button is-primary">
              <i class="fas fa-envelope mr-2"></i>Send Email Inquiry
            </a>
          </div>
        </div>
      {% endif %}
    </section>
    <footer class="modal-card-foot">
      <button class="button is-small" data-modal-close>Close</button>
    </footer>
  </div>
</div>

<script src="{{ '/assets/js/projects.js' | relative_url }}?v={{ site.time | date: '%s' }}" defer></script>
```

- [ ] **Step 4: Run test to verify it passes**

Run: `docker compose run --rm site bundle exec ruby -Itest test/homepage_test.rb`
Expected: PASS.

- [ ] **Step 5: Run full verification suite across all 3 gates**

1. `docker compose run --rm site bundle exec ruby scripts/validate_content.rb`
2. `docker compose run --rm site bundle exec ruby -I. -e "Dir.glob('test/**/*_test.rb').each { |f| require f }"`
3. `docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace`

Expected: All gates PASS with 0 errors.

- [ ] **Step 6: Commit changes**

```bash
git add index.md test/homepage_test.rb
git commit -m "feat(homepage): integrate rich project cards and inquiry modal on frontpage"
```
