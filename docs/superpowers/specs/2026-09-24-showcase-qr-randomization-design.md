# Hallway TV Showcase — Slide QR Codes, Randomized Ordering, and Font Alignment

Date: 2026-09-24
Status: approved (design decisions confirmed in session)

## Context

The hallway TV showcase (`/showcase/`) currently rotates 11 research-group
slides, 3 available student-project slides, and 0 news slides (only flagged
content appears). The rotation order is fixed (labs, then projects, then news).
The only QR code is a 48×48 px static PNG in the footer — too small to scan
from hallway viewing distance. The showcase also renders in the OS system font
stack while the website renders in Montserrat (loaded via the theme's
`@import`), so the display does not match the site's typography.

## Decisions (confirmed with the lab)

1. **Per-item QR codes live on the showcase slides**, not on website pages.
   Each project slide links to that project's page; each news/publication
   slide links to the item's `canonical_url`.
2. **All research-group slides are removed.** The showcase rotates only
   Student Project and News/Publication slides.
3. **Randomization = shuffled order** of all eligible slides on each page
   load (re-shuffled by the existing 30-minute auto-reload). Every eligible
   item still appears each cycle; nothing is hidden.

## Changes

### Subtitle (`_layouts/showcase.html`)

- Remove "— Technion" from the header subtitle, leaving
  "Stephen B. Klein Faculty of Aerospace Engineering".

### Slide pool (`showcase.md`)

- Delete the Research Groups category block (Category 1). Eligibility for
  projects (`recruitment_status: available` + `show_on_showcase: true`) and
  news (`show_on_showcase: true`) is unchanged.
- Each project slide's `<article>` carries `data-qr-url="{{ project.url | absolute_url }}"`.
- Each news/publication slide with a `canonical_url` carries `data-qr-url`
  resolved to an absolute URL (relative values pass through `absolute_url`;
  values already containing `://` are used as-is).
- Cards gain a right-side QR aside: a bordered white frame
  (`[data-qr-target]`) plus a caption ("Scan to view this project" /
  "Scan to read more"). News slides without `canonical_url` omit the aside.

### QR rendering (`assets/js/showcase.js`, vendored lib)

- Vendor `qrcode-generator` 1.4.4 (MIT, Kazuhiko Arase) to
  `assets/js/vendor/qrcode-generator-1.4.4.min.js` with a license header.
  Rationale: GitHub Pages permits no build-time QR plugins and an external
  QR-image API would add a third-party dependency to a kiosk.
- `showcase.js` renders each `[data-qr-url]` slide's QR into its
  `[data-qr-target]` as a scalable SVG (`qrcode(0, 'M')`, byte mode,
  error correction M). Failures degrade silently — the slide stays
  informative without the QR.
- Footer "Visit Website" QR keeps its static 200×200 PNG; CSS enlarges it
  from 48 px to 120 px (native resolution covers this — stays crisp).

### Randomization (`assets/js/showcase.js`)

- Fisher–Yates shuffle of the slide array at startup, before the first
  `showSlide(0)`. DOM order and the no-JS first-slide fallback are
  unaffected; only rotation order changes.

### Fonts (`_sass/showcase.scss`)

- Body font-family changes from the system stack to `"Montserrat", sans-serif`
  to match the website (Montserrat already loads via `app.css`).
- The clock uses the site's monospace stack
  (`"Inconsolata", "Hack", "SF Mono", "Roboto Mono", "Source Code Pro",
  "Ubuntu Mono", monospace`) instead of bare `monospace`.

### Dead styles (`_sass/showcase.scss`)

- Remove lab-only rules: `.showcase-card-lab`, `.showcase-card-left`,
  `.showcase-card-right` (kept only via shared `.showcase-card-main` rule),
  `.showcase-lab-logo`, `.showcase-leader-box`, `.showcase-leader-name`,
  `.showcase-leader-email`, `pill-cyan`.

## Testing

Update `test/showcase_test.rb` (file-content regression tests, matching the
suite's existing idiom):

- Subtitle no longer contains "— Technion".
- `showcase.md` no longer iterates `site.labs`; still iterates
  `site.projects`/`site.news` with `show_on_showcase`.
- `showcase.md` contains `data-qr-url`; vendor lib file exists;
  `showcase.js` references `data-qr-url` and `createSvgTag` and contains the
  shuffle routine; `showcase.scss` declares Montserrat.
- Existing light-theme/sharp-corner assertions remain valid (colors and
  radii untouched).

Manual verification: content validator, full test suite, production build,
plus a headless-browser DOM dump of `/showcase/` proving the QR SVGs render,
and a screenshot for layout sanity.
