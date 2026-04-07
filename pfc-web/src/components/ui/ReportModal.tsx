import { useState } from 'react'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/context/AuthContext'
import styles from './ReportModal.module.css'

interface ReportModalProps {
  type: 'listing' | 'user'
  targetId: string // listing_id or user_id
  onClose: () => void
}

const LISTING_REASONS = [
  'Counterfeit / Fake',
  'Incorrect Information',
  'Inappropriate Content',
  'Prohibited Item',
  'Other'
]

const USER_REASONS = [
  'Scam / Fraud',
  'Harassment / Abuse',
  'Fake Reviews',
  'Other'
]

export function ReportModal({ type, targetId, onClose }: ReportModalProps) {
  const { user } = useAuth()
  const [reason, setReason] = useState('')
  const [details, setDetails] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)

  const reasons = type === 'listing' ? LISTING_REASONS : USER_REASONS

  async function handleSubmit() {
    if (!user || !reason) return
    setLoading(true)

    const payload = {
      reporter_id: user.id,
      reason,
      details: details.trim() || null,
      ...(type === 'listing' ? { reported_listing_id: targetId } : { reported_user_id: targetId })
    }

    const { error } = await supabase.from('reports').insert(payload)

    if (!error) {
      setSuccess(true)
      setTimeout(onClose, 2000)
    } else {
      console.error(error)
      alert(`Failed to submit report. Ensure you are signed in. Status: ${error.message}`)
    }
    setLoading(false)
  }

  return (
    <div className={styles.reportOverlay} onClick={onClose}>
      <div className={styles.reportModal} onClick={e => e.stopPropagation()}>
        {success ? (
          <div className={styles.successMessage}>
            Report submitted successfully. Thank you for keeping PFC safe.
          </div>
        ) : (
          <>
            <div className={styles.reportHeader}>
              <h3 className={styles.reportTitle}>
                Report {type === 'listing' ? 'Listing' : 'User'}
              </h3>
              <p className={styles.reportSubtitle}>
                Your report will be reviewed by moderators.
              </p>
            </div>

            <div className={styles.formGroup}>
              <label className={styles.formLabel}>Reason</label>
              <select 
                className={styles.selectInput}
                value={reason}
                onChange={e => setReason(e.target.value)}
              >
                <option value="" disabled>Select a reason...</option>
                {reasons.map(r => (
                  <option key={r} value={r}>{r}</option>
                ))}
              </select>
            </div>

            <div className={styles.formGroup}>
              <label className={styles.formLabel}>Details (Optional)</label>
              <textarea
                className={styles.textareaInput}
                placeholder="Provide any additional details..."
                value={details}
                onChange={e => setDetails(e.target.value)}
              />
            </div>

            <div className={styles.reportActions}>
              <button 
                className={styles.cancelBtn} 
                onClick={onClose}
                disabled={loading}
              >
                Cancel
              </button>
              <button 
                className={styles.submitBtn} 
                onClick={handleSubmit}
                disabled={!reason || loading}
              >
                {loading ? 'Submitting...' : 'Submit Report'}
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  )
}
