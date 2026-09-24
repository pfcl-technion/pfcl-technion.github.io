# Student Projects Visual Portfolio & Detail Pages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform Student Projects into a visual portfolio with dedicated detail pages (`/projects/<slug>/`) modeled on the ANPL lab website and upgraded with real-time keyword search, supervisor lookups, status badges, and a Technion Microsoft Forms inquiry modal.

**Architecture:** Set `output: true` for the `_projects` collection in `_config.yml` and create `_layouts/project.html` for standalone project pages. Create `_includes/project_card.html` with thumbnail headers, supervisor lookups from `_team`, and categorization tags. Update `_includes/project_filters.html` and `assets/js/projects.js` to combine keyword search with dropdown filters, and integrate a reusable Bulma inquiry modal.

**Tech Stack:** Jekyll 4, Liquid, Bulma CSS, Vanilla JavaScript, Ruby Minitest, Docker Compose.

## Global Constraints

- Never invent fake personnel, contact details, or dates (quote strings with colons/brackets).
- Universal sharp-corner aesthetic (`border-radius: 0 !important;`) must be preserved across all cards, tags, inputs, and buttons.
- Retain existing recruitment statuses (`available`, `ongoing`, `completed`) without artificial seat quotas.
- Accessible without JavaScript: all project links and pages render statically in HTML.
- Run all 3 verification gates before claiming completion: validator, test suite, production build.

---

### Task 1: Schema Validator and Test Suite Update for Project Thumbnails

**Files:**
- Modify: `scripts/validate_content.rb:85-103`
- Modify: `test/content_validation_test.rb`

**Interfaces:**
- Consumes: `_projects/*.md` frontmatter documents.
- Produces: Validation rules allowing optional `thumbnail` field (must start with `/assets/` or be a valid HTTP/HTTPS URL).

- [ ] **Step 1: Write failing unit test for thumbnail validation**

In `test/content_validation_test.rb`, add tests for valid and invalid project thumbnails:

```ruby
  def test_project_thumbnail_valid_path
    doc = valid_project.merge("thumbnail" => "/assets/images/projects/test.jpg")
    write_project("valid-thumb.md", doc)
    validator = ContentValidator.new(@dir).validate
    assert_empty validator.errors
  end

  def test_project_thumbnail_invalid_path
    doc = valid_project.merge("thumbnail" => "not-a-valid-path-or-url")
    write_project("invalid-thumb.md", doc)
    validator = ContentValidator.new(@dir).validate
    assert validator.errors.any? { |e| e.include?("thumbnail") }
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb`
Expected: FAIL (unknown field or missing check for thumbnail).

- [ ] **Step 3: Update `scripts/validate_content.rb`**

In `scripts/validate_content.rb`, add `check_thumbnail` in the `projects` validation case:

```ruby
      when "projects"
        check_enum(rel, fields, "recruitment_status", RECRUITMENT_STATUSES)
        check_string_list(rel, fields, "lab_ids", known_labs)
        check_string_list(rel, fields, "project_types", PROJECT_TYPES)
        check_string_list(rel, fields, "student_levels", STUDENT_LEVELS)
        check_string_list(rel, fields, "advisor_names")
        check_url(rel, fields, "application_url")
        check_url(rel, fields, "canonical_url")
        check_date(rel, fields, "updated_at")
        check_thumbnail(rel, fields, "thumbnail")
```

Add helper method `check_thumbnail`:

```ruby
  def check_thumbnail(rel, fields, field)
    value = fields[field]
    return unless present?(value)

    valid = value.is_a?(String) && (value.start_with?("/assets/") || valid_url?(value))
    error(rel, "#{field} '#{value}' must start with '/assets/' or be an http(s) URL") unless valid
  end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb`
Expected: PASS (all tests pass).

- [ ] **Step 5: Commit changes**

```bash
git add scripts/validate_content.rb test/content_validation_test.rb
git commit -m "feat(schema): add thumbnail validation to projects schema"
```

---

### Task 2: Project Collection Output Configuration and Assets

**Files:**
- Modify: `_config.yml`
- Create: `assets/images/project_default.jpg`
- Modify: `_projects/autonomous-semantic-perception.md`
- Modify: `_projects/collaborative-aerial-navigation.md`
- Modify: `_projects/robust-risk-averse-decision-making.md`

**Interfaces:**
- Consumes: `_config.yml` collections settings.
- Produces: `collections.projects.output = true` with `permalink: /projects/:slug/`, default thumbnail image, and frontmatter thumbnail paths.

- [ ] **Step 1: Create fallback default project thumbnail**

Copy an existing laboratory drone image as the fallback thumbnail:

```bash
powershell -Command "Copy-Item 'assets/images/drone2.jpg' 'assets/images/project_default.jpg'"
```

- [ ] **Step 2: Update `_config.yml` for project collection output and form URL**

In `_config.yml`, update `collections.projects` and add `project_inquiry_form_url`:

```yaml
collections:
  labs:
    output: false
  team:
    output: false
  projects:
    output: true
    permalink: /projects/:slug/
  news:
    output: false

defaults:
  - scope:
      path: ""
      type: "projects"
    values:
      layout: "project"

project_inquiry_form_url: ""
```

- [ ] **Step 3: Add thumbnail property to existing project documents**

In `_projects/autonomous-semantic-perception.md`:
```yaml
thumbnail: /assets/images/project_default.jpg
```

In `_projects/collaborative-aerial-navigation.md`:
```yaml
thumbnail: /assets/images/project_default.jpg
```

In `_projects/robust-risk-averse-decision-making.md`:
```yaml
thumbnail: /assets/images/project_default.jpg
```

- [ ] **Step 4: Run validator to ensure compliance**

Run: `docker compose run --rm site bundle exec ruby scripts/validate_content.rb`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add _config.yml assets/images/project_default.jpg _projects/
git commit -m "feat(projects): enable collection page output and set default thumbnail"
```

---

### Task 3: Build Dedicated Project Detail Page Layout (`_layouts/project.html`)

**Files:**
- Create: `_layouts/project.html`
- Modify: `_sass/pfcl.scss`
- Create: `test/project_layout_test.rb`

**Interfaces:**
- Consumes: Project document fields (`page.title`, `page.summary`, `page.advisor_names`, `page.recruitment_status`, `page.thumbnail`, `page.project_types`, `page.student_levels`, `content`).
- Produces: Standalone project page with hero, metadata overview panel, body content, and inquiry trigger.

- [ ] **Step 1: Write regression test for project layout**

Create `test/project_layout_test.rb`:

```ruby
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `docker compose run --rm site bundle exec ruby -Itest test/project_layout_test.rb`
Expected: FAIL (file not found).

- [ ] **Step 3: Create `_layouts/project.html`**

Create `_layouts/project.html`:

```liquid
---
layout: default
---

{% assign thumb = page.thumbnail | default: '/assets/images/project_default.jpg' %}

<section class="hero is-small is-primary pfcl-hero pfcl-project-detail-hero">
  <div class="hero-body">
    <div class="container">
      <nav class="breadcrumb is-small mb-3" aria-label="breadcrumbs">
        <ul>
          <li><a href="{{ '/' | relative_url }}">Home</a></li>
          <li><a href="{{ '/projects/' | relative_url }}">Student Projects</a></li>
          <li class="is-active"><a href="#" aria-current="page">{{ page.title }}</a></li>
        </ul>
      </nav>
      <h1 class="title is-2">{{ page.title }}</h1>
      <p class="subtitle is-5">{{ page.summary }}</p>
    </div>
  </div>
</section>

<section class="section">
  <div class="container">
    <div class="columns is-multiline">
      <!-- Left Column: High-Res Project Image -->
      <div class="column is-6-desktop is-12-tablet">
        <div class="pfcl-project-detail-image-wrapper">
          <img src="{{ thumb | relative_url }}" alt="{{ page.title }}" class="pfcl-project-detail-image">
          <span class="pfcl-project-status pfcl-status-{{ page.recruitment_status }}">
            {{ page.recruitment_status | capitalize }}
          </span>
        </div>
      </div>

      <!-- Right Column: Project Metadata Box -->
      <div class="column is-6-desktop is-12-tablet">
        <div class="card pfcl-card pfcl-project-detail-meta">
          <div class="card-content">
            <h2 class="title is-5 mb-4">Project Overview</h2>

            <!-- Supervising Advisors -->
            <div class="mb-4">
              <span class="is-size-7 has-text-grey is-uppercase has-text-weight-bold">Supervising Advisors</span>
              <div class="mt-2">
                {% for advisor_name in page.advisor_names %}
                  {% assign advisor_member = site.team | where: "title", advisor_name | first %}
                  <div class="pfcl-supervisor-item mb-2">
                    {% if advisor_member.photo %}
                      <img src="{{ advisor_member.photo | relative_url }}" alt="{{ advisor_name }}" class="pfcl-supervisor-avatar">
                    {% else %}
                      <span class="pfcl-supervisor-avatar-placeholder"><i class="fas fa-user"></i></span>
                    {% endif %}
                    <div class="pfcl-supervisor-info">
                      {% if advisor_member.faculty_url %}
                        <a href="{{ advisor_member.faculty_url }}" target="_blank" rel="noopener noreferrer" class="has-text-weight-semibold">{{ advisor_name }}</a>
                      {% elsif advisor_member.email %}
                        <a href="mailto:{{ advisor_member.email }}" class="has-text-weight-semibold">{{ advisor_name }}</a>
                      {% else %}
                        <span class="has-text-weight-semibold">{{ advisor_name }}</span>
                      {% endif %}
                      {% if advisor_member.role %}
                        <span class="is-size-7 has-text-grey">{{ advisor_member.role }}</span>
                      {% endif %}
                    </div>
                  </div>
                {% endfor %}
              </div>
            </div>

            <!-- Research Groups -->
            <div class="mb-4">
              <span class="is-size-7 has-text-grey is-uppercase has-text-weight-bold">Research Group</span>
              <div class="tags mt-1">
                {% for lab_slug in page.lab_ids %}
                  {% assign lab = site.labs | where: "slug", lab_slug | first %}
                  <a href="{{ '/labs/' | relative_url }}" class="tag is-info is-light">
                    <i class="fas fa-flask mr-1"></i>{{ lab.title | default: lab_slug }}
                  </a>
                {% endfor %}
              </div>
            </div>

            <!-- Target Degree Levels & Types -->
            <div class="mb-5">
              <span class="is-size-7 has-text-grey is-uppercase has-text-weight-bold">Degree Levels &amp; Project Types</span>
              <div class="tags mt-1">
                {% for level in page.student_levels %}
                  <span class="tag is-primary is-light">{{ level | capitalize }}</span>
                {% endfor %}
                {% for ptype in page.project_types %}
                  <span class="tag is-light">{{ ptype | capitalize }}</span>
                {% endfor %}
              </div>
            </div>

            <!-- Action Button -->
            <button type="button" class="button is-primary is-fullwidth"
                    data-inquiry-btn
                    data-project-title="{{ page.title }}"
                    data-project-advisor="{{ page.advisor_names | join: ', ' }}"
                    data-project-contact="{{ page.contact_email | default: site.email }}">
              <i class="fas fa-paper-plane mr-2"></i>Hear more / Apply
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Main Project Description -->
    <div class="content pfcl-project-detail-body mt-5">
      <hr>
      {{ content }}
    </div>

    <div class="mt-6">
      <a href="{{ '/projects/' | relative_url }}" class="button is-light">
        &larr; Back to all student projects
      </a>
    </div>
  </div>
</section>

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
          <p>Interested in learning more or applying for this project? Contact the lab and advisor directly:</p>
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

- [ ] **Step 4: Add detail page styles to `_sass/pfcl.scss`**

In `_sass/pfcl.scss`, add:

```scss
// Project Detail Page
.pfcl-project-detail-image-wrapper {
  position: relative;
  width: 100%;
  aspect-ratio: 16 / 9;
  background: #000e1f;
  overflow: hidden;
  border: 1px solid #e2e8f0;
  border-radius: 0 !important;

  .pfcl-project-detail-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
  }
}

.pfcl-project-detail-meta {
  border-radius: 0 !important;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
}
```

- [ ] **Step 5: Run tests and verify**

Run: `docker compose run --rm site bundle exec ruby -Itest test/project_layout_test.rb`
Expected: PASS.

- [ ] **Step 6: Commit changes**

```bash
git add _layouts/project.html _sass/pfcl.scss test/project_layout_test.rb
git commit -m "feat(projects): add dedicated project detail layout and styling"
```

---

### Task 4: Reusable Project Card Component (`_includes/project_card.html`)

**Files:**
- Create: `_includes/project_card.html`
- Modify: `_sass/pfcl.scss`
- Create: `test/project_card_test.rb`

**Interfaces:**
- Consumes: `project` object from `site.projects`.
- Produces: Rich card HTML with thumbnail, title linking to `{{ project.url | relative_url }}`, supervisor avatar from `site.team`, footer tags, and "View Details & Apply" button.

- [ ] **Step 1: Write test for project card**

Create `test/project_card_test.rb`:

```ruby
# frozen_string_literal: true

require "minitest/autorun"

class ProjectCardTest < Minitest::Test
  def setup
    @template = File.read(File.expand_path("../_includes/project_card.html", __dir__))
  end

  def test_card_elements
    assert_includes @template, "pfcl-project-card", "Must have pfcl-project-card class"
    assert_includes @template, "pfcl-project-thumb", "Must have thumbnail"
    assert_includes @template, "p.url", "Must link to project detail page"
    assert_includes @template, "pfcl-project-tags", "Must have tags"
    assert_includes @template, "data-inquiry-btn", "Must have inquiry trigger"
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `docker compose run --rm site bundle exec ruby -Itest test/project_card_test.rb`
Expected: FAIL.

- [ ] **Step 3: Create `_includes/project_card.html`**

Create `_includes/project_card.html`:

```liquid
{% assign p = include.project %}
{% assign thumb = p.thumbnail | default: '/assets/images/project_default.jpg' %}

<div class="card pfcl-card pfcl-project-card">
  <div class="pfcl-project-thumb-wrapper">
    <a href="{{ p.url | relative_url }}">
      <img src="{{ thumb | relative_url }}" alt="{{ p.title }}" class="pfcl-project-thumb">
    </a>
    <span class="pfcl-project-status pfcl-status-{{ p.recruitment_status }}">
      {{ p.recruitment_status | capitalize }}
    </span>
  </div>

  <div class="card-content pfcl-project-body">
    <p class="title is-5 pfcl-project-title mb-2">
      <a href="{{ p.url | relative_url }}" class="has-text-inherit">{{ p.title }}</a>
    </p>

    <!-- Supervisor Section -->
    <div class="pfcl-project-supervisor mb-3">
      {% for advisor_name in p.advisor_names %}
        {% assign advisor_member = site.team | where: "title", advisor_name | first %}
        <div class="pfcl-supervisor-item">
          {% if advisor_member.photo %}
            <img src="{{ advisor_member.photo | relative_url }}" alt="{{ advisor_name }}" class="pfcl-supervisor-avatar">
          {% else %}
            <span class="pfcl-supervisor-avatar-placeholder"><i class="fas fa-user"></i></span>
          {% endif %}
          <div class="pfcl-supervisor-info">
            <span class="is-size-7 has-text-grey">Advisor:</span>
            {% if advisor_member.faculty_url %}
              <a href="{{ advisor_member.faculty_url }}" target="_blank" rel="noopener noreferrer" class="is-size-6 has-text-weight-semibold">{{ advisor_name }}</a>
            {% elsif advisor_member.email %}
              <a href="mailto:{{ advisor_member.email }}" class="is-size-6 has-text-weight-semibold">{{ advisor_name }}</a>
            {% else %}
              <span class="is-size-6 has-text-weight-semibold">{{ advisor_name }}</span>
            {% endif %}
          </div>
        </div>
      {% endfor %}
    </div>

    <!-- Summary -->
    <div class="content pfcl-project-summary is-size-6 mb-3">
      {{ p.summary }}
    </div>

    <!-- Footer Tags -->
    <div class="pfcl-project-tags tags mb-3">
      {% for lab_slug in p.lab_ids %}
        {% assign lab = site.labs | where: "slug", lab_slug | first %}
        <span class="tag is-info is-light" title="Research Group">
          <i class="fas fa-flask mr-1"></i>{{ lab.short_name | default: lab_slug | upcase }}
        </span>
      {% endfor %}

      {% for ptype in p.project_types %}
        <span class="tag is-primary is-light" title="Project Type">
          {{ ptype | capitalize }}
        </span>
      {% endfor %}

      {% for level in p.student_levels %}
        <span class="tag is-light" title="Student Level">
          {{ level | capitalize }}
        </span>
      {% endfor %}
    </div>

    <!-- Action Buttons -->
    <div class="pfcl-project-footer mt-auto buttons are-small">
      <a href="{{ p.url | relative_url }}" class="button is-primary is-outlined is-flex-grow-1">
        View Details &rarr;
      </a>
      <button type="button" class="button is-primary"
              data-inquiry-btn
              data-project-title="{{ p.title }}"
              data-project-advisor="{{ p.advisor_names | join: ', ' }}"
              data-project-contact="{{ p.contact_email | default: site.email }}">
        Inquire
      </button>
    </div>
  </div>
</div>
```

- [ ] **Step 4: Run tests and verify**

Run: `docker compose run --rm site bundle exec ruby -Itest test/project_card_test.rb`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add _includes/project_card.html test/project_card_test.rb
git commit -m "feat(projects): add rich project card component linking to detail pages"
```

---

### Task 5: Filter Bar Search Input and Client-Side Script Enhancement

**Files:**
- Modify: `_includes/project_filters.html`
- Modify: `assets/js/projects.js`

**Interfaces:**
- Consumes: `#pfcl-project-search` input and `[data-project-card]` DOM elements.
- Produces: Real-time filtering matching keyword query against card text alongside dropdown select filters.

- [ ] **Step 1: Update `_includes/project_filters.html`**

In `_includes/project_filters.html`, add search bar with an icon:

```html
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
</div>
```

- [ ] **Step 2: Update `assets/js/projects.js`**

In `assets/js/projects.js`, add text search and modal handlers:

```javascript
// PFCL student-project filters and inquiry modal.
(function () {
  "use strict";

  var root = document.querySelector("[data-project-list]");
  var modal = document.getElementById("pfcl-project-modal");

  // Filter Logic
  if (root) {
    var searchInput = root.querySelector("#pfcl-project-search");
    var selects = Array.prototype.slice.call(root.querySelectorAll("select[data-filter]"));
    var cards = Array.prototype.slice.call(root.querySelectorAll("[data-project-card]"));
    var emptyNotice = root.querySelector("[data-empty-filter]");

    function cardValues(card, name) {
      return (card.getAttribute("data-" + name) || "").split(/\s+/).filter(Boolean);
    }

    function applyFilters() {
      var query = searchInput ? searchInput.value.trim().toLowerCase() : "";
      var visibleCount = 0;

      cards.forEach(function (card) {
        var matchesDropdowns = selects.every(function (select) {
          var value = select.value;
          if (!value) return true;
          return cardValues(card, select.getAttribute("data-filter")).indexOf(value) !== -1;
        });

        var matchesSearch = !query || card.textContent.toLowerCase().indexOf(query) !== -1;
        var visible = matchesDropdowns && matchesSearch;

        card.hidden = !visible;
        card.style.display = visible ? "" : "none";
        card.classList.toggle("is-hidden", !visible);
        if (visible) visibleCount++;
      });

      if (emptyNotice) {
        emptyNotice.style.display = visibleCount === 0 ? "" : "none";
        emptyNotice.classList.toggle("is-hidden", visibleCount > 0);
      }
    }

    selects.forEach(function (select) {
      select.addEventListener("change", applyFilters);
    });

    if (searchInput) {
      searchInput.addEventListener("input", applyFilters);
    }
  }

  // Inquiry Modal Logic (works on both listing page and detail pages)
  if (modal) {
    var modalTitle = modal.querySelector("#pfcl-modal-title");
    var modalContact = modal.querySelector("#pfcl-modal-direct-contact");
    var modalEmailBtn = modal.querySelector("#pfcl-modal-email-btn");

    function openModal(btn) {
      var pTitle = btn.getAttribute("data-project-title") || "Student Project";
      var pAdvisor = btn.getAttribute("data-project-advisor") || "";
      var pEmail = btn.getAttribute("data-project-contact") || "pfcl@technion.ac.il";

      if (modalTitle) modalTitle.textContent = "Inquire: " + pTitle;
      if (modalContact) {
        modalContact.innerHTML = "<strong>Project:</strong> " + pTitle + "<br><strong>Advisor:</strong> " + pAdvisor;
      }
      if (modalEmailBtn) {
        var subject = encodeURIComponent("Inquiry regarding project: " + pTitle);
        var body = encodeURIComponent("Hello,\n\nI am interested in learning more about the project \"" + pTitle + "\".\n\nName:\nDegree/Year:\nQuestions/Background:\n");
        modalEmailBtn.setAttribute("href", "mailto:" + pEmail + "?subject=" + subject + "&body=" + body);
      }

      modal.classList.add("is-active");
      modal.setAttribute("aria-hidden", "false");
    }

    function closeModal() {
      modal.classList.remove("is-active");
      modal.setAttribute("aria-hidden", "true");
    }

    document.addEventListener("click", function (e) {
      var btn = e.target.closest("[data-inquiry-btn]");
      if (btn) {
        e.preventDefault();
        openModal(btn);
      }
    });

    var closeTriggers = modal.querySelectorAll("[data-modal-close]");
    Array.prototype.slice.call(closeTriggers).forEach(function (trigger) {
      trigger.addEventListener("click", closeModal);
    });

    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && modal.classList.contains("is-active")) {
        closeModal();
      }
    });
  }
})();
```

- [ ] **Step 3: Commit changes**

```bash
git add _includes/project_filters.html assets/js/projects.js
git commit -m "feat(projects): add text search input and global modal inquiry handler"
```

---

### Task 6: Directory Page (`projects.md`) Integration and End-to-End Verification

**Files:**
- Modify: `projects.md`
- Create: `test/projects_page_test.rb`

**Interfaces:**
- Consumes: `_includes/project_card.html`, `_includes/project_filters.html`.
- Produces: Integrated Student Projects directory rendering responsive grid columns with modal support.

- [ ] **Step 1: Write integration test for projects page**

Create `test/projects_page_test.rb`:

```ruby
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `docker compose run --rm site bundle exec ruby -Itest test/projects_page_test.rb`
Expected: FAIL.

- [ ] **Step 3: Update `projects.md`**

In `projects.md`:

```markdown
---
layout: page
title: Student Projects
subtitle: Available and ongoing student research projects
permalink: /projects/
---

The Control Lab offers diverse research and engineering project opportunities for undergraduate and graduate students. Browse currently available and active projects below, filter by topic or research group, or click any project to view its full details and prerequisites.

<div data-project-list>
{% include project_filters.html %}

{% assign projects = site.projects | where: 'published', true | sort: 'order' %}
{% if projects.size == 0 %}
<p class="pfcl-placeholder" data-project-empty>No student projects are currently published.</p>
{% else %}
<div class="columns is-multiline">
{% for project in projects %}
  <div class="column is-4-desktop is-6-tablet is-12-mobile" data-project-card
       data-labs="{{ project.lab_ids | join: ' ' }}"
       data-status="{{ project.recruitment_status }}"
       data-types="{{ project.project_types | join: ' ' }}"
       data-levels="{{ project.student_levels | join: ' ' }}">
    {% include project_card.html project=project %}
  </div>
{% endfor %}
</div>
<div class="notification is-light mt-4 is-hidden pfcl-empty-filter" data-empty-filter>
  No student projects match the selected search and filter criteria.
</div>
{% endif %}

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

</div>

<script src="{{ '/assets/js/projects.js' | relative_url }}?v={{ site.time | date: '%s' }}" defer></script>
```

- [ ] **Step 4: Run integration tests**

Run: `docker compose run --rm site bundle exec ruby -Itest test/projects_page_test.rb`
Expected: PASS.

- [ ] **Step 5: Run full verification suite**

1. Validator:
   `docker compose run --rm site bundle exec ruby scripts/validate_content.rb`
2. Test suite:
   `docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb`
   `docker compose run --rm site bundle exec ruby -Itest test/project_card_test.rb`
   `docker compose run --rm site bundle exec ruby -Itest test/project_layout_test.rb`
   `docker compose run --rm site bundle exec ruby -Itest test/projects_page_test.rb`
3. Production build:
   `docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace`

Expected: All commands succeed with exit code 0.

- [ ] **Step 6: Commit changes**

```bash
git add projects.md test/projects_page_test.rb
git commit -m "feat(projects): integrate rich cards, responsive grid, and inquiry modal"
```
