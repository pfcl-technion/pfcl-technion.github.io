# Design: Hallway TV Cinematic Showcase Redesign

**Date:** 2026-10-06  
**Status:** Approved  
**Route:** `/showcase/`

## Objective

Redesign the Hallway TV Showcase display at `/showcase/` into a cinematic, full-bleed hero presentation optimized for 16:9 displays (1080p and 4K). Ingest both native and aggregated external research content (student projects and updates), and replace the floating card aesthetic with an edge-to-edge layout featuring asymmetric gradient scrims, subtle ambient motion, and floating translucent HUD chrome.

## Scope of Changes

1. **Slide Pool & Ingestion (`showcase.md`)**:
   - Merge native student projects (`site.projects`) and aggregated external projects (`site.data.generated.projects`) filtered by `recruitment_status == 'available'`.
   - Merge native news (`site.news`) and aggregated external updates (`site.data.generated.updates`) where `show_on_showcase == true`.
   - Normalize slide attributes: title, category, tags, advisor/author metadata, summary/excerpt, thumbnail or hero background, and canonical QR URL.
   - Use high-resolution lab hero imagery (`assets/images/drone2.jpg`, etc.) as fallbacks when slides lack individual images.

2. **Layout & Scrim (`_layouts/showcase.html` & `_sass/showcase.scss`)**:
   - Full-bleed 100vw × 100vh canvas with zero white margins or constrained center cards.
   - Background hero layer with slow subtle Ken Burns zoom (`transform: scale(1.04)`) during active display.
   - Asymmetric directional gradient scrim from left to right ensuring high text contrast against diverse image backdrops.
   - Split presentation within the slide:
     - Left column (60%): High-contrast typography, category/lab pills, advisor badge with avatar photo, summary, and badges.
     - Right column (40%): Unobstructed view of the research visual, with a high-contrast floating QR code card.
   - Translucent floating HUDs (`backdrop-filter: blur(16px)`):
     - Top HUD: PFCL emblem, faculty subtitle, cyan digital clock and date.
     - Bottom HUD: Slide category badge, slide counter, 12s progress bar, and "Visit Website" QR code.

3. **Controller & Transitions (`assets/js/showcase.js`)**:
   - 12 seconds per slide with smooth opacity/transform transitions.
   - Randomized Fisher-Yates shuffle on page load.
   - Silent 30-minute auto-reload to keep dynamic feeds updated.
   - Pause/resume toggle with Space key and click.
   - Keyboard left/right arrows for manual slide navigation.
   - Vector SVG QR code rendering into `[data-qr-target]`.

4. **Testing (`test/showcase_test.rb`)**:
   - Assert inclusion of both native and generated project/update pools.
   - Assert presence of full-bleed layout elements, QR attributes, and HUD structure.
   - Assert clean compilation and production Jekyll build.
