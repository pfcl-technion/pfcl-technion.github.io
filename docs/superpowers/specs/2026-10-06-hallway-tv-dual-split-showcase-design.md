# Design: Hallway TV Dual-Split Screen Showcase

**Date:** 2026-10-06  
**Status:** Approved  
**Route:** `/showcase/`

## Objective

Split the 16:9 Hallway TV Showcase display into two simultaneous side-by-side columns:
- **Left Column (50%):** Available Student Projects (cycling open research opportunities from ANPL and PFCL).
- **Right Column (50%):** Research News & Publications (cycling latest lab publications and announcements from ANPL, ConNeCt, and PFCL).

Both sides rotate simultaneously every 12 seconds with smooth transitions, providing passersby with both recruitment opportunities and lab research achievements at a single glance.

## Architecture & Layout

1. **Screen Canvas (`100vw` × `100vh`)**:
   - Fullscreen 16:9 layout with floating top and bottom translucent HUDs.
   - Central container `.showcase-split-container` divides the screen into two equal 50% columns separated by an illuminated cyan vertical divider.

2. **Left Panel: Student Projects**:
   - Cycles available student projects (`recruitment_status: available`).
   - Displays project graphic, category pill (`AVAILABLE STUDENT PROJECT`), duration/student level, title, advisor avatar and name, summary, prerequisites, and dedicated QR code to apply.

3. **Right Panel: News & Publications**:
   - Cycles recent updates (`show_on_showcase: true`).
   - Displays research imagery, category pill (`RESEARCH PUBLICATION` / `LAB NEWS`), research group badge (`ANPL` / `ConNeCt`), date, title, excerpt, and dedicated QR code to read online.

4. **HUD Chrome**:
   - **Top HUD:** PFCL logo, faculty title, live digital clock and date.
   - **Bottom HUD:** Project counter (e.g. `Project 2 of 9`), central 12s progress bar, News counter (e.g. `Update 2 of 15`), and persistent "Visit Website" QR code.

5. **Controller Logic (`assets/js/showcase.js`)**:
   - Manages independent slide sets for projects and news.
   - On each 12-second tick, advances both panels modulo their respective list lengths.
   - Space/click toggles pause; arrow keys advance both slides.
   - Renders scalable SVG QR codes into each panel's QR target.
