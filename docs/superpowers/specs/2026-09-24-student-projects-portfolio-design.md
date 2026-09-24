# Design: Student Projects Visual Rich-Card Portfolio & Detail Pages

## Problem statement

The current Student Projects page (`/projects/`) renders projects as basic text blocks without imagery, and projects do not have standalone detail pages (`output: false`). In contrast, the ANPL lab website (`anpl-technion.github.io/student_projects/`) and the original legacy WordPress website provide rich visual thumbnails and dedicated project detail pages. 

We want to adopt ANPL's visual multi-page architecture while significantly upgrading it with real-time keyword search, recruitment status badges, supervisor lookups from `_team`, categorized footer tags, and an embedded Technion Microsoft Form inquiry modal.

## Design goals

1. **Visual directory grid:** Transform `/projects/` into a responsive rich-card portfolio using 4:3 / 16:9 thumbnails and clean Bulma grid columns.
2. **Dedicated project detail pages:** Set `output: true` for `_projects` and create a dedicated layout (`_layouts/project.html`) displaying full project descriptions, prerequisites, supervisor details, and direct inquiry actions.
3. **Brand aesthetic:** Adhere strictly to the universal sharp-corner policy (`border-radius: 0 !important;`) matching the Faculty of Aerospace Engineering theme.
4. **Recruitment transparency:** Retain clear status badges (`Available`, `Ongoing`, `Completed`) without artificial seat quotas.
5. **Supervisor humanization:** Automatically pull supervisor profile photos, titles, and faculty links from [`_team`](file:///c:/Users/sarchi/git/pfcl-technion.github.io/_team) on both cards and detail pages.
6. **Categorization tags:** Display Research Group, Advisor, and Project Type tags on each card and detail page.
7. **Instant search & filtering:** Provide a text search bar working in real time alongside dropdown filters in client-side JavaScript.
8. **Inquiry workflow:** Provide a "Hear more" button launching a Technion Microsoft Form modal with direct email fallback.

---

## 1. Data schema & site configuration

### Project schema (`_projects/*.md`)

Projects retain their existing schema, with the addition of an optional `thumbnail` field:

```yaml
---
title: Autonomous Viewpoint-Dependent Semantic Perception
slug: autonomous-semantic-perception
lab_ids: [anpl]
recruitment_status: available
project_types:
  - research
  - software
student_levels:
  - undergraduate
  - masters
advisor_names:
  - Vadim Indelman
thumbnail: /assets/images/projects/autonomous-semantic-perception.jpg
summary: "Development of active perception algorithms enabling mobile robots to optimize viewpoints for semantic understanding and scene reconstruction."
contact_email: vadim.indelman@technion.ac.il
application_url: https://anpl-technion.github.io/student_projects/
published: true
updated_at: 2026-09-22
featured: true
show_on_showcase: true
order: 20
---

Detailed description of project scope, background, methodology, and prerequisites.
```

- `thumbnail` (optional string): Path to a web-optimized project image under `/assets/images/projects/`.
- Fallback graphic: When `thumbnail` is omitted, the template displays a default aerospace engineering graphic (`/assets/images/project_default.jpg`).

### Site configuration (`_config.yml`)

Enable standalone page output for projects and set their URL permalinks:

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

project_inquiry_form_url: ""
```

### Schema validator (`scripts/validate_content.rb`)

Update `ContentValidator` to recognize `thumbnail` as an allowed optional field for `projects`. When present, the validator checks that the path begins with `/assets/` or is a valid URL.

---

## 2. Card component architecture (`_includes/project_card.html`)

A reusable include `project_card.html` encapsulates card rendering for `/projects/` and the homepage selected projects grid.

### Visual structure

```
+-------------------------------------------------------------+
| [Thumbnail Image (Link to Detail)] [Status Badge: Available]|
+-------------------------------------------------------------+
| Title: Autonomous Viewpoint-Dependent Semantic Perception   |
|                                                             |
| [Avatar] Vadim Indelman (Faculty Link)                      |
|                                                             |
| Summary: Development of active perception algorithms...     |
+-------------------------------------------------------------+
| Tags: [Lab: ANPL]  [Advisor: V. Indelman]  [Type: Research] |
+-------------------------------------------------------------+
| [ Button: View Details & Apply -> ]                         |
+-------------------------------------------------------------+
```

### Component details

1. **Card container:** Sharp corners (`border-radius: 0`), subtle border (`#e2e8f0`), and soft hover lift.
2. **Card image header:** Bulma `card-image` with status overlay badge (`Available` in green, `Ongoing` in navy, `Completed` in slate gray).
3. **Card title & link:** Clicking the thumbnail or title navigates to `{{ project.url | relative_url }}`.
4. **Supervisor lookup:** Liquid inspects `site.team` matching `advisor_names` to display avatar photo, name, and profile link.
5. **Footer tags:** Research group short name, Advisor name(s), and Project Type tags.
6. **Action button:** "View Details & Apply" button linking directly to the project detail page, with quick inquiry trigger.

---

## 3. Dedicated project detail page layout (`_layouts/project.html`)

Modeled on ANPL's `_layouts/student_project.html` and modernized to match the PFCL design system.

### Layout structure

1. **Hero header:** Page title displaying the project name, subtitle showing supervising faculty, and a breadcrumb link back to `/projects/`.
2. **Overview panel (two columns on desktop):**
   - **Left column:** High-resolution project image with status badge.
   - **Right column (Project metadata card):**
     - Status: Color-coded recruitment badge.
     - Research Group: Lab title linking to `/labs/`.
     - Supervising Advisors: Avatars, names, email links, and faculty pages.
     - Target Students: Degree levels (Undergraduate, Masters, PhD).
     - Project Types: Tags (Research, Experimental, Software, etc.).
     - Primary Action: "Hear More / Inquire" button launching the Microsoft Form modal.
3. **Content body:**
   - Full Markdown body (`{{ content }}`), cleanly rendered with sections for Background, Scope, Prerequisites, and Expected Deliverables.
4. **Bottom navigation:** "Back to all projects" button.

---

## 4. Microsoft Forms inquiry modal

### Modal markup & interaction

Included on both `projects.md` and `_layouts/project.html`:

```html
<div class="modal" id="pfcl-project-modal" aria-hidden="true">
  <div class="modal-background" data-modal-close></div>
  <div class="modal-card">
    <header class="modal-card-head">
      <p class="modal-card-title is-size-5" id="pfcl-modal-title">Inquire about project</p>
      <button class="delete" aria-label="close" data-modal-close></button>
    </header>
    <section class="modal-card-body">
      <div id="pfcl-modal-form-container">
        <!-- Rendered iframe for site.project_inquiry_form_url or mailto fallback -->
      </div>
    </section>
    <footer class="modal-card-foot">
      <button class="button is-small" data-modal-close>Close</button>
    </footer>
  </div>
</div>
```

### Behavior

1. Clicking "Hear more" on any card or detail page opens the modal.
2. The modal displays the embedded Technion Microsoft Form (`site.project_inquiry_form_url`).
3. If no form URL is set in `_config.yml`, the modal provides a pre-filled direct email button opening `mailto:pfcl@technion.ac.il?subject=Inquiry: [Project Title]`.
4. Escape key, background click, and close buttons dismiss the modal.

---

## 5. Search and filter controls

### Filter bar (`_includes/project_filters.html`)

Add an expanded text search input field before the dropdown filters:

```html
<div class="field is-grouped is-grouped-multiline pfcl-filters-wrapper">
  <div class="control is-expanded">
    <label class="label is-small" for="pfcl-project-search">Search projects</label>
    <div class="control has-icons-left">
      <input class="input is-small" id="pfcl-project-search" type="search" placeholder="Search title, advisor, or keywords...">
      <span class="icon is-small is-left">
        <i class="fas fa-search"></i>
      </span>
    </div>
  </div>
  <!-- Dropdown controls for Group, Status, Type, Level -->
</div>
```

### Client-side logic (`assets/js/projects.js`)

Extend `applyFilters()` to:
1. Normalize text search query to lowercase.
2. Test whether `card.textContent` contains the search query.
3. Simultaneously verify all active select dropdowns match the card's `data-labs`, `data-status`, `data-types`, and `data-levels` attributes.
4. Toggle visibility and update the empty results notification cleanly.

---

## 6. Verification plan

1. **Content validator:** Run `docker compose run --rm site bundle exec ruby scripts/validate_content.rb` to ensure schema compliance.
2. **Unit tests:** Run `docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb` and component tests.
3. **Production build:** Run `docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace`.
4. **Browser testing:** Verify grid scannability on `/projects/`, verify that clicking a card navigates to `/projects/<slug>/`, and test modal inquiry interactions on both desktop and mobile.
