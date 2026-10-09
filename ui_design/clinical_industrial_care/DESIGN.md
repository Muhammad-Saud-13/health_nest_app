---
name: Clinical Industrial Care
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
  on-surface-variant: '#3f4947'
  inverse-surface: '#283044'
  inverse-on-surface: '#eef0ff'
  outline: '#6f7977'
  outline-variant: '#bec9c7'
  surface-tint: '#216963'
  primary: '#004541'
  on-primary: '#ffffff'
  primary-container: '#115e59'
  on-primary-container: '#91d5ce'
  inverse-primary: '#8fd3cc'
  secondary: '#006a63'
  on-secondary: '#ffffff'
  secondary-container: '#99efe5'
  on-secondary-container: '#006f67'
  tertiary: '#17443e'
  on-tertiary: '#ffffff'
  tertiary-container: '#305c55'
  on-tertiary-container: '#a4d2c9'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#abefe8'
  primary-fixed-dim: '#8fd3cc'
  on-primary-fixed: '#00201e'
  on-primary-fixed-variant: '#00504b'
  secondary-fixed: '#9cf2e8'
  secondary-fixed-dim: '#80d5cb'
  on-secondary-fixed: '#00201d'
  on-secondary-fixed-variant: '#00504a'
  tertiary-fixed: '#bdece2'
  tertiary-fixed-dim: '#a2d0c6'
  on-tertiary-fixed: '#00201c'
  on-tertiary-fixed-variant: '#224e47'
  background: '#faf8ff'
  on-background: '#131b2e'
  surface-variant: '#dae2fd'
typography:
  headline-xl:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Manrope
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Manrope
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 30px
  body-xl:
    fontFamily: Public Sans
    fontSize: 20px
    fontWeight: '500'
    lineHeight: 30px
  body-lg:
    fontFamily: Public Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Public Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-lg:
    fontFamily: Public Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  label-md:
    fontFamily: Public Sans
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
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
  space-xs: 0.5rem
  space-sm: 0.75rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system is engineered for industrial environments where workers require immediate, unambiguous health telemetry with zero cognitive friction. The visual identity addresses users with low digital literacy through radical directness, clear hierarchies, and an authoritative yet calm institutional tone.

The aesthetic combines institutional clinical precision with utilitarian ergonomics. Flat surfaces, intentional high-contrast borders, and oversized tap affordances eliminate ambiguity. It avoids decorative gradients, skeuomorphic illusions, and complex iconography, relying instead on high-legibility typographic scale, deep teal accents, and explicit status badges.

## Colors

Color is applied functionally rather than ornamentally. The primary deep forest teal (`#115E59`) and vibrant teal (`#0F766E`) are reserved exclusively for critical interactive elements—such as primary actions, selected navigation items, and text links. The canvas background remains an ultra-soft cool neutral (`#F8FAFB`), while active surfaces use pure white (`#FFFFFF`) with distinct borders (`#E2E8F0`).

Health status feedback is communicated through high-contrast pairs that strictly bind text, glyphs, and containers together:
- **Calm / Normal**: Forest Green text (`#15803D`) over mint container (`#DCFCE7`).
- **Attention / Getting Ready**: Deep amber text (`#B45309`) over amber container (`#FEF3C7`).
- **Stressed**: Burnt orange text (`#C2410C`) over warm container (`#FFEDD5`).
- **Critical / Disconnected / Error**: Deep red text (`#B91C1C`) over soft crimson container (`#FEE2E2`).

Neutral text colors enforce WCAG AAA compliance: Primary Text (`#0F172A`) for high legibility, and Secondary Text (`#475569`) for auxiliary guidance.

## Typography

The typography uses a split role: **Manrope** lends structured, authoritative headlines, while **Public Sans** provides neutral, institutional legibility for reading text and UI labels. 

To account for users with lower digital literacy, fatigue, or challenging factory lighting, the baseline body size starts at 18px (`body-lg`), and critical headings scale from 22px to 32px. Line heights are spaced generously (at least 1.4x to 1.5x) to prevent crowded text blocks. All letterforms prioritize rapid character distinction—particularly between numerals and uppercase letters during vital sign readouts.

## Layout & Spacing

Layouts adhere to an 8pt spatial grid calibrated for Android portrait form factors (standard target 390x844). Content structures are single-column and vertical-flow to reduce navigational friction.

- **Screen Margins**: 20px (`1.25rem`) fixed gutter on mobile devices to prevent touch clipping near display edges.
- **Touch Target Envelopes**: All interactive elements (buttons, row items, status cards) enforce an absolute minimum height and width of 56px (56dp).
- **Rhythm**: Element stacks use 16px (`space-md`) gaps between related items and 24px (`space-lg`) between distinct semantic sections, preserving clear boundaries between data points.

## Elevation & Depth

This system avoids ambient shadows, blur effects, and stacked card drop-shadows. Depth is articulated purely through tonal layers and low-contrast outlines:

- **Surface 0 (Canvas)**: `#F8FAFB` acts as the foundational plane.
- **Surface 1 (Cards & Controls)**: Pure white `#FFFFFF` layered with a uniform 1px solid border in `#E2E8F0`.
- **Surface 2 (Status Insets & Tonal Containers)**: Soft tinted backgrounds (`#DCFCE7`, `#FEF3C7`, `#FFEDD5`, `#FEE2E2`) nested inside Surface 1, inset with 12px to 16px internal padding.
- **Pressed & Active States**: Conveyed via 2px high-contrast borders or inward color fill shifts rather than dynamic drop shadows, ensuring responsiveness remains obvious under industrial screen glare.

## Shapes

The roundedness level is set to `2` (0.5rem base radius), scaling up to a uniform `rounded-lg` of 16px (`1rem`) for major interactive containers, cards, and primary buttons. 

This 16px radius strikes a deliberate balance: it softens the clinical edge while maintaining structural box geometry that clearly demarcates tap targets. Smaller tags and status indicators use an 8px radius (`0.5rem`), ensuring they remain visibly nested inside parent containers without circular distortion.

## Components

### Buttons
- **Primary Button**: Solid `#115E59` fill, `#FFFFFF` text in `label-lg`, 16px border-radius, minimum 56px height. Full-width on mobile.
- **Secondary Button**: 2px solid `#115E59` border, transparent background, `#115E59` text.
- **Destructive Button**: `#FEE2E2` background, 1px solid `#B91C1C`, `#B91C1C` text.
- Every state includes an explicit outlined left icon (24px) paired with single-verb or direct action labels ("Call Medic", "Check SpO2").

### Vital Status Cards
- Surface: `#FFFFFF`, 16px border-radius, 1px border `#E2E8F0`.
- Padding: 20px.
- Structure: A top row featuring the metric label (e.g., "Heart Rate") in `headline-md`, followed by an oversized value (32px bold), and an explicit status badge (`15803D` on `#DCFCE7`). Never show raw charts; display clear words ("Normal", "Needs Rest", "Disconnected").

### Checkboxes & Radios
- Size: 32px × 32px minimum bounding target centered in a 56px touch zone.
- Border: 2px solid `#0F172A` when unchecked, filling solid `#115E59` with a distinct checkmark when selected.

### Input Fields
- Enclosed box style, 56px height, 1px solid border `#E2E8F0` resting, 2px solid `#115E59` on focus.
- Floating or fixed top labels always visible in `label-md` to avoid relying on vanishing placeholder text.

### Navigation
- Bottom App Bar: Fixed 64px height with a top border of 1px `#E2E8F0`. Exactly 3 to 4 destinations. Active tab shows an active teal accent bar and `#115E59` outline icon; inactive tabs use `#475569`.