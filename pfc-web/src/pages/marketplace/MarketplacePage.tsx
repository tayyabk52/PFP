import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { useSearchParams } from 'react-router-dom'
import { ListingCard } from '@/components/cards/ListingCard'
import { EmptyState } from '@/components/ui/EmptyState'
import styles from './MarketplacePage.module.css'

// ─── Types ─────────────────────────────────────────────────────────────────────

type FilterType = 'All' | 'Full Bottle' | 'Decant/Split' | 'Swap' | 'Auction'

interface Listing {
  id: string
  sale_post_number: number
  fragrance_name: string
  brand: string
  price_pkr: number
  listing_type: string
  condition: string | null
  size_ml: number | null
  seller_id: string
  fragrance_family: string | null
  condition_notes: string | null
  vintage_year: number | null
  hashtags: string[] | null
  listing_photos: { file_url: string; display_order: number }[]
  listing_variants: { id: string; size_ml: number; price_pkr: number; display_order: number }[]
  profiles: {
    id: string
    display_name: string | null
    avatar_url: string | null
    city: string | null
    role: string
    transaction_count: number
    pfc_seller_code: string | null
  } | null
}

const FILTER_TYPES: FilterType[] = ['All', 'Full Bottle', 'Decant/Split', 'Swap', 'Auction']

// ─── MarketplacePage ───────────────────────────────────────────────────────────

export function MarketplacePage() {
  const [listings, setListings] = useState<Listing[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [search, setSearch] = useState('')
  const [activeType, setActiveType] = useState<FilterType>('All')
  const [searchParams] = useSearchParams()
  const tagParam = searchParams.get('tag')

  useEffect(() => {
    async function fetchListings() {
      setLoading(true)
      setError(null)
      const { data, error: err } = await supabase
        .from('listings')
        .select('id, sale_post_number, seller_id, listing_type, fragrance_name, brand, size_ml, condition, price_pkr, status, fragrance_family, condition_notes, vintage_year, hashtags, listing_photos(file_url, display_order), listing_variants(id, size_ml, price_pkr, display_order), profiles(id, display_name, avatar_url, city, role, transaction_count, pfc_seller_code)')
        .eq('status', 'Published')
        .neq('listing_type', 'ISO')
        .order('created_at', { ascending: false })

      if (err) {
        setError('Unable to load listings. Please try again.')
      } else {
        setListings((data as unknown as Listing[]) ?? [])
      }
      setLoading(false)
    }
    fetchListings()
  }, [])

  const filtered = listings.filter(l => {
    if (activeType !== 'All' && l.listing_type !== activeType) return false
    if (tagParam && !(l.hashtags && l.hashtags.includes(tagParam))) return false
    if (search) {
      const q = search.toLowerCase()
      return l.fragrance_name.toLowerCase().includes(q) || l.brand.toLowerCase().includes(q)
    }
    return true
  })

  return (
    <div className={styles.page}>
      {/* Filter bar */}
      <div className={styles.filterBar}>
        <div className={styles.filterLeft}>
          <div className={styles.searchWrap}>
            <svg className={styles.searchIcon} width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
              <circle cx="7" cy="7" r="5" stroke="currentColor" strokeWidth="1.5" />
              <path d="M11 11l3 3" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
            </svg>
            <input
              className={styles.searchInput}
              type="search"
              placeholder="Search fragrance or brand…"
              value={search}
              onChange={e => setSearch(e.target.value)}
              aria-label="Search listings"
            />
          </div>
          <div className={styles.pills}>
            {FILTER_TYPES.map(t => (
              <button
                key={t}
                className={`${styles.pill} ${activeType === t ? styles.pillActive : ''}`}
                onClick={() => setActiveType(t)}
              >
                {t}
              </button>
            ))}
          </div>
          {tagParam && (
            <div className={styles.activeTagFilter}>
              <span className={styles.tagLabel}>Filtering by tag:</span>
              <span className={styles.tagPill}>#{tagParam}</span>
            </div>
          )}
        </div>
        {!loading && !error && (
          <span className={styles.resultCount}>{filtered.length} listing{filtered.length !== 1 ? 's' : ''}</span>
        )}
      </div>

      {/* Content */}
      {loading ? (
        <div className={styles.spinnerWrap}>
          <div className={styles.spinner} />
        </div>
      ) : error ? (
        <p className={styles.errorMsg}>{error}</p>
      ) : filtered.length === 0 ? (
        <EmptyState
          icon={
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <path d="M3 6h18M3 12h18M3 18h18" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
            </svg>
          }
          title="No listings found"
          description={search || activeType !== 'All' ? 'Try adjusting your search or filter.' : 'No listings have been published yet.'}
        />
      ) : (
        <div className={styles.grid}>
          {filtered.map(l => {
            const photos = [...(l.listing_photos ?? [])].sort((a, b) => a.display_order - b.display_order)
            const variants = [...(l.listing_variants ?? [])].sort((a, b) => a.display_order - b.display_order)
            const firstVariant = variants[0]
            return (
              <ListingCard
                key={l.id}
                id={l.id}
                fragranceName={l.fragrance_name}
                brand={l.brand}
                pricePkr={firstVariant?.price_pkr ?? l.price_pkr}
                listingType={l.listing_type}
                condition={l.condition ?? undefined}
                photoUrl={photos[0]?.file_url}
                sizeMl={variants.length === 1 ? firstVariant?.size_ml : null}
                variantCount={variants.length || 1}
                sellerName=""
              />
            )
          })}
        </div>
      )}
    </div>
  )
}
