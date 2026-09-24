# PFCL Website

Source for the Philadelphia Flight Control Laboratory (PFCL) website,
served via GitHub Pages. Jekyll 4 + Bulma Clean Theme (gem), content in
Markdown collections, validated before every build.

## Development (Docker)

```bash
docker compose up --build            # dev server at http://localhost:4000/
```

The dev server serves the site at `http://localhost:4000/`.

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
`AGENTS.md`. Read it before editing content.

## Content editing

Site content lives in Markdown files with YAML frontmatter. Items in `_labs/`, `_team/`, `_projects/`, and `_news/` belong to Jekyll collections. These collections have `output: false` set in `_config.yml`, meaning individual files do not generate standalone URLs. Instead, Jekyll loops through each collection and renders cards onto hub pages such as `labs.md`, `team.md`, and `projects.md`.

### Research groups (`_labs/*.md`)

Create a file named `<slug>.md` in `_labs/`.

```yaml
---
title: Autonomous Navigation and Perception Lab
short_name: ANPL
slug: anpl
kind: research-group
leader_names:
  - Vadim Indelman
leader_email: vadim.indelman@technion.ac.il
logo: /assets/images/lab_anpl.png
leader_photo: /assets/images/pi_indelman.jpg
website: https://anpl-technion.github.io/
faculty_url: https://aerospace.technion.ac.il/person/vadim-indelman/
summary: "Short description of what the lab investigates."
active: true
order: 20
---
```

Required fields: `title`, `slug`, `kind`, `leader_names`, `summary`, `active`, `order`.
Allowed values for `kind`: `research-group`, `teaching-lab`, `shared-facility`.
The `slug` serves as the foreign key referenced by `lab_ids` in `_team/` and `_projects/`.

### Team members (`_team/*.md`)

Create a file named `<slug>.md` in `_team/`.

```yaml
---
title: Anna Clarke
slug: anna-clarke
role: Research Fellow
category: research-fellows
lab_ids: [clarke-group, pfcl]
email: anna.clarke@technion.ac.il
photo: /assets/images/pi_clarke.jpg
phone: "(04) 829-3819"
office: "Lady Davis, 276"
active: true
order: 10
---

Optional biographical text goes in the Markdown body.
```

Required fields: `title`, `slug`, `role`, `category`, `lab_ids`, `active`, `order`.
Allowed values for `category`: `leadership`, `faculty`, `research-fellows`, `research-staff`, `lab-staff`, `visiting`, `emeritus`.
Every entry in `lab_ids` must match an existing slug in `_labs/` or the umbrella id `pfcl`.

### Student projects (`_projects/*.md`)

Create a file named `<slug>.md` in `_projects/`.

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
summary: "Short project summary."
contact_email: vadim.indelman@technion.ac.il
application_url: https://anpl-technion.github.io/student_projects/
published: true
updated_at: 2026-09-22
featured: true
show_on_showcase: true
order: 20
---

Detailed description of project scope and requirements.
```

Required fields: `title`, `slug`, `lab_ids`, `recruitment_status`, `project_types`, `student_levels`, `advisor_names`, `summary`, `contact_email`, `published`, `updated_at`, `featured`, `show_on_showcase`.
Allowed values for `recruitment_status`: `available`, `ongoing`, `completed`.
Allowed values for `project_types`: `research`, `experimental`, `software`, `hardware`, `teaching`.
Allowed values for `student_levels`: `undergraduate`, `masters`, `phd`.
Available projects require either `contact_email` or `application_url`.

### News and announcements (`_news/*.md`)

Create a file named `YYYY-MM-DD-<slug>.md` in `_news/`.

```yaml
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

Article text goes here.
```

Required fields: `title`, `date`, `lab_id`, `category`, `excerpt`, `canonical_url`, `source_name`, `featured`, `show_on_showcase`.
Allowed values for `category`: `news`, `event`, `publication`, `project`, `award`, `position`, `research-highlight`.
For lab items other than `pfcl`, `canonical_url` must be a full HTTP or HTTPS URL, and `source_name` must attribute the source.

### Authoring rules

- Quote strings containing colons or brackets. An unquoted colon followed by a space breaks frontmatter parsing, causing Jekyll to drop all metadata silently.
- Do not fabricate content. Write `[Placeholder: description]` for any unverified names, emails, dates, or links.
- Keep slugs stable. Do not rename slugs once created, as other files reference them.
- Do not edit `_data/generated/updates.json` by hand. That file is reserved for automated feeds.

## Deployment

GitHub Actions builds and deploys `main` to GitHub Pages. Preview URL:
`https://pfcl-technion.github.io/`.
The production domain `pfcl.technion.ac.il` is not connected to this
repository; any cutover is a separate, explicitly approved operation.
