# Research: Auction Bidding, ISO Matching & Multi-Quantity

**Feature**: 009-auction-bids-iso-match
**Date**: 2026-03-18

---

## R1: Technology Stack

**Decision**: Next.js (App Router) + Supabase + Vercel

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Frontend | Next.js 14+ (App Router, React) | SSR for SEO on listing pages; first-class Supabase integration; App Router for layouts per role |
| Backend/BaaS | Supabase | PostgreSQL + Auth + Realtime + Storage + Edge Functions in one platform; eliminates custom backend |
| Database | PostgreSQL (via Supabase) | Relational model required for listings, bids, users, conversations; supports complex queries (ISO matching, bid ranking); RLS for row-level security |
| Auth | Supabase Auth | Native email OTP/magic link support; role claims via custom JWT; session management built-in |
| Real-time | Supabase Realtime | Postgres Changes broadcast via WebSocket; subscribe to bid inserts, message inserts, notification inserts |
| File storage | Supabase Storage | Integrated with auth (RLS on buckets); handles photo uploads (JPEG/PNG/WEBP) |
| Scheduled jobs | pg_cron (Supabase extension) | Runs inside PostgreSQL; triggers auction expiry processing on a schedule |
| Hosting | Vercel | Natural fit for Next.js; free tier covers <1,000 users; edge functions for API routes |
| Testing | Vitest + React Testing Library + Playwright | Vitest for unit/integration; RTL for component tests; Playwright for E2E |
| Styling | TBD at plan stage for UI specs | Not relevant to this feature's data/logic layer |

**Alternatives rejected**:
- *Vite SPA*: No SSR means listing pages aren't SEO-indexed — bad for marketplace discovery
- *Custom Express/Fastify backend*: Unnecessary complexity for <1,000 users when Supabase provides auth, realtime, storage, and edge functions
- *Firebase/Firestore*: NoSQL model is a poor fit for relational data (bids referencing listings, conversations referencing users+listings, ISO matching queries)
- *Remix*: Smaller ecosystem, less Supabase community support than Next.js

---

## R2: Auction Bid Concurrency

**Decision**: Atomic PostgreSQL function for bid placement

**Problem**: Two users could bid simultaneously on the same auction. Both read the current highest bid as PKR 5,000, both submit PKR 5,500 — but only one should succeed (or both succeed since 5,500 > 5,000 + 500 is false for the second).

**Pattern**: Database-level atomic operation using a PostgreSQL function:

```
place_bid(listing_id, bidder_id, bid_amount) → { success, bid_id, error_message }
```

The function executes inside a single transaction:
1. Lock the listing row (SELECT ... FOR UPDATE)
2. Verify: listing status = 'Published', listing type = 'Auction', auction_end_at > now()
3. Verify: bidder_id ≠ listing.seller_id (can't bid on own)
4. Get current highest bid (MAX(bid_amount) from bids WHERE listing_id = ?)
5. If no bids: verify bid_amount >= listing.price_pkr (starting price)
6. If bids exist: verify bid_amount >= current_highest + 500
7. Insert bid record
8. Return success + bid_id

The FOR UPDATE lock prevents race conditions — the second concurrent bid will wait for the first to commit, then re-evaluate against the new highest.

**Alternatives rejected**:
- *Application-level optimistic locking*: Race window between read and write; would need retry loops
- *Supabase RLS only*: RLS can enforce "is authenticated" but can't atomically compare bid_amount to current highest
- *Queue-based sequential processing*: Over-engineered for <1,000 users; adds latency

---

## R3: Auction Expiry Processing

**Decision**: pg_cron job running every 30 seconds + PostgreSQL function

**Pattern**: A PostgreSQL function `process_expired_auctions()` that:
1. Finds all listings WHERE status = 'Published' AND type = 'Auction' AND auction_end_at <= now()
2. Updates each to status = 'Expired', sets expired_at = now()
3. For each expired auction: inserts AuctionNotification records for all distinct bidders
4. Returns count of processed auctions

Triggered by pg_cron: `SELECT cron.schedule('process-expired-auctions', '30 seconds', 'SELECT process_expired_auctions()');`

**Why 30 seconds**: SC-003 requires expiry within 60 seconds. A 30-second interval guarantees worst-case 30 seconds of delay (auction expires 1ms after the last check), well within the 60-second SLA.

**Alternatives rejected**:
- *Supabase Edge Function on schedule*: External HTTP call adds latency and failure modes; pg_cron runs inside the database with zero network overhead
- *Client-side expiry detection*: Unreliable — depends on a user having the page open; doesn't trigger notifications
- *Per-auction scheduled job*: Creating individual cron entries per auction is complex to manage; a single sweep query is simpler

---

## R4: Real-Time Subscriptions

**Decision**: Supabase Realtime (Postgres Changes) for bids, messages, and notifications

**Channels**:

| Channel | Table | Filter | Use Case |
|---------|-------|--------|----------|
| auction-bids:{listing_id} | bids | listing_id = ? | Live bid list on auction detail page |
| messages:{conversation_id} | messages | conversation_id = ? | Real-time messaging in thread |
| notifications:{user_id} | auction_notifications | recipient_id = ? | Notification bell updates |
| inbox:{user_id} | messages | recipient involved | Unread count in inbox |

**Pattern**: Frontend subscribes to Supabase Realtime channels scoped by relevant ID. On INSERT events, the component state updates immediately. No polling needed.

**Bid list refresh**: When a new bid is inserted, all subscribers to `auction-bids:{listing_id}` receive the event with the full bid row. The React component prepends it to the list and updates the "current highest" display.

**Notification delivery**: When `process_expired_auctions()` bulk-inserts notification records, Supabase Realtime broadcasts each INSERT to the relevant `notifications:{user_id}` channel. The notification bell component increments its unread count.

**Alternatives rejected**:
- *Polling*: Wastes bandwidth, adds latency (minimum = poll interval), more complex client code
- *Server-Sent Events*: Supabase doesn't natively support SSE; would require custom endpoint
- *Custom WebSocket server*: Over-engineered when Supabase Realtime is built-in and free at this scale

---

## R5: ISO Matching Query Strategy

**Decision**: On-demand PostgreSQL query at page load time (no stored matches)

**"Suggested Listings" query** (on ISO detail page):
```sql
SELECT id, sale_post_number, listing_type, size_ml, condition, price_pkr, seller_id
FROM listings
WHERE status = 'Published'
  AND listing_type != 'ISO'
  AND (LOWER(fragrance_name) = LOWER(:iso_fragrance_name)
       OR LOWER(brand) = LOWER(:iso_brand))
ORDER BY created_at DESC
LIMIT 20;
```

**"Buyers Looking For This" query** (on non-ISO detail page):
```sql
SELECT id, sale_post_number, fragrance_name, price_pkr, size_ml, seller_id
FROM listings
WHERE status = 'Published'
  AND listing_type = 'ISO'
  AND (LOWER(fragrance_name) = LOWER(:listing_fragrance_name)
       OR LOWER(brand) = LOWER(:listing_brand))
ORDER BY created_at DESC
LIMIT 20;
```

**Performance**: With a B-tree index on `(status, listing_type)` and a functional index on `LOWER(fragrance_name)` and `LOWER(brand)`, these queries will be fast even at 5,000+ listings. No materialized view or caching needed at <1,000 users.

**Alternatives rejected**:
- *Materialized view*: Adds complexity for a query that's fast enough without it
- *Full-text search*: Spec explicitly says exact (case-insensitive) matching in v1; FTS is for future fuzzy matching
- *Stored match records*: Spec explicitly prohibits persistent storage for ISO matches — "computed at display time"

---

## R6: Notification Data Model

**Decision**: Dedicated `auction_notifications` table with Realtime subscription

The AuctionNotification entity is specific to auction events. A generic notification system would be over-engineered for v1 where only two notification types exist (auction_closed, auction_sold).

**Schema approach**: Single table `auction_notifications` with a `notification_type` enum ('closed' | 'sold'). Fan-out happens in the `process_expired_auctions()` function (for close) and a trigger on listing status change to 'Sold' (for sold notifications on Auction-type listings).

**Alternatives rejected**:
- *Generic notifications table*: YAGNI — only auction notifications exist in v1; can generalize later if other features need notifications
- *Push notifications*: Out of scope per spec assumptions (in-platform only, no email/SMS)
- *Notification via messaging*: Conflates two systems; notifications are broadcast (one-to-many), messages are conversations (one-to-one)

---

## R7: Full Bottle Multi-Quantity

**Decision**: Use existing `quantity_available` column on listings table; PostgreSQL trigger for auto-Sold transition

The `quantity_available` field is already defined in spec 008 FR-015 as a schema-reserved extensibility field. This feature activates it for Full Bottle listings (in addition to Decant/Split where it was already active).

**Auto-transition**: A PostgreSQL trigger on the `listings` table:
- AFTER UPDATE on `quantity_available`
- When new value = 0 AND listing_type IN ('Full Bottle', 'Decant/Split')
- Sets status = 'Sold', sold_at = now()

This is identical to the existing Decant/Split behaviour — Full Bottle simply joins the same trigger.

**Frontend**: The listing edit form shows a numeric input for `quantity_available` when listing_type is 'Full Bottle' or 'Decant/Split'. For Swap, ISO, and Auction the field is hidden and fixed at 1.

---

## R8: Defensive Lazy Expiry Check

**Decision**: In addition to pg_cron, the `place_bid()` function checks `auction_end_at > now()` on every bid attempt.

If a bid arrives between cron runs on an auction that should have expired (e.g., cron ran at :00:00, auction expired at :00:01, bid arrives at :00:15), the bid is rejected immediately with 'AUCTION_CLOSED'. This eliminates the 30-second gap between cron sweeps for bid acceptance.

The cron job remains responsible for: (a) transitioning the listing status to Expired, (b) creating notifications, (c) rendering the Auction Result Page state. The lazy check only prevents stale bids — it does not handle notifications.

---

## R9: Frontend Libraries

**Decision**: Standard Next.js ecosystem libraries for form handling, UI, and date/time.

| Concern | Library | Rationale |
|---------|---------|-----------|
| Forms | React Hook Form + Zod | 5 listing types with conditional validation (Auction needs end date, Swap allows zero price, ISO relabels price). Zod discriminated unions map to listing type variants. |
| UI Components | shadcn/ui (Radix + Tailwind) | Copy-paste, no npm dependency, full control. Covers bid lists, listing cards, notification dropdowns. |
| Styling | Tailwind CSS 4 | Paired with shadcn/ui. Utility-first for fast iteration. |
| Date/time | date-fns | Auction countdown timers, bid timestamp formatting. Lighter than Moment/Luxon. |
| State | React Server Components + Supabase client | No global state manager. Server components fetch, client components subscribe to Realtime. |

**Alternatives rejected**:
- *Formik*: Less TypeScript integration than React Hook Form + Zod
- *MUI/Ant Design*: Heavy dependencies; shadcn/ui is lighter and more customizable
- *Zustand/Redux*: YAGNI — Supabase client + React state is sufficient at this scale
