import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/context/AuthContext'
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

function ChevronRightIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="9 18 15 12 9 6" />
    </svg>
  )
}

// ─── MemberDashboard ─────────────────────────────────────────────────────────

export function MemberDashboard() {
  const { profile } = useAuth()
  const navigate = useNavigate()

  const archiveNumber = (profile as any)?.created_at
    ? new Date((profile as any).created_at).getTime().toString().slice(-6)
    : '—'

  const displayName = profile?.display_name ?? 'Member'
  const isSeller = profile?.role === 'seller' || profile?.role === 'admin'

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
          <div className={styles.statCell}>
            <p className={styles.statLabel}>ISO Posts</p>
            {/* TODO: connect to data */}
            <p className={styles.statValue}>0</p>
          </div>
          <div className={styles.statCell}>
            <p className={styles.statLabel}>Reviews</p>
            {/* TODO: connect to data */}
            <p className={styles.statValue}>0</p>
          </div>
          <div className={styles.statCell}>
            <p className={styles.statLabel}>Unread</p>
            {/* TODO: connect to data */}
            <p className={styles.statValue}>0</p>
          </div>
          <div className={styles.statCell}>
            <p className={styles.statLabel}>Transactions</p>
            {/* TODO: connect to data */}
            <p className={styles.statValue}>0</p>
          </div>
        </div>
      </div>

      {/* ─── Main Grid ─── */}
      <div className={styles.mainGrid}>
        <div className={styles.leftCol}>
          {/* ─── Seller Quick Actions ─── */}
          {isSeller && (
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
                    <ShopIcon />
                  </div>
                  <div className={styles.actionCardText}>
                    <p className={styles.actionCardTitle}>My Listings</p>
                    <p className={styles.actionCardSub}>Manage your active listings</p>
                  </div>
                  <span className={styles.chevron}>
                    <ChevronRightIcon />
                  </span>
                </button>
              </div>
            </>
          )}

          {/* ─── ISO Quick Actions ─── */}
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
        </div>

        <div className={styles.rightCol}>
          {/* ─── Marketplace Pulse Card ─── */}
          <div className={styles.pulseCard}>
            <div className={styles.pulseCircle1} />
            <div className={styles.pulseCircle2} />
            <div className={styles.pulseHeader}>
              <span className={styles.pulseLabel}>Marketplace Pulse</span>
              <div className={styles.pulseLiveGroup}>
                <div className={styles.liveDot} />
                <span className={styles.liveText}>Live</span>
              </div>
            </div>
            <div className={styles.pulseStats}>
              <div className={styles.pulseStat}>
                {/* TODO: connect to data */}
                <span className={styles.pulseStatValue}>0</span>
                <span className={styles.pulseStatLabel}>Listings</span>
              </div>
              <div className={styles.pulseStat}>
                {/* TODO: connect to data */}
                <span className={styles.pulseStatValue}>0</span>
                <span className={styles.pulseStatLabel}>Active ISOs</span>
              </div>
              <div className={styles.pulseStat}>
                {/* TODO: connect to data */}
                <span className={styles.pulseStatValue}>0</span>
                <span className={styles.pulseStatLabel}>Sellers</span>
              </div>
            </div>
          </div>

          {/* ─── Become Seller CTA ─── */}
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
