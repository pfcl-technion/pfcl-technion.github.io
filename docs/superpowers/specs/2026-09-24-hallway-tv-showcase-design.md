# Design: PFCL Hallway TV Showcase Display (`/showcase/`)

## Problem Statement
The Philadelphia Flight Control Laboratory (PFCL) has a reserved route `/showcase/` intended for a dedicated digital signage / TV screen in the laboratory hallway. The display needs to run unattended on a 1080p/4K screen, continuously highlighting the lab's constituent research groups, available student projects, recent news announcements, and research publications. It should be legible from a distance of 3–5 meters and require zero human intervention once launched.

## User Decisions & Requirements
1. **Display Format:** Dedicated full-screen kiosk presentation without the standard website navbar or footer.
2. **Content Categories:**
   - **Research Group Spotlights:** Rotating overview of each constituent research group (`_labs` with `kind: research-group`).
   - **Available Student Projects:** Filtered from `_projects` with `recruitment_status: available` and `show_on_showcase: true`.
   - **News & Announcements:** Filtered from `_news` with `category: news` and `show_on_showcase: true`.
   - **Publications & Research Highlights:** Filtered from `_news` with `category ∈ {publication, research-highlight}` and `show_on_showcase: true`.
3. **Slide Timing & Rotation:**
   - 12 seconds per slide.
   - Smooth animated progress bar at the bottom.
   - Infinite loop rotation with pause on click/touch/spacebar.
   - Left and right keyboard navigation for guided tours.
4. **Header & Footer Framing:**
   - Top banner: PFCL logo, "Philadelphia Flight Control Laboratory", "Technion – Faculty of Aerospace Engineering", and a live digital clock with current date and time.
   - Bottom bar: Category pill, slide counter (e.g. `Slide 3 of 10`), progress bar, and a QR code pointing to the live website (`https://pfcl-technion.github.io/`).
5. **Autonomy & Resilience:**
   - 100% vanilla JavaScript (no external CDN dependencies like Alpine.js or jQuery).
   - Silent background reload every 30 minutes to pull freshly deployed projects and news without restarting the browser.

## Architecture & Implementation Details

### 1. Dedicated Layout (`_layouts/showcase.html`)
- Independent HTML5 document with dark/high-contrast styling optimized for digital screens.
- Omits theme header, navigation drawer, and theme footer.
- Embeds required CSS and `assets/js/showcase.js`.

### 2. Showcase Page (`showcase.md`)
- Route: `/showcase/` (`permalink: /showcase/`).
- Frontmatter:
  ```yaml
  ---
  layout: showcase
  title: "PFCL Showcase"
  permalink: /showcase/
  ---
  ```
- Page body compiles slides using Liquid loops:
  - Iterates `site.labs` where `kind == 'research-group'`.
  - Iterates `site.projects` where `recruitment_status == 'available'` and `show_on_showcase == true`.
  - Iterates `site.news` where `show_on_showcase == true` and separates news vs publication slides based on category.

### 3. Client Controller (`assets/js/showcase.js`)
- **Slide Engine:**
  - Manages active slide index using CSS opacity / transform transitions.
  - 12-second timer interval with a synchronized CSS `transition` / `requestAnimationFrame` progress bar.
- **Clock Engine:** Updates the live digital clock every second (`HH:MM:SS — Day, Month DD, YYYY`).
- **Interactive Controls:**
  - Arrow keys (`ArrowLeft`, `ArrowRight`) to manually navigate slides.
  - Spacebar or click to toggle Pause / Play with a visual indicator.
- **Auto-Refresh:** Periodically executes `window.location.reload()` every 30 minutes.

### 4. Styles (`_sass/showcase.scss` imported into `assets/css/app.scss`)
- Fixed full-screen container (`100vw`, `100vh`, `overflow: hidden`).
- Generous typography (min 18px body, 36px–48px titles, 24px subtitles) with WCAG AAA contrast ratio.
- Category accent badges:
  - Research Group: Cyan / Blue (`#0ea5e9`)
  - Available Project: Green (`#10b981`)
  - Lab News: Amber (`#f59e0b`)
  - Publication: Purple (`#8b5cf6`)
- High-contrast card containers with subtle glassmorphism or dark-slate elevated backgrounds.

## Verification Plan
1. **Automated Regression Suite (`test/showcase_test.rb`)**:
   - Verify `/showcase/` file exists and has `layout: showcase`.
   - Verify `_layouts/showcase.html` exists.
   - Verify Liquid queries correctly generate slides for labs, projects, and news.
2. **Content Validation**:
   - `docker compose run --rm site bundle exec ruby scripts/validate_content.rb`
   - `docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb`
   - `docker compose run --rm site bundle exec ruby -Itest test/homepage_test.rb`
   - `docker compose run --rm site bundle exec ruby -Itest test/showcase_test.rb`
3. **Production Build**:
   - `docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace`
