# API Contracts: Marketplace Listings

**Feature**: 002-marketplace-listings
**Date**: 2026-03-19
**Platform**: Next.js 16 + Supabase (PostgreSQL + Auth + Storage)

---

## 1. Supabase REST Endpoints (PostgREST)

All requests use the Supabase project URL as the base: `{SUPABASE_URL}/rest/v1/`

---

### GET /rest/v1/listings — Browse / Search Listings

**Auth**: Public (anon key)
**Use case**: Marketplace browse page, search, and filtering

**Required query parameter** (always present for public browse):
```
status=eq.Published
```

**Optional filter parameters**:

| Parameter | Example | Description |
|-----------|---------|-------------|
| `listing_type` | `listing_type=eq.Full Bottle` | Filter by type enum value |
| `condition` | `condition=eq.Like New` | Filter by condition enum value |
| `price_pkr` (range) | `price_pkr=gte.1000&price_pkr=lte.50000` | Price range in PKR |
| `or` (keyword) | `or=(fragrance_name.ilike.%oud%25,brand.ilike.%oud%25)` | Case-insensitive keyword across name and brand |
| `order` | `order=created_at.desc` | Default sort: newest first |
| `limit` | `limit=20` | Page size (default: 20) |
| `offset` | `offset=0` | Pagination offset |

**`select` — include verified seller join**:
```
select=*,profiles!seller_id(display_name,avatar_url,pfc_seller_code,is_verified:verified_at)
```

**Full example request**:
```
GET /rest/v1/listings
  ?status=eq.Published
  &listing_type=eq.Full Bottle
  &price_pkr=gte.1000&price_pkr=lte.50000
  &order=created_at.desc
  &limit=20&offset=0
  &select=*,profiles!seller_id(display_name,avatar_url,pfc_seller_code,is_verified:verified_at)
```

**Response 200** — array of listing objects:
```json
[
  {
    "id": "e5f6g7h8-0000-0000-0000-000000000001",
    "sale_post_number": "PFC-00042",
    "seller_id": "a1b2c3d4-0000-0000-0000-000000000001",
    "listing_type": "Full Bottle",
    "fragrance_name": "Black Afgano",
    "brand": "Nasomatto",
    "size_ml": 30.0,
    "condition": "Like New",
    "price_pkr": 18000,
    "status": "Published",
    "delivery_details": "Lahore local only, or TCS at buyer's cost",
    "impression_declaration_accepted": true,
    "auction_end_at": null,
    "quantity_available": 1,
    "created_at": "2026-03-10T09:00:00Z",
    "published_at": "2026-03-10T09:15:00Z",
    "last_updated_at": "2026-03-10T09:15:00Z",
    "sold_at": null,
    "expired_at": null,
    "deleted_at": null,
    "removed_at": null,
    "profiles": {
      "display_name": "Zainab K.",
      "avatar_url": "https://.../avatars/a1b2c3d4/avatar.jpg",
      "pfc_seller_code": "PFC-S-00007",
      "is_verified": "2026-01-15T12:00:00Z"
    }
  }
]
```

**Note**: `is_verified` is the raw `verified_at` timestamp aliased via PostgREST. A non-null value means the seller is verified. The field is null for unverified sellers.

---

### GET /rest/v1/listings?id=eq.{id} — Single Listing Detail

**Auth**: Public (anon key)
**Use case**: Listing detail page at `/listings/{id}`

**Query**:
```
GET /rest/v1/listings
  ?id=eq.e5f6g7h8-0000-0000-0000-000000000001
  &select=*,listing_photos(*),profiles!seller_id(*)
```

**Notes**:
- `listing_photos(*)` returns all photo rows ordered by `display_order` (ascending).
- `profiles!seller_id(*)` returns the full seller profile row.
- RLS ensures unauthenticated callers only see the listing if `status = 'Published'`. An authenticated seller calling for their own Draft listing will receive it; anyone else receives an empty array.

**Response 200** — single-element array (use `.single()` in the client to unwrap):
```json
[
  {
    "id": "e5f6g7h8-0000-0000-0000-000000000001",
    "sale_post_number": "PFC-00042",
    "fragrance_name": "Black Afgano",
    "brand": "Nasomatto",
    "size_ml": 30.0,
    "condition": "Like New",
    "price_pkr": 18000,
    "status": "Published",
    "delivery_details": "Lahore local only, or TCS at buyer's cost",
    "listing_photos": [
      {
        "id": "photo-uuid-1",
        "listing_id": "e5f6g7h8-...",
        "file_url": "https://.../listing-photos/a1b2.../e5f6.../1.jpg",
        "display_order": 1,
        "uploaded_at": "2026-03-10T09:10:00Z"
      },
      {
        "id": "photo-uuid-2",
        "listing_id": "e5f6g7h8-...",
        "file_url": "https://.../listing-photos/a1b2.../e5f6.../2.jpg",
        "display_order": 2,
        "uploaded_at": "2026-03-10T09:10:00Z"
      }
    ],
    "profiles": {
      "id": "a1b2c3d4-...",
      "display_name": "Zainab K.",
      "avatar_url": "https://.../avatars/a1b2c3d4/avatar.jpg",
      "pfc_seller_code": "PFC-S-00007",
      "verified_at": "2026-01-15T12:00:00Z",
      "transaction_count": 14
    }
  }
]
```

---

### GET /rest/v1/listings?seller_id=eq.{user_id} — Seller's Own Listings

**Auth**: Authenticated (caller's JWT in `Authorization: Bearer` header)
**Use case**: Seller dashboard — manage all own listings regardless of status

**Query**:
```
GET /rest/v1/listings
  ?seller_id=eq.{auth.uid()}
  &select=*,listing_photos(*)
  &order=created_at.desc
```

**Notes**:
- RLS policy `listings: public read published` permits this: rows where `seller_id = auth.uid()` are always visible to the authenticated owner, regardless of status.
- Returns listings in all statuses: Draft, Published, Sold, Expired, Deleted, Removed.
- `listing_photos(*)` included so the dashboard can show cover photo thumbnails.

**Response 200** — array of listing objects (same shape as browse response, without nested `profiles`):
```json
[
  {
    "id": "e5f6g7h8-...",
    "sale_post_number": "PFC-00042",
    "status": "Published",
    "fragrance_name": "Black Afgano",
    "brand": "Nasomatto",
    "price_pkr": 18000,
    "listing_photos": [
      {
        "file_url": "https://.../listing-photos/.../1.jpg",
        "display_order": 1
      }
    ]
  },
  {
    "id": "aa11bb22-...",
    "sale_post_number": "PFC-00039",
    "status": "Draft",
    "fragrance_name": "Tobacco Vanille",
    "brand": "Tom Ford",
    "price_pkr": 25000,
    "listing_photos": []
  }
]
```

---

## 2. Next.js Server Actions

All actions live in `src/lib/actions/listings.ts` and are declared with `'use server'`.
All actions conform to the React 19 `useActionState` signature: `(prevState, formData) => Promise<ActionResult>`.

```typescript
type ActionResult = {
  success: boolean
  listingId?: string
  error?: string
  fieldErrors?: Record<string, string>
}
```

---

### createListing(prevState, formData) → ActionResult

**Auth**: Authenticated. Role requirements enforced server-side:
- `listing_type = 'ISO'`: any authenticated user (role `member`, `seller`, or `admin`)
- All other types: role must be `seller` or `admin`

**Purpose**: Create a new listing as either a Draft or trigger immediate publish.

**FormData fields**:

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `listingType` | string | Yes | `'Full Bottle'` \| `'Decant/Split'` \| `'ISO'` \| `'Swap'` \| `'Auction'` |
| `fragranceName` | string | Yes | Non-empty |
| `brand` | string | Yes | Non-empty |
| `sizeMl` | string / number | Yes | Parsed to numeric; must be > 0 |
| `condition` | string | Conditional | Required for all types except ISO |
| `pricePkr` | string / number | Conditional | Required and > 0 for all non-Swap types |
| `deliveryDetails` | string | Required to publish | May be omitted for draft save |
| `impressionDeclarationAccepted` | `'true'` \| `'false'` | Required to publish | Must be `'true'` to publish |
| `auctionEndAt` | ISO datetime string | Conditional | Required for `Auction` type; must be in the future |
| `quantityAvailable` | string / number | Optional | Relevant for `Full Bottle` and `Decant/Split` only |
| `action` | `'draft'` \| `'publish'` | Yes | Controls whether listing is saved as Draft or Published |

**Validation rules** (applied server-side before any DB write):

| Rule | Condition |
|------|-----------|
| `fragranceName`, `brand` non-empty | Always |
| `sizeMl` > 0 | Always |
| `pricePkr` > 0 | `listingType` is not `'Swap'` AND `action = 'publish'` |
| `condition` present | `listingType` is not `'ISO'` |
| `auctionEndAt` present and in future | `listingType = 'Auction'` AND `action = 'publish'` |
| `deliveryDetails` present | `action = 'publish'` |
| `impressionDeclarationAccepted = 'true'` | `action = 'publish'` |
| At least 1 photo exists in `listing_photos` | `action = 'publish'` (checked after insert) |
| Caller role is `seller` or `admin` | `listingType` is not `'ISO'` |

**Returns**:

On draft save success:
```json
{ "success": true, "listingId": "e5f6g7h8-uuid" }
```

On publish success (server action also calls `redirect('/listings/e5f6g7h8-uuid')`):
```json
{ "success": true, "listingId": "e5f6g7h8-uuid" }
```

On validation failure:
```json
{
  "success": false,
  "fieldErrors": {
    "pricePkr": "Price is required for this listing type",
    "deliveryDetails": "Delivery details are required to publish"
  }
}
```

On auth / role failure:
```json
{ "success": false, "error": "You must be a registered seller to post this listing type" }
```

---

### updateListing(prevState, formData) → ActionResult

**Auth**: Authenticated. Caller must be the listing owner (enforced server-side via `seller_id = auth.uid()` check before any write).

**Purpose**: Update an existing listing (Draft or Published). The `sale_post_number` column is never modified by this action and must not be exposed as an editable field.

**FormData fields**: Same as `createListing`, plus:

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `listingId` | string (UUID) | Yes | The listing to update |

All validation rules from `createListing` apply identically.

**Returns**: Same `ActionResult` shape as `createListing`.

On success:
```json
{ "success": true, "listingId": "e5f6g7h8-uuid" }
```

On ownership check failure:
```json
{ "success": false, "error": "Listing not found or you do not have permission to edit it" }
```

---

### markListingSold(prevState, formData) → ActionResult

**Auth**: Authenticated. Caller must be the listing owner.

**Purpose**: Transition a Published listing to Sold status. The DB trigger `listing_status_changed()` fires on the status UPDATE, stamps `sold_at = now()`, and increments `profiles.transaction_count` for the seller.

**FormData fields**:

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `listingId` | string (UUID) | Yes | Must be a Published listing owned by the caller |

**Returns**:

On success:
```json
{ "success": true }
```

On failure (not owner, listing not found, or invalid current status):
```json
{ "success": false, "error": "Unable to mark listing as sold" }
```

---

### deleteListing(prevState, formData) → ActionResult

**Auth**: Authenticated. Caller must be the listing owner.

**Purpose**: Soft-delete a listing (sets `status = 'Deleted'`). The DB trigger `listing_status_changed()` stamps `deleted_at = now()`. The listing remains in the database and is no longer visible in public browse due to RLS.

**FormData fields**:

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `listingId` | string (UUID) | Yes | Must be a listing owned by the caller |

**Returns**:

On success:
```json
{ "success": true }
```

On failure (not owner or listing not found):
```json
{ "success": false, "error": "Unable to delete listing" }
```

---

### updateListingPhotos(listingId, photoUrls[]) → ActionResult

**Auth**: Authenticated. Caller must be the listing owner.

**Purpose**: Sync the `listing_photos` table after a client-side photo upload session completes. Called after all Storage uploads finish to ensure the DB reflects the final photo set.

**Parameters**:

| Parameter | Type | Notes |
|-----------|------|-------|
| `listingId` | string (UUID) | Target listing |
| `photoUrls` | `Array<{ url: string; displayOrder: number }>` | Ordered photo URLs from Storage |

**Behaviour**: Replaces all existing `listing_photos` rows for the listing (DELETE then INSERT within a transaction) to match the provided array.

**Returns**: Same `ActionResult` shape (no `listingId` in response).

---

## 3. Photo Upload Contract (Supabase Storage)

Photo uploads are performed client-side directly to Supabase Storage. The server action `updateListingPhotos` is called after all uploads complete to sync the database.

### Storage Bucket

| Setting | Value |
|---------|-------|
| Bucket name | `listing-photos` |
| Visibility | Public (direct URL access, no signed URLs required) |
| Max file size | 10 MB |
| Allowed MIME types | `image/jpeg`, `image/png`, `image/webp` |

### Storage RLS Policies

| Operation | Policy |
|-----------|--------|
| SELECT | Public — anyone can read (bucket is public) |
| INSERT | Authenticated users may upload only to `{auth.uid()}/` prefix |
| UPDATE | Authenticated users may replace files under `{auth.uid()}/` only |
| DELETE | Authenticated users may delete files under `{auth.uid()}/` only |

### Path Convention

```
{user_id}/{listing_id}/{display_order}.{ext}
```

Example:
```
a1b2c3d4-0000-0000-0000-000000000001/e5f6g7h8-0000-0000-0000-000000000001/1.jpg
```

`display_order = 1` is always the cover photo shown in listing cards and as the default carousel image.

### Upload Flow

```
1. User selects up to 5 image files in the listing form
2. Client validates: MIME type in [jpeg, png, webp], file size <= 10 MB
3. For each file (in display_order sequence):
     supabase.storage
       .from('listing-photos')
       .upload(`{user_id}/{listing_id}/{display_order}.{ext}`, file)
4. Collect the public URL for each successful upload:
     supabase.storage
       .from('listing-photos')
       .getPublicUrl(`{path}`)
5. On all uploads complete: call updateListingPhotos(listingId, photoUrls[])
6. Server action syncs listing_photos table (DELETE + INSERT in transaction)
```

### listing_photos Table Sync

After the Storage upload, the client calls `updateListingPhotos`. This ensures the `listing_photos` rows are in sync with what was actually uploaded. Any previously uploaded photos not in the new `photoUrls` array are removed from the table (but the Storage object must be deleted separately via the Storage API if cleanup is needed).

---

## 4. Middleware / Route Protection Contract

Route protection is split between Next.js middleware (redirect on auth state) and server-side checks in Server Actions (ownership and role enforcement).

### Route Table

| Route | Auth Requirement | Notes |
|-------|-----------------|-------|
| `/marketplace` | None — public | Listing browse; uses anon key |
| `/listings/{id}` | None — public | Listing detail; uses anon key |
| `/listings/new` | Authenticated | Any authenticated user may load the page; Server Action enforces ISO-only for `member` role |
| `/listings/{id}/edit` | Authenticated + listing owner | Ownership verified server-side in `updateListing` action, not in middleware |

### Middleware Behaviour

The Next.js middleware (`src/middleware.ts`) handles session-level redirects:

- Unauthenticated user visits `/listings/new` → redirect to `/login?redirectTo=/listings/new`
- Unauthenticated user visits `/listings/{id}/edit` → redirect to `/login`
- Authenticated user visits any route → pass through; ownership/role checks are deferred to Server Actions

### Server Action Enforcement (not middleware)

Role and ownership rules that cannot be checked in middleware (because they require DB reads) are enforced inside the Server Actions:

| Check | Enforced in |
|-------|------------|
| `listing_type != 'ISO'` requires role `seller` or `admin` | `createListing` |
| `listingId` must belong to `auth.uid()` | `updateListing`, `markListingSold`, `deleteListing` |
| Listing must be in `Published` status to mark sold | `markListingSold` |

---
