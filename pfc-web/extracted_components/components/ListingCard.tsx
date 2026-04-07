import { Link } from 'react-router-dom'
import { MapPin, Heart, ArrowUpRight, Package, Wrench, Sparkles } from 'lucide-react'
import { Avatar, AvatarImage, AvatarFallback } from '@/components/ui/avatar'
import { cn } from '@/lib/utils'
import type { ListingSearchResult } from '@/types'

// ── Helpers ──────────────────────────────────────────────────

// Replace this URL with your own storage bucket base path
const STORAGE_BASE_URL =
  'https://YOUR_PROJECT.supabase.co/storage/v1/object/public/listings'

export function getListingImageUrl(path: string): string {
  return `${STORAGE_BASE_URL}/${path}`
}

function relativeTime(dateStr: string): string {
  const now = Date.now()
  const then = new Date(dateStr).getTime()
  const seconds = Math.floor((now - then) / 1000)

  if (seconds < 60) return 'JUST NOW'
  const minutes = Math.floor(seconds / 60)
  if (minutes < 60) return `${minutes}M AGO`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}H AGO`
  const days = Math.floor(hours / 24)
  if (days < 7) return `${days}D AGO`
  const weeks = Math.floor(days / 7)
  if (weeks < 5) return `${weeks}W AGO`
  const months = Math.floor(days / 30)
  if (months < 12) return `${months}MO AGO`
  const years = Math.floor(days / 365)
  return `${years}Y AGO`
}

const CONDITION_LABELS: Record<string, string> = {
  new: 'NEW',
  like_new: 'LIKE NEW',
  good: 'GOOD',
  fair: 'FAIR',
  poor: 'POOR',
}

const TYPE_ICONS: Record<string, typeof Package> = {
  good: Package,
  service: Wrench,
  skill: Sparkles,
}

// ── Component ────────────────────────────────────────────────

export interface ListingCardProps {
  listing: ListingSearchResult
  isHighlighted?: boolean
}

export function ListingCard({ listing, isHighlighted = false }: ListingCardProps) {
  const hasImage = listing.images && listing.images.length > 0
  const TypeIcon = TYPE_ICONS[listing.listing_type] ?? Package

  return (
    <Link
      to={`/listings/${listing.id}`}
      className={cn(
        'group flex border border-black/10 bg-white transition-all duration-200',
        'active:bg-slate-50 lg:hover:bg-slate-50',
        isHighlighted && 'ring-2 ring-black ring-offset-2 ring-offset-white'
      )}
    >
      {/* ── Left: image thumbnail (desktop) ────────── */}
      {hasImage ? (
        <div className="hidden sm:block w-28 shrink-0 overflow-hidden border-r border-black/10 bg-black/5">
          <img
            src={getListingImageUrl(listing.images![0])}
            alt={listing.title}
            className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
            loading="lazy"
          />
        </div>
      ) : null}

      {/* Mobile type-icon strip (shown when no image, or always on xs) */}
      <div className={cn(
        'flex w-10 shrink-0 flex-col items-center justify-center border-r border-black/10 bg-black/[0.02] sm:hidden',
        !hasImage && 'sm:flex',
      )}>
        <TypeIcon className="h-4 w-4 text-black/50" strokeWidth={1.5} />
      </div>

      {/* Desktop fallback when no image */}
      {!hasImage && (
        <div className="hidden sm:flex w-28 shrink-0 items-center justify-center border-r border-black/10 bg-black/[0.02]">
          <TypeIcon className="h-6 w-6 text-black/20" strokeWidth={1.5} />
        </div>
      )}

      {/* ── Right: content ──────────────────────────── */}
      <div className="flex flex-1 flex-col justify-center gap-1.5 px-3.5 py-3 min-w-0 sm:px-4 sm:py-3.5">

        {/* Row 1: title + arrow */}
        <div className="flex items-start justify-between gap-3">
          <h3 className="flex-1 font-sans text-[13px] font-semibold leading-snug tracking-tight text-black line-clamp-1 sm:text-sm sm:line-clamp-2 group-hover:underline decoration-1 underline-offset-4">
            {listing.title}
          </h3>
          <ArrowUpRight className="mt-0.5 h-3.5 w-3.5 shrink-0 text-slate-300 transition-transform group-hover:-translate-y-0.5 group-hover:translate-x-0.5 group-hover:text-black" strokeWidth={2} />
        </div>

        {/* Row 2: type · condition · distance · age */}
        <div className="flex items-center gap-1.5 flex-wrap text-slate-400">
          <span className="inline-flex items-center gap-1 font-sans text-[10px] font-bold uppercase tracking-wider">
            <TypeIcon className="h-2.5 w-2.5 hidden sm:block" strokeWidth={2} />
            {listing.listing_type}
          </span>

          {listing.listing_type === 'good' && listing.condition && (
            <>
              <span className="text-black/10">·</span>
              <span className="font-sans text-[10px] font-bold uppercase tracking-wider text-slate-400">
                {CONDITION_LABELS[listing.condition]}
              </span>
            </>
          )}

          {listing.distance_km != null && (
            <>
              <span className="text-black/10">·</span>
              <span className="flex items-center gap-1 font-sans text-[10px] font-bold uppercase tracking-wider text-slate-500">
                <MapPin className="h-2.5 w-2.5" strokeWidth={2} />
                {listing.distance_km.toFixed(1)} km
              </span>
            </>
          )}

          <span className="text-black/10">·</span>
          <span className="font-sans text-[10px] font-semibold uppercase tracking-wider text-slate-300">
            {relativeTime(listing.created_at)}
          </span>
        </div>

        {/* Row 3: owner avatar + name | favorites */}
        <div className="flex items-center justify-between pt-0.5">
          <div className="flex items-center gap-2 min-w-0">
            <Avatar className="h-4 w-4 sm:h-5 sm:w-5 rounded-full border border-black/10">
              {listing.owner_avatar_url ? (
                <AvatarImage src={listing.owner_avatar_url} alt={listing.owner_display_name} className="rounded-full object-cover" />
              ) : null}
              <AvatarFallback className="rounded-full bg-black/5 font-sans text-[7px] sm:text-[8px] font-bold uppercase text-black">
                {listing.owner_display_name.charAt(0)}
              </AvatarFallback>
            </Avatar>
            <span className="truncate font-sans text-[10px] font-medium text-slate-500 sm:text-[11px]">
              {listing.owner_display_name}
            </span>
          </div>

          <div className="flex items-center gap-1 shrink-0">
            <Heart className="h-2.5 w-2.5 text-slate-300" strokeWidth={2} />
            <span className="font-sans text-[10px] font-bold text-slate-400 tabular-nums">
              {listing.favorites_count}
            </span>
          </div>
        </div>
      </div>
    </Link>
  )
}

export default ListingCard
