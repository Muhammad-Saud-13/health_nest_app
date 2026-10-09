---
name: HealthNest Clinical Precision
colors:
  surface: '#faf8ff'
  surface-dim: '#d2d9f4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#eaedff'
  surface-container-high: '#e2e7ff'
  surface-container-highest: '#dae2fd'
  on-surface: '#131b2e'
  on-surface-variant: '#454556'
  inverse-surface: '#283044'
  inverse-on-surface: '#eef0ff'
  outline: '#757687'
  outline-variant: '#c6c5d8'
  surface-tint: '#3a46eb'
  primary: '#0008ad'
  on-primary: '#ffffff'
  primary-container: '#1c27d6'
  on-primary-container: '#acb2ff'
  inverse-primary: '#bec2ff'
  secondary: '#4750c8'
  on-secondary: '#ffffff'
  secondary-container: '#7b85ff'
  on-secondary-container: '#000595'
  tertiary: '#2e323d'
  on-tertiary: '#ffffff'
  tertiary-container: '#454854'
  on-tertiary-container: '#b4b7c5'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e0e0ff'
  primary-fixed-dim: '#bec2ff'
  on-primary-fixed: '#00036b'
  on-primary-fixed-variant: '#1924d4'
  secondary-fixed: '#e0e0ff'
  secondary-fixed-dim: '#bec2ff'
  on-secondary-fixed: '#00036b'
  on-secondary-fixed-variant: '#2d35af'
  tertiary-fixed: '#e0e2f0'
  tertiary-fixed-dim: '#c3c6d4'
  on-tertiary-fixed: '#181b26'
  on-tertiary-fixed-variant: '#434652'
  background: '#faf8ff'
  on-background: '#131b2e'
  surface-variant: '#dae2fd'
typography:
  display-lg:
    fontFamily: Manrope
    fontSize: 44px
    fontWeight: '700'
    lineHeight: 52px
    letterSpacing: -0.02em
  display-metric:
    fontFamily: Manrope
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Manrope
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Manrope
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Hanken Grotesk
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system translates critical biometric monitoring into an elevated, high-confidence personal health experience. It balances absolute clinical rigor with the serene refinement of high-end diagnostic hardware. 

The aesthetic is clean, flat, and structured. Extraneous visual noise, heavy gradients, and non-essential ornamentation are eliminated to support rapid cognitive processing during health assessments. Visual clarity delivers immediate reassurance: the interface feels authoritative, surgically precise, and quietly protective.

## Colors

The palette enforces strict functional partitioning to prevent cognitive fatigue and erroneous readings:

- **Primary Electric Blue (`#1C27D6`)**: Reserved exclusively for active user intent—primary action buttons, text links, selected filter chips, and active tab indicators. It must never be applied to status indicators, backgrounds, or decorative strokes.
- **Primary Variations**: `#151D9E` serves as the active/pressed state for primary controls; `#EEF0FF` provides the foundational surface for selected toggles and interactive indicator backings.
- **Foundations**: The canvas operates on an off-white plane (`#F7F8FC`), against which cards and sheet surfaces rise in pure `#FFFFFF`, bounded by precise hairline borders (`#E2E8F0`).
- **Typography Levels**: All primary readings and headings leverage `#0F172A` for high-contrast accessibility, supported by `#475569` for secondary data labels, timestamps, and metric units.
- **Biometric Status Ensembles**: Statuses pair tinted backgrounds with high-contrast text and explicit icons. Calm/Connected uses `#15803D` on `#DCFCE7`; Stressed uses `#C2410C` on `#FFEDD5`; Transition/Getting Ready uses `#B45309` on `#FEF3C7`; Critical/Disconnected uses `#B91C1C` on `#FEE2E2`.

## Typography

The type system blends the balanced geometric clarity of `Manrope` for display and high-level vitals with the readable utility of `Hanken Grotesk` for dense health streams and body text.

- **Display & Metrics**: The `display-metric` token communicates numerical readings (e.g., heart rate, SpO2 percentages) with zero ambiguity.
- **Headings**: `Manrope` provides structured, confident orientation across dashboard screens and sheet headers.
- **Labels & Units**: `Hanken Grotesk` at medium and semibold weights maintains critical legibility for units of measurement (BPM, %, °C) alongside large vitals.

## Layout & Spacing

The layout is built around a mobile-first single-column structure that expands into a 4-to-8 column system on tablet viewports. The horizontal screen margin is set to `1.25rem` (20px) to maximize screen area while preserving boundary breathing room.

- **Stack Rhythm**: Primary data containers and metric cards maintain a consistent vertical gap of `1rem` (`space-md`), preventing visual crowding.
- **Internal Card Padding**: Cards use `1.25rem` internal padding for primary health summaries and `1rem` for nested status groups.
- **Touch Ergonomics**: All interactive regions comply with an absolute minimum touch boundary of 56px (`56dp`) vertically, guaranteeing failure-free activation even during physical movement or stress.

## Elevation & Depth

This system avoids ambient shadows, blurs, and skeuomorphic gradients in favor of an authentic flat paradigm:

- **Surface Separation**: Hierarchy is achieved purely through color contrast—pure white (`#FFFFFF`) containers resting directly against the light cool gray (`#F7F8FC`) canvas.
- **Structural Boundaries**: All cards, modal sheets, and system banners utilize a crisp 1px solid stroke (`#E2E8F0`).
- **Modal Depth**: Overlays and sheets do not use drop shadows; they rely on a dimming canvas scrim (`rgba(15, 23, 42, 0.4)`) and an explicit top/perimeter 1px border to demarcate interaction layers.

## Shapes

The interface balances soft organic human anatomy with technical precision using a standardized geometric radius scale:

- **Cards and Modals (`rounded-lg`)**: Use a calibrated 16px (`1rem`) border radius, framing biometric widgets cleanly without excessive bubble-like softness.
- **Buttons and Inputs**: Built with a standardized 8px (`0.5rem`) radius for focused, deliberate, and dependable form controls.
- **Status Badges & Chips**: Feature fully pill-rounded perimeters (9999px) to signal self-contained, discrete states and filter controls.

## Components

### Buttons
- **Primary Button**: Solid `#1C27D6` background, `#FFFFFF` text (`label-lg`), minimum height of 56px, corner radius of 8px. Hover/active shifts to `#151D9E`.
- **Secondary Button**: Pure `#FFFFFF` background, `#E2E8F0` 1px border, `#0F172A` text.
- **Destructive Button**: Pure `#FFFFFF` background, 1px border of `#B91C1C`, `#B91C1C` text.

### Vital Status Badges
- Pill-shaped inline badges with explicit icon-plus-label alignment.
- **Calm/Connected**: `#DCFCE7` background, `#15803D` typography and icon.
- **Stressed**: `#FFEDD5` background, `#C2410C` typography and icon.
- **Reconnecting/Pending**: `#FEF3C7` background, `#B45309` typography and icon.
- **Disconnected/Critical**: `#FEE2E2` background, `#B91C1C` typography and icon.

### Cards
- Pure `#FFFFFF` background, 16px radius, bordered by a single continuous 1px `#E2E8F0` stroke. Zero drop shadows. Header rows house the biometric title (`headline-sm`) along with a corresponding Status Badge.

### Chips & Segmented Controls
- **Unselected**: `#FFFFFF` background, `#E2E8F0` border, `#475569` text.
- **Selected**: `#EEF0FF` background, `#1C27D6` border, `#1C27D6` text. Minimum touch height of 44px (expanded to 56px hitbox).

### Input Fields & Controls
- **Inputs**: 56px height, `#FFFFFF` background, 1px `#E2E8F0` border, 8px radius, `#0F172A` text. Focus state transitions border to `#1C27D6` with a 1px inner stroke.
- **Checkboxes & Radios**: 24px diameter controls centered within a 56px touch zone. Unchecked borders use `#E2E8F0`; checked state uses `#1C27D6` fill with `#FFFFFF` iconography.