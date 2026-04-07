import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/context/AuthContext'
import { formatPkr, initials } from '@/lib/format'
import styles from './MyListingsPage.module.css'

// ─── Types ────────────────────────────────────────────────────────────────────

interface ListingVariantSummary {
  id: string
  size_ml: number
  price_pkr: number
  quantity_available: number
  sold_at: string | null
}

interface MyListing {
  id: string
  sale_post_number: string
  fragrance_name: string
  brand: string
  listing_type: string
  price_pkr: number
  status: 'Draft' | 'Published' | 'Sold' | 'Expired'
  created_at: string
  published_at: string | null
  quantity_available: number | null
  listing_photos: { file_url: string; display_order: number }[]
  listing_variants: ListingVariantSummary[]
}

type StatusFilter = 'All' | 'Published' | 'Draft' | 'Sold' | 'Expired'

// ─── Icons ────────────────────────────────────────────────────────────────────

function PlusIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="5" x2="12" y2="19" />
      <line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  )
}

function ExternalLinkIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
      <polyline points="15 3 21 3 21 9" />
      <line x1="10" y1="14" x2="21" y2="3" />
    </svg>
  )
}

function SearchIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="8" />
      <line x1="21" y1="21" x2="16.65" y2="16.65" />
    </svg>
  )
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function getVariantSummary(variants: ListingVariantSummary[], price: number): string {
  if (!variants || variants.length === 0) {
    return formatPkr(price)
  }
  if (variants.length === 1) {
    return `${variants[0].size_ml}ml · ${formatPkr(variants[0].price_pkr)}`
  }
  const prices = variants.map(v => v.price_pkr)
  const minPrice = Math.min(...prices)
  return `${variants.length} variants · from ${formatPkr(minPrice)}`
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))

  if (diffDays === 0) return 'Today'
  if (diffDays === 1) return 'Yesterday'
  if (diffDays < 7) return `${diffDays}d ago`
  if (diffDays < 30) return `${Math.floor(diffDays / 7)}w ago`
  if (diffDays < 365) return `${Math.floor(diffDays / 30)}mo ago`
  return `${Math.floor(diffDays / 365)}y ago`
}

// ─── MyListingsPage ───────────────────────────────────────────────────────────

export function MyListingsPage() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const [listings, setListings] = useState<MyListing[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState<StatusFilter>('All')
  const [searchTerm, setSearchTerm] = useState('')

  useEffect(() => {
    if (!user?.id) return

    async function fetchListings() {
      setLoading(true)
      setError(null)

      const { data, error: err } = await supabase
        .from('listings')
        .select(`
          id, sale_post_number, fragrance_name, brand, listing_type,
          price_pkr, status, created_at, published_at, quantity_available,
          listing_photos(file_url, display_order),
          listing_variants(id, size_ml, price_pkr, quantity_available, sold_at)
        `)
        .eq('seller_id', user!.id)
        .not('status', 'in', '("Deleted","Removed")')
        .order('created_at', { ascending: false })

      if (err) {
        setError(err.message)
      } else {
        setListings((data as MyListing[]) || [])
      }

      setLoading(false)
    }

    fetchListings()
  }, [user?.id])

  const filteredListings = listings.filter(l => {
    const matchesTab = activeTab === 'All' || l.status === activeTab
    const matchesSearch =
      l.fragrance_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      l.brand.toLowerCase().includes(searchTerm.toLowerCase())
    return matchesTab && matchesSearch
  })

  const tabs: StatusFilter[] = ['All', 'Published', 'Draft', 'Sold', 'Expired']

  const emptyStateMessages: Record<StatusFilter, string> = {
    All: 'No listings yet. Create one to get started.',
    Published: 'No published listings yet.',
    Draft: 'No draft listings saved.',
    Sold: 'No sold listings.',
    Expired: 'No expired listings.',
  }

  return (
    <div className={styles.page}>
      <div className={styles.inner}>
        {/* ── Header ─────────────────────────────────────── */}
        <header className={styles.header}>
          <div className={styles.headerLeft}>
            <p className={styles.label}>SELLER ARCHIVE</p>
            <h1 className={styles.title}>My Listings</h1>
          </div>
          <button className={styles.newBtn} onClick={() => navigate('/marketplace/new')}>
            <PlusIcon />
            New Listing
          </button>
        </header>

        {/* ── Controls: Tabs & Search ────────────────────────────── */}
        <div className={styles.controlsBar}>
          <div className={styles.tabsBar}>
            {tabs.map(tab => (
              <button
                key={tab}
                className={`${styles.tab} ${activeTab === tab ? styles.tabActive : ''}`}
                onClick={() => setActiveTab(tab)}
              >
                {tab}
              </button>
            ))}
          </div>
          <div className={styles.searchWrap}>
            <SearchIcon />
            <input
              type="text"
              placeholder="Search listings..."
              className={styles.searchInput}
              value={searchTerm}
              onChange={e => setSearchTerm(e.target.value)}
            />
          </div>
        </div>

        {/* ── Content ────────────────────────────────────── */}
        {loading ? (
          <div className={styles.spinnerWrap}>
            <div className={styles.spinner} />
          </div>
        ) : error ? (
          <div className={styles.errorWrap}>
            <p className={styles.errorMsg}>{error}</p>
            <button className={styles.retryBtn} onClick={() => window.location.reload()}>
              Retry
            </button>
          </div>
        ) : filteredListings.length === 0 ? (
          <div className={styles.emptyState}>
            <p className={styles.emptyStateMsg}>{listings.length > 0 && searchTerm ? 'No listings found for your search.' : emptyStateMessages[activeTab]}</p>
          </div>
        ) : (
          <div className={styles.tableContainer}>
            <table className={styles.table}>
              <thead className={styles.thead}>
                <tr>
                  <th className={styles.th}>Item</th>
                  <th className={styles.th}>Type</th>
                  <th className={styles.th}>Variants & Price</th>
                  <th className={styles.th}>Status</th>
                  <th className={styles.th}>Created</th>
                  <th className={`${styles.th} ${styles.thAction}`}>Actions</th>
                </tr>
              </thead>
              <tbody className={styles.tbody}>
                {filteredListings.map(listing => {
                  const photos = [...(listing.listing_photos ?? [])].sort((a, b) => a.display_order - b.display_order)
                  const mainPhoto = photos[0]?.file_url ?? null
                  
                  return (
                    <tr key={listing.id} className={styles.tr}>
                      <td className={`${styles.td} ${styles.tdItem}`}>
                        <div className={styles.itemWrap}>
                          <div className={styles.thumbnail}>
                            {mainPhoto ? (
                              <img src={mainPhoto} alt={listing.fragrance_name} className={styles.thumbnailImg} />
                            ) : (
                              <div className={styles.thumbnailPlaceholder}>
                                {initials(listing.fragrance_name)}
                              </div>
                            )}
                            <div className={styles.postNumberChip}>{listing.sale_post_number}</div>
                          </div>
                          <div className={styles.itemInfo}>
                            <div className={styles.fragranceName} title={listing.fragrance_name}>
                              {listing.fragrance_name}
                            </div>
                            <div className={styles.brand}>{listing.brand}</div>
                          </div>
                        </div>
                      </td>
                      <td className={styles.td} data-label="Type">
                        <span className={styles.typeBadge}>{listing.listing_type}</span>
                      </td>
                      <td className={styles.td} data-label="Variants & Price">
                        <span className={styles.variantSummary}>
                          {getVariantSummary(listing.listing_variants, listing.price_pkr)}
                        </span>
                      </td>
                      <td className={styles.td} data-label="Status">
                        <span className={`${styles.statusBadge} ${styles[`status${listing.status}` as keyof typeof styles]}`}>
                          {listing.status}
                        </span>
                      </td>
                      <td className={styles.td} data-label="Created">
                        <span className={styles.meta}>{formatDate(listing.created_at)}</span>
                      </td>
                      <td className={`${styles.td} ${styles.tdAction}`}>
                        <div className={styles.actionRowTable}>
                          <button
                            className={styles.editBtnTable}
                            onClick={() => navigate(`/marketplace/${listing.id}/edit`)}
                          >
                            Edit
                          </button>
                          <button
                            className={styles.viewBtnTable}
                            onClick={() => navigate(`/marketplace/${listing.id}`)}
                            title="View in marketplace"
                          >
                            <ExternalLinkIcon />
                          </button>
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}
