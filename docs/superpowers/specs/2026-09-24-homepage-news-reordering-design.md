# Design: Homepage Section Reordering & News CTA

## Problem Statement
The Philadelphia Flight Control Laboratory (PFCL) website homepage currently places the "News & updates" section at the very bottom of the page, below "Welcome", "Research groups", and "Selected student projects". Dynamic updates and recent lab announcements should be prominent and immediately visible to visitors browsing the homepage, while maintaining the contextual introduction to the lab.

## User Decision & Approach
1. Position "News & updates" directly below the introductory "Welcome" section and photo carousel, elevating it above "Research groups" and "Selected student projects".
2. Add a call-to-action button linking to the full News page (`/news/`) styled consistently with existing site action buttons (`is-primary is-outlined`).
3. Maintain the current display limit of 4 news items to keep vertical space balanced and ensure subsequent sections remain easily discoverable.

## Target Structure (`index.md`)
The homepage content structure will be ordered as follows:

1. **Frontmatter**: Existing metadata, page titles, hero image (`/assets/images/drone2.jpg`), and carousel items.
2. **Welcome Section**:
   - Section heading: `## Welcome`
   - Introduction paragraph describing the PFCL umbrella lab.
   - Action buttons: "Research groups" (`/labs/`) and "Available student projects" (`/projects/`).
   - Image carousel: `{% include carousel.html %}`.
3. **News & updates Section** (Moved from bottom):
   - Section heading: `## News &amp; updates`
   - Activity feed include: `{% include news_feed.html limit=4 %}`
   - Action button:
     ```html
     <div class="buttons">
       <a href="{{ '/news/' | relative_url }}" class="button is-primary is-outlined">All news &amp; updates</a>
     </div>
     ```
4. **Research groups Section**:
   - Section heading: `## Research groups`
   - Grid rendering active research group lab cards.
5. **Selected student projects Section**:
   - Section heading: `## Selected student projects`
   - Grid rendering up to 4 available student projects.
   - Action button linking to all student projects (`/projects/`).

## Verification Plan
1. **Schema & Content Validator**:
   Execute `bundle exec ruby scripts/validate_content.rb` (or via docker: `docker compose run --rm site bundle exec ruby scripts/validate_content.rb`) to verify all YAML frontmatter schemas pass.
2. **Test Suite**:
   Execute `bundle exec ruby -Itest test/content_validation_test.rb` (or via docker: `docker compose run --rm site bundle exec ruby -Itest test/content_validation_test.rb`).
3. **Production Build**:
   Execute `JEKYLL_ENV=production bundle exec jekyll build --trace` (or via docker: `docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace`) to ensure no build errors, broken liquid tags, or missing links occur.
