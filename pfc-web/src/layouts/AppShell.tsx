import { useEffect, useState } from 'react'
import { Navigate, Outlet } from 'react-router-dom'
import { useAuth } from '@/context/AuthContext'
import { Sidebar } from '@/components/nav/Sidebar'
import { BottomNav } from '@/components/nav/BottomNav'
import { TopBar } from '@/components/nav/TopBar'
import styles from './AppShell.module.css'

type Breakpoint = 'desktop' | 'tablet' | 'mobile'

function useBreakpoint(): Breakpoint {
  const getBreakpoint = (): Breakpoint => {
    if (typeof window === 'undefined') return 'desktop'
    if (window.innerWidth >= 1024) return 'desktop'
    if (window.innerWidth >= 600) return 'tablet'
    return 'mobile'
  }

  const [breakpoint, setBreakpoint] = useState<Breakpoint>(getBreakpoint)

  useEffect(() => {
    const handler = () => setBreakpoint(getBreakpoint())
    window.addEventListener('resize', handler)
    return () => window.removeEventListener('resize', handler)
  }, [])

  return breakpoint
}

export function AppShell() {
  const { session, loading } = useAuth()
  const breakpoint = useBreakpoint()
  const [desktopCollapsed, setDesktopCollapsed] = useState(false)

  if (loading) {
    return (
      <div className={styles.loadingScreen}>
        <div className={styles.spinner} />
      </div>
    )
  }

  if (!session) {
    return <Navigate to="/login" replace />
  }

  if (breakpoint === 'mobile') {
    return (
      <div className={styles.shellMobile}>
        <main className={styles.contentMobile}>
          <Outlet />
        </main>
        <BottomNav />
      </div>
    )
  }

  const collapsed = breakpoint === 'tablet' || desktopCollapsed

  return (
    <div className={styles.shell}>
      <div className={styles.sidebar}>
        <Sidebar
          collapsed={collapsed}
          onToggle={breakpoint === 'desktop' ? () => setDesktopCollapsed(v => !v) : undefined}
        />
      </div>
      <div className={styles.contentWrapper}>
        <TopBar />
        <main className={styles.content}>
          <Outlet />
        </main>
      </div>
    </div>
  )
}
