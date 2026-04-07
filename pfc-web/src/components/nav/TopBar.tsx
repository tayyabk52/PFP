import { useMemo } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { useAuth } from '@/context/AuthContext'
import styles from './TopBar.module.css'

// ─── Title Resolution ─────────────────────────────────────────────────────────

interface TitleResult {
  section: string | null
  title: string
}

function toTitleCase(str: string): string {
  return str.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
}

const EXACT_TITLES: Record<string, TitleResult> = {
  '/dashboard':          { section: 'Dashboard', title: 'Overview' },
  '/marketplace':        { section: null,        title: 'Marketplace' },
  '/iso':                { section: null,        title: 'ISO Board' },
  '/knowledge':          { section: null,        title: 'Knowledge Base' },
  '/sellers':            { section: null,        title: 'Sellers' },
  '/dashboard/messages': { section: 'Dashboard', title: 'Messages' },
  '/dashboard/iso':      { section: 'Dashboard', title: 'My ISO Posts' },
  '/dashboard/reports':  { section: 'Dashboard', title: 'Reports' },
  '/dashboard/profile':  { section: 'Dashboard', title: 'Profile' },
}

const PATTERN_TITLES: Array<{ pattern: RegExp; result: TitleResult }> = [
  { pattern: /^\/marketplace\/[^/]+$/, result: { section: 'Marketplace', title: 'Listing' } },
  { pattern: /^\/iso\/[^/]+$/, result: { section: 'ISO Board', title: 'ISO Request' } },
  { pattern: /^\/sellers\/[^/]+$/, result: { section: 'Sellers', title: 'Seller Profile' } },
]

function resolveTitle(pathname: string): TitleResult {
  if (EXACT_TITLES[pathname]) return EXACT_TITLES[pathname]
  for (const { pattern, result } of PATTERN_TITLES) {
    if (pattern.test(pathname)) return result
  }
  const last = pathname.split('/').filter(Boolean).pop() ?? 'PFC'
  return { section: null, title: toTitleCase(last) }
}

// ─── TopBar ───────────────────────────────────────────────────────────────────

export function TopBar() {
  const location = useLocation()
  const { profile } = useAuth()

  const { section, title } = resolveTitle(location.pathname)

  const avatarInitial = profile?.display_name?.charAt(0).toUpperCase() ?? '?'

  const dateStr = useMemo(() => {
    return new Intl.DateTimeFormat(undefined, {
      weekday: 'short',
      day: 'numeric',
      month: 'short',
    }).format(new Date())
  }, [])

  return (
    <header className={styles.topBar}>
      <div className={styles.left}>
        {section && (
          <>
            <span className={styles.section}>{section}</span>
            <span className={styles.separator} aria-hidden="true">—</span>
          </>
        )}
        <p className={styles.title}>{title}</p>
      </div>

      <Link to="/dashboard/profile" className={styles.right}>
        <span className={styles.dateStr}>{dateStr}</span>
        <span className={styles.displayName}>{profile?.display_name ?? 'Member'}</span>
        <div className={styles.avatar}>
          {profile?.avatar_url ? (
            <img src={profile.avatar_url} alt="" className={styles.avatarImg} />
          ) : (
            avatarInitial
          )}
        </div>
      </Link>
    </header>
  )
}
