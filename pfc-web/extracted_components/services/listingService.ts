/**
 * listingService — data access layer for listings.
 *
 * Built on Supabase. The key method for the Browse page is searchNearby(),
 * which calls a PostGIS RPC function that returns results sorted by distance.
 *
 * To adapt this to a different backend:
 *   1. Replace the `supabase.rpc(...)` call in searchNearby with your own API call.
 *   2. Replace `supabase.from('categories')` with your own category fetch.
 *   3. Keep the return types the same so the store and page don't need to change.
 */

import { supabase } from '@/lib/supabase'
import { toPostgisPoint } from '@/lib/geo'
import type {
  Listing,
  ListingSearchResult,
  ListingStatus,
  ListingType,
  ListingCondition,
  Category,
  CategoryWithChildren,
  GeoPoint,
} from '@/types'

// ── Param types ──────────────────────────────────────────────

interface SearchNearbyParams {
  lat: number
  lng: number
  radiusKm: number
  listingType?: ListingType | null
  categoryId?: string | null
  searchText?: string | null
  minRating?: number | null
  limit?: number
  offset?: number
  userId?: string | null
}

interface CreateListingData {
  title: string
  description: string
  listing_type: ListingType
  category_id: string
  condition: ListingCondition | null
  location: GeoPoint | null
  location_text: string | null
  max_distance_km: number
  tags: string[]
}

// ── Service ──────────────────────────────────────────────────

export const listingService = {
  /**
   * Search listings near a geographic point.
   * Calls the `search_listings_nearby` Supabase RPC (PostGIS).
   * Replace this with your own distance-search endpoint.
   */
  async searchNearby(params: SearchNearbyParams): Promise<ListingSearchResult[]> {
    const rpcParams: Record<string, unknown> = {
      p_lat: params.lat,
      p_lng: params.lng,
      p_radius_km: params.radiusKm,
    }
    if (params.listingType) rpcParams.p_listing_type = params.listingType
    if (params.categoryId)  rpcParams.p_category_id  = params.categoryId
    if (params.searchText)  rpcParams.p_search_text  = params.searchText
    if (params.minRating != null) rpcParams.p_min_rating = params.minRating
    if (params.limit != null)     rpcParams.p_limit  = params.limit
    if (params.offset != null)    rpcParams.p_offset = params.offset
    if (params.userId)            rpcParams.p_user_id = params.userId

    const { data, error } = await supabase.rpc('search_listings_nearby', rpcParams)
    if (error) throw error
    return (data ?? []) as ListingSearchResult[]
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('listings')
      .select(
        '*, owner:profiles!user_id(id, display_name, avatar_url, trust_score, total_exchanges, created_at, verification_status), category:categories!category_id(id, name, slug, parent_id)',
      )
      .eq('id', id)
      .single()
    if (error) throw error
    return data
  },

  async getUserListings(userId: string) {
    const { data, error } = await supabase
      .from('listings')
      .select('*')
      .eq('user_id', userId)
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
    if (error) throw error
    return (data ?? []) as Listing[]
  },

  async create(data: CreateListingData): Promise<Listing> {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('You must be logged in to create a listing')

    const { location, ...rest } = data
    const { data: listing, error } = await supabase
      .from('listings')
      .insert({
        ...rest,
        user_id: user.id,
        location: location ? toPostgisPoint(location) : null,
        status: 'draft' as ListingStatus,
      })
      .select('*')
      .single()
    if (error) throw error
    return listing as Listing
  },

  async update(id: string, data: Partial<CreateListingData>): Promise<Listing> {
    const { location, ...rest } = data
    const updateData: Record<string, unknown> = { ...rest }
    if (location !== undefined) {
      updateData.location = location ? toPostgisPoint(location) : null
    }
    const { data: listing, error } = await supabase
      .from('listings')
      .update(updateData)
      .eq('id', id)
      .select('*')
      .single()
    if (error) throw error
    return listing as Listing
  },

  async publish(id: string): Promise<Listing> {
    const { data, error } = await supabase
      .from('listings')
      .update({ status: 'active' as ListingStatus })
      .eq('id', id)
      .select('*')
      .single()
    if (error) throw error
    return data as Listing
  },

  async softDelete(id: string): Promise<void> {
    const { error } = await supabase
      .from('listings')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id)
    if (error) throw error
  },

  async updateStatus(id: string, status: ListingStatus): Promise<Listing> {
    const { data, error } = await supabase
      .from('listings')
      .update({ status })
      .eq('id', id)
      .select('*')
      .single()
    if (error) throw error
    return data as Listing
  },

  async uploadImages(listingId: string, files: File[]): Promise<string[]> {
    const paths: string[] = []
    for (const file of files) {
      const timestamp = Date.now()
      const path = `${listingId}/${timestamp}-${file.name}`
      const { error } = await supabase.storage.from('listings').upload(path, file)
      if (error) throw error
      paths.push(path)
    }
    return paths
  },

  async deleteImage(path: string): Promise<void> {
    const { error } = await supabase.storage.from('listings').remove([path])
    if (error) throw error
  },

  async incrementViews(id: string): Promise<void> {
    await supabase.rpc('increment_views', { p_listing_id: id })
  },

  async toggleFavorite(userId: string, listingId: string): Promise<{ isFavorited: boolean }> {
    const { data: existing } = await supabase
      .from('listing_favorites')
      .select('user_id')
      .eq('user_id', userId)
      .eq('listing_id', listingId)
      .maybeSingle()

    if (existing) {
      const { error } = await supabase
        .from('listing_favorites')
        .delete()
        .eq('user_id', userId)
        .eq('listing_id', listingId)
      if (error) throw error
      return { isFavorited: false }
    } else {
      const { error } = await supabase
        .from('listing_favorites')
        .insert({ user_id: userId, listing_id: listingId })
      if (error) throw error
      return { isFavorited: true }
    }
  },

  async isFavorited(userId: string, listingId: string): Promise<boolean> {
    const { data } = await supabase
      .from('listing_favorites')
      .select('user_id')
      .eq('user_id', userId)
      .eq('listing_id', listingId)
      .maybeSingle()
    return !!data
  },

  async getUserFavorites(userId: string) {
    const { data, error } = await supabase
      .from('listing_favorites')
      .select('*, listing:listings!listing_id(*)')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
    if (error) throw error
    return data
  },

  /**
   * Fetch all active categories and build a parent → children tree.
   * Replace with your own API call if not using Supabase.
   */
  async getCategories(): Promise<CategoryWithChildren[]> {
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .eq('is_active', true)
      .order('sort_order', { ascending: true })
    if (error) throw error

    const categories = (data ?? []) as Category[]
    const topLevel = categories.filter((c) => c.parent_id === null)
    const children = categories.filter((c) => c.parent_id !== null)

    return topLevel.map((parent) => ({
      ...parent,
      children: children.filter((c) => c.parent_id === parent.id),
    }))
  },
}
