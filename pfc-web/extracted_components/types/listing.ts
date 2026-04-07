/**
 * Types needed by the Browse page and its sub-components.
 * Extracted from src/types/index.ts — use only these if you don't want
 * to copy the full project type file.
 */

// ── Enums ────────────────────────────────────────────────────

export type ListingType      = 'good' | 'service' | 'skill'
export type ListingCondition = 'new' | 'like_new' | 'good' | 'fair' | 'poor'
export type ListingStatus    = 'draft' | 'active' | 'reserved' | 'exchanged' | 'expired' | 'removed'

// ── Geography ────────────────────────────────────────────────

export interface GeoPoint {
  lat: number
  lng: number
}

// ── Categories ───────────────────────────────────────────────

export interface Category {
  id: string
  name: string
  slug: string
  description: string | null
  icon: string | null         // Lucide icon name
  parent_id: string | null
  sort_order: number
  is_active: boolean
  created_at: string
  updated_at: string
}

/** Tree node returned by getCategories() */
export interface CategoryWithChildren extends Category {
  children: Category[]
}

// ── Listings ─────────────────────────────────────────────────

export interface Listing {
  id: string
  user_id: string
  title: string
  description: string
  listing_type: ListingType
  category_id: string
  condition: ListingCondition | null
  status: ListingStatus
  location: GeoPoint | null
  location_text: string | null
  max_distance_km: number
  images: string[]        // Storage paths, pass through getListingImageUrl()
  tags: string[]
  views_count: number
  favorites_count: number
  expires_at: string | null
  deleted_at: string | null
  created_at: string
  updated_at: string
}

/**
 * Shape returned by the search_listings_nearby RPC.
 * Includes owner info and computed distance_km.
 */
export interface ListingSearchResult {
  id: string
  title: string
  description: string
  listing_type: ListingType
  category_id: string
  condition: ListingCondition | null
  status: ListingStatus
  location: GeoPoint | null     // Raw geography column — parse with parseGeoPoint()
  location_text: string | null
  max_distance_km: number
  images: string[]
  tags: string[]
  views_count: number
  favorites_count: number
  created_at: string
  user_id: string
  // Joined from profiles
  owner_display_name: string
  owner_avatar_url: string | null
  owner_trust_score: number
  // Computed by PostGIS RPC
  distance_km: number
}
