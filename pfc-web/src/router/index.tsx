import { createBrowserRouter, Navigate } from 'react-router-dom'
import { AppShell } from '@/layouts/AppShell'
import { LoginPage } from '@/pages/auth/LoginPage'
import { RegisterPage } from '@/pages/auth/RegisterPage'
import { DashboardPage } from '@/pages/dashboard/DashboardPage'
import { MarketplacePage } from '@/pages/marketplace/MarketplacePage'
import { ListingDetailPage } from '@/pages/marketplace/ListingDetailPage'
import { EditListingPage } from '@/pages/marketplace/EditListingPage'
import { IsoBoardPage } from '@/pages/iso/IsoBoardPage'
import { IsoDetailPage } from '@/pages/iso/IsoDetailPage'
import { SellersPage } from '@/pages/sellers/SellersPage'
import { SellerProfilePage } from '@/pages/sellers/SellerProfilePage'
import { KnowledgePage } from '@/pages/knowledge/KnowledgePage'
import { MessagesPage } from '@/pages/dashboard/messages/MessagesPage'
import { MyIsoPostsPage } from '@/pages/dashboard/iso/MyIsoPostsPage'
import { ProfilePage } from '@/pages/dashboard/profile/ProfilePage'
import { MyListingsPage } from '@/pages/dashboard/listings/MyListingsPage'

function StubPage({ title }: { title: string }) {
  return (
    <div style={{ padding: '2.5rem', maxWidth: 800 }}>
      <p style={{ fontFamily: 'Inter', fontSize: '0.625rem', fontWeight: 700, letterSpacing: '0.2em', color: '#8a9099', marginBottom: '0.5rem', textTransform: 'uppercase' }}>
        Coming Soon
      </p>
      <h1 style={{ fontFamily: 'Noto Serif', fontSize: '2rem', color: '#003527', marginBottom: '0.5rem' }}>
        {title}
      </h1>
      <p style={{ fontFamily: 'Inter', fontSize: '0.875rem', color: '#555f70' }}>
        This section is being curated.
      </p>
    </div>
  )
}

export const router = createBrowserRouter([
  { path: '/', element: <Navigate to="/login" replace /> },
  { path: '/login', element: <LoginPage /> },
  { path: '/register', element: <RegisterPage /> },
  { path: '/register/seller-apply', element: <StubPage title="Seller Application" /> },
  {
    element: <AppShell />,
    children: [
      { path: '/dashboard', element: <DashboardPage /> },
      { path: '/marketplace', element: <MarketplacePage /> },
      { path: '/marketplace/new', element: <StubPage title="Create Listing" /> },
      { path: '/marketplace/:id/edit', element: <EditListingPage /> },
      { path: '/marketplace/:id', element: <ListingDetailPage /> },
      { path: '/iso', element: <IsoBoardPage /> },
      { path: '/iso/:id', element: <IsoDetailPage /> },
      { path: '/sellers', element: <SellersPage /> },
      { path: '/sellers/:id', element: <SellerProfilePage /> },
      { path: '/knowledge', element: <KnowledgePage /> },
      { path: '/dashboard/messages', element: <MessagesPage /> },
      { path: '/dashboard/iso', element: <MyIsoPostsPage /> },
      { path: '/dashboard/listings', element: <MyListingsPage /> },
      { path: '/dashboard/reports', element: <StubPage title="Reports" /> },
      { path: '/dashboard/profile', element: <ProfilePage /> },
    ],
  },
  { path: '*', element: <Navigate to="/login" replace /> },
])
