import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { SellerCard } from '@/components/cards/SellerCard'
import { EmptyState } from '@/components/ui/EmptyState'
import styles from './SellersPage.module.css'

// ─── Types ─────────────────────────────────────────────────────────────────────

interface SellerProfile {
  id: string
  display_name: string
  city: string
  transaction_count: number
  avg_rating: number
  rating_count: number
  avatar_url: string | null
  pfc_seller_code: string | null
  is_legacy_fb_seller: boolean
  verified_at: string | null
  created_at: string
}

// ─── SellersPage ───────────────────────────────────────────────────────────────

export function SellersPage() {
  const [sellers, setSellers] = useState<SellerProfile[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [search, setSearch] = useState('')

  useEffect(() => {
    async function fetchSellers() {
      setLoading(true)
      setError(null)
      const { data, error: err } = await supabase
        .from('profiles')
        .select('id, display_name, city, avatar_url, transaction_count, avg_rating, rating_count, pfc_seller_code, is_legacy_fb_seller, verified_at, created_at')
        .eq('role', 'seller')
        .order('transaction_count', { ascending: false })

      if (err) {
        setError('Unable to load sellers. Please try again.')
      } else {
        setSellers((data as SellerProfile[]) ?? [])
      }
      setLoading(false)
    }
    fetchSellers()
  }, [])

  const filtered = search
    ? sellers.filter(s => s.display_name.toLowerCase().includes(search.toLowerCase()) || s.city?.toLowerCase().includes(search.toLowerCase()))
    : sellers

  return (
    <div className={styles.page}>
      {/* Search bar */}
      <div className={styles.searchRow}>
        <div className={styles.searchWrap}>
          <svg className={styles.searchIcon} width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
            <circle cx="7" cy="7" r="5" stroke="currentColor" strokeWidth="1.5" />
            <path d="M11 11l3 3" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
          </svg>
          <input
            className={styles.searchInput}
            type="search"
            placeholder="Search sellers by name or city…"
            value={search}
            onChange={e => setSearch(e.target.value)}
            aria-label="Search sellers"
          />
        </div>
        {!loading && !error && (
          <span className={styles.count}>{filtered.length} verified seller{filtered.length !== 1 ? 's' : ''}</span>
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
              <circle cx="12" cy="8" r="4" stroke="currentColor" strokeWidth="1.5" />
              <path d="M4 20c0-3.314 3.582-6 8-6s8 2.686 8 6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
            </svg>
          }
          title="No sellers found"
          description={search ? 'No sellers match your search.' : 'No verified sellers yet.'}
        />
      ) : (
        <div className={styles.grid}>
          {filtered.map(s => (
            <SellerCard
              key={s.id}
              id={s.id}
              displayName={s.display_name}
              city={s.city}
              transactionCount={s.transaction_count ?? 0}
              avgRating={s.avg_rating ?? 0}
              ratingCount={s.rating_count ?? 0}
              avatarUrl={s.avatar_url ?? undefined}
              pfcSellerCode={s.pfc_seller_code ?? undefined}
              isLegacyFbSeller={s.is_legacy_fb_seller}
            />
          ))}
        </div>
      )}
    </div>
  )
}
