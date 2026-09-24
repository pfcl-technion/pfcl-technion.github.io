# AGENTS.md

Instructions for AI agents and contributors working on the PFCL website.

## Session Initialization & Context

To ensure proper context in any new agent session:
1. **Check references:** Review relevant documents in the `references/` folder to understand the original content, architecture, and historical context of the task.
   - The markdown files (`Home.md`, `Teaching Labs.md`, `Contact Us.md`, `Projects Archive.md`, `Research Groups Archive.md`) contain original text content for reference.
   - The directories prefixed with `backup_` are backups of the legacy WordPress website (`https://pfcl.technion.ac.il/`).
2. **Obsidian vault:** The internal PFCL Obsidian vault is strictly **read-only**. You may use its contents for reference to understand what we are doing, but never write to it or modify its files. Public site content is authored exclusively in this repository. For more information look at C:\Users\sarchi\OneDrive - Technion\PFCL\Obsidian Vaults\lab-agent-workspace

## Core rules and boundaries

1. **Inspect before editing.** Read existing schemas, layouts, and files before modifying or adding content.
2. **Umbrella terminology.** PFCL is the umbrella institution; "research group" and "sub-lab" are equivalent terms.
3. **Obsidian vault boundary.** Respect the read-only nature of the Obsidian vault. Do not link to its internal paths. Public content is authored in this repo or imported via configured public adapters.
4. **No fabricated content.** Only verified names, titles, and contact details. Everything unverified is a bracketed `[Placeholder: …]` marker. Never invent emails, phone numbers, dates, bios, quotes, or statistics.
5. **Preserve frontmatter schemas.** Maintain the strict YAML schemas of `_labs/`, `_team/`, `_projects/`, and `_news/` (see `scripts/validate_content.rb` for the enforced fields and enums).
6. **Stable identifiers.** Never rename slugs; references use identifiers, not display names.
7. **Attribution integrity.** Never present a constituent lab's publication or news as PFCL-authored. Imported items always carry `canonical_url` and `source_name`.
8. **Generated data boundary.** `_data/generated/updates.json` is reserved for the future aggregation deliverable; never hand-edit it once aggregation exists.
9. **No theme vendoring.** `bulma-clean-theme` stays a gem dependency; overrides live only in `_layouts/`, `_includes/`, and `_sass/`.
10. **Verify before claiming completion.** Run the validator, the test suite, and a production Jekyll build (commands in README) before declaring work done.
11. **Accessibility.** The site works without JavaScript; keep WCAG 2.2 AA contrast; respect `prefers-reduced-motion`.
12. **Domain safety.** Never change DNS, GitHub Pages custom-domain settings, organization settings, or anything touching the live `pfcl.technion.ac.il` site without explicit authorization.

## YAML gotcha

An unquoted colon+space inside a plain frontmatter scalar (for example `caption: slide — [Placeholder: text]`) makes the whole frontmatter unparseable — and Jekyll silently renders the page with **empty** frontmatter instead of failing the build. Quote any value containing `: `, `[`, or `{`.

## Page Mapping (New vs Original Website)

For historical reference and correct data migration, here is how the pages in the current website map to the legacy WordPress website paths:

| Current Website (Jekyll) | Original Website (Legacy WordPress) |
| --- | --- |
| Home (`/`) | Home (`/`) |
| About (`/about/`) | About Us -> A History (`/history/`) |
| About -> Team (`/team/`) | About Us -> Team (`/team/`) |
| About -> Media (`/media/`) | Media & Events -> Media (`/media-events/`) |
| About -> History (`/history/`) | About Us -> A History (`/history/`) |
| About -> PFCL Dedication (`/dedication/`) | About Us -> PFCL Dedication (`/pfcl-dedication/`) |
| Research Groups (`/labs/`) | Research Groups (`/research_groups/`) |
| Student Projects (`/projects/`) | Student Projects (`/projects/`) |
| Teaching Labs (`/teaching/`) | Teaching Labs (`/teaching-lab/`) |
| News (`/news/`) | Media & Events -> Events (`/events/`) |
| Contact (`/contact/`) | Contact Us (`/contact-us/`) |
