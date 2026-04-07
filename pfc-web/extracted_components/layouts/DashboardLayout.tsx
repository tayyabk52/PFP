import { Outlet, Navigate } from 'react-router-dom'
import { DashboardSidebar } from '@/components/common/DashboardSidebar'
import { useAuth } from '@/hooks/useAuth'
import { useUIStore } from '@/stores/uiStore'
import { useIsMobile } from '@/hooks/useMediaQuery'
import { LoadingSpinner } from '@/components/common/LoadingSpinner'
import { ROUTES } from '@/constants'

/**
 * Dashboard layout — persistent sidebar + swappable content area.
 */
export function DashboardLayout() {
  const { isAuthenticated, isEmailVerified, isBanned, profile, isLoading } = useAuth()
  const { sidebarCollapsed } = useUIStore()
  const isMobile = useIsMobile()

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (!isAuthenticated) return <Navigate to={ROUTES.LOGIN} replace />
  if (isBanned) return <Navigate to={ROUTES.BANNED} replace />
  if (!isEmailVerified) return <Navigate to={ROUTES.VERIFY_EMAIL} replace />
  if (!profile?.postcode) return <Navigate to={ROUTES.ONBOARDING} replace />

  const desktopMargin = sidebarCollapsed ? '4rem' : '16rem'

  return (
    <div className="dashboard-light flex min-h-screen">
      <DashboardSidebar />

      <div
        className="flex flex-1 flex-col pt-14 md:pt-0 transition-[margin-left] duration-200"
        style={{ marginLeft: isMobile ? 0 : desktopMargin }}
      >
        <main className="flex-1 overflow-y-auto">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
