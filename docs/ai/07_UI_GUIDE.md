# 07 — UI/UX Design Guide

Extracted from Google Stitch mockups in `/ui_design/`. Requirements (`03_REQUIREMENTS_APP.md` & `06_DECISIONS.md`) dictate **WHAT** to build; this guide dictates **HOW** it looks (layout, colors, typography, component style).

---

## 1. Design Tokens

| Token Category | Value / Hex | Usage / Description |
|---|---|---|
| **Primary Accent** | `#1C27D6` | Main brand blue/indigo; active icons, tab bars, primary buttons |
| **Primary Dark** | `#151D9E` | Button hover & pressed states |
| **Primary Soft** | `#EEF0FF` | Background for primary chips, icons, and active containers |
| **Canvas Background** | `#EDF0F7` / `#F7F8FC` | Cool light grey page background |
| **Surface White** | `#FFFFFF` | Card backgrounds, modals, input containers |
| **Text Primary** | `#0F172A` | High contrast headings and titles (WCAG AAA compliant) |
| **Text Secondary** | `#475569` | Body text, subheadings, labels |
| **Text Muted** | `#64748B` / `#94A3B8` | Auxiliary info, timestamps |
| **Border Subtle** | `#D5DCEB` / `#E2E8F0` | 1px card and container outlines |
| **State Calm** | Text `#15803D`, Bg `#DCFCE7`, Border `#BBF7D0` | Icon: `check_circle` |
| **State Stressed** | Text `#C2410C`, Bg `#FFEDD5`, Border `#FED7AA` | Icon: `warning` |
| **State Getting Ready** | Text `#B45309`, Bg `#FEF3C7`, Border `#FDE68A` | Icon: `schedule` |
| **Error / Destructive** | Text `#B91C1C`, Bg `#FEE2E2`, Border `#FECACA` | Icon: `error` / `report` |
| **Typography** | Headlines: **Manrope**, Body/Labels: **Hanken Grotesk** / **Public Sans** | Modern, highly legible industrial fonts |
| **Corner Radius** | Cards/Modals: `16px`, Buttons/Inputs: `12px`, Badges: `9999px` | Consistent rounded geometry |
| **Touch Targets** | Min Height: `56px` (`56dp`), Margin: `20px` (`1.25rem`) | Large touch targets for factory floor |

---

## 2. Screen Map

| Screen Name | Mockup Directory | Requirements / Tasks |
|---|---|---|
| **Login Screen** | `ui_design/login_with_error/` | FR-1.1, FR-1.6, NFR-4.1 / T-03 |
| **Home Screen (Calm)** | `ui_design/home_calm_connected/` | FR-7.1, FR-7.2, FR-6.3, FR-7.5 / T-04 |
| **Home Screen (Stressed)** | `ui_design/home_stressed_connected/` | FR-7.1, FR-6.2, FR-9.1, D-24 / T-04, T-06 |
| **Band Connection** | `ui_design/band_connected/` | FR-3.2, FR-3.6, FR-3.7, FR-3.9 / T-05, T-10 |
| **24-Hour History** | `ui_design/history_last_24_hours/` | FR-7.6 / T-08 |
| **Menu & Shift Toggle** | `ui_design/menu_end_shift/` | FR-1.6, Shift Start/End (D-22) / T-03, T-07 |
| **Self-Report Check-in** | `ui_design/shift_check_in_modal/` | FR-8.1–8.4, NFR-4.3 / T-07 |

---

## 3. Screen Specs (Element Order & Kept Elements)

### A. Login Screen (`login_with_error`)
1. **Header**: HealthNest icon + title ("HealthNest"), subtitle ("Worker Wellbeing & Safety"), badge ("Official Plant Terminal").
2. **Login Card**:
   - High-visibility inline error alert banner (Red container `#FEE2E2`, `Access Denied`).
   - Field 1: Work Email or Employee ID (`56px` height, badge icon).
   - Field 2: Password input (`56px` height, reveal eye toggle button).
   - Primary CTA: **Log in** button (`#1C27D6`, `56px` height).
   - Secondary Action: **Forgot password?** link.
3. **HR Support Card**: "Need account access? Speak to your shift supervisor." (No sign-up link).

### B. Home Screen (`home_calm_connected` & `home_stressed_connected`)
1. **Header**: Logo + "HealthNest" + Profile Avatar button.
2. **BLE Connection Status Banner**: Green container `#DCFCE7`, `check_circle` icon, "Wristband Connected", pulsing "Live" chip.
3. **Shift Status Line**: Schedule icon, "Shift active since [Time]".
4. **Primary State Card**:
   - Calm: Green aura/circle, `check_circle` icon, "You are Calm", reassurance text.
   - Stressed: Burnt orange icon, `warning` icon, "You are Stressed", "Physical Monitor" tag.
5. **Passive Tip Card (When Stressed - D-24)**: Warm orange container `#FFF7ED`, "Stress has been high for a while", "Got it" dismiss button (`#1C27D6`).
6. **Vitals Grid (2 Tiles Side-by-Side)**:
   - Heart Rate Tile: `favorite` icon, value (e.g. `72 bpm`), status badge (`Normal`).
   - SpO2 Tile: `air` / `water_drop` icon, value (e.g. `98%`), status badge (`Good`).
7. **Footer Disclaimer**: "This is a wellness tool, not a medical diagnosis."

### C. Band Connection Screen (`band_connected`)
1. **Header**: Title "Band Connection", subtitle "Manage your HealthNest device".
2. **Device Visual Stage Card**: Radiating pulse rings, watch icon, status badge ("Connected to HealthNest Band").
3. **Disconnect Button**: Destructive button (`#FEE2E2` bg, `#B91C1C` text, `link_off` icon, `56px` height).
4. **Safety Notice**: "Keep your wristband on during your shift for accurate tracking."

### D. 24-Hour History Screen (`history_last_24_hours`)
1. **Header**: Title "History", subtitle "Your wellbeing over the last 24 hours".
2. **Summary Metric Card**: Logged records count, percentage Calm badge (e.g. "75% Calm").
3. **Vertical Timeline Flow**:
   - Vertical continuous spine connector line.
   - Entries: Time, status badge (Calm green / Stressed orange / Getting ready amber), HR value.
4. **Footer**: Auto-sync notice.

### E. Menu Screen (`menu_end_shift`)
1. **Profile & Station Context Card**: Operator name, Station ID, Active tag.
2. **Shift Status & Action Card**: Current duration, Start/End Shift button (`52px` height).
3. **Action List**:
   - Start Check-in (`fact_check` icon).
   - Wristband Status (`watch` icon).
   - Hydration & Ergonomics / Safety Guide.
   - Log Out (`logout` icon).
4. **End Shift Modal (Dialog)**: Confirmation modal ("End shift?"), Shift summary metrics, Confirm & Cancel buttons.

### F. Self-Report Check-In Modal (`shift_check_in_modal`)
1. **Header**: "Quick check-in", "1 of 3 answered" indicator, 3-segment progress bar.
2. **Question 1 (Feeling)**: Chips (`Fine` | `Tired` | `Unwell`).
3. **Question 2 (Pain)**: Chips (`No` | `Mild` | `Severe`).
4. **Question 3 (Stress)**: Chips (`Low` | `Medium` | `High`).
5. **Action Controls**: Primary **Submit** button (`#1C27D6`), **Skip for now** text button.

---

## 4. DO NOT BUILD List (Mockup elements omitted by requirements)

- ❌ **Photos / Real Employee Portraits**: Do not use photo assets; use clean vector avatar icons (`person`).
- ❌ **Shift Start / End Buttons on Home Screen**: Home screen shows shift status line only. Shift Start/End toggle lives strictly inside **Menu Screen**.
- ❌ **Active Haptic / Vibration Stress Pop-ups**: No active vibration/pop-up alerts (D-24). Stress is shown passively on the Home State card / passive tip card.
- ❌ **4-State Classifications (Fatigued / Overexerted)**: Mockup entries showing 4 ML states are superseded. FYP-1 strictly uses 2 states: **Calm** and **Stressed**.
- ❌ **Factory Safeguard Banners / Supervisor Auto-Notify Cards**: Omit extra non-required plant notification cards.
- ❌ **Guided Breathing Exercises**: FR-7.4 is DELETED.

---

## 5. MISSING FROM MOCKUPS List (Screens to build in matching style)

1. **Disconnected / Reconnecting BLE States**:
   - Amber banner (`#FEF3C7`, `Reconnecting...`) and Red banner (`#FEE2E2`, `Disconnected - Tap to retry`).
2. **Forgot Password Screen**:
   - Clean card matching Login style with Email input, Submit button, and "Return to Login".
3. **Low SpO2 Alert Card (< 95%)**:
   - Separate warning card on Home Screen when SpO2 drops below 95%.

---

## 6. Conflict Resolutions

| Mockup Element | Requirement Rule | Winner / Resolution |
|---|---|---|
| Mockup shows 4 states (Fatigued) | ML Guide v2 specifies 2 states for FYP-1 | **Requirements Win**: Only Calm and Stressed states built. |
| Shift buttons on Home mockup | Decision D-22 & specification | **Requirements Win**: Shift Toggle button in Menu only. |
| Vibration alert mockup | Decision D-24 | **Requirements Win**: Passive UI state card display only. |
