# Design: Frontpage Rotating Student Project Showcase

## Problem Statement
The frontpage previously displayed a static list of up to three projects, which became hidden when all native projects were transitioned to external lab references. Students visiting the homepage should see an active, rotating showcase of student research opportunities directly below the Welcome introduction and above News & updates. The showcase should present 3 projects at a time and automatically advance every 7 seconds, while remaining touch-friendly and accessible without JavaScript.

## User Requirements & Decisions
1. **Section ordering:**
   - `## Welcome`
   - Section divider (`<hr class="pfcl-section-divider">`)
   - `## Selected projects looking for students` (Rotating showcase)
   - Section divider (`<hr class="pfcl-section-divider">`)
   - `## News &amp; updates`
   - Section divider (`<hr class="pfcl-section-divider">`)
   - `## Research groups`
2. **Project selection:** Include all published projects marked `recruitment_status: available` from both native PFCL projects and aggregated external lab projects (`site.data.generated.projects`).
3. **Carousel & rotation behavior:**
   - Desktop displays 3 project cards per slide.
   - Auto-advances every 7 seconds.
   - Pauses on mouse hover and keyboard focus.
   - Disables auto-advance if `prefers-reduced-motion: reduce` is enabled.
   - Provides manual next/previous navigation buttons and clickable indicator dots.
   - If 3 or fewer projects exist, controls and auto-advance are suppressed.
4. **Mobile responsiveness:** Uses native CSS scroll-snap (`overflow-x: auto; scroll-snap-type: x mandatory`). On mobile screens, cards fill the container width for swipe readability.
5. **No-JavaScript accessibility:** Adheres to AGENTS.md rule 11. Without JavaScript, CSS scroll-snap ensures all slides are navigable via native touch swipe or scroll.

## Architecture & Components

### 1. Data Pipeline & Liquid Rendering (`index.md`)
Combine available projects across native and aggregated sources:
```liquid
{% assign empty_projects = '' | split: '' %}
{% assign native_available = site.projects | where: 'published', true | where: 'recruitment_status', 'available' | where_exp: 'project', 'project.external != true' | sort: 'order' %}
{% assign generated_available = site.data.generated.projects | default: empty_projects | where: 'recruitment_status', 'available' | sort_natural: 'title' %}
{% assign available_projects = native_available | concat: generated_available %}
```
Projects are chunked into slides of 3 cards each. Each slide is marked with `data-showcase-slide` inside the track `[data-showcase-track]`.

### 2. Styles (`_sass/pfcl.scss`)
- `.pfcl-showcase-container`: Relative container holding the slider track and controls.
- `.pfcl-showcase-track`: CSS scroll-snap container with hidden scrollbars, smooth scrolling, and full slide width.
- `.pfcl-showcase-slide`: `flex: 0 0 100%`, snaps to start. Holds a Bulma `columns` layout with cards.
- `.pfcl-showcase-nav`: Controls row containing previous/next buttons and dot indicators.
- `.pfcl-showcase-dot`: Button indicator representing each slide, styled with brand cyan active state.

### 3. Client Logic (`assets/js/project-showcase.js`)
- Initializes on DOMContentLoaded for containers with `[data-project-showcase]`.
- Checks for `prefers-reduced-motion`.
- Implements 7-second auto-rotation interval with wrap-around.
- Listens to `mouseenter`, `mouseleave`, `focusin`, `focusout`, and touch events to pause and resume.
- Listens to scroll position via `scroll` / `IntersectionObserver` to synchronize active dot indicators.
- Attaches click handlers to next/prev buttons and indicator dots.

## Verification Plan

1. **Automated Unit & Regression Tests:**
   - Update `test/homepage_test.rb` to assert:
     - Section order: Welcome precedes Selected projects, Selected projects precedes News & updates, News & updates precedes Research groups.
     - Section dividers: Divider count and placement between all frontpage sections.
     - Project showcase markup: Track, slides, and controls attributes are rendered.
2. **Content Validation:**
   - Run `docker compose run --rm site bundle exec ruby scripts/validate_content.rb`.
3. **Full Test Suite:**
   - Run `docker compose run --rm site bundle exec ruby -e "Dir.glob('test/**/*_test.rb').each { |f| require_relative f }"`.
4. **Production Jekyll Build:**
   - Run `docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace`.
