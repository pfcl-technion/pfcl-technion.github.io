# PFCL Website

Source for the Philadelphia Flight Control Laboratory (PFCL) website,
served via GitHub Pages. Jekyll 4 + Bulma Clean Theme (gem), content in
Markdown collections, validated before every build.

## Development (Docker)

```bash
docker compose up --build            # dev server at http://localhost:4000/pfcl-technion.github.io/
```

The dev server serves the site under the same base path as the GitHub
Pages preview, so visiting `http://localhost:4000/` alone returns 404 —
this is expected.

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
`AGENTS.md` — read it before editing content.

## Deployment

GitHub Actions builds and deploys `main` to GitHub Pages. Preview URL:
`https://philadelphia-flight-control-laboratory.github.io/pfcl-technion.github.io/`.
The production domain `pfcl.technion.ac.il` is not connected to this
repository; any cutover is a separate, explicitly approved operation.
