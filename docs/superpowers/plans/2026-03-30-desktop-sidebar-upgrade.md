# Desktop Sidebar Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the desktop sidebar to match the professional extracted design — hairline borders, user badge, uppercase nav labels, role-based CTA, tinted active state, black collapse toggle — without touching any mobile code.

**Architecture:** Pure CSS Modules update. All changes live in two files: `Sidebar.module.css` (visual) and `Sidebar.tsx` (structure). The sidebar layout shifts from brand→divider→nav→(profile+signout) to brand→userbadge→cta→nav→(signout only).

**Tech Stack:** React 19, CSS Modules, React Router v7. No new dependencies.

---

## File Map

| File | Action | What changes |
|---|---|---|
| `pfc-web/src/components/nav/Sidebar.module.css` | Modify | Full rewrite — all class changes |
| `pfc-web/src/components/nav/Sidebar.tsx` | Modify | Add user badge section, add CTA, move toggle, remove profileRow from bottom |

---

## Task 1: Rewrite Sidebar.module.css

**Files:**
- Modify: `pfc-web/src/components/nav/Sidebar.module.css`

This is a full replacement of the CSS file. Every visual change in the spec is encoded here.

- [ ] **Step 1: Replace the entire contents of `Sidebar.module.css`**

```css
/* Sidebar */

.sidebar {
  display: flex;
  flex-direction: column;
  height: 100dvh;
  background: #ffffff;
  border-right: 0.5px solid var(--color-surface-container-highest);
  overflow: hidden;
  transition: width 0.2s ease;
}

.sidebarExpanded {
  width: 240px;
}

.sidebarCollapsed {
  width: 64px;
}

/* Hairline border utilities */

.hairlineBottom {
  border-bottom: 0.5px solid var(--color-surface-container-low);
}

.hairlineTop {
  border-top: 0.5px solid var(--color-surface-container-low);
}

/* ── Brand block ─────────────────────────────────────────────── */

.brand {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1.25rem 0.75rem 1rem;
  flex-shrink: 0;
}

.brandCollapsed {
  justify-content: center;
  padding: 1.25rem 0 1rem;
}

.brandSquare {
  width: 36px;
  height: 36px;
  min-width: 36px;
  background: var(--color-primary);
  border-radius: var(--radius-sm);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  font-family: var(--font-sans);
  font-weight: 700;
  font-size: 1.125rem;
  letter-spacing: -0.02em;
}

.brandText {
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.brandName {
  font-family: var(--font-sans);
  font-weight: 700;
  font-size: 0.875rem;
  color: var(--color-on-background);
  white-space: nowrap;
  line-height: 1.2;
}

.brandSub {
  font-family: var(--font-sans);
  font-size: 0.6875rem;
  color: var(--color-text-muted);
  line-height: 1.35;
}

/* ── Collapse toggle button ──────────────────────────────────── */

.collapseBtn {
  flex-shrink: 0;
  width: 24px;
  height: 24px;
  border: none;
  background: #000000;
  border-radius: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: #ffffff;
  transition: background 0.15s ease;
}

.collapseBtn:hover {
  background: rgba(0, 0, 0, 0.75);
}

/* expanded: pushed to right edge of user badge row */
.collapseBtnExpanded {
  margin-left: auto;
}

/* collapsed: just sits in centre of 64px column naturally */

/* ── User badge ──────────────────────────────────────────────── */

.userBadge {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem 0.75rem;
  flex-shrink: 0;
}

.userBadgeCollapsed {
  justify-content: center;
  gap: 0.5rem;
  padding: 0.75rem 0;
}

.avatar {
  width: 28px;
  height: 28px;
  min-width: 28px;
  border-radius: 50%;
  background: var(--color-surface-container-highest);
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: var(--font-sans);
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--color-primary);
  overflow: hidden;
}

.avatarImg {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.userInfo {
  flex: 1;
  min-width: 0;
  overflow: hidden;
}

.userName {
  font-family: var(--font-sans);
  font-size: 0.8125rem;
  font-weight: 600;
  color: var(--color-on-background);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.userRole {
  font-family: var(--font-sans);
  font-size: 0.625rem;
  font-weight: 700;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--color-text-muted);
  margin-top: 1px;
}

/* ── Role-based CTA button ───────────────────────────────────── */

.ctaWrapper {
  padding: 0.5rem 0.75rem 0.25rem;
  flex-shrink: 0;
}

.ctaWrapperCollapsed {
  padding: 0.5rem 0.5rem 0.25rem;
}

.ctaButton {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  width: 100%;
  height: 2.25rem;
  background: var(--color-primary);
  color: #ffffff;
  border: none;
  border-radius: 0;
  cursor: pointer;
  font-family: var(--font-sans);
  font-size: 0.625rem;
  font-weight: 700;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  text-decoration: none;
  transition: background 0.15s ease;
}

.ctaButton:hover {
  background: rgba(0, 53, 39, 0.85);
}

/* ── Nav list ────────────────────────────────────────────────── */

.nav {
  flex: 1;
  overflow-y: auto;
  padding: 0.25rem 0.5rem;
}

.navCollapsed {
  padding: 0.25rem 0;
}

/* ── Nav item ────────────────────────────────────────────────── */

.item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.625rem 0.75rem;
  cursor: pointer;
  border-radius: 0;
  margin-bottom: 2px;
  transition: background 0.15s ease, color 0.15s ease;
  text-decoration: none;
  color: var(--color-text-muted);
}

.item:hover {
  background: rgba(0, 53, 39, 0.04);
  color: var(--color-on-background);
}

.itemActive {
  background: rgba(0, 53, 39, 0.08);
  color: var(--color-primary);
}

.itemActive:hover {
  background: rgba(0, 53, 39, 0.08);
  color: var(--color-primary);
}

.itemCollapsed {
  justify-content: center;
  padding: 0.75rem 0;
}

.itemLabel {
  font-family: var(--font-sans);
  font-size: 0.6875rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  white-space: nowrap;
  overflow: hidden;
}

.itemIcon {
  width: 20px;
  height: 20px;
  min-width: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* ── Bottom section ──────────────────────────────────────────── */

.bottom {
  flex-shrink: 0;
  padding: 0.5rem 0.5rem 1rem;
}

.bottomCollapsed {
  padding: 0.5rem 0 1rem;
}

.signOutBtn {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.625rem 0.75rem;
  cursor: pointer;
  border-radius: 0;
  border: none;
  background: transparent;
  width: 100%;
  color: var(--color-text-muted);
  transition: background 0.15s ease, color 0.15s ease;
  font-family: var(--font-sans);
  font-size: 0.6875rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.signOutBtn:hover {
  background: rgba(186, 26, 26, 0.06);
  color: var(--color-error);
}

.signOutCollapsed {
  justify-content: center;
  padding: 0.75rem 0;
}
```

- [ ] **Step 2: Verify no TypeScript errors from CSS-only change**

```bash
cd pfc-web && npx tsc --noEmit
```

Expected: no errors (CSS Modules rename doesn't affect TS unless classes are accessed — we'll fix those in Task 2).

- [ ] **Step 3: Commit the CSS**

```bash
cd F:/PerfumeApp && git add pfc-web/src/components/nav/Sidebar.module.css && git commit -m "style(sidebar): rewrite CSS — hairlines, sharp corners, uppercase labels, new sections"
```

---

## Task 2: Rewrite Sidebar.tsx

**Files:**
- Modify: `pfc-web/src/components/nav/Sidebar.tsx`

Structural changes:
1. Remove the old `<div className={styles.divider} />` — replaced by `hairlineBottom` on sections
2. Remove the `profileRow` / `profileInfo` / `profileName` / `profileRole` / `avatarImg` references from the bottom — profile info moves to the new user badge
3. Add `UserBadge` section (between brand and nav) — avatar + name + role label + collapse toggle
4. Add `CtaButton` section (between user badge and nav)
5. Collapse toggle moves from brand block into the user badge row
6. Bottom section retains only the sign out button (no profile row)

- [ ] **Step 1: Replace the entire contents of `Sidebar.tsx`**

```tsx
import type { ReactElement } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '@/context/AuthContext'
import styles from './Sidebar.module.css'

// ─── Inline SVG Icons ─────────────────────────────────────────────────────────

function StorefrontIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 9l1-4h16l1 4" />
      <path d="M3 9v11h18V9" />
      <path d="M9 9v6h6V9" />
      <path d="M3 9c0 1.1.9 2 2 2s2-.9 2-2-2-2-2-2" />
      <path d="M9 9c0 1.1.9 2 2 2s2-.9 2-2" />
      <path d="M15 9c0 1.1.9 2 2 2s2-.9 2-2" />
      <path d="M19 9c0 1.1.9 2 2 2" />
    </svg>
  )
}

function GridIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" rx="1" />
      <rect x="14" y="3" width="7" height="7" rx="1" />
      <rect x="3" y="14" width="7" height="7" rx="1" />
      <rect x="14" y="14" width="7" height="7" rx="1" />
    </svg>
  )
}

function MailIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <rect x="2" y="4" width="20" height="16" rx="2" />
      <path d="M2 7l10 7 10-7" />
    </svg>
  )
}

function SearchIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="7" />
      <path d="M21 21l-4.35-4.35" />
    </svg>
  )
}

function InboxIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M22 12h-6l-2 3H10L8 12H2" />
      <path d="M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z" />
    </svg>
  )
}

function FlagIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" />
      <line x1="4" y1="22" x2="4" y2="15" />
    </svg>
  )
}

function BookIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z" />
      <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z" />
    </svg>
  )
}

function VerifiedIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 2l2.5 4.5L20 7.5l-4 4 .9 5.5L12 14.5l-4.9 2.5.9-5.5-4-4 5.5-1z" />
      <path d="M9 12l2 2 4-4" />
    </svg>
  )
}

function LogOutIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
      <polyline points="16 17 21 12 16 7" />
      <line x1="21" y1="12" x2="9" y2="12" />
    </svg>
  )
}

function ChevronLeftIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="15 18 9 12 15 6" />
    </svg>
  )
}

function ChevronRightIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="9 18 15 12 9 6" />
    </svg>
  )
}

function PlusIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="5" x2="12" y2="19" />
      <line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  )
}

// ─── Nav Items ────────────────────────────────────────────────────────────────

interface NavItem {
  label: string
  icon: () => ReactElement
  route: string
}

const memberItems: NavItem[] = [
  { label: 'Market',       icon: StorefrontIcon, route: '/marketplace' },
  { label: 'Dashboard',    icon: GridIcon,       route: '/dashboard' },
  { label: 'Messages',     icon: MailIcon,       route: '/dashboard/messages' },
  { label: 'ISO Board',    icon: SearchIcon,     route: '/iso' },
  { label: 'My ISO Posts', icon: InboxIcon,      route: '/dashboard/iso' },
  { label: 'Reports',      icon: FlagIcon,       route: '/dashboard/reports' },
  { label: 'Knowledge',    icon: BookIcon,       route: '/knowledge' },
  { label: 'Sellers',      icon: VerifiedIcon,   route: '/sellers' },
]

// ─── Sidebar Component ────────────────────────────────────────────────────────

interface SidebarProps {
  collapsed: boolean
  onToggle?: () => void
}

export function Sidebar({ collapsed, onToggle }: SidebarProps) {
  const location = useLocation()
  const navigate = useNavigate()
  const { profile, signOut } = useAuth()

  const handleSignOut = async () => {
    await signOut()
    navigate('/login')
  }

  const isActive = (route: string) => {
    if (route === '/dashboard') {
      return location.pathname === '/dashboard'
    }
    return location.pathname.startsWith(route)
  }

  const avatarInitial = profile?.display_name?.charAt(0).toUpperCase() ?? '?'

  const isSeller = profile?.role === 'seller' || profile?.role === 'admin'
  const ctaLabel = isSeller ? 'Create Listing' : 'Create ISO'
  const ctaRoute = isSeller ? '/marketplace/new' : '/iso/new'

  return (
    <div className={`${styles.sidebar} ${collapsed ? styles.sidebarCollapsed : styles.sidebarExpanded}`}>

      {/* ── Brand block ─────────────────────────────────────── */}
      <div className={`${styles.brand} ${styles.hairlineBottom} ${collapsed ? styles.brandCollapsed : ''}`}>
        <div className={styles.brandSquare}>P</div>
        {!collapsed && (
          <div className={styles.brandText}>
            <span className={styles.brandName}>PFC</span>
            <span className={styles.brandSub}>Pakistan Fragrance Community</span>
          </div>
        )}
      </div>

      {/* ── User badge ──────────────────────────────────────── */}
      <div className={`${styles.userBadge} ${styles.hairlineBottom} ${collapsed ? styles.userBadgeCollapsed : ''}`}>
        <div className={styles.avatar}>
          {profile?.avatar_url ? (
            <img src={profile.avatar_url} alt="avatar" className={styles.avatarImg} />
          ) : (
            avatarInitial
          )}
        </div>
        {!collapsed && (
          <div className={styles.userInfo}>
            <div className={styles.userName}>{profile?.display_name ?? 'Member'}</div>
            <div className={styles.userRole}>{profile?.role ?? 'member'}</div>
          </div>
        )}
        {onToggle && (
          <button
            className={`${styles.collapseBtn} ${!collapsed ? styles.collapseBtnExpanded : ''}`}
            onClick={onToggle}
            title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          >
            {collapsed ? <ChevronRightIcon /> : <ChevronLeftIcon />}
          </button>
        )}
      </div>

      {/* ── CTA button ──────────────────────────────────────── */}
      <div className={collapsed ? styles.ctaWrapperCollapsed : styles.ctaWrapper}>
        <button
          className={styles.ctaButton}
          onClick={() => navigate(ctaRoute)}
        >
          <PlusIcon />
          {!collapsed && ctaLabel}
        </button>
      </div>

      {/* ── Nav items ───────────────────────────────────────── */}
      <nav className={`${styles.nav} ${collapsed ? styles.navCollapsed : ''}`}>
        {memberItems.map((item) => {
          const active = isActive(item.route)
          const Icon = item.icon
          return (
            <div
              key={item.route}
              className={`${styles.item} ${collapsed ? styles.itemCollapsed : ''} ${active ? styles.itemActive : ''}`}
              onClick={() => navigate(item.route)}
              title={collapsed ? item.label : undefined}
              role="button"
              tabIndex={0}
              onKeyDown={(e) => e.key === 'Enter' && navigate(item.route)}
            >
              <span className={styles.itemIcon}>
                <Icon />
              </span>
              {!collapsed && <span className={styles.itemLabel}>{item.label}</span>}
            </div>
          )
        })}
      </nav>

      {/* ── Bottom: sign out ────────────────────────────────── */}
      <div className={`${styles.bottom} ${styles.hairlineTop} ${collapsed ? styles.bottomCollapsed : ''}`}>
        <button
          className={`${styles.signOutBtn} ${collapsed ? styles.signOutCollapsed : ''}`}
          onClick={handleSignOut}
          title={collapsed ? 'Sign Out' : undefined}
        >
          <LogOutIcon />
          {!collapsed && <span>Sign Out</span>}
        </button>
      </div>

    </div>
  )
}
```

- [ ] **Step 2: Run TypeScript check**

```bash
cd F:/PerfumeApp/pfc-web && npx tsc --noEmit
```

Expected: no errors. If there are errors, they will be about unknown CSS module class names — check that each `styles.X` used in the TSX exists in the CSS file.

- [ ] **Step 3: Start dev server and verify visually**

```bash
cd F:/PerfumeApp/pfc-web && npm run dev
```

Open `http://localhost:5173` and log in. Check desktop view (≥1024px):
- [ ] Sidebar has hairline right border (not a thick shadow)
- [ ] Brand block: green P square + "PFC" name + subtitle, hairline bottom
- [ ] User badge below brand: avatar initial + display name + role label, toggle button (black square) at right
- [ ] CTA button: deep green full-width, uppercase text, sharp corners
  - member → "CREATE ISO"
  - seller/admin → "CREATE LISTING"
- [ ] Nav items: uppercase labels, no left border on active, tinted bg on active
- [ ] Collapse toggle: black square button, chevron icon
- [ ] Collapsed state: all sections show icon-only
- [ ] Bottom: "SIGN OUT" in uppercase, red hover

- [ ] **Step 4: Commit**

```bash
cd F:/PerfumeApp && git add pfc-web/src/components/nav/Sidebar.tsx && git commit -m "feat(sidebar): professional desktop redesign — user badge, CTA, hairlines, uppercase nav"
```

---

## Self-Review Checklist

**Spec coverage:**
- [x] Hairline borders (0.5px) → `.sidebar` border-right, `.hairlineBottom`, `.hairlineTop`
- [x] User badge → `.userBadge` + JSX section in Task 2
- [x] Uppercase tracking nav labels → `.itemLabel` with `text-transform: uppercase`, `letter-spacing: 0.08em`
- [x] Active state: tinted bg + primary text, no left border → `.itemActive` with `background: rgba(0,53,39,0.08)`, no `border-left`
- [x] Sharp corners on nav items → `.item` `border-radius: 0`
- [x] Black collapse toggle → `.collapseBtn` `background: #000000`
- [x] Toggle moves to user badge row → in `userBadge` JSX block
- [x] Role-based CTA → `isSeller` check, `ctaLabel`/`ctaRoute`
- [x] CTA collapsed = icon only → `{!collapsed && ctaLabel}` with `<PlusIcon />` always shown
- [x] Bottom section hairline top → `.hairlineTop` applied to `.bottom` wrapper
- [x] Profile row removed from bottom → bottom only has `signOutBtn`
- [x] Sign out typography upgraded → `text-transform: uppercase`, `letter-spacing`
- [x] Mobile untouched → no changes to `AppShell.tsx`, `BottomNav.tsx`
- [x] No new dependencies → no `package.json` changes

**Placeholder scan:** No TBDs or todos.

**Type consistency:** `styles.ctaWrapper` / `styles.ctaWrapperCollapsed` used in TSX, defined in CSS. `styles.collapseBtnExpanded` used in TSX, defined in CSS. All other class names verified against the CSS.
