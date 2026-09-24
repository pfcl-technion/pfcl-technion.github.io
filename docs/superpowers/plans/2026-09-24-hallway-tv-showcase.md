# PFCL Hallway TV Showcase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a dedicated, full-screen digital signage display at `/showcase/` for laboratory hallway TVs, auto-rotating through research groups, available student projects, lab news, and publications every 12 seconds with zero external runtime dependencies.

**Architecture:** A standalone Jekyll layout (`_layouts/showcase.html`) that omits the standard navbar/footer and renders a kiosk frame with top branding, live clock, bottom progress bar, and QR code. Liquid iterates existing Jekyll collections to generate static slide cards. A lightweight vanilla JavaScript controller (`assets/js/showcase.js`) handles 12-second transitions, keyboard navigation, pause/play, and automatic 30-minute background reload. Dedicated styling lives in `_sass/showcase.scss`.

**Tech Stack:** Jekyll 4, Liquid, HTML5, CSS3 Grid/Flexbox, Vanilla JavaScript, Ruby Minitest, Docker Compose.

## Global Constraints

- Never fabricate content or contact information.
- Strictly preserve YAML frontmatter formatting and collection schemas.
- Dedicated standalone layout: must NOT render the website navbar or website footer on `/showcase/`.
- 100% vanilla JavaScript for kiosk controls (no CDN libraries required).
- Verify using validator, test suites, and production Jekyll build.

---

### Task 1: Add Automated Regression Test for Showcase

**Files:**
- Create: `test/showcase_test.rb`

**Interfaces:**
- Consumes: `showcase.md`, `_layouts/showcase.html`, `assets/js/showcase.js`, `_sass/showcase.scss`.
- Produces: Minitest test assertions verifying that the showcase page, layout, scripts, slide loops, and filters exist and compile properly.

- [ ] **Step 1: Write the failing test**

Create `test/showcase_test.rb`:

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
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `docker compose run --rm site bundle exec ruby -Itest test/showcase_test.rb`
Expected output: FAIL (Expected showcase.md to exist).

- [ ] **Step 3: Commit the test**

```bash
git add test/showcase_test.rb
git commit -m "test: add regression test suite for hallway TV showcase display"
```

---

### Task 2: Create Showcase Layout and Page

**Files:**
- Create: `_layouts/showcase.html`
- Create: `showcase.md`

**Interfaces:**
- Consumes: Collections `site.labs`, `site.projects`, `site.news`.
- Produces: HTML structure rendering top branding bar, live clock container, static slide cards with category tags, bottom progress bar, and QR code.

- [ ] **Step 1: Create `_layouts/showcase.html`**

Create `_layouts/showcase.html`:

```html
<!doctype html>
<html lang="en" class="showcase-html">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{ page.title | default: site.title }} — Showcase</title>
  <link rel="stylesheet" href="{{ '/assets/css/app.css' | relative_url }}">
  <link rel="shortcut icon" type="image/png" href="{{ site.favicon | relative_url }}">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.6.0/css/all.min.css" crossorigin="anonymous">
</head>
<body class="showcase-body">
  <header class="showcase-header">
    <div class="showcase-brand">
      <img src="{{ '/assets/images/pfcl_logo_white.png' | relative_url }}" alt="PFCL Emblem" class="showcase-logo">
      <div class="showcase-titles">
        <h1 class="showcase-main-title">Philadelphia Flight Control Laboratory</h1>
        <p class="showcase-sub-title">Stephen B. Klein Faculty of Aerospace Engineering — Technion</p>
      </div>
    </div>
    <div class="showcase-clock-container">
      <div id="showcase-clock" class="showcase-clock">--:--:--</div>
      <div id="showcase-date" class="showcase-date">Loading...</div>
    </div>
  </header>

  <main class="showcase-main">
    {{ content }}
  </main>

  <footer class="showcase-footer">
    <div class="showcase-status-left">
      <span id="showcase-category" class="showcase-category-badge">OVERVIEW</span>
      <span id="showcase-counter" class="showcase-counter">Slide 1 of --</span>
      <span id="showcase-pause-status" class="showcase-pause-badge" style="display:none;"><i class="fa-solid fa-pause"></i> PAUSED</span>
    </div>

    <div class="showcase-progress-wrapper">
      <div id="showcase-progress" class="showcase-progress-bar"></div>
    </div>

    <div class="showcase-status-right">
      <div class="showcase-qr-box">
        <span class="showcase-qr-label">Visit Website</span>
        <img src="https://api.qrserver.com/v1/create-qr-code/?size=70x70&data=https%3A%2F%2Fpfcl-technion.github.io%2F" alt="QR Code" class="showcase-qr-img">
      </div>
    </div>
  </footer>

  <script src="{{ '/assets/js/showcase.js' | relative_url }}"></script>
</body>
</html>
```

- [ ] **Step 2: Create `showcase.md`**

Create `showcase.md` rendering all 4 slide types:

```markdown
---
layout: showcase
title: PFCL Laboratory Showcase
permalink: /showcase/
---

<div id="showcase-slider" class="showcase-slider">

  {% comment %} --- Category 1: Research Groups --- {% endcomment %}
  {% assign labs = site.labs | where: "kind", "research-group" | sort: "order" %}
  {% for lab in labs %}
  <article class="showcase-slide" data-category="RESEARCH GROUP" data-accent="cyan">
    <div class="showcase-card showcase-card-lab">
      <div class="showcase-card-header">
        <span class="showcase-pill pill-cyan">RESEARCH GROUP</span>
        {% if lab.short_name %}<span class="showcase-tag">{{ lab.short_name }}</span>{% endif %}
      </div>
      <div class="showcase-card-body">
        <div class="showcase-card-left">
          {% if lab.logo %}
            <img src="{{ lab.logo | relative_url }}" alt="{{ lab.title }}" class="showcase-lab-logo">
          {% endif %}
          <div class="showcase-leader-box">
            <span class="showcase-meta-label">Group Leader</span>
            <p class="showcase-leader-name">{{ lab.leader_names | join: ', ' }}</p>
            {% if lab.leader_email %}
              <p class="showcase-leader-email"><i class="fa-solid fa-envelope"></i> {{ lab.leader_email }}</p>
            {% endif %}
          </div>
        </div>
        <div class="showcase-card-right">
          <h2 class="showcase-title">{{ lab.title }}</h2>
          <p class="showcase-summary">{{ lab.summary }}</p>
          {% if lab.website %}
            <p class="showcase-link-note"><i class="fa-solid fa-globe"></i> {{ lab.website }}</p>
          {% endif %}
        </div>
      </div>
    </div>
  </article>
  {% endfor %}

  {% comment %} --- Category 2: Available Student Projects --- {% endcomment %}
  {% assign showcase_projects = site.projects | where: "recruitment_status", "available" | where: "show_on_showcase", true | sort: "order" %}
  {% for project in showcase_projects %}
  <article class="showcase-slide" data-category="STUDENT PROJECT" data-accent="emerald">
    <div class="showcase-card showcase-card-project">
      <div class="showcase-card-header">
        <span class="showcase-pill pill-emerald">AVAILABLE STUDENT PROJECT</span>
        {% if project.student_levels %}
          <span class="showcase-tag">{{ project.student_levels | join: ', ' | upcase }}</span>
        {% endif %}
      </div>
      <div class="showcase-card-body">
        <div class="showcase-card-main">
          <h2 class="showcase-title">{{ project.title }}</h2>
          <div class="showcase-advisors">
            <span class="showcase-meta-label">Advisor:</span>
            <strong>{{ project.advisor_names | join: ', ' }}</strong>
            {% if project.contact_email %}
              <span class="showcase-contact-email"><i class="fa-solid fa-envelope"></i> {{ project.contact_email }}</span>
            {% endif %}
          </div>
          <p class="showcase-summary">{{ project.summary }}</p>
          {% if project.project_types %}
            <div class="showcase-badges">
              {% for ptype in project.project_types %}
                <span class="showcase-badge">{{ ptype }}</span>
              {% endfor %}
            </div>
          {% endif %}
        </div>
      </div>
    </div>
  </article>
  {% endfor %}

  {% comment %} --- Category 3 & 4: News & Publications --- {% endcomment %}
  {% assign showcase_news = site.news | where: "show_on_showcase", true | sort: "date" | reverse %}
  {% for item in showcase_news %}
    {% assign is_pub = false %}
    {% if item.category == 'publication' or item.category == 'research-highlight' %}
      {% assign is_pub = true %}
    {% endif %}

    <article class="showcase-slide" data-category="{% if is_pub %}RESEARCH PUBLICATION{% else %}LAB NEWS{% endif %}" data-accent="{% if is_pub %}purple{% else %}amber{% endif %}">
      <div class="showcase-card {% if is_pub %}showcase-card-pub{% else %}showcase-card-news{% endif %}">
        <div class="showcase-card-header">
          <span class="showcase-pill {% if is_pub %}pill-purple{% else %}pill-amber{% endif %}">
            {% if is_pub %}RESEARCH PUBLICATION{% else %}LAB NEWS &amp; ANNOUNCEMENT{% endif %}
          </span>
          <span class="showcase-tag">{{ item.date | date: "%B %-d, %Y" }}</span>
        </div>
        <div class="showcase-card-body">
          <div class="showcase-card-main">
            <h2 class="showcase-title">{{ item.title }}</h2>
            <div class="showcase-news-meta">
              <span class="showcase-meta-label">Source:</span>
              <strong>{{ item.source_name | default: 'PFCL' }}</strong>
            </div>
            <p class="showcase-summary">{{ item.excerpt }}</p>
            {% if item.canonical_url %}
              <p class="showcase-link-note"><i class="fa-solid fa-arrow-up-right-from-square"></i> Read online</p>
            {% endif %}
          </div>
        </div>
      </div>
    </article>
  {% endfor %}

</div>
```

- [ ] **Step 3: Verify tests progress**

Run: `docker compose run --rm site bundle exec ruby -Itest test/showcase_test.rb`
Expected output: Fails on missing script/style files, passes on layout and page tests.

---

### Task 3: Implement Showcase Styling and Client Controller

**Files:**
- Create: `_sass/showcase.scss`
- Modify: `assets/css/app.scss`
- Create: `assets/js/showcase.js`

**Interfaces:**
- Consumes: DOM elements `#showcase-slider`, `.showcase-slide`, `#showcase-clock`, `#showcase-progress`, `#showcase-counter`, `#showcase-category`.
- Produces: Functional 12s slide engine with smooth CSS transitions, live clock updates, keyboard control, and auto-reload.

- [ ] **Step 1: Create `_sass/showcase.scss`**

Create `_sass/showcase.scss`:

```scss
// PFCL Hallway TV Showcase Display Styles (16:9 1080p/4K Optimized)

html.showcase-html,
body.showcase-body {
  background-color: #0b1120 !important;
  color: #f1f5f9;
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

// Top Branding Bar
.showcase-header {
  align-items: center;
  background: rgba(15, 23, 42, 0.95);
  border-bottom: 2px solid #1e293b;
  display: flex;
  flex: 0 0 auto;
  justify-content: space-between;
  padding: 1.25rem 3rem;
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
  color: #94a3b8;
  font-size: 1.05rem;
  font-weight: 500;
  margin: 0.2rem 0 0 0;
}

.showcase-clock-container {
  text-align: right;
}

.showcase-clock {
  color: #38bdf8;
  font-family: monospace;
  font-size: 1.9rem;
  font-weight: 700;
}

.showcase-date {
  color: #94a3b8;
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

// Showcase Card Design
.showcase-card {
  background: #1e293b;
  border: 1px solid #334155;
  border-radius: 16px;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
  display: flex;
  flex-direction: column;
  height: 100%;
  max-width: 1400px;
  overflow: hidden;
  width: 100%;
}

.showcase-card-header {
  align-items: center;
  background: #0f172a;
  border-bottom: 1px solid #334155;
  display: flex;
  justify-content: space-between;
  padding: 1.25rem 2.5rem;
}

.showcase-pill {
  border-radius: 9999px;
  font-size: 0.9rem;
  font-weight: 800;
  letter-spacing: 0.05em;
  padding: 0.4rem 1.25rem;
  text-transform: uppercase;

  &.pill-cyan { background: #0284c7; color: #ffffff; }
  &.pill-emerald { background: #059669; color: #ffffff; }
  &.pill-amber { background: #d97706; color: #ffffff; }
  &.pill-purple { background: #7c3aed; color: #ffffff; }
}

.showcase-tag {
  color: #94a3b8;
  font-size: 1.1rem;
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
  border-right: 1px solid #334155;
  display: flex;
  flex: 0 0 320px;
  flex-direction: column;
  justify-content: center;
  padding-right: 2.5rem;
  text-align: center;
}

.showcase-lab-logo {
  background: #ffffff;
  border-radius: 12px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  margin-bottom: 2rem;
  max-height: 140px;
  max-width: 240px;
  object-fit: contain;
  padding: 1rem;
}

.showcase-leader-box {
  background: #0f172a;
  border-radius: 8px;
  padding: 1rem 1.5rem;
  width: 100%;
}

.showcase-meta-label {
  color: #64748b;
  display: block;
  font-size: 0.85rem;
  font-weight: 700;
  letter-spacing: 0.05em;
  margin-bottom: 0.25rem;
  text-transform: uppercase;
}

.showcase-leader-name {
  color: #ffffff;
  font-size: 1.25rem;
  font-weight: 700;
  margin: 0;
}

.showcase-leader-email {
  color: #38bdf8;
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
  color: #ffffff;
  font-size: 2.75rem;
  font-weight: 800;
  line-height: 1.2;
  margin: 0 0 1.5rem 0;
}

.showcase-advisors,
.showcase-news-meta {
  color: #cbd5e1;
  font-size: 1.35rem;
  margin-bottom: 1.5rem;

  strong {
    color: #38bdf8;
  }
}

.showcase-contact-email {
  color: #94a3b8;
  font-size: 1.1rem;
  margin-left: 1.5rem;
}

.showcase-summary {
  color: #cbd5e1;
  font-size: 1.45rem;
  line-height: 1.6;
  margin: 0 0 2rem 0;
}

.showcase-badges {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
}

.showcase-badge {
  background: #334155;
  border-radius: 6px;
  color: #f1f5f9;
  font-size: 1rem;
  font-weight: 600;
  padding: 0.4rem 1rem;
  text-transform: capitalize;
}

.showcase-link-note {
  color: #38bdf8;
  font-size: 1.15rem;
  font-weight: 600;
  margin-top: 1rem;
}

// Bottom Footer & Progress Bar
.showcase-footer {
  align-items: center;
  background: rgba(15, 23, 42, 0.95);
  border-top: 2px solid #1e293b;
  display: flex;
  flex: 0 0 auto;
  gap: 2rem;
  justify-content: space-between;
  padding: 1rem 3rem;
}

.showcase-status-left {
  align-items: center;
  display: flex;
  flex: 0 0 350px;
  gap: 1.25rem;
}

.showcase-category-badge {
  background: #334155;
  border-radius: 6px;
  color: #f8fafc;
  font-size: 0.85rem;
  font-weight: 700;
  letter-spacing: 0.05em;
  padding: 0.35rem 0.75rem;
}

.showcase-counter {
  color: #94a3b8;
  font-size: 1.1rem;
  font-weight: 600;
}

.showcase-pause-badge {
  background: #dc2626;
  border-radius: 4px;
  color: #ffffff;
  font-size: 0.75rem;
  font-weight: 800;
  padding: 0.2rem 0.5rem;
}

.showcase-progress-wrapper {
  background: #334155;
  border-radius: 9999px;
  flex: 1;
  height: 8px;
  overflow: hidden;
  position: relative;
}

.showcase-progress-bar {
  background: linear-gradient(90deg, #0284c7, #38bdf8);
  height: 100%;
  transition: width 0.1s linear;
  width: 0%;
}

.showcase-status-right {
  align-items: center;
  display: flex;
  flex: 0 0 220px;
  justify-content: flex-end;
}

.showcase-qr-box {
  align-items: center;
  display: flex;
  gap: 0.75rem;
}

.showcase-qr-label {
  color: #94a3b8;
  font-size: 0.85rem;
  font-weight: 600;
  text-align: right;
}

.showcase-qr-img {
  background: #ffffff;
  border-radius: 6px;
  height: 52px;
  padding: 3px;
  width: 52px;
}
```

- [ ] **Step 2: Import `showcase.scss` in `assets/css/app.scss`**

Add `@import "showcase";` to `assets/css/app.scss`.

- [ ] **Step 3: Create `assets/js/showcase.js`**

Create `assets/js/showcase.js`:

```javascript
// PFCL Hallway TV Showcase Controller
(function() {
  'use strict';

  const DURATION_MS = 12000; // 12 seconds per slide
  const RELOAD_INTERVAL_MS = 30 * 60 * 1000; // 30 minutes silent refresh

  const slides = Array.from(document.querySelectorAll('.showcase-slide'));
  const progressBar = document.getElementById('showcase-progress');
  const counterEl = document.getElementById('showcase-counter');
  const categoryBadge = document.getElementById('showcase-category');
  const pauseBadge = document.getElementById('showcase-pause-status');
  const clockEl = document.getElementById('showcase-clock');
  const dateEl = document.getElementById('showcase-date');

  let currentIndex = 0;
  let isPaused = false;
  let startTime = Date.now();
  let animationFrameId = null;

  if (slides.length === 0) return;

  function updateClock() {
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    if (clockEl) clockEl.textContent = `${hours}:${minutes}:${seconds}`;

    if (dateEl) {
      const options = { weekday: 'long', year: 'numeric', month: 'short', day: 'numeric' };
      dateEl.textContent = now.toLocaleDateString('en-US', options);
    }
  }

  function showSlide(index) {
    slides.forEach((slide, i) => {
      slide.classList.toggle('is-active', i === index);
    });

    const activeSlide = slides[index];
    const category = activeSlide.dataset.category || 'SHOWCASE';

    if (categoryBadge) categoryBadge.textContent = category;
    if (counterEl) counterEl.textContent = `Slide ${index + 1} of ${slides.length}`;

    startTime = Date.now();
    if (progressBar) progressBar.style.width = '0%';
  }

  function nextSlide() {
    currentIndex = (currentIndex + 1) % slides.length;
    showSlide(currentIndex);
  }

  function prevSlide() {
    currentIndex = (currentIndex - 1 + slides.length) % slides.length;
    showSlide(currentIndex);
  }

  function togglePause() {
    isPaused = !isPaused;
    if (pauseBadge) pauseBadge.style.display = isPaused ? 'inline-block' : 'none';
    if (!isPaused) {
      startTime = Date.now();
      tick();
    }
  }

  function tick() {
    if (isPaused) return;

    const elapsed = Date.now() - startTime;
    const progress = Math.min((elapsed / DURATION_MS) * 100, 100);

    if (progressBar) progressBar.style.width = `${progress}%`;

    if (elapsed >= DURATION_MS) {
      nextSlide();
    }

    animationFrameId = requestAnimationFrame(tick);
  }

  // Key navigation
  window.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowRight' || e.key === ' ') {
      e.preventDefault();
      nextSlide();
    } else if (e.key === 'ArrowLeft') {
      e.preventDefault();
      prevSlide();
    } else if (e.key === 'p' || e.key === 'P') {
      togglePause();
    }
  });

  // Click to toggle pause
  document.addEventListener('click', (e) => {
    if (e.target.closest('a')) return;
    togglePause();
  });

  // Live clock interval
  updateClock();
  setInterval(updateClock, 1000);

  // Background refresh to pick up fresh builds
  setTimeout(() => {
    window.location.reload();
  }, RELOAD_INTERVAL_MS);

  // Start presentation
  showSlide(0);
  animationFrameId = requestAnimationFrame(tick);
})();
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `docker compose run --rm site bundle exec ruby -Itest test/showcase_test.rb`
Expected output: PASS (4 runs, 12 assertions, 0 failures, 0 errors).

---

### Task 4: Full Verification and Visual Inspection

**Files:**
- Test: All tests and Jekyll build

- [ ] **Step 1: Run full verification suite**

Run content validation:
`docker compose run --rm site bundle exec ruby scripts/validate_content.rb`

Run all test suites:
`docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb`
`docker compose run --rm site bundle exec ruby -Itest test/homepage_test.rb`
`docker compose run --rm site bundle exec ruby -Itest test/showcase_test.rb`

Run production Jekyll build:
`docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace`

Expected output: All commands exit with code 0.

- [ ] **Step 2: Commit changes**

```bash
git add _layouts/showcase.html showcase.md _sass/showcase.scss assets/css/app.scss assets/js/showcase.js
git commit -m "feat: implement hallway TV digital signage showcase display at /showcase/"
```
