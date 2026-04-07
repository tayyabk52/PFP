import { useState } from 'react'
import { supabase } from '@/lib/supabase'
import styles from './ReviewModal.module.css'

interface ReviewModalProps {
  listingId: string
  sellerId: string
  onClose: () => void
  onSuccess: () => void
}

export function ReviewModal({ listingId, sellerId, onClose, onSuccess }: ReviewModalProps) {
  const [reviewRating, setReviewRating] = useState(5)
  const [reviewComment, setReviewComment] = useState('')
  const [reviewSubmitting, setReviewSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function handleSubmitReview() {
    if (reviewSubmitting || !reviewComment.trim()) return
    if (reviewComment.length < 20) {
      setError('Please write at least 20 characters.')
      return
    }
    
    setReviewSubmitting(true)
    setError(null)
    
    const { error: rpcError } = await supabase.rpc('submit_review', {
      p_listing_id: listingId,
      p_seller_id: sellerId,
      p_rating: reviewRating,
      p_comment: reviewComment.trim().slice(0, 500),
    })
    
    if (rpcError) {
      setError(rpcError.message)
      setReviewSubmitting(false)
    } else {
      setReviewSubmitting(false)
      onSuccess()
      onClose()
    }
  }

  return (
    <div className={styles.reviewOverlay} onClick={onClose}>
      <div className={styles.reviewModal} onClick={e => e.stopPropagation()}>
        <h3 className={styles.reviewTitle}>Leave a Review</h3>
        <p className={styles.reviewSubtitle}>How was your experience with this seller?</p>
        
        <div className={styles.starRow} role="group" aria-label="Rating">
          {[1, 2, 3, 4, 5].map(star => (
            <button
              key={star}
              className={`${styles.star} ${star <= reviewRating ? styles.starFilled : ''}`}
              onClick={() => setReviewRating(star)}
              aria-label={`${star} star${star !== 1 ? 's' : ''}`}
            >
              ★
            </button>
          ))}
        </div>
        
        <textarea
          className={styles.reviewInput}
          placeholder="Share your experience… (min 20 max 500 characters)"
          value={reviewComment}
          onChange={e => {
            setReviewComment(e.target.value)
            if (error) setError(null)
          }}
          maxLength={500}
          rows={4}
        />
        <div className={styles.reviewFooterText}>
          {error ? (
            <span className={styles.errorMessage}>{error}</span>
          ) : (
            <span className={styles.reviewCharCount}>{reviewComment.length} / 500</span>
          )}
        </div>
        
        <div className={styles.reviewActions}>
          <button className={styles.reviewCancelBtn} onClick={onClose} disabled={reviewSubmitting}>
            Cancel
          </button>
          <button
            className={styles.reviewSubmitBtn}
            onClick={handleSubmitReview}
            disabled={reviewSubmitting || !reviewComment.trim() || reviewComment.length < 20}
          >
            {reviewSubmitting ? 'Submitting…' : 'Submit Review'}
          </button>
        </div>
      </div>
    </div>
  )
}
