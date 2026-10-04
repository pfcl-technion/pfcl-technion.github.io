# External Lab Content Aggregation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and render a deterministic, metadata-only feed of ANPL and ConNeCt news, final publications, and ANPL student projects during the PFCL Pages build.

**Architecture:** A Ruby pipeline reads an allowlisted set of files from shallow source-repository checkouts, normalizes them through source-specific adapters, and atomically writes three JSON catalogs for Jekyll. PFCL renders those catalogs with explicit lab attribution, while strict validation and fixture-based tests keep source drift or unsafe data from reaching a deployment.

**Tech Stack:** Ruby 3.3, `bibtex-ruby`, YAML/JSON standard libraries, Jekyll 4, Liquid, Bulma, Minitest, Docker Compose, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-10-04-external-content-aggregation-design.md`

## Global Constraints

- PFCL is the umbrella institution; imported items remain attributed to their constituent research group.
- Read only the configured public files from source repositories; never execute source code or write back to those repositories.
- Never call X/Twitter or add an X credential; ANPL news comes only from its committed `_data/tweets.json`.
- Import publication metadata only; discard every PDF field and never copy a PDF or source-site asset.
- Exclude submitted, accepted, in-press, forthcoming, future-dated, and arXiv-only publications.
- Publication News uses the current month plus the preceding eleven calendar months, at most five records per lab; year-only publications cannot become News.
- Never invent missing project status, type, advisor, contact, date, or other metadata.
- Preserve the existing project slugs `autonomous-semantic-perception`, `collaborative-aerial-navigation`, and `robust-risk-averse-decision-making`.
- Generated JSON is deterministic for fixed source revisions and `as_of`; once aggregation exists, `_data/generated/*.json` is machine-owned.
- All content and links remain usable without JavaScript, imported strings render as escaped text, and external links use `rel="noopener noreferrer"`.
- Do not change DNS, Pages custom-domain settings, organization settings, or the live `pfcl.technion.ac.il` site.
- Before completion, run the content validator, complete test suite, and production Jekyll build.

## Review Focus

- A syntactically valid but unexpectedly empty source collection must fail the sync instead of erasing a lab's feed; Task 5 adds the runner test.
- Duplicate BibTeX keys that refer to different papers must survive, while matching DOI/arXiv records across labs must merge; Task 4 adds both tests.
- Month-only publication dates must sort deterministically without displaying an invented day; Tasks 5 and 7 add catalog and rendering tests.
- Source Markdown containing HTML or script tags must become escaped plain text, never executable markup; Tasks 2, 3, and 8 add adapter and card tests.
- External project records lacking status or type must appear in the unfiltered/ANPL views and disappear under a status or type filter without breaking no-JavaScript access; Task 8 adds template and browser-logic tests.

---

### Task 1: Source Allowlist and Aggregation Foundation

**Files:**
- Modify: `Gemfile`
- Modify: `Gemfile.lock`
- Modify: `_config.yml`
- Create: `_data/external_sources.yml`
- Create: `_data/generated/publications.json`
- Create: `_data/generated/projects.json`
- Create: `scripts/external_content/config.rb`
- Create: `test/external_content/config_test.rb`

**Interfaces:**
- Produces: `PFCL::ExternalContent::Config.load(path) -> Config` and `Config#fetch(id) -> Source`.
- Produces: `Source` readers `id`, `lab_id`, `source_name`, `repository`, `site_url`, `publications_url`, `paths`, and `legacy_project_slugs`.
- Produces: Empty-array placeholders for all three generated catalogs; later tasks replace them only through the writer.

- [ ] **Step 1: Add failing configuration tests**

In `test/external_content/config_test.rb`, assert that the real config loads `anpl` and `connect`, exposes the exact allowlisted paths below, preserves all three legacy slug mappings, and rejects a source missing `repository`, `site_url`, `lab_id`, `source_name`, or `paths`.

Expected source paths:

```yaml
anpl:
  news: _data/tweets.json
  publications: _bibliography/VadimIndelman.bib
  projects: _student-projects
connect:
  news: _news
  publications: _bibliography/DZ_Complete.bib
```

- [ ] **Step 2: Run the test and confirm the missing loader failure**

Run: `docker compose run --rm site bundle exec ruby -Itest test/external_content/config_test.rb`

Expected: FAIL because `PFCL::ExternalContent::Config` does not exist.

- [ ] **Step 3: Add the parser dependency and source configuration**

Add `gem "bibtex-ruby", "~> 6.1"` to the test/runtime bundle and refresh `Gemfile.lock`. Create `_data/external_sources.yml` with the two repository slugs, source-site URLs, publications-page URLs, allowlisted paths, and these exact PFCL-to-ANPL mappings:

```yaml
autonomous-semantic-perception: "AutonomousViewpoint-DependentSemantic Perception.md"
collaborative-aerial-navigation: "Collaborative_Multi-Robot_Aerial_Autonomous_Navigation_and 3D_Reconstruction.md"
robust-risk-averse-decision-making: "RobustRiskAverseDecisonMaking.md"
```

Add `external` to `_config.yml`'s `exclude` list so CI source checkouts cannot enter the Jekyll artifact. Initialize `publications.json` and `projects.json` to `[]`; keep the existing `updates.json` empty.

- [ ] **Step 4: Implement the strict configuration interface**

Implement `PFCL::ExternalContent::Config.load(path)` in `scripts/external_content/config.rb`. Resolve no filesystem paths here; validate required scalar fields, validate that configured source paths are relative and contain no `..`, freeze the returned values, and make `Config#fetch` raise a descriptive error for an unknown source.

- [ ] **Step 5: Run the configuration tests**

Run: `docker compose run --rm site bundle exec ruby -Itest test/external_content/config_test.rb`

Expected: PASS with no warnings.

- [ ] **Step 6: Commit the foundation**

```bash
git add Gemfile Gemfile.lock _config.yml _data/external_sources.yml _data/generated/publications.json _data/generated/projects.json scripts/external_content/config.rb test/external_content/config_test.rb
git commit -m "feat(aggregation): define external source allowlist"
```

---

### Task 2: ANPL News and Student-Project Adapter

**Files:**
- Create: `scripts/external_content/front_matter_document.rb`
- Create: `scripts/external_content/plain_text.rb`
- Create: `scripts/external_content/anpl_adapter.rb`
- Create: `test/external_content/anpl_adapter_test.rb`
- Create: `test/fixtures/external/anpl/_data/tweets.json`
- Create: `test/fixtures/external/anpl/_student-projects/AutonomousViewpoint-DependentSemantic Perception.md`
- Create: `test/fixtures/external/anpl/_student-projects/Unsafe Project.md`

**Interfaces:**
- Consumes: `Source` from Task 1, a source root, and a resolved commit SHA.
- Produces: `FrontMatterDocument.read(path) -> Document` with `frontmatter`, `body`, and `source_path` readers.
- Produces: `PlainText.from_markdown(markdown, max_length:) -> String` with tags, images, and Markdown syntax removed at a word boundary.
- Produces: `AnplAdapter#updates -> Array<Hash<String, Object>>` and `AnplAdapter#projects -> Array<Hash<String, Object>>`.

- [ ] **Step 1: Write failing ANPL adapter tests**

Cover these exact outcomes:

- Tweet `2097017262284693848` maps to ID `anpl:x:2097017262284693848`, lab `anpl`, day precision, its X canonical URL, source account, an escaped/plain excerpt, and provenance.
- Expanded URLs are retained for later DOI/arXiv duplicate detection, while `t.co` tokens do not become the title.
- A project filename with spaces produces its encoded project-specific ANPL URL, absolute ANPL image URL, verified advisor/prerequisite/duration fields, and no `recruitment_status`, `project_type`, or `contact_email`.
- `<script>` and inline HTML in the unsafe fixture do not survive in the output title or summary.
- Invalid tweet JSON, invalid frontmatter, a missing projects directory, and an empty projects directory raise `SourceError` with the configured source path.

- [ ] **Step 2: Run the tests and confirm the missing adapter failure**

Run: `docker compose run --rm site bundle exec ruby -Itest test/external_content/anpl_adapter_test.rb`

Expected: FAIL because the adapter and parsing helpers do not exist.

- [ ] **Step 3: Implement safe frontmatter and plain-text parsing**

Implement `FrontMatterDocument.read` with `YAML.safe_load`, permitting `Date` only and disabling aliases. Implement `PlainText.from_markdown` so source Markdown/HTML becomes normalized text; never pass source HTML through to Liquid.

- [ ] **Step 4: Implement `AnplAdapter`**

Use only `source.paths["news"]` and `source.paths["projects"]`. Build tweet titles from the first non-empty sentence/line with a 120-character word-boundary limit and project summaries from successive prose blocks with a 280-character limit. Parse advisor, prerequisites, and duration only under their explicit source headings. Sort updates newest-first by timestamp and projects by source filename before returning them.

- [ ] **Step 5: Run the ANPL adapter tests**

Run: `docker compose run --rm site bundle exec ruby -Itest test/external_content/anpl_adapter_test.rb`

Expected: PASS; the unsafe fixture output contains no `<script>` or raw HTML.

- [ ] **Step 6: Commit the ANPL adapter**

```bash
git add scripts/external_content test/external_content/anpl_adapter_test.rb test/fixtures/external/anpl
git commit -m "feat(aggregation): normalize ANPL updates and projects"
```

---

### Task 3: ConNeCt News Adapter

**Files:**
- Create: `scripts/external_content/connect_adapter.rb`
- Create: `test/external_content/connect_adapter_test.rb`
- Create: `test/fixtures/external/connect/_news/news_8-09-26.md`
- Create: `test/fixtures/external/connect/_news/news_8-09-26_no2.md`
- Create: `test/fixtures/external/connect/_news/unsafe.md`

**Interfaces:**
- Consumes: `Source`, `FrontMatterDocument`, `PlainText`, a source root, and a resolved commit SHA.
- Produces: `ConnectAdapter#updates -> Array<Hash<String, Object>>` using the same update schema as Task 2.

- [ ] **Step 1: Write failing ConNeCt news tests**

Assert that `news_8-09-26_no2.md` maps to ID `connect:news:news_8-09-26_no2`, date `2026-09-08`, day precision, lab `connect`, source name `ConNeCt`, its frontmatter description as the escaped excerpt, canonical URL `https://connect-lab-technion.github.io/news/news_8-09-26_no2/`, and provenance. Assert deterministic newest-first ordering with filename as the tie-breaker. Assert that raw body content and unsafe HTML never appear in the update. Assert missing/empty `_news`, invalid frontmatter, missing title/description, and invalid dates fail with `SourceError`.

- [ ] **Step 2: Run the test and confirm the missing adapter failure**

Run: `docker compose run --rm site bundle exec ruby -Itest test/external_content/connect_adapter_test.rb`

Expected: FAIL because `ConnectAdapter` does not exist.

- [ ] **Step 3: Implement `ConnectAdapter`**

Read only `*.md` directly under the configured news directory. Use frontmatter `title`, `date`, and `description`; never render or copy the body. Construct the canonical URL from the source file stem and source-site base URL, and return records in deterministic order.

- [ ] **Step 4: Run the ConNeCt news tests**

Run: `docker compose run --rm site bundle exec ruby -Itest test/external_content/connect_adapter_test.rb`

Expected: PASS.

- [ ] **Step 5: Commit the ConNeCt adapter**

```bash
git add scripts/external_content/connect_adapter.rb test/external_content/connect_adapter_test.rb test/fixtures/external/connect/_news
git commit -m "feat(aggregation): normalize ConNeCt news"
```

---

### Task 4: Final-Publication Normalization and Deduplication

**Files:**
- Create: `scripts/external_content/publication_adapter.rb`
- Create: `scripts/external_content/publication_catalog.rb`
- Create: `test/external_content/publication_adapter_test.rb`
- Create: `test/external_content/publication_catalog_test.rb`
- Create: `test/fixtures/external/anpl/_bibliography/VadimIndelman.bib`
- Create: `test/fixtures/external/connect/_bibliography/DZ_Complete.bib`

**Interfaces:**
- Consumes: `Source`, source root, resolved revision, `as_of: Date`, and `warn_io: IO`.
- Produces: `PublicationAdapter#records -> Array<Hash<String, Object>>` with `id`, `title`, `authors`, `year`, optional `month`, `date_precision`, `type`, optional `venue`, optional `doi`, optional `arxiv_id`, `canonical_url`, `lab_ids`, `source_names`, and `provenance`.
- Produces: `PublicationCatalog.merge(record_sets) -> Array<Hash<String, Object>>`, deduplicated by DOI, then arXiv ID, then the fallback digest.

- [ ] **Step 1: Write failing publication-adapter tests**

Use fixtures that include a final DOI article, a final conference paper, a year-only final paper, completed theses, a future paper, `TechReport` arXiv preprints, and records marked accepted/in press/forthcoming. Assert:

- Only final, non-future `article`, `inproceedings`, `incollection`, `book`, `phdthesis`, and `mastersthesis` records survive.
- `month={09}`, `month={September}`, and `month={sep}` normalize to integer `9`; absent month yields `date_precision: "year"`.
- DOI links win over explicit external URLs, an arXiv URL is used only for an otherwise-final record, and the lab publications page is the final fallback.
- Output contains no `pdf` key, no `.pdf` URL, and no source-relative `/Publications/` URL.
- Unsupported types write a warning naming the source key and continue; malformed BibTeX fails the whole source file.

- [ ] **Step 2: Write failing catalog identity tests**

Assert that two different records sharing the duplicate source key `Barkai2026_ECC` both survive when their titles/identifiers differ. Assert that matching normalized DOI or arXiv identifiers across labs merge into one record containing both lab IDs, both source names, and both provenance entries. Assert stable title/year fallback IDs and deterministic newest-first ordering.

- [ ] **Step 3: Run both tests and confirm the missing implementation failures**

Run:

```bash
docker compose run --rm site bundle exec ruby -Itest test/external_content/publication_adapter_test.rb
docker compose run --rm site bundle exec ruby -Itest test/external_content/publication_catalog_test.rb
```

Expected: FAIL because the adapter and catalog do not exist.

- [ ] **Step 4: Implement `PublicationAdapter`**

Parse with `bibtex-ruby` without indexing by BibTeX key. Normalize LaTeX text, authors, types, month values, DOI/arXiv identifiers, venue, and dates. Reject future records relative to `as_of`; treat status-like fields and title/venue annotations matching `submitted`, `accepted`, `in press`, `forthcoming`, or `to appear` case-insensitively as non-final. Delete source PDF fields before constructing the output hash.

- [ ] **Step 5: Implement `PublicationCatalog.merge`**

Merge across sources by the identity priority in the spec. Preserve all lab attribution and provenance, sort array fields deterministically, and sort records by year descending, known month descending, normalized title, then ID.

- [ ] **Step 6: Run the publication tests**

Run:

```bash
docker compose run --rm site bundle exec ruby -Itest test/external_content/publication_adapter_test.rb
docker compose run --rm site bundle exec ruby -Itest test/external_content/publication_catalog_test.rb
```

Expected: PASS; warning assertions contain only the intentionally unsupported fixture entries.

- [ ] **Step 7: Commit publication normalization**

```bash
git add scripts/external_content/publication_adapter.rb scripts/external_content/publication_catalog.rb test/external_content test/fixtures/external/anpl/_bibliography test/fixtures/external/connect/_bibliography
git commit -m "feat(aggregation): normalize final publication metadata"
```

---

### Task 5: Recent-Publication Feed, Atomic Writer, and Sync CLI

**Files:**
- Create: `scripts/external_content/catalog.rb`
- Create: `scripts/external_content/json_writer.rb`
- Create: `scripts/external_content/runner.rb`
- Create: `scripts/sync_external_content.rb`
- Create: `test/external_content/catalog_test.rb`
- Create: `test/external_content/runner_test.rb`

**Interfaces:**
- Consumes: The adapters from Tasks 2-4 and `as_of: Date`.
- Produces: `Catalog#updates`, `Catalog#publications`, and `Catalog#projects`, each an ordered array ready for JSON serialization.
- Produces: `JsonWriter.write(path, value) -> nil`, using UTF-8, pretty JSON, stable hash-key ordering, trailing newline, and atomic replacement.
- Produces: `Runner.call(config_path:, source_roots:, output_dir:, as_of:, revisions: {}) -> Result`; `Result` exposes counts and warnings.
- Produces: CLI options `--config`, `--anpl-root`, `--connect-root`, `--output-dir`, `--as-of`, `--anpl-revision`, and `--connect-revision`.

- [ ] **Step 1: Write failing catalog tests for the News subset**

With `as_of: Date.new(2026, 10, 4)`, assert that eligible publication months are November 2025 through October 2026 inclusive, year-only records are excluded, theses are excluded, and only the five newest records per lab remain. Assert `date_precision: "month"`, display value `published_at: "2026-09"`, and internal sort key `date: "2026-09-01"`. Assert that a matching DOI or arXiv identifier in an ANPL tweet's expanded URLs suppresses the automatic publication update while preserving the tweet.

- [ ] **Step 2: Write failing runner and determinism tests**

Run the fixture pipeline twice into separate temporary output directories and assert byte-for-byte equality of all three JSON files. Assert every record carries repository, revision, and source path provenance. Assert a missing configured file, empty tweets array, empty news directory, empty BibTeX bibliography, or empty ANPL project directory raises `SourceError` and leaves pre-existing output files unchanged.

- [ ] **Step 3: Run both tests and confirm the missing implementation failures**

Run:

```bash
docker compose run --rm site bundle exec ruby -Itest test/external_content/catalog_test.rb
docker compose run --rm site bundle exec ruby -Itest test/external_content/runner_test.rb
```

Expected: FAIL because the catalog, writer, runner, and CLI do not exist.

- [ ] **Step 4: Implement `Catalog`**

Combine source news with recent-publication updates. Apply the exact 12-calendar-month rule, per-lab cap, and duplicate suppression from the tests. Keep publication updates attributed to their source labs; a cross-lab publication may list both lab IDs on `/publications/`, but create at most one update per contributing lab before the per-lab cap. Return all arrays in deterministic order.

- [ ] **Step 5: Implement atomic JSON output and orchestration**

Have `Runner.call` load config, verify each configured root/path, resolve each revision with `git rev-parse HEAD` unless explicitly supplied, run all adapters before writing anything, validate non-empty required source results, and then write `updates.json`, `publications.json`, and `projects.json`. `JsonWriter` must prepare all temporary files successfully before replacing any destination so a failed run preserves the prior catalog set.

- [ ] **Step 6: Implement the CLI**

Parse ISO `--as-of`, default it to the current UTC date, print source revisions and record counts on success, print actionable errors to stderr, and return nonzero on any source, schema, or write failure. Do not add network calls.

- [ ] **Step 7: Run catalog and runner tests**

Run:

```bash
docker compose run --rm site bundle exec ruby -Itest test/external_content/catalog_test.rb
docker compose run --rm site bundle exec ruby -Itest test/external_content/runner_test.rb
```

Expected: PASS, including byte-identical output and all fail-safe assertions.

- [ ] **Step 8: Commit the sync pipeline**

```bash
git add scripts/external_content scripts/sync_external_content.rb test/external_content
git commit -m "feat(aggregation): generate deterministic external catalogs"
```

---

### Task 6: Generated-Data and External-Handoff Validation

**Files:**
- Modify: `scripts/validate_content.rb`
- Modify: `test/content_validation_test.rb`

**Interfaces:**
- Consumes: The three generated schemas from Tasks 2-5 and native/external project frontmatter.
- Produces: `ContentValidator` errors for invalid generated attribution, URLs, precision, provenance, IDs, PDF leakage, and project schemas.

- [ ] **Step 1: Add failing generated-catalog validation tests**

Add isolated test documents for:

- Duplicate IDs within each generated file.
- Unknown lab IDs and missing source attribution/provenance.
- Non-HTTP canonical URLs.
- Day precision without `YYYY-MM-DD`, month precision without `YYYY-MM`, or disagreement between `published_at` and the sort-only `date`.
- Publication records containing a `pdf` key, `.pdf` canonical URL, or `/Publications/` source-relative link.
- Project records with `external != true`, inferred status/type/contact, or a non-ANPL lab ID.
- Valid empty generated arrays, which remain legal for a local checkout before sync.

- [ ] **Step 2: Add failing native/external project schema tests**

Keep the existing strict native-project requirements. Add the external branch requiring exactly `title`, `slug`, `lab_ids`, `external: true`, `canonical_url`, `source_name`, and `published`, plus optional `layout`; assert it rejects native recruitment/contact fields and accepts the three preserved slugs.

- [ ] **Step 3: Run the validator tests and confirm failures**

Run: `docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb`

Expected: FAIL on the newly added cases.

- [ ] **Step 4: Extend `ContentValidator`**

Split project validation into `validate_native_project` and `validate_external_project`. Add `validate_generated_updates`, `validate_generated_publications`, and `validate_generated_projects`, sharing helpers for unique IDs, known lab IDs, HTTP URLs, provenance objects, date precision, and forbidden PDF fields. Keep error messages prefixed with the exact file and array index.

- [ ] **Step 5: Run validator tests and the validator command**

Run:

```bash
docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb
docker compose run --rm site bundle exec ruby scripts/validate_content.rb
```

Expected: PASS with `Content validation passed.`

- [ ] **Step 6: Commit validation**

```bash
git add scripts/validate_content.rb test/content_validation_test.rb
git commit -m "test(aggregation): validate generated catalogs and handoffs"
```

---

### Task 7: Publications Page and Precision-Aware News Rendering

**Files:**
- Create: `publications.md`
- Modify: `_includes/news_feed.html`
- Modify: `_data/navigation.yml`
- Modify: `_data/footer.yml`
- Modify: `_sass/pfcl.scss`
- Modify: `test/footer_navigation_test.rb`
- Create: `test/publications_page_test.rb`
- Create: `test/news_feed_test.rb`

**Interfaces:**
- Consumes: `_data/generated/publications.json` and `_data/generated/updates.json`.
- Produces: `/publications/` grouped by descending year and external-attributed News date rendering.

- [ ] **Step 1: Write failing Publications and News template tests**

Assert that `publications.md` groups `site.data.generated.publications` by `year`, renders authors, venue, contributing labs, source attribution, canonical external links, and an empty state. Assert all dynamic external strings pass through Liquid `escape`. Assert `_includes/news_feed.html` uses `published_at` plus `date_precision` for display, shows `%B %Y` for month precision and `%B %-d, %Y` for day precision, while sorting on `date`.

- [ ] **Step 2: Add the navigation test expectation**

Extend the existing footer mirroring test so Publications must appear immediately after Research Groups in primary navigation and therefore in the footer's Explore group.

- [ ] **Step 3: Run the three tests and confirm failures**

Run:

```bash
docker compose run --rm site bundle exec ruby -Itest test/publications_page_test.rb
docker compose run --rm site bundle exec ruby -Itest test/news_feed_test.rb
docker compose run --rm site bundle exec ruby -Itest test/footer_navigation_test.rb
```

Expected: FAIL because the page and precision branch are absent and navigation lacks Publications.

- [ ] **Step 4: Implement `/publications/`**

Create a no-JavaScript Liquid page that groups records by year descending, prints authors and available venue metadata, resolves lab names through `site.labs`, identifies all contributing groups, and uses the canonical external URL. Do not add download buttons or PDF links.

- [ ] **Step 5: Update the news feed and mirrored navigation**

Render the source date according to precision without exposing the normalized sort day. Keep PFCL local news behavior unchanged. Add Publications immediately after Research Groups in `_data/navigation.yml` and `_data/footer.yml`.

- [ ] **Step 6: Add focused styles and run the tests**

Add only publication-list and source-label styles to `_sass/pfcl.scss`, retaining sharp corners and WCAG 2.2 AA contrast.

Run:

```bash
docker compose run --rm site bundle exec ruby -Itest test/publications_page_test.rb
docker compose run --rm site bundle exec ruby -Itest test/news_feed_test.rb
docker compose run --rm site bundle exec ruby -Itest test/footer_navigation_test.rb
```

Expected: PASS.

- [ ] **Step 7: Commit publications and news rendering**

```bash
git add publications.md _includes/news_feed.html _data/navigation.yml _data/footer.yml _sass/pfcl.scss test/publications_page_test.rb test/news_feed_test.rb test/footer_navigation_test.rb
git commit -m "feat(publications): render attributed external metadata"
```

---

### Task 8: ANPL External Cards and Stable PFCL Handoff Routes

**Files:**
- Modify: `projects.md`
- Modify: `index.md`
- Modify: `_includes/project_filters.html`
- Modify: `_includes/project_card.html`
- Modify: `assets/js/projects.js`
- Create: `_layouts/external_project.html`
- Modify: `_projects/autonomous-semantic-perception.md`
- Modify: `_projects/collaborative-aerial-navigation.md`
- Modify: `_projects/robust-risk-averse-decision-making.md`
- Modify: `_sass/pfcl.scss`
- Modify: `test/project_card_test.rb`
- Modify: `test/projects_page_test.rb`
- Modify: `test/homepage_test.rb`
- Create: `test/external_project_layout_test.rb`
- Create: `test/projects_filter_test.rb`

**Interfaces:**
- Consumes: Native `site.projects` plus `_data/generated/projects.json`.
- Produces: One project-card include with native and `external: true` branches.
- Produces: Preserved `/projects/<slug>/` handoff pages for the three prior placeholder records.

- [ ] **Step 1: Write failing external-card tests**

Assert the external branch:

- Uses `canonical_url` for image, title, and action links with `target="_blank"` and `rel="noopener noreferrer"`.
- Shows an `ANPL listing` source label and button text `View on ANPL`.
- Escapes imported title, summary, advisor, and tag strings.
- Omits status badge, `data-inquiry-btn`, and any fallback contact when those values are absent.
- Leaves the native card branch and inquiry button unchanged.

- [ ] **Step 2: Write failing directory/filter tests**

Assert `projects.md` excludes native handoff documents (`external: true`), concatenates generated projects once, passes the combined list to `project_filters.html`, and emits blank status/type data for external cards. In `assets/js/projects.js`, add a DOM-free exported predicate or equivalent test seam and assert an external ANPL card matches no filters and the ANPL lab filter, but not `available` or `research` filters. Assert the unfiltered HTML remains visible before JavaScript runs.

- [ ] **Step 3: Write failing handoff and homepage tests**

Assert all three source files preserve their exact slugs, use `layout: external_project`, set `external: true`, identify source `ANPL`, and carry their verified project-specific canonical URLs. Assert the layout supplies a canonical link and visible no-JavaScript fallback. Assert the homepage selects only native available projects and suppresses the selected-project block cleanly when none exist.

- [ ] **Step 4: Run project tests and confirm failures**

Run:

```bash
docker compose run --rm site bundle exec ruby -Itest test/project_card_test.rb
docker compose run --rm site bundle exec ruby -Itest test/projects_page_test.rb
docker compose run --rm site bundle exec ruby -Itest test/homepage_test.rb
docker compose run --rm site bundle exec ruby -Itest test/external_project_layout_test.rb
docker compose run --rm site bundle exec ruby -Itest test/projects_filter_test.rb
```

Expected: FAIL on the missing external branches and handoff layout.

- [ ] **Step 5: Merge native and generated project records**

In `projects.md`, select published native projects excluding `external: true`, concatenate generated projects, sort by explicit `order` with deterministic title fallback, and pass that array to both filters and cards. Change `_includes/project_filters.html` to derive active lab IDs from `include.projects`. Keep all cards visible in static HTML.

- [ ] **Step 6: Implement the external card and filter behavior**

Branch in `_includes/project_card.html` on `p.external`. Do not invent status/type/contact fields. Add the smallest testable filtering seam to `assets/js/projects.js` while preserving current progressive enhancement and inquiry modal behavior.

- [ ] **Step 7: Replace placeholder details with stable handoffs**

Convert the three `_projects` files to the strict external schema from Task 6 and remove the placeholder descriptions, inferred recruitment metadata, and local thumbnails. Create `_layouts/external_project.html` with source attribution, a direct ANPL button, canonical metadata, and readable fallback text/link. Use these verified canonical URLs:

```text
https://anpl-technion.github.io/student-projects/AutonomousViewpoint-DependentSemantic%20Perception/
https://anpl-technion.github.io/student-projects/Collaborative_Multi-Robot_Aerial_Autonomous_Navigation_and%203D_Reconstruction/
https://anpl-technion.github.io/student-projects/RobustRiskAverseDecisonMaking/
```

- [ ] **Step 8: Prevent an empty homepage project grid**

Filter the homepage selection to native, published, available projects. Wrap its heading, grid, modal, and script in the same non-empty condition so removing the placeholders does not leave an empty section or load unused inquiry behavior.

- [ ] **Step 9: Run project tests and validation**

Run:

```bash
docker compose run --rm site bundle exec ruby -Itest test/project_card_test.rb
docker compose run --rm site bundle exec ruby -Itest test/projects_page_test.rb
docker compose run --rm site bundle exec ruby -Itest test/homepage_test.rb
docker compose run --rm site bundle exec ruby -Itest test/external_project_layout_test.rb
docker compose run --rm site bundle exec ruby -Itest test/projects_filter_test.rb
docker compose run --rm site bundle exec ruby scripts/validate_content.rb
```

Expected: PASS; each stable route validates and the directory has no duplicate card for any mapped source project.

- [ ] **Step 10: Commit ANPL project integration**

```bash
git add projects.md index.md _includes/project_filters.html _includes/project_card.html assets/js/projects.js _layouts/external_project.html _projects _sass/pfcl.scss test/project_card_test.rb test/projects_page_test.rb test/homepage_test.rb test/external_project_layout_test.rb test/projects_filter_test.rb
git commit -m "feat(projects): link ANPL listings from stable PFCL routes"
```

---

### Task 9: Scheduled Pages Sync, Documentation, and End-to-End Verification

**Files:**
- Modify: `.github/workflows/pages.yml`
- Modify: `README.md`
- Create: `test/external_content/workflow_test.rb`

**Interfaces:**
- Consumes: The CLI from Task 5 and the existing Docker verification commands.
- Produces: A Pages workflow that checks out source data, syncs, validates, tests, builds, and deploys in that order.

- [ ] **Step 1: Write failing workflow contract tests**

Assert the workflow contains:

- `schedule` with `17 3 * * *`, plus existing push and manual triggers.
- Read-only shallow checkouts at `external/anpl` and `external/connect` with `persist-credentials: false`.
- Non-cone sparse paths matching `_data/external_sources.yml` exactly.
- A sync step before validation.
- The complete `test/**/*_test.rb` suite rather than only `content_validation_test.rb`.
- Deployment gated on the successful build job.

- [ ] **Step 2: Run the workflow test and confirm failure**

Run: `docker compose run --rm site bundle exec ruby -Itest test/external_content/workflow_test.rb`

Expected: FAIL because scheduling, source checkouts, and sync are absent.

- [ ] **Step 3: Update the Pages workflow**

Keep the PFCL checkout at the workspace root. Add separate `actions/checkout@v4` steps for `anpl-technion/anpl-technion.github.io` and `Connect-Lab-Technion/Connect-Lab-Technion.github.io`, `fetch-depth: 1`, `persist-credentials: false`, `sparse-checkout-cone-mode: false`, and only the configured paths. After dependencies are available, run:

```bash
docker compose run --rm site bundle exec ruby scripts/sync_external_content.rb --anpl-root external/anpl --connect-root external/connect --output-dir _data/generated
```

Then validate, run the complete Minitest suite, build, and deploy. Do not execute any checked-out source-repository script, plugin, or build.

- [ ] **Step 4: Update README operational documentation**

Document source ownership, metadata-only behavior, generated-file ownership, local fixture tests, the optional local sync command when source checkouts exist, the three generated schemas, and failure behavior. Note that scheduled GitHub workflows may be delayed or disabled after prolonged public-repository inactivity and can be run manually. Correct the existing project schema example so it matches the current `project_type`/`tags` validator.

- [ ] **Step 5: Run the workflow test**

Run: `docker compose run --rm site bundle exec ruby -Itest test/external_content/workflow_test.rb`

Expected: PASS.

- [ ] **Step 6: Run the fixture sync and prove repeatability**

Run the CLI twice with the test fixtures, explicit revisions, and `--as-of 2026-10-04`, writing to two temporary directories. Compare all three JSON files byte-for-byte.

Expected: All comparisons are identical, no output contains a `pdf` key or `.pdf` URL, and the command reports nonzero update/publication/project counts.

- [ ] **Step 7: Run all three project verification gates**

Run:

```bash
docker compose run --rm site bundle exec ruby scripts/validate_content.rb
docker compose run --rm site bundle exec ruby -Itest -e "Dir.glob('test/**/*_test.rb').sort.each { |file| require File.expand_path(file) }"
docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace
```

Expected: Validator prints `Content validation passed.`, all Minitest cases pass with zero failures/errors, and Jekyll exits 0.

- [ ] **Step 8: Inspect the production artifact**

Check `_site/news/index.html`, `_site/publications/index.html`, `_site/projects/index.html`, and the three `_site/projects/<preserved-slug>/index.html` files. Confirm attribution, canonical links, month-only publication dates, no raw source markup, no PDF links from imported metadata, no duplicate mapped projects, and usable links with JavaScript disabled.

- [ ] **Step 9: Commit workflow and documentation**

```bash
git add .github/workflows/pages.yml README.md test/external_content/workflow_test.rb
git commit -m "ci(aggregation): sync lab content before Pages deploy"
```
