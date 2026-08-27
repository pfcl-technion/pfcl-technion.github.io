# PFCL Website Foundation Design

**Date:** 2026-08-27  
**Status:** Proposed for user review  
**Repository:** `Philadelphia-Flight-Control-Laboratory/pfcl-technion.github.io`

## Purpose

Build a clean, maintainable public website for the Philadelphia Flight Control Laboratory (PFCL). PFCL is the umbrella organization for constituent research groups and sub-labs; the terms **research group** and **sub-lab** are equivalent in this project. ANPL, ConNect, CASY, and future groups retain ownership of their research, publications, news, and detailed websites. PFCL presents the shared institution, facilities, people, teaching activity, available student projects, and attributed highlights from those groups.

This specification covers the first deliverable: repository conventions, development environment, Jekyll foundation, public content model, navigation, build validation, and preview deployment. External update aggregation and the full-screen TV showcase are separate follow-on deliverables built against the interfaces defined here.

## Fixed Constraints

- The internal PFCL Obsidian vault is context only. It is never read by the website build, copied into the repository, or used as a publishing source.
- Public content lives in this GitHub repository or is imported from explicitly configured public lab websites in the later aggregation deliverable.
- PFCL must attribute imported material to its originating group and link to the canonical source.
- The site starts independently; it does not fork or copy the histories and accumulated files of the ANPL or ConNect repositories.
- The implementation uses Jekyll 4.3 or newer within the 4.x series, Bulma Clean Theme 1.3.1, and Bulma 1.x.
- GitHub Pages is deployed through GitHub Actions so the build is not limited to the `github-pages` gem dependency set.
- The current `pfcl.technion.ac.il` website remains untouched during development. Initial deployments use the GitHub Pages project-site preview URL until a separately approved domain cutover.
- The primary language is English. The architecture may add Hebrew later, but multilingual routing is outside this deliverable.

## Delivery Decomposition

The website program is divided into three independently testable deliverables:

1. **Foundation:** theme, environment, public content collections, navigation, validation, CI, and preview deployment. This document specifies that work.
2. **Lab update aggregation:** scheduled adapters that read public lab sources, normalize attributed updates, preserve last-known-good data, and trigger deployment.
3. **TV showcase:** a full-screen, auto-refreshing presentation page that mixes news, events, research highlights, and available projects using controlled weighted rotation.

The foundation reserves data contracts for deliverables 2 and 3 without implementing their behavior prematurely.

## Selected Architecture

### Static site and theme

Use Jekyll with `bulma-clean-theme` as a versioned gem dependency. The repository will override only the layouts, includes, and Sass required by the PFCL design. It will not vendor the whole theme. This keeps upstream updates possible while giving PFCL control over institutional presentation.

The alternatives rejected for the first release are:

- Copying ANPL as a baseline, because that imports obsolete example posts, duplicate configuration, custom plugins, publication machinery, and unrelated automation.
- Building a database-backed CMS, because the initial editorial volume does not justify a server, authentication system, database, security patching, and backup operations.
- Loading every lab website directly in visitors' browsers, because inconsistent source formats and source failures would make the PFCL pages unreliable.

### Development environment

The primary development environment is containerized and matches the Linux environment used by GitHub Actions:

- Ruby 3.3 container based on Debian Bookworm
- Bundler-managed Ruby dependencies
- Jekyll development server bound to the host with live reload
- VS Code Dev Container configuration using the same image definition
- Native Ruby remains optional; contributors do not need to install Ruby globally on Windows

The standard commands exposed in the README are:

```text
docker compose up --build
docker compose run --rm site bundle exec jekyll build --trace
docker compose run --rm site bundle exec ruby scripts/validate_content.rb
docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb
```

### Repository structure

```text
.
|-- .devcontainer/
|   `-- devcontainer.json
|-- .github/workflows/
|   |-- ci.yml
|   `-- pages.yml
|-- _data/
|   |-- navigation.yml
|   |-- taxonomies.yml
|   `-- generated/
|       `-- updates.json
|-- _includes/
|-- _labs/
|-- _layouts/
|-- _news/
|-- _projects/
|-- _sass/
|-- _team/
|-- assets/
|   |-- css/
|   |-- images/
|   `-- js/
|-- docs/superpowers/
|   |-- plans/
|   `-- specs/
|-- scripts/
|-- test/
|-- AGENTS.md
|-- Dockerfile
|-- Gemfile
|-- Gemfile.lock
|-- README.md
|-- _config.yml
|-- compose.yml
`-- index.md
```

`_data/generated/updates.json` is an explicitly generated interface reserved for the aggregation deliverable. It begins as a valid empty array and is never edited manually after the aggregator is introduced.

## Information Architecture

The initial public navigation is:

- Home
- About
  - About PFCL
  - History
  - PFCL Dedication
  - Team
- Research Groups
- Student Projects
- Teaching Labs
- News
- Media
- Contact

The following routes are reserved:

| Route | Responsibility |
| --- | --- |
| `/` | PFCL introduction, featured groups, available projects, and latest attributed activity |
| `/about/` | Concise institutional overview |
| `/history/` | Long-form chronological history with accessible images and captions |
| `/dedication/` | Philadelphia Chapter and donor recognition |
| `/team/` | Public PFCL personnel grouped by role and affiliation |
| `/labs/` | Constituent research-group directory |
| `/projects/` | Filterable public student-project directory |
| `/teaching/` | Teaching laboratories and course activity |
| `/news/` | Chronological PFCL-wide activity feed |
| `/media/` | Curated photos and videos |
| `/contact/` | Public contact details, address, directions, and email link |
| `/showcase/` | Reserved for the later TV showcase deliverable |

There is no top-level PFCL publications page in the foundation. Publications remain owned by constituent groups and may appear later as attributed update items that link to the originating lab.

## Public Content Model

All collection documents use YAML frontmatter followed by Markdown content. Identifiers are lowercase, stable, ASCII slugs. References use identifiers rather than display names so a lab or person can be renamed without breaking relationships.

### Research groups: `_labs`

Required fields:

```yaml
title: Autonomous Navigation and Perception Lab
short_name: ANPL
slug: anpl
kind: research-group
leader_names:
  - Vadim Indelman
summary: Public one-paragraph description.
website: https://anpl-technion.github.io/
active: true
order: 10
```

Optional fields include `logo`, `hero_image`, `email`, and `research_topics`. `kind` accepts `research-group`, `teaching-lab`, or `shared-facility` so the same infrastructure can represent all PFCL units without calling teaching spaces research groups.

### Team: `_team`

Required fields:

```yaml
title: Public display name
slug: stable-person-id
role: Public role or title
category: faculty
lab_ids: [anpl]
active: true
order: 10
```

Allowed categories are `leadership`, `faculty`, `research-staff`, `lab-staff`, `visiting`, and `emeritus`. Optional fields are `image`, `email`, `phone`, `website`, and `bio`. Only contact information already approved for public display is entered.

### Student projects: `_projects`

Projects are public website records maintained in this repository. Internal project notes and internal status values are not synchronized from Obsidian.

Required fields:

```yaml
title: Project title
slug: stable-project-id
lab_ids: [casy]
recruitment_status: available
project_types: [experimental]
student_levels: [undergraduate]
advisor_names: [Advisor Name]
summary: Public recruitment-oriented summary.
contact_email: public-contact@technion.ac.il
published: true
updated_at: 2026-08-27
featured: false
show_on_showcase: true
```

`lab_ids` is an array because a project may span multiple research groups or belong directly to PFCL using the reserved identifier `pfcl`. Allowed recruitment statuses are `available`, `ongoing`, and `completed`. Allowed project types are `research`, `experimental`, `software`, `hardware`, and `teaching`. Optional fields include `image`, `skills`, `duration`, `application_url`, `canonical_url`, `display_weight`, and Markdown detail content.

Only `published: true` documents are rendered. Only `recruitment_status: available` projects appear in the default projects view and in the later showcase rotation; visitors can deliberately reveal ongoing or completed projects using filters.

### News: `_news`

The foundation supports manually authored PFCL news. The aggregation deliverable will normalize external items into `_data/generated/updates.json` rather than copying entire external articles into `_news`.

Required fields:

```yaml
title: Update title
date: 2026-08-27
lab_id: connect
category: event
excerpt: A short public summary.
canonical_url: https://original-lab.example/item/
source_name: ConNect Lab
featured: false
show_on_showcase: true
```

Allowed categories are `news`, `event`, `publication`, `project`, `award`, `position`, and `research-highlight`. A PFCL-authored item may use `lab_id: pfcl` and a local canonical URL. Imported items always retain their external canonical URL and source label.

### Reserved generated update interface

`_data/generated/updates.json` contains an array of objects with this contract:

```json
{
  "id": "source-stable-id",
  "title": "Item title",
  "published_at": "2026-08-27T09:00:00Z",
  "lab_id": "anpl",
  "category": "news",
  "excerpt": "Short plain-text excerpt.",
  "canonical_url": "https://origin.example/item/",
  "source_name": "ANPL",
  "image_url": null,
  "featured": false,
  "show_on_showcase": true,
  "display_weight": 1
}
```

The foundation renders a combined, date-sorted view of local `_news` and generated updates. An empty or missing generated array does not prevent the site from building.

## Rendering and Interaction

- Collection lists use reusable cards and filters rather than page-specific duplicated markup.
- Project filters work without a server. The complete, accessible list remains present in the HTML, and lightweight JavaScript hides or shows matching cards.
- JavaScript is progressive enhancement: core navigation, content, and project links work when scripts fail or are disabled.
- Every image has meaningful alternative text or is explicitly decorative.
- Keyboard focus is visible, headings are hierarchical, and color contrast meets WCAG 2.2 AA.
- Motion respects `prefers-reduced-motion`. The later showcase includes a non-animated fallback and explicit pause control.
- Missing optional images use a PFCL or lab fallback image; broken images never collapse card layout.
- The contact page initially uses direct email, telephone, and directions links. A serverless contact form is not introduced without a separate privacy, spam, and data-retention decision.

## Validation and Failure Behavior

`scripts/validate_content.rb` validates all collection frontmatter before Jekyll builds. It reports the exact file and field for:

- missing required fields;
- unknown enum values;
- duplicate slugs;
- references to unknown `lab_ids`;
- invalid public URLs and dates;
- available projects without a public contact path;
- imported updates without canonical attribution.

The validator rejects a deployment on invalid content. Optional remote images and external links are reported separately so a temporary external outage does not block deployment.

Jekyll build warnings are treated as CI failures where possible. Generated update data is validated as JSON and against its required keys. The aggregation deliverable will preserve the previous per-source items when a source refresh fails; the foundation merely guarantees that last-known-good data can render.

## Testing and Continuous Integration

The test suite includes:

- unit tests for valid and invalid collection frontmatter;
- fixture tests for single-lab and multi-lab projects;
- a fixture proving an available project without contact information is rejected;
- a fixture proving unknown lab references are rejected;
- a fixture proving an empty generated update feed remains buildable;
- a production Jekyll build with the preview `baseurl`;
- generated HTML checks for internal links, missing local images, titles, and canonical metadata.

`ci.yml` runs validation, tests, and a production build for pull requests and pushes to `main`. `pages.yml` repeats the production validation and publishes the artifact only after all checks pass.

## Deployment and Domain Strategy

The repository name is a project-site name under the `Philadelphia-Flight-Control-Laboratory` organization, so the initial preview is built for:

```text
https://philadelphia-flight-control-laboratory.github.io/pfcl-technion.github.io/
```

The preview configuration uses:

```yaml
url: https://philadelphia-flight-control-laboratory.github.io
baseurl: /pfcl-technion.github.io
```

Migration of `pfcl.technion.ac.il` is a later, separately approved cutover. That operation requires repository Pages settings, a `CNAME` file, DNS coordination with Technion, HTTPS verification, and a rollback plan. No DNS or current-site change is part of the foundation implementation.

## Project Agent Rules

The root `AGENTS.md` created during implementation will encode these rules:

- Inspect existing files and public sources before editing.
- Treat PFCL as the umbrella and research group/sub-lab as equivalent terms.
- Never read from, link to, or publish the internal Obsidian vault from repository code or automation.
- Preserve YAML frontmatter and stable slugs during content edits.
- Validate all `lab_ids` and source attribution.
- Never present a constituent lab's publication or news as PFCL-authored.
- Never hand-edit generated aggregation data after the aggregator exists.
- Keep edits small and avoid vendoring the upstream theme.
- Run content validation, tests, and a production Jekyll build before completion claims.
- Keep the normal website progressively enhanced and accessible.
- Keep showcase-only animation isolated to `/showcase/` and honor reduced-motion preferences.
- Do not change DNS, Pages custom-domain settings, organization settings, or the current public website without explicit approval.

## Foundation Acceptance Criteria

The foundation is complete when:

1. A new contributor can start the site using Docker or the VS Code Dev Container without installing Ruby globally.
2. The site builds with Jekyll 4.x and Bulma Clean Theme 1.3.1.
3. All planned routes render at the GitHub Pages project-site base path.
4. Research groups, team members, projects, and local news use the documented schemas.
5. Projects can be filtered by group, recruitment status, project type, and student level.
6. The homepage can render featured groups, available projects, and a combined local/generated activity list.
7. Empty generated update data and missing optional images fail gracefully.
8. Invalid content prevents deployment with actionable file-level messages.
9. CI validates and builds every pull request and `main` push.
10. GitHub Pages preview deployment succeeds without altering `pfcl.technion.ac.il`.
11. `AGENTS.md` and `README.md` accurately explain the repository workflow and safety boundaries.

## Follow-on Interfaces

The aggregation specification will consume the lab registry and produce the reserved update JSON contract. The showcase specification will consume available `_projects`, local `_news`, and generated update objects. Neither follow-on deliverable may bypass the public schemas or introduce a dependency on the internal vault.
