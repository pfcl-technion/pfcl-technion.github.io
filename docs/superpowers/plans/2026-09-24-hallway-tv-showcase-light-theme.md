# Hallway TV Showcase Light Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the `/showcase/` hallway TV digital signage display from a dark slate/rounded style into a 1:1 light theme adhering strictly to the PFCL website design guidelines (sharp corners, Technion Aerospace navy `#001b54` and cyan `#31bfe4` palette, crisp `#ffffff`/`#f8fafc` surfaces).

**Architecture:** Refactor `_sass/showcase.scss` to use the site's brand palette, sharp 0px corners, high-contrast light surfaces, and authoritative obsidian-navy top header. Align `showcase.md` and `_layouts/showcase.html` markup with the sharp-badge architecture. Update `test/showcase_test.rb` to enforce sharp corners and light theme constraints.

**Tech Stack:** Jekyll 4.3.4, Sass/SCSS, Vanilla JavaScript, HTML5, Minitest, Docker.

## Global Constraints

- Universal sharp-corner policy: `border-radius: 0 !important;` across all cards, badges, containers, progress bar, and images.
- Color palette: `#000e1f` top header, `#001b54` royal navy, `#31bfe4` sky cyan, `#f8fafc` canvas, `#ffffff` card surfaces, `#e2e8f0` borders.
- Dedicated standalone kiosk layout: do NOT render standard website navbar or footer.
- 100% vanilla JavaScript, zero external runtime CDNs.
- Full accessibility: WCAG AA contrast, reduced-motion media query, and no-JS fallback support.

---

### Task 1: Update Automated Regression Tests for Light Theme & Sharp Corners

**Files:**
- Modify: `test/showcase_test.rb`

**Interfaces:**
- Consumes: Minitest suite in `test/showcase_test.rb`
- Produces: Assertions requiring sharp corners and light theme styling in `_sass/showcase.scss`

- [ ] **Step 1: Write the failing test assertions**

Update `test/showcase_test.rb` to assert that:
1. `_sass/showcase.scss` does not contain rounded `border-radius` values (such as `16px`, `12px`, `8px`, `9999px`).
2. `_sass/showcase.scss` includes the light-theme canvas background `#f8fafc` and `#001b54` brand color.
3. The layout structure tests continue to pass.

```ruby
# frozen_string_literal: true

require "minitest/autorun"

class ShowcaseTest < Minitest::Test
  def setup
    @root = File.expand_path("..", __dir__)
    @page_path = File.join(@root, "showcase.md")
    @layout_path = File.join(@root, "_layouts", "showcase.html")
    @script_path = File.join(@root, "assets", "js", "showcase.js")
    @style_path = File.join(@root, "_sass", "showcase.scss")
  end

  def test_showcase_files_exist
    assert File.exist?(@page_path), "Expected showcase.md to exist"
    assert File.exist?(@layout_path), "Expected _layouts/showcase.html to exist"
    assert File.exist?(@script_path), "Expected assets/js/showcase.js to exist"
    assert File.exist?(@style_path), "Expected _sass/showcase.scss to exist"
  end

  def test_showcase_page_frontmatter
    skip unless File.exist?(@page_path)
    content = File.read(@page_path)
    assert_match(/^layout:\s*showcase/m, content, "showcase.md must use layout: showcase")
    assert_match(%r{^permalink:\s*/showcase/?}m, content, "showcase.md must have permalink: /showcase/")
  end

  def test_showcase_slide_categories_present
    skip unless File.exist?(@page_path)
    content = File.read(@page_path)
    assert_includes content, "site.labs", "showcase.md must iterate over site.labs"
    assert_includes content, "site.projects", "showcase.md must iterate over site.projects"
    assert_includes content, "site.news", "showcase.md must iterate over site.news"
    assert_includes content, "show_on_showcase", "showcase.md must filter items by show_on_showcase"
  end

  def test_showcase_layout_structure
    skip unless File.exist?(@layout_path)
    content = File.read(@layout_path)
    assert_includes content, "showcase-clock", "showcase layout must include a live clock element"
    assert_includes content, "showcase-progress", "showcase layout must include a progress bar"
    assert_includes content, "showcase.js", "showcase layout must include showcase.js script"
    refute_includes content, "{% include header.html %}", "showcase layout must NOT include standard site header"
    refute_includes content, "{% include footer.html %}", "showcase layout must NOT include standard site footer"
  end

  def test_showcase_light_theme_and_sharp_corners
    skip unless File.exist?(@style_path)
    content = File.read(@style_path)
    assert_includes content, "#f8fafc", "Showcase styles must use #f8fafc light canvas surface"
    assert_includes content, "#001b54", "Showcase styles must use #001b54 brand navy"
    assert_includes content, "border-radius: 0", "Showcase styles must enforce sharp corners"
    refute_match(/border-radius:\s*(16px|12px|8px|9999px)/, content, "Showcase styles must not use rounded corners")
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `docker compose run --rm site bundle exec ruby -Itest test/showcase_test.rb`  
Expected: FAIL on `test_showcase_light_theme_and_sharp_corners` because `showcase.scss` currently contains `border-radius: 16px;`.

- [ ] **Step 3: Commit test changes**

```bash
git add test/showcase_test.rb
git commit -m "test(showcase): add regression tests for light theme and sharp corners"
```

---

### Task 2: Implement Light Theme & Sharp Corners in Showcase Styles and Templates

**Files:**
- Modify: `_sass/showcase.scss`
- Modify: `showcase.md`
- Modify: `_layouts/showcase.html`

**Interfaces:**
- Consumes: Brand palette variables and styling from `_sass/pfcl.scss`
- Produces: Full light-theme kiosk presentation matching PFCL site guidelines

- [ ] **Step 1: Update `_sass/showcase.scss` with brand light theme and sharp corners**

Replace `_sass/showcase.scss` with:
```scss
// PFCL Hallway TV Showcase Display Styles (16:9 1080p/4K Optimized)
// Aligned with Faculty of Aerospace Engineering PFCL Brand Guidelines (Light Theme)

html.showcase-html,
body.showcase-body {
  background-color: #f8fafc !important;
  color: #2d3748;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  height: 100vh;
  margin: 0;
  overflow: hidden;
  padding: 0;
  width: 100vw;
}

.showcase-body {
  display: flex;
  flex-direction: column;
  height: 100vh;
  justify-content: space-between;
}

// Top Branding Bar (Obsidian Navy with Signature 3px Cyan Accent)
.showcase-header {
  align-items: center;
  background: #000e1f;
  border-bottom: 3px solid #31bfe4;
  box-shadow: 0 4px 12px rgba(0, 14, 31, 0.15);
  display: flex;
  flex: 0 0 auto;
  justify-content: space-between;
  padding: 1.15rem 3.5rem;
}

.showcase-brand {
  align-items: center;
  display: flex;
  gap: 1.5rem;
}

.showcase-logo {
  height: 52px;
  width: auto;
}

.showcase-main-title {
  color: #ffffff;
  font-size: 1.85rem;
  font-weight: 700;
  letter-spacing: -0.02em;
  margin: 0;
}

.showcase-sub-title {
  color: #cbd5e1;
  font-size: 1.05rem;
  font-weight: 500;
  margin: 0.2rem 0 0 0;
}

.showcase-clock-container {
  text-align: right;
}

.showcase-clock {
  color: #31bfe4;
  font-family: monospace;
  font-size: 1.9rem;
  font-weight: 700;
  letter-spacing: 0.05em;
}

.showcase-date {
  color: #cbd5e1;
  font-size: 0.95rem;
}

// Main Slide Area
.showcase-main {
  align-items: center;
  display: flex;
  flex: 1 1 auto;
  justify-content: center;
  overflow: hidden;
  padding: 2rem 4rem;
  position: relative;
}

.showcase-slider {
  height: 100%;
  position: relative;
  width: 100%;
}

.showcase-slide {
  display: flex;
  height: 100%;
  inset: 0;
  justify-content: center;
  opacity: 0;
  pointer-events: none;
  position: absolute;
  transition: opacity 0.8s ease-in-out, transform 0.8s ease-in-out;
  transform: scale(0.98);
  width: 100%;

  &.is-active {
    opacity: 1;
    pointer-events: auto;
    transform: scale(1);
    z-index: 10;
  }
}

html:not(.has-showcase-js) .showcase-slide:first-child {
  opacity: 1;
  pointer-events: auto;
  transform: scale(1);
}

// Showcase Card Design (Sharp Corners & Crisp White Surface)
.showcase-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 0 !important;
  border-top: 4px solid #001b54;
  box-shadow: 0 10px 30px rgba(0, 27, 84, 0.08);
  display: flex;
  flex-direction: column;
  height: 100%;
  max-width: 1400px;
  overflow: hidden;
  width: 100%;
}

.showcase-card-header {
  align-items: center;
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
  border-radius: 0 !important;
  display: flex;
  justify-content: space-between;
  padding: 1.25rem 2.5rem;
}

// Sharp Badges
.showcase-pill {
  border-radius: 0 !important;
  font-size: 0.85rem;
  font-weight: 800;
  letter-spacing: 0.06em;
  padding: 0.45rem 1.25rem;
  text-transform: uppercase;

  &.pill-cyan {
    background: #001b54;
    border-left: 4px solid #31bfe4;
    color: #ffffff;
  }
  &.pill-emerald {
    background: #001b54;
    border-left: 4px solid #10b981;
    color: #ffffff;
  }
  &.pill-amber {
    background: #001b54;
    border-left: 4px solid #f59e0b;
    color: #ffffff;
  }
  &.pill-purple {
    background: #002147;
    border-left: 4px solid #8b5cf6;
    color: #ffffff;
  }
}

.showcase-tag {
  color: #64748b;
  font-size: 1.05rem;
  font-weight: 600;
}

.showcase-card-body {
  display: flex;
  flex: 1;
  gap: 3rem;
  overflow: hidden;
  padding: 3rem;
}

.showcase-card-left {
  align-items: center;
  border-right: 1px solid #e2e8f0;
  display: flex;
  flex: 0 0 320px;
  flex-direction: column;
  justify-content: center;
  padding-right: 2.5rem;
  text-align: center;
}

.showcase-lab-logo {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 0 !important;
  margin-bottom: 2rem;
  max-height: 140px;
  max-width: 240px;
  object-fit: contain;
  padding: 1rem;
}

.showcase-leader-box {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-left: 3px solid #31bfe4;
  border-radius: 0 !important;
  padding: 1rem 1.5rem;
  width: 100%;
}

.showcase-meta-label {
  color: #64748b;
  display: block;
  font-size: 0.825rem;
  font-weight: 700;
  letter-spacing: 0.05em;
  margin-bottom: 0.25rem;
  text-transform: uppercase;
}

.showcase-leader-name {
  color: #001b54;
  font-size: 1.25rem;
  font-weight: 700;
  margin: 0;
}

.showcase-leader-email {
  color: #002147;
  font-size: 0.95rem;
  margin-top: 0.25rem;
}

.showcase-card-right,
.showcase-card-main {
  display: flex;
  flex: 1;
  flex-direction: column;
  justify-content: center;
}

.showcase-title {
  color: #001b54;
  font-size: 2.75rem;
  font-weight: 800;
  line-height: 1.2;
  margin: 0 0 1.5rem 0;
}

.showcase-advisors,
.showcase-news-meta {
  color: #334155;
  font-size: 1.35rem;
  margin-bottom: 1.5rem;

  strong {
    color: #001b54;
  }
}

.showcase-contact-email {
  color: #64748b;
  font-size: 1.1rem;
  margin-left: 1.5rem;
}

.showcase-summary {
  color: #334155;
  font-size: 1.65rem;
  line-height: 1.6;
  margin: 0 0 1.5rem 0;
}

.showcase-link-note {
  color: #002147;
  font-size: 1.1rem;
  font-weight: 600;
  margin: 0;
}

.showcase-badges {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin-top: 1rem;
}

.showcase-badge {
  background: #f1f5f9;
  border: 1px solid #cbd5e1;
  border-radius: 0 !important;
  color: #001b54;
  font-size: 0.95rem;
  font-weight: 600;
  padding: 0.35rem 0.85rem;
  text-transform: capitalize;
}

// Bottom Kiosk Bar
.showcase-footer {
  align-items: center;
  background: #ffffff;
  border-top: 1px solid #e2e8f0;
  box-shadow: 0 -4px 12px rgba(0, 0, 0, 0.03);
  display: flex;
  flex: 0 0 auto;
  gap: 2rem;
  justify-content: space-between;
  padding: 1rem 3.5rem;
}

.showcase-status-left {
  align-items: center;
  display: flex;
  flex: 0 0 auto;
  gap: 1.25rem;
}

.showcase-category-badge {
  background: #001b54;
  border-radius: 0 !important;
  color: #ffffff;
  font-size: 0.85rem;
  font-weight: 800;
  letter-spacing: 0.05em;
  padding: 0.4rem 1rem;
  text-transform: uppercase;
}

.showcase-counter {
  color: #64748b;
  font-size: 1rem;
  font-weight: 600;
}

.showcase-pause-badge {
  background: #fef3c7;
  border: 1px solid #fde68a;
  border-radius: 0 !important;
  color: #92400e;
  font-size: 0.8rem;
  font-weight: 800;
  letter-spacing: 0.05em;
  padding: 0.3rem 0.75rem;
}

.showcase-progress-wrapper {
  background: #e2e8f0;
  border-radius: 0 !important;
  flex: 1 1 auto;
  height: 6px;
  overflow: hidden;
  position: relative;
}

.showcase-progress-bar {
  background: #31bfe4;
  border-radius: 0 !important;
  height: 100%;
  transform-origin: left;
  width: 0%;
}

.showcase-status-right {
  flex: 0 0 auto;
}

.showcase-qr-box {
  align-items: center;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 0 !important;
  display: flex;
  gap: 0.85rem;
  padding: 0.4rem 0.85rem;
}

.showcase-qr-label {
  color: #64748b;
  font-size: 0.85rem;
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
}

.showcase-qr-img {
  border-radius: 0 !important;
  display: block;
  height: 48px;
  width: 48px;
}

// Accessibility: Reduced Motion
@media (prefers-reduced-motion: reduce) {
  .showcase-slide {
    transform: none !important;
    transition: opacity 0.2s ease-in-out !important;
  }
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `docker compose run --rm site bundle exec ruby -Itest test/showcase_test.rb`  
Expected: PASS with 5 runs, 30 assertions, 0 failures.

- [ ] **Step 3: Commit style changes**

```bash
git add _sass/showcase.scss
git commit -m "feat(showcase): align styling with light theme and sharp corner guidelines"
```

---

### Task 3: Full Verification & Visual Build Check

**Files:**
- Test all suites
- Check content validator
- Production Jekyll build

- [ ] **Step 1: Run complete test suite and validator**

Run:
```bash
docker compose run --rm site bundle exec ruby -Itest -e "Dir['test/*_test.rb'].each { |f| load f }"
docker compose run --rm site bundle exec ruby scripts/validate_content.rb
docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace
```
Expected: All 25+ runs pass with 0 failures, content validation passes, production build succeeds.

- [ ] **Step 2: Commit any remaining updates**

```bash
git status
```
Ensure working tree is clean.
