# Philadelphia Flight Control Laboratory (PFCL) Website

Public website for the Philadelphia Flight Control Laboratory at the Technion - Israel Institute of Technology Faculty of Aerospace Engineering.

## Architecture

- **Static Site Generator:** Jekyll 4.x
- **Theme:** Bulma Clean Theme 1.3.1 (Bulma 1.x)
- **Deployment:** GitHub Pages via GitHub Actions (`pages.yml`)
- **Validation:** Ruby content validator (`scripts/validate_content.rb`)

## Quickstart with Docker Compose

No local Ruby installation is required.

```bash
# Start local development server with livereload
docker compose up --build

# Open in browser: http://localhost:4000
```

## Running Tests and Validation

```bash
# Validate frontmatter content schemas
docker compose run --rm site bundle exec ruby scripts/validate_content.rb

# Run unit tests
docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb

# Build preview site
docker compose run --rm site bundle exec jekyll build --config _config.yml,_config.preview.yml --trace
```

## Content Guidelines

See [AGENTS.md](AGENTS.md) and [docs/superpowers/specs/2026-08-27-pfcl-website-foundation-design.md](docs/superpowers/specs/2026-08-27-pfcl-website-foundation-design.md) for data schemas and contributor guidelines.

