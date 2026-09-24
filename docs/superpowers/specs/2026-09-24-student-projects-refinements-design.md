# Design: Student Projects Refinements and Homepage Alignment

## Problem statement

Following the initial rollout of the Student Projects portfolio and standalone detail pages, several refinements are needed to better align with departmental reality and streamline the user experience:

1. **Empty groups in filter dropdown:** The research group dropdown currently displays every laboratory registered in `_labs`, even if that group currently has zero active student projects.
2. **Project classification:** Projects are strictly either **Research** or **Experimental**. Secondary attributes like Software, Hardware, and specific software tools (MATLAB, Simulink) belong as extra tags rather than primary categories.
3. **Student level redundancy:** All projects in the PFCL portfolio are undergraduate projects by definition. Displaying and filtering by degree level adds clutter without informational value.
4. **Homepage inconsistency:** The homepage (`index.md`) still uses legacy plain text blocks for selected student projects instead of the newly developed visual rich cards.

## Design goals

1. **Dynamic group filtering:** Render only research groups that have at least one published project in `_includes/project_filters.html`.
2. **Simplified project type schema:** Replace `project_types: []` with an enum `project_type: "research" | "experimental"` and an optional `tags: []` list for technical topics (Software, Hardware, etc.).
3. **Remove student level:** Drop `student_levels` from the schema, validation, card templates, detail layout, and filter controls.
4. **Homepage visual alignment:** Render `_includes/project_card.html` in the homepage's `Selected student projects` section with inquiry modal support.
5. **Zero regressions:** Maintain full test coverage and schema validation across all gates.

---

## 1. Schema & Validation Updates

### Schema adjustments (`_projects/*.md`)

- Remove `student_levels` entirely from all project documents.
- Replace `project_types: [research, software]` with:
  ```yaml
  project_type: research
  tags:
    - software
  ```
- Allowed values for `project_type`: `research`, `experimental`.
- `tags` is an optional list of string scalars representing technical areas or tools (e.g. `software`, `hardware`, `matlab`, `simulink`).

### Validator adjustments (`scripts/validate_content.rb`)

- In `REQUIRED_FIELDS["projects"]`:
  - Remove `project_types` and `student_levels`.
  - Add `project_type`.
- Define `PROJECT_TYPES = %w[research experimental].freeze`.
- In `validate_collection("projects")`:
  - `check_enum(rel, fields, "project_type", PROJECT_TYPES)`
  - Optional `check_string_list(rel, fields, "tags")` if present.

---

## 2. Filter Bar & Search Logic

### Filter bar markup (`_includes/project_filters.html`)

1. **Research group dropdown**:
   - Collect unique lab IDs from all published projects:
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
     ```
   - Only output `<option>` tags for labs whose `slug` is contained in `active_lab_ids`.
2. **Project type dropdown**:
   - Dropdown with 2 options: `Research` and `Experimental` (plus "All types").
3. **Remove student level dropdown**:
   - Remove the level `<select>` completely.

### Client-side logic (`assets/js/projects.js`)

- Filter cards based on `data-labs`, `data-status`, and `data-type` (`project.project_type`).
- Text search matches title, advisor name, lab name, summary, and `project.tags`.

---

## 3. Component & Layout Updates

### Card component (`_includes/project_card.html`)

- Update tag rendering:
  1. Research Group tag (`<span class="tag is-info is-light"><i class="fas fa-flask mr-1"></i>{{ lab.short_name | default: lab_slug | upcase }}</span>`)
  2. Advisor tag (`<span class="tag is-link is-light"><i class="fas fa-user-tie mr-1"></i>{{ advisor_name }}</span>`)
  3. Type tag (`<span class="tag is-primary is-light">{{ p.project_type | capitalize }}</span>`)
  4. Extra tags from `p.tags` (`<span class="tag is-light">{{ tag | capitalize }}</span>`)
- Remove student level tags completely.

### Project detail layout (`_layouts/project.html`)

- Update overview panel:
  - Display `Project Type` (`page.project_type | capitalize`) as primary badge.
  - Display `Technical Topics / Tools` from `page.tags` if present.
  - Remove student levels section completely.

---

## 4. Homepage Integration (`index.md`)

- In `## Selected student projects`:
  - Render projects using `_includes/project_card.html` inside responsive grid columns (`column is-4-desktop is-6-tablet is-12-mobile` or `column is-6-desktop is-12-tablet`).
  - Append the inquiry modal markup and `<script src="{{ '/assets/js/projects.js' | relative_url }}"></script>` to `index.md` so that the "Inquire" button functions seamlessly from the homepage.

---

## 5. Verification Plan

1. **Content validator**:
   `docker compose run --rm site bundle exec ruby scripts/validate_content.rb`
2. **Test suite**:
   `docker compose run --rm site bundle exec ruby -I. -e "Dir.glob('test/**/*_test.rb').each { |f| require f }"`
3. **Production build**:
   `docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace`
4. **Browser testing**:
   Verify homepage visual cards, inquiry modal on homepage, directory dropdown filtering without empty groups, and project detail page tags.
