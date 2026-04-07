import { useEffect, useState, useCallback, useRef, useMemo } from 'react'
import { Search, List, MapIcon, X, SlidersHorizontal, ChevronDown } from 'lucide-react'
import { useListingStore } from '@/stores/listingStore'
import { useAuth } from '@/hooks/useAuth'
import { ListingCard } from '@/components/listings/ListingCard'
import { MapView } from '@/components/map/MapView'
import { cn } from '@/lib/utils'
import { parseGeoPoint } from '@/lib/geo'
import type { ListingType, ListingCondition } from '@/types'

// ── Constants ────────────────────────────────────────────────
// Replace DEFAULT_CENTER with your project's city/area coordinates

const DEFAULT_CENTER = { lat: 51.4769, lng: -0.0005 } // Greenwich — swap this

const LISTING_TYPES: { label: string; value: ListingType | null }[] = [
  { label: 'All', value: null },
  { label: 'Goods', value: 'good' },
  { label: 'Services', value: 'service' },
  { label: 'Skills', value: 'skill' },
]

const CONDITIONS: { label: string; value: ListingCondition }[] = [
  { label: 'New', value: 'new' },
  { label: 'Like New', value: 'like_new' },
  { label: 'Good', value: 'good' },
  { label: 'Fair', value: 'fair' },
  { label: 'Poor', value: 'poor' },
]

const SORT_OPTIONS: { label: string; value: 'distance' | 'newest' | 'most_popular' }[] = [
  { label: 'Distance', value: 'distance' },
  { label: 'Newest', value: 'newest' },
  { label: 'Popular', value: 'most_popular' },
]

// ── Component ────────────────────────────────────────────────

export function BrowsePage() {
  const { profile } = useAuth()

  const {
    listings,
    selectedListingId,
    categories,
    filters,
    isLoading,
    totalCount,
    setFilters,
    search,
    clearFilters,
    loadCategories,
    setSelectedListing,
  } = useListingStore()

  // Mobile view toggle: list or map
  const [mobileView, setMobileView] = useState<'list' | 'map'>('list')

  // Collapsible filter panel on mobile
  const [filtersOpen, setFiltersOpen] = useState(false)

  // Local search text (debounced before committing to store)
  const [searchText, setSearchText] = useState(filters.searchText)
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  // Map center — user's location or fallback to DEFAULT_CENTER
  const mapCenter = useMemo(() => {
    const loc = parseGeoPoint(profile?.display_location)
    return loc ?? DEFAULT_CENTER
  }, [profile?.display_location])

  // ── Init ─────────────────────────────────────────────────
  useEffect(() => {
    loadCategories()

    // Pass user coordinates into distance-sort filter
    if (profile?.display_location) {
      const loc = parseGeoPoint(profile.display_location)
      if (loc) setFilters({ lat: loc.lat, lng: loc.lng })
    }
    if (profile?.id) setFilters({ userId: profile.id })

    search()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // ── Debounced search text ────────────────────────────────
  const handleSearchTextChange = useCallback(
    (value: string) => {
      setSearchText(value)
      if (debounceRef.current) clearTimeout(debounceRef.current)
      debounceRef.current = setTimeout(() => {
        setFilters({ searchText: value })
        search()
      }, 300)
    },
    [setFilters, search],
  )

  // ── Filter handlers ──────────────────────────────────────
  const handleTypeChange = useCallback(
    (type: ListingType | null) => {
      setFilters({ listingType: type, condition: null })
      search()
    },
    [setFilters, search],
  )

  const handleCategoryChange = useCallback(
    (categoryId: string) => {
      setFilters({ categoryId: categoryId || null })
      search()
    },
    [setFilters, search],
  )

  const handleConditionChange = useCallback(
    (condition: string) => {
      setFilters({ condition: (condition || null) as ListingCondition | null })
      search()
    },
    [setFilters, search],
  )

  const handleDistanceChange = useCallback(
    (km: number) => {
      setFilters({ radiusKm: km })
      search()
    },
    [setFilters, search],
  )

  const handleSortChange = useCallback(
    (sortBy: string) => {
      setFilters({ sortBy: sortBy as 'distance' | 'newest' | 'most_popular' })
      search()
    },
    [setFilters, search],
  )

  const handleClearFilters = useCallback(() => {
    clearFilters()
    setSearchText('')
    search()
  }, [clearFilters, search])

  const handleMarkerClick = useCallback(
    (listingId: string) => {
      setSelectedListing(listingId)
    },
    [setSelectedListing],
  )

  // Auto-scroll highlighted card into view when map marker is clicked
  const highlightedRef = useRef<HTMLDivElement>(null)
  useEffect(() => {
    if (selectedListingId && highlightedRef.current) {
      highlightedRef.current.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
    }
  }, [selectedListingId])

  // ── Derived filter state ────────────────────────────────
  const hasActiveFilters =
    filters.searchText ||
    filters.categoryId ||
    filters.listingType ||
    filters.condition ||
    filters.radiusKm !== 5 ||
    filters.sortBy !== 'distance'

  const activeFilterCount = [
    filters.searchText,
    filters.categoryId,
    filters.listingType,
    filters.condition,
    filters.radiusKm !== 5,
    filters.sortBy !== 'distance',
  ].filter(Boolean).length

  // ── Layout ───────────────────────────────────────────────
  //
  // Mobile (< lg):   full-height column, toggle between list and map
  // Desktop (≥ lg):  side-by-side — left panel (440–520px) | right map (flex-1)
  //
  // The outer div height is:
  //   - Mobile:  calc(100dvh - 3.5rem)  → subtracts the 56px fixed mobile header
  //   - Desktop: 100dvh                 → sidebar is positioned outside this element

  return (
    <div className="flex h-[calc(100dvh-3.5rem)] md:h-[100dvh] flex-col bg-white selection:bg-black selection:text-white lg:flex-row overflow-hidden">

      {/* ── Mobile toggle: List | Map ───────────────────── */}
      <div className="flex shrink-0 lg:hidden">
        <button
          onClick={() => setMobileView('list')}
          className={cn(
            'flex flex-1 items-center justify-center gap-2 py-3 text-[10px] font-bold uppercase tracking-[0.2em] font-sans transition-colors',
            mobileView === 'list'
              ? 'bg-black text-white'
              : 'bg-white text-slate-400 active:bg-slate-100 border-b border-black/10',
          )}
        >
          <List className="h-4 w-4" strokeWidth={2} />
          Directory
        </button>
        <button
          onClick={() => setMobileView('map')}
          className={cn(
            'flex flex-1 items-center justify-center gap-2 py-3 text-[10px] font-bold uppercase tracking-[0.2em] font-sans transition-colors',
            mobileView === 'map'
              ? 'bg-black text-white'
              : 'bg-white text-slate-400 active:bg-slate-100 border-b border-black/10 border-l border-l-black/10',
          )}
        >
          <MapIcon className="h-4 w-4" strokeWidth={2} />
          Map
        </button>
      </div>

      {/* ── Left panel: Filters + Results ──────────────── */}
      <div
        className={cn(
          'w-full flex-col overflow-hidden lg:border-r lg:border-black/10 lg:w-[440px] xl:w-[520px] shrink-0',
          mobileView === 'map' ? 'hidden lg:flex' : 'flex',
        )}
      >
        {/* Search + filter controls (always visible) */}
        <div className="shrink-0">

          {/* Panel header — desktop only */}
          <div className="hidden lg:flex items-center justify-between px-5 py-3 border-b border-black/10 bg-white">
            <h2 className="font-sans text-[10px] font-bold uppercase tracking-[0.25em] text-black">
              Browse Listings
            </h2>
            <span className="font-sans text-[9px] uppercase tracking-[0.2em] text-slate-400">
              {!isLoading && `${totalCount} found`}
            </span>
          </div>

          {/* Search bar */}
          <div className="relative border-b border-black/10">
            <Search
              className="absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400"
              strokeWidth={1.5}
            />
            <input
              placeholder="Search listings..."
              value={searchText}
              onChange={(e) => handleSearchTextChange(e.target.value)}
              className="w-full bg-transparent py-3.5 pl-11 pr-4 font-sans text-sm text-black placeholder:text-slate-300 focus:outline-none lg:py-3.5 lg:pl-12 lg:pr-5 lg:text-xs lg:uppercase lg:tracking-[0.1em]"
            />

            {/* Mobile: filter toggle pill */}
            <button
              onClick={() => setFiltersOpen(!filtersOpen)}
              className={cn(
                'absolute right-2 top-1/2 -translate-y-1/2 flex items-center gap-1.5 rounded-full px-3 py-1.5 text-[10px] font-bold uppercase tracking-wider transition-colors lg:hidden',
                filtersOpen
                  ? 'bg-black text-white'
                  : 'bg-slate-100 text-slate-500 active:bg-slate-200',
              )}
            >
              <SlidersHorizontal className="h-3 w-3" strokeWidth={2} />
              Filters
              {activeFilterCount > 0 && (
                <span className="flex h-4 w-4 items-center justify-center rounded-full bg-white text-[9px] font-bold text-black">
                  {activeFilterCount}
                </span>
              )}
            </button>
          </div>

          {/* Type tabs — always visible */}
          <div className="flex border-b border-black/10 lg:gap-1 lg:px-4 lg:pt-2 lg:pb-0 lg:border-b-0">
            {LISTING_TYPES.map((t) => (
              <button
                key={t.label}
                onClick={() => handleTypeChange(t.value)}
                className={cn(
                  'flex-1 border-r border-black/10 last:border-r-0 py-2.5 text-[10px] font-bold uppercase tracking-[0.15em] font-sans transition-colors',
                  'lg:border-r-0 lg:py-2 lg:text-[9px] lg:tracking-[0.2em] lg:rounded-sm',
                  filters.listingType === t.value
                    ? 'bg-black text-white border-black z-10'
                    : 'bg-white text-slate-400 active:bg-slate-50 lg:hover:bg-slate-50 lg:hover:text-black lg:bg-transparent',
                )}
              >
                {t.label}
              </button>
            ))}
          </div>
          <div className="hidden lg:block border-b border-black/10" />

          {/* Collapsible filter panel — hidden on mobile until pill tapped; always open on desktop */}
          <div
            className={cn(
              'overflow-hidden border-b border-black/10 transition-all duration-200',
              filtersOpen ? 'max-h-[500px]' : 'max-h-0 lg:max-h-[500px]',
            )}
          >
            {/* Category + Sort dropdowns */}
            <div className="grid grid-cols-2 divide-x divide-black/10 border-b border-black/10 bg-white">
              {/* Category */}
              <div className="relative p-3">
                <label className="mb-1.5 block font-sans text-[8px] font-bold uppercase tracking-[0.2em] text-slate-400">
                  Classification
                </label>
                <div className="relative">
                  <select
                    value={filters.categoryId ?? ''}
                    onChange={(e) => handleCategoryChange(e.target.value)}
                    className="w-full appearance-none bg-transparent pr-5 font-sans text-[11px] font-semibold uppercase tracking-widest text-black focus:outline-none"
                  >
                    <option value="">ALL</option>
                    {categories.map((parent) => (
                      <optgroup key={parent.id} label={parent.name.toUpperCase()} className="font-sans font-bold">
                        {parent.children.length > 0 ? (
                          parent.children.map((child) => (
                            <option key={child.id} value={child.id}>
                              {child.name.toUpperCase()}
                            </option>
                          ))
                        ) : (
                          <option value={parent.id}>{parent.name.toUpperCase()}</option>
                        )}
                      </optgroup>
                    ))}
                  </select>
                  <ChevronDown className="pointer-events-none absolute right-0 top-1/2 h-3 w-3 -translate-y-1/2 text-slate-400" strokeWidth={2} />
                </div>
              </div>

              {/* Sort */}
              <div className="relative p-3">
                <label className="mb-1.5 block font-sans text-[8px] font-bold uppercase tracking-[0.2em] text-slate-400">
                  Sort By
                </label>
                <div className="relative">
                  <select
                    value={filters.sortBy}
                    onChange={(e) => handleSortChange(e.target.value)}
                    className="w-full appearance-none bg-transparent pr-5 font-sans text-[11px] font-semibold uppercase tracking-widest text-black focus:outline-none"
                  >
                    {SORT_OPTIONS.map((s) => (
                      <option key={s.value} value={s.value}>
                        {s.label.toUpperCase()}
                      </option>
                    ))}
                  </select>
                  <ChevronDown className="pointer-events-none absolute right-0 top-1/2 h-3 w-3 -translate-y-1/2 text-slate-400" strokeWidth={2} />
                </div>
              </div>
            </div>

            {/* Distance (radius) slider */}
            <div className="flex items-center gap-3 px-4 py-3">
              <label className="font-sans text-[9px] font-bold uppercase tracking-[0.2em] text-slate-400 whitespace-nowrap">
                Radius
              </label>
              <input
                type="range"
                min={1}
                max={50}
                step={1}
                value={filters.radiusKm}
                onChange={(e) => handleDistanceChange(Number(e.target.value))}
                className="h-1 flex-1 cursor-pointer appearance-none rounded-none bg-black/10 accent-black [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:h-4 [&::-webkit-slider-thumb]:w-4 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-black"
              />
              <span className="min-w-[44px] text-right font-sans text-[11px] font-bold text-black tabular-nums tracking-widest">
                {filters.radiusKm} KM
              </span>
            </div>

            {/* Condition (goods only) + Reset row */}
            <div className="flex items-center justify-between px-4 py-2.5 bg-slate-50/50">
              {filters.listingType === 'good' ? (
                <div className="flex items-center gap-3">
                  <label className="font-sans text-[9px] font-bold uppercase tracking-[0.2em] text-slate-400">
                    Condition
                  </label>
                  <select
                    value={filters.condition ?? ''}
                    onChange={(e) => handleConditionChange(e.target.value)}
                    className="appearance-none bg-transparent font-sans text-[10px] font-semibold uppercase tracking-widest text-black focus:outline-none"
                  >
                    <option value="">Any</option>
                    {CONDITIONS.map((c) => (
                      <option key={c.value} value={c.value}>
                        {c.label.toUpperCase()}
                      </option>
                    ))}
                  </select>
                </div>
              ) : (
                <div />
              )}
              {hasActiveFilters && (
                <button
                  onClick={handleClearFilters}
                  className="flex shrink-0 items-center gap-1 rounded-full bg-red-50 px-3 py-1.5 font-sans text-[9px] font-bold uppercase tracking-[0.15em] text-red-600 active:bg-red-100 transition-colors"
                >
                  <X className="h-3 w-3" strokeWidth={2} />
                  Reset
                </button>
              )}
            </div>
          </div>
        </div>

        {/* Results count — mobile only (desktop count is in the panel header) */}
        <div className="shrink-0 border-b border-black/10 bg-black/5 px-4 py-2.5 flex items-center justify-between lg:hidden">
          <p className="font-sans text-[9px] font-bold uppercase tracking-[0.2em] text-slate-500">
            {isLoading ? 'Searching...' : 'Results'}
          </p>
          <p className="font-sans text-[9px] font-bold uppercase tracking-[0.2em] text-black">
            {!isLoading && `${totalCount} found`}
          </p>
        </div>

        {/* Results list */}
        <div className="flex-1 overflow-y-auto bg-black/5 p-3 lg:p-6">
          {isLoading ? (
            <div className="flex items-center justify-center py-16">
              <p className="font-sans text-[10px] uppercase tracking-[0.2em] text-slate-400">
                Loading...
              </p>
            </div>
          ) : listings.length === 0 ? (
            /* Empty state */
            <div className="flex flex-col items-center justify-center py-16 text-center bg-white border border-black/10 px-6 lg:py-32">
              <Search className="mb-4 h-8 w-8 text-black/20" strokeWidth={1} />
              <p className="font-sans text-base font-medium tracking-tight text-black lg:text-lg">
                No listings found
              </p>
              <p className="mt-2 max-w-xs font-sans text-xs text-slate-500 leading-relaxed">
                Try adjusting your filters or expanding the search radius.
              </p>
              {hasActiveFilters && (
                <button
                  onClick={handleClearFilters}
                  className="mt-5 border border-black px-5 py-2.5 font-sans text-[10px] font-bold uppercase tracking-widest text-black active:bg-black active:text-white transition-colors lg:hover:bg-black lg:hover:text-white"
                >
                  Clear All Filters
                </button>
              )}
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-2 sm:gap-3">
              {listings.map((listing) => (
                <div
                  key={listing.id}
                  ref={listing.id === selectedListingId ? highlightedRef : undefined}
                >
                  <ListingCard
                    listing={listing}
                    isHighlighted={listing.id === selectedListingId}
                  />
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ── Right panel: Map ───────────────────────────── */}
      {/*
        Mobile:  absolutely positioned, 0-height and invisible when list view is active.
                 Becomes flex-1 when map view is active.
        Desktop: always visible as flex-1 alongside the left panel.
      */}
      <div
        className={cn(
          'bg-black/5',
          mobileView === 'list'
            ? 'absolute lg:relative lg:flex-1 invisible lg:visible h-0 lg:h-auto overflow-hidden lg:overflow-visible'
            : 'flex-1 min-h-0',
        )}
      >
        <MapView
          listings={listings}
          selectedListingId={selectedListingId}
          onMarkerClick={handleMarkerClick}
          center={mapCenter}
        />
      </div>
    </div>
  )
}

export default BrowsePage
