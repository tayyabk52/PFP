import { create } from 'zustand'
import type {
  ListingSearchResult,
  ListingType,
  ListingCondition,
  CategoryWithChildren,
} from '@/types'
import { listingService } from '@/services/listingService'

// ── Filter shape ─────────────────────────────────────────────
// Adapt defaults (lat/lng, radiusKm, sortBy) to your project

export interface SearchFilters {
  searchText: string
  categoryId: string | null
  listingType: ListingType | null
  condition: ListingCondition | null
  radiusKm: number
  sortBy: 'distance' | 'newest' | 'most_popular'
  lat: number
  lng: number
  userId: string | null
}

interface ListingState {
  listings: ListingSearchResult[]
  selectedListingId: string | null
  categories: CategoryWithChildren[]
  filters: SearchFilters
  isLoading: boolean
  error: string | null
  totalCount: number

  // Actions
  setFilters: (filters: Partial<SearchFilters>) => void
  search: () => Promise<void>
  clearFilters: () => void
  loadCategories: () => Promise<void>
  setSelectedListing: (id: string | null) => void
}

// Replace lat/lng with your own default map center
const defaultFilters: SearchFilters = {
  searchText: '',
  categoryId: null,
  listingType: null,
  condition: null,
  radiusKm: 5,
  sortBy: 'distance',
  lat: 51.4769,   // ← replace with your city
  lng: -0.0005,   // ← replace with your city
  userId: null,
}

export const useListingStore = create<ListingState>()((set, get) => ({
  listings: [],
  selectedListingId: null,
  categories: [],
  filters: { ...defaultFilters },
  isLoading: false,
  error: null,
  totalCount: 0,

  setFilters: (filters) => {
    set((state) => ({
      filters: { ...state.filters, ...filters },
    }))
  },

  search: async () => {
    const { filters } = get()
    set({ isLoading: true, error: null })
    try {
      const results = await listingService.searchNearby({
        lat: filters.lat,
        lng: filters.lng,
        radiusKm: filters.radiusKm,
        listingType: filters.listingType,
        categoryId: filters.categoryId,
        searchText: filters.searchText || null,
        userId: filters.userId,
      })
      set({
        listings: results,
        totalCount: results.length,
        isLoading: false,
      })
    } catch (error) {
      set({
        isLoading: false,
        error: error instanceof Error ? error.message : 'Search failed',
      })
    }
  },

  clearFilters: () => {
    set({ filters: { ...defaultFilters } })
  },

  loadCategories: async () => {
    try {
      const categories = await listingService.getCategories()
      set({ categories })
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Failed to load categories',
      })
    }
  },

  setSelectedListing: (id) => {
    set({ selectedListingId: id })
  },
}))
