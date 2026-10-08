# Hallway TV Single-Screen Showcase Redesign

**Date:** 2026-10-08  
**Status:** Proposed  
**Author:** Antigravity & User  
**Target File(s):**
- [`showcase.md`](file:///c:/Users/sarchi/git/pfcl-technion.github.io/showcase.md)
- [`_layouts/showcase.html`](file:///c:/Users/sarchi/git/pfcl-technion.github.io/_layouts/showcase.html)
- [`_sass/showcase.scss`](file:///c:/Users/sarchi/git/pfcl-technion.github.io/_sass/showcase.scss)
- [`assets/js/showcase.js`](file:///c:/Users/sarchi/git/pfcl-technion.github.io/assets/js/showcase.js)
- [`test/showcase_test.rb`](file:///c:/Users/sarchi/git/pfcl-technion.github.io/test/showcase_test.rb)

---

## 1. Objectives & Context

The experimental 50/50 dual-split layout (simultaneously showing a project on the left and news on the right) proved visually dense and confusing for the hallway TV display.

This redesign reverts the showcase display to a **single unified presentation stream** while introducing a clean, balanced layout:
1. **Single Unified Presentation:** One active slide at a time rotating through available student projects and research news/publications every 12 seconds.
2. **Top Center Emblem Logo:** The official white PFCL circular emblem ([`assets/images/PFCL-1_edited.png`](file:///c:/Users/sarchi/git/pfcl-technion.github.io/assets/images/PFCL-1_edited.png)) positioned above everything in the top center of the screen, flanked by the laboratory title on the left and live digital clock on the right.
3. **Bottom Center Website QR Code:** A medium-sized website QR code ([`assets/images/showcase_qr.png`](file:///c:/Users/sarchi/git/pfcl-technion.github.io/assets/images/showcase_qr.png)) anchored in the center of the bottom HUD, inviting hallway visitors to open `pfcl.technion.ac.il`.
4. **Left Content / Right Image Split within Slide:** Each slide dedicates its left ~52% to typographic and content focus (category, title, advisor avatar, summary, prerequisite badges) and its right ~48% to a large framed visual related to that content.
5. **No Progress Bar:** The bottom progress bar is completely removed from HTML, SCSS, and JavaScript for a cleaner, calmer aesthetic.

---

## 2. Visual Architecture

```
+---------------------------------------------------------------------------------------+
| [PFCL / Faculty Title]           (O) PFCL-1_edited.png Logo           [ 19:45:00 ]   |
| (Left)                                  (Center)                           (Right)    |
+---------------------------------------------------------------------------------------+
|                                                                                       |
|   LEFT PANE (~52% width)                    RIGHT PANE (~48% width)                  |
|   ======================                    =======================                  |
|   [CATEGORY PILL] [LAB] [DATE]              +-------------------------------------+  |
|                                             |                                     |  |
|   Title of Project or News                  |                                     |  |
|   High-contrast, bold Montserrat            |       Featured Content Image        |  |
|                                             |    (Project thumbnail, hardware     |  |
|   [ADVISOR AVATAR] Advisor Name             |     photo, publication figure)      |  |
|                                             |                                     |  |
|   Summary description text                  |       2px cyan accent border        |  |
|   Multi-line legible typography             |        Sharp 0px corners            |  |
|                                             |                                     |  |
|   [Badge 1] [Badge 2] [Badge 3]             +-------------------------------------+  |
|                                                                                       |
+---------------------------------------------------------------------------------------+
| [CATEGORY] Slide 3 of 25               [QR CODE]                 [Space] Pause       |
|                                 Scan pfcl.technion.ac.il                              |
+---------------------------------------------------------------------------------------+
```

---

## 3. Detailed Specifications

### 3.1 Top Header HUD ([`_layouts/showcase.html`](file:///c:/Users/sarchi/git/pfcl-technion.github.io/_layouts/showcase.html))
- **Height:** 88px fixed height, `box-sizing: border-box`.
- **Background:** `rgba(0, 10, 25, 0.92)` with `backdrop-filter: blur(16px)` and 2px `#31bfe4` cyan bottom border.
- **Three-Column Grid/Flex:**
  - **Left Section (`.showcase-header-left`):**
    - Laboratory name: `Philadelphia Flight Control Laboratory` (`1.25rem`, bold, white).
    - Faculty affiliation: `Stephen B. Klein Faculty of Aerospace Engineering` (`0.85rem`, `#94a3b8`).
  - **Center Section (`.showcase-header-center`):**
    - Medium emblem logo: `/assets/images/PFCL-1_edited.png` (`height: 64px`, `width: auto`), perfectly centered horizontally.
  - **Right Section (`.showcase-header-right`):**
    - Digital clock (`#showcase-clock`): Inconsolata font, `1.6rem`, bold, `#31bfe4`.
    - Date display (`#showcase-date`): `0.85rem`, `#94a3b8`.

### 3.2 Slide Content Structure ([`showcase.md`](file:///c:/Users/sarchi/git/pfcl-technion.github.io/showcase.md))
- Iterates over unified collection:
  - Available Student Projects (`recruitment_status == 'available'`) from `site.projects` and `site.data.generated.projects`.
  - Research News & Publications (`show_on_showcase == true`) from `site.news` and `site.data.generated.updates`.
- Each slide element `<article class="showcase-slide" data-category="..." data-accent="...">`:
  - **Left Content Pane (`.showcase-slide-text`):**
    - Category pills: `AVAILABLE STUDENT PROJECT` (emerald border), `RESEARCH PUBLICATION` (cyan border), or `LAB NEWS` (amber border).
    - Lab badge: Source lab tag (`PFCL`, `ANPL`, `ConNeCt`).
    - Date / duration badge.
    - Large Title: font-size `2.2rem`, bold Montserrat, max 3 lines.
    - Advisor strip (for student projects): Avatar photo or initial placeholder, advisor name, and role label.
    - Metadata (for news/pubs): Research group affiliation and publication venue.
    - Summary text: font-size `1.2rem`, `#e2e8f0`, comfortable line-height `1.6`, up to 5 lines.
    - Topic / Prerequisite badges.
  - **Right Visual Pane (`.showcase-slide-visual`):**
    - High-resolution image card containing the content image (`project.thumbnail` / `project.image` or `item.image`).
    - Sharp 0px border with 2px accent border (`rgba(49, 191, 228, 0.4)`).
    - `object-fit: cover` with subtle Ken Burns scale animation when active.

### 3.3 Bottom Footer HUD ([`_layouts/showcase.html`](file:///c:/Users/sarchi/git/pfcl-technion.github.io/_layouts/showcase.html))
- **Height:** 100px fixed height to accommodate the QR code comfortably.
- **Background:** `rgba(0, 10, 25, 0.92)` with `backdrop-filter: blur(16px)` and 1px top border.
- **Three-Column Grid/Flex:**
  - **Left Section (`.showcase-footer-left`):**
    - `#showcase-category`: Active slide category badge.
    - `#showcase-counter`: Slide counter (`Slide X of N`).
    - `#showcase-pause-status`: `PAUSED` pill indicator.
  - **Center Section (`.showcase-footer-center`):**
    - Medium-sized website QR code card (`.showcase-qr-center`):
      - White background, sharp 0px border.
      - Image: `/assets/images/showcase_qr.png` (`height: 72px`, `width: 72px`).
      - Text label: "Visit Website: pfcl.technion.ac.il".
  - **Right Section (`.showcase-footer-right`):**
    - Keyboard navigation reminder: "[Space] / [P] Pause · [← / →] Navigate".
- **Progress Bar:** Completely removed.

### 3.4 JavaScript Controller ([`assets/js/showcase.js`](file:///c:/Users/sarchi/git/pfcl-technion.github.io/assets/js/showcase.js))
- Query slides via `.showcase-slider > .showcase-slide`.
- Single `currentIndex` pointer, rotating every 12,000ms.
- Fisher-Yates array shuffle on initialization.
- Timer loop advances slides without needing progress bar updates.
- Space / Arrow / P keyboard controls & click-to-pause remain fully functional.
- Silent 30-minute page reload preserved.

---

## 4. Verification & Testing Strategy

1. **Automated Unit Tests ([`test/showcase_test.rb`](file:///c:/Users/sarchi/git/pfcl-technion.github.io/test/showcase_test.rb)):**
   - Verify single-slider structure (`.showcase-slider > .showcase-slide`).
   - Verify top-center logo (`PFCL-1_edited.png`) is loaded.
   - Verify bottom-center QR code (`showcase_qr.png`) exists and has proper dimensions.
   - Verify progress bar elements are absent.
   - Verify sharp corners policy (`border-radius: 0`).
2. **Schema & Content Validator:**
   - Run `ruby scripts/validate_content.rb`.
3. **Production Jekyll Build:**
   - Run `docker compose run -e JEKYLL_ENV=production --rm site bundle exec jekyll build --trace`.
4. **Browser Visual Inspection:**
   - Load in browser subagent, capture screenshots of multiple slides, verifying:
     - Top center logo alignment and size.
     - Bottom center QR code visibility and scannability.
     - Left text legibility and right image framing.
