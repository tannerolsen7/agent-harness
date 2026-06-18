---
title: Design System
generated-by: design-synthesizer
status: starter
---

# Design System

This file is the single source of truth for design tokens in this project.
The token linter (`scripts/token-lint.sh`) checks that UI files use `var(--...)` references
rather than hardcoded hex colors or raw spacing values. Committing this file activates enforcement.
Run `/design` or `@design-synthesizer` to fill in a full system.

---

## 1. Colors

| Token | Hex | Use |
|---|---|---|
| `color-primary` | `#0070f3` | Primary actions, links |
| `color-surface` | `#ffffff` | Page and card backgrounds |
| `color-border` | `#e5e7eb` | Borders and dividers |
| `color-error` | `#ef4444` | Errors and destructive states |
| `color-text-primary` | `#111827` | Body text |
| `color-text-secondary` | `#6b7280` | Captions, helper text |
| `color-neutral-50` | `#f9fafb` | Lightest neutral |
| `color-neutral-100` | `#f3f4f6` | Light neutral |
| `color-neutral-200` | `#e5e7eb` | |
| `color-neutral-300` | `#d1d5db` | |
| `color-neutral-400` | `#9ca3af` | |
| `color-neutral-500` | `#6b7280` | Mid neutral |
| `color-neutral-600` | `#4b5563` | |
| `color-neutral-700` | `#374151` | |
| `color-neutral-800` | `#1f2937` | |
| `color-neutral-900` | `#111827` | Darkest neutral |

---

## 2. Typography

Font family: System stack — `-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`
Code font: `'JetBrains Mono', 'Fira Mono', monospace`

| Level | Size | Weight | Line-height | Tracking | Use |
|---|---|---|---|---|---|
| `text-display` | 48px | 700 | 1.1 | -0.02em | Page hero |
| `text-heading-1` | 36px | 700 | 1.2 | -0.01em | Section title |
| `text-heading-2` | 24px | 600 | 1.3 | 0 | Sub-section |
| `text-heading-3` | 20px | 600 | 1.4 | 0 | Card title |
| `text-body` | 16px | 400 | 1.6 | 0 | Default body |
| `text-small` | 14px | 400 | 1.5 | 0 | Caption, helper |
| `text-caption` | 12px | 400 | 1.4 | 0.01em | Metadata |

---

## 3. Spacing

Base unit: 4px

| Token | px | Use |
|---|---|---|
| `space-1` | 4px | Micro gap |
| `space-2` | 8px | Tight gap |
| `space-3` | 12px | |
| `space-4` | 16px | Default component gap |
| `space-5` | 20px | |
| `space-6` | 24px | Card padding |
| `space-8` | 32px | Section internal gap |
| `space-10` | 40px | |
| `space-12` | 48px | |
| `space-16` | 64px | Section gap (compact) |
| `space-20` | 80px | Section gap (default) |
| `space-24` | 96px | Section gap (generous) |

Component padding:
- Card: `space-6` (24px)
- Button: `space-2` vertical / `space-4` horizontal
- Input: `space-2` vertical / `space-3` horizontal

---

## 4. Components

### Button
- Padding: 8px 16px (primary, secondary) / 8px 12px (ghost)
- Border radius: 6px
- States: default, hover (`brightness(0.9)`), active (`brightness(0.8)`), disabled (`opacity: 0.4`)

### Input
- Padding: 8px 12px
- Border: 1px solid `color-border`
- Border radius: 6px
- Focus: 2px `color-primary` outline offset 2px
- Error: 1px solid `color-error`

### Card
- Padding: 24px
- Border: 1px solid `color-border`
- Border radius: 8px
- Background: `color-surface`

### Badge
- Padding: 2px 8px
- Border radius: 999px (pill)
- Font: `text-small`

---

## 5. Shapes & Elevation

Border radius scale:
- Sharp: 4px
- Default: 6px
- Large: 8px
- Pill: 999px

Elevation (shadow):
- Level 0 (flat): none
- Level 1 (card): `0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06)`
- Level 2 (dropdown): `0 4px 6px rgba(0,0,0,0.07), 0 2px 4px rgba(0,0,0,0.06)`
- Level 3 (modal): `0 20px 25px rgba(0,0,0,0.1), 0 10px 10px rgba(0,0,0,0.04)`

---

## 6. Philosophy & Constraints

**Hard rules:**
1. Use tokens — never hardcode hex colors or raw pixel spacing in components.
2. One accent color maximum. If you add a second, the first one must go.
3. Type scale is fixed — never introduce a size outside the defined levels.
4. All interactive states (hover, active, disabled) must be specified before shipping.
5. Components follow the spacing scale — no arbitrary pixel values.

**Absolute bans (the token linter enforces these):**
- No gradient text (`background-clip: text`)
- No glassmorphism (`backdrop-filter: blur` with semi-transparent backgrounds as the primary card style)
- No side-stripe borders as the sole visual differentiator (`border-left: 4px solid` used decoratively)
- No hero-metric template (giant number + small label, centered, used as a primary content pattern)
- No identical-card grids (three or more cards with identical structure, layout, and padding and no content differentiation)
- No eyebrow labels on every section (`text-transform: uppercase` small label above every heading)

**Register:** Product — design serves the product; it does not compete with it.

---

## 7. Agent Prompt Guide

Paste this before writing any UI code for this project:

```
Colors: color-primary=#0070f3 | color-surface=#ffffff | color-border=#e5e7eb |
        color-error=#ef4444 | color-text-primary=#111827 | color-text-secondary=#6b7280
Neutral scale: 50=#f9fafb 100=#f3f4f6 200=#e5e7eb 300=#d1d5db 400=#9ca3af
               500=#6b7280 600=#4b5563 700=#374151 800=#1f2937 900=#111827

Typography: display=48/700 | h1=36/700 | h2=24/600 | h3=20/600 |
            body=16/400 | small=14/400 | caption=12/400

Spacing (4px base): 1=4 2=8 3=12 4=16 5=20 6=24 8=32 10=40 12=48 16=64 20=80 24=96

Personality: Clean and functional. Every element earns its place. Whitespace is
intentional — not a gap to fill. Restraint over expression. No decorative
flourishes that don't serve communication. Engineering product: the UI recedes
so the user can work.
```
