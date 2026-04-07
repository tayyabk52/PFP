# Data Model: Auction Bidding, ISO Matching & Multi-Quantity

**Feature**: 009-auction-bids-iso-match
**Date**: 2026-03-18
**Database**: PostgreSQL (via Supabase)

---

## Entity Relationship Summary

```
┌──────────┐       ┌──────────────┐       ┌─────────────────────┐
│  users   │──1:N──│    bids      │──N:1──│      listings       │
│          │       │              │       │  (Auction type)     │
│          │       └──────────────┘       │                     │
│          │                              │  + auction_outcome  │
│          │──1:N──┌──────────────────┐   │    _note (new)      │
│          │       │ auction_         │   │                     │
│          │       │ notifications    │──N:1│                     │
│          │       └──────────────────┘   └─────────────────────┘
└──────────┘
```

**ISO matching has NO entity** — it is a live query computed at display time.

---

## New Tables

### bids

Stores all bids placed on Auction-type listings. Bids are immutable once created (no update, no delete).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK, default gen_random_uuid() | Bid unique identifier |
| listing_id | uuid | FK → listings.id, NOT NULL | The Auction listing this bid is on |
| bidder_id | uuid | FK → users.id, NOT NULL | The user who placed the bid |
| bid_amount | integer | NOT NULL, CHECK (bid_amount > 0) | Bid amount in PKR |
| placed_at | timestamptz | NOT NULL, default now() | When the bid was placed |

**Indexes**:
- `idx_bids_listing_id` on (listing_id) — for querying all bids on a listing
- `idx_bids_listing_amount` on (listing_id, bid_amount DESC) — for finding current highest bid efficiently
- `idx_bids_bidder_id` on (bidder_id) — for finding all auctions a user has bid on (notification fan-out)

**Constraints**:
- FK listing_id references listings(id)
- FK bidder_id references users(id)
- No UPDATE or DELETE permitted at application layer (bids are non-retractable per FR-003)
- bid_amount validated by `place_bid()` function, not by CHECK constraint alone (needs comparison to current highest)

**RLS Policies**:
- SELECT: anyone (bids are publicly visible per FR-004)
- INSERT: authenticated users only, via `place_bid()` RPC (not direct insert)
- UPDATE: none (bids are immutable)
- DELETE: none (bids are non-retractable)

---

### auction_notifications

Stores in-platform notifications sent to bidders when their auction closes or is sold.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK, default gen_random_uuid() | Notification unique identifier |
| recipient_id | uuid | FK → users.id, NOT NULL | The bidder receiving this notification |
| listing_id | uuid | FK → listings.id, NOT NULL | The Auction listing |
| notification_type | text | NOT NULL, CHECK IN ('closed', 'sold') | Event type |
| notification_text | text | NOT NULL | Display text (e.g., "Auction PFC-01042 — Creed Aventus has closed. View results.") |
| link_url | text | NOT NULL | URL to the Auction Result Page |
| sent_at | timestamptz | NOT NULL, default now() | When the notification was created |
| read_at | timestamptz | nullable | When the recipient read it (null = unread) |

**Indexes**:
- `idx_notifications_recipient` on (recipient_id, sent_at DESC) — for loading a user's notification list
- `idx_notifications_recipient_unread` on (recipient_id) WHERE read_at IS NULL — for unread count
- `idx_notifications_listing` on (listing_id) — for finding all notifications for an auction

**Constraints**:
- FK recipient_id references users(id)
- FK listing_id references listings(id)
- notification_type must be 'closed' or 'sold'
- One notification per (recipient_id, listing_id, notification_type) — UNIQUE constraint prevents duplicates

**RLS Policies**:
- SELECT: authenticated user WHERE recipient_id = auth.uid()
- INSERT: service role only (created by database functions, not by users)
- UPDATE: authenticated user WHERE recipient_id = auth.uid() (only read_at can be set)
- DELETE: none

---

## Extended Tables

### listings (additions for spec 009)

One new column added to the existing `listings` table defined in spec 008:

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| auction_outcome_note | text | nullable, CHECK (char_length <= 200) | Optional seller note displayed on Auction Result Page. Editable by seller only when status IN ('Expired', 'Sold'). |

**Note**: All other listing fields (`quantity_available`, `auction_end_at`, `price_pkr`, status fields, transaction-ready fields) are already defined in spec 008. This spec only adds `auction_outcome_note`.

**RLS addition for auction_outcome_note**:
- UPDATE: seller can set `auction_outcome_note` WHERE seller_id = auth.uid() AND status IN ('Expired', 'Sold') AND listing_type = 'Auction'

---

## Database Functions

### place_bid(p_listing_id uuid, p_bid_amount integer)

**Purpose**: Atomic bid placement with validation.

**Returns**: JSON `{ success: boolean, bid_id: uuid | null, error: text | null, minimum_amount: integer | null }`

**Logic**:
1. Get auth.uid() as bidder_id
2. SELECT listing FOR UPDATE WHERE id = p_listing_id
3. Validate: listing exists, status = 'Published', listing_type = 'Auction'
4. Validate: auction_end_at > now() (defensive lazy-check — catches expirations between cron runs)
5. Validate: bidder_id ≠ listing.seller_id (can't bid on own)
6. Get current_highest = MAX(bid_amount) FROM bids WHERE listing_id = p_listing_id
7. If current_highest IS NULL: minimum = listing.price_pkr
   Else: minimum = current_highest + 500
8. Validate: p_bid_amount >= minimum
9. INSERT INTO bids (listing_id, bidder_id, bid_amount)
10. Return { success: true, bid_id: new_id }

**Error cases**:
- 'LISTING_NOT_FOUND' — listing doesn't exist
- 'NOT_AUCTION' — listing is not Auction type
- 'AUCTION_CLOSED' — auction_end_at has passed or status ≠ Published
- 'OWN_LISTING' — bidder is the listing owner
- 'BID_TOO_LOW' — bid_amount < minimum (returns minimum_amount)

---

### process_expired_auctions()

**Purpose**: Scheduled function (pg_cron, every 30s) that expires auctions and sends notifications.

**Returns**: integer (count of auctions processed)

**Logic**:
1. SELECT id, sale_post_number, fragrance_name FROM listings
   WHERE status = 'Published' AND listing_type = 'Auction' AND auction_end_at <= now()
   FOR UPDATE SKIP LOCKED
2. For each listing:
   a. UPDATE status = 'Expired', expired_at = now()
   b. Get all DISTINCT bidder_ids from bids WHERE listing_id = listing.id
   c. For each bidder: INSERT INTO auction_notifications (recipient_id, listing_id, notification_type, notification_text, link_url)
      VALUES (bidder_id, listing.id, 'closed', 'Auction ' || sale_post_number || ' — ' || fragrance_name || ' has closed. View results.', '/listings/' || listing.id)
3. Return count

**SKIP LOCKED**: Prevents the cron job from blocking if a previous run is still processing.

---

### notify_auction_sold()

**Purpose**: Trigger function fired AFTER UPDATE on listings when status changes to 'Sold' on an Auction-type listing.

**Trigger**: `AFTER UPDATE OF status ON listings FOR EACH ROW WHEN (NEW.status = 'Sold' AND OLD.status = 'Expired' AND NEW.listing_type = 'Auction')`

**Logic**:
1. Get all DISTINCT bidder_ids from bids WHERE listing_id = NEW.id
2. For each bidder: INSERT INTO auction_notifications (recipient_id, listing_id, notification_type, notification_text, link_url)
   VALUES (bidder_id, NEW.id, 'sold', 'Auction ' || NEW.sale_post_number || ' — ' || NEW.fragrance_name || ' has been sold.', '/listings/' || NEW.id)

---

### auto_sold_on_zero_quantity()

**Purpose**: Trigger function fired AFTER UPDATE on listings when quantity_available changes to 0.

**Trigger**: `AFTER UPDATE OF quantity_available ON listings FOR EACH ROW WHEN (NEW.quantity_available = 0 AND OLD.quantity_available > 0 AND NEW.listing_type IN ('Full Bottle', 'Decant/Split'))`

**Logic**:
1. UPDATE listings SET status = 'Sold', sold_at = now() WHERE id = NEW.id

**Note**: This trigger exists for the Decant/Split case already (spec 008). Spec 009 extends it to include Full Bottle — the trigger condition simply adds 'Full Bottle' to the IN clause.

---

## Derived / Computed Values (NOT stored)

These values are computed at query time, not stored in any table:

| Value | Computation | Used In |
|-------|------------|---------|
| bid_count | COUNT(*) FROM bids WHERE listing_id = ? | Auction listing detail page |
| current_highest_bid | MAX(bid_amount) FROM bids WHERE listing_id = ? | Auction listing detail, bid validation |
| time_remaining | auction_end_at - now() | Auction listing detail (computed client-side) |
| suggested_listings | Query: Published non-ISO listings matching fragrance_name or brand | ISO listing detail page |
| buyers_looking | Query: Published ISO listings matching fragrance_name or brand | Non-ISO listing detail page |
| unread_notification_count | COUNT(*) FROM auction_notifications WHERE recipient_id = ? AND read_at IS NULL | Notification bell |

---

## Realtime Subscriptions

| Channel | Table | Event | Filter | Purpose |
|---------|-------|-------|--------|---------|
| bids:listing_id={id} | bids | INSERT | listing_id = eq.{id} | Live bid list on auction page |
| notifications:user_id={id} | auction_notifications | INSERT | recipient_id = eq.{id} | Notification bell + popup |

---

## Enumerations

### notification_type (new)

| Value | Description |
|-------|-------------|
| closed | Auction has expired (auction_end_at reached) |
| sold | Seller manually marked the auction as Sold |

### Existing enums unchanged

- ListingType: Full Bottle, Decant/Split, ISO, Swap, Auction (no change)
- ListingStatus: Draft, Published, Sold, Expired, Deleted, Removed (no change)
- ListingCondition: New, Like New, Excellent, Good, Fair (no change)

---

## Migration Sequence

1. **Add column**: `ALTER TABLE listings ADD COLUMN auction_outcome_note text CHECK (char_length(auction_outcome_note) <= 200);`
2. **Create table**: `bids` with all columns, indexes, and constraints
3. **Create table**: `auction_notifications` with all columns, indexes, and constraints
4. **Create function**: `place_bid()`
5. **Create function**: `process_expired_auctions()`
6. **Create function + trigger**: `notify_auction_sold()`
7. **Modify trigger**: `auto_sold_on_zero_quantity()` to include 'Full Bottle'
8. **Schedule**: `SELECT cron.schedule('process-expired-auctions', '30 seconds', 'SELECT process_expired_auctions()');`
9. **Apply RLS**: Policies for bids and auction_notifications tables
10. **Enable Realtime**: Add bids and auction_notifications to Supabase Realtime publication
