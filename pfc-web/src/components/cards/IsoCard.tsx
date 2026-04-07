import { useNavigate } from 'react-router-dom'
import { formatPkr, timeAgo, initials } from '@/lib/format'
import styles from './IsoCard.module.css'

interface IsoCardProps {
  id: string
  fragranceName: string
  brand: string
  sizeMl: number
  budgetPkr: number      // price_pkr field — 0 means flexible
  posterName: string
  posterCity: string
  createdAt: string
}

export function IsoCard({
  id,
  fragranceName,
  brand,
  sizeMl,
  budgetPkr,
  posterName,
  posterCity,
  createdAt,
}: IsoCardProps) {
  const navigate = useNavigate()
  const posterInitials = initials(posterName)

  return (
    <article
      className={styles.card}
      onClick={() => navigate(`/iso/${id}`)}
      role="button"
      tabIndex={0}
      onKeyDown={(e) => e.key === 'Enter' && navigate(`/iso/${id}`)}
      aria-label={`ISO: ${fragranceName} by ${brand}`}
    >
      <h3 className={styles.fragranceName}>{fragranceName}</h3>
      <p className={styles.brand}>{brand}</p>

      <div className={styles.chips}>
        <span className={styles.chipMuted}>{sizeMl}ml</span>
        {budgetPkr > 0 ? (
          <span className={styles.chipGold}>{formatPkr(budgetPkr)}</span>
        ) : (
          <span className={styles.chipMuted}>Flexible</span>
        )}
      </div>

      <div className={styles.divider} />

      <div className={styles.posterRow}>
        <div className={styles.avatar} aria-hidden="true">
          {posterInitials}
        </div>
        <span className={styles.posterName}>{posterName}</span>
        <span className={styles.posterCity}>· {posterCity}</span>
        <span className={styles.timeAgo}>{timeAgo(createdAt)}</span>
      </div>
    </article>
  )
}
