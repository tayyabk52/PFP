import type { ReactElement } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import styles from './BottomNav.module.css'

// ─── Inline SVG Icons ────────────────────────────────────────────────────────

function StorefrontIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 9l1-4h16l1 4" />
      <path d="M3 9v11h18V9" />
      <path d="M9 9v6h6V9" />
      <path d="M3 9c0 1.1.9 2 2 2s2-.9 2-2-2-2-2-2" />
      <path d="M9 9c0 1.1.9 2 2 2s2-.9 2-2" />
      <path d="M15 9c0 1.1.9 2 2 2s2-.9 2-2" />
    </svg>
  )
}

function SearchIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="7" />
      <path d="M21 21l-4.35-4.35" />
    </svg>
  )
}

function GridIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" rx="1" />
      <rect x="14" y="3" width="7" height="7" rx="1" />
      <rect x="3" y="14" width="7" height="7" rx="1" />
      <rect x="14" y="14" width="7" height="7" rx="1" />
    </svg>
  )
}

function PersonIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="8" r="4" />
      <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" />
    </svg>
  )
}

// ─── Tab Config ───────────────────────────────────────────────────────────────

interface TabItem {
  label: string
  icon: () => ReactElement
  route: string
}

const tabs: TabItem[] = [
  { label: 'Market',    icon: StorefrontIcon, route: '/marketplace' },
  { label: 'ISO',       icon: SearchIcon,     route: '/iso' },
  { label: 'Dashboard', icon: GridIcon,       route: '/dashboard' },
  { label: 'Profile',   icon: PersonIcon,     route: '/dashboard/profile' },
]

// ─── BottomNav Component ──────────────────────────────────────────────────────

export function BottomNav() {
  const location = useLocation()
  const navigate = useNavigate()

  const isActive = (route: string) => {
    if (route === '/dashboard') {
      return location.pathname === '/dashboard'
    }
    return location.pathname.startsWith(route)
  }

  return (
    <nav className={styles.nav}>
      {tabs.map((tab) => {
        const active = isActive(tab.route)
        const Icon = tab.icon
        return (
          <button
            key={tab.route}
            className={`${styles.tab} ${active ? styles.tabActive : ''}`}
            onClick={() => navigate(tab.route)}
            aria-label={tab.label}
          >
            <Icon />
            <span className={styles.label}>{tab.label}</span>
            <div className={styles.indicatorWrap}>
              {active && <div className={styles.activeIndicator} />}
            </div>
          </button>
        )
      })}
    </nav>
  )
}
