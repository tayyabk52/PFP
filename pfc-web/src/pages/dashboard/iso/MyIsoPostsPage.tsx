import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/context/AuthContext'
import { formatPkr, timeAgo } from '@/lib/format'
import { EmptyState } from '@/components/ui/EmptyState'
import styles from './MyIsoPostsPage.module.css'

// ─── Types ─────────────────────────────────────────────────────────────────────

type TabStatus = 'All' | 'Published' | 'Sold' | 'Draft'

interface IsoPost {
  id: string
  sale_post_number: number
  fragrance_name: string
  brand: string
  size_ml: number
  price_pkr: number
  status: string
  created_at: string
  published_at: string | null
}

const TABS: TabStatus[] = ['All', 'Published', 'Sold', 'Draft']

// ─── MyIsoPostsPage ────────────────────────────────────────────────────────────

export function MyIsoPostsPage() {
  const navigate = useNavigate()
  const { profile } = useAuth()
  const [posts, setPosts] = useState<IsoPost[]>([])
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState<TabStatus>('All')

  useEffect(() => {
    if (!profile) return
    async function fetchPosts() {
      setLoading(true)
      const { data } = await supabase
        .from('listings')
        .select('id, sale_post_number, fragrance_name, brand, size_ml, price_pkr, status, created_at, published_at')
        .eq('seller_id', profile!.id)
        .eq('listing_type', 'ISO')
        .neq('status', 'Deleted')
        .neq('status', 'Removed')
        .order('created_at', { ascending: false })
      setPosts((data as IsoPost[]) ?? [])
      setLoading(false)
    }
    fetchPosts()
  }, [profile])

  const filtered = activeTab === 'All' ? posts : posts.filter(p => p.status === activeTab)

  const emptyMessages: Record<TabStatus, { title: string; desc: string }> = {
    All: { title: 'No ISO posts yet', desc: 'Post an ISO request to find the fragrances you\'re looking for.' },
    Published: { title: 'No active requests', desc: 'Your published ISO requests will appear here.' },
    Sold: { title: 'No fulfilled requests', desc: 'ISO posts marked as sold/fulfilled appear here.' },
    Draft: { title: 'No drafts', desc: 'Saved drafts of your ISO requests will appear here.' },
  }

  const statusColors: Record<string, string> = {
    Published: styles.statusPublished,
    Draft: styles.statusDraft,
    Sold: styles.statusFulfilled,
    Expired: styles.statusDraft,
    Removed: styles.statusRemoved,
  }

  return (
    <div className={styles.page}>
      {/* Tab bar */}
      <div className={styles.tabs} role="tablist">
        {TABS.map(t => (
          <button
            key={t}
            role="tab"
            aria-selected={activeTab === t}
            className={`${styles.tab} ${activeTab === t ? styles.tabActive : ''}`}
            onClick={() => setActiveTab(t)}
          >
            {t}
          </button>
        ))}
      </div>

      {/* Content */}
      {loading ? (
        <div className={styles.spinnerWrap}>
          <div className={styles.spinner} />
        </div>
      ) : filtered.length === 0 ? (
        <EmptyState
          icon={
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="1.5" />
              <path d="M12 8v4M12 16h.01" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
            </svg>
          }
          title={emptyMessages[activeTab].title}
          description={emptyMessages[activeTab].desc}
          action={activeTab === 'All' ? { label: 'Post ISO Request', onClick: () => navigate('/iso/create') } : undefined}
        />
      ) : (
        <div className={styles.list}>
          {filtered.map(p => (
            <button
              key={p.id}
              className={styles.isoRow}
              onClick={() => navigate(`/iso/${p.id}`)}
              aria-label={`Open ${p.fragrance_name}`}
            >
              <div className={styles.isoLeft}>
                <div className={styles.isoMain}>
                  <h3 className={styles.isoName}>{p.fragrance_name}</h3>
                  <p className={styles.isoBrand}>{p.brand}</p>
                </div>
                <div className={styles.isoMeta}>
                  <span className={`${styles.statusBadge} ${statusColors[p.status] ?? ''}`}>
                    {p.status}
                  </span>
                  {p.price_pkr > 0 && (
                    <span className={styles.budgetChip}>{formatPkr(p.price_pkr)}</span>
                  )}
                  <span className={styles.sizeChip}>{p.size_ml}ml</span>
                </div>
                <p className={styles.timeAgo}>{timeAgo(p.created_at)}</p>
              </div>
              <span className={styles.editBtn} aria-hidden="true">
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                  <path d="M6 4l4 4-4 4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </span>
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
