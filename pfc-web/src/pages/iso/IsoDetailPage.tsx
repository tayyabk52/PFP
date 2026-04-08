import { useEffect, useState, FormEvent } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/context/AuthContext'
import { formatPkr, timeAgo, initials } from '@/lib/format'
import styles from './IsoDetailPage.module.css'

// ─── Types ─────────────────────────────────────────────────────────────────────

interface IsoDetail {
  id: string
  fragrance_name: string
  brand: string
  size_ml: number
  price_pkr: number
  condition_notes: string | null
  status: string
  created_at: string
  seller_id: string
  profiles: {
    id: string
    display_name: string
    city: string
    avatar_url: string | null
  }
}

interface IsoOffer {
  id: string
  iso_id: string
  seller_id: string
  message: string | null
  offer_amount: number | null
  status: string
  created_at: string
  profiles: {
    id: string
    display_name: string
    avatar_url: string | null
    city: string
    transaction_count: number
    pfc_seller_code: string | null
  }
}

// Offers grouped by seller (for ISO owner view)
interface SellerOfferGroup {
  seller_id: string
  sellerProfile: IsoOffer['profiles']
  offers: IsoOffer[]   // sorted newest-first; latest is offers[0]
}

function groupOffersBySeller(offers: IsoOffer[]): SellerOfferGroup[] {
  const map = new Map<string, SellerOfferGroup>()
  // offers come in ascending order from DB; we reverse per-group below
  for (const o of offers) {
    if (!map.has(o.seller_id)) {
      map.set(o.seller_id, { seller_id: o.seller_id, sellerProfile: o.profiles, offers: [] })
    }
    map.get(o.seller_id)!.offers.unshift(o) // newest first within group
  }
  // Sort groups: groups with a pending offer bubble to top
  return Array.from(map.values()).sort((a, b) => {
    const aPending = a.offers.some(o => o.status === 'pending') ? 0 : 1
    const bPending = b.offers.some(o => o.status === 'pending') ? 0 : 1
    return aPending - bPending
  })
}

// ─── IsoDetailPage ─────────────────────────────────────────────────────────────

export function IsoDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { profile } = useAuth()
  const [post, setPost] = useState<IsoDetail | null>(null)
  const [offers, setOffers] = useState<IsoOffer[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // ── Edit state ──────────────────────────────────────────────────────────────
  const [editing, setEditing] = useState(false)
  const [editName, setEditName] = useState('')
  const [editBrand, setEditBrand] = useState('')
  const [editSize, setEditSize] = useState('')
  const [editBudget, setEditBudget] = useState('')
  const [editNotes, setEditNotes] = useState('')
  const [saving, setSaving] = useState(false)
  const [saveMsg, setSaveMsg] = useState<string | null>(null)
  const [deleting, setDeleting] = useState(false)

  // ── Offer form state ────────────────────────────────────────────────────────
  const [showOfferForm, setShowOfferForm] = useState(false)
  const [offerAmount, setOfferAmount] = useState('')
  const [offerMessage, setOfferMessage] = useState('')
  const [submittingOffer, setSubmittingOffer] = useState(false)
  const [offerError, setOfferError] = useState<string | null>(null)

  // ── Expanded history groups (for owner view) ────────────────────────────────
  const [expandedGroups, setExpandedGroups] = useState<Set<string>>(new Set())

  useEffect(() => {
    if (!id) return
    async function fetchPost() {
      setLoading(true)
      setError(null)
      const { data, error: err } = await supabase
        .from('listings')
        .select('*, profiles(id, display_name, city, avatar_url)')
        .eq('id', id)
        .eq('listing_type', 'ISO')
        .single()

      if (err || !data) {
        setError('ISO post not found.')
      } else {
        setPost(data as IsoDetail)
        setEditName(data.fragrance_name)
        setEditBrand(data.brand)
        setEditSize(String(data.size_ml))
        setEditBudget(data.price_pkr > 0 ? String(data.price_pkr) : '')
        setEditNotes(data.condition_notes ?? '')

        const { data: offersData } = await supabase
          .from('iso_offers')
          .select('id, iso_id, seller_id, message, offer_amount, status, created_at, profiles(id, display_name, avatar_url, city, transaction_count, pfc_seller_code)')
          .eq('iso_id', id)
          .order('created_at', { ascending: true })
        setOffers((offersData as unknown as IsoOffer[]) ?? [])
      }
      setLoading(false)
    }
    fetchPost()
  }, [id])

  // ── Save edits ──────────────────────────────────────────────────────────────

  async function handleSave(e: FormEvent) {
    e.preventDefault()
    if (!post) return
    setSaving(true)
    setSaveMsg(null)
    const { error: err } = await supabase
      .from('listings')
      .update({
        fragrance_name: editName.trim(),
        brand: editBrand.trim(),
        size_ml: parseFloat(editSize) || post.size_ml,
        price_pkr: editBudget ? parseInt(editBudget, 10) : 0,
        condition_notes: editNotes.trim() || null,
      })
      .eq('id', post.id)

    if (err) {
      setSaveMsg('Failed to save. Please try again.')
    } else {
      setPost(prev => prev ? {
        ...prev,
        fragrance_name: editName.trim(),
        brand: editBrand.trim(),
        size_ml: parseFloat(editSize) || prev.size_ml,
        price_pkr: editBudget ? parseInt(editBudget, 10) : 0,
        condition_notes: editNotes.trim() || null,
      } : prev)
      setSaveMsg('Saved.')
      setEditing(false)
    }
    setSaving(false)
    setTimeout(() => setSaveMsg(null), 3000)
  }

  // ── Publish / Delete ──────────────────────────────────────────────────────────────────

  const [publishing, setPublishing] = useState(false)

  async function handlePublish() {
    if (!post || !confirm('Publish this ISO request?')) return
    setPublishing(true)
    const { error } = await supabase.from('listings').update({ 
      status: 'Published',
      published_at: new Date().toISOString()
    }).eq('id', post.id)
    
    if (!error) {
      setPost(prev => prev ? { ...prev, status: 'Published' } : prev)
    } else {
      alert('Failed to publish. Please try again.')
    }
    setPublishing(false)
  }

  async function handleDelete() {
    if (!post || !confirm('Remove this ISO post?')) return
    setDeleting(true)
    await supabase.from('listings').update({ status: 'Removed' }).eq('id', post.id)
    navigate('/dashboard/iso')
  }

  // ── Owner: accept / decline ─────────────────────────────────────────────────

  async function handleAcceptOffer(offerId: string) {
    if (!post || !confirm('Accept this offer? This will mark the ISO as fulfilled.')) return
    const { error } = await supabase.rpc('accept_iso_offer', {
      offer_id: offerId,
      iso_id: post.id
    })
    if (!error) {
      setOffers(prev => prev.map(o => o.id === offerId ? { ...o, status: 'accepted' } : { ...o, status: o.status === 'pending' ? 'declined' : o.status }))
      setPost(prev => prev ? { ...prev, status: 'Sold' } : prev)
    } else {
      alert(`Failed to accept: ${error.message}`)
    }
  }

  async function handleDeclineOffer(offerId: string) {
    if (!confirm('Decline this offer?')) return
    const { error } = await supabase.from('iso_offers').update({ status: 'declined' }).eq('id', offerId)
    if (!error) {
      setOffers(prev => prev.map(o => o.id === offerId ? { ...o, status: 'declined' } : o))
    }
  }

  // ── Seller: submit new offer ────────────────────────────────────────────────

  async function handleSubmitOffer(e: FormEvent) {
    e.preventDefault()
    if (!profile || !post) return
    if (!offerMessage.trim() && !offerAmount) {
      setOfferError('Please provide an offer amount or message.')
      return
    }
    setSubmittingOffer(true)
    setOfferError(null)
    const { data: newOffer, error } = await supabase
      .from('iso_offers')
      .insert({
        iso_id: post.id,
        seller_id: profile.id,
        offer_amount: parseFloat(offerAmount) || null,
        message: offerMessage.trim() || null,
        status: 'pending',
      })
      .select('id, iso_id, seller_id, message, offer_amount, status, created_at, profiles(id, display_name, avatar_url, city, transaction_count, pfc_seller_code)')
      .single()

    if (!error && newOffer) {
      setOffers(prev => [...prev, newOffer as unknown as IsoOffer])
      setShowOfferForm(false)
      setOfferAmount('')
      setOfferMessage('')
    } else {
      setOfferError(error?.message ?? 'Failed to submit offer.')
    }
    setSubmittingOffer(false)
  }

  // ── Seller: withdraw own pending offer ──────────────────────────────────────

  async function handleWithdrawOffer(offerId: string) {
    if (!confirm('Withdraw this offer?')) return
    const { error } = await supabase.from('iso_offers').update({ status: 'withdrawn' }).eq('id', offerId)
    if (!error) {
      setOffers(prev => prev.map(o => o.id === offerId ? { ...o, status: 'withdrawn' } : o))
    }
  }

  // ── Derived state ───────────────────────────────────────────────────────────

  if (loading) {
    return (
      <div className={styles.spinnerWrap}>
        <div className={styles.spinner} />
      </div>
    )
  }

  if (error || !post) {
    return (
      <div className={styles.errorWrap}>
        <p className={styles.errorMsg}>{error ?? 'ISO post not found.'}</p>
        <button className={styles.backBtn} onClick={() => navigate('/iso')}>← Back to ISO Board</button>
      </div>
    )
  }

  const poster = post.profiles
  const posterInitials = poster ? initials(poster.display_name) : '?'
  const isOwner = profile?.id === post.seller_id
  const isSeller = profile?.role === 'seller' || profile?.role === 'admin'
  const isOpen = post.status === 'Published'

  // Seller's own offers on this ISO (all time), newest first
  const myOffers = offers.filter(o => o.seller_id === profile?.id).sort((a, b) =>
    new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  )
  const myPendingOffer = myOffers.find(o => o.status === 'pending')
  const myLatestOffer = myOffers[0]
  // Can offer if: ISO is open, not owner, no pending offer currently
  const canSubmitOffer = isSeller && !isOwner && isOpen && !myPendingOffer

  const sellerGroups = isOwner ? groupOffersBySeller(offers) : []

  const statusColors: Record<string, string> = {
    Published: styles.statusPublished,
    Draft: styles.statusDraft,
    Sold: styles.statusFulfilled,
    Expired: styles.statusDraft,
    Removed: styles.statusRemoved,
  }

  return (
    <div className={styles.page}>
      <div className={styles.layout}>
        {/* ── Left column ── */}
        <div className={styles.leftCol}>

          {isOwner && editing ? (
            <form onSubmit={handleSave} className={styles.editForm}>
              <div className={styles.editHeader}>
                <p className={styles.editTitle}>Edit ISO Post</p>
                <button type="button" className={styles.cancelBtn} onClick={() => setEditing(false)}>
                  Cancel
                </button>
              </div>

              <div className={styles.editField}>
                <label className={styles.editLabel}>Fragrance Name</label>
                <input className={styles.editInput} value={editName} onChange={e => setEditName(e.target.value)} required maxLength={120} />
              </div>

              <div className={styles.editField}>
                <label className={styles.editLabel}>Brand / House</label>
                <input className={styles.editInput} value={editBrand} onChange={e => setEditBrand(e.target.value)} required maxLength={80} />
              </div>

              <div className={styles.editRow}>
                <div className={styles.editField}>
                  <label className={styles.editLabel}>Size (ml)</label>
                  <input className={styles.editInput} type="number" min="1" max="1000" value={editSize} onChange={e => setEditSize(e.target.value)} required />
                </div>
                <div className={styles.editField}>
                  <label className={styles.editLabel}>Budget (PKR, 0 = flexible)</label>
                  <input className={styles.editInput} type="number" min="0" value={editBudget} onChange={e => setEditBudget(e.target.value)} placeholder="0" />
                </div>
              </div>

              <div className={styles.editField}>
                <label className={styles.editLabel}>Notes (optional)</label>
                <textarea className={styles.editTextarea} value={editNotes} onChange={e => setEditNotes(e.target.value)} rows={3} maxLength={500} />
              </div>

              {saveMsg && <p className={saveMsg.includes('Failed') ? styles.msgError : styles.msgSuccess}>{saveMsg}</p>}

              <div className={styles.editActions}>
                <button className={styles.saveBtn} type="submit" disabled={saving}>
                  {saving ? 'Saving…' : 'Save Changes'}
                </button>
                <button type="button" className={styles.deleteBtn} onClick={handleDelete} disabled={deleting}>
                  {deleting ? 'Removing…' : 'Remove Post'}
                </button>
              </div>
            </form>

          ) : (
            <>
              <div className={styles.statusRow}>
                <span className={`${styles.statusBadge} ${statusColors[post.status] ?? ''}`}>
                  {post.status.toUpperCase()}
                </span>
                <div className={styles.statusActions}>
                  {isOwner && post.status === 'Draft' && !editing && (
                    <button className={styles.publishBtn} onClick={handlePublish} disabled={publishing}>
                      {publishing ? 'Publishing…' : 'Publish Request'}
                    </button>
                  )}
                  {isOwner && (
                    <button className={styles.editToggleBtn} onClick={() => setEditing(true)}>
                      <svg width="13" height="13" viewBox="0 0 14 14" fill="none" aria-hidden="true">
                        <path d="M9.5 1.5l3 3L4 13H1v-3L9.5 1.5z" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" />
                      </svg>
                      Edit
                    </button>
                  )}
                </div>
              </div>

              <h1 className={styles.fragranceName}>{post.fragrance_name}</h1>
              <p className={styles.brand}>{post.brand}</p>

              <div className={styles.chips}>
                <span className={styles.chipMuted}>{post.size_ml}ml</span>
                {post.price_pkr > 0 ? (
                  <span className={styles.chipGold}>{formatPkr(post.price_pkr)}</span>
                ) : (
                  <span className={styles.chipMuted}>Flexible Budget</span>
                )}
              </div>

              {post.condition_notes && (
                <div className={styles.notes}>
                  <p className={styles.notesLabel}>Notes</p>
                  <p className={styles.notesText}>{post.condition_notes}</p>
                </div>
              )}

              <div className={styles.posterRow}>
                <div className={styles.posterAvatar} aria-hidden="true">
                  {poster?.avatar_url ? (
                    <img src={poster.avatar_url} alt={poster.display_name} className={styles.posterAvatarImg} />
                  ) : posterInitials}
                </div>
                <div className={styles.posterInfo}>
                  <span className={styles.posterName}>{poster?.display_name ?? 'Member'}</span>
                  <span className={styles.posterMeta}>{poster?.city} · Posted {timeAgo(post.created_at)}</span>
                </div>
              </div>
            </>
          )}
        </div>

        {/* ── Right column ── */}
        <div className={styles.rightCol}>

          {/* ════════════════════════════════════════
              OWNER VIEW — grouped offers per seller
          ════════════════════════════════════════ */}
          {isOwner && (
            <>
              <p className={styles.offersLabel}>
                Offers
                {sellerGroups.length > 0 && (
                  <span className={styles.offersCount}>{sellerGroups.length}</span>
                )}
              </p>

              {sellerGroups.length === 0 ? (
                <div className={styles.noOffers}>
                  <p className={styles.noOffersText}>No offers yet. Sellers will appear here when they respond to your ISO.</p>
                </div>
              ) : (
                <div className={styles.offerList}>
                  {sellerGroups.map(group => {
                    const latestOffer = group.offers[0]
                    const hasPending = group.offers.some(o => o.status === 'pending')
                    const pendingOffer = group.offers.find(o => o.status === 'pending')
                    const pastOffers = group.offers.filter(o => o.status !== 'pending')
                    const isExpanded = expandedGroups.has(group.seller_id)

                    return (
                      <div key={group.seller_id} className={`${styles.offerGroup} ${!hasPending ? styles.offerGroupDim : ''}`}>
                        {/* Seller header */}
                        <div className={styles.offerGroupHeader}>
                          <div className={styles.offerSellerRow}>
                            <div className={styles.offerAvatarSmall}>
                              {group.sellerProfile?.avatar_url
                                ? <img src={group.sellerProfile.avatar_url} alt="" />
                                : initials(group.sellerProfile?.display_name ?? '?')}
                            </div>
                            <div className={styles.offerSellerInfo}>
                              <button
                                className={styles.offerSellerName}
                                onClick={() => navigate(`/sellers/${group.seller_id}`)}
                                title="View seller profile"
                              >
                                {group.sellerProfile?.display_name ?? 'Seller'}
                              </button>
                              {group.sellerProfile?.city && (
                                <span className={styles.offerSellerCity}>{group.sellerProfile.city} · {group.sellerProfile.transaction_count ?? 0} sales</span>
                              )}
                            </div>
                          </div>
                          <div className={styles.offerRight}>
                            {latestOffer.offer_amount != null && latestOffer.offer_amount > 0 && (
                              <span className={styles.offerAmount}>{formatPkr(latestOffer.offer_amount)}</span>
                            )}
                            <span className={`${styles.offerStatus} ${styles[`offerStatus_${latestOffer.status}` as keyof typeof styles]}`}>
                              {latestOffer.status}
                            </span>
                          </div>
                        </div>

                        {/* Current / latest message */}
                        {latestOffer.message && (
                          <p className={styles.offerMsg}>{latestOffer.message}</p>
                        )}
                        <p className={styles.offerTime}>{timeAgo(latestOffer.created_at)}</p>

                        {/* Accept / Decline — only on pending offer */}
                        {hasPending && pendingOffer && post.status === 'Published' && (
                          <div className={styles.offerActions}>
                            <button className={styles.acceptBtn} onClick={() => handleAcceptOffer(pendingOffer.id)}>Accept</button>
                            <button className={styles.declineBtn} onClick={() => handleDeclineOffer(pendingOffer.id)}>Decline</button>
                          </div>
                        )}

                        {/* Previous offers from same seller */}
                        {pastOffers.length > 0 && (
                          <div className={styles.offerHistoryToggle}>
                            <button
                              className={styles.offerHistoryBtn}
                              onClick={() => setExpandedGroups(prev => {
                                const next = new Set(prev)
                                isExpanded ? next.delete(group.seller_id) : next.add(group.seller_id)
                                return next
                              })}
                            >
                              {isExpanded ? '▾' : '▸'} {pastOffers.length} previous offer{pastOffers.length > 1 ? 's' : ''}
                            </button>
                            {isExpanded && (
                              <div className={styles.offerHistory}>
                                {pastOffers.map(o => (
                                  <div key={o.id} className={styles.offerHistoryItem}>
                                    <div className={styles.offerHistoryMeta}>
                                      <span className={`${styles.offerStatus} ${styles[`offerStatus_${o.status}` as keyof typeof styles]}`}>
                                        {o.status}
                                      </span>
                                      {o.offer_amount != null && o.offer_amount > 0 && (
                                        <span className={styles.offerAmount}>{formatPkr(o.offer_amount)}</span>
                                      )}
                                      <span className={styles.offerTime}>{timeAgo(o.created_at)}</span>
                                    </div>
                                    {o.message && <p className={styles.offerHistoryMsg}>{o.message}</p>}
                                  </div>
                                ))}
                              </div>
                            )}
                          </div>
                        )}
                      </div>
                    )
                  })}
                </div>
              )}
            </>
          )}

          {/* ════════════════════════════════════════
              SELLER VIEW — own offer state + form
          ════════════════════════════════════════ */}
          {!isOwner && isSeller && (
            <>
              <p className={styles.offersLabel}>Your Offer</p>

              {/* ISO is closed */}
              {!isOpen && (
                <div className={styles.noOffers}>
                  <p className={styles.noOffersText}>
                    {post.status === 'Sold' ? 'This ISO has been fulfilled.' : 'This ISO is no longer accepting offers.'}
                  </p>
                </div>
              )}

              {/* ISO is open */}
              {isOpen && (
                <>
                  {/* Existing offer history for this seller */}
                  {myOffers.length > 0 && (
                    <div className={styles.myOfferHistory}>
                      {myOffers.map((o, i) => (
                        <div key={o.id} className={`${styles.myOfferRow} ${i > 0 ? styles.myOfferRowPast : ''}`}>
                          <div className={styles.myOfferMeta}>
                            <span className={`${styles.offerStatus} ${styles[`offerStatus_${o.status}` as keyof typeof styles]}`}>
                              {o.status === 'pending' ? 'Pending response' : o.status.charAt(0).toUpperCase() + o.status.slice(1)}
                            </span>
                            {o.offer_amount != null && o.offer_amount > 0 && (
                              <span className={styles.offerAmount}>{formatPkr(o.offer_amount)}</span>
                            )}
                            <span className={styles.offerTime}>{timeAgo(o.created_at)}</span>
                          </div>
                          {o.message && <p className={styles.offerMsg}>{o.message}</p>}
                          {o.status === 'pending' && (
                            <button className={styles.withdrawBtn} onClick={() => handleWithdrawOffer(o.id)}>
                              Withdraw offer
                            </button>
                          )}
                        </div>
                      ))}
                    </div>
                  )}

                  {/* Status-based messaging and CTA */}
                  {myPendingOffer ? (
                    <p className={styles.offerNote}>
                      Your offer is awaiting a response from the buyer.
                    </p>
                  ) : myLatestOffer?.status === 'accepted' ? (
                    <p className={styles.offerNote}>
                      Your offer was accepted. Coordinate with the buyer to complete the transaction.
                    </p>
                  ) : canSubmitOffer && !showOfferForm ? (
                    <button
                      className={styles.submitOfferBtn}
                      onClick={() => setShowOfferForm(true)}
                    >
                      {myLatestOffer ? 'Submit a New Offer' : 'Submit an Offer'}
                    </button>
                  ) : null}

                  {/* Offer form */}
                  {canSubmitOffer && showOfferForm && (
                    <form onSubmit={handleSubmitOffer} className={styles.offerForm}>
                      <h3 className={styles.offerFormTitle}>
                        {myLatestOffer ? 'New Offer' : 'Submit your offer'}
                      </h3>
                      {myLatestOffer && (
                        <p className={styles.offerFormNote}>
                          Your previous offer was {myLatestOffer.status}. You can submit a new one.
                        </p>
                      )}
                      <div className={styles.offerField}>
                        <label>Offer Amount (PKR)</label>
                        <input type="number" min="0" value={offerAmount} onChange={e => setOfferAmount(e.target.value)} placeholder="0" />
                      </div>
                      <div className={styles.offerField}>
                        <label>Message <span className={styles.fieldRequired}>*</span></label>
                        <textarea
                          value={offerMessage}
                          onChange={e => setOfferMessage(e.target.value)}
                          rows={3}
                          placeholder="Let them know what you have..."
                          required
                          minLength={10}
                        />
                      </div>
                      {offerError && <p className={styles.msgError}>{offerError}</p>}
                      <div className={styles.offerFormActions}>
                        <button type="button" className={styles.offerFormCancel} onClick={() => { setShowOfferForm(false); setOfferError(null) }}>Cancel</button>
                        <button type="submit" className={styles.offerFormSubmit} disabled={submittingOffer}>
                          {submittingOffer ? 'Submitting…' : 'Send Offer'}
                        </button>
                      </div>
                    </form>
                  )}
                </>
              )}
            </>
          )}

          {/* ════════════════════════════════════════
              MEMBER VIEW (non-seller, non-owner)
          ════════════════════════════════════════ */}
          {!isOwner && !isSeller && (
            <div className={styles.memberInfo}>
              <p className={styles.memberInfoText}>Only verified sellers can submit offers on ISO requests.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
