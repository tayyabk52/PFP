import { useState, useCallback, useMemo } from 'react'
import { APIProvider, Map, AdvancedMarker, InfoWindow } from '@vis.gl/react-google-maps'
import { Link } from 'react-router-dom'
import { ArrowUpRight, MapPin, Package, Wrench, Sparkles } from 'lucide-react'
import { getListingImageUrl } from '@/components/listings/ListingCard'
import { parseGeoPoint } from '@/lib/geo'
import type { ListingSearchResult } from '@/types'

// ── Types ────────────────────────────────────────────────────

interface MapViewProps {
  listings: ListingSearchResult[]
  selectedListingId: string | null
  onMarkerClick: (listingId: string) => void
  center: { lat: number; lng: number }
  onCenterChanged?: (center: { lat: number; lng: number }) => void
}

// ── Config ───────────────────────────────────────────────────

// Set VITE_GOOGLE_MAPS_API_KEY in your .env file
const API_KEY = import.meta.env.VITE_GOOGLE_MAPS_API_KEY ?? ''

// Map ID registered in Google Cloud Console (required for AdvancedMarker)
// Create one at: console.cloud.google.com → Google Maps Platform → Map IDs
const MAP_ID = 'YOUR_MAP_ID'

// ── Marker icons per item type ───────────────────────────────

const TYPE_CONFIG: Record<string, { icon: typeof Package; color: string; bg: string }> = {
  good:    { icon: Package,   color: '#000000', bg: '#ffffff' },
  service: { icon: Wrench,    color: '#000000', bg: '#ffffff' },
  skill:   { icon: Sparkles,  color: '#000000', bg: '#ffffff' },
}

// ── Listing Marker ───────────────────────────────────────────

function ListingMarker({
  listing,
  isSelected,
  onClick,
}: {
  listing: ListingSearchResult
  isSelected: boolean
  onClick: () => void
}) {
  const config = TYPE_CONFIG[listing.listing_type] ?? TYPE_CONFIG.good
  const Icon = config.icon

  return (
    <button
      onClick={onClick}
      className="group relative cursor-pointer outline-none"
      aria-label={listing.title}
    >
      {/* Pulse ring on selected */}
      {isSelected && (
        <span className="absolute inset-0 -m-2 animate-ping rounded-full bg-black/20" />
      )}

      {/* Marker body */}
      <div
        className={
          isSelected
            ? 'relative flex items-center gap-1.5 rounded-full bg-black px-3 py-1.5 shadow-[0_4px_20px_rgba(0,0,0,0.3)] transition-all duration-200'
            : 'relative flex items-center justify-center rounded-full bg-white border-2 border-black/80 p-1.5 shadow-[0_2px_8px_rgba(0,0,0,0.15)] transition-all duration-200 hover:scale-110 hover:shadow-[0_4px_16px_rgba(0,0,0,0.25)]'
        }
      >
        <Icon
          className={isSelected ? 'h-3 w-3 text-white' : 'h-3 w-3 text-black'}
          strokeWidth={2}
        />
        {isSelected && (
          <span className="max-w-[120px] truncate font-sans text-[10px] font-bold text-white">
            {listing.title}
          </span>
        )}
      </div>

      {/* Pointer triangle below marker */}
      <div className="flex justify-center -mt-[1px]">
        <div
          className={
            isSelected
              ? 'h-0 w-0 border-l-[6px] border-r-[6px] border-t-[6px] border-l-transparent border-r-transparent border-t-black'
              : 'h-0 w-0 border-l-[4px] border-r-[4px] border-t-[4px] border-l-transparent border-r-transparent border-t-black/80'
          }
        />
      </div>
    </button>
  )
}

// ── User Location Beacon ─────────────────────────────────────

function UserLocationMarker() {
  return (
    <div className="relative flex items-center justify-center">
      <span className="absolute h-8 w-8 animate-ping rounded-full bg-blue-500/20" />
      <span className="absolute h-6 w-6 rounded-full bg-blue-500/10 border border-blue-500/30" />
      <span className="relative h-3 w-3 rounded-full bg-blue-500 border-2 border-white shadow-[0_0_6px_rgba(59,130,246,0.6)]" />
    </div>
  )
}

// ── MapView ──────────────────────────────────────────────────

export function MapView({
  listings,
  selectedListingId,
  onMarkerClick,
  center,
}: MapViewProps) {
  const [infoWindowId, setInfoWindowId] = useState<string | null>(null)

  const handleMarkerClick = useCallback(
    (listingId: string) => {
      onMarkerClick(listingId)
      setInfoWindowId(listingId)
    },
    [onMarkerClick],
  )

  const handleInfoWindowClose = useCallback(() => {
    setInfoWindowId(null)
  }, [])

  // Filter out listings without parseable coordinates
  const positioned = useMemo(() => {
    return listings
      .map((listing) => {
        const pos = parseGeoPoint(listing.location)
        return pos ? { listing, pos } : null
      })
      .filter(Boolean) as { listing: ListingSearchResult; pos: { lat: number; lng: number } }[]
  }, [listings])

  const selectedItem = useMemo(
    () => positioned.find((p) => p.listing.id === infoWindowId) ?? null,
    [positioned, infoWindowId],
  )

  return (
    <APIProvider apiKey={API_KEY}>
      <Map
        defaultCenter={center}
        defaultZoom={13}
        mapId={MAP_ID}
        gestureHandling="greedy"
        disableDefaultUI={false}
        className="h-full w-full"
        colorScheme="LIGHT"
      >
        {/* User location beacon */}
        <AdvancedMarker position={center} zIndex={0}>
          <UserLocationMarker />
        </AdvancedMarker>

        {/* Listing markers */}
        {positioned.map(({ listing, pos }) => {
          const isSelected = listing.id === selectedListingId
          return (
            <AdvancedMarker
              key={listing.id}
              position={pos}
              onClick={() => handleMarkerClick(listing.id)}
              zIndex={isSelected ? 10 : 1}
            >
              <ListingMarker
                listing={listing}
                isSelected={isSelected}
                onClick={() => handleMarkerClick(listing.id)}
              />
            </AdvancedMarker>
          )
        })}

        {/* InfoWindow popup for the clicked marker */}
        {selectedItem && (
          <InfoWindow
            position={selectedItem.pos}
            onCloseClick={handleInfoWindowClose}
            pixelOffset={[0, -20]}
          >
            <div className="w-64 font-sans text-black">
              {/* Thumbnail */}
              {selectedItem.listing.images && selectedItem.listing.images.length > 0 && (
                <div className="aspect-[16/9] w-full overflow-hidden bg-black/5">
                  <img
                    src={getListingImageUrl(selectedItem.listing.images[0])}
                    alt={selectedItem.listing.title}
                    className="h-full w-full object-cover"
                  />
                </div>
              )}

              {/* Body */}
              <div className="space-y-2.5 p-3">
                {/* Type badge */}
                <div className="flex items-center gap-2">
                  <span className="inline-flex items-center gap-1 border border-black/10 bg-black/5 px-2 py-0.5 text-[9px] font-bold uppercase tracking-[0.15em] text-slate-600">
                    {selectedItem.listing.listing_type === 'good'    && <Package  className="h-2.5 w-2.5" strokeWidth={2} />}
                    {selectedItem.listing.listing_type === 'service' && <Wrench   className="h-2.5 w-2.5" strokeWidth={2} />}
                    {selectedItem.listing.listing_type === 'skill'   && <Sparkles className="h-2.5 w-2.5" strokeWidth={2} />}
                    {selectedItem.listing.listing_type}
                  </span>
                </div>

                {/* Title */}
                <p className="text-[13px] font-semibold leading-snug tracking-tight text-black line-clamp-2">
                  {selectedItem.listing.title}
                </p>

                {/* Distance */}
                <div className="flex items-center gap-1.5 text-slate-500">
                  <MapPin className="h-3 w-3 shrink-0" strokeWidth={2} />
                  <span className="text-[10px] font-bold uppercase tracking-[0.1em]">
                    {selectedItem.listing.distance_km != null
                      ? `${selectedItem.listing.distance_km.toFixed(1)} km away`
                      : selectedItem.listing.location_text ?? 'Nearby'}
                  </span>
                </div>

                {/* Owner */}
                <div className="flex items-center gap-2 pt-0.5">
                  <div className="flex h-5 w-5 items-center justify-center bg-black/5 text-[9px] font-bold text-black">
                    {selectedItem.listing.owner_display_name.charAt(0)}
                  </div>
                  <span className="text-[10px] font-medium text-slate-500">
                    {selectedItem.listing.owner_display_name}
                  </span>
                </div>

                {/* View details link */}
                <Link
                  to={`/listings/${selectedItem.listing.id}`}
                  className="group flex items-center justify-between border-t border-black/10 pt-2.5 text-[10px] font-bold uppercase tracking-[0.15em] text-black hover:text-slate-600 transition-colors"
                >
                  View Details
                  <ArrowUpRight className="h-3.5 w-3.5 transition-transform group-hover:-translate-y-0.5 group-hover:translate-x-0.5" strokeWidth={2} />
                </Link>
              </div>
            </div>
          </InfoWindow>
        )}
      </Map>
    </APIProvider>
  )
}

export default MapView
