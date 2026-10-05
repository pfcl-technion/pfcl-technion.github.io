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
docker compose run --rm site bundle exec ruby -Itest -e "Dir.glob('test/**/*_test.rb').sort.each { |file| require File.expand_path(file) }"
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

Site content lives in Markdown files with YAML frontmatter. Items in `_labs/`, `_team/`, `_projects/`, and `_news/` belong to Jekyll collections. Labs, team, and news are rendered on hub pages; published projects also retain stable detail or external-handoff URLs under `/projects/<slug>/`.

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
project_type: research
tags: [software]
prerequisites: "Linear Systems, Python or C++"
duration: "1–2 semesters"
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

Required fields: `title`, `slug`, `lab_ids`, `recruitment_status`, `project_type`, `advisor_names`, `summary`, `contact_email`, `published`, `updated_at`, `featured`, `show_on_showcase`.
Allowed values for `recruitment_status`: `available`, `ongoing`, `completed`.
Allowed values for `project_type`: `research`, `experimental`.
Optional `tags` must be a list of strings; `prerequisites` may be a string or list of strings; `duration` must be a string.
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
- Do not edit any file under `_data/generated/` by hand. The aggregation command owns all three catalogs.

## External research-group content

PFCL aggregates public content owned by two constituent research groups:

- ANPL owns its committed X/Twitter cache, publication bibliography, and student-project listings.
- ConNeCt owns its news collection and publication bibliography.

The PFCL build treats both repositories as untrusted data. It checks out only the paths allowlisted in `_data/external_sources.yml`; it does not execute source-repository code, plugins, or build scripts. ANPL news is read from its committed cache, so PFCL never contacts X or uses X credentials.

Aggregation is metadata-only. It does not copy publication PDFs, full news bodies, full project pages, or source-site assets. Imported records retain their source name, canonical external URL, repository, commit revision, and source path. A constituent lab's content is never presented as PFCL-authored.

The generated catalogs are:

| File | Contents |
| --- | --- |
| `_data/generated/updates.json` | Attributed ANPL/ConNeCt news plus the eligible recent-publication subset |
| `_data/generated/publications.json` | Deduplicated metadata for final, non-future publications |
| `_data/generated/projects.json` | ANPL external project-card metadata and original-site links |

Empty arrays are valid before a local sync. Once generated, the files are machine-owned and must not be hand-edited.

Fixture-based adapter and orchestration tests run as part of the complete test command in [Verification](#verification); they do not require network access. To perform an optional local sync, first place read-only source checkouts at `external/anpl` and `external/connect`, then run:

```bash
docker compose run --rm site bundle exec ruby scripts/sync_external_content.rb \
  --anpl-root external/anpl \
  --connect-root external/connect \
  --output-dir _data/generated
```

The command resolves each checkout's Git revision, parses every required source before replacing any catalog, and writes deterministic UTF-8 JSON. Missing, empty, malformed, unsafe, or schema-invalid source data fails the sync; the Pages workflow then stops before deployment and retains the last successfully deployed site.

## Deployment

GitHub Actions builds and deploys `main` to GitHub Pages. Preview URL:
`https://pfcl-technion.github.io/`.
The workflow also runs daily at 03:17 UTC and can be started manually from the Actions tab. GitHub may delay scheduled jobs under load and may disable schedules in inactive public repositories after 60 days; use the manual workflow trigger when needed.
The production domain `pfcl.technion.ac.il` is not connected to this
repository; any cutover is a separate, explicitly approved operation.
