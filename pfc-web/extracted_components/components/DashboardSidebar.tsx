import { NavLink } from 'react-router-dom'
import {
  LayoutDashboard,
  Compass,
  LayoutGrid,
  ArrowLeftRight,
  MessageSquare,
  Bell,
  User,
  Settings,
  PlusCircle,
  LogOut,
  Menu,
  ShieldAlert,
  ChevronsLeft,
  ChevronsRight,
  Home,
} from 'lucide-react'
import { Logo } from './Logo'
import { NotificationBell } from './NotificationBell'
import { Button } from '@/components/ui/button'
import { Sheet, SheetContent, SheetTrigger, SheetTitle } from '@/components/ui/sheet'
import { Avatar, AvatarImage, AvatarFallback } from '@/components/ui/avatar'
import { useAuth } from '@/hooks/useAuth'
import { useIsMobile } from '@/hooks/useMediaQuery'
import { useUIStore } from '@/stores/uiStore'
import { ROUTES } from '@/constants'
import { cn } from '@/lib/utils'
import { useState } from 'react'

function getInitials(displayName: string | null | undefined): string {
  if (!displayName) return '?'
  const parts = displayName.trim().split(' ')
  return parts.length >= 2
    ? `${parts[0][0]}${parts[1][0]}`.toUpperCase()
    : displayName.slice(0, 2).toUpperCase()
}

const dashboardNavLinks = [
  { to: ROUTES.DASHBOARD, label: 'Dashboard', icon: LayoutDashboard, end: true },
  { to: ROUTES.BROWSE, label: 'Browse', icon: Compass, end: false },
  { to: ROUTES.MY_LISTINGS, label: 'My Listings', icon: LayoutGrid, end: false },
  { to: ROUTES.EXCHANGES, label: 'Exchanges', icon: ArrowLeftRight, end: false },
  { to: ROUTES.MESSAGES, label: 'Messages', icon: MessageSquare, end: false },
  { to: ROUTES.NOTIFICATIONS, label: 'Notifications', icon: Bell, end: false },
  { to: ROUTES.PROFILE, label: 'My Profile', icon: User, end: false },
  { to: ROUTES.SETTINGS, label: 'Settings', icon: Settings, end: false },
]

// ── Expanded sidebar content (mobile sheet + desktop expanded) ──

function SidebarContent({ onNavigate, collapsed = false, onToggleCollapse }: { onNavigate?: () => void; collapsed?: boolean; onToggleCollapse?: () => void }) {
  const { profile, isModerator, logout } = useAuth()

  const handleLogout = async () => {
    try {
      await logout()
    } catch {
      /* ignore */
    }
  }

  return (
    <div className="flex h-full flex-col">
      {/* Logo */}
      <div className={cn('flex h-16 items-center hairline-b', collapsed ? 'justify-center px-2' : 'px-6')}>
        <NavLink to={ROUTES.DASHBOARD} onClick={onNavigate}>
          <Logo showText={!collapsed} />
        </NavLink>
      </div>

      {/* User badge */}
      <div className={cn('flex items-center hairline-b', collapsed ? 'justify-center px-2 py-4' : 'gap-3 px-6 py-4')}>
        <Avatar className={cn(collapsed ? 'h-8 w-8' : 'h-8 w-8')}>
          <AvatarImage src={profile?.avatar_url ?? undefined} alt={profile?.display_name ?? ''} />
          <AvatarFallback className="text-[10px] font-sans">
            {getInitials(profile?.display_name)}
          </AvatarFallback>
        </Avatar>
        {!collapsed && (
          <div className="min-w-0 flex-1">
            <p className="truncate font-sans text-xs font-medium text-foreground">
              {profile?.display_name ?? 'Member'}
            </p>
            <p className="font-sans text-[10px] uppercase tracking-widest text-muted-foreground">
              Member
            </p>
          </div>
        )}
        {onToggleCollapse && (
          <button
            onClick={onToggleCollapse}
            className="flex h-6 w-6 shrink-0 items-center justify-center rounded-sm bg-black text-white transition-colors hover:bg-black/80"
            aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          >
            {collapsed ? (
              <ChevronsRight className="h-3 w-3" strokeWidth={2} />
            ) : (
              <ChevronsLeft className="h-3 w-3" strokeWidth={2} />
            )}
          </button>
        )}
      </div>

      {/* Create Listing CTA */}
      <div className={cn(collapsed ? 'px-2 pt-4 pb-2' : 'px-3 pt-4 pb-2')}>
        {collapsed ? (
          <NavLink
            to={ROUTES.LISTING_NEW}
            onClick={onNavigate}
            className="flex h-9 w-full items-center justify-center bg-primary text-primary-foreground transition-colors hover:bg-primary/90"
          >
            <PlusCircle className="h-4 w-4" strokeWidth={2} />
          </NavLink>
        ) : (
          <Button
            asChild
            size="sm"
            className="w-full h-9 rounded-none font-sans text-[10px] uppercase tracking-[0.2em] px-4"
          >
            <NavLink to={ROUTES.LISTING_NEW} onClick={onNavigate}>
              <PlusCircle className="mr-2 h-3.5 w-3.5" strokeWidth={2} />
              Create Listing
            </NavLink>
          </Button>
        )}
      </div>

      {/* Nav links */}
      <nav className={cn("flex-1 px-2 py-4", collapsed ? "overflow-hidden" : "overflow-y-auto")}>
        <ul className="space-y-1">
          {dashboardNavLinks.map(({ to, label, icon: Icon, end }) => (
            <li key={to}>
              <NavLink
                to={to}
                end={end}
                onClick={onNavigate}
                title={collapsed ? label : undefined}
                className={({ isActive }) =>
                  cn(
                    'flex items-center rounded-none transition-colors',
                    collapsed
                      ? 'justify-center px-2 py-2.5'
                      : 'justify-between px-3 py-2 font-sans text-xs uppercase tracking-widest',
                    isActive
                      ? 'bg-primary/10 text-primary'
                      : 'text-muted-foreground hover:bg-accent hover:text-foreground'
                  )
                }
              >
                {collapsed ? (
                  <Icon className="h-4.5 w-4.5" strokeWidth={1.5} />
                ) : (
                  <>
                    <span className="flex items-center gap-3">
                      <Icon className="h-4 w-4" strokeWidth={1.5} />
                      {label}
                    </span>
                  </>
                )}
              </NavLink>
            </li>
          ))}
        </ul>
      </nav>

      {/* Bottom actions */}
      <div className={cn('py-4 hairline-t space-y-1', collapsed ? 'px-2' : 'px-3 space-y-2')}>
        {isModerator && (
          <NavLink
            to={ROUTES.ADMIN}
            onClick={onNavigate}
            title={collapsed ? 'Admin Panel' : undefined}
            className={cn(
              'flex items-center rounded-none text-muted-foreground transition-colors hover:text-primary',
              collapsed ? 'justify-center px-2 py-2.5' : 'gap-3 px-3 py-2 font-sans text-xs uppercase tracking-widest'
            )}
          >
            <ShieldAlert className="h-4 w-4" strokeWidth={1.5} />
            {!collapsed && 'Admin Panel'}
          </NavLink>
        )}
        <NavLink
          to={ROUTES.HOME}
          onClick={onNavigate}
          title={collapsed ? 'Back to Home' : undefined}
          className={cn(
            'flex items-center rounded-none text-muted-foreground transition-colors hover:text-primary',
            collapsed ? 'justify-center px-2 py-2.5' : 'gap-3 px-3 py-2 font-sans text-xs uppercase tracking-widest'
          )}
        >
          <Home className="h-4 w-4" strokeWidth={1.5} />
          {!collapsed && 'Back to Home'}
        </NavLink>
        <button
          onClick={() => {
            handleLogout()
            onNavigate?.()
          }}
          title={collapsed ? 'Sign Out' : undefined}
          className={cn(
            'flex w-full items-center rounded-none text-muted-foreground transition-colors hover:text-destructive',
            collapsed ? 'justify-center px-2 py-2.5' : 'gap-3 px-3 py-2 font-sans text-xs uppercase tracking-widest'
          )}
        >
          <LogOut className="h-4 w-4" strokeWidth={1.5} />
          {!collapsed && 'Sign Out'}
        </button>
      </div>
    </div>
  )
}

// ── Export ─────────────────────────────────────────────────────

export function DashboardSidebar() {
  const isMobile = useIsMobile()
  const [open, setOpen] = useState(false)
  const { sidebarCollapsed, toggleSidebar } = useUIStore()
  const { session } = useAuth()
  const userId = session?.user?.id

  // Mobile: Sheet drawer
  if (isMobile) {
    return (
      <>
        <header className="fixed top-0 z-50 flex h-14 w-full items-center justify-between hairline-b bg-background/95 backdrop-blur-md px-4 md:hidden">
          <NavLink to={ROUTES.DASHBOARD}>
            <Logo />
          </NavLink>
          <div className="flex items-center gap-1">
            <NotificationBell userId={userId} />
            <Sheet open={open} onOpenChange={setOpen}>
              <SheetTrigger asChild>
                <Button variant="ghost" size="icon" className="rounded-none" aria-label="Open menu">
                  <Menu className="h-5 w-5" strokeWidth={1.5} />
                </Button>
              </SheetTrigger>
            <SheetContent side="left" className="w-64 p-0 rounded-none">
              <SheetTitle className="sr-only">Dashboard Navigation</SheetTitle>
              <SidebarContent onNavigate={() => setOpen(false)} />
            </SheetContent>
            </Sheet>
          </div>
        </header>
      </>
    )
  }

  // Desktop: fixed sidebar (collapsible)
  return (
    <aside
      className={cn(
        'fixed inset-y-0 left-0 z-40 hidden flex-col hairline-r bg-background md:flex transition-all duration-200 overflow-hidden',
        sidebarCollapsed ? 'w-16' : 'w-64',
      )}
    >
      <SidebarContent collapsed={sidebarCollapsed} onToggleCollapse={toggleSidebar} />
    </aside>
  )
}
