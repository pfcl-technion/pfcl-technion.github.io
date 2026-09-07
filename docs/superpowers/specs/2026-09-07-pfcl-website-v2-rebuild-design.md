# PFCL Website v2 Rebuild Design

**Date:** 2026-09-07
**Status:** Proposed for user review
**Branch:** `v2-rebuild` (orphan; the v1 build is archived on `archive/v1-antigravity`)

## Purpose

Replace the v1 (antigravity-generated) implementation of the PFCL website with a clean, from-scratch rebuild that looks like the ANPL website (https://anpl-technion.github.io) while following the PFCL information architecture. This phase delivers **structure only**: real names and titles, bracketed placeholders everywhere else, no prose content. Visual design refinement and content filling are separate later phases.

## Why rebuild

The v1 build followed the letter of the 2026-08-27 foundation spec (Jekyll, Bulma Clean Theme, collections, CI, Docker) but:

- its presentation diverged from the intended ANPL-like look;
- it filled content gaps with generated prose and unverifiable details. Spot checks found every `_team` member assigned `pfcl@technion.ac.il`, an invented phone number, and paraphrased bios presented as fact;
- its `_config.yml` used `url: https://pfcl-technion.github.io` with an empty `baseurl`, which cannot serve correctly as a project page under the `Philadelphia-Flight-Control-Laboratory` organization.

## Relationship to the 2026-08-27 foundation spec

The earlier spec (`2026-08-27-pfcl-website-foundation-design.md`) remains normative for everything it defines: fixed constraints, umbrella terminology, Obsidian boundary, collection schemas, navigation IA, routes, validation behavior, CI, Docker environment, deployment strategy, and agent rules. This document **amends** it where stated below and adds the rebuild-specific decisions. Where the two documents disagree, this document wins.

## Decision record (approved 2026-09-07)

| Decision | Choice |
| --- | --- |
| Rebuild scope | Total from-scratch; `v2-rebuild` starts from an empty tree, infra included |
| ANPL look | Write fresh layouts/includes on the `bulma-clean-theme` gem, styled after ANPL; do not copy ANPL files or adopt its plugins (`jekyll-scholar` etc.) |
| `references/` folder | Local-only, gitignored, never committed |
| Branches | `archive/v1-antigravity` (v1 preserved) and `v2-rebuild` (this work); `main` keeps deploying v1 until v2 is approved via PR |
| Initial `_team` | Verified core only: 6 group PIs + Ruslan Arhipov + Arthur Grunwald |
| Initial `_projects` | Empty; `/projects/` page shell with filters and a placeholder marker |

## Git strategy

1. Commit pending housekeeping on `main` (done: `.claude/` gitignored).
2. `archive/v1-antigravity` points at the final v1 commit (done, pushed).
3. `v2-rebuild` is an orphan branch with an empty root commit (done, pushed).
4. `references/` stays untracked in the working directory and is listed in v2's `.gitignore`.
5. v2 reaches `main` only through a PR after CI passes and the user approves the structure.

## Amendments to the foundation spec

### 1. URL and baseurl

```yaml
url: https://philadelphia-flight-control-laboratory.github.io
baseurl: /pfcl-technion.github.io
```

This is a correction, not a change of deployment strategy; domain cutover for `pfcl.technion.ac.il` remains a separate, explicitly approved operation.

### 2. Content policy (new, normative for all future phases)

- **Real data only where verified:** lab names, PI names, staff names, course names and numbers, the public contact details (`pfcl@technion.ac.il`, `+972-4-829-3820`), and the postal address from the WordPress contact page.
- **Placeholders everywhere else,** using a single visible convention: `[Descriptive placeholder — e.g. one-paragraph lab summary]`. Placeholders must describe *what* content belongs there, not fake it.
- **Never invent:** emails, phone numbers, dates, bios, quotes, statistics, or roles. If a field is required by a schema but unknown, the seed content uses the field's documented default and the body carries a placeholder noting the field needs confirmation.
- Enum-typed frontmatter in seed content must hold **valid** values (the validator enforces this), with a placeholder in the body flagging the value as unconfirmed.

### 3. ANPL-styled presentation

Built as fresh overrides on the `bulma-clean-theme` gem:

- **Navbar:** fixed to top, PFCL logo left, menu right, mirroring ANPL's flat navigation bar.
- **Homepage order:** hero (site title, "Technion – Israel Institute of Technology" subtitle, welcome paragraph placeholder, two CTA buttons) → image carousel (placeholder slides) → Research Groups grid (logo, name, PI, one-line placeholder) → Selected Student Projects teaser → News & Updates feed (local `_news` plus the reserved generated-updates slot) → partner logo row (placeholders).
- **Inner pages:** single clean content column, no sidebar, `theme_color: '#eeeeee'`, Bulma Clean Theme defaults otherwise.
- **No Twitter embeds, no Disqus, no analytics** in v2 (ANPL has them; PFCL does not inherit them without a separate decision).

### 4. Footer (from the WordPress `footer.php` pattern)

Three-zone footer above a copyright bar, entirely data-driven from `_data/footer.yml`:

- **Left (~50%):** two or three menu columns, each a heading + link list (site sections).
- **Middle (~25%):** email icon + `pfcl@technion.ac.il`, phone icon + `+972-4-829-3820`, divider, YouTube channel link.
- **Right (~25%):** stacked logo images linking out — Technion, Faculty of Aerospace Engineering, `[additional partner/donor logos to confirm]`.
- **Copyright bar:** `© 2026 Philadelphia Flight Control Laboratory — Technion`. No web-designer credit.

## Seed content inventory

- `_labs` (7): ANPL, ConNeCt, CASY, Idan Group, Ben-Asher Group, Oshman Group, Flight Control Teaching Lab — real names, real PIs, placeholder summaries.
- `_team` (8): Daniel Zelazo, Vadim Indelman, Tal Shima, Moshe Idan, Yossi Ben-Asher, Yaakov Oshman, Ruslan Arhipov (Lab Engineer), Arthur Grunwald (emeritus, history author). Placeholder bios; no emails or phones unless verified.
- `_projects`: none; page shell only.
- `_news`: one placeholder welcome item or none, per implementation judgment.
- Pages: the eleven routes from the foundation spec, each a titled shell with section placeholders.

## Acceptance criteria

1. `v2-rebuild` builds with Jekyll 4.3.x + `bulma-clean-theme` 1.3.1 from a tree containing no v1 files.
2. All eleven foundation routes render under the project-site base path.
3. Navbar, homepage order, inner-page column, and footer match this document's presentation section.
4. Footer content is driven entirely by `_data/footer.yml`.
5. Seed collections contain exactly the inventory above; every unverified content slot shows a bracketed placeholder.
6. `scripts/validate_content.rb`, the minitest suite, and both workflows are recreated and pass.
7. Docker/compose/devcontainer work per the foundation spec.
8. CI passes on the v2 PR; `main` still serves v1 until that PR merges.

## Out of scope

Visual design refinement (colors beyond theme defaults, typography, imagery), real content authoring, the aggregation deliverable, the TV showcase, Hebrew, and any DNS or `pfcl.technion.ac.il` change.
