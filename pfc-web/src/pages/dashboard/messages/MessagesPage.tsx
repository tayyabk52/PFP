import { useEffect, useRef, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/context/AuthContext'
import { formatPkr, initials, timeAgo } from '@/lib/format'
import { EmptyState } from '@/components/ui/EmptyState'
import { ReviewModal } from '@/components/ui/ReviewModal'
import styles from './MessagesPage.module.css'

interface ConversationItem {
  id: string
  otherUserId: string
  otherUserName: string
  otherUserAvatarUrl: string | null
  lastMessageBody: string | null
  lastMessageAt: string | null
  isUnread: boolean
}

interface ChatMessage {
  id: string
  sender_id: string | null
  body: string
  sent_at: string
  read_at: string | null
}

interface ConversationListingRef {
  listingId: string
  variantId: string | null
  fragranceName: string
  brand: string
  pricePkr: number
  salePostNumber: string
  photoUrl: string | null
  isAvailable: boolean
  sellerId: string
  listingType: string
  status: string
}

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

interface ReviewedListing {
  listingId: string
  submittedAt: string
  review: ExistingReview
}

interface ReviewSheetState {
  listingId: string
  sellerId: string
  sellerName: string
  fragranceName: string
  brand: string
  existingReview?: ExistingReview | null
}

interface ReviewedListingRow {
  id: string
  listing_id: string
  rating: number
  comment: string
  submitted_at: string
  review_photos: ExistingReviewPhoto[] | null
}

export function MessagesPage() {
  const { user, profile } = useAuth()
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const targetConvoId = searchParams.get('c')

  const [convos, setConvos] = useState<ConversationItem[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [messages, setMessages] = useState<ChatMessage[]>([])
  const [msgLoading, setMsgLoading] = useState(false)
  const [newMsg, setNewMsg] = useState('')
  const [sending, setSending] = useState(false)
  const messagesEndRef = useRef<HTMLDivElement>(null)

  const [listingRefs, setListingRefs] = useState<ConversationListingRef[]>([])
  const [confirmedSaleIds, setConfirmedSaleIds] = useState<Set<string>>(new Set())
  const [confirmingId, setConfirmingId] = useState<string | null>(null)
  const [reviewedListings, setReviewedListings] = useState<Record<string, ReviewedListing>>({})
  const [reviewSheet, setReviewSheet] = useState<ReviewSheetState | null>(null)

  const isSeller = profile?.role === 'seller' || profile?.role === 'admin'

  useEffect(() => {
    if (!user) return
    fetchConversations()
  }, [user])

  useEffect(() => {
    if (!targetConvoId || loading) return
    const found = convos.find(convo => convo.id === targetConvoId)
    if (found) {
      setSelectedId(targetConvoId)
    } else {
      fetchAndSelectConversation(targetConvoId)
    }
  }, [targetConvoId, loading, convos])

  useEffect(() => {
    if (!selectedId || !user) return
    fetchMessages(selectedId)
    fetchListingRefs(selectedId)
    markMessagesRead(selectedId)
  }, [selectedId, user])

  useEffect(() => {
    if (!selectedId) return
    const channel = supabase
      .channel(`msg-${selectedId}`)
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'messages', filter: `conversation_id=eq.${selectedId}` },
        () => {
          fetchMessages(selectedId)
          markMessagesRead(selectedId)
          fetchConversations()
        }
      )
      .subscribe()
    return () => {
      supabase.removeChannel(channel)
    }
  }, [selectedId])

  async function fetchConversations() {
    if (!user) return
    setLoading(true)

    const { data: rawConvos } = await supabase
      .from('conversations')
      .select('id, buyer_id, seller_id, last_message_at, buyer_deleted_at, seller_deleted_at')
      .or(`buyer_id.eq.${user.id},seller_id.eq.${user.id}`)
      .order('last_message_at', { ascending: false })

    if (!rawConvos) {
      setLoading(false)
      return
    }

    const visible = rawConvos.filter(convo => {
      if (convo.buyer_id === user.id) return !convo.buyer_deleted_at
      return !convo.seller_deleted_at
    })

    const items: ConversationItem[] = await Promise.all(
      visible.map(async convo => {
        const otherId = convo.buyer_id === user.id ? convo.seller_id : convo.buyer_id
        const [profileRes, lastMsgRes, unreadRes] = await Promise.all([
          supabase.from('profiles').select('id, display_name, avatar_url').eq('id', otherId).single(),
          supabase
            .from('messages')
            .select('body')
            .eq('conversation_id', convo.id)
            .order('sent_at', { ascending: false })
            .limit(1)
            .maybeSingle(),
          supabase
            .from('messages')
            .select('id', { count: 'exact', head: true })
            .eq('conversation_id', convo.id)
            .neq('sender_id', user.id)
            .is('read_at', null),
        ])

        return {
          id: convo.id,
          otherUserId: otherId,
          otherUserName: profileRes.data?.display_name ?? 'Member',
          otherUserAvatarUrl: profileRes.data?.avatar_url ?? null,
          lastMessageBody: lastMsgRes.data?.body ?? null,
          lastMessageAt: convo.last_message_at,
          isUnread: (unreadRes.count ?? 0) > 0,
        }
      })
    )

    items.sort((a, b) => {
      if (!a.lastMessageAt && !b.lastMessageAt) return 0
      if (!a.lastMessageAt) return 1
      if (!b.lastMessageAt) return -1
      return new Date(b.lastMessageAt).getTime() - new Date(a.lastMessageAt).getTime()
    })

    setConvos(items)
    setLoading(false)
  }

  async function fetchAndSelectConversation(convoId: string) {
    if (!user) return
    const { data: convo } = await supabase
      .from('conversations')
      .select('id, buyer_id, seller_id')
      .eq('id', convoId)
      .single()

    if (!convo) return

    const otherId = convo.buyer_id === user.id ? convo.seller_id : convo.buyer_id
    const { data: prof } = await supabase
      .from('profiles')
      .select('display_name, avatar_url')
      .eq('id', otherId)
      .single()

    const item: ConversationItem = {
      id: convoId,
      otherUserId: otherId,
      otherUserName: prof?.display_name ?? 'Member',
      otherUserAvatarUrl: prof?.avatar_url ?? null,
      lastMessageBody: null,
      lastMessageAt: null,
      isUnread: false,
    }

    setConvos(prev => (prev.find(entry => entry.id === convoId) ? prev : [item, ...prev]))
    setSelectedId(convoId)
  }

  async function fetchMessages(convoId: string) {
    setMsgLoading(true)
    const { data } = await supabase
      .from('messages')
      .select('id, sender_id, body, sent_at, read_at')
      .eq('conversation_id', convoId)
      .order('sent_at', { ascending: true })

    setMessages((data as ChatMessage[]) ?? [])
    setMsgLoading(false)
    setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 50)
  }

  async function markMessagesRead(convoId: string) {
    if (!user) return
    await supabase
      .from('messages')
      .update({ read_at: new Date().toISOString() })
      .eq('conversation_id', convoId)
      .neq('sender_id', user.id)
      .is('read_at', null)

    setConvos(prev => prev.map(convo => (convo.id === convoId ? { ...convo, isUnread: false } : convo)))
  }

  async function fetchListingRefs(convoId: string) {
    const { data } = await supabase
      .from('conversation_listings')
      .select('listing_id, variant_id, listings(seller_id, fragrance_name, brand, price_pkr, sale_post_number, status, listing_type, listing_photos(file_url, display_order), listing_variants(id, size_ml, price_pkr))')
      .eq('conversation_id', convoId)

    if (!data) {
      setListingRefs([])
      return
    }

    const refs: ConversationListingRef[] = (data as Array<Record<string, unknown>>).map(row => {
      const listing = row.listings as
        | {
            seller_id?: string
            fragrance_name?: string
            brand?: string
            price_pkr?: number
            sale_post_number?: string
            status?: string
            listing_type?: string
            listing_photos?: { file_url: string; display_order: number }[]
            listing_variants?: { id: string; size_ml: number; price_pkr: number }[]
          }
        | null

      const photos = listing?.listing_photos ?? []
      const firstPhoto = [...photos].sort((a, b) => a.display_order - b.display_order)[0]
      const variant = row.variant_id
        ? (listing?.listing_variants ?? []).find(entry => entry.id === row.variant_id)
        : null

      return {
        listingId: row.listing_id as string,
        variantId: (row.variant_id as string | null) ?? null,
        fragranceName: listing?.fragrance_name ?? '',
        brand: listing?.brand ?? '',
        pricePkr: variant?.price_pkr ?? listing?.price_pkr ?? 0,
        salePostNumber: listing?.sale_post_number ?? '',
        photoUrl: firstPhoto?.file_url ?? null,
        isAvailable: listing?.status === 'Published' || listing?.status === 'Draft',
        sellerId: listing?.seller_id ?? '',
        listingType: listing?.listing_type ?? '',
        status: listing?.status ?? '',
      }
    })

    setListingRefs(refs)
    await fetchConfirmedSales(convoId, refs)
  }

  async function fetchConfirmedSales(convoId: string, refsOverride?: ConversationListingRef[]) {
    const { data } = await supabase
      .from('sale_confirmations')
      .select('listing_id')
      .eq('conversation_id', convoId)

    const confirmedSet = new Set<string>(data?.map(row => row.listing_id as string) ?? [])
    const refs = refsOverride ?? listingRefs
    refs.filter(ref => ref.status === 'Sold').forEach(ref => confirmedSet.add(ref.listingId))
    setConfirmedSaleIds(confirmedSet)

    if (!user || confirmedSet.size === 0) {
      setReviewedListings({})
      return
    }

    const { data: reviews } = await supabase
      .from('reviews')
      .select('id, listing_id, rating, comment, submitted_at, review_photos(id, file_url, path)')
      .eq('reviewer_id', user.id)
      .in('listing_id', [...confirmedSet])

    const nextReviewedListings: Record<string, ReviewedListing> = {}
    for (const review of ((reviews ?? []) as unknown as ReviewedListingRow[])) {
      nextReviewedListings[review.listing_id] = {
        listingId: review.listing_id,
        submittedAt: review.submitted_at,
        review: {
          id: review.id,
          rating: review.rating,
          comment: review.comment,
          photos: review.review_photos ?? [],
        },
      }
    }
    setReviewedListings(nextReviewedListings)
  }

  async function handleConfirmSale(listingId: string) {
    if (!selectedId || confirmingId) return
    setConfirmingId(listingId)
    const ref = listingRefs.find(entry => entry.listingId === listingId)
    const { error } = await supabase.rpc('confirm_sale', {
      p_conversation_id: selectedId,
      p_listing_id: listingId,
      p_variant_id: ref?.variantId ?? null,
    })

    if (!error) {
      fetchMessages(selectedId)
      await fetchConfirmedSales(selectedId)
      setListingRefs(prev =>
        prev.map(entry => (entry.listingId === listingId ? { ...entry, isAvailable: false } : entry))
      )
    }

    setConfirmingId(null)
  }

  async function handleSend() {
    if (!newMsg.trim() || !selectedId || !user || sending) return
    setSending(true)
    const body = newMsg.trim().slice(0, 1000)
    const optimistic: ChatMessage = {
      id: crypto.randomUUID(),
      sender_id: user.id,
      body,
      sent_at: new Date().toISOString(),
      read_at: null,
    }
    setMessages(prev => [...prev, optimistic])
    setNewMsg('')
    setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 50)
    await supabase.from('messages').insert({ conversation_id: selectedId, sender_id: user.id, body })
    setSending(false)
    setConvos(prev =>
      prev.map(convo =>
        convo.id === selectedId ? { ...convo, lastMessageBody: body, lastMessageAt: new Date().toISOString() } : convo
      )
    )
  }

  const selectedConvo = convos.find(convo => convo.id === selectedId)

  return (
    <div className={styles.page}>
      <aside className={`${styles.convoList} ${selectedId ? styles.convoListHidden : ''}`}>
        <p className={styles.inboxLabel}>Inbox</p>
        {loading ? (
          <div className={styles.spinnerWrap}>
            <div className={styles.spinner} />
          </div>
        ) : convos.length === 0 ? (
          <EmptyState
            icon={
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                <path
                  d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            }
            title="No messages yet"
            description="Your conversations with sellers will appear here."
          />
        ) : (
          <div className={styles.convoItems}>
            {convos.map(convo => {
              const avatarInitials = initials(convo.otherUserName)
              return (
                <button
                  key={convo.id}
                  className={`${styles.convoRow} ${convo.id === selectedId ? styles.convoRowActive : ''}`}
                  onClick={() => setSelectedId(convo.id)}
                >
                  <div className={styles.convoAvatarWrap}>
                    <div className={styles.convoAvatar}>
                      {convo.otherUserAvatarUrl ? (
                        <img
                          src={convo.otherUserAvatarUrl}
                          alt={convo.otherUserName}
                          className={styles.convoAvatarImg}
                        />
                      ) : (
                        avatarInitials
                      )}
                    </div>
                    {convo.isUnread && <span className={styles.unreadDot} aria-label="Unread" />}
                  </div>
                  <div className={styles.convoInfo}>
                    <span className={`${styles.convoName} ${convo.isUnread ? styles.convoNameUnread : ''}`}>
                      {convo.otherUserName}
                    </span>
                    <span className={styles.convoPreview}>{convo.lastMessageBody ?? 'New conversation'}</span>
                  </div>
                  {convo.lastMessageAt && <span className={styles.convoTime}>{timeAgo(convo.lastMessageAt)}</span>}
                </button>
              )
            })}
          </div>
        )}
      </aside>

      <main className={`${styles.chatPanel} ${selectedId ? styles.chatPanelVisible : ''}`}>
        {selectedId && selectedConvo ? (
          <div className={styles.chatContent}>
            <div className={styles.chatHeader}>
              <button className={styles.backToList} onClick={() => setSelectedId(null)} aria-label="Back to inbox">
                <svg width="18" height="18" viewBox="0 0 18 18" fill="none" aria-hidden="true">
                  <path
                    d="M11 4L6 9l5 5"
                    stroke="currentColor"
                    strokeWidth="1.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </button>
              <div className={styles.chatHeaderAvatar}>
                {selectedConvo.otherUserAvatarUrl ? (
                  <img
                    src={selectedConvo.otherUserAvatarUrl}
                    alt={selectedConvo.otherUserName}
                    className={styles.chatHeaderAvatarImg}
                  />
                ) : (
                  initials(selectedConvo.otherUserName)
                )}
              </div>
              <span className={styles.chatName}>{selectedConvo.otherUserName}</span>
            </div>

            {listingRefs.length > 0 && (
              <div className={styles.refsStrip}>
                <p className={styles.refsLabel}>Attached Listings</p>
                <div className={styles.refsScroll}>
                  {listingRefs.map(ref => {
                    const isConfirmed = confirmedSaleIds.has(ref.listingId)
                    const reviewedListing = reviewedListings[ref.listingId]
                    const isReviewed = !!reviewedListing
                    const isConfirming = confirmingId === ref.listingId
                    const canEditReview =
                      !!reviewedListing &&
                      new Date(reviewedListing.submittedAt).getTime() > Date.now() - 48 * 60 * 60 * 1000

                    return (
                      <div
                        key={ref.listingId}
                        className={`${styles.refCard} ${!ref.isAvailable && !isConfirmed ? styles.refCardUnavailable : ''} ${isConfirmed ? styles.refCardConfirmed : ''}`}
                        onClick={() =>
                          navigate(ref.listingType === 'ISO' ? `/iso/${ref.listingId}` : `/marketplace/${ref.listingId}`)
                        }
                        role="button"
                        tabIndex={0}
                        onKeyDown={event => {
                          if (event.key === 'Enter') {
                            navigate(ref.listingType === 'ISO' ? `/iso/${ref.listingId}` : `/marketplace/${ref.listingId}`)
                          }
                        }}
                      >
                        <div className={styles.refThumb}>
                          {ref.photoUrl ? <img src={ref.photoUrl} alt={ref.fragranceName} /> : <span>{ref.fragranceName.charAt(0)}</span>}
                        </div>
                        <div className={styles.refInfo}>
                          <p className={styles.refName}>{ref.fragranceName}</p>
                          <p className={styles.refMeta}>{ref.pricePkr > 0 ? formatPkr(ref.pricePkr) : 'Swap'}</p>
                          {ref.listingType === 'ISO' && <span className={styles.isoTag}>ISO</span>}

                          {isSeller && (ref.isAvailable || isConfirmed) && (
                            <>
                              {!isConfirmed ? (
                                <button
                                  className={styles.refConfirmBtn}
                                  onClick={event => {
                                    event.stopPropagation()
                                    handleConfirmSale(ref.listingId)
                                  }}
                                  disabled={isConfirming}
                                >
                                  {isConfirming ? 'Confirming...' : 'Confirm Sale'}
                                </button>
                              ) : (
                                <button className={styles.refConfirmedBtn} disabled>
                                  Sale Confirmed
                                </button>
                              )}
                            </>
                          )}

                          {!isSeller && isConfirmed && !isReviewed && (
                            <button
                              className={styles.refReviewBtn}
                              onClick={event => {
                                event.stopPropagation()
                                setReviewSheet({
                                  listingId: ref.listingId,
                                  sellerId: ref.sellerId,
                                  sellerName: selectedConvo.otherUserName,
                                  fragranceName: ref.fragranceName,
                                  brand: ref.brand,
                                })
                              }}
                            >
                              Leave a Review
                            </button>
                          )}

                          {isConfirmed && !isSeller && isReviewed && (
                            <div className={styles.refReviewRow}>
                              <span className={styles.refSoldBadge}>Reviewed</span>
                              {canEditReview && (
                                <button
                                  type="button"
                                  className={styles.refEditBtn}
                                  onClick={event => {
                                    event.stopPropagation()
                                    setReviewSheet({
                                      listingId: ref.listingId,
                                      sellerId: ref.sellerId,
                                      sellerName: selectedConvo.otherUserName,
                                      fragranceName: ref.fragranceName,
                                      brand: ref.brand,
                                      existingReview: reviewedListing.review,
                                    })
                                  }}
                                  aria-label="Edit review"
                                >
                                  <svg width="11" height="11" viewBox="0 0 14 14" fill="none" aria-hidden="true">
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
                          )}
                        </div>
                      </div>
                    )
                  })}
                </div>
              </div>
            )}

            <div className={styles.messageArea}>
              {msgLoading ? (
                <div className={styles.spinnerWrap}>
                  <div className={styles.spinner} />
                </div>
              ) : messages.length === 0 ? (
                <div className={styles.noMessages}>
                  <p>No messages yet. Say hello!</p>
                </div>
              ) : (
                <>
                  {messages.map(message => {
                    const isMine = message.sender_id === user?.id
                    const isSystem =
                      !message.sender_id ||
                      (message.sender_id !== user?.id && message.sender_id !== selectedConvo.otherUserId)

                    if (isSystem) {
                      return (
                        <div key={message.id} className={styles.systemMsg}>
                          <span>{message.body}</span>
                        </div>
                      )
                    }

                    return (
                      <div
                        key={message.id}
                        className={`${styles.bubble} ${isMine ? styles.bubbleMine : styles.bubbleTheirs}`}
                      >
                        <p className={styles.bubbleText}>{message.body}</p>
                        <div className={styles.bubbleMeta}>
                          <span className={styles.bubbleTime}>{timeAgo(message.sent_at)}</span>
                          {isMine && (
                            <span
                              className={`${styles.readTick} ${message.read_at ? styles.readTickRead : ''}`}
                              aria-label={message.read_at ? 'Read' : 'Sent'}
                            >
                              <svg width="14" height="10" viewBox="0 0 14 10" fill="none" aria-hidden="true">
                                {message.read_at ? (
                                  <>
                                    <path
                                      d="M1 5l3 3L9 2"
                                      stroke="currentColor"
                                      strokeWidth="1.5"
                                      strokeLinecap="round"
                                      strokeLinejoin="round"
                                    />
                                    <path
                                      d="M5 5l3 3 5-6"
                                      stroke="currentColor"
                                      strokeWidth="1.5"
                                      strokeLinecap="round"
                                      strokeLinejoin="round"
                                    />
                                  </>
                                ) : (
                                  <path
                                    d="M2 5l3 3L12 1"
                                    stroke="currentColor"
                                    strokeWidth="1.5"
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                  />
                                )}
                              </svg>
                            </span>
                          )}
                        </div>
                      </div>
                    )
                  })}
                  <div ref={messagesEndRef} />
                </>
              )}
            </div>

            <div className={styles.inputRow}>
              <input
                className={styles.msgInput}
                type="text"
                placeholder="Type a message..."
                value={newMsg}
                onChange={event => setNewMsg(event.target.value)}
                onKeyDown={event => event.key === 'Enter' && !event.shiftKey && handleSend()}
                maxLength={1000}
                aria-label="Message input"
              />
              <button
                className={styles.sendBtn}
                onClick={handleSend}
                disabled={!newMsg.trim() || sending}
                aria-label="Send"
              >
                <svg width="18" height="18" viewBox="0 0 18 18" fill="none" aria-hidden="true">
                  <path
                    d="M16 2L8 10M16 2L11 16l-3-6-6-3 14-5z"
                    stroke="currentColor"
                    strokeWidth="1.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </button>
            </div>
          </div>
        ) : (
          <EmptyState
            icon={
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                <path
                  d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            }
            title="Select a conversation"
            description="Choose a conversation from the inbox to view messages."
          />
        )}
      </main>

      {reviewSheet && (
        <ReviewModal
          listingId={reviewSheet.listingId}
          sellerId={reviewSheet.sellerId}
          sellerName={reviewSheet.sellerName}
          fragranceName={reviewSheet.fragranceName}
          brand={reviewSheet.brand}
          existingReview={reviewSheet.existingReview ?? null}
          onClose={() => setReviewSheet(null)}
          onSuccess={async () => {
            if (selectedId) {
              await fetchConfirmedSales(selectedId)
            }
            setReviewSheet(null)
          }}
        />
      )}
    </div>
  )
}
