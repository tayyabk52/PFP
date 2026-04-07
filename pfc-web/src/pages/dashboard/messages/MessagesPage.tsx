import { useEffect, useState, useRef } from 'react'
import { useSearchParams, useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/context/AuthContext'
import { initials, timeAgo, formatPkr } from '@/lib/format'
import { EmptyState } from '@/components/ui/EmptyState'
import { ReviewModal } from '@/components/ui/ReviewModal'
import styles from './MessagesPage.module.css'

// ─── Types ─────────────────────────────────────────────────────────────────────

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
}

// ─── MessagesPage ──────────────────────────────────────────────────────────────

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

  // Listing refs & sale flow
  const [listingRefs, setListingRefs] = useState<ConversationListingRef[]>([])
  const [confirmedSaleIds, setConfirmedSaleIds] = useState<Set<string>>(new Set())
  const [confirmingId, setConfirmingId] = useState<string | null>(null)
  const [reviewedIds, setReviewedIds] = useState<Set<string>>(new Set())
  const [reviewSheet, setReviewSheet] = useState<{ listingId: string; sellerId: string } | null>(null)

  const isSeller = profile?.role === 'seller' || profile?.role === 'admin'

  // ── Fetch conversations ──────────────────────────────────────────────────────

  useEffect(() => {
    if (!user) return
    fetchConversations()
  }, [user])

  // ── Auto-select conversation from ?c= param ──────────────────────────────────

  useEffect(() => {
    if (!targetConvoId || loading) return
    const found = convos.find(c => c.id === targetConvoId)
    if (found) {
      setSelectedId(targetConvoId)
    } else {
      fetchAndSelectConversation(targetConvoId)
    }
  }, [targetConvoId, loading])

  // ── Fetch messages + refs when conversation is selected ──────────────────────

  useEffect(() => {
    if (!selectedId || !user) return
    fetchMessages(selectedId)
    fetchListingRefs(selectedId)
    markMessagesRead(selectedId)
  }, [selectedId])

  // ── Realtime: new messages in selected conversation ──────────────────────────

  useEffect(() => {
    if (!selectedId) return
    const channel = supabase
      .channel(`msg-${selectedId}`)
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages', filter: `conversation_id=eq.${selectedId}` }, () => {
        fetchMessages(selectedId)
        markMessagesRead(selectedId)
        fetchConversations()
      })
      .subscribe()
    return () => { supabase.removeChannel(channel) }
  }, [selectedId])

  // ── Data fetching ────────────────────────────────────────────────────────────

  async function fetchConversations() {
    if (!user) return
    setLoading(true)

    const { data: rawConvos } = await supabase
      .from('conversations')
      .select('id, buyer_id, seller_id, last_message_at, buyer_deleted_at, seller_deleted_at')
      .or(`buyer_id.eq.${user.id},seller_id.eq.${user.id}`)
      .order('last_message_at', { ascending: false })

    if (!rawConvos) { setLoading(false); return }

    const visible = rawConvos.filter(c => {
      if (c.buyer_id === user.id) return !c.buyer_deleted_at
      return !c.seller_deleted_at
    })

    const items: ConversationItem[] = await Promise.all(
      visible.map(async (c) => {
        const otherId = c.buyer_id === user.id ? c.seller_id : c.buyer_id
        const [profileRes, lastMsgRes, unreadRes] = await Promise.all([
          supabase.from('profiles').select('id, display_name, avatar_url').eq('id', otherId).single(),
          supabase.from('messages').select('body').eq('conversation_id', c.id).order('sent_at', { ascending: false }).limit(1).maybeSingle(),
          supabase.from('messages').select('id', { count: 'exact', head: true }).eq('conversation_id', c.id).neq('sender_id', user.id).is('read_at', null),
        ])
        return {
          id: c.id,
          otherUserId: otherId,
          otherUserName: profileRes.data?.display_name ?? 'Member',
          otherUserAvatarUrl: profileRes.data?.avatar_url ?? null,
          lastMessageBody: lastMsgRes.data?.body ?? null,
          lastMessageAt: c.last_message_at,
          isUnread: (unreadRes.count ?? 0) > 0,
        }
      })
    )

    // Convos with messages first (newest), then empty convos
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
    const { data: c } = await supabase
      .from('conversations')
      .select('id, buyer_id, seller_id')
      .eq('id', convoId)
      .single()
    if (!c) return

    const otherId = c.buyer_id === user.id ? c.seller_id : c.buyer_id
    const { data: prof } = await supabase.from('profiles').select('display_name, avatar_url').eq('id', otherId).single()

    const item: ConversationItem = {
      id: convoId,
      otherUserId: otherId,
      otherUserName: prof?.display_name ?? 'Member',
      otherUserAvatarUrl: prof?.avatar_url ?? null,
      lastMessageBody: null,
      lastMessageAt: null,
      isUnread: false,
    }
    setConvos(prev => prev.find(c => c.id === convoId) ? prev : [item, ...prev])
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
    setConvos(prev => prev.map(c => c.id === convoId ? { ...c, isUnread: false } : c))
  }

  async function fetchListingRefs(convoId: string) {
    const { data } = await supabase
      .from('conversation_listings')
      .select('listing_id, variant_id, listings(seller_id, fragrance_name, brand, price_pkr, sale_post_number, status, listing_type, listing_photos(file_url, display_order), listing_variants(id, size_ml, price_pkr))')
      .eq('conversation_id', convoId)

    if (!data) { setListingRefs([]); return }

    const refs: ConversationListingRef[] = (data as any[]).map(row => {
      const l = row.listings
      const photos: { file_url: string; display_order: number }[] = l?.listing_photos ?? []
      const firstPhoto = [...photos].sort((a, b) => a.display_order - b.display_order)[0]
      // If a specific variant was attached, use its price; otherwise use listing min price
      const variant = row.variant_id
        ? (l?.listing_variants ?? []).find((v: any) => v.id === row.variant_id)
        : null
      return {
        listingId: row.listing_id,
        variantId: row.variant_id ?? null,
        fragranceName: l?.fragrance_name ?? '',
        brand: l?.brand ?? '',
        pricePkr: variant?.price_pkr ?? l?.price_pkr ?? 0,
        salePostNumber: l?.sale_post_number ?? '',
        photoUrl: firstPhoto?.file_url ?? null,
        isAvailable: l?.status === 'Published' || l?.status === 'Draft',
        sellerId: l?.seller_id ?? '',
        listingType: l?.listing_type ?? '',
      }
    })

    setListingRefs(refs)
    await fetchConfirmedSales(convoId)
  }

  async function fetchConfirmedSales(convoId: string) {
    const { data } = await supabase
      .from('sale_confirmations')
      .select('listing_id')
      .eq('conversation_id', convoId)

    const confirmedSet = new Set<string>(data?.map((r: any) => r.listing_id) ?? [])
    setConfirmedSaleIds(confirmedSet)

    if (!user || !confirmedSet.size) { setReviewedIds(new Set()); return }
    const { data: reviews } = await supabase
      .from('reviews')
      .select('listing_id')
      .eq('reviewer_id', user.id)
      .in('listing_id', [...confirmedSet])
    setReviewedIds(new Set(reviews?.map((r: any) => r.listing_id) ?? []))
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  async function handleConfirmSale(listingId: string) {
    if (!selectedId || confirmingId) return
    setConfirmingId(listingId)
    const ref = listingRefs.find(r => r.listingId === listingId)
    const { error } = await supabase.rpc('confirm_sale', {
      p_conversation_id: selectedId,
      p_listing_id: listingId,
      p_variant_id: ref?.variantId ?? null,
    })
    if (!error) {
      setConfirmedSaleIds(prev => new Set([...prev, listingId]))
      fetchMessages(selectedId)
      // Also update local listing availability logic
      setListingRefs(prev => prev.map(r => r.listingId === listingId ? { ...r, isAvailable: false } : r))
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
    setConvos(prev => prev.map(c => c.id === selectedId ? { ...c, lastMessageBody: body, lastMessageAt: new Date().toISOString() } : c))
  }

  const selectedConvo = convos.find(c => c.id === selectedId)

  // ── Render ───────────────────────────────────────────────────────────────────

  return (
    <div className={styles.page}>

      {/* ── Conversation list ── */}
      <aside className={`${styles.convoList} ${selectedId ? styles.convoListHidden : ''}`}>
        <p className={styles.inboxLabel}>Inbox</p>
        {loading ? (
          <div className={styles.spinnerWrap}><div className={styles.spinner} /></div>
        ) : convos.length === 0 ? (
          <EmptyState
            icon={
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            }
            title="No messages yet"
            description="Your conversations with sellers will appear here."
          />
        ) : (
          <div className={styles.convoItems}>
            {convos.map(c => {
              const avatarInitials = initials(c.otherUserName)
              return (
                <button
                  key={c.id}
                  className={`${styles.convoRow} ${c.id === selectedId ? styles.convoRowActive : ''}`}
                  onClick={() => setSelectedId(c.id)}
                >
                  <div className={styles.convoAvatarWrap}>
                    <div className={styles.convoAvatar}>
                      {c.otherUserAvatarUrl
                        ? <img src={c.otherUserAvatarUrl} alt={c.otherUserName} className={styles.convoAvatarImg} />
                        : avatarInitials}
                    </div>
                    {c.isUnread && <span className={styles.unreadDot} aria-label="Unread" />}
                  </div>
                  <div className={styles.convoInfo}>
                    <span className={`${styles.convoName} ${c.isUnread ? styles.convoNameUnread : ''}`}>
                      {c.otherUserName}
                    </span>
                    <span className={styles.convoPreview}>
                      {c.lastMessageBody ?? 'New conversation'}
                    </span>
                  </div>
                  {c.lastMessageAt && (
                    <span className={styles.convoTime}>{timeAgo(c.lastMessageAt)}</span>
                  )}
                </button>
              )
            })}
          </div>
        )}
      </aside>

      {/* ── Chat panel ── */}
      <main className={`${styles.chatPanel} ${selectedId ? styles.chatPanelVisible : ''}`}>
        {selectedId && selectedConvo ? (
          <div className={styles.chatContent}>

            {/* Chat header */}
            <div className={styles.chatHeader}>
              <button className={styles.backToList} onClick={() => setSelectedId(null)} aria-label="Back to inbox">
                <svg width="18" height="18" viewBox="0 0 18 18" fill="none" aria-hidden="true">
                  <path d="M11 4L6 9l5 5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </button>
              <div className={styles.chatHeaderAvatar}>
                {selectedConvo.otherUserAvatarUrl
                  ? <img src={selectedConvo.otherUserAvatarUrl} alt={selectedConvo.otherUserName} className={styles.chatHeaderAvatarImg} />
                  : initials(selectedConvo.otherUserName)}
              </div>
              <span className={styles.chatName}>{selectedConvo.otherUserName}</span>
            </div>

            {/* Listing refs strip */}
            {listingRefs.length > 0 && (
              <div className={styles.refsStrip}>
                <p className={styles.refsLabel}>Attached Listings</p>
                <div className={styles.refsScroll}>
                  {listingRefs.map(ref => {
                    const isConfirmed = confirmedSaleIds.has(ref.listingId)
                    const isReviewed = reviewedIds.has(ref.listingId)
                    const isConfirming = confirmingId === ref.listingId
                    return (
                      <div
                        key={ref.listingId}
                        className={`${styles.refCard} ${!ref.isAvailable && !isConfirmed ? styles.refCardUnavailable : ''} ${isConfirmed ? styles.refCardConfirmed : ''}`}
                        onClick={() => navigate(ref.listingType === 'ISO' ? `/iso/${ref.listingId}` : `/marketplace/${ref.listingId}`)}
                        role="button"
                        tabIndex={0}
                        onKeyDown={e => e.key === 'Enter' && navigate(ref.listingType === 'ISO' ? `/iso/${ref.listingId}` : `/marketplace/${ref.listingId}`)}
                      >
                        <div className={styles.refThumb}>
                          {ref.photoUrl
                            ? <img src={ref.photoUrl} alt={ref.fragranceName} />
                            : <span>{ref.fragranceName.charAt(0)}</span>}
                        </div>
                        <div className={styles.refInfo}>
                          <p className={styles.refName}>{ref.fragranceName}</p>
                          <p className={styles.refMeta}>
                            {ref.pricePkr > 0 ? formatPkr(ref.pricePkr) : 'Swap'}
                          </p>
                          {ref.listingType === 'ISO' && (
                            <span className={styles.isoTag}>ISO</span>
                          )}
                          {/* Seller: confirm sale */}
                          {isSeller && (ref.isAvailable || isConfirmed) && (
                            !isConfirmed ? (
                              <button
                                className={styles.refConfirmBtn}
                                onClick={e => { e.stopPropagation(); handleConfirmSale(ref.listingId) }}
                                disabled={isConfirming}
                              >
                                {isConfirming ? 'Confirming…' : 'Confirm Sale'}
                              </button>
                            ) : (
                              <button className={styles.refConfirmedBtn} disabled>
                                Sale Confirmed ✓
                              </button>
                            )
                          )}
                          {/* Buyer: leave a review */}
                          {!isSeller && isConfirmed && !isReviewed && (
                            <button
                              className={styles.refReviewBtn}
                              onClick={e => {
                                e.stopPropagation()
                                setReviewSheet({ listingId: ref.listingId, sellerId: ref.sellerId })
                              }}
                            >
                              Leave a Review
                            </button>
                          )}
                          {/* Status badges */}
                          {isConfirmed && !isSeller && isReviewed && (
                            <span className={styles.refSoldBadge}>Reviewed</span>
                          )}
                        </div>
                      </div>
                    )
                  })}
                </div>
              </div>
            )}

            {/* Messages */}
            <div className={styles.messageArea}>
              {msgLoading ? (
                <div className={styles.spinnerWrap}><div className={styles.spinner} /></div>
              ) : messages.length === 0 ? (
                <div className={styles.noMessages}>
                  <p>No messages yet. Say hello!</p>
                </div>
              ) : (
                <>
                  {messages.map(m => {
                    const isMine = m.sender_id === user?.id
                    const isSystem = !m.sender_id || (m.sender_id !== user?.id && m.sender_id !== selectedConvo?.otherUserId)
                    if (isSystem) {
                      return (
                        <div key={m.id} className={styles.systemMsg}>
                          <span>{m.body}</span>
                        </div>
                      )
                    }
                    return (
                      <div key={m.id} className={`${styles.bubble} ${isMine ? styles.bubbleMine : styles.bubbleTheirs}`}>
                        <p className={styles.bubbleText}>{m.body}</p>
                        <div className={styles.bubbleMeta}>
                          <span className={styles.bubbleTime}>{timeAgo(m.sent_at)}</span>
                          {isMine && (
                            <span className={`${styles.readTick} ${m.read_at ? styles.readTickRead : ''}`} aria-label={m.read_at ? 'Read' : 'Sent'}>
                              <svg width="14" height="10" viewBox="0 0 14 10" fill="none" aria-hidden="true">
                                {m.read_at ? (
                                  <>
                                    <path d="M1 5l3 3L9 2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                                    <path d="M5 5l3 3 5-6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                                  </>
                                ) : (
                                  <path d="M2 5l3 3L12 1" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
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

            {/* Input */}
            <div className={styles.inputRow}>
              <input
                className={styles.msgInput}
                type="text"
                placeholder="Type a message…"
                value={newMsg}
                onChange={e => setNewMsg(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && !e.shiftKey && handleSend()}
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
                  <path d="M16 2L8 10M16 2L11 16l-3-6-6-3 14-5z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </button>
            </div>
          </div>
        ) : (
          <EmptyState
            icon={
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            }
            title="Select a conversation"
            description="Choose a conversation from the inbox to view messages."
          />
        )}
      </main>

      {/* ── Review modal ── */}
      {reviewSheet && (
        <ReviewModal
          listingId={reviewSheet.listingId}
          sellerId={reviewSheet.sellerId}
          onClose={() => setReviewSheet(null)}
          onSuccess={() => setReviewedIds(prev => new Set([...prev, reviewSheet.listingId]))}
        />
      )}
    </div>
  )
}
