# API Contracts: Auction Bidding, ISO Matching & Multi-Quantity

**Feature**: 009-auction-bids-iso-match
**Date**: 2026-03-18
**Platform**: Supabase (auto-generated REST + RPC) + Next.js API routes

---

## Overview

Supabase auto-generates a REST API for all tables. This feature uses:
- **Supabase RPC** for the `place_bid` function (atomic operation)
- **Supabase REST** (PostgREST) for reads on bids, notifications, and listings
- **Supabase Realtime** for live subscriptions
- **Next.js Server Actions** for form mutations (quantity update, outcome note)

---

## RPC Endpoints

### POST /rest/v1/rpc/place_bid

Places a bid on an active Auction listing. Atomic — validates and inserts in one transaction.

**Auth**: Required (Bearer token — Supabase auth JWT)

**Request body**:
```json
{
  "p_listing_id": "uuid",
  "p_bid_amount": 5500
}
```

**Success response** (200):
```json
{
  "success": true,
  "bid_id": "uuid",
  "error": null,
  "minimum_amount": null
}
```

**Error responses** (200 with success=false):
```json
{
  "success": false,
  "bid_id": null,
  "error": "BID_TOO_LOW",
  "minimum_amount": 6000
}
```

| error code | Meaning |
|------------|---------|
| LISTING_NOT_FOUND | No listing with this ID |
| NOT_AUCTION | Listing is not Auction type |
| AUCTION_CLOSED | Auction has expired or listing is not Published |
| OWN_LISTING | Bidder is the listing owner |
| BID_TOO_LOW | Bid amount below minimum (minimum_amount returned) |
| NOT_AUTHENTICATED | No valid auth token |

---

## REST Endpoints (Supabase auto-generated)

### GET /rest/v1/bids?listing_id=eq.{id}&order=bid_amount.desc,placed_at.asc

Fetches all bids for an auction listing, ordered highest first.

**Auth**: None required (bids are publicly visible)

**Query params**:
- `listing_id=eq.{uuid}` — filter by listing
- `order=bid_amount.desc,placed_at.asc` — highest first, ties by earliest
- `select=id,bid_amount,placed_at,bidder:users(id,display_name)` — include bidder display name

**Response** (200):
```json
[
  {
    "id": "uuid",
    "bid_amount": 6000,
    "placed_at": "2026-03-18T14:30:00Z",
    "bidder": {
      "id": "uuid",
      "display_name": "Ahmed K."
    }
  }
]
```

---

### GET /rest/v1/auction_notifications?recipient_id=eq.{user_id}&order=sent_at.desc

Fetches notifications for the authenticated user.

**Auth**: Required (RLS enforces recipient_id = auth.uid())

**Query params**:
- `order=sent_at.desc` — newest first
- `select=id,listing_id,notification_type,notification_text,link_url,sent_at,read_at`

**Response** (200):
```json
[
  {
    "id": "uuid",
    "listing_id": "uuid",
    "notification_type": "closed",
    "notification_text": "Auction PFC-01042 — Creed Aventus has closed. View results.",
    "link_url": "/listings/uuid",
    "sent_at": "2026-03-18T18:00:00Z",
    "read_at": null
  }
]
```

---

### GET /rest/v1/auction_notifications?recipient_id=eq.{user_id}&read_at=is.null&select=count

Fetches unread notification count.

**Auth**: Required

**Response** (200 with `Prefer: count=exact` header):
```json
[]
```
Response header `content-range: 0-0/3` → 3 unread notifications.

---

### PATCH /rest/v1/auction_notifications?id=eq.{id}

Marks a notification as read.

**Auth**: Required (RLS enforces recipient_id = auth.uid())

**Request body**:
```json
{
  "read_at": "2026-03-18T18:05:00Z"
}
```

---

### PATCH /rest/v1/listings?id=eq.{id}

Updates listing fields. Used for:
- `auction_outcome_note` (seller sets post-close note)
- `quantity_available` (seller decrements stock)

**Auth**: Required (RLS enforces seller_id = auth.uid() + status/type conditions)

**Request body** (outcome note):
```json
{
  "auction_outcome_note": "Sale completed — thank you all for bidding!"
}
```

**Request body** (quantity update):
```json
{
  "quantity_available": 2
}
```

**RLS conditions**:
- `auction_outcome_note`: seller_id = auth.uid() AND status IN ('Expired', 'Sold') AND listing_type = 'Auction'
- `quantity_available`: seller_id = auth.uid() AND status = 'Published' AND listing_type IN ('Full Bottle', 'Decant/Split')

---

## ISO Matching Queries (client-side via Supabase SDK)

These are standard Supabase queries made from the frontend, not custom endpoints.

### Suggested Listings (on ISO detail page)

```
supabase.from('listings')
  .select('id, sale_post_number, listing_type, size_ml, condition, price_pkr, seller:users(id, display_name, is_verified)')
  .eq('status', 'Published')
  .neq('listing_type', 'ISO')
  .or(`fragrance_name.ilike.${isoFragranceName},brand.ilike.${isoBrand}`)
  .order('created_at', { ascending: false })
  .limit(20)
```

### Buyers Looking For This (on non-ISO detail page)

```
supabase.from('listings')
  .select('id, sale_post_number, fragrance_name, price_pkr, size_ml, seller:users(id, display_name, is_verified)')
  .eq('status', 'Published')
  .eq('listing_type', 'ISO')
  .or(`fragrance_name.ilike.${listingFragranceName},brand.ilike.${listingBrand}`)
  .order('created_at', { ascending: false })
  .limit(20)
```

**Note**: `.ilike` performs case-insensitive exact match when the value has no wildcards. For exact match as specified, we use `.ilike.${value}` (no % wildcards). If the value itself could contain special characters, parameterize via RPC.

---

## Realtime Subscriptions (client-side)

### Bid list (auction detail page)

```
supabase.channel('auction-bids')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'bids',
    filter: `listing_id=eq.${listingId}`
  }, (payload) => {
    // prepend new bid to list, update highest bid display
  })
  .subscribe()
```

### Notifications (global — in nav bar)

```
supabase.channel('user-notifications')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'auction_notifications',
    filter: `recipient_id=eq.${userId}`
  }, (payload) => {
    // increment unread count, show toast
  })
  .subscribe()
```

---

## Next.js Server Actions

Server Actions are used for mutations that need server-side validation beyond what RLS provides.

### placeBid(listingId: string, bidAmount: number)

Calls Supabase RPC `place_bid` from the server using the service role client.
Returns the RPC result to the client.

### updateQuantity(listingId: string, quantity: number)

Validates quantity > 0 (or = 0 for auto-Sold), then PATCHes the listing.
The auto-Sold transition is handled by the database trigger, not the server action.

### setOutcomeNote(listingId: string, note: string)

Validates note length ≤ 200, then PATCHes the listing's `auction_outcome_note`.

### markNotificationRead(notificationId: string)

PATCHes the notification's `read_at` field.

### markAllNotificationsRead()

Bulk PATCHes all unread notifications for the authenticated user.
