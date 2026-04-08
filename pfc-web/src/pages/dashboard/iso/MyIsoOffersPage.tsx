import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/context/AuthContext'
import { EmptyState } from '@/components/ui/EmptyState'
import { formatPkr, timeAgo } from '@/lib/format'
import styles from './MyIsoOffersPage.module.css'

interface MyIsoOffer {
  id: string
  iso_id: string
  offer_amount: number | null
  message: string | null
  status: 'pending' | 'accepted' | 'declined' | 'withdrawn'
  created_at: string
  listings: {
    id: string
    fragrance_name: string
    brand: string
    sale_post_number: string
    status: string
    profiles: {
      display_name: string
      city: string
      avatar_url: string | null
    } | null
  } | null
}

type TabFilter = 'All' | 'Pending' | 'Accepted' | 'Declined' | 'Withdrawn'
const tabs: TabFilter[] = ['All', 'Pending', 'Accepted', 'Declined', 'Withdrawn']

export function MyIsoOffersPage() {
  const navigate = useNavigate()
  const { profile, loading: authLoading } = useAuth()
  
  const [offers, setOffers] = useState<MyIsoOffer[]>([])
  const [activeTab, setActiveTab] = useState<TabFilter>('All')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!authLoading && !profile) navigate('/login', { replace: true })
  }, [authLoading, profile, navigate])

  useEffect(() => {
    if (!profile) return
    let isMounted = true

    async function fetchOffers() {
      setLoading(true)
      setError(null)

      const { data, error: err } = await supabase
        .from('iso_offers')
        .select(`
          id, iso_id, offer_amount, message, status, created_at,
          listings!iso_id (
            id, fragrance_name, brand, sale_post_number, status,
            profiles!seller_id (display_name, city, avatar_url)
          )
        `)
        .eq('seller_id', profile!.id)
        .order('created_at', { ascending: false })

      if (isMounted) {
        if (err) {
          setError('Failed to load your ISO offers. Please try again.')
        } else {
          setOffers((data as unknown as MyIsoOffer[]) ?? [])
        }
        setLoading(false)
      }
    }

    fetchOffers()
    return () => { isMounted = false }
  }, [profile])

  if (authLoading || !profile) return null

  const filtered = activeTab === 'All'
    ? offers
    : offers.filter(o => o.status === activeTab.toLowerCase())

  const getEmptyState = () => {
    switch (activeTab) {
      case 'All': return { title: 'No offers yet', desc: 'Browse the ISO board and submit your first offer.', action: true }
      case 'Pending': return { title: 'No pending offers', desc: 'Pending offers awaiting buyer responses will appear here.' }
      case 'Accepted': return { title: 'No accepted offers', desc: 'Offers accepted by buyers will appear here.' }
      case 'Declined': return { title: 'No declined offers', desc: 'Offers declined by buyers will appear here.' }
      case 'Withdrawn': return { title: 'No withdrawn offers', desc: 'Offers you have withdrawn will appear here.' }
      default: return { title: 'No offers', desc: '' }
    }
  }
  const emptyState = getEmptyState()

  return (
    <div className={styles.page}>
      <div className={styles.tabsWrap}>
        <div className={styles.tabs}>
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
      </div>

      <div className={styles.content}>
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
                <path d="M4 7v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V7L12 12 4 7z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                <path d="M4 7l8 5 8-5c0-1.1-.9-2-2-2H6c-1.1 0-2 .9-2 2z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            }
            title={emptyState.title}
            description={emptyState.desc}
          >
            {emptyState.action && (
              <button 
                className={styles.browseBtn}
                onClick={() => navigate('/iso')}
              >
                Browse ISO Board
              </button>
            )}
          </EmptyState>
        ) : (
          <div className={styles.list}>
            {filtered.map(o => {
              const post = o.listings
              if (!post) return null
              const isInactive = post.status !== 'Published'
              const posterName = post.profiles?.display_name ?? 'Unknown Member'
              const city = post.profiles?.city ?? ''

              return (
                <button
                  key={o.id}
                  className={`${styles.offerRow} ${o.status === 'pending' ? styles.offerRowPending : ''} ${isInactive ? styles.offerRowInactive : ''}`}
                  onClick={() => navigate(`/iso/${post.id}`)}
                >
                  <div className={styles.rowLeft}>
                    <div className={styles.topMeta}>
                      <span className={`${styles.statusBadge} ${styles['status' + o.status.charAt(0).toUpperCase() + o.status.slice(1)]}`}>
                        {o.status.toUpperCase()}
                      </span>
                    </div>
                    <h3 className={styles.isoName}>{post.fragrance_name}</h3>
                    <p className={styles.isoBrand}>{post.brand}</p>
                    <p className={styles.meta}>
                      ISO by {posterName}{city ? ` · ${city}` : ''}
                    </p>
                    <p className={styles.metaTime}>{timeAgo(o.created_at)}</p>
                  </div>

                  <div className={styles.rowRight}>
                    {o.offer_amount ? (
                      <span className={styles.amountChip}>{formatPkr(o.offer_amount)}</span>
                    ) : (
                      <span className={`${styles.amountChip} ${styles.chipMuted}`}>Flexible</span>
                    )}
                    <span className={styles.chevron}>
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M9 18l6-6-6-6" />
                      </svg>
                    </span>
                  </div>
                </button>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}
