import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/context/AuthContext'
import { fetchDashboardData, type DashboardStats, type PulseStats } from '@/utils/dashboardCache'
import styles from './MemberDashboard.module.css'

// ─── Inline SVG Icons ────────────────────────────────────────────────────────

function ShopIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 9l1-4h16l1 4" />
      <path d="M3 9v11h18V9" />
      <path d="M9 9v6h6V9" />
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

function PlusIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="5" x2="12" y2="19" />
      <line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  )
}

function MailIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <rect x="2" y="4" width="20" height="16" rx="2" />
      <path d="M2 7l10 7 10-7" />
    </svg>
  )
}

function PersonIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="8" r="4" />
      <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" />
    </svg>
  )
}

function BadgeIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="8" r="5" />
      <path d="M12 13v9" />
      <path d="M9 19l3 3 3-3" />
    </svg>
  )
}

function PackageIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M16.5 9.4l-9-5.19" />
      <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
      <polyline points="3.27 6.96 12 12.01 20.73 6.96" />
      <line x1="12" y1="22.08" x2="12" y2="12" />
    </svg>
  )
}

function ChevronRightIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="9 18 15 12 9 6" />
    </svg>
  )
}

function InboxIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M22 12h-6l-2 3H10L8 12H2" />
      <path d="M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z" />
    </svg>
  )
}

// ─── Icons ────────────────────────────────────────────────────────────────────

function RefreshIcon({ className }: { className?: string }) {
  return (
    <svg className={className} width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="23 4 23 10 17 10" />
      <polyline points="1 20 1 14 7 14" />
      <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15" />
    </svg>
  )
}

// ─── MemberDashboard ─────────────────────────────────────────────────────────

export function MemberDashboard() {
  const { profile, user } = useAuth()
  const navigate = useNavigate()
  const [stats, setStats] = useState<DashboardStats>({ isoPosts: 0, activeListings: 0, unreadMessages: 0 })
  const [pulse, setPulse] = useState<PulseStats>({ publishedListings: 0, activeIsos: 0, sellers: 0 })
  const [statsLoading, setStatsLoading] = useState(true)

  const isSeller = profile?.role === 'seller' || profile?.role === 'admin'

  const loadData = async (force = false) => {
    if (!user?.id) return
    setStatsLoading(true)
    try {
      const data = await fetchDashboardData(user.id, force)
      setStats(data.stats)
      setPulse(data.pulse)
    } finally {
      setStatsLoading(false)
    }
  }

  useEffect(() => {
    loadData()
  }, [user?.id])

  const archiveNumber = profile?.created_at
    ? new Date(profile.created_at).getTime().toString().slice(-6)
    : '—'

  const displayName = profile?.display_name ?? 'Member'

  // Stats from profile (no extra query needed — already loaded in AuthContext)
  const avgRating = profile?.avg_rating ? profile.avg_rating.toFixed(1) : '—'
  const transactions = profile?.transaction_count ?? 0

  return (
    <div className={styles.page}>
      <div className={styles.heroTop}>
        {/* ─── Header ─── */}
        <header className={styles.header}>
          <div className={styles.headerLeft}>
            <div className={styles.archiveChip}>MEMBER ARCHIVE</div>
            <p className={styles.archiveLabel}>No. {archiveNumber}</p>
            <h1 className={styles.memberName}>{displayName}</h1>
          </div>
          <div className={styles.headerDecor}>
            <div className={styles.decorCircle1} />
            <div className={styles.decorCircle2} />
            <div className={styles.decorCircle3} />
          </div>
        </header>

        {/* ─── Stat Grid ─── */}
        <div className={styles.statGrid}>
          {/* Col 1 */}
          <div 
            className={`${styles.statPrimary} ${styles.clickable}`}
            onClick={() => navigate(isSeller ? '/dashboard/listings' : '/dashboard/iso')}
          >
            <div className={styles.statPattern} />
            <div className={styles.statPrimaryContent}>
              <div className={styles.statPrimaryIcon}>
                 <PackageIcon />
              </div>
              <div className={styles.statPrimaryBottom}>
                <p className={styles.statPrimaryLabel}>{isSeller ? 'Asset Portfolio' : 'ISO Requisitions'}</p>
                <div className={styles.statPrimaryValueRow}>
                  <span className={styles.statPrimaryValue}>{statsLoading ? '—' : (isSeller ? stats.activeListings : stats.isoPosts)}</span>
                  <span className={styles.statPrimarySub}>{isSeller ? 'Active Listings' : 'Active Posts'}</span>
                </div>
              </div>
            </div>
          </div>
          
          {/* Col 2 */}
          <div className={styles.statStack}>
            <div className={styles.statMini}>
              {stats.unreadMessages > 0 && <div className={styles.redDot} />}
              <div className={styles.statMiniValue}>{statsLoading ? '—' : stats.unreadMessages}</div>
              <div className={styles.statMiniLabel}>Inbox</div>
            </div>
            <div className={styles.statMini}>
              <div className={styles.statMiniValue}>{statsLoading ? '—' : (isSeller ? avgRating : transactions)}</div>
              <div className={styles.statMiniLabel}>{isSeller ? 'Avg Rating' : 'Transactions'}</div>
            </div>
          </div>
        </div>
      </div>

      {/* ─── Main Grid ─── */}
      <div className={styles.mainGrid}>
        <div className={styles.leftCol}>
          {isSeller ? (
            // Seller quick actions
            <>
              <p className={styles.sectionLabel}>Seller Actions</p>
              <div className={styles.actionCards}>
                <button
                  className={styles.actionCard}
                  onClick={() => navigate('/marketplace/new')}
                >
                  <div className={styles.actionIconBox}>
                    <PlusIcon />
                  </div>
                  <div className={styles.actionCardText}>
                    <p className={styles.actionCardTitle}>Create Listing</p>
                    <p className={styles.actionCardSub}>List a fragrance for sale</p>
                  </div>
                  <span className={styles.chevron}>
                    <ChevronRightIcon />
                  </span>
                </button>

                <button
                  className={styles.actionCard}
                  onClick={() => navigate('/dashboard/listings')}
                >
                  <div className={styles.actionIconBox}>
                    <PackageIcon />
                  </div>
                  <div className={styles.actionCardText}>
                    <p className={styles.actionCardTitle}>My Listings</p>
                    <p className={styles.actionCardSub}>Manage your active posts</p>
                  </div>
                  <span className={styles.chevron}>
                    <ChevronRightIcon />
                  </span>
                </button>

                <button
                  className={styles.actionCard}
                  onClick={() => navigate('/iso')}
                >
                  <div className={styles.actionIconBox}>
                    <SearchIcon />
                  </div>
                  <div className={styles.actionCardText}>
                    <p className={styles.actionCardTitle}>Browse ISO Board</p>
                    <p className={styles.actionCardSub}>Find buyers seeking fragrances</p>
                  </div>
                  <span className={styles.chevron}>
                    <ChevronRightIcon />
                  </span>
                </button>

                <button className={styles.actionCard} onClick={() => navigate('/dashboard/iso/offers')}>
                  <div className={styles.actionIconBox}>
                    <InboxIcon />
                  </div>
                  <div className={styles.actionCardText}>
                    <p className={styles.actionCardTitle}>My ISO Offers</p>
                    <p className={styles.actionCardSub}>Track your offer statuses</p>
                  </div>
                  <span className={styles.chevron}>
                    <ChevronRightIcon />
                  </span>
                </button>
              </div>
            </>
          ) : (
            // Member quick actions
            <>
              <p className={styles.sectionLabel}>ISO Quick Actions</p>
              <div className={styles.actionCards}>
                <button
                  className={styles.actionCard}
                  onClick={() => navigate('/iso')}
                >
                  <div className={styles.actionIconBox}>
                    <SearchIcon />
                  </div>
                  <div className={styles.actionCardText}>
                    <p className={styles.actionCardTitle}>Browse ISO Board</p>
                    <p className={styles.actionCardSub}>See what others are seeking</p>
                  </div>
                  <span className={styles.chevron}>
                    <ChevronRightIcon />
                  </span>
                </button>

                <button
                  className={styles.actionCard}
                  onClick={() => navigate('/dashboard/iso')}
                >
                  <div className={styles.actionIconBox}>
                    <PlusIcon />
                  </div>
                  <div className={styles.actionCardText}>
                    <p className={styles.actionCardTitle}>Post an ISO</p>
                    <p className={styles.actionCardSub}>Request a fragrance you want</p>
                  </div>
                  <span className={styles.chevron}>
                    <ChevronRightIcon />
                  </span>
                </button>
              </div>
            </>
          )}

          {/* ─── Quick Links ─── */}
          <p className={styles.sectionLabel}>Quick Links</p>
          <div className={styles.quickLinks}>
            <button
              className={styles.quickLink}
              onClick={() => navigate('/dashboard/messages')}
            >
              <div className={styles.quickLinkIcon}>
                <MailIcon />
              </div>
              <span className={styles.quickLinkLabel}>Messages</span>
              {stats.unreadMessages > 0 && !statsLoading && (
                <span className={styles.unreadBadge}>{stats.unreadMessages}</span>
              )}
              <span className={styles.quickLinkArrow}>
                <ChevronRightIcon />
              </span>
            </button>

            <button
              className={styles.quickLink}
              onClick={() => navigate('/dashboard/profile')}
            >
              <div className={styles.quickLinkIcon}>
                <PersonIcon />
              </div>
              <span className={styles.quickLinkLabel}>My Profile</span>
              <span className={styles.quickLinkArrow}>
                <ChevronRightIcon />
              </span>
            </button>

            <button
              className={styles.quickLink}
              onClick={() => navigate('/marketplace')}
            >
              <div className={styles.quickLinkIcon}>
                <ShopIcon />
              </div>
              <span className={styles.quickLinkLabel}>Marketplace</span>
              <span className={styles.quickLinkArrow}>
                <ChevronRightIcon />
              </span>
            </button>
          </div>

          {/* ─── Become Seller CTA — hidden for existing sellers/admins ─── */}
          {!isSeller && (
            <div className={styles.becomeSellerCard}>
              <div className={styles.becomeSellerIcon}>
                <BadgeIcon />
              </div>
              <div className={styles.becomeSellerText}>
                <p className={styles.becomeSellerTitle}>Become a Seller</p>
                <p className={styles.becomeSellerSub}>List your fragrances and reach the community.</p>
              </div>
              <button
                className={styles.ctaBtn}
                onClick={() => navigate('/register/seller-apply')}
              >
                Apply Now
              </button>
            </div>
          )}
        </div>

        <div className={styles.rightCol}>
          {/* ─── Marketplace Pulse Card ─── */}
          <div className={styles.pulseCard}>
            <div className={styles.pulseBgBlur} />
            <div className={styles.pulseContent}>
              <div className={styles.pulseHeader}>
                <div className={styles.pulseTitleWrap}>
                  <div className={styles.pulsePingWrap}>
                    <span className={styles.pulsePing} />
                    <span className={styles.pulsePingInner} />
                  </div>
                  <h3 className={styles.pulseTitle}>Marketplace Pulse</h3>
                  <button 
                    className={`${styles.refreshBtn} ${statsLoading ? styles.spinning : ''}`} 
                    onClick={() => loadData(true)}
                    disabled={statsLoading}
                    title="Refresh Data"
                  >
                    <RefreshIcon />
                  </button>
                </div>
              </div>
              
              <div className={styles.pulseStatsRow}>
                <div 
                  className={`${styles.pulseStatItem} ${styles.clickable}`}
                  onClick={() => navigate('/marketplace')}
                >
                   <span className={styles.pulseItemLabel}>Inventory</span>
                   <div className={styles.pulseItemValueRow}>
                     <span className={styles.pulseItemValue}>{statsLoading ? '—' : pulse.publishedListings} Listings</span>
                     <ChevronRightIcon />
                   </div>
                </div>
                <div 
                  className={`${styles.pulseStatItem} ${styles.clickable}`}
                  onClick={() => navigate('/iso')}
                >
                   <span className={styles.pulseItemLabel}>Requests</span>
                   <div className={styles.pulseItemValueRow}>
                     <span className={styles.pulseItemValue}>{statsLoading ? '—' : pulse.activeIsos} ISOs</span>
                     <ChevronRightIcon />
                   </div>
                </div>
              </div>
              
              <div 
                className={`${styles.pulseFooter} ${styles.clickable}`}
                onClick={() => navigate('/sellers')}
              >
                <span className={styles.pulseItemLabel}>Network Status</span>
                <span className={styles.pulseFooterText}>{statsLoading ? '—' : pulse.sellers} Verified Sellers Active</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* ─── Guides / From the Archive ─── */}
      <section className={styles.guidesSection}>
        <p className={styles.guidesSectionLabel}>From the Archive</p>
        <div className={styles.guidesGrid}>
          <button className={styles.guideCard}>
            <span className={styles.guideIndex}>01</span>
            <h3 className={styles.guideTitle}>Buying Safely</h3>
            <p className={styles.guideDesc}>Learn how to verify authentic fragrances and protect yourself as a buyer.</p>
            <span className={styles.guideCta}>Read Guide <ChevronRightIcon /></span>
          </button>
          <button className={styles.guideCard}>
            <span className={styles.guideIndex}>02</span>
            <h3 className={styles.guideTitle}>ISO Protocol</h3>
            <p className={styles.guideDesc}>Best practices for making successful ISO requests and finding rare gems.</p>
            <span className={styles.guideCta}>Read Guide <ChevronRightIcon /></span>
          </button>
          <button className={styles.guideCard} onClick={() => navigate('/register/seller-apply')}>
            <span className={styles.guideIndex}>03</span>
            <h3 className={styles.guideTitle}>Seller Standards</h3>
            <p className={styles.guideDesc}>The requirements and expectations for becoming a verified community seller.</p>
            <span className={styles.guideCta}>Read Guide <ChevronRightIcon /></span>
          </button>
        </div>
      </section>
    </div>
  )
}
