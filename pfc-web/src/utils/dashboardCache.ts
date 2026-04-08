import { supabase } from '@/lib/supabase'

export interface DashboardStats {
  isoPosts: number
  activeListings: number
  unreadMessages: number
}

export interface PulseStats {
  publishedListings: number
  activeIsos: number
  sellers: number
}

let cachedStats: DashboardStats | null = null
let cachedPulse: PulseStats | null = null
let lastFetched: number = 0

// 5 minutes cache duration
const CACHE_DURATION = 5 * 60 * 1000

export async function fetchDashboardData(userId: string, force = false): Promise<{ stats: DashboardStats, pulse: PulseStats }> {
  const now = Date.now()
  if (!force && cachedStats && cachedPulse && (now - lastFetched < CACHE_DURATION)) {
    return { stats: cachedStats, pulse: cachedPulse }
  }

  // ── User-specific stats ──────────────────────────────
  const isoPromise = supabase
    .from('listings')
    .select('id', { count: 'exact', head: true })
    .eq('seller_id', userId)
    .eq('listing_type', 'ISO')
    .not('status', 'in', '("Deleted","Removed")')

  const listingsPromise = supabase
    .from('listings')
    .select('id', { count: 'exact', head: true })
    .eq('seller_id', userId)
    .eq('status', 'Published')
    .neq('listing_type', 'ISO')

  const convsPromise = supabase
    .from('conversations')
    .select('id')
    .or(`buyer_id.eq.${userId},seller_id.eq.${userId}`)

  // ── Marketplace pulse ──────────────────────────────
  const listingsPulsePromise = supabase
    .from('listings')
    .select('id', { count: 'exact', head: true })
    .eq('status', 'Published')
    .neq('listing_type', 'ISO')

  const isosPulsePromise = supabase
    .from('listings')
    .select('id', { count: 'exact', head: true })
    .eq('status', 'Published')
    .eq('listing_type', 'ISO')

  const sellersPulsePromise = supabase
    .from('profiles')
    .select('id', { count: 'exact', head: true })
    .eq('role', 'seller')

  // Run all in parallel
  const [
    isoRes, 
    listingsRes, 
    convsRes,
    listingsPulseRes,
    isosPulseRes,
    sellersPulseRes
  ] = await Promise.all([
    isoPromise, 
    listingsPromise, 
    convsPromise,
    listingsPulsePromise,
    isosPulsePromise,
    sellersPulsePromise
  ])

  let unread = 0
  const convIds = convsRes.data?.map((c: { id: string }) => c.id) ?? []
  if (convIds.length > 0) {
    const { count } = await supabase
      .from('messages')
      .select('id', { count: 'exact', head: true })
      .in('conversation_id', convIds)
      .neq('sender_id', userId)
      .is('read_at', null)
    unread = count ?? 0
  }

  cachedStats = {
    isoPosts: isoRes.count ?? 0,
    activeListings: listingsRes.count ?? 0,
    unreadMessages: unread,
  }

  cachedPulse = {
    publishedListings: listingsPulseRes.count ?? 0,
    activeIsos: isosPulseRes.count ?? 0,
    sellers: sellersPulseRes.count ?? 0,
  }

  lastFetched = now

  return { stats: cachedStats, pulse: cachedPulse }
}
