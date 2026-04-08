import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/context/AuthContext'
import { initials, timeAgo } from '@/lib/format'
import { ListingCard } from '@/components/cards/ListingCard'
import { IsoCard } from '@/components/cards/IsoCard'
import { EmptyState } from '@/components/ui/EmptyState'
import { ReportModal } from '@/components/ui/ReportModal'
import styles from './SellerProfilePage.module.css'

// ─── Types ─────────────────────────────────────────────────────────────────────

interface SellerProfile {
  id: string
  display_name: string
  city: string
  avatar_url: string | null
  pfc_seller_code: string | null
  is_legacy_fb_seller: boolean
  transaction_count: number
  avg_rating: number
  rating_count: number
  verified_at: string | null
  created_at: string
  role: string
}

interface Listing {
  id: string
  fragrance_name: string
  brand: string
  price_pkr: number
  listing_type: string
  condition: string | null
  size_ml: number
  seller_id: string
  listing_photos: { file_url: string; display_order: number }[]
}

interface IsoPost {
  id: string
  fragrance_name: string
  brand: string
  size_ml: number
  price_pkr: number
  created_at: string
  profiles: { display_name: string; city: string; avatar_url: string | null }
}

interface Review {
  id: string
  rating: number
  comment: string
  submitted_at: string
  reviewer_display_name: string | null
  reviewer_avatar_url: string | null
  fragrance_name: string | null
  brand: string | null
}

// ─── StarRow ───────────────────────────────────────────────────────────────────

function StarRow({ rating }: { rating: number }) {
  return (
    <div className={styles.starRow} aria-label={`${rating} out of 5`}>
      {[1, 2, 3, 4, 5].map(i => (
        <svg key={i} width="12" height="12" viewBox="0 0 10 10" fill={i <= rating ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="0.5" aria-hidden="true" className={i <= rating ? styles.starFilled : styles.starEmpty}>
          <path d="M5 1l1.12 2.27L8.5 3.635l-1.75 1.705.413 2.41L5 6.545l-2.163 1.205.413-2.41L1.5 3.635l2.38-.365L5 1z" />
        </svg>
      ))}
    </div>
  )
}

// ─── SellerProfilePage ─────────────────────────────────────────────────────────

export function SellerProfilePage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { profile: myProfile } = useAuth()
  const [seller, setSeller] = useState<SellerProfile | null>(null)
  const [listings, setListings] = useState<Listing[]>([])
  const [isoPosts, setIsoPosts] = useState<IsoPost[]>([])
  const [reviews, setReviews] = useState<Review[]>([])
  const [reportModalOpen, setReportModalOpen] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!id) return
    async function fetchProfile() {
      setLoading(true)
      setError(null)

      const [profileRes, listingsRes, isoRes, reviewsRes] = await Promise.all([
        supabase
          .from('profiles')
          .select('id, display_name, city, avatar_url, transaction_count, avg_rating, rating_count, pfc_seller_code, is_legacy_fb_seller, verified_at, created_at, role')
          .eq('id', id)
          .single(),

        supabase
          .from('listings')
          .select('id, fragrance_name, brand, price_pkr, listing_type, condition, size_ml, seller_id, listing_photos(file_url, display_order)')
          .eq('seller_id', id)
          .eq('status', 'Published')
          .neq('listing_type', 'ISO')
          .order('created_at', { ascending: false }),

        supabase
          .from('listings')
          .select('id, fragrance_name, brand, size_ml, price_pkr, created_at, profiles(display_name, city, avatar_url)')
          .eq('seller_id', id)
          .eq('listing_type', 'ISO')
          .eq('status', 'Published')
          .order('created_at', { ascending: false }),

        supabase
          .from('reviews')
          .select('id, rating, comment, submitted_at, reviewer:profiles!reviewer_id(display_name, avatar_url), listings!listing_id(fragrance_name, brand)')
          .eq('seller_id', id)
          .order('submitted_at', { ascending: false }),
      ])

      if (profileRes.error || !profileRes.data) {
        setError('Seller profile not found.')
        setLoading(false)
        return
      }

      setSeller(profileRes.data as unknown as SellerProfile)
      setListings((listingsRes.data as unknown as Listing[]) ?? [])
      setIsoPosts((isoRes.data as unknown as IsoPost[]) ?? [])

      // Flatten the nested review join
      const rawReviews = (reviewsRes.data ?? []) as unknown as Array<{
        id: string
        rating: number
        comment: string
        submitted_at: string
        reviewer: { display_name: string; avatar_url: string | null } | null
        listings: { fragrance_name: string; brand: string } | null
      }>
      setReviews(rawReviews.map(r => ({
        id: r.id,
        rating: r.rating,
        comment: r.comment,
        submitted_at: r.submitted_at,
        reviewer_display_name: r.reviewer?.display_name ?? null,
        reviewer_avatar_url: r.reviewer?.avatar_url ?? null,
        fragrance_name: r.listings?.fragrance_name ?? null,
        brand: r.listings?.brand ?? null,
      })))
      setLoading(false)
    }
    fetchProfile()
  }, [id])

  if (loading) {
    return (
      <div className={styles.spinnerWrap}>
        <div className={styles.spinner} />
      </div>
    )
  }

  if (error || !seller) {
    return (
      <div className={styles.errorWrap}>
        <p className={styles.errorMsg}>{error ?? 'Seller not found.'}</p>
        <button className={styles.backBtn} onClick={() => navigate('/sellers')}>← Back to Sellers</button>
      </div>
    )
  }

  const sellerInitials = initials(seller.display_name)
  const isOwnProfile = myProfile?.id === seller.id
  const memberSince = new Date(seller.created_at).getFullYear()

  return (
    <div className={styles.page}>
      <div className={styles.layout}>
        {/* ── Left (identity) ── */}
        <div className={styles.leftCol}>
          <div className={styles.identityCard}>
            <div className={styles.avatarWrap}>
              {seller.avatar_url ? (
                <img src={seller.avatar_url} alt={seller.display_name} className={styles.avatarImg} />
              ) : (
                <div className={styles.avatarInitials} aria-hidden="true">{sellerInitials}</div>
              )}
            </div>

            <h1 className={styles.displayName}>{seller.display_name}</h1>

            <div className={styles.badgeRow}>
              <span className={styles.verifiedBadge}>
                <svg width="9" height="9" viewBox="0 0 10 10" fill="none" aria-hidden="true">
                  <path d="M2 5.2L4.1 7.5L8 3" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
                Verified Seller
              </span>
              {seller.is_legacy_fb_seller && (
                <span className={styles.legacyBadge}>Legacy Seller</span>
              )}
            </div>

            {seller.pfc_seller_code && (
              <p className={styles.sellerCode}>{seller.pfc_seller_code}</p>
            )}

            <p className={styles.cityMeta}>{seller.city} · Member since {memberSince}</p>

            {/* Stats */}
            <div className={styles.statsGrid}>
              <div className={styles.statCell}>
                <span className={styles.statNum}>{listings.length}</span>
                <span className={styles.statLbl}>Listings</span>
              </div>
              <div className={styles.statCell}>
                <span className={styles.statNum}>{seller.transaction_count}</span>
                <span className={styles.statLbl}>Sold</span>
              </div>
              <div className={styles.statCell}>
                <span className={styles.statNum}>
                  {seller.rating_count > 0 ? seller.avg_rating.toFixed(1) : '—'}
                </span>
                <span className={styles.statLbl}>
                  {seller.rating_count > 0 ? `${seller.rating_count} Reviews` : 'Reviews'}
                </span>
              </div>
            </div>

            {!isOwnProfile && (
              <div className={styles.ctaGroup}>
                <button className={styles.messageBtn} onClick={() => navigate('/dashboard/messages')}>
                  Message Seller
                </button>
                <button 
                  className={styles.reportLinkBtn}
                  onClick={() => setReportModalOpen(true)}
                >
                  Report User
                </button>
              </div>
            )}
          </div>
        </div>

        {/* ── Right (listings + ISO + reviews) ── */}
        <div className={styles.rightCol}>
          {/* Active Listings */}
          <section className={styles.section}>
            <p className={styles.sectionLabel}>Active Listings</p>
            {listings.length === 0 ? (
              <EmptyState
                icon={
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                    <rect x="3" y="3" width="18" height="18" rx="2" stroke="currentColor" strokeWidth="1.5" />
                    <path d="M9 9h6M9 13h4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
                  </svg>
                }
                title="No active listings"
                description="This seller has no published listings at the moment."
              />
            ) : (
              <div className={styles.listingGrid}>
                {listings.map(l => {
                  const photos = [...(l.listing_photos ?? [])].sort((a, b) => a.display_order - b.display_order)
                  return (
                    <ListingCard
                      key={l.id}
                      id={l.id}
                      fragranceName={l.fragrance_name}
                      brand={l.brand}
                      pricePkr={l.price_pkr}
                      listingType={l.listing_type}
                      condition={l.condition ?? undefined}
                      photoUrl={photos[0]?.file_url}
                      sizeMl={l.size_ml}
                      sellerName={seller.display_name}
                    />
                  )
                })}
              </div>
            )}
          </section>

          {/* ISO Posts */}
          {isoPosts.length > 0 && (
            <section className={styles.section}>
              <p className={styles.sectionLabel}>ISO Requests</p>
              <div className={styles.isoList}>
                {isoPosts.map(p => (
                  <IsoCard
                    key={p.id}
                    id={p.id}
                    fragranceName={p.fragrance_name}
                    brand={p.brand}
                    sizeMl={p.size_ml}
                    budgetPkr={p.price_pkr}
                    posterName={p.profiles?.display_name ?? seller.display_name}
                    createdAt={p.created_at}
                  />
                ))}
              </div>
            </section>
          )}

          {/* Reviews */}
          {reviews.length > 0 && (
            <section className={styles.section}>
              <p className={styles.sectionLabel}>Reviews · {seller.rating_count}</p>
              <div className={styles.reviewList}>
                {reviews.map(r => {
                  const reviewerInitials = r.reviewer_display_name ? initials(r.reviewer_display_name) : '?'
                  return (
                    <div key={r.id} className={styles.reviewCard}>
                      <div className={styles.reviewHeader}>
                        <div className={styles.reviewerAvatar}>
                          {r.reviewer_avatar_url ? (
                            <img src={r.reviewer_avatar_url} alt={r.reviewer_display_name ?? ''} className={styles.reviewerAvatarImg} />
                          ) : reviewerInitials}
                        </div>
                        <div className={styles.reviewerInfo}>
                          <span className={styles.reviewerName}>{r.reviewer_display_name ?? 'Member'}</span>
                          {(r.fragrance_name || r.brand) && (
                            <span className={styles.reviewListing}>
                              {r.fragrance_name}{r.brand ? ` · ${r.brand}` : ''}
                            </span>
                          )}
                        </div>
                        <div className={styles.reviewMeta}>
                          <StarRow rating={r.rating} />
                          <span className={styles.reviewTime}>{timeAgo(r.submitted_at)}</span>
                        </div>
                      </div>
                      {r.comment && <p className={styles.reviewComment}>{r.comment}</p>}
                    </div>
                  )
                })}
              </div>
            </section>
          )}
        </div>
      </div>
      
      {/* ── Report modal ── */}
      {reportModalOpen && (
        <ReportModal
          type="user"
          targetId={seller.id}
          onClose={() => setReportModalOpen(false)}
        />
      )}
    </div>
  )
}
