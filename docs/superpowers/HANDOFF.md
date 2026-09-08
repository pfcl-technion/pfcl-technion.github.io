# Handoff: PFCL Website v2 Rebuild — Status & Continuation Notes

**Written:** 2026-09-08 (work done 2026-09-07). **Branch:** `v2-rebuild` (pushed).
**Read first:** `AGENTS.md` (rules), then the specs below. This file tells you where things stand.

## Context in three sentences

PFCL (Philadelphia Flight Control Laboratory, Technion) is an umbrella org over research groups (ANPL, ConNeCt, CASY, Idan, Ben-Asher, Oshman + teaching labs). The v1 site was built by "antigravity" and the user rejected it (wrong look, fabricated filler content). v2 is a from-scratch rebuild on an orphan branch: ANPL-style structure, WordPress-pattern footer, **structure only** — real names/titles/contact info, everything else as `[Placeholder: …]` markers.

## Authoritative documents (in-repo)

1. `docs/superpowers/specs/2026-08-27-pfcl-website-foundation-design.md` — **normative** for schemas, IA, validation, deployment, boundaries.
2. `docs/superpowers/specs/2026-09-07-pfcl-website-v2-rebuild-design.md` — amendments that **win** over (1): url/baseurl fix, no-fabrication content policy, ANPL-styled presentation, footer design, seed inventory.
3. `docs/superpowers/plans/2026-09-07-pfcl-website-v2-rebuild.md` — the implementation plan; **all 6 tasks executed and verified**.

## Git state

- `main` — v1 antigravity site, still the deploy source for Pages. Do not touch casually.
- `archive/v1-antigravity` — frozen v1 snapshot (pushed).
- `v2-rebuild` — current work, orphan branch, 11 commits, pushed, **all checks green**.
- Integration rule (user-approved design): v2 reaches `main` only via **PR after CI passes and the user approves**. Not merged yet. `gh` CLI is NOT installed on this machine — the user must open the PR themselves via https://github.com/Philadelphia-Flight-Control-Laboratory/pfcl-technion.github.io/pull/new/v2-rebuild (draft PR was intended; suggested title: "Rebuild PFCL website (v2): ANPL-style structure with placeholder content").
- `references/` (WordPress scrape + theme backup) and `.claude/` are **gitignored, local-only by user decision** — never commit them. They contain the real contact info, teaching-labs copy, projects archive, and the WP `footer.php` the footer design came from.

## What exists on v2-rebuild

- Jekyll 4.3.4 + `bulma-clean-theme` 1.3.1 as a gem (never vendor). Overrides: `_includes/header.html`, `_includes/footer.html`, plus custom includes `lab_card`, `team_card`, `news_feed`, `carousel`, `project_filters`; styles in `_sass/pfcl.scss`; entry `assets/css/app.scss`.
- `_config.yml`: url `https://philadelphia-flight-control-laboratory.github.io`, baseurl `/pfcl-technion.github.io`; collections labs/team/projects/news all `output: false` (data-only; directory pages render them).
- Data: `_data/navigation.yml` (navbar, theme format: list of `{name, link, dropdown}`), `_data/footer.yml` (menus/contact/logos/copyright), `_data/taxonomies.yml`, `_data/generated/updates.json` = `[]` (reserved for aggregation deliverable — never hand-edit once aggregator exists).
- Seed content: 7 labs, 8 team members (6 PIs + Ruslan Arhipov + Arthur Grunwald), 1 welcome news item, **0 projects** (empty shell by user choice). Real PFCL logos in `assets/images/` (restored from archive branch).
- 11 route pages at root (`index.md`, `about.md`, `history.md`, `dedication.md`, `team.md`, `labs.md`, `projects.md`, `teaching.md`, `news.md`, `media.md`, `contact.md`) — all placeholder-marked; contact has the only real details (phone/email/address from WP contact page).
- `scripts/validate_content.rb` (+ `test/content_validation_test.rb`, minitest, 9 tests) enforces schemas/enums/slug rules/lab_id references/attribution. CI: `.github/workflows/ci.yml` (PR + main) and `pages.yml` (deploy main only), both via docker compose.
- Docker/compose/devcontainer per foundation spec (Ruby 3.3, Bookworm).

## Verification (run all three before any completion claim)

```bash
docker compose run --rm site bundle exec ruby scripts/validate_content.rb
docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb
docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace
```

Last run: all green. Dev server: `docker compose up --build` → **http://localhost:4000/pfcl-technion.github.io/** (bare `/` 404s — expected, it's the base path; README documents this).

## Gotchas learned the hard way

1. **Unquoted `: ` inside a plain YAML scalar** (e.g. `caption: x — [Placeholder: y]`) makes frontmatter unparseable and **Jekyll silently renders the page with empty frontmatter** — no build error. Quote such values. (Documented in AGENTS.md; collections are protected by the validator, *pages are not* — a page-frontmatter YAML check in the validator is a known, deliberately-skipped improvement.)
2. Ruby `String#split` drops trailing empty strings — validator needed `split(/^---\s*$/, -1)` for empty-body docs (regression test exists).
3. bulma-clean-theme internals (v1.3.1) for reference were cloned to `/tmp/bct` — includes `head/header/hero/footer.html`, layouts `default/page/post`; navbar uses Alpine.js (CDN), footer_menu mechanic is overridden by our `footer.html`.
4. Sass deprecation warnings in builds are upstream (Bulma 1.x inside the theme gem) — noise, not failures; don't vendor to silence them.

## Environment (this Windows machine)

- **Docker Desktop must be started manually** (`Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"` from PowerShell; engine takes minutes). No native Ruby; WSL Ubuntu-20.04 has no Ruby either. Everything runs through docker compose.
- `gh` CLI not installed. Screenshots possible via `msedge.exe --headless=new --screenshot=... --window-size=1440,3000 URL` (worked; the harness sometimes fails to display PNGs — retry or accept HTML greps).
- User's git identity: Ruslan Arhipov (he's the lab engineer + PFCL team member in `_team/`).

## Where the work stopped / next steps (in priority order)

1. **User is reviewing the structure** (dev server). One fix already made after review: duplicate Home navbar item (hardcoded + data) — removed hardcoded one; navbar is now purely data-driven.
2. Awaiting user's structural sign-off → they open the draft PR (link above) → CI runs → **user decides merge** (v1 keeps serving until then).
3. Next phases per user: **(a) design pass** (navbar+hero both solid teal = first candidate; typography, card polish, real carousel images), then **(b) content phase** — fill placeholders with real content. Note: dedication + history real text is NOT in `references/`; needs scraping from pfcl.technion.ac.il first. Also missing/deferred: footer logo images, YouTube URL (empty on purpose until verified), team photos, projects (23 real titles exist in `references/Projects Archive.md`).
4. Out of scope until separately specified: lab-update aggregation, TV showcase (`/showcase/` route reserved), Hebrew, any DNS/`pfcl.technion.ac.il` cutover.

## Working conventions on this repo

- Conventional commits + `Co-Authored-By: Claude Code <noreply@anthropic.com>` trailer.
- Never fabricate content (see AGENTS.md rule 4) — placeholders everywhere until verified.
- TDD for validator changes; commit after each green task; push to `v2-rebuild` freely (CI doesn't run on this branch — only PRs and main).
