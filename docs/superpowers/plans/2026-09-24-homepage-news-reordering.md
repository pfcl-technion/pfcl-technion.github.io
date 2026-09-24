# Homepage News Section Reordering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorder the PFCL homepage so that the News & Updates feed appears directly beneath the Welcome introduction and carousel, accompanied by an "All news & updates" button linking to `/news/`.

**Architecture:** Update `index.md` Markdown and Liquid template markup to reposition the `## News &amp; updates` section and include a call-to-action button matching the site's Bulma design patterns. Add a regression test in `test/homepage_test.rb` to assert section ordering and required links.

**Tech Stack:** Jekyll 4, Liquid, Bulma CSS, Ruby Minitest, Docker Compose.

## Global Constraints

- Never invent fake content or modify collections in an invalid way.
- Maintain strict YAML frontmatter formatting (quote strings with colons/brackets).
- Ensure WCAG 2.2 AA contrast and JavaScript-free functionality.
- Verify using validator, test suite, and production Jekyll build.

---

### Task 1: Add Homepage Structure Regression Test

**Files:**
- Create: `test/homepage_test.rb`

**Interfaces:**
- Consumes: `index.md` file content.
- Produces: Minitest test assertions verifying that "News & updates" precedes "Research groups" and "Selected student projects", follows the carousel, and contains the `/news/` link button.

- [ ] **Step 1: Write the failing test**

Create `test/homepage_test.rb`:

```ruby
# frozen_string_literal: true

require "minitest/autorun"

class HomepageTest < Minitest::Test
  def setup
    @content = File.read(File.expand_path("../index.md", __dir__))
  end

  def test_homepage_section_ordering
    welcome_pos = @content.index("## Welcome")
    carousel_pos = @content.index("{% include carousel.html %}")
    news_pos = @content.index("## News &amp; updates")
    labs_pos = @content.index("## Research groups")
    projects_pos = @content.index("## Selected student projects")

    refute_nil welcome_pos, "Expected '## Welcome' section in index.md"
    refute_nil carousel_pos, "Expected carousel include in index.md"
    refute_nil news_pos, "Expected '## News &amp; updates' section in index.md"
    refute_nil labs_pos, "Expected '## Research groups' section in index.md"
    refute_nil projects_pos, "Expected '## Selected student projects' section in index.md"

    assert carousel_pos > welcome_pos, "Carousel should appear after Welcome"
    assert news_pos > carousel_pos, "News & updates should appear after Carousel"
    assert labs_pos > news_pos, "Research groups should appear after News & updates"
    assert projects_pos > labs_pos, "Selected student projects should appear after Research groups"
  end

  def test_news_cta_button_present
    assert_includes @content, "{{ '/news/' | relative_url }}", "Homepage should include a link to /news/"
    assert_includes @content, "All news &amp; updates", "Homepage should include 'All news & updates' button text"
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `docker compose run --rm site bundle exec ruby -Itest test/homepage_test.rb`
Expected output: FAIL with assertion failure on `labs_pos > news_pos` or `test_news_cta_button_present`.

- [ ] **Step 3: Commit the test**

```bash
git add test/homepage_test.rb
git commit -m "test: add regression test for homepage section ordering and news CTA"
```

---

### Task 2: Reorder Homepage Sections in `index.md`

**Files:**
- Modify: `index.md:23-61`
- Test: `test/homepage_test.rb`

**Interfaces:**
- Consumes: `_includes/news_feed.html`, `_includes/carousel.html`, `_includes/lab_card.html`.
- Produces: Updated `index.md` where News & updates is rendered immediately after carousel.

- [ ] **Step 1: Update `index.md` markup**

In `index.md`, move the News & updates block directly after the carousel include and add the outlined button:

```markdown
{% include carousel.html %}

## News &amp; updates

{% include news_feed.html limit=4 %}

<div class="buttons">
  <a href="{{ '/news/' | relative_url }}" class="button is-primary is-outlined">All news &amp; updates</a>
</div>

## Research groups
```

Remove the trailing `## News &amp; updates` block from the bottom of `index.md`.

- [ ] **Step 2: Run tests to verify they pass**

Run: `docker compose run --rm site bundle exec ruby -Itest test/homepage_test.rb`
Expected output: PASS (2 runs, 9 assertions, 0 failures, 0 errors).

- [ ] **Step 3: Run full verification suite**

Run content validation:
`docker compose run --rm site bundle exec ruby scripts/validate_content.rb`

Run existing test suite:
`docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb`

Run production Jekyll build:
`docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace`

Expected output: All 3 commands succeed with exit code 0.

- [ ] **Step 4: Commit changes**

```bash
git add index.md
git commit -m "feat: move news and updates section above research groups on homepage"
```
