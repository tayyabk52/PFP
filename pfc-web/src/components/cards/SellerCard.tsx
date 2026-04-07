import { useNavigate } from 'react-router-dom'
import { initials } from '@/lib/format'
import styles from './SellerCard.module.css'

interface SellerCardProps {
  id: string
  displayName: string
  city: string
  transactionCount: number
  avgRating?: number
  ratingCount?: number
  avatarUrl?: string
  pfcSellerCode?: string
  isLegacyFbSeller?: boolean
}

export function SellerCard({
  id,
  displayName,
  city,
  transactionCount,
  avgRating = 0,
  ratingCount = 0,
  avatarUrl,
  isLegacyFbSeller,
}: SellerCardProps) {
  const navigate = useNavigate()
  const sellerInitials = initials(displayName)

  return (
    <article
      className={styles.card}
      onClick={() => navigate(`/sellers/${id}`)}
      role="button"
      tabIndex={0}
      onKeyDown={(e) => e.key === 'Enter' && navigate(`/sellers/${id}`)}
      aria-label={`Seller: ${displayName}`}
    >
      {/* Top row: avatar + name/city */}
      <div className={styles.topRow}>
        <div className={styles.avatarWrap}>
          {avatarUrl ? (
            <img src={avatarUrl} alt={displayName} className={styles.avatarImg} />
          ) : (
            <div className={styles.avatarInitials} aria-hidden="true">
              {sellerInitials}
            </div>
          )}
        </div>
        <div className={styles.nameBlock}>
          <span className={styles.displayName}>{displayName}</span>
          <span className={styles.city}>{city}</span>
        </div>
      </div>

      {/* Stats row */}
      <div className={styles.statsRow}>
        <span className={styles.stat}>
          <span className={styles.statNum}>{transactionCount}</span>
          <span className={styles.statLbl}>Sales</span>
        </span>
        {ratingCount > 0 && (
          <span className={styles.stat}>
            <span className={styles.statNum}>
              {/* Star icon */}
              <svg width="10" height="10" viewBox="0 0 10 10" fill="currentColor" aria-hidden="true" className={styles.starIcon}>
                <path d="M5 1l1.12 2.27L8.5 3.635l-1.75 1.705.413 2.41L5 6.545l-2.163 1.205.413-2.41L1.5 3.635l2.38-.365L5 1z" />
              </svg>
              {avgRating.toFixed(1)}
            </span>
            <span className={styles.statLbl}>{ratingCount} Review{ratingCount !== 1 ? 's' : ''}</span>
          </span>
        )}
      </div>

      {/* Chips row */}
      <div className={styles.chips}>
        <span className={styles.chipVerified}>
          <svg width="9" height="9" viewBox="0 0 10 10" fill="none" aria-hidden="true" className={styles.checkIcon}>
            <path d="M2 5.2L4.1 7.5L8 3" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
          Verified Seller
        </span>

        {isLegacyFbSeller && (
          <span className={styles.chipLegacy}>Legacy Seller</span>
        )}
      </div>
    </article>
  )
}
