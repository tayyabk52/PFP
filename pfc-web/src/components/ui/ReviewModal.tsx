import { useEffect, useRef, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/context/AuthContext'
import styles from './ReviewModal.module.css'

interface ExistingReviewPhoto {
  id: string
  file_url: string
  path: string
}

interface ExistingReview {
  id: string
  rating: number
  comment: string
  photos?: ExistingReviewPhoto[]
}

interface ReviewModalProps {
  listingId: string
  sellerId: string
  sellerName: string
  fragranceName?: string
  brand?: string
  isoId?: string
  existingReview?: ExistingReview | null
  onClose: () => void
  onSuccess: () => void
}

const MAX_PHOTOS = 3
const MAX_FILE_SIZE = 10 * 1024 * 1024
const ACCEPTED_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp'])

export function ReviewModal({
  listingId,
  sellerId,
  sellerName,
  fragranceName,
  brand,
  isoId,
  existingReview,
  onClose,
  onSuccess,
}: ReviewModalProps) {
  const { user } = useAuth()
  const fileInputRef = useRef<HTMLInputElement>(null)
  const isEditMode = !!existingReview

  const [rating, setRating] = useState(existingReview?.rating ?? 5)
  const [hoverRating, setHoverRating] = useState(0)
  const [comment, setComment] = useState(existingReview?.comment ?? '')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [photoWarning, setPhotoWarning] = useState<string | null>(null)
  const [existingPhotos, setExistingPhotos] = useState<ExistingReviewPhoto[]>(existingReview?.photos ?? [])
  const [newFiles, setNewFiles] = useState<File[]>([])
  const [newPreviews, setNewPreviews] = useState<string[]>([])

  useEffect(() => {
    return () => {
      newPreviews.forEach(preview => URL.revokeObjectURL(preview))
    }
  }, [newPreviews])

  const totalPhotos = existingPhotos.length + newFiles.length
  const effectiveRating = hoverRating || rating

  function resetInlineErrors() {
    if (error) setError(null)
    if (photoWarning) setPhotoWarning(null)
  }

  function handleFileChange(event: React.ChangeEvent<HTMLInputElement>) {
    const selectedFiles = Array.from(event.target.files ?? [])
    if (selectedFiles.length === 0) return

    resetInlineErrors()

    const remainingSlots = MAX_PHOTOS - totalPhotos
    if (remainingSlots <= 0) {
      setError(`You can upload up to ${MAX_PHOTOS} photos.`)
      event.target.value = ''
      return
    }

    const validFiles: File[] = []
    for (const file of selectedFiles) {
      if (!ACCEPTED_TYPES.has(file.type)) {
        setError('Only JPG, PNG, and WebP images are allowed.')
        continue
      }
      if (file.size > MAX_FILE_SIZE) {
        setError('Each photo must be 10MB or smaller.')
        continue
      }
      validFiles.push(file)
    }

    const acceptedFiles = validFiles.slice(0, remainingSlots)
    if (validFiles.length > remainingSlots) {
      setError(`You can upload up to ${MAX_PHOTOS} photos total.`)
    }

    if (acceptedFiles.length > 0) {
      const nextPreviews = acceptedFiles.map(file => URL.createObjectURL(file))
      setNewFiles(prev => [...prev, ...acceptedFiles])
      setNewPreviews(prev => [...prev, ...nextPreviews])
    }

    event.target.value = ''
  }

  function removeNewPhoto(index: number) {
    URL.revokeObjectURL(newPreviews[index])
    setNewFiles(prev => prev.filter((_, currentIndex) => currentIndex !== index))
    setNewPreviews(prev => prev.filter((_, currentIndex) => currentIndex !== index))
  }

  async function deleteExistingPhoto(photo: ExistingReviewPhoto) {
    resetInlineErrors()

    const { error: storageError } = await supabase.storage.from('review-photos').remove([photo.path])
    if (storageError) {
      setError('Unable to remove the photo from storage.')
      return
    }

    const { error: dbError } = await supabase.from('review_photos').delete().eq('id', photo.id)
    if (dbError) {
      setError('The photo was removed from storage but not from the review record.')
      return
    }

    setExistingPhotos(prev => prev.filter(existing => existing.id !== photo.id))
  }

  async function uploadPhotos(reviewId: string) {
    if (!user || newFiles.length === 0) return

    let failedUploads = 0

    for (const file of newFiles) {
      const extension = file.name.split('.').pop()?.toLowerCase() ?? 'jpg'
      const path = `${user.id}/${reviewId}/${crypto.randomUUID()}.${extension}`

      const { error: uploadError } = await supabase.storage
        .from('review-photos')
        .upload(path, file, { contentType: file.type })

      if (uploadError) {
        failedUploads += 1
        continue
      }

      const { data: publicUrlData } = supabase.storage.from('review-photos').getPublicUrl(path)
      const { error: insertError } = await supabase
        .from('review_photos')
        .insert({ review_id: reviewId, file_url: publicUrlData.publicUrl, path })

      if (insertError) {
        failedUploads += 1
      }
    }

    if (failedUploads > 0) {
      setPhotoWarning(
        failedUploads === newFiles.length
          ? 'Review saved, but the photo upload failed.'
          : 'Review saved, but some photos failed to upload.'
      )
    }
  }

  async function handleSubmit() {
    if (submitting) return

    const trimmedComment = comment.trim()
    if (trimmedComment.length < 20) {
      setError('Please write at least 20 characters.')
      return
    }

    if (!listingId || !sellerId) {
      setError('Missing review context. Please reopen the review sheet.')
      return
    }

    setSubmitting(true)
    setError(null)
    setPhotoWarning(null)

    try {
      let reviewId = existingReview?.id ?? null

      if (isEditMode && reviewId) {
        const { error: rpcError } = await supabase.rpc('edit_review', {
          p_review_id: reviewId,
          p_rating: rating,
          p_comment: trimmedComment.slice(0, 500),
        })

        if (rpcError) {
          setError(rpcError.message)
          return
        }
      } else {
        const params: Record<string, unknown> = {
          p_listing_id: listingId,
          p_seller_id: sellerId,
          p_rating: rating,
          p_comment: trimmedComment.slice(0, 500),
        }

        if (isoId) {
          params.p_iso_id = isoId
        }

        const { data, error: rpcError } = await supabase.rpc('submit_review', params)
        if (rpcError) {
          setError(rpcError.message)
          return
        }

        reviewId = typeof data === 'string' ? data : null
      }

      if (reviewId && newFiles.length > 0) {
        await uploadPhotos(reviewId)
      }

      onSuccess()
      if (!photoWarning) {
        onClose()
      }
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className={styles.reviewOverlay} onClick={onClose}>
      <div className={styles.reviewModal} onClick={event => event.stopPropagation()}>
        <div className={styles.reviewHeader}>
          <h3 className={styles.reviewTitle}>{isEditMode ? 'Edit Review' : 'Leave a Review'}</h3>
          <p className={styles.reviewSellerLine}>
            {isEditMode ? 'Editing review for ' : 'Reviewing '}
            <strong>{sellerName}</strong>
          </p>
          {(fragranceName || brand) && (
            <p className={styles.reviewContextLine}>
              {[fragranceName, brand].filter(Boolean).join(' · ')}
            </p>
          )}
        </div>

        <div
          className={styles.starRow}
          role="group"
          aria-label="Rating"
          onMouseLeave={() => setHoverRating(0)}
        >
          {[1, 2, 3, 4, 5].map(star => (
            <button
              key={star}
              type="button"
              className={`${styles.star} ${star <= effectiveRating ? styles.starFilled : ''}`}
              onClick={() => setRating(star)}
              onMouseEnter={() => setHoverRating(star)}
              aria-label={`${star} star${star === 1 ? '' : 's'}`}
            >
              ★
            </button>
          ))}
        </div>

        <div className={styles.verifiedBadge}>
          <svg width="10" height="10" viewBox="0 0 10 10" fill="none" aria-hidden="true">
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

        <textarea
          className={styles.reviewInput}
          placeholder="Share your experience... (min 20, max 500 characters)"
          value={comment}
          onChange={event => {
            setComment(event.target.value)
            if (error) setError(null)
          }}
          maxLength={500}
          rows={4}
        />

        <div className={styles.reviewFooterText}>
          {error ? (
            <span className={styles.errorMessage}>{error}</span>
          ) : (
            <span className={styles.reviewCharCount}>{comment.length} / 500</span>
          )}
        </div>

        <div className={styles.photoSection}>
          <p className={styles.photoLabel}>
            Photos <span className={styles.photoHint}>(optional, max 3)</span>
          </p>

          <div className={styles.photoGrid}>
            {existingPhotos.map(photo => (
              <div key={photo.id} className={styles.photoThumb}>
                <img src={photo.file_url} alt="Review" />
                <button
                  type="button"
                  className={styles.photoDeleteBtn}
                  onClick={() => deleteExistingPhoto(photo)}
                  aria-label="Remove photo"
                >
                  ×
                </button>
              </div>
            ))}

            {newPreviews.map((preview, index) => (
              <div key={`new-${preview}`} className={styles.photoThumb}>
                <img src={preview} alt="Preview" />
                <button
                  type="button"
                  className={styles.photoDeleteBtn}
                  onClick={() => removeNewPhoto(index)}
                  aria-label="Remove photo"
                >
                  ×
                </button>
              </div>
            ))}

            {totalPhotos < MAX_PHOTOS && (
              <button
                type="button"
                className={styles.photoAddBtn}
                onClick={() => fileInputRef.current?.click()}
                aria-label="Add photo"
              >
                <svg
                  width="20"
                  height="20"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  aria-hidden="true"
                >
                  <path d="M12 5v14M5 12h14" />
                </svg>
              </button>
            )}
          </div>

          <input
            ref={fileInputRef}
            type="file"
            accept="image/jpeg,image/png,image/webp"
            multiple
            hidden
            onChange={handleFileChange}
          />

          {photoWarning && <p className={styles.photoWarning}>{photoWarning}</p>}
        </div>

        <div className={styles.reviewActions}>
          <button
            type="button"
            className={styles.reviewCancelBtn}
            onClick={onClose}
            disabled={submitting}
          >
            Cancel
          </button>
          <button
            type="button"
            className={styles.reviewSubmitBtn}
            onClick={handleSubmit}
            disabled={submitting || comment.trim().length < 20}
          >
            {submitting
              ? newFiles.length > 0
                ? 'Uploading...'
                : 'Submitting...'
              : isEditMode
                ? 'Save Changes'
                : 'Submit Review'}
          </button>
        </div>
      </div>
    </div>
  )
}
