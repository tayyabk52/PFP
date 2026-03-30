# Desktop Sidebar Upgrade — Design Spec

**Date:** 2026-03-30
**Scope:** `pfc-web/src/components/nav/Sidebar.tsx` + `Sidebar.module.css` only
**Constraint:** No new dependencies. No mobile changes. No route or nav item changes.

---

## Reference

Source design: `pfc-web/extracted_components/components/DashboardSidebar.tsx`
Design tokens used: `pfc-web/src/styles/tokens.css` (PFC Olfactory Archive system)

---

## Visual Structure

### Expanded State (240px)

```
┌──────────────────────────────────────────┐  ← hairline-right: 0.5px solid var(--color-surface-container-highest)
│  [P]  PFC                            [◀] │  ← brand block, hairline-bottom (0.5px)
│       Pakistan Fragrance Community       │    padding: 1.25rem 0.75rem 1rem
│                                          │
│  [av] Display Name                       │  ← user badge, hairline-bottom (0.5px)
│       MEMBER                             │    padding: 1rem 0.75rem
│                                          │
│  [+  CREATE ISO  ]  or                   │  ← role-based CTA (primary bg, white text)
│  [+  CREATE LISTING ]                    │    margin: 0.75rem; height: 2.25rem; no border-radius
│                                          │
│  MARKET                                  │  ← nav section, flex: 1, overflow-y auto
│  DASHBOARD                               │    padding: 0.25rem 0.5rem
│  MESSAGES                                │
│  ISO BOARD                               │
│  MY ISO POSTS                            │
│  REPORTS                                 │
│  KNOWLEDGE                               │
│  SELLERS                                 │
│                                          │
├──────────────────────────────────────────┤  ← hairline-top: 0.5px
│  SIGN OUT                                │  ← bottom section, padding: 0.5rem
└──────────────────────────────────────────┘
```

### Collapsed State (64px)

```
┌──────┐
│ [P]  │  ← brand square only, centered. Collapse btn hidden.
│ [av] │  ← avatar only, centered
│ [+]  │  ← CTA: icon only (PlusIcon), centered, primary bg
│  ◎   │  ← icons only, centered, no labels
│  ⊞   │
│  ✉   │
│  ...  │
├──────┤
│  ↩   │  ← sign out icon only
└──────┘
```

---

## Component Sections (detailed)

### 1. Brand Block

**Expanded:**
- Flex row, `align-items: center`, `gap: 0.75rem`, `padding: 1.25rem 0.75rem 1rem`
- Brand square: `36×36px`, `background: var(--color-primary)` (`#003527`), white bold "P", `border-radius: var(--radius-sm)`
- Brand text column: "PFC" bold 0.875rem + "Pakistan Fragrance Community" 0.6875rem muted
- Collapse toggle: pushed to far right via `margin-left: auto`. Black filled square (`24×24px`, `background: #000`, white chevron icon `14×14px`). Hover: `background: rgba(0,0,0,0.75)`. Sharp corners.
- `hairline-bottom` separates from user badge.

**Collapsed:**
- Brand square only, centered. No brand text. No toggle button in this block.
- Toggle button moves into the user-badge row (see Section 2 below).

### 2. User Badge

**Expanded:**
- Flex row, `gap: 0.75rem`, `padding: 1rem 0.75rem`
- Avatar: `28×28px` circle, `background: var(--color-surface-container-highest)`, initial letter fallback, `overflow: hidden` for `<img>`
- Text column: display_name (0.8125rem, semibold, truncate) + role label (0.625rem, uppercase, tracking-widest, muted)
- Collapse toggle button at far right: `24×24px` black square, white chevron `ChevronsLeft` / `ChevronsRight` equivalent. `margin-left: auto`.
- `hairline-bottom` separates from CTA.

**Collapsed:**
- Avatar centered + toggle button stacked or side-by-side (centered column). Since width is only 64px, show avatar centered and below it the toggle button. Or: avatar row with toggle to its right (both centered in 64px). Follow extracted: when collapsed, avatar and toggle are in a `justify-center` row together.

### 3. Role-Based CTA Button

**Logic:**
- `profile?.role === 'seller' || profile?.role === 'admin'` → **"Create Listing"** → navigates to `/marketplace/new`
- `profile?.role === 'member'` or null → **"Create ISO"** → navigates to `/iso/new`

**Expanded appearance:**
- Full-width button (minus `0.75rem` padding on each side → `calc(100% - 1.5rem)` or `margin: 0 0.75rem`)
- Height: `2.25rem` (36px)
- Background: `var(--color-primary)` (`#003527`)
- Text: white, `0.625rem`, uppercase, `letter-spacing: 0.2em`, Inter font
- Left icon: `+` (inline SVG, `16×16px`)
- `border-radius: 0` (sharp)
- Hover: `background: rgba(0, 53, 39, 0.85)`
- Bottom margin: `0.5rem` to separate from nav

**Collapsed appearance:**
- Centered `+` icon only, same `bg-primary`, full width within the 64px column (subtract padding): `margin: 0 0.5rem`, height `2.25rem`
- No text

### 4. Navigation Items

**Expanded:**
- `padding: 0.625rem 0.75rem`
- `border-radius: 0` (sharp — no rounding)
- `border-left: none` (remove the 3px left indicator entirely)
- Label: `0.6875rem`, uppercase, `letter-spacing: 0.12em`, Inter font, `white-space: nowrap`
- Icon: `20×20px`, `strokeWidth: 1.75` (keep existing SVGs)
- **Inactive:** text `var(--color-text-muted)`, hover `background: rgba(0, 53, 39, 0.04)`, hover text `var(--color-on-background)`
- **Active:** `background: rgba(0, 53, 39, 0.08)`, text `var(--color-primary)`, no left border
- `margin-bottom: 2px` between items

**Collapsed:**
- Icon centered, `padding: 0.75rem 0`, `justify-content: center`
- Same active/inactive bg logic

### 5. Bottom Section

**Expanded:**
- `hairline-top` separator (0.5px)
- `padding: 0.5rem 0.5rem 1rem`
- Sign Out button: flex row, `gap: 0.75rem`, `padding: 0.625rem 0.75rem`, `border-radius: 0`, text `0.6875rem` uppercase tracking, muted color
- Hover: `background: rgba(186, 26, 26, 0.06)`, `color: var(--color-error)`

**Collapsed:**
- Icon centered only

---

## CSS Changes

### Remove from `.item`:
- `border-left: 3px solid transparent`
- `border-radius: var(--radius-sm)`

### Remove from `.itemActive`:
- `border-left-color: var(--color-primary)`

### Remove from `.itemCollapsed` and `.itemCollapsed.itemActive`:
- All `border-left` references

### Update `.sidebar`:
- Replace `box-shadow: 1px 0 0 0 ...` with `border-right: 0.5px solid var(--color-surface-container-highest)`

### Add hairline utilities (inline in module, no global needed):
```css
.hairlineBottom { border-bottom: 0.5px solid var(--color-surface-container-low); }
.hairlineTop    { border-top:    0.5px solid var(--color-surface-container-low); }
```

### New classes needed:
- `.userBadge`, `.userBadgeCollapsed`
- `.ctaButton`, `.ctaButtonCollapsed`
- `.collapseToggle` (updated: black bg)
- Update `.itemLabel` — smaller, uppercase, tracking
- Update `.collapseBtn` — black bg, white color, `border-radius: 0`

---

## TypeScript Changes

`Sidebar.tsx`:
- Import `useNavigate` (already imported)
- Read `profile.role` from `useAuth()` (already available)
- Add `ctaLabel` + `ctaRoute` derived from role
- Add `UserBadge` sub-section in JSX (between brand and nav)
- Add `CtaButton` JSX section
- No new imports required

---

## What Does NOT Change

- `BottomNav.tsx` — untouched
- `AppShell.tsx` — untouched
- `AppShell.module.css` — untouched
- `TopBar.tsx` — untouched
- Nav items list (`memberItems`) — untouched
- Route paths — untouched
- Any mobile behavior — untouched
