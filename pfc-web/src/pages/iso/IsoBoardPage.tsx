import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/context/AuthContext'
import { IsoCard } from '@/components/cards/IsoCard'
import { EmptyState } from '@/components/ui/EmptyState'
import styles from './IsoBoardPage.module.css'

// ─── Types ─────────────────────────────────────────────────────────────────────

interface IsoPost {
  id: string
  sale_post_number: number
  seller_id: string
  fragrance_name: string
  brand: string
  size_ml: number
  price_pkr: number
  condition_notes: string | null
  created_at: string
  profiles: {
    id: string
    display_name: string
    city: string
    avatar_url: string | null
    transaction_count: number
    pfc_seller_code: string | null
  }
}

// ─── IsoBoardPage ──────────────────────────────────────────────────────────────

export function IsoBoardPage() {
  const navigate = useNavigate()
  const { profile } = useAuth()
  const [posts, setPosts] = useState<IsoPost[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [search, setSearch] = useState('')
  const [showFilters, setShowFilters] = useState(false)
  const [sort, setSort] = useState<'newest' | 'oldest' | 'budget_asc' | 'budget_desc'>('newest')
  const [minSize, setMinSize] = useState('')
  const [maxBudget, setMaxBudget] = useState('')

  useEffect(() => {
    async function fetchPosts() {
      setLoading(true)
      setError(null)
      const { data, error: err } = await supabase
        .from('listings')
        .select('id, sale_post_number, seller_id, fragrance_name, brand, size_ml, price_pkr, condition_notes, created_at, profiles(id, display_name, avatar_url, city, transaction_count, pfc_seller_code)')
        .eq('listing_type', 'ISO')
        .eq('status', 'Published')
        .order('created_at', { ascending: false })

      if (err) {
        setError('Unable to load ISO posts. Please try again.')
      } else {
        setPosts((data as unknown as IsoPost[]) ?? [])
      }
      setLoading(false)
    }
    fetchPosts()
  }, [])

  let filtered = posts

  if (search) {
    const q = search.toLowerCase()
    filtered = filtered.filter(p => p.fragrance_name.toLowerCase().includes(q) || p.brand.toLowerCase().includes(q))
  }

  if (minSize) {
    const s = parseInt(minSize) || 0
    filtered = filtered.filter(p => p.size_ml >= s)
  }

  if (maxBudget) {
    const b = parseInt(maxBudget) || 0
    // 0 budget_pkr means flexible. Flexible is technically anything, but when filtering by maximum, we typically only include items that strictly match the tight budget constraint, or flexible items.
    filtered = filtered.filter(p => p.price_pkr === 0 || p.price_pkr <= b)
  }

  filtered.sort((a, b) => {
    switch (sort) {
      case 'oldest': return new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
      case 'budget_asc': {
        const valA = a.price_pkr === 0 ? Infinity : a.price_pkr
        const valB = b.price_pkr === 0 ? Infinity : b.price_pkr
        return valA - valB
      }
      case 'budget_desc': {
        const valA = a.price_pkr === 0 ? Infinity : a.price_pkr
        const valB = b.price_pkr === 0 ? Infinity : b.price_pkr
        return valB - valA
      }
      case 'newest':
      default:
        return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    }
  })

  return (
    <div className={styles.page}>
      {/* Header */}
      <div className={styles.headerRow}>
        <div className={styles.searchWrap}>
          <svg className={styles.searchIcon} width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
            <circle cx="7" cy="7" r="5" stroke="currentColor" strokeWidth="1.5" />
            <path d="M11 11l3 3" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
          </svg>
          <input
            className={styles.searchInput}
            type="search"
            placeholder="Search by fragrance or brand…"
            value={search}
            onChange={e => setSearch(e.target.value)}
            aria-label="Search ISO posts"
          />
        </div>
        
        <button 
          className={`${styles.filterToggleBtn} ${showFilters ? styles.filterToggleActive : ''}`}
          onClick={() => setShowFilters(!showFilters)}
          aria-expanded={showFilters}
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
            <line x1="4" y1="6" x2="20" y2="6" />
            <line x1="8" y1="12" x2="16" y2="12" />
            <line x1="10" y1="18" x2="14" y2="18" />
          </svg>
          Filters
        </button>

        {(profile?.role === 'member' || profile?.role === 'seller') && (
          <div className={styles.actionsWrap}>
            <button
              className={styles.viewBtn}
              onClick={() => navigate('/dashboard/iso')}
            >
              My ISOs
            </button>
            <button
              className={styles.postBtn}
              onClick={() => navigate('/iso/create')}
            >
              Post ISO Request
            </button>
          </div>
        )}
      </div>

      {showFilters && (
        <div className={styles.filterPanel}>
          <div className={styles.filterCol}>
            <label className={styles.filterLabel}>Sort By</label>
            <select className={styles.filterSelect} value={sort} onChange={e => setSort(e.target.value as any)}>
              <option value="newest">Newest First</option>
              <option value="oldest">Oldest First</option>
              <option value="budget_asc">Budget: Low to High</option>
              <option value="budget_desc">Budget: High to Low</option>
            </select>
          </div>
          <div className={styles.filterCol}>
            <label className={styles.filterLabel}>Budget Range (PKR)</label>
            <input 
              className={styles.filterInput} 
              type="number" 
              placeholder="Max budget (any)" 
              value={maxBudget} 
              onChange={e => setMaxBudget(e.target.value)}
              min={0}
            />
          </div>
          <div className={styles.filterCol}>
            <label className={styles.filterLabel}>Size (ml)</label>
            <input 
              className={styles.filterInput} 
              type="number" 
              placeholder="Min size (any)" 
              value={minSize} 
              onChange={e => setMinSize(e.target.value)}
              min={1}
            />
          </div>
          <div className={styles.filterActions}>
            <button className={styles.clearBtn} onClick={() => { setSort('newest'); setMaxBudget(''); setMinSize('') }}>Clear Filters</button>
          </div>
        </div>
      )}

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
              <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="1.5" />
              <path d="M12 8v4M12 16h.01" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
            </svg>
          }
          title="No ISO requests yet"
          description={search ? 'No results match your search.' : 'Be the first to post an ISO request for a fragrance you\'re looking for.'}
        />
      ) : (
        <div className={styles.grid}>
          {filtered.map(p => (
            <IsoCard
              key={p.id}
              id={p.id}
              fragranceName={p.fragrance_name}
              brand={p.brand}
              sizeMl={p.size_ml}
              budgetPkr={p.price_pkr}
              posterName={p.profiles?.display_name ?? 'Member'}
              createdAt={p.created_at}
            />
          ))}
        </div>
      )}
    </div>
  )
}
