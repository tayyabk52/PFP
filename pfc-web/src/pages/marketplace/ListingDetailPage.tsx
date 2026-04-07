import { useEffect, useState } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/context/AuthContext'
import { formatPkr, initials, timeAgo } from '@/lib/format'
import { ReportModal } from '@/components/ui/ReportModal'
import { AuctionPanel } from '@/components/ui/AuctionPanel'
import styles from './ListingDetailPage.module.css'

// ─── Types ─────────────────────────────────────────────────────────────────────

interface Review {
  id: string
  rating: number
  comment: string
  submitted_at: string
  reviewer_display_name: string | null
  reviewer_avatar_url: string | null
}

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

interface ListingVariant {
  id: string
  size_ml: number
  price_pkr: number
  quantity_available: number
  condition: string | null
  condition_notes: string | null
  variant_notes: string | null
  display_order: number
}

interface ListingDetail {
  id: string
  sale_post_number: string
  seller_id: string
  fragrance_name: string
  brand: string
  price_pkr: number
  listing_type: string
  condition: string | null
  condition_notes: string | null
  size_ml: number | null
  fragrance_family: string | null
  fragrance_notes: string | null
  vintage_year: number | null
  delivery_details: string | null
  quantity_available: number | null
  created_at: string
  auction_end_at: string | null
  hashtags: string[] | null
  listing_photos: { file_url: string; display_order: number }[]
  listing_variants: ListingVariant[]
  profiles: {
    id: string
    display_name: string
    city: string
    avatar_url: string | null
    pfc_seller_code: string | null
    transaction_count: number
    avg_rating: number
    rating_count: number
    is_legacy_fb_seller: boolean
    verified_at: string | null
  }
}

function formatType(type: string): string {
  if (type === 'Decant/Split') return 'Decant / Split'
  return type
}

// ─── ListingDetailPage ─────────────────────────────────────────────────────────

export function ListingDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { user } = useAuth()
  const [listing, setListing] = useState<ListingDetail | null>(null)
  const [reviews, setReviews] = useState<Review[]>([])
  const [reportModalOpen, setReportModalOpen] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activePhoto, setActivePhoto] = useState(0)
  const [msgLoading, setMsgLoading] = useState(false)
  const [selectedVariantId, setSelectedVariantId] = useState<string | null>(null)

  useEffect(() => {
    if (!id) return
    async function fetchListing() {
      setLoading(true)
      setError(null)
      const { data, error: err } = await supabase
        .from('listings')
        .select('id, sale_post_number, seller_id, listing_type, fragrance_name, brand, size_ml, condition, price_pkr, delivery_details, fragrance_family, fragrance_notes, vintage_year, condition_notes, quantity_available, created_at, auction_end_at, hashtags, listing_photos(file_url, display_order), listing_variants(id, size_ml, price_pkr, quantity_available, condition, condition_notes, variant_notes, display_order), profiles(id, display_name, avatar_url, city, role, transaction_count, avg_rating, rating_count, pfc_seller_code, is_legacy_fb_seller, verified_at)')
        .eq('id', id)
        .single()
      if (err || !data) {
        setError('Listing not found or unavailable.')
      } else {
        const d = data as unknown as ListingDetail
        setListing(d)
        // Default to first variant (sorted by display_order)
        const sorted = [...(d.listing_variants ?? [])].sort((a, b) => a.display_order - b.display_order)
        if (sorted.length > 0) setSelectedVariantId(sorted[0].id)

        // Fetch reviews
        const { data: revData } = await supabase
          .from('reviews')
          .select('id, rating, comment, submitted_at, reviewer:profiles!reviewer_id(display_name, avatar_url)')
          .eq('seller_id', d.seller_id)
          .order('submitted_at', { ascending: false })

        const rawReviews = (revData ?? []) as any[]
        setReviews(rawReviews.map(r => ({
          id: r.id,
          rating: r.rating,
          comment: r.comment,
          submitted_at: r.submitted_at,
          reviewer_display_name: r.reviewer?.display_name ?? null,
          reviewer_avatar_url: r.reviewer?.avatar_url ?? null,
        })))
      }
      setLoading(false)
    }
    fetchListing()
  }, [id])

  if (loading) {
    return <div className={styles.spinnerWrap}><div className={styles.spinner} /></div>
  }

  if (error || !listing) {
    return (
      <div className={styles.errorWrap}>
        <p className={styles.errorMsg}>{error ?? 'Listing not found.'}</p>
        <button className={styles.backBtn} onClick={() => navigate('/marketplace')}>← Back to Marketplace</button>
      </div>
    )
  }

  const photos = [...(listing.listing_photos ?? [])].sort((a, b) => a.display_order - b.display_order)
  const variants = [...(listing.listing_variants ?? [])].sort((a, b) => a.display_order - b.display_order)
  const hasVariants = variants.length > 0
  const activeVariant = variants.find(v => v.id === selectedVariantId) ?? variants[0] ?? null

  // Active values — variant wins over parent row where applicable
  const activePrice = activeVariant?.price_pkr ?? listing.price_pkr
  const activeSizeMl = activeVariant?.size_ml ?? listing.size_ml
  const activeCondition = activeVariant?.condition ?? listing.condition
  const activeConditionNotes = activeVariant?.condition_notes ?? listing.condition_notes
  const activeQty = activeVariant?.quantity_available ?? listing.quantity_available

  const seller = listing.profiles
  const sellerInitials = seller ? initials(seller.display_name) : '?'
  const isSwap = listing.listing_type === 'Swap'
  const isVerified = !!seller?.verified_at
  const isOwnListing = user?.id === listing.seller_id

  async function handleMessageSeller() {
    if (!user) { navigate('/login'); return }
    setMsgLoading(true)
    try {
      const { data: convoId } = await supabase.rpc('get_or_create_conversation', {
        p_other_user_id: listing!.seller_id,
      })
      if (convoId) {
        await supabase.rpc('add_listing_to_conversation', {
          p_conversation_id: convoId,
          p_listing_id: listing!.id,
          p_variant_id: selectedVariantId ?? null,
        })
        navigate(`/dashboard/messages?c=${convoId}`)
      }
    } finally {
      setMsgLoading(false)
    }
  }

  return (
    <div className={styles.page}>
      <div className={styles.inner}>

        {/* ── Hero header ── */}
        <div className={styles.hero}>
          <div className={styles.heroLeft}>
            <span className={styles.archiveLabel}>Archive Registry</span>
            <h1 className={styles.fragranceName}>{listing.fragrance_name}</h1>
          </div>
          <div className={styles.postNumberBox}>
            <span className={styles.postNumberBoxLabel}>Sale Post Number</span>
            <span className={styles.postNumberBoxValue}>{listing.sale_post_number}</span>
          </div>
        </div>

        {/* ── Main grid ── */}
        <div className={styles.mainGrid}>

          {/* ── Gallery (left 7/12) ── */}
          <div className={styles.galleryCol}>
            {/* Main image */}
            <div className={styles.mainImageWrap}>
              {photos.length > 0 ? (
                <img
                  src={photos[activePhoto]?.file_url}
                  alt={listing.fragrance_name}
                  className={styles.mainImage}
                />
              ) : (
                <div className={styles.imagePlaceholder}>
                  <span>{listing.fragrance_name.charAt(0)}</span>
                </div>
              )}
              {/* Badges */}
              <div className={styles.badges}>
                {isVerified && (
                  <div className={styles.badgeVerified}>
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                      <path d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" stroke="currentColor" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                    Verified Authentic
                  </div>
                )}
              </div>
            </div>

            {/* Thumbnail grid */}
            {photos.length > 1 && (
              <div className={styles.thumbGrid}>
                {photos.slice(1, 4).map((p, i) => (
                  <button
                    key={i + 1}
                    className={`${styles.thumbCell} ${activePhoto === i + 1 ? styles.thumbCellActive : ''}`}
                    onClick={() => setActivePhoto(i + 1)}
                    aria-label={`Photo ${i + 2}`}
                  >
                    <img src={p.file_url} alt="" />
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* ── Details sidebar (right 5/12) ── */}
          <div className={styles.detailsCol}>

            {/* Pricing card */}
            <div className={styles.pricingCard}>
              <div className={styles.pricingHeader}>
                <div className={styles.pricingLeft}>
                  <p className={styles.pricingBrand}>{listing.brand}</p>
                  <h3 className={styles.pricingType}>{formatType(listing.listing_type)}</h3>
                </div>
                <div className={styles.pricingRight}>
                  {isSwap ? (
                    <span className={styles.swapLabel}>Swap</span>
                  ) : (
                    <span className={styles.priceValue}>{formatPkr(activePrice)}</span>
                  )}
                  <p className={styles.priceCaption}>
                    {hasVariants && variants.length > 1 ? 'Price for selected size' : 'Listing Price'}
                  </p>
                </div>
              </div>

              {/* Variant size selector */}
              {hasVariants && variants.length > 1 && (
                <div className={styles.variantPills}>
                  {variants.map(v => (
                    <button
                      key={v.id}
                      className={`${styles.variantPill} ${v.id === selectedVariantId ? styles.variantPillActive : ''}`}
                      onClick={() => setSelectedVariantId(v.id)}
                    >
                      {v.size_ml}ml
                    </button>
                  ))}
                </div>
              )}

              <div className={styles.pricingDivider} />

              <div className={styles.detailsGrid}>
                {listing.fragrance_family && (
                  <div className={styles.detailCell}>
                    <p className={styles.detailLabel}>Fragrance Family</p>
                    <p className={styles.detailValue}>{listing.fragrance_family}</p>
                  </div>
                )}
                {listing.hashtags && listing.hashtags.length > 0 && (
                  <div className={`${styles.detailCell} ${styles.detailCellFull}`}>
                    <p className={styles.detailLabel}>Tags</p>
                    <div className={styles.pills}>
                      {listing.hashtags.map(t => (
                        <Link key={t} to={`/marketplace?tag=${encodeURIComponent(t)}`} className={styles.pill}>
                          #{t}
                        </Link>
                      ))}
                    </div>
                  </div>
                )}
                {activeSizeMl && (
                  <div className={styles.detailCell}>
                    <p className={styles.detailLabel}>Size</p>
                    <p className={styles.detailValue}>{activeSizeMl}ml</p>
                  </div>
                )}
                {listing.vintage_year && (
                  <div className={styles.detailCell}>
                    <p className={styles.detailLabel}>Vintage Year</p>
                    <p className={styles.detailValue}>{listing.vintage_year}</p>
                  </div>
                )}
                <div className={styles.detailCell}>
                  <p className={styles.detailLabel}>Listing Type</p>
                  <p className={styles.detailValue}>{formatType(listing.listing_type)}</p>
                </div>
                {activeQty != null && activeQty > 0 && (
                  <div className={styles.detailCell}>
                    <p className={styles.detailLabel}>Available</p>
                    <p className={styles.detailValue}>{activeQty} unit{activeQty !== 1 ? 's' : ''}</p>
                  </div>
                )}
                {activeCondition && (
                  <div className={`${styles.detailCell} ${styles.detailCellFull}`}>
                    <p className={styles.detailLabel}>Condition</p>
                    <p className={styles.detailValue}>
                      {activeCondition}
                      {activeConditionNotes ? ` — ${activeConditionNotes}` : ''}
                    </p>
                  </div>
                )}
                {activeVariant?.variant_notes && (
                  <div className={`${styles.detailCell} ${styles.detailCellFull}`}>
                    <p className={styles.detailLabel}>Variant Notes</p>
                    <p className={styles.detailValue}>{activeVariant.variant_notes}</p>
                  </div>
                )}
                {listing.delivery_details && (
                  <div className={`${styles.detailCell} ${styles.detailCellFull}`}>
                    <p className={styles.detailLabel}>Delivery & Shipping</p>
                    <p className={styles.detailValue}>{listing.delivery_details}</p>
                  </div>
                )}
              </div>
            </div>

            {/* Auction panel */}
            {listing.listing_type === 'Auction' && listing.auction_end_at && (
              <div className={styles.auctionWrap}>
                <AuctionPanel 
                  listingId={listing.id} 
                  auctionEndAt={listing.auction_end_at} 
                  basePrice={activePrice} 
                />
              </div>
            )}

            {/* Seller card */}
            {seller && (
              <Link to={`/sellers/${seller.id}`} className={styles.sellerCard}>
                <div className={styles.sellerAvatar}>
                  {seller.avatar_url ? (
                    <img src={seller.avatar_url} alt={seller.display_name} className={styles.sellerAvatarImg} />
                  ) : sellerInitials}
                </div>
                <div className={styles.sellerInfo}>
                  <div className={styles.sellerNameRow}>
                    <span className={styles.sellerName}>{seller.display_name}</span>
                    {isVerified && (
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" className={styles.sellerVerifiedIcon} aria-label="Verified">
                        <path d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      </svg>
                    )}
                  </div>
                  <p className={styles.sellerMeta}>
                    {seller.city} · {seller.transaction_count ?? 0} Successful Sales
                    {seller.rating_count > 0 ? ` · ★ ${seller.avg_rating.toFixed(1)}` : ''}
                  </p>
                </div>
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none" className={styles.sellerArrow} aria-hidden="true">
                  <path d="M6 4l4 4-4 4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </Link>
            )}

            {/* Security advisory */}
            <div className={styles.advisory}>
              <div className={styles.advisoryIcon}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/>
                  <line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
                </svg>
              </div>
              <div>
                <h5 className={styles.advisoryTitle}>Security Advisory</h5>
                <p className={styles.advisoryText}>
                  Always complete transactions through the PFC platform. Never share personal payment details outside of verified channels.
                </p>
              </div>
            </div>

            {/* CTA */}
            {!isOwnListing && (
              <div className={styles.ctaGroup}>
                <button className={styles.ctaBtn} onClick={handleMessageSeller} disabled={msgLoading}>
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                    <path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/>
                  </svg>
                  {msgLoading ? 'Opening…' : 'Message Seller'}
                </button>
                <button 
                  className={styles.reportLinkBtn}
                  onClick={() => setReportModalOpen(true)}
                >
                  Report this listing
                </button>
              </div>
            )}
          </div>
        </div>

        {/* ── Notes section ── */}
        {listing.fragrance_notes && (
          <div className={styles.notesSection}>
            <div className={styles.notesNarrative}>
              <h3 className={styles.notesNarrativeTitle}>The Olfactory Narrative</h3>
              <p className={styles.notesNarrativeText}>"{listing.fragrance_notes}"</p>
            </div>
            <div className={styles.notesComposition}>
              <h4 className={styles.notesCompositionTitle}>Fragrance Notes</h4>
              <p className={styles.notesCompositionText}>{listing.fragrance_notes}</p>
            </div>
          </div>
        )}

        {/* ── Reviews section ── */}
        {reviews.length > 0 && (
          <div className={styles.reviewsSection}>
            <h3 className={styles.reviewsTitle}>Seller Reviews ({seller?.rating_count ?? reviews.length})</h3>
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
          </div>
        )}

        {/* ── Report modal ── */}
        {reportModalOpen && (
          <ReportModal
            type="listing"
            targetId={listing.id}
            onClose={() => setReportModalOpen(false)}
          />
        )}

      </div>
    </div>
  )
}
