# Quickstart: 002-marketplace-listings

**Feature**: Marketplace Listings
**Date**: 2026-03-19
**Platform**: Next.js 16 + Supabase
**Database**: Already deployed — migration `20260319_000_complete_schema` covers all tables, triggers, RLS policies, and storage buckets. No new migrations are needed.

---

## Prerequisites (already satisfied)

- Next.js 16 project with `@supabase/supabase-js` and `@supabase/ssr` installed
- Supabase project linked with environment variables set
- Database schema deployed (`listings`, `listing_photos`, `pickup_locations` all exist)
- Storage bucket `listing-photos` exists (public)

---

## Key Files to Create

```
src/
├── app/
│   ├── marketplace/
│   │   └── page.tsx                  # Public browse/search page (SSR, URL filter params)
│   ├── listings/
│   │   └── [id]/
│   │       └── page.tsx              # Public listing detail page (SSR)
│   └── (protected)/
│       └── listings/
│           ├── new/
│           │   └── page.tsx          # Create listing page (all authenticated users)
│           ├── [id]/
│           │   └── edit/
│           │       └── page.tsx      # Edit listing page (owner only)
│           └── manage/
│               └── page.tsx          # Seller's listing management dashboard
├── components/
│   └── listings/
│       ├── ListingCard.tsx           # Browse card (sale post #, name, brand, price, type, condition)
│       ├── ListingFilters.tsx        # Filter bar (type, condition, price range, verified)
│       ├── ListingForm.tsx           # Create/edit form (client, useActionState)
│       ├── ListingDetail.tsx         # Full detail view (photos, disclaimer, CTAs)
│       └── PhotoUploader.tsx         # Multi-photo upload (max 5, ordered, client-side)
├── lib/
│   ├── actions/
│   │   └── listings.ts              # createListing, updateListing, markListingSold, deleteListing
│   └── queries/
│       └── listings.ts              # getListings (browse), getListing (detail), getSellerListings
└── types/
    └── listings.ts                  # ListingWithPhotos, ListingCard, BrowseFilters types
```

---

## Integration Points

1. **Middleware** (`src/middleware.ts`): `/listings/new` and `/listings/[id]/edit` require authentication. Already handled by existing middleware — no additional middleware needed.

2. **Profiles**: The listing detail page reads the seller's profile via JOIN to display name, avatar, and verification status.

3. **Spec 006 (Messaging)**: "Message Seller" CTA on the detail page — implemented as a button linking to `/messages?listing={id}` for feature 006 to handle. Shown to non-owner authenticated users only.

4. **Spec 003 (Reviews)**: "Leave a Review" CTA on the detail page — implemented as a button/section linking to the review form (owned by spec 003). Shown to non-owner authenticated users only.

5. **Spec 007 (Pickup)**: `pickup_locations` table already exists; a pickup filter is included in the browse filters component.

6. **Auction Auto-Expiry**: Already running via `pg_cron`. No additional setup needed.

---

## Running Tests

```bash
# Unit tests (Vitest)
npx vitest run src/lib/actions/listings.ts
npx vitest run src/lib/queries/listings.ts

# Component tests (Vitest + React Testing Library)
npx vitest run src/components/listings/

# E2E tests (Playwright)
npx playwright test tests/e2e/listing-create.spec.ts
npx playwright test tests/e2e/listing-browse.spec.ts
npx playwright test tests/e2e/listing-manage.spec.ts
```

---

## Verification Checklist

- [ ] Verified seller can create a Full Bottle listing with 1+ photos and see it in `/marketplace`
- [ ] Sale post number is auto-generated in `PFC-XXXXX` format and cannot be edited
- [ ] Member (non-seller) can create an ISO listing but not a Full Bottle listing
- [ ] Unauthenticated visitor can browse `/marketplace` and view listing detail pages
- [ ] Filter by listing type shows only matching results
- [ ] Keyword search matches fragrance name and brand (case-insensitive)
- [ ] Off-platform payment disclaimer is visible on every listing detail page
- [ ] "Message Seller" button visible to non-owner authenticated users, hidden from owner and unauthenticated visitors
- [ ] "Leave a Review" section visible to non-owner authenticated users, hidden from owner
- [ ] Impression declaration checkbox must be checked before publish is enabled
- [ ] Zero-price validation: non-Swap listings with price 0 cannot be published
- [ ] Marking listing as "Sold" removes it from `/marketplace` browse
- [ ] Deleting a listing removes it from all public views
- [ ] Auction listing auto-expires after `auction_end_at` (within 30 seconds)
- [ ] Draft listing is invisible to all users except the creator
