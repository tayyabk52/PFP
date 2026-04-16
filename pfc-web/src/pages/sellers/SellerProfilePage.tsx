import { useCallback, useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/context/AuthContext'
import { initials, timeAgo } from '@/lib/format'
import { ListingCard } from '@/components/cards/ListingCard'
import { IsoCard } from '@/components/cards/IsoCard'
import { EmptyState } from '@/components/ui/EmptyState'
import { ReportModal } from '@/components/ui/ReportModal'
import { ReviewModal } from '@/components/ui/ReviewModal'
import styles from './SellerProfilePage.module.css'

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

interface ReviewPhoto {
  id: string
  file_url: string
  path: string
}

interface Review {
  id: string
  listing_id: string
  rating: number
  comment: string
  submitted_at: string
  last_edited_at: string | null
  reviewer_display_name: string | null
  reviewer_avatar_url: string | null
  reviewer_id: string | null
  fragrance_name: string | null
  brand: string | null
  photos: ReviewPhoto[]
}

interface IsoPostRow {
  id: string
  fragrance_name: string
  brand: string
  size_ml: number
  price_pkr: number
  created_at: string
  profiles: { display_name: string; city: string; avatar_url: string | null }[] | null
}

interface ReviewRow {
  id: string
  listing_id: string
  rating: number
  comment: string
  submitted_at: string
  last_edited_at: string | null
  reviewer_id: string
  reviewer: { display_name: string; avatar_url: string | null }[] | null
  listings: { fragrance_name: string; brand: string }[] | null
  review_photos: ReviewPhoto[] | null
}

function StarRow({ rating }: { rating: number }) {
  return (
    <div className={styles.starRow} aria-label={`${rating} out of 5`}>
      {[1, 2, 3, 4, 5].map(index => (
        <svg
          key={index}
          width="12"
          height="12"
          viewBox="0 0 10 10"
          fill={index <= rating ? 'currentColor' : 'none'}
          stroke="currentColor"
          strokeWidth="0.5"
          aria-hidden="true"
          className={index <= rating ? styles.starFilled : styles.starEmpty}
        >
          <path d="M5 1l1.12 2.27L8.5 3.635l-1.75 1.705.413 2.41L5 6.545l-2.163 1.205.413-2.41L1.5 3.635l2.38-.365L5 1z" />
        </svg>
      ))}
    </div>
  )
}

function RatingDistribution({ reviews }: { reviews: Review[] }) {
  const total = reviews.length
  if (total === 0) return null

  const rows = [5, 4, 3, 2, 1].map(star => ({
    star,
    count: reviews.filter(review => review.rating === star).length,
  }))

  return (
    <div className={styles.ratingDistribution}>
      {rows.map(({ star, count }) => (
        <div key={star} className={styles.ratingDistRow}>
          <span className={styles.ratingDistLabel}>{'★'.repeat(star)}{'☆'.repeat(5 - star)}</span>
          <div className={styles.ratingDistBarWrap}>
            <div
              className={styles.ratingDistBar}
              style={{ width: `${total > 0 ? (count / total) * 100 : 0}%` }}
            />
          </div>
          <span className={styles.ratingDistCount}>{count}</span>
        </div>
      ))}
    </div>
  )
}

export function SellerProfilePage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { profile: myProfile } = useAuth()
  const [seller, setSeller] = useState<SellerProfile | null>(null)
  const [listings, setListings] = useState<Listing[]>([])
  const [isoPosts, setIsoPosts] = useState<IsoPost[]>([])
  const [reviews, setReviews] = useState<Review[]>([])
  const [reportModalOpen, setReportModalOpen] = useState(false)
  const [editingReview, setEditingReview] = useState<Review | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchProfile = useCallback(async () => {
    if (!id) return

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
        .select('id, listing_id, rating, comment, submitted_at, last_edited_at, reviewer_id, reviewer:profiles!reviewer_id(display_name, avatar_url), listings!listing_id(fragrance_name, brand), review_photos(id, file_url, path)')
        .eq('seller_id', id)
        .order('submitted_at', { ascending: false }),
    ])

    if (profileRes.error || !profileRes.data) {
      setError('Seller profile not found.')
      setLoading(false)
      return
    }

    setSeller(profileRes.data as unknown as SellerProfile)
    setListings((listingsRes.data as Listing[]) ?? [])
    setIsoPosts(
      ((isoRes.data ?? []) as unknown as IsoPostRow[]).map(post => ({
        id: post.id,
        fragrance_name: post.fragrance_name,
        brand: post.brand,
        size_ml: post.size_ml,
        price_pkr: post.price_pkr,
        created_at: post.created_at,
        profiles: post.profiles?.[0] ?? {
          display_name: '',
          city: '',
          avatar_url: null,
        },
      }))
    )

    const rawReviews = (reviewsRes.data ?? []) as unknown as ReviewRow[]

    setReviews(
      rawReviews.map(review => ({
        id: review.id,
        listing_id: review.listing_id,
        rating: review.rating,
        comment: review.comment,
        submitted_at: review.submitted_at,
        last_edited_at: review.last_edited_at,
        reviewer_id: review.reviewer_id,
        reviewer_display_name: review.reviewer?.[0]?.display_name ?? null,
        reviewer_avatar_url: review.reviewer?.[0]?.avatar_url ?? null,
        fragrance_name: review.listings?.[0]?.fragrance_name ?? null,
        brand: review.listings?.[0]?.brand ?? null,
        photos: review.review_photos ?? [],
      }))
    )

    setLoading(false)
  }, [id])

  useEffect(() => {
    fetchProfile()
  }, [fetchProfile])

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
        <button className={styles.backBtn} onClick={() => navigate('/sellers')}>
          ← Back to Sellers
        </button>
      </div>
    )
  }

  const sellerInitials = initials(seller.display_name)
  const isOwnProfile = myProfile?.id === seller.id
  const memberSince = new Date(seller.created_at).getFullYear()

  return (
    <div className={styles.page}>
      <div className={styles.layout}>
        <div className={styles.leftCol}>
          <div className={styles.identityCard}>
            <div className={styles.avatarWrap}>
              {seller.avatar_url ? (
                <img src={seller.avatar_url} alt={seller.display_name} className={styles.avatarImg} />
              ) : (
                <div className={styles.avatarInitials} aria-hidden="true">
                  {sellerInitials}
                </div>
              )}
            </div>

            <h1 className={styles.displayName}>{seller.display_name}</h1>

            <div className={styles.badgeRow}>
              <span className={styles.verifiedBadge}>
                <svg width="9" height="9" viewBox="0 0 10 10" fill="none" aria-hidden="true">
                  <path
                    d="M2 5.2L4.1 7.5L8 3"
                    stroke="currentColor"
                    strokeWidth="1.6"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
                Verified Seller
              </span>
              {seller.is_legacy_fb_seller && <span className={styles.legacyBadge}>Legacy Seller</span>}
            </div>

            {seller.pfc_seller_code && <p className={styles.sellerCode}>{seller.pfc_seller_code}</p>}

            <p className={styles.cityMeta}>
              {seller.city} · Member since {memberSince}
            </p>

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
                <button className={styles.reportLinkBtn} onClick={() => setReportModalOpen(true)}>
                  Report User
                </button>
              </div>
            )}
          </div>
        </div>

        <div className={styles.rightCol}>
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
                {listings.map(listing => {
                  const photos = [...(listing.listing_photos ?? [])].sort(
                    (a, b) => a.display_order - b.display_order
                  )

                  return (
                    <ListingCard
                      key={listing.id}
                      id={listing.id}
                      fragranceName={listing.fragrance_name}
                      brand={listing.brand}
                      pricePkr={listing.price_pkr}
                      listingType={listing.listing_type}
                      condition={listing.condition ?? undefined}
                      photoUrl={photos[0]?.file_url}
                      sizeMl={listing.size_ml}
                      sellerName={seller.display_name}
                    />
                  )
                })}
              </div>
            )}
          </section>

          {isoPosts.length > 0 && (
            <section className={styles.section}>
              <p className={styles.sectionLabel}>ISO Requests</p>
              <div className={styles.isoList}>
                {isoPosts.map(post => (
                  <IsoCard
                    key={post.id}
                    id={post.id}
                    fragranceName={post.fragrance_name}
                    brand={post.brand}
                    sizeMl={post.size_ml}
                    budgetPkr={post.price_pkr}
                    posterName={post.profiles?.display_name ?? seller.display_name}
                    createdAt={post.created_at}
                  />
                ))}
              </div>
            </section>
          )}

          {reviews.length > 0 && (
            <section className={styles.section}>
              <p className={styles.sectionLabel}>Reviews · {seller.rating_count}</p>
              <RatingDistribution reviews={reviews} />

              <div className={styles.reviewList}>
                {reviews.map(review => {
                  const reviewerInitials = review.reviewer_display_name
                    ? initials(review.reviewer_display_name)
                    : '?'
                  const isOwnReview = myProfile?.id === review.reviewer_id
                  const withinEditWindow =
                    isOwnReview &&
                    new Date(review.submitted_at).getTime() > Date.now() - 48 * 60 * 60 * 1000

                  return (
                    <div key={review.id} className={styles.reviewCard}>
                      <div className={styles.reviewHeader}>
                        <div className={styles.reviewerAvatar}>
                          {review.reviewer_avatar_url ? (
                            <img
                              src={review.reviewer_avatar_url}
                              alt={review.reviewer_display_name ?? 'Member'}
                              className={styles.reviewerAvatarImg}
                            />
                          ) : (
                            reviewerInitials
                          )}
                        </div>

                        <div className={styles.reviewerInfo}>
                          <span className={styles.reviewerName}>
                            {review.reviewer_display_name ?? 'Member'}
                          </span>
                          {(review.fragrance_name || review.brand) && (
                            <span className={styles.reviewListing}>
                              {[review.fragrance_name, review.brand].filter(Boolean).join(' · ')}
                            </span>
                          )}
                        </div>

                        <div className={styles.reviewMeta}>
                          <StarRow rating={review.rating} />
                          <span className={styles.reviewTime}>{timeAgo(review.submitted_at)}</span>
                        </div>

                        {withinEditWindow && (
                          <button
                            type="button"
                            className={styles.reviewEditBtn}
                            onClick={() => setEditingReview(review)}
                            aria-label="Edit review"
                          >
                            <svg width="13" height="13" viewBox="0 0 14 14" fill="none" aria-hidden="true">
                              <path
                                d="M9.5 1.5l3 3L4 13H1v-3L9.5 1.5z"
                                stroke="currentColor"
                                strokeWidth="1.4"
                                strokeLinecap="round"
                                strokeLinejoin="round"
                              />
                            </svg>
                          </button>
                        )}
                      </div>

                      {review.comment && <p className={styles.reviewComment}>{review.comment}</p>}

                      {review.photos.length > 0 && (
                        <div className={styles.reviewPhotoGrid}>
                          {review.photos.map(photo => (
                            <a
                              key={photo.id}
                              href={photo.file_url}
                              target="_blank"
                              rel="noopener noreferrer"
                              className={styles.reviewPhotoThumb}
                            >
                              <img src={photo.file_url} alt="Review" />
                            </a>
                          ))}
                        </div>
                      )}

                      <div className={styles.verifiedChip}>
                        <svg width="9" height="9" viewBox="0 0 10 10" fill="none" aria-hidden="true">
                          <path
                            d="M2 5.2L4.1 7.5L8 3"
                            stroke="currentColor"
                            strokeWidth="1.6"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                          />
                        </svg>
                        Verified Purchase
                      </div>
                    </div>
                  )
                })}
              </div>
            </section>
          )}
        </div>
      </div>

      {reportModalOpen && (
        <ReportModal
          type="user"
          targetId={seller.id}
          onClose={() => setReportModalOpen(false)}
        />
      )}

      {editingReview && (
        <ReviewModal
          listingId={editingReview.listing_id}
          sellerId={seller.id}
          sellerName={seller.display_name}
          fragranceName={editingReview.fragrance_name ?? undefined}
          brand={editingReview.brand ?? undefined}
          existingReview={{
            id: editingReview.id,
            rating: editingReview.rating,
            comment: editingReview.comment,
            photos: editingReview.photos,
          }}
          onClose={() => setEditingReview(null)}
          onSuccess={async () => {
            setEditingReview(null)
            await fetchProfile()
          }}
        />
      )}
    </div>
  )
}
