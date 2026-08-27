# AGENTS.md

Instructions for AI Agents and Contributors working on the PFCL Website project.

## Core Rules & Boundaries

1. **Inspect Before Editing:** Always inspect existing schemas, layouts, and files before modifying or adding content.
2. **Umbrella Terminology:** Treat PFCL as the umbrella institution. The terms "research group" and "sub-lab" are equivalent.
3. **Obsidian Vault Boundary:** Never read from, link to, or copy files from the internal PFCL Obsidian vault into this repository. Public content is authored in this repo or imported via configured public adapters.
4. **Preserve Frontmatter Schemas:** Maintain strict YAML frontmatter types, lowercase alphanumeric slugs, and required metadata across `_labs/`, `_team/`, `_projects/`, and `_news/`.
5. **Attribution Integrity:** Never present a constituent lab's publication or news as PFCL-authored. Always provide canonical source links and source lab attribution.
6. **Generated Data Boundary:** `_data/generated/updates.json` is reserved for automated aggregation. Never hand-edit items after aggregation is enabled.
7. **Keep Changes Focused:** Avoid vendoring the upstream `bulma-clean-theme` gem. Keep overrides scoped to `_layouts/`, `_includes/`, and `_sass/`.
8. **Run Verification Before Completion:** Always run `bundle exec ruby scripts/validate_content.rb`, `bundle exec ruby -Itest test/content_validation_test.rb`, and `bundle exec jekyll build` before claiming completion.
9. **Accessibility & Progressive Enhancement:** Keep the website functional without JavaScript. Ensure WCAG 2.2 AA color contrast and respect `prefers-reduced-motion`.
10. **Domain Safety:** Do not alter DNS, GitHub Pages custom domain settings, or the live `pfcl.technion.ac.il` site without explicit authorization.
