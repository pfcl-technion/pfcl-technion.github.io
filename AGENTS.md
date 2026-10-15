# AGENTS.md

Instructions and specifications for AI agents and contributors working on the PFCL website.

## Core Purpose & Architecture

The Philadelphia Flight Control Laboratory (PFCL) at the Technion is an umbrella institution encompassing multiple research groups and teaching laboratories (ANPL, ConNeCt, CASY, Idan Group, Ben-Asher Group, Oshman Group, Flight Control Teaching Lab).

The website is built with:
- **Jekyll 4.3.x** with `bulma-clean-theme` (1.3.x) installed as a Ruby gem dependency.
- **Presentation style:** Flat, clean aesthetic inspired by the ANPL website layout with custom SCSS in `_sass/pfcl.scss` and `assets/css/app.scss`.
- **Theme overrides:** No theme vendoring. Overrides live strictly in `_includes/` (e.g., `header.html`, `footer.html`, `lab_card.html`, `team_card.html`, `news_feed.html`, `carousel.html`, `project_filters.html`) and `_layouts/`.

## Repository Structure & Content Collections

### Collections (Data-Only, `output: false`)
1. **`_labs/`**: Constituent research groups and laboratories.
   - Enforced frontmatter keys: `name`, `pi`, `slug`, `website`, `logo`, `description`.
2. **`_team/`**: Faculty, lab engineers, and research personnel.
   - Enforced frontmatter keys: `name`, `title`, `role` (enum: faculty, staff, student, emeritus), `lab_id` (must reference valid lab or pfcl), `order`.
3. **`_projects/`**: Student research and development projects.
   - Enforced frontmatter keys: `title`, `slug`, `lab_id`, `description`, `topics`, `status` (enum: open, completed).
4. **`_news/`**: News releases, announcements, and lab milestones.
   - Enforced frontmatter keys: `title`, `date`, `lab_id`, `category`, `canonical_url`, `source_name`.

### Route Pages
- Home (`/`, `index.md`): Hero, welcome, image carousel, research groups grid, student projects showcase, news feed, partner logos.
- About (`/about/`, `about.md`): Overview of PFCL umbrella mission.
- Research Groups (`/labs/`, `labs.md`): Grid of constituent labs and teaching facilities.
- Team (`/team/`, `team.md`): Leadership, principal investigators, and staff directory.
- Projects (`/projects/`, `projects.md`): Student project directory with tag/lab filtering.
- Teaching (`/teaching/`, `teaching.md`): Laboratory courses, equipment, and flight simulators.
- News (`/news/`, `news.md`): Laboratory announcements and achievements.
- Media (`/media/`, `media.md`): Photo galleries, event documentation, and videos.
- History (`/history/`, `history.md`): Archival history of aerospace flight control at Technion.
- Dedication (`/dedication/`, `dedication.md`): Historical dedication to the Philadelphia community.
- Contact (`/contact/`, `contact.md`): Address, map, email, and phone contact details.
- Showcase (`/showcase/`, `showcase.md`): Digital signage display mode for hallway displays (high contrast, sharp borders, live rotating slides).
- Compliance & Policy: `accessibility.md`, `privacy.md`.

### Shared Data (`_data/`)
- `navigation.yml`: Main navbar structure (`name`, `link`, `dropdown`).
- `footer.yml`: Three-zone footer (About menu, Research menu, Student menu, verified contact info, partner logos, copyright).
- `taxonomies.yml`: Standardized project tags, categories, and research topics.
- `generated/updates.json`: Reserved slot for external lab aggregation feed (never manually edit).

## Core Rules and Boundaries

1. **Inspect before editing.** Read existing schemas, layouts, and files before modifying or adding content.
2. **Umbrella terminology.** PFCL is the umbrella institution; "research group" and "sub-lab" are equivalent terms.
3. **No fabricated content.** Only verified names, titles, and contact details. Everything unverified must use a bracketed `[Placeholder: ...]` marker. Never invent emails, phone numbers, dates, bios, quotes, or statistics.
4. **Preserve frontmatter schemas.** Maintain the strict YAML schemas of `_labs/`, `_team/`, `_projects/`, and `_news/` (see `scripts/validate_content.rb` for enforced fields and enums).
5. **Stable identifiers.** Never rename slugs; references use identifiers, not display names.
6. **Attribution integrity.** Never present a constituent lab's publication or news as PFCL-authored. Imported items always carry `canonical_url` and `source_name`.
7. **No theme vendoring.** `bulma-clean-theme` stays a gem dependency; overrides live only in `_layouts/`, `_includes/`, and `_sass/`.
8. **Accessibility.** The site works without JavaScript; maintains WCAG 2.2 AA contrast; respects `prefers-reduced-motion`.
9. **Domain safety.** Never change DNS, GitHub Pages custom-domain settings, or organization settings without explicit authorization.

## YAML Syntax Rule

An unquoted colon+space inside a plain frontmatter scalar (e.g. `caption: slide — [Placeholder: text]`) makes YAML unparseable, causing Jekyll to silently render the page with **empty** frontmatter without failing the build. Always quote any value containing `: `, `[`, or `{`.

## Verification Commands

Before declaring any task or feature complete, verify through the build suite:
```bash
docker compose run --rm site bundle exec ruby scripts/validate_content.rb
docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb
docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace
```
