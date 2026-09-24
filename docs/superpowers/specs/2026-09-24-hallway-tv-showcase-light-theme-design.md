# Design: Hallway TV Showcase Light Theme Alignment

**Date:** 2026-09-24  
**Status:** Approved for Implementation Planning  
**Route:** `/showcase/`  

---

## 1. Problem Statement & Motivation

The initial hallway TV showcase display at `/showcase/` used a dark slate aesthetic with rounded corners (`16px`, `12px`, `8px`, `9999px`) and generic color accents (emerald, amber, purple). This diverged from the official PFCL website design guidelines:
1. **Universal sharp-corner policy:** The site strictly enforces `border-radius: 0 !important;` matching the Faculty of Aerospace Engineering theme.
2. **Technion Aerospace brand palette:** The site uses `#000e1f` dark navy, `#001b54` royal navy, `#31bfe4` sky cyan, `#f8fafc` surface gray, and `#e2e8f0` light border.
3. **Full light theme consistency:** Per user decision, the showcase must replicate the exact 1:1 crisp white/light aesthetic of the main website rather than a dark mode kiosk.

---

## 2. Design Specifications

### 2.1 Universal Sharp Corners
- Universal rule: `border-radius: 0 !important;` applies to every element:
  - Slide cards (`.showcase-card`)
  - Category badges (`.showcase-pill`, `.showcase-category-badge`)
  - Slide counter and pause status badges
  - Lab logo container and leader info box
  - Topic/project tags and badges
  - Progress bar and progress wrapper (`#showcase-progress`)
  - QR code frame and container (`.showcase-qr-box`)

### 2.2 Color System & Typography
- **Page Canvas:** `background-color: #f8fafc; color: #2d3748;`
- **Headings & Titles:** `#001b54` (bold, clean typography matching the main site)
- **Body & Summaries:** `#334155` (high contrast, crisp text for readability at distance)
- **Metadata Labels:** `#64748b` uppercase tracking (0.05em letter spacing)
- **Brand Accent:** `#31bfe4` (sky cyan) for borders, highlights, and progress fill

### 2.3 Layout & Components

#### Header (Top Branding Bar)
- Matches the authoritative top navbar on `index.md`:
  - Background: `#000e1f` (obsidian navy)
  - Bottom border: `3px solid #31bfe4` (signature cyan accent line)
  - Title: "Philadelphia Flight Control Laboratory" (`#ffffff`, 700 weight)
  - Subtitle: "Stephen B. Klein Faculty of Aerospace Engineering — Technion" (`#cbd5e1`)
  - Logo: `/assets/images/pfcl_logo_white.png`
  - Live clock: `#31bfe4` monospace digits
  - Live date: `#cbd5e1`

#### Slide Container & Cards
- Container: `#f8fafc` padded display area.
- Slide Card (`.showcase-card`):
  - Background: `#ffffff`
  - Border: `1px solid #e2e8f0`
  - Top Accent Line: `4px solid #001b54`
  - Box Shadow: `0 10px 30px rgba(0, 27, 84, 0.08)`
  - Sharp corners (`border-radius: 0`)
- Card Header:
  - Background: `#f8fafc` with bottom border `1px solid #e2e8f0`
  - Category Badges: Sharp rectangular badges:
    - Research Group: `background: #001b54; color: #ffffff;`
    - Student Project: `background: #001b54; color: #ffffff;` with cyan accent
    - News & Announcement: `background: #001b54; color: #ffffff;`
    - Publication: `background: #002147; color: #ffffff;`
- Card Body:
  - **Research Groups:**
    - Left sidebar: White background with `1px solid #e2e8f0` border, sharp lab logo, leader box with `border-left: 3px solid #31bfe4; background: #f8fafc;`
    - Right area: `#001b54` title, `#334155` summary, `#002147` website note
  - **Student Projects:**
    - Title: `#001b54`
    - Advisor & Contact: `#001b54` bold advisor, `#64748b` contact email
    - Summary: `#334155`
    - Project tags: Sharp rectangular badges (`background: #f1f5f9; border: 1px solid #cbd5e1; color: #001b54;`)
  - **News & Publications:**
    - Title: `#001b54`
    - Meta source: `#001b54`
    - Excerpt: `#334155`

#### Footer (Bottom Kiosk Controls)
- Background: `#ffffff`
- Top border: `1px solid #e2e8f0`
- Category indicator & slide counter: `#001b54` text on `#f1f5f9` sharp badge
- Progress bar:
  - Track: `#e2e8f0`
  - Bar: `#31bfe4` (sharp rectangular fill)
- QR Code Box:
  - Sharp rectangular white box with `1px solid #e2e8f0` border
  - Label: `#64748b` "Visit Website"
  - Image: `/assets/images/showcase_qr.png`

---

## 3. Accessibility & Motion
- WCAG AA contrast ratio compliance on all text against white/light gray backgrounds.
- `@media (prefers-reduced-motion: reduce)` disables slide scaling and opacity transitions.
- Fully operational without JavaScript (`html:not(.has-showcase-js)` displays the first slide statically).

---

## 4. Verification & Testing
- Automated regression test in `test/showcase_test.rb`:
  - Assert existence of light theme markers (`showcase-light` or light theme CSS variables).
  - Assert zero `border-radius` rules on showcase cards and badges.
- Production Jekyll build and content validator validation.
- Visual inspection in browser.
