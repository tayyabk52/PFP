# Tasks: Marketplace Listings

**Feature**: 002-marketplace-listings
**Input**: Design documents from `/specs/002-marketplace-listings/`
**Prerequisites**: plan.md ✓, spec.md ✓, data-model.md ✓, contracts/api.md ✓, quickstart.md ✓, research.md ✓

**No migrations needed** — full schema already deployed in `20260319_000_complete_schema` (listings, listing_photos, all triggers, pg_cron, storage bucket).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: User story this task belongs to (US1–US5)
- Exact file paths included in every task description

---

## Phase 1: Setup

**Purpose**: TypeScript type definitions that all query, action, and component files depend on.

- [X] T001 Create TypeScript type helpers in `src/types/listings.ts` — export `ListingRow`, `ListingWithPhotos` (listing + nested `listing_photos[]` + nested `profiles`), `ListingCardData` (fields needed by browse card), `BrowseFilters` (keyword, type, condition, priceMin, priceMax, verifiedOnly, hasPickup, page), and `ListingActionResult` (`success`, `listingId?`, `error?`, `fieldErrors?`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Query functions and server actions used by multiple user stories. MUST be complete before any story phase begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 [P] Implement query module in `src/lib/queries/listings.ts` — three exported async functions: `getListings(filters: BrowseFilters)` (Supabase server client, `status=eq.Published`, type/condition/price/verified/keyword filters, `or=(fragrance_name.ilike.%kw%,brand.ilike.%kw%)` when keyword present, nested `profiles!seller_id` join with display_name/avatar_url/pfc_seller_code/verified_at, `order=created_at.desc`, limit 20 + offset); `getListing(id: string)` (single listing with `listing_photos(*)` + `profiles!seller_id(*)` join, RLS enforces published-or-owner visibility); `getSellerListings(userId: string)` (all statuses, `seller_id=eq.userId`, `listing_photos(file_url,display_order)` for thumbnails). Apply `(supabase.from('listings') as any)` cast per established TS 5.9 workaround.
- [X] T003 [P] Implement server actions module in `src/lib/actions/listings.ts` — five `'use server'` functions all using `useActionState` signature `(prevState, formData) => Promise<ListingActionResult>`: `createListing` (role gate: ISO-only for `member`, seller/admin for other types; validates fragranceName, brand, sizeMl > 0; publish-mode: pricePkr > 0 for non-Swap, auctionEndAt in future for Auction, deliveryDetails present, impressionDeclarationAccepted = 'true', ≥1 listing_photo row exists; draft-mode: inserts with status='Draft'; publish-mode: inserts with status='Published'; returns `{ success: true, listingId }` or `{ success: false, fieldErrors }`); `updateListing` (ownership check seller_id = auth.uid(); same validation as createListing; sale_post_number never in UPDATE payload); `markListingSold` (ownership + status='Published' check; UPDATE status='Sold'; DB trigger stamps sold_at + increments transaction_count); `deleteListing` (ownership check; UPDATE status='Deleted'; DB trigger stamps deleted_at); `updateListingPhotos(listingId, photoUrls[])` (ownership check; DELETE existing listing_photos WHERE listing_id; INSERT new rows in transaction).

**Checkpoint**: Types, queries, and actions ready — all user story phases can now begin.

---

## Phase 3: User Story 1 — Seller Creates a New Listing (Priority: P1) 🎯 MVP

**Goal**: A verified seller fills in all mandatory fields, uploads at least one photo, and publishes a listing. The system auto-generates a `PFC-XXXXX` sale post number via DB sequence. The listing appears in the public marketplace.

**Independent Test**: Verified seller opens `/listings/new`, fills all mandatory fields, ticks the impression declaration checkbox, uploads one photo, clicks Publish — listing appears in `/marketplace` with auto-generated `PFC-XXXXX` sale post number and off-platform payment disclaimer visible.

- [X] T004 [P] [US1] Create `PhotoUploader` component in `src/components/listings/PhotoUploader.tsx` — `'use client'`; props: `listingId: string`, `existingPhotos: { url: string; displayOrder: number }[]`, `onComplete: () => void`; renders file input (accept image/jpeg,image/png,image/webp, multiple, max 5); client-side validates MIME type and 10 MB limit before upload; uploads each file to `listing-photos` Storage bucket at `{userId}/{listingId}/{order}.{ext}` via `supabase.storage.from('listing-photos').upload()`; collects public URLs via `getPublicUrl()`; on all uploads complete, calls `updateListingPhotos(listingId, photoUrls[])`; shows ordered thumbnail previews with drag-to-reorder for display_order; shows per-file upload progress; shows validation errors inline
- [X] T005 [US1] Create `ListingForm` component in `src/components/listings/ListingForm.tsx` — `'use client'`; props: `action: (prevState, formData) => Promise<ListingActionResult>`, `initialValues?: Partial<ListingRow>`, `userRole: 'member' | 'seller' | 'admin'`; uses `useActionState(action, null)`; fields: listing type (select: Full Bottle, Decant/Split, ISO, Swap, Auction — never includes Impression/Expression), fragrance name (text), brand (text), size ml (number, > 0), condition (select: New/Like New/Good/Fair/Poor — hidden/optional for ISO type), price PKR (number, label changes to "Budget (PKR)" for ISO type), delivery details (textarea), impression declaration checkbox (mandatory; Publish button disabled until checked), auction end date/time (datetime-local, shown only for Auction type), quantity available (number, shown only for Full Bottle and Decant/Split); member role + non-ISO type selected: show info message "Only verified sellers can post this listing type"; two submit buttons: "Save Draft" (submits hidden `action='draft'`) and "Publish" (submits hidden `action='publish'`, disabled until impression checkbox checked); renders `fieldErrors` inline next to each field; renders top-level `error` message; after draft save returns `listingId`, renders `PhotoUploader` component
- [X] T006 [US1] Create protected create listing page in `src/app/(protected)/listings/new/page.tsx` — server component; reads current user session + role from `supabase.auth.getUser()` and `user.app_metadata.role`; renders `<ListingForm>` wired to `createListing` action, passing `userRole`; page title "New Listing"; already auth-gated by `(protected)/layout.tsx` from spec 001

**Checkpoint**: Verified seller can create and publish a listing end-to-end. `PFC-XXXXX` auto-generated. Listing reachable at `/listings/{id}`.

---

## Phase 4: User Story 2 — Seller Saves a Draft Listing (Priority: P1)

**Goal**: A seller saves an incomplete listing as a draft (privately), returns later via their dashboard, resumes editing, and publishes once complete. Drafts are never visible to other users.

**Independent Test**: Seller saves draft → logs out → logs back in → finds draft under "My Listings" (status: Draft) → clicks "Resume Editing" → completes all fields → publishes → listing appears in `/marketplace`.

- [X] T007 [US2] Create seller listing management page in `src/app/(protected)/listings/manage/page.tsx` — server component; calls `getSellerListings(userId)` to fetch all own listings across all statuses; renders listings in sections by status group: Drafts (show "Resume Editing" link → `/listings/{id}/edit`), Published (show listing title, price, sale post number, "Mark Sold" button, "Edit" link, "Delete" button), Sold/Expired/Deleted (show in history table with status badge and timestamp); "Mark Sold" and "Delete" implemented as `<form>` elements with hidden `listingId` inputs wired to `markListingSold` / `deleteListing` actions; add simple JS-free confirmation via a dedicated confirm page or `formAction` pattern; calls `revalidatePath('/listings/manage')` after each mutation; empty state if seller has no listings; page title "My Listings"

**Checkpoint**: Draft round-trip verified. Drafts never visible in public browse (RLS). Seller can track all listing statuses in one place.

---

## Phase 5: User Story 3 — Buyer Browses Marketplace Listings (Priority: P1)

**Goal**: Any visitor (authenticated or not) opens the marketplace, sees published listings newest-first with key details on each card, applies filters (type/condition/price/verified seller), and views a full listing detail page showing photos, payment disclaimer, and CTAs.

**Independent Test**: Unauthenticated visitor opens `/marketplace`, applies filter "Decant/Split", sees only Decant/Split listings with sale post number/name/brand/price/condition/verified badge on each card. Clicks a card: detail page shows all fields, photo carousel, payment disclaimer, "Message Seller" button visible to authenticated non-owner, hidden from owner.

- [X] T008 [P] [US3] Create `ListingCard` component in `src/components/listings/ListingCard.tsx` — accepts `ListingCardData` prop; displays: cover photo (display_order=1, fallback placeholder), sale post number (small badge), fragrance name (heading), brand, listing type pill, size ml, condition, price PKR formatted as `PKR {:,}`, verified seller badge (shown when `verified_at` is non-null); entire card is a link to `/listings/{id}`; responsive layout suitable for grid display
- [X] T009 [P] [US3] Create `ListingFilters` component in `src/components/listings/ListingFilters.tsx` — `'use client'`; reads current URL search params via `useSearchParams()`; controls: keyword search text input (param `q`), listing type select (param `type`; options: all types), condition select (param `condition`), price min input (param `priceMin`), price max input (param `priceMax`), verified seller toggle checkbox (param `verified`), local pickup available toggle (param `pickup`, spec 007 hook — renders but can remain non-functional until spec 007); on any filter change, updates URL params via `useRouter().push()` with `startTransition` to avoid blocking; "Clear filters" resets all params; renders as a sidebar or top bar per design convention
- [X] T010 [US3] Create `ListingDetail` component in `src/components/listings/ListingDetail.tsx` — accepts `ListingWithPhotos` + `currentUserId: string | null`; photo carousel: images ordered by `display_order`, primary photo shown full-width with thumbnail strip; all listing fields displayed (sale post number, type, name, brand, size, condition, price, delivery details, auction end date if Auction type); prominent off-platform payment disclaimer box: "PFC does not process or guarantee payments. All transactions are off-platform." (always visible, FR-009, SC-002); seller profile card: avatar, display name, verified badge, transaction count, `pfc_seller_code`; "Message Seller" button: visible when `currentUserId` is set AND `currentUserId !== listing.seller_id`, hidden otherwise, links to `/messages?listing={id}`; unauthenticated click on Message Seller redirects to `/login`; "Leave a Review" section: visible when `currentUserId` is set AND `currentUserId !== listing.seller_id`, links to review flow (spec 003); listing owner sees neither CTA on their own listing
- [X] T011 [US3] Create public marketplace browse page in `src/app/marketplace/page.tsx` — server component (SSR); reads all filter params from `searchParams` prop into `BrowseFilters`; calls `getListings(filters)`; renders `<ListingFilters>` (client) + grid of `<ListingCard>` (server); "No listings found" empty state with "Clear filters" link; pagination: render prev/next links updating `page` URL param; `generateMetadata` returning `{ title: 'Marketplace — PFC', description: 'Browse fragrance listings...' }`
- [X] T012 [US3] Create public listing detail page in `src/app/listings/[id]/page.tsx` — server component (SSR); calls `getListing(id)` (returns null for non-Published listings unless authenticated owner); if null, call `notFound()` from `next/navigation`; reads current user id from session (null for unauthenticated); renders `<ListingDetail listing={listing} currentUserId={userId}`; `generateMetadata({ params })` fetches listing and returns `{ title: '{fragrance_name} by {brand} — PFC', description: '...' }`

**Checkpoint**: Public marketplace fully browsable and filterable without authentication. Detail page shows all fields, payment disclaimer, and conditional CTAs. Verified badge displayed correctly.

---

## Phase 6: User Story 4 — Buyer Searches Listings by Keyword (Priority: P2)

**Goal**: A buyer types a keyword in the search bar and sees all published listings where fragrance name or brand contains that keyword (case-insensitive ILIKE), ordered newest-first. Draft and sold listings are never returned.

**Independent Test**: User types "Aventus" in search → sees all Published listings with "Aventus" in `fragrance_name` or `brand` (case-insensitive). Empty search returns all Published listings. Searching "zzznomatch" shows "No results found" with "Browse all listings" link.

- [X] T013 [US4] Add keyword search input to `ListingFilters` in `src/components/listings/ListingFilters.tsx` — text input at top of filters, placeholder "Search fragrance or brand name", value bound to `q` URL param; submitting updates URL; clearing input removes `q` param; input is a controlled component reading from `useSearchParams()`
- [X] T014 [US4] Update `getListings` in `src/lib/queries/listings.ts` to handle `keyword` filter — when `filters.keyword` is non-empty, append `or=(fragrance_name.ilike.%{kw}%25,brand.ilike.%{kw}%25)` PostgREST parameter; LOWER-indexed columns on DB side handle case-insensitivity; when keyword is empty/undefined, omit the filter entirely so unfiltered browse is unaffected
- [X] T015 [US4] Read `q` search param in `src/app/marketplace/page.tsx` and pass as `keyword` to `getListings`; update "No listings found" empty state to show: if `keyword` is set, display "No listings found for '{keyword}'" with a "Browse all listings" link that clears all params; if no keyword and no filters, show "No listings yet — check back soon"

**Checkpoint**: Keyword search functional end-to-end. Draft/sold listings excluded by existing `status=eq.Published` filter. Empty state messages differentiate keyword search vs unfiltered empty marketplace.

---

## Phase 7: User Story 5 — Seller Manages Their Listings (Priority: P2)

**Goal**: A seller views all their listings, edits a published listing (sale post number unchanged), marks a listing as sold (removed from public browse), and deletes a listing.

**Independent Test**: Seller marks a Published listing as "Sold" → listing disappears from `/marketplace` and keyword search results within 5 seconds; listing remains visible in seller's "My Listings" dashboard with "Sold" status badge and `sold_at` timestamp.

- [X] T016 [US5] Create edit listing page in `src/app/(protected)/listings/[id]/edit/page.tsx` — server component; calls `getListing(id)` and verifies `listing.seller_id === currentUserId`; redirect to `/listings/manage` with error message if ownership check fails; renders `<ListingForm>` with `initialValues` populated from existing listing and wired to `updateListing` action; sale post number rendered as a read-only `<p>` field (never in a form input, never passed in FormData); `userRole` passed through so form can show/hide type-conditional fields correctly
- [X] T017 [US5] Complete seller management page actions in `src/app/(protected)/listings/manage/page.tsx` — extend T007's scaffolding: wire "Mark Sold" `<form>` with `action={markListingSold}`, hidden `listingId` input; wire "Delete" `<form>` with `action={deleteListing}`, hidden `listingId` input; add a two-step delete confirmation: first click reveals a "Are you sure?" inline confirmation form, second click submits; after each mutation, `revalidatePath('/listings/manage')` causes server re-render showing updated status; sold listings appear in "Sold" history section with `sold_at` date; deleted listings removed from all sections on next render

**Checkpoint**: Full seller inventory lifecycle: create (US1) → draft (US2) → publish (US1) → edit (US5) → mark sold / delete (US5). Sold listing removal from public browse confirmed within 5 seconds (SC-006).

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final hardening applied across all user stories.

- [X] T018 [P] Harden `ListingForm` loading and error states in `src/components/listings/ListingForm.tsx` — use `useFormStatus` or check `isPending` from `useActionState` to disable both submit buttons during pending server action; add visual spinner on active button; ensure all `fieldErrors` keys map to field names and display inline below each input with accessible `aria-describedby`; ensure top-level `error` is announced via `role="alert"`
- [X] T019 [P] Add Open Graph metadata to marketplace page in `src/app/marketplace/page.tsx` — extend `generateMetadata` to return `openGraph: { title, description, type: 'website' }` tags for social sharing; ensure listing detail page `generateMetadata` also returns `openGraph.images` using the listing's cover photo URL
- [ ] T020 Run quickstart.md verification checklist — manually (or via Playwright) verify all 15 checklist items in `specs/002-marketplace-listings/quickstart.md` pass against running dev server; mark each item `[X]` as confirmed

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 (types imported by queries and actions)
- **Phase 3 (US1)**: Depends on Phase 2 — `createListing` and `updateListingPhotos` must exist
- **Phase 4 (US2)**: Depends on Phase 3 — draft mode is a mode of the `ListingForm` built in US1; manage page requires `getSellerListings`
- **Phase 5 (US3)**: Depends on Phase 2 — `getListings` / `getListing` must exist; can proceed in parallel with US1/US2 after Foundational
- **Phase 6 (US4)**: Depends on Phase 5 — extends `ListingFilters` (T009) and `getListings` (T002)
- **Phase 7 (US5)**: Depends on Phase 3 (edit page reuses `ListingForm`), Phase 4 (manage page extended), and Phase 2 (`updateListing`, `markListingSold`, `deleteListing` ready)
- **Phase 8 (Polish)**: Depends on all story phases complete

### User Story Dependencies

- **US1 (P1)**: Foundational only. No story dependencies.
- **US2 (P1)**: Depends on US1 (`ListingForm` and `createListing` with draft mode exist).
- **US3 (P1)**: Foundational only. Can start in parallel with US1/US2.
- **US4 (P2)**: Depends on US3 (`ListingFilters` component and `getListings` query exist).
- **US5 (P2)**: Depends on US1 (`ListingForm` for edit), US2 (manage page scaffolded), Foundational.

### Within Each Story

- Types/shared infrastructure before components
- Component before page (page composes component)
- Core implementation before integration hooks (spec 003/006/007 CTAs)
- Story complete before moving to next priority

### Parallel Opportunities

- **T002 + T003** (Foundational): query module and actions module are independent files
- **T004 + T005** (US1): PhotoUploader is self-contained [P] alongside form
- **T008 + T009** (US3): ListingCard and ListingFilters are independent components [P]
- **T018 + T019** (Polish): different files, no dependencies [P]

---

## Parallel Example: Phase 2 (Foundational)

```
# Launch both foundational tasks simultaneously (different files):
Task A: src/lib/queries/listings.ts  [T002]
Task B: src/lib/actions/listings.ts  [T003]
```

## Parallel Example: Phase 5 (US3 — Browse)

```
# Launch card and filter components simultaneously (different files):
Task A: src/components/listings/ListingCard.tsx    [T008]
Task B: src/components/listings/ListingFilters.tsx [T009]

# Then sequentially (depends on card/filter patterns):
Task C: src/components/listings/ListingDetail.tsx  [T010]
Task D: src/app/marketplace/page.tsx               [T011]  (composes ListingCard + ListingFilters)
Task E: src/app/listings/[id]/page.tsx             [T012]  (composes ListingDetail)
```

---

## Implementation Strategy

### MVP First (P1 Stories Only — US1 + US2 + US3)

1. T001 — Types
2. T002 + T003 in parallel — Foundational
3. T004 + T005 → T006 — US1 (create + publish)
4. T007 — US2 (draft save + manage page)
5. T008 + T009 in parallel → T010 → T011 → T012 — US3 (browse + detail)
6. **STOP and VALIDATE**: All P1 stories working. Public marketplace live.
7. Deploy MVP.

### Full Delivery (add P2)

8. T013 → T014 → T015 — US4 (keyword search)
9. T016 → T017 — US5 (edit + full manage)
10. T018 + T019 in parallel → T020 — Polish

---

## Notes

- **No migrations**: All schema objects already deployed. The `listing_sale_post_seq` sequence, `listing_status_changed` trigger (stamps sold_at, increments transaction_count), `auto_sold_on_zero_quantity` trigger, and `process_expired_auctions` pg_cron job are all live.
- **TypeScript 5.9 workaround**: Use `(supabase.from('listings') as any)` cast in queries and actions (established pattern from spec 001 — see `src/lib/actions/auth.ts` and `src/lib/actions/profile.ts`).
- **Auth guard**: The `(protected)` route group's `layout.tsx` (spec 001) already redirects unauthenticated users. No additional middleware needed for 002 routes.
- **Role check**: Read `user.app_metadata.role` server-side in the create/edit pages and pass to `ListingForm`. Do NOT read from client-side state for security-relevant role gating.
- **Sale post number immutability**: Never render `sale_post_number` inside a `<form>` input. Show it as a read-only `<p>` or `<span>`. Never pass it in `FormData` to `updateListing`.
- **Impression/Expression exclusion**: The `ListingForm` type dropdown must list exactly five values: Full Bottle, Decant/Split, ISO, Swap, Auction. The strings "Impression" and "Expression" must not appear as options anywhere in the form (FR-006 mechanism 1).
- **Spec 003/006/007 CTAs**: "Message Seller" and "Leave a Review" CTAs in `ListingDetail` (T010) are stubs for now — render the button/link with the correct `href` but the destination page is owned by the respective specs. "Local Pickup Available" filter in `ListingFilters` (T009) renders but the `pickup_locations` table integration is owned by spec 007.
