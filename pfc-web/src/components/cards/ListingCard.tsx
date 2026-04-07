import { useNavigate } from 'react-router-dom'
import { formatPkr, listingTypeLabel } from '@/lib/format'
import styles from './ListingCard.module.css'

interface ListingCardProps {
  id: string
  fragranceName: string
  brand: string
  pricePkr: number
  listingType: string
  condition?: string
  photoUrl?: string
  sellerName: string
  sizeMl?: number | null
  variantCount?: number   // > 1 means multi-variant listing
}

export function ListingCard({
  id,
  fragranceName,
  brand,
  pricePkr,
  listingType,
  photoUrl,
  sizeMl,
  variantCount = 1,
}: ListingCardProps) {
  const isMultiVariant = variantCount > 1
  const navigate = useNavigate()

  return (
    <article
      className={styles.card}
      onClick={() => navigate(`/marketplace/${id}`)}
      role="button"
      tabIndex={0}
      onKeyDown={(e) => e.key === 'Enter' && navigate(`/marketplace/${id}`)}
      aria-label={`${fragranceName} by ${brand}`}
    >
      <div className={styles.imageArea}>
        {photoUrl ? (
          <img
            src={photoUrl}
            alt={fragranceName}
            className={styles.photo}
          />
        ) : (
          <div className={styles.imagePlaceholder}>
            <span>P</span>
          </div>
        )}
      </div>

      <div className={styles.info}>
        <span className={styles.typeChip}>{listingTypeLabel(listingType)}</span>
        <h3 className={styles.name}>{fragranceName}</h3>
        <p className={styles.brand}>{brand}</p>
        <div className={styles.priceRow}>
          <span className={styles.price}>
            {isMultiVariant ? 'From ' : ''}{formatPkr(pricePkr)}
          </span>
          <span className={styles.size}>
            {isMultiVariant ? `${variantCount} sizes` : sizeMl ? `${sizeMl}ml` : ''}
          </span>
        </div>
      </div>
    </article>
  )
}
