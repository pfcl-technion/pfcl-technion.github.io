# External Lab Content Aggregation Design

## Purpose

PFCL is the umbrella laboratory for several constituent research groups. The PFCL site should surface current public content from ANPL and ConNeCt without presenting that content as PFCL-authored, copying publication PDFs, or depending on browser-time network requests.

This design adds a build-time aggregation pipeline for lab news, publication metadata, and ANPL student-project listings. ConNeCt's legacy student projects remain outside the automated feed and can be migrated into PFCL separately.

## Goals

- Aggregate ANPL updates from its committed X/Twitter cache and ConNeCt updates from its `_news` collection.
- Build a combined metadata-only Publications page for final, already-published work.
- Add only recent final publications to News: the latest 12 calendar months, capped at five items per research group.
- Surface ANPL student projects as external cards that link to the original ANPL project pages.
- Replace the three current placeholder ANPL project records while preserving their PFCL slugs as stable handoff routes.
- Generate deterministic, validated JSON during the GitHub Pages build.
- Keep all rendered content usable without JavaScript.

## Non-goals

- Do not copy publication PDFs, source-site assets, full news articles, or full project pages.
- Do not call X/Twitter directly or store X credentials in PFCL.
- Do not import submitted, accepted, in-press, forthcoming, future-dated, or arXiv-only work.
- Do not infer missing project status, type, advisor, contact details, or other metadata.
- Do not write to the ANPL or ConNeCt repositories.
- Do not dynamically import ConNeCt student projects. Their existing entries are old and will be migrated or redirected separately.

## Architecture

GitHub Actions checks out PFCL plus sparse, read-only copies of the two source repositories. A Ruby command in PFCL reads only configured public data paths, normalizes them into three deterministic files under `_data/generated/`, validates the result, and then runs the ordinary Jekyll build. A source checkout or aggregation failure stops the new deployment, leaving the previously deployed site intact.

The generated files are:

- `_data/generated/updates.json`: ANPL social updates, ConNeCt news, and the eligible recent-publication subset.
- `_data/generated/publications.json`: deduplicated metadata for final publications.
- `_data/generated/projects.json`: ANPL project-card metadata and original-site links.

Once aggregation is implemented, these files are machine-owned and must not be hand-edited.

## Source configuration and provenance

`_data/external_sources.yml` is the single allowlist for repository names, source paths, site URLs, lab IDs, and the mapping from preserved PFCL project slugs to ANPL source files. The aggregator refuses unconfigured paths.

Every generated record includes provenance containing the repository name, checked-out commit SHA, and source path. Source repositories are treated as untrusted data: their code and plugins are never executed, imported text is rendered as escaped text, and external links use `rel="noopener noreferrer"`.

## News adapters

### ANPL

ANPL news comes only from `_data/tweets.json`, which is the source site's committed cache for posts by `@ANPL_Technion` and `@vadim_indelman`. PFCL never calls X.

Each record contains:

- Stable ID `anpl:x:<tweet-id>`.
- Lab ID `anpl`, category `news`, source name `ANPL`, and the source account.
- The exact source timestamp with day precision.
- A title derived from the first sentence or line, shortened at a word boundary.
- A plain-text excerpt and the canonical X/Twitter post URL.
- Repository, commit, and source-path provenance.

The adapter does not infer that a post is a publication merely because it mentions a paper. If a post links to the DOI or arXiv identifier of an automatically generated recent-publication item, the human-authored post wins and the automatic publication update is suppressed.

### ConNeCt

ConNeCt news comes from `_news/*.md`. The adapter reads YAML frontmatter but does not render or copy the Markdown body.

Each record contains:

- Stable ID `connect:news:<source-file-stem>`.
- Frontmatter title, date, and description as the excerpt.
- Lab ID `connect`, category `news`, source name `ConNeCt`, and day precision.
- The canonical original-site news URL and source provenance.

A missing required collection, invalid frontmatter, invalid date, or unexpectedly empty source collection fails aggregation.

## Publications

Publication metadata comes from ANPL's `_bibliography/VadimIndelman.bib` and ConNeCt's `_bibliography/DZ_Complete.bib`. A maintained BibTeX parser is used; BibTeX keys are retained only as provenance because source files can contain duplicate keys.

### Eligibility

The combined Publications page may include final `article`, `inproceedings`, `incollection`, `book`, `phdthesis`, and `mastersthesis` records whose publication month or year is not in the future. It excludes `techreport`, `unpublished`, `misc`, arXiv-only entries, and records marked submitted, accepted, in press, forthcoming, or to appear.

The News feed is narrower. A publication update must:

- Be a final journal, conference, book, or book-chapter record; theses are not News items.
- Supply at least year and month.
- Fall within the current month or preceding eleven calendar months.
- Rank among the five newest eligible publications for its lab.

Year-only publications remain on the Publications page but never enter News. Publication news displays month and year only; the normalized first day used for sorting is not shown as a claimed publication day. Future-dated and work-in-progress records are not labeled "upcoming" and are not imported.

### Identity and links

Record identity is resolved in this order:

1. Normalized DOI.
2. Normalized arXiv identifier.
3. A deterministic digest of source lab, normalized title, and year.

Matching DOI or arXiv records across labs become one publication with all contributing lab IDs and provenance records. Canonical link priority is DOI, an explicit external source URL, arXiv for an otherwise-final record, then the originating lab's publications page.

PDF fields are discarded before output. Generated metadata must never contain a local or remote PDF URL copied from a source BibTeX file.

## ANPL student projects

ANPL projects come from `_student-projects/*.md`. Generated cards contain only verifiable source data:

- Stable generated ID and slug.
- Title, plain-text summary, lab ID `anpl`, source name `ANPL`, and project-specific canonical URL.
- An absolute source image URL when frontmatter supplies an image; otherwise PFCL's default project image.
- Advisor, prerequisites, and duration only when explicitly present in the source document.
- Source provenance and `external: true`.

No recruitment status or PFCL project type is inferred. External cards remain visible in the unfiltered view and ANPL lab filter. Selecting a status or type naturally excludes cards without that metadata. External cards carry an "ANPL listing" label, link directly to ANPL, and do not offer PFCL's inquiry button.

The existing PFCL slugs remain reserved:

- `autonomous-semantic-perception`
- `collaborative-aerial-navigation`
- `robust-risk-averse-decision-making`

Their current placeholder details are replaced by minimal, strictly validated external-handoff documents. Those routes identify ANPL as the source, provide the canonical project link, and retain an accessible link when JavaScript is disabled. They do not appear as duplicate cards in the project directory.

## Rendering

- `/news/` and the homepage continue to merge PFCL-authored `_news` with generated updates. External attribution and canonical links are always shown.
- Date rendering respects `date_precision`: day-precise news shows a full date; month-precise publication updates show month and year.
- `/publications/` groups final metadata by year, displays author and venue metadata, identifies contributing research groups, and links to the canonical external record.
- `/projects/` merges native projects with generated ANPL project data. Existing JavaScript enhances filtering but is not required to see or follow any project.
- Publications is added immediately after Research Groups in both primary navigation and the mirrored footer navigation.

## Workflow and failure behavior

The Pages workflow runs on pushes to `main`, manual dispatch, and once daily away from the top of the hour. It uses shallow sparse checkouts for only the configured data paths, runs the aggregator, then runs the validator, complete test suite, and production Jekyll build.

Aggregation is deterministic for a fixed source revision and `as_of` date. It writes UTF-8 JSON with stable ordering and a trailing newline, using temporary files followed by atomic replacement.

Unsupported individual publication types are skipped with warnings. The build fails for missing configured collections, unreadable source data, invalid JSON/YAML/BibTeX, unexpectedly empty required inputs, duplicate generated IDs, schema violations, or non-deterministic output.

GitHub can disable scheduled workflows in inactive public repositories after 60 days and scheduled jobs can be delayed. Manual dispatch remains available; this operational limitation is documented in the README.

## Security note

The ANPL repository contains a file that appears to expose bearer credentials. PFCL must not read, copy, or use that file. Credential revocation, rotation, and history cleanup belong to the ANPL repository owners and are a separate remediation task.

## Verification and acceptance

Tests use small checked-in fixtures rather than the live source repositories. Coverage includes source parsing, missing metadata, unsafe markup, duplicate BibTeX keys, DOI/arXiv deduplication, publication eligibility, date precision, the 12-month window, per-lab cap, PDF-field removal, project slug preservation, deterministic output, and rendering behavior.

The work is accepted when:

1. No publication PDF is copied or linked from imported PDF fields.
2. PFCL makes no direct X API request and stores no X credential.
3. ANPL and ConNeCt news render with source attribution and canonical links.
4. Publications contains only final, non-future metadata and News contains only the eligible recent subset.
5. Month-only publication dates never display an invented day.
6. ANPL projects render as external cards without invented status or type metadata.
7. The three existing PFCL project slugs remain valid handoff routes and no duplicate cards appear.
8. Generated output is deterministic and carries provenance.
9. A failed sync prevents deployment without altering source repositories or the last deployed site.
10. The content validator, complete test suite, and production Jekyll build all pass.
