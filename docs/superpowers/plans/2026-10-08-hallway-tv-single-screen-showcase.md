# Hallway TV Single-Screen Showcase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the PFCL Hallway TV Showcase display into a single-screen presentation featuring a top-center emblem logo, bottom-center website QR code, left-content / right-image slide layout, and no progress bar.

**Architecture:** A unified Jekyll presentation page (`showcase.md` with layout `showcase.html`) rotating single slides every 12 seconds with vanilla JavaScript (`assets/js/showcase.js`) and high-contrast SCSS styles (`_sass/showcase.scss`). Left pane holds project and news text metadata, right pane holds a large framed content image. Top HUD centers the white PFCL emblem logo, and bottom HUD centers the website QR code.

**Tech Stack:** Jekyll, Liquid, Vanilla JavaScript, Sass (SCSS), Minitest (Ruby).

## Global Constraints
- Strictly 0px border-radius (`border-radius: 0 !important`).
- Montserrat font for headings and Inconsolata for monospace clock.
- Brand colors: `#001b54` brand navy, `#31bfe4` brand cyan, `#000814` dark canvas background.
- High contrast, WCAG 2.2 AA compliant.
- No progress bar anywhere in HTML, SCSS, or JS.
- Single unified slide list (`.showcase-slider > .showcase-slide`), no simultaneous split screen.

---

### Task 1: Update Test Suite for Single-Screen Showcase

**Files:**
- Modify: `test/showcase_test.rb`

**Interfaces:**
- Consumes: Test paths in `test/showcase_test.rb`.
- Produces: Updated assertions checking for `.showcase-slider > .showcase-slide`, top-center logo `PFCL-1_edited.png`, bottom-center QR `showcase_qr.png`, and absence of progress bar.

- [x] **Step 1: Write updated test assertions in `test/showcase_test.rb`**

Update `test/showcase_test.rb` to:
1. Replace `test_showcase_dual_split_structure` with `test_showcase_single_screen_structure` verifying `.showcase-slider`, `.showcase-slide`, `.showcase-slide-text`, and `.showcase-slide-visual`.
2. Update `test_showcase_layout_structure` to assert `PFCL-1_edited.png` and `showcase_qr.png`, and refute `showcase-progress` or `showcase-progress-bar`.
3. Update `test_showcase_styles_match_site_typography` to verify `#showcase-clock` and sharp borders.

- [x] **Step 2: Run test suite to verify tests fail (TDD red)**

Run: `docker compose run --rm site bundle exec ruby -e "Dir.glob('test/**/*_test.rb').each { |f| require_relative f }"`
Expected: FAIL on `test_showcase_single_screen_structure` and `test_showcase_layout_structure` because the layout and markup still have the dual-split structure.

- [x] **Step 3: Commit test updates**

```bash
git add test/showcase_test.rb
git commit -m "test(showcase): update assertions for single-screen showcase layout"
```

---

### Task 2: Update Top and Bottom HUD Layout in `_layouts/showcase.html`

**Files:**
- Modify: `_layouts/showcase.html`

**Interfaces:**
- Consumes: Site assets `/assets/images/PFCL-1_edited.png` and `/assets/images/showcase_qr.png`.
- Produces: 3-column top header (left titles, center emblem logo, right clock) and 3-column bottom footer (left counter/category, center website QR code, right pause status & hints).

- [x] **Step 1: Update `_layouts/showcase.html`**

Replace the header and footer in `_layouts/showcase.html`:
1. In `<header class="showcase-header">`:
   - Left: `.showcase-header-left` with lab title and faculty title.
   - Center: `.showcase-header-center` with `<img src="{{ '/assets/images/PFCL-1_edited.png' | relative_url }}" alt="PFCL Emblem" class="showcase-logo-center">`.
   - Right: `.showcase-header-right` with clock (`#showcase-clock`) and date (`#showcase-date`).
2. In `<footer class="showcase-footer">`:
   - Left: `.showcase-footer-left` with `#showcase-category`, `#showcase-counter`, `#showcase-pause-status`.
   - Center: `.showcase-footer-center` with `.showcase-qr-center`:
     - `<img src="{{ '/assets/images/showcase_qr.png' | relative_url }}" alt="Website QR Code" class="showcase-qr-img">`
     - `<span class="showcase-qr-label">Visit Website</span>`
   - Right: `.showcase-footer-right` with keyboard hints: `<span class="showcase-key-hint">Press [Space] to Pause</span>`.
   - Completely remove `#showcase-progress` and `.showcase-progress-wrapper`.

- [x] **Step 2: Commit layout changes**

```bash
git add _layouts/showcase.html
git commit -m "feat(showcase): center logo in top HUD and website QR in bottom HUD"
```

---

### Task 3: Redesign Slide Markup in `showcase.md`

**Files:**
- Modify: `showcase.md`

**Interfaces:**
- Consumes: `site.projects` (available status) and `site.news` (show_on_showcase) + generated data.
- Produces: Single unified sequence of `.showcase-slide` elements, each partitioned into `.showcase-slide-text` (left) and `.showcase-slide-visual` (right).

- [x] **Step 1: Update `showcase.md`**

In `showcase.md`:
1. Use single container `<div id="showcase-slider" class="showcase-slider">`.
2. Concatenate available student projects (native + generated) and news/publications (native + generated).
3. For each item:
   - `<article class="showcase-slide" data-category="..." data-accent="...">`
   - Left Pane: `<div class="showcase-slide-text">`:
     - Category pills (`AVAILABLE STUDENT PROJECT`, `RESEARCH PUBLICATION`, `LAB NEWS`).
     - Lab badge (`PFCL`, `ANPL`, `ConNeCt`).
     - Date / duration badge.
     - Title (`<h2 class="showcase-title">`).
     - Advisor strip (if project) or author/research group metadata (if news/pub).
     - Summary text (`<p class="showcase-summary">`).
     - Prerequisite badges / topic tags.
   - Right Pane: `<div class="showcase-slide-visual">`:
     - `<div class="showcase-visual-frame">`:
       - `<img src="{{ hero_img | escape }}" alt="{{ item.title | escape }}" class="showcase-visual-img" loading="lazy">`

- [x] **Step 2: Commit slide template changes**

```bash
git add showcase.md
git commit -m "feat(showcase): restructure slides into left-content and right-visual panes"
```

---

### Task 4: Update JavaScript Controller in `assets/js/showcase.js`

**Files:**
- Modify: `assets/js/showcase.js`

**Interfaces:**
- Consumes: `.showcase-slider > .showcase-slide`, `#showcase-counter`, `#showcase-category`, `#showcase-pause-status`, `#showcase-clock`.
- Produces: Single-slider controller cycling slides every 12 seconds without progress bar dependencies.

- [x] **Step 1: Update `assets/js/showcase.js`**

1. Query single slide array: `const slides = Array.from(document.querySelectorAll('.showcase-slider > .showcase-slide'));`.
2. Single index pointer `let currentIndex = 0;`.
3. `shuffleSlides()` shuffles the single `slides` array.
4. `showSlide()` sets `.is-active` on `slides[currentIndex]`, updates `#showcase-category` and `#showcase-counter` (`Slide X of N`).
5. `nextSlide()` and `prevSlide()` adjust `currentIndex`.
6. `tick()` measures `Date.now() - startTime >= DURATION_MS`, calling `nextSlide()` without updating `#showcase-progress`.
7. Remove obsolete per-slide SVG QR code rendering function since QR is now the static website QR in the bottom HUD.

- [x] **Step 2: Commit controller update**

```bash
git add assets/js/showcase.js
git commit -m "refactor(showcase): streamline controller for single-slide rotation without progress bar"
```

---

### Task 5: Redesign Styles in `_sass/showcase.scss`

**Files:**
- Modify: `_sass/showcase.scss`

**Interfaces:**
- Consumes: Design system tokens (#000814, #001b54, #31bfe4, Montserrat, Inconsolata).
- Produces: CSS rules for top header (left/center/right), bottom footer (left/center/right), and slide 52/48 split.

- [x] **Step 1: Update `_sass/showcase.scss`**

1. Header styles:
   - `.showcase-header`: `height: 88px; display: flex; justify-content: space-between; align-items: center; padding: 0 3rem;`.
   - `.showcase-header-left`: `flex: 1;`.
   - `.showcase-header-center`: `flex: 0 0 auto; display: flex; justify-content: center;`.
   - `.showcase-logo-center`: `height: 64px; width: auto;`.
   - `.showcase-header-right`: `flex: 1; text-align: right;`.
2. Main Canvas & Slides:
   - `.showcase-main`: fills height between top header (`top: 88px`) and bottom footer (`bottom: 96px`).
   - `.showcase-slide`: `position: absolute; inset: 0; display: flex; flex-direction: row; opacity: 0; transition: opacity 0.8s ease;`.
   - `.showcase-slide.is-active`: `opacity: 1; pointer-events: auto; z-index: 20;`.
   - `.showcase-slide-text`: `flex: 1 1 52%; padding: 2.5rem 3rem; display: flex; flex-direction: column; justify-content: center; overflow: hidden;`.
   - `.showcase-slide-visual`: `flex: 1 1 48%; padding: 2.5rem 3rem 2.5rem 1rem; display: flex; align-items: center; justify-content: center;`.
   - `.showcase-visual-frame`: `width: 100%; height: 100%; max-height: 720px; border: 2px solid rgba(49, 191, 228, 0.45); border-radius: 0 !important; overflow: hidden; background: #001b54; box-shadow: 0 12px 40px rgba(0,0,0,0.6);`.
   - `.showcase-visual-img`: `width: 100%; height: 100%; object-fit: cover; transition: transform 12s ease;`.
3. Footer styles:
   - `.showcase-footer`: `height: 96px; display: flex; justify-content: space-between; align-items: center; padding: 0 3rem; border-top: 1px solid rgba(255, 255, 255, 0.12);`.
   - `.showcase-footer-left`: `flex: 1; display: flex; align-items: center; gap: 1.25rem;`.
   - `.showcase-footer-center`: `flex: 0 0 auto; display: flex; align-items: center; gap: 0.85rem; background: #ffffff; border: 1px solid #31bfe4; padding: 0.35rem 1rem;`.
   - `.showcase-qr-img`: `height: 68px; width: 68px; display: block; border-radius: 0 !important;`.
   - `.showcase-footer-right`: `flex: 1; text-align: right; color: #94a3b8; font-size: 0.85rem;`.
   - Remove obsolete split column divider and progress bar styles.

- [x] **Step 2: Commit style changes**

```bash
git add _sass/showcase.scss
git commit -m "feat(showcase): style single-screen layout with top-center logo and bottom-center QR"
```

---

### Task 6: Full Verification, Browser Visual Inspection, and Push

**Files:**
- Test: `test/showcase_test.rb`
- Validate: `scripts/validate_content.rb`

**Interfaces:**
- Consumes: All modified files.
- Produces: Passing test suite, passing validator, passing production build, verified browser screenshots.

- [x] **Step 1: Run Content Schema Validator**
Run: `docker compose run --rm site bundle exec ruby scripts/validate_content.rb`
Expected: "Content validation passed."

- [x] **Step 2: Run Full Automated Test Suite**
Run: `docker compose run --rm site bundle exec ruby -e "Dir.glob('test/**/*_test.rb').each { |f| require_relative f }"`
Expected: 115+ runs, 0 failures, 0 errors.

- [x] **Step 3: Run Production Jekyll Build**
Run: `docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace`
Expected: Build completed with 0 errors.

- [x] **Step 4: Inspect Live Display in Browser**
Use `browser_subagent` to load `http://localhost:4000/showcase/`, capture screenshots of at least 2 distinct slides, and verify:
- Top center logo is prominent and crisp.
- Bottom center QR code is clean and visible.
- Left content has clear hierarchy and no clipping.
- Right image fills its frame with sharp borders.
- Progress bar is completely absent.

- [ ] **Step 5: Push commit to GitHub**
```bash
git push origin main
```
