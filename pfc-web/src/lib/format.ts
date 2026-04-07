// Format price in PKR
export function formatPkr(amount: number): string {
  if (amount === 0) return 'Free'
  if (amount >= 100000) return `PKR ${(amount / 100000).toFixed(1)}L`
  if (amount >= 1000) return `PKR ${(amount / 1000).toFixed(0)}K`
  return `PKR ${amount.toLocaleString()}`
}

// Relative time-ago
export function timeAgo(dateStr: string): string {
  const now = Date.now()
  const then = new Date(dateStr).getTime()
  const diff = Math.floor((now - then) / 1000)
  if (diff < 60) return 'just now'
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`
  if (diff < 2592000) return `${Math.floor(diff / 86400)}d ago`
  if (diff < 31536000) return `${Math.floor(diff / 2592000)}mo ago`
  return `${Math.floor(diff / 31536000)}y ago`
}

// Listing type display label
export function listingTypeLabel(type: string): string {
  const map: Record<string, string> = {
    FullBottle: 'Full Bottle',
    DecantSplit: 'Decant',
    Swap: 'Swap',
    Auction: 'Auction',
    ISO: 'ISO',
  }
  return map[type] ?? type
}

// Initials from display name
export function initials(name: string): string {
  return name.split(' ').map(p => p[0]).join('').toUpperCase().slice(0, 2)
}
