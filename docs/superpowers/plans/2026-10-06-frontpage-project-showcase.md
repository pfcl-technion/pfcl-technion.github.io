# Frontpage Rotating Student Project Showcase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a responsive, auto-advancing 3-card student project showcase on the frontpage directly below the Welcome introduction and above News & updates, with full no-JavaScript and reduced-motion accessibility.

**Architecture:** A Liquid data pipeline in `index.md` merges available native and generated external projects and groups them into 3-project slides within a CSS scroll-snap track. A dedicated stylesheet in `_sass/pfcl.scss` handles responsive card widths and scroll-snap styling. A lightweight script `assets/js/project-showcase.js` manages 7-second auto-rotation, pause-on-hover/focus, next/prev arrow buttons, and indicator dots while honoring `prefers-reduced-motion`.

**Tech Stack:** Jekyll 4, Liquid, Bulma Clean Theme / Sass, Vanilla JavaScript, Minitest, Docker Compose.

## Global Constraints

- Section ordering on `index.md`: Welcome -> Selected projects looking for students -> News & updates -> Research groups.
- All frontpage sections must remain separated by `<hr class="pfcl-section-divider">`.
- Project cards must support both native PFCL projects and aggregated external projects (`project_card.html`).
- The site must remain fully navigable without JavaScript: users can swipe or scroll through slides natively via CSS scroll-snap.
- Respect `prefers-reduced-motion: reduce`: disable auto-advance timer when requested.
- If 3 or fewer projects are available, controls and timer are disabled.
- Follow the universal sharp-corner design rule: all buttons and controls must have `border-radius: 0 !important`.
- Run content validator, full Minitest suite, and production Jekyll build before declaring completion.

---

### Task 1: Update Homepage Structure and Regression Tests

**Files:**
- Modify: `test/homepage_test.rb`
- Modify: `index.md:14-88`

**Interfaces:**
- Consumes: `site.projects`, `site.data.generated.projects`, `_includes/project_card.html`.
- Produces: `[data-project-showcase]`, `[data-showcase-track]`, `[data-showcase-slide]`, and navigation controls on `index.md`.

- [ ] **Step 1: Update `test/homepage_test.rb` with failing tests for showcase markup and section ordering**

Update `test/homepage_test.rb` to assert the showcase track, slide data attributes, controls, and section order:

```ruby
  def test_homepage_showcase_structure
    assert_includes @content, "data-project-showcase", "Homepage must contain data-project-showcase container"
    assert_includes @content, "data-showcase-track", "Homepage must contain data-showcase-track element"
    assert_includes @content, "data-showcase-slide", "Homepage must contain data-showcase-slide elements"
    assert_includes @content, "data-showcase-prev", "Homepage must contain previous slide button"
    assert_includes @content, "data-showcase-next", "Homepage must contain next slide button"
    assert_includes @content, "data-showcase-dots", "Homepage must contain dot indicators container"
    assert_includes @content, "project-showcase.js", "Homepage must load project-showcase.js script"
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `docker compose run --rm site bundle exec ruby -Itest test/homepage_test.rb`
Expected: FAIL because `data-project-showcase` is not yet present in `index.md`.

- [ ] **Step 3: Update `index.md` with the new data pipeline and showcase markup**

In `index.md`, update the student projects section to query both native and external available projects, chunk them into 3-card slides, and render the showcase markup:

```liquid
{% assign empty_projects = '' | split: '' %}
{% assign native_available = site.projects | where: 'published', true | where: 'recruitment_status', 'available' | where_exp: 'project', 'project.external != true' | sort: 'order' %}
{% assign generated_available = site.data.generated.projects | default: empty_projects | where: 'recruitment_status', 'available' | sort_natural: 'title' %}
{% assign available_projects = native_available | concat: generated_available %}

{% if available_projects.size > 0 %}
<hr class="pfcl-section-divider">

<div class="pfcl-project-showcase-section" data-project-showcase>
  <div class="level is-mobile mb-4">
    <div class="level-left">
      <h2 class="title is-4 mb-0">Selected projects looking for students</h2>
    </div>
    <div class="level-right pfcl-showcase-nav-desktop">
      <div class="buttons has-addons mb-0">
        <button class="button is-small is-outlined is-primary pfcl-showcase-btn" data-showcase-prev aria-label="Previous projects">
          <i class="fas fa-chevron-left"></i>
        </button>
        <button class="button is-small is-outlined is-primary pfcl-showcase-btn" data-showcase-next aria-label="Next projects">
          <i class="fas fa-chevron-right"></i>
        </button>
      </div>
    </div>
  </div>

  <div class="pfcl-showcase-track" data-showcase-track tabindex="0" aria-label="Student projects showcase">
    {% assign slide_size = 3 %}
    {% assign total_projects = available_projects.size %}
    {% assign total_slides = total_projects | plus: slide_size | minus: 1 | divided_by: slide_size %}

    {% for slide_idx in (0..total_slides) %}
      {% assign offset = slide_idx | times: slide_size %}
      {% if offset < total_projects %}
        <div class="pfcl-showcase-slide" data-showcase-slide data-slide-index="{{ slide_idx }}">
          <div class="columns is-multiline">
            {% for project in available_projects limit: slide_size offset: offset %}
              <div class="column is-4-desktop is-6-tablet is-12-mobile">
                {% include project_card.html project=project %}
              </div>
            {% endfor %}
          </div>
        </div>
      {% endif %}
    {% endfor %}
  </div>

  <div class="level is-mobile mt-3">
    <div class="level-left">
      <div class="pfcl-showcase-dots" data-showcase-dots aria-label="Showcase slide indicators"></div>
    </div>
    <div class="level-right">
      <a href="{{ '/projects/' | relative_url }}" class="button is-small is-primary is-outlined">All student projects &rarr;</a>
    </div>
  </div>
</div>
{% endif %}
```

Ensure `<script src="{{ '/assets/js/project-showcase.js' | relative_url }}?v={{ site.time | date: '%s' }}" defer></script>` is included at the bottom of `index.md`.

- [ ] **Step 4: Run test to verify it passes**

Run: `docker compose run --rm site bundle exec ruby -Itest test/homepage_test.rb`
Expected: PASS (all tests pass).

- [ ] **Step 5: Commit changes**

```bash
git add test/homepage_test.rb index.md
git commit -m "feat(homepage): add student projects showcase markup and ordering tests"
```

---

### Task 2: CSS Styles for the Showcase

**Files:**
- Modify: `_sass/pfcl.scss`

**Interfaces:**
- Consumes: Bulma variables, `.pfcl-section-divider`, `.button`.
- Produces: `.pfcl-project-showcase-section`, `.pfcl-showcase-track`, `.pfcl-showcase-slide`, `.pfcl-showcase-dots`, `.pfcl-showcase-dot`.

- [ ] **Step 1: Add showcase styles to `_sass/pfcl.scss`**

Append showcase styles to `_sass/pfcl.scss`:

```scss
// ---- Student Projects Showcase (Frontpage Rotating) ----
.pfcl-project-showcase-section {
  position: relative;
}

.pfcl-showcase-track {
  display: flex;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  scroll-behavior: smooth;
  gap: 1.5rem;
  scrollbar-width: none;
  -ms-overflow-style: none;
  padding: 0.25rem 0.25rem 0.75rem 0.25rem;
  outline: none;

  &::-webkit-scrollbar {
    display: none;
  }

  &:focus-visible {
    box-shadow: 0 0 0 2px #31bfe4;
  }
}

.pfcl-showcase-slide {
  flex: 0 0 100%;
  min-width: 100%;
  scroll-snap-align: start;
  scroll-snap-stop: always;
}

.pfcl-showcase-btn {
  border-radius: 0 !important;
  width: 32px;
  height: 32px;
  padding: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.pfcl-showcase-dots {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.pfcl-showcase-dot {
  width: 10px;
  height: 10px;
  padding: 0;
  border: 1px solid #001b54;
  background-color: transparent;
  cursor: pointer;
  border-radius: 0 !important;
  transition: all 0.2s ease;

  &:hover {
    background-color: #31bfe4;
    border-color: #31bfe4;
  }

  &.is-active {
    background-color: #001b54;
    border-color: #001b54;
    width: 24px;
  }
}

@media (prefers-reduced-motion: reduce) {
  .pfcl-showcase-track {
    scroll-behavior: auto;
  }
}
```

- [ ] **Step 2: Run build to ensure Sass compiles cleanly**

Run: `docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace`
Expected: PASS (build succeeds in ~3s).

- [ ] **Step 3: Commit styles**

```bash
git add _sass/pfcl.scss
git commit -m "feat(homepage): add styling for rotating student projects showcase"
```

---

### Task 3: Client JavaScript for Showcase Auto-Rotation and Navigation

**Files:**
- Create: `assets/js/project-showcase.js`

**Interfaces:**
- Consumes: DOM elements with `data-project-showcase`, `data-showcase-track`, `data-showcase-slide`, `data-showcase-prev`, `data-showcase-next`, `data-showcase-dots`.
- Produces: 7-second auto-rotation interval, pause on hover/focus/touch, responsive dot synchronization.

- [ ] **Step 1: Implement `assets/js/project-showcase.js`**

Create `assets/js/project-showcase.js`:

```javascript
(function () {
  'use strict';

  document.addEventListener('DOMContentLoaded', function () {
    var showcase = document.querySelector('[data-project-showcase]');
    if (!showcase) return;

    var track = showcase.querySelector('[data-showcase-track]');
    var slides = showcase.querySelectorAll('[data-showcase-slide]');
    var prevBtn = showcase.querySelector('[data-showcase-prev]');
    var nextBtn = showcase.querySelector('[data-showcase-next]');
    var dotsContainer = showcase.querySelector('[data-showcase-dots]');

    if (!track || slides.length === 0) return;

    var totalSlides = slides.length;
    var currentIndex = 0;
    var timer = null;
    var intervalMs = 7000;
    var prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    // Build indicator dots
    if (dotsContainer && totalSlides > 1) {
      dotsContainer.innerHTML = '';
      for (var i = 0; i < totalSlides; i++) {
        var dot = document.createElement('button');
        dot.className = 'pfcl-showcase-dot' + (i === 0 ? ' is-active' : '');
        dot.setAttribute('type', 'button');
        dot.setAttribute('aria-label', 'Go to slide ' + (i + 1) + ' of ' + totalSlides);
        dot.dataset.slideIndex = i;
        dot.addEventListener('click', function (e) {
          var targetIndex = parseInt(e.currentTarget.dataset.slideIndex, 10);
          goToSlide(targetIndex);
          resetTimer();
        });
        dotsContainer.appendChild(dot);
      }
    }

    if (totalSlides <= 1) {
      if (prevBtn) prevBtn.style.display = 'none';
      if (nextBtn) nextBtn.style.display = 'none';
      if (dotsContainer) dotsContainer.style.display = 'none';
      return;
    }

    function updateDots(index) {
      if (!dotsContainer) return;
      var dots = dotsContainer.querySelectorAll('.pfcl-showcase-dot');
      dots.forEach(function (dot, idx) {
        if (idx === index) {
          dot.classList.add('is-active');
        } else {
          dot.classList.remove('is-active');
        }
      });
    }

    function goToSlide(index) {
      if (index < 0) {
        index = totalSlides - 1;
      } else if (index >= totalSlides) {
        index = 0;
      }
      currentIndex = index;
      var targetSlide = slides[index];
      if (targetSlide) {
        track.scrollTo({
          left: targetSlide.offsetLeft,
          behavior: prefersReducedMotion ? 'auto' : 'smooth'
        });
      }
      updateDots(currentIndex);
    }

    if (prevBtn) {
      prevBtn.addEventListener('click', function () {
        goToSlide(currentIndex - 1);
        resetTimer();
      });
    }

    if (nextBtn) {
      nextBtn.addEventListener('click', function () {
        goToSlide(currentIndex + 1);
        resetTimer();
      });
    }

    // Synchronize active dot when user scrolls manually
    var scrollDebounce = null;
    track.addEventListener('scroll', function () {
      clearTimeout(scrollDebounce);
      scrollDebounce = setTimeout(function () {
        var scrollLeft = track.scrollLeft;
        var slideWidth = track.clientWidth;
        var detectedIndex = Math.round(scrollLeft / slideWidth);
        if (detectedIndex >= 0 && detectedIndex < totalSlides && detectedIndex !== currentIndex) {
          currentIndex = detectedIndex;
          updateDots(currentIndex);
        }
      }, 50);
    });

    // Auto-advance timer management
    function startTimer() {
      if (prefersReducedMotion || totalSlides <= 1) return;
      stopTimer();
      timer = setInterval(function () {
        goToSlide(currentIndex + 1);
      }, intervalMs);
    }

    function stopTimer() {
      if (timer) {
        clearInterval(timer);
        timer = null;
      }
    }

    function resetTimer() {
      stopTimer();
      startTimer();
    }

    showcase.addEventListener('mouseenter', stopTimer);
    showcase.addEventListener('mouseleave', startTimer);
    showcase.addEventListener('focusin', stopTimer);
    showcase.addEventListener('focusout', startTimer);
    showcase.addEventListener('touchstart', stopTimer, { passive: true });
    showcase.addEventListener('touchend', startTimer, { passive: true });

    startTimer();
  });
})();
```

- [ ] **Step 2: Commit client logic**

```bash
git add assets/js/project-showcase.js
git commit -m "feat(homepage): implement rotating showcase auto-advance, controls, and accessibility"
```

---

### Task 4: End-to-End Verification and Validation

**Files:**
- Verify: `scripts/validate_content.rb`
- Verify: `test/**/*_test.rb`
- Verify: Production Jekyll Build

- [ ] **Step 1: Run content validator**

Run: `docker compose run --rm site bundle exec ruby scripts/validate_content.rb`
Expected: Output `Content validation passed.`

- [ ] **Step 2: Run full test suite**

Run: `docker compose run --rm site bundle exec ruby -e "Dir.glob('test/**/*_test.rb').each { |f| require_relative f }"`
Expected: All tests pass with 0 failures and 0 errors.

- [ ] **Step 3: Run production Jekyll build**

Run: `docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace`
Expected: Build succeeds with 0 errors.
