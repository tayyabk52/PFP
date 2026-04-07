# Data Model: Marketplace Listings

**Feature**: 002-marketplace-listings
**Date**: 2026-03-19
**Database**: PostgreSQL (via Supabase)

---

## Entity Relationship Summary

```
┌──────────────────┐       ┌──────────────────────────────────┐
│   auth.users     │──1:N──│           listings               │
│  (Supabase Auth) │       │                                  │
│                  │       │  id (uuid PK)                    │
│  id (uuid)       │       │  sale_post_number (text UNIQUE)  │
└──────────────────┘       │  seller_id (FK → auth.users)     │
                           │  listing_type (enum)             │
                           │  fragrance_name / brand          │
                           │  size_ml / condition             │
                           │  price_pkr                       │
                           │  status (enum)                   │
                           │  timestamps (published_at, ...)  │
                           │  auction_end_at                  │
                           │  quantity_available              │
                           └──────────────────┬───────────────┘
                                              │
                              ┌───────────────┴───────────────┐
                              │                               │
              ┌───────────────▼───────────┐   ┌──────────────▼──────────────┐
              │      listing_photos        │   │      pickup_locations        │
              │                           │   │      (spec 007)              │
              │  id (uuid PK)             │   │                              │
              │  listing_id (FK)          │   │  listing_id (FK, UNIQUE)     │
              │  file_url                 │   │  address, lat/lng            │
              │  display_order (1–5)      │   │  visibility settings         │
              └───────────────────────────┘   └──────────────────────────────┘
```

**listings** is the central entity for all marketplace activity. A seller (auth.users) may have many listings. Each listing has zero to five ordered photos (listing_photos) and an optional single pickup location (pickup_locations, owned by spec 007). Spec 002 owns the marketplace behaviour of listings; spec 008 owns field-level definitions for fragrance metadata.

---

## New Tables

### listings

The primary table for all seller-posted items. Covers five listing types: Full Bottle, Decant/Split, ISO, Swap, and Auction. Status lifecycle: Draft → Published → Sold / Expired / Deleted / Removed.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK, DEFAULT gen_random_uuid() | Listing's unique identifier |
| sale_post_number | text | NOT NULL, UNIQUE, DEFAULT sequence | Human-readable reference (e.g. PFC-00001), generated from `listing_sale_post_seq`. Immutable once assigned. |
| seller_id | uuid | NOT NULL, FK → auth.users(id) | Owning seller; not cascaded (listings persist if user is deleted administratively) |
| listing_type | listing_type | NOT NULL | Enum: 'Full Bottle', 'Decant/Split', 'ISO', 'Swap', 'Auction' |
| fragrance_name | text | NOT NULL | Name of the fragrance being listed |
| brand | text | NOT NULL | Fragrance brand / house |
| size_ml | numeric(8,1) | NOT NULL, CHECK (> 0) | Volume in millilitres |
| condition | listing_condition | nullable | Enum: 'New', 'Like New', 'Good', 'Fair', 'Poor'. Nullable for ISO listings. |
| price_pkr | integer | NOT NULL, DEFAULT 0, CHECK (>= 0) | Price in Pakistani Rupees. Must be > 0 for all non-Swap types (app-layer rule). For ISO, represents buyer's budget. |
| delivery_details | text | nullable | Free-text shipping or delivery information provided by seller |
| impression_declaration_accepted | boolean | NOT NULL, DEFAULT false | Seller must confirm listing does not misrepresent impressions/copies. Must be true to publish. |
| status | listing_status | NOT NULL, DEFAULT 'Draft' | Enum: 'Draft', 'Published', 'Sold', 'Expired', 'Deleted', 'Removed' |
| created_at | timestamptz | NOT NULL, DEFAULT now() | When the listing was first created |
| published_at | timestamptz | nullable | When the listing first entered Published status. Immutable once set (enforced by trigger). |
| last_updated_at | timestamptz | NOT NULL, DEFAULT now() | Updated by trigger on every row modification |
| sold_at | timestamptz | nullable | Timestamp of Sold transition; set by trigger |
| expired_at | timestamptz | nullable | Timestamp of Expired transition; set by trigger |
| deleted_at | timestamptz | nullable | Timestamp of Deleted transition (seller-initiated soft delete); set by trigger |
| removed_at | timestamptz | nullable | Timestamp of Removed transition (admin-initiated removal); set by trigger |
| auction_end_at | timestamptz | nullable | Mandatory for Auction type. Must be in the future at publish time. Processed by pg_cron every 30 seconds. |
| quantity_available | integer | nullable, DEFAULT 1, CHECK (>= 0) | Stock count for Full Bottle and Decant/Split listings. Auto-transitions to Sold at 0. |
| fragrance_family | text | nullable | Fragrance family classification (e.g. Oriental, Floral) — spec 008 metadata |
| fragrance_notes | text | nullable | Free-text description of scent notes — spec 008 metadata |
| hashtags | text[] | nullable | Array of searchable tags supplied by seller |
| vintage_year | integer | nullable | Vintage / batch year if applicable — spec 008 metadata |
| condition_notes | text | nullable | Seller's additional notes on condition — spec 008 metadata |
| commission_rate | numeric(5,2) | nullable | Reserved for commission engine (v1 inactive) |
| commission_status | text | nullable | Reserved for commission engine (v1 inactive) |
| transaction_value | integer | nullable | Reserved for transaction recording (v1 inactive) |
| payment_provider | text | nullable | Reserved for payment integration (v1 inactive) |
| payment_status | text | nullable | Reserved for payment integration (v1 inactive) |
| auction_outcome_note | text | nullable | Free-text note recorded when an auction closes |

**Sequence**: `listing_sale_post_seq` (START 1) — used in the DEFAULT for sale_post_number to produce 'PFC-00001', 'PFC-00002', etc.

**Indexes**:
- `idx_listings_status` on (status) — primary filter for published browse
- `idx_listings_seller` on (seller_id) — seller's own listing queries
- `idx_listings_type_status` on (listing_type, status) — type-filtered browse
- `idx_listings_created_at` on (created_at DESC) — chronological ordering
- `idx_listings_auction_end_at` on (auction_end_at) WHERE status = 'Published' — auction expiry polling
- `idx_listings_sale_post_number` on (sale_post_number) — lookup by human reference
- `idx_listings_fragrance_name_lower` on LOWER(fragrance_name) — case-insensitive search
- `idx_listings_brand_lower` on LOWER(brand) — case-insensitive brand filter

**RLS Policies**:
- SELECT (`listings: public read published`): Returns rows where `status = 'Published'` OR `seller_id = auth.uid()` OR caller is admin. Unauthenticated users see only Published listings.
- INSERT (`listings: seller insert`): Authenticated user only; enforces `seller_id = auth.uid()`.
- UPDATE (`listings: seller update own`): Authenticated user WHERE `seller_id = auth.uid()`.
- UPDATE (`listings: admin update`): Users with admin role can update any listing (for moderation / removal).

---

### listing_photos

Stores up to five ordered photos per listing. Photos are uploaded to Supabase Storage; this table records the public URL and display position.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK, DEFAULT gen_random_uuid() | Photo row identifier |
| listing_id | uuid | NOT NULL, FK → listings(id) ON DELETE CASCADE | Parent listing. Cascades on listing deletion. |
| file_url | text | NOT NULL | Public URL of the photo in the `listing-photos` Storage bucket |
| display_order | integer | NOT NULL, CHECK (BETWEEN 1 AND 5) | Position in the photo carousel (1 = primary/cover photo) |
| uploaded_at | timestamptz | NOT NULL, DEFAULT now() | When the photo was uploaded |

**Unique constraint**: (listing_id, display_order) — prevents duplicate positions per listing.

**Indexes**:
- `idx_listing_photos_listing_order` on (listing_id, display_order) — ordered photo retrieval

**RLS Policies**:
- SELECT: All authenticated users can read photos for any listing (public browse).
- INSERT: Authenticated user can insert only for listings they own (seller_id = auth.uid() on the parent listing).
- DELETE: Authenticated user can delete photos only for their own listings.

---

## Existing Referenced Tables

### pickup_locations (spec 007)

Spec 007 owns this table's full definition. It holds a single optional pickup location per listing (1:0..1 with listings via a UNIQUE FK on listing_id). Relevant columns: listing_id, address, latitude, longitude, display_latitude, display_longitude, location_source, visibility_consent_acknowledged. See `specs/007-pickup-locations/data-model.md` for complete documentation.

### profiles (spec 001)

Linked to auth.users. The `transaction_count` column on profiles is incremented by the `listing_status_changed` trigger when a listing transitions to Sold. See `specs/001-user-auth/data-model.md`.

---

## Database Functions

### listing_status_changed()

**Purpose**: Stamp the appropriate timestamp column and maintain derived counters when a listing's status changes.

**Trigger**: `BEFORE UPDATE OF status ON listings FOR EACH ROW`

**Logic**:
1. When NEW.status = 'Published' AND OLD.status != 'Published': SET NEW.published_at = now() (only if published_at IS NULL — immutable once set)
2. When NEW.status = 'Sold': SET NEW.sold_at = now(); INCREMENT profiles.transaction_count for seller_id
3. When NEW.status = 'Expired': SET NEW.expired_at = now()
4. When NEW.status = 'Deleted': SET NEW.deleted_at = now()
5. When NEW.status = 'Removed': SET NEW.removed_at = now()

---

### auto_sold_on_zero_quantity()

**Purpose**: Automatically transition a listing to Sold when its stock is depleted.

**Trigger**: `BEFORE UPDATE OF quantity_available ON listings FOR EACH ROW`

**Logic**:
1. If NEW.quantity_available = 0 AND listing_type IN ('Full Bottle', 'Decant/Split'): SET NEW.status = 'Sold'

**Note**: Triggers the `listing_status_changed` trigger chain (Sold timestamp and transaction_count increment).

---

### listing_last_updated()

**Purpose**: Keep last_updated_at current on every row modification.

**Trigger**: `BEFORE UPDATE ON listings FOR EACH ROW`

**Logic**:
1. SET NEW.last_updated_at = now()
2. RETURN NEW

---

### process_expired_auctions()

**Purpose**: Scheduled function that closes Auction listings whose end time has passed.

**Schedule**: pg_cron, every 30 seconds — `* * * * * pg_cron.schedule(...)` (30-second interval via two cron entries or Supabase Scheduled Functions).

**Logic**:
1. SELECT id, seller_id FROM listings WHERE listing_type = 'Auction' AND status = 'Published' AND auction_end_at <= now()
2. For each matched listing: UPDATE listings SET status = 'Expired' WHERE id = <id>
3. INSERT into auction_notifications for all bidders on each expired auction (notifies of outcome)

**Note**: This function is the only path that transitions Auction listings to Expired. Non-auction listings expire via seller action or admin action only.

---

## Supabase Storage

### listing-photos bucket

| Setting | Value |
|---------|-------|
| Bucket name | listing-photos |
| Public | true (direct URL access without signed URLs) |
| File size limit | Configured at project level |
| Allowed MIME types | image/jpeg, image/png, image/webp |

**Storage RLS Policies**:
- SELECT: Public (anyone can read listing photos — bucket is public)
- INSERT: Authenticated user can upload only to `{auth.uid()}/` prefix (own folder)
- UPDATE: Authenticated user can replace files under `{auth.uid()}/` only
- DELETE: Authenticated user can delete files under `{auth.uid()}/` only

**Path convention**: `{user_id}/{listing_id}/{display_order}.{ext}`

Example: `a1b2c3d4-…/e5f6g7h8-…/1.jpg` — display_order 1 is the cover photo.

**Coordination with listing_photos table**: On photo upload, the application inserts a row into `listing_photos` with the resulting public URL. On photo delete, the application deletes the `listing_photos` row (which does not cascade to Storage — the Storage object must be deleted separately via the Storage API).

---

## Business Rules (Application-Layer Enforcement)

These rules are enforced in Server Actions, not by database constraints:

| Rule | Listing Types | Enforcement Point |
|------|--------------|-------------------|
| price_pkr must be > 0 | Full Bottle, Decant/Split, ISO, Auction | Server Action: publish listing |
| price_pkr may be 0 (or omitted) | Swap only | Server Action: no-op, DEFAULT 0 is valid |
| auction_end_at must be set and in the future | Auction | Server Action: publish listing |
| impression_declaration_accepted must be true | All types | Server Action: publish listing |
| At least 1 listing_photo row must exist | All types (Published) | Server Action: publish listing |
| condition is optional | ISO only | Server Action: allow null condition for ISO |
| sale_post_number is immutable | All types | Server Action: never expose as editable field; never allow UPDATE on this column |
| quantity_available is relevant for stock | Full Bottle, Decant/Split | Server Action: decrement on each sale; Auction and ISO ignore quantity |
| ISO price represents buyer budget | ISO | UI/UX labelling; stored identically in price_pkr |

---

## Migration Sequence

All objects for this feature are already deployed as part of migration `20260319_000_complete_schema`. No further migrations are required for spec 002. For reference, the deployment order within that migration was:

1. Create enum types: `listing_type`, `listing_condition`, `listing_status`
2. Create sequence: `listing_sale_post_seq`
3. Create table: `listings` with all columns, constraints, and DEFAULT using the sequence
4. Create table: `listing_photos` with FK → listings ON DELETE CASCADE
5. Create indexes on both tables (see index lists above)
6. Enable RLS on `listings` and `listing_photos`; create all policies
7. Create functions: `listing_status_changed()`, `auto_sold_on_zero_quantity()`, `listing_last_updated()`
8. Attach triggers on `listings` for each function above
9. Create function: `process_expired_auctions()`
10. Schedule `process_expired_auctions()` via pg_cron (every 30 seconds)
11. Create Storage bucket: `listing-photos` (public)
12. Apply Storage RLS policies for the `listing-photos` bucket
