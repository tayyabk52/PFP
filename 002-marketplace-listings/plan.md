# Implementation Plan: Marketplace Listings

**Branch**: `002-marketplace-listings` | **Date**: 2026-03-19 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-marketplace-listings/spec.md`

## Summary

This feature implements the supply and discovery side of the PFC marketplace:

1. **Listing Creation** — Verified sellers create fragrance listings in five types (Full Bottle, Decant/Split, ISO, Swap, Auction). ISO listings are open to any authenticated member. Server Actions validate all fields including the mandatory impression-declaration checkbox and type-specific rules (non-zero price, auction end date). Draft save enabled; drafts are private.

2. **Browse & Filter** — Public marketplace page (SSR for SEO) lists all Published listings newest-first. URL search params drive filter state (type, condition, price range, verified seller). Pagination at 20 per page.

3. **Keyword Search** — ILIKE queries against `LOWER(fragrance_name)` and `LOWER(brand)` using existing functional indexes. No full-text search needed for <1,000 listings.

4. **Listing Detail** — Full listing page with photos (ordered carousel), seller profile, off-platform payment disclaimer, "Message Seller" CTA (spec 006), and "Leave a Review" CTA (spec 003).

5. **Seller Management** — Sellers can edit published listings, mark listings as Sold (removes from public browse, increments transaction count via DB trigger), and delete listings. Sale post numbers are immutable.

6. **Auction Auto-Expiry** — `process_expired_auctions()` function runs via pg_cron every 30 seconds (already deployed). No additional setup required.

**Technical approach**: Next.js 16 Server Components for SSR browse/detail pages. Server Actions (`useActionState`) for create/edit/manage. Supabase client-side direct upload to `listing-photos` storage bucket. All DB logic (sale post generation, status timestamps, transaction count) handled by existing PostgreSQL triggers and sequences.

## Technical Context

**Language/Version**: TypeScript 5.x (strict mode)
**Frontend**: Next.js 16 (App Router, React 19, Server Components)
**Backend/BaaS**: Supabase (PostgreSQL 17, Auth, Storage, RLS)
**Storage**: Supabase Storage `listing-photos` bucket (public); PostgreSQL for all relational data
**Testing**: Vitest + React Testing Library (unit/component), Playwright (E2E)
**Target Platform**: Web (SSR via Next.js for SEO on public marketplace pages)
**Project Type**: Web application (marketplace feature)
**Performance Goals**: Browse/search < 2s for 5,000 listings (SC-005); Sold status removal < 5s (SC-006)
**Constraints**: <1,000 concurrent users; ILIKE search sufficient (no full-text); YAGNI for advanced features
**Scale/Scope**: ~5 pages, ~5 components, ~4 server actions, ~3 query functions

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Pre-Phase 0 | Post-Phase 1 | Notes |
|---|-----------|-------------|-------------|-------|
| I | Transparency-First | PASS | PASS | Off-platform payment disclaimer on every listing detail page (FR-009). Prices always visible (price_pkr non-zero enforcement, FR-007). No hidden listing data in public views. |
| II | Trust Through Verified Identity | PASS | PASS | Seller role enforced for all non-ISO listing types (FR-008). Verified seller badge shown on browse cards. ISO exception correctly scoped to members. |
| III | Community Safety | PASS | PASS | Impression/expression ban via two mechanisms: excluded from form options AND mandatory declaration checkbox (FR-006). Admin Removed status hides listings from all public views. |
| IV | Transaction-Ready Architecture | PASS | PASS | commission_rate, commission_status, transaction_value, payment_provider, payment_status all present as nullable inactive fields (FR-017). No UI exposure in v1. Schema supports future payment integration. |
| V | Mandatory Listing Completeness | PASS | PASS | All mandatory fields enforced before publish (FR-003): name, brand, type, size, condition, price, photo, delivery details. Draft fallback for incomplete submissions (FR-005). |
| VI | Simplicity & Incremental Delivery | PASS | PASS | ILIKE search (no pg_trgm or external search). Existing DB triggers/sequences reused. No client-side state management needed. URL params for filter state. |

**Gate result: ALL PASS. No violations.**

## Project Structure

### Documentation (this feature)

```text
specs/002-marketplace-listings/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: technology decisions
├── data-model.md        # Phase 1: database schema (already deployed)
├── quickstart.md        # Phase 1: setup guide
├── contracts/
│   └── api.md           # Phase 1: Server Actions + REST contracts
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
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
│           │       └── page.tsx      # Edit listing (owner only — server-side ownership check)
│           └── manage/
│               └── page.tsx          # Seller's listing management dashboard
├── components/
│   └── listings/
│       ├── ListingCard.tsx           # Browse card: sale post #, name, brand, type, condition, price
│       ├── ListingFilters.tsx        # Filter bar: type, condition, price range, verified seller filter
│       ├── ListingForm.tsx           # Create/edit form (client component, useActionState)
│       ├── ListingDetail.tsx         # Full detail view: photos, all fields, disclaimer, CTAs
│       └── PhotoUploader.tsx         # Multi-photo upload, display_order management, max 5
├── lib/
│   ├── actions/
│   │   └── listings.ts              # createListing, updateListing, markListingSold, deleteListing
│   └── queries/
│       └── listings.ts              # getListings (browse+filter), getListing (detail), getSellerListings
└── types/
    └── listings.ts                  # ListingWithPhotos, ListingCard, BrowseFilters type helpers

supabase/
└── migrations/
    └── 20260319_000_complete_schema.sql  # Already deployed — listings, listing_photos, all triggers

tests/
├── unit/
│   ├── actions/
│   │   └── listings.test.ts         # Server action validation logic
│   └── queries/
│       └── listings.test.ts         # Query builder unit tests
├── integration/
│   └── database/
│       └── listing-triggers.test.ts # trigger: sold→transaction_count, qty→0→sold, status timestamps
└── e2e/
    ├── listing-create.spec.ts       # Full create → publish → marketplace visibility
    ├── listing-browse.spec.ts       # Browse, filter, search, detail page
    └── listing-manage.spec.ts       # Mark sold, edit, delete
```

**Structure Decision**: Next.js App Router with two route groups — public (`/marketplace`, `/listings/[id]`) for SSR and SEO, and `(protected)/listings/` for authenticated create/edit/manage flows. Follows the same pattern established in spec 001 (`(auth)` and `(protected)` route groups). Query functions are separated from Server Actions to keep server-action files focused on mutation logic.

## Complexity Tracking

No violations. No entries needed.
