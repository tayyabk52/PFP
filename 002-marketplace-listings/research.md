# Research: 002-marketplace-listings

**Feature**: 002-marketplace-listings — create, browse, search, and manage fragrance listings
**Date**: 2026-03-19
**Platform**: Next.js 16 + Supabase

---

## R1: Sale Post Number Generation

**Decision**: PostgreSQL sequence `listing_sale_post_seq` with DEFAULT clause in listings table. Format `PFC-` + LPAD(nextval, 5, '0'). Already deployed.

**Rationale**: Auto-generated at INSERT time, immutable, globally unique, zero application code needed.

**Alternatives rejected**:
- App-layer UUID — not human-readable
- Custom trigger — more complex than DEFAULT expression
- User-supplied number — security risk

---

## R2: Keyword Search Implementation

**Decision**: ILIKE queries on `LOWER(fragrance_name)` and `LOWER(brand)` fields using existing functional indexes. Supabase client `.or('fragrance_name.ilike.%keyword%,brand.ilike.%keyword%')`. No full-text search.

**Rationale**: For <1,000 listings, ILIKE with btree indexes on lowercased columns is <5ms. pg_trgm or tsvector is over-engineered. YAGNI principle (Constitution VI).

**Alternatives rejected**:
- PostgreSQL full-text search (tsvector) — over-engineered for this scale
- pg_trgm — requires extension and index rebuild
- External search (Algolia, Meilisearch) — cost and complexity unjustified for <1K listings

---

## R3: Multi-Photo Upload Pattern

**Decision**: Client-side direct upload to Supabase Storage bucket `listing-photos` with path `{user_id}/{listing_id}/{display_order}.{ext}`. After listing is saved (or as draft), upload photos and INSERT to `listing_photos` table. Primary photo = display_order = 1.

**Rationale**: Direct client-to-storage upload avoids proxying large files through Next.js server. Listing must exist (by ID) before photo rows can be inserted (FK constraint). Draft save first, then photos pattern.

Photo constraints: max 5, min 1 for publish, JPEG/PNG/WEBP, max 10MB each.

**Alternatives rejected**:
- Server-side upload proxying — unnecessary overhead
- Base64 encoding — wasteful
- Storing order in filename only — hard to reorder

---

## R4: Auction Auto-Expiry

**Decision**: `process_expired_auctions()` PostgreSQL function scheduled via pg_cron every 30 seconds. Already deployed. Transitions `status = Published AND listing_type = Auction AND auction_end_at <= now()` to `status = Expired`. Notifies bidders via `auction_notifications`.

**Rationale**: Server-side scheduling ensures expiry is accurate regardless of user activity. 30-second granularity is acceptable for auction timing.

**Alternatives rejected**:
- Edge Function cron — requires Supabase Pro plan
- Client-side timer — unreliable
- On-request check — lazy expiry, listings could appear active after deadline

---

## R5: Listing Browse & Filter Architecture

**Decision**: Next.js Server Components with URL search params for filter state. Supabase server client queries directly from Server Component. Filter params: `type`, `condition`, `min_price`, `max_price`, `verified_seller`, `search`. Pagination: limit/offset with 20 listings per page.

**Rationale**: SSR for SEO on marketplace page. URL-based filter state is shareable and bookmarkable. No client-side state management needed for browse.

**Alternatives rejected**:
- Client-side filtering — loses SEO
- React Query/SWR — adds complexity
- GraphQL — over-engineered

---

## R6: Listing Form & Validation

**Decision**: React `useActionState` with Next.js Server Actions. Zod for server-side validation. Client-side impression declaration checkbox disables publish button until checked. Draft auto-save not implemented (complexity > benefit for v1). Two-step form: (1) create/save draft to get listing ID, (2) upload photos with listing ID.

**Rationale**: Server Actions pattern matches spec 001 (auth). Zod validation reusable. Impression declaration is purely client-side UX gate plus server-side re-validation.

**Alternatives rejected**:
- Multi-step wizard — complexity for v1
- Auto-save with debounce — over-engineered
- Client-side only validation — security risk

---

## R7: Role-Based Create Access

**Decision**: Middleware enforces: only `role = seller OR role = admin` can reach `/listings/new`. Exception: ISO-type listings can be created by any authenticated user (`role = member` allowed). Implement as: allow all authenticated users to reach the form page; server action validates that non-sellers can only submit ISO type; return error if non-seller attempts to create non-ISO listing.

**Rationale**: ISO listings are a buyer "wanted" post, not a seller offer. Any member should be able to post what they are looking for. Middleware cannot intercept listing type selection (happens inside the form), so type validation happens in the server action.

**Alternatives rejected**:
- Separate ISO-specific page — splits UX unnecessarily
- Role check only at page level — blocks member ISO creation
