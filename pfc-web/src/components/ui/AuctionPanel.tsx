import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/context/AuthContext'
import { formatPkr } from '@/lib/format'
import styles from './AuctionPanel.module.css'

interface AuctionPanelProps {
  listingId: string
  auctionEndAt: string | null
  basePrice?: number
}

export function AuctionPanel({ listingId, auctionEndAt, basePrice = 0 }: AuctionPanelProps) {
  const { user } = useAuth()
  const [highestBid, setHighestBid] = useState<number>(0)
  const [bidAmount, setBidAmount] = useState('')
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  
  const [timeLeft, setTimeLeft] = useState('')
  const [ended, setEnded] = useState(false)

  // 1. Fetch highest bid
  useEffect(() => {
    async function fetchHighestBid() {
      const { data } = await supabase
        .from('bids')
        .select('bid_amount')
        .eq('listing_id', listingId)
        .order('bid_amount', { ascending: false })
        .limit(1)

      if (data && data.length > 0) {
        setHighestBid(data[0].bid_amount)
      } else {
        setHighestBid(0)
      }
      setLoading(false)
    }
    fetchHighestBid()
  }, [listingId])

  // 2. Countdown timer
  useEffect(() => {
    if (!auctionEndAt) return

    const endDate = new Date(auctionEndAt).getTime()

    const updateTimer = () => {
      const now = new Date().getTime()
      const diff = endDate - now

      if (diff <= 0) {
        setEnded(true)
        setTimeLeft('Auction Ended')
        return
      }

      const d = Math.floor(diff / (1000 * 60 * 60 * 24))
      const h = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
      const m = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
      const s = Math.floor((diff % (1000 * 60)) / 1000)

      setTimeLeft(d > 0 ? `${d}d ${h}h ${m}m` : `${h}h ${m}m ${s}s`)
    }

    updateTimer()
    const intv = setInterval(updateTimer, 1000)
    return () => clearInterval(intv)
  }, [auctionEndAt])

  // Subscriptions can be added if realtime is desired, but manually refreshing works too.

  async function handleBid(e: React.FormEvent) {
    e.preventDefault()
    if (!user) {
      setError('Please sign in to place a bid.')
      return
    }

    const amount = Number(bidAmount)
    if (isNaN(amount) || amount <= 0) {
      setError('Invalid bid amount.')
      return
    }

    const minRequired = Math.max(highestBid + 1, basePrice)
    if (amount < minRequired) {
      setError(`Bid must be at least ${formatPkr(minRequired)}`)
      return
    }

    setSubmitting(true)
    setError(null)
    setSuccess(null)

    const { error: rpcErr } = await supabase.rpc('place_bid', {
      listing_id: listingId,
      bid_amount: amount
    })

    if (rpcErr) {
      setError(rpcErr.message || 'Failed to place bid')
    } else {
      setSuccess('Bid placed successfully!')
      setBidAmount('')
      setHighestBid(amount) // optimistic update
    }
    setSubmitting(false)
  }

  if (loading) return null

  return (
    <div className={styles.panel}>
      <div className={styles.header}>
        <div className={styles.titleWrap}>
          <svg className={styles.icon} width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
          </svg>
          <h3 className={styles.title}>Live Auction</h3>
        </div>
        <div className={`${styles.status} ${ended ? styles.statusEnded : styles.statusActive}`}>
          {timeLeft || 'TBD'}
        </div>
      </div>

      <div className={styles.bidRow}>
        <div className={styles.bidCol}>
          <span className={styles.bidLabel}>Current Highest</span>
          <span className={styles.bidValue}>
            {highestBid > 0 ? formatPkr(highestBid) : 'No bids yet'}
          </span>
        </div>
        {basePrice > 0 && highestBid === 0 && (
          <div className={styles.bidCol}>
            <span className={styles.bidLabel}>Starting Price</span>
            <span className={styles.bidValueSm}>{formatPkr(basePrice)}</span>
          </div>
        )}
      </div>

      {!ended ? (
        <form onSubmit={handleBid} className={styles.form}>
          <div className={styles.inputWrap}>
            <span className={styles.currencyPrefix}>RS</span>
            <input
              className={styles.input}
              type="number"
              placeholder={`Min ${highestBid > 0 ? highestBid + 1 : basePrice}`}
              value={bidAmount}
              onChange={e => setBidAmount(e.target.value)}
              min={Math.max(highestBid + 1, basePrice)}
              required
            />
          </div>
          <button type="submit" className={styles.submitBtn} disabled={submitting}>
            {submitting ? '...' : 'Place Bid'}
          </button>
        </form>
      ) : (
        <div className={styles.endedMessage}>
          Auction has concluded.
        </div>
      )}

      {error && <p className={styles.error}>{error}</p>}
      {success && <p className={styles.success}>{success}</p>}
    </div>
  )
}
