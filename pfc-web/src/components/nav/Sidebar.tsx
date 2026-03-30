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
