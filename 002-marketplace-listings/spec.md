# Feature Specification: Marketplace Listings

**Feature Branch**: `002-marketplace-listings`
**Created**: 2026-03-18
**Status**: Draft
**Input**: User description: "Marketplace listings — create, browse, and search fragrance
listings supporting five types: full bottle, decant/split, ISO, swap, and auction."

**Related features**:
- `008-listing-schema` — Owns the complete Listing data model, all field definitions,
  validation rules, status lifecycle, and extensibility hooks. This spec (002) defines the
  marketplace behaviours (create, browse, search, manage) that act on that entity. Any
  conflict between the two specs is resolved in favour of 008.
- `003-seller-verification` — Owns review submission behaviour and seller profiles. The
  listing detail page defined here MUST include a "Leave a Review" CTA (FR-020). All review
  behaviour (rating, proof image, one-per-listing limit) is specified in
  `specs/003-seller-verification/spec.md`; this spec owns only the CTA placement.
- `006-buyer-seller-messaging` — The listing detail page defined here
  MUST include a "Message Seller" CTA (FR-018). All messaging behaviour is specified in
  `specs/006-buyer-seller-messaging/spec.md`; this spec owns only the CTA placement and
  the listing-status events that affect active conversation references (sold, expired,
  deleted listings surface as "Listing no longer available" in message threads).
- `007-local-pickup-maps` — Sellers may optionally add a pickup location to any listing.
  At plan stage, the Listing entity defined here MUST be extended with an optional
  `pickup_location` reference, and the browse filter list (FR-011) MUST be extended to
  include a "Local Pickup Available" filter option. All pickup location behaviour is
  specified in `specs/007-local-pickup-maps/spec.md`.

## Clarifications

### Session 2026-03-18

- Q: What happens when an auction listing's end date/time is reached? → A: Auto-transitions to "Expired" at end time; removed from public browse; seller sees it in listing history as "Expired"
- Q: How is the impression/expression ban enforced at submission? → A: Both mechanisms — "Impression" is excluded from all selectable options in the listing form, AND seller must tick a declaration checkbox confirming the listing is not an impression/expression before publishing
- Q: Maximum photos per listing? → A: 5 photos maximum

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Seller Creates a New Listing (Priority: P1)

A verified seller wants to list a fragrance for sale. They fill in all mandatory fields,
upload at least one photo, and publish the listing. The system auto-generates a unique
sale post number. The listing then appears in the public marketplace.

**Why this priority**: Creating listings is the supply side of the marketplace. Without
listings, there is nothing for buyers to browse or search.

**Independent Test**: A verified seller can create a full-bottle listing with all mandatory
fields, submit it, and see it appear in the marketplace with an auto-generated sale post
number and the off-platform payment disclaimer visible.

**Acceptance Scenarios**:

1. **Given** a verified seller is on the create listing page, **When** they fill in all
   mandatory fields (fragrance name, brand, type, size in ml, condition, price in PKR,
   minimum one photo, delivery details) and submit, **Then** the listing is published with
   a unique system-generated sale post number and appears in the public marketplace.
2. **Given** a seller submits a listing with one or more mandatory fields missing,
   **When** they attempt to publish, **Then** the system blocks submission, highlights the
   missing fields, and saves the listing as a draft.
3. **Given** a seller selects an impression or expression as the fragrance being listed,
   **When** they attempt to publish, **Then** the system rejects the listing with a clear
   message that impressions/expressions are banned on PFC.
4. **Given** a seller enters a zero or blank price on a non-Swap listing type, **When** they
   attempt to publish, **Then** the system rejects the submission. (Swap listings may have
   PKR 0 for a no-cash-component swap — zero price is valid for Swap type only.)
5. **Given** a published listing page, **When** any user views it, **Then** a prominent
   off-platform payment disclaimer is displayed stating that PFC does not handle payments.
6. **Given** a user with Member role only, **When** they attempt to access the create
   listing page, **Then** they are shown a message that only verified sellers can create
   listings.

---

### User Story 2 - Seller Saves a Draft Listing (Priority: P1)

A seller starts creating a listing but does not have all the information ready (e.g., photos
not yet taken). They save it as a draft to complete later. The draft is private and does
not appear in the public marketplace.

**Why this priority**: Drafts prevent data loss and allow sellers to work across multiple
sessions. This is foundational to listing creation.

**Independent Test**: A seller can save an incomplete listing as a draft, log out, log back
in, resume editing the draft, and publish it once all mandatory fields are complete.

**Acceptance Scenarios**:

1. **Given** a seller has partially filled a listing form, **When** they click "Save Draft",
   **Then** the listing is saved privately and does not appear in the public marketplace.
2. **Given** a seller has a saved draft, **When** they return to their dashboard,
   **Then** the draft appears under "My Drafts" and can be resumed for editing.
3. **Given** a seller completes all mandatory fields on a draft, **When** they publish it,
   **Then** the listing transitions to published status and appears in the marketplace.
4. **Given** a draft listing exists, **When** any other user or guest visits the site,
   **Then** the draft is not visible in browse, search, or any public listing view.

---

### User Story 3 - Buyer Browses Marketplace Listings (Priority: P1)

Any visitor (authenticated or not) browses the marketplace and sees available listings.
They can filter by listing type, condition, or price range. Each listing card shows key
details: sale post number, fragrance name, brand, type, size, condition, price in PKR,
and whether the seller is verified.

**Why this priority**: Browsing is the primary discovery path. Without it, the marketplace
has no visible value to buyers.

**Independent Test**: An unauthenticated visitor can open the marketplace, apply a filter
for listing type "Decant/Split", and see only matching listings with all key fields shown.

**Acceptance Scenarios**:

1. **Given** a visitor opens the marketplace, **When** the page loads, **Then** they see
   published listings ordered by most recent first, each showing sale post number, fragrance
   name, brand, type, size, condition, price in PKR, and seller verified badge if applicable.
2. **Given** a visitor applies a type filter (e.g., "ISO"), **When** applied, **Then** only
   listings of that type are shown.
3. **Given** a visitor applies a price range filter, **When** applied, **Then** only listings
   within that PKR range are displayed.
4. **Given** no listings match the applied filters, **When** results render, **Then** a clear
   "no listings found" message is shown with a prompt to adjust filters.
5. **Given** a visitor clicks a listing card, **When** the detail page loads, **Then** all
   listing fields are shown, photos are viewable, and the off-platform payment disclaimer
   is prominently displayed.
6. **Given** a logged-in member (not the listing owner) views a listing detail page,
   **When** the page loads, **Then** a "Message Seller" button is visible. Clicking it
   initiates or opens a conversation about this listing per feature 006.
7. **Given** the listing owner views their own listing, **When** the page loads, **Then**
   the "Message Seller" button is NOT shown.

---

### User Story 4 - Buyer Searches Listings by Keyword (Priority: P2)

A buyer knows the fragrance they want and types it into the search bar. Results show
matching listings across all types, ordered by relevance and recency.

**Why this priority**: Search serves motivated buyers who know what they want. Browsing
(P1) must work first; search adds targeted discovery on top.

**Independent Test**: A user searching "Aventus" sees all published listings with "Aventus"
in the fragrance name or brand, across all listing types.

**Acceptance Scenarios**:

1. **Given** a user enters a keyword in the search bar, **When** they submit, **Then** all
   published listings matching that keyword in fragrance name or brand name are returned,
   ordered by most recent first.
2. **Given** search returns results, **When** displayed, **Then** each result shows sale
   post number, fragrance name, brand, type, price, and condition.
3. **Given** a search term matches no listings, **When** results show, **Then** a "no
   results found" message is displayed with a suggestion to browse all listings.
4. **Given** a search is performed, **When** results load, **Then** draft and sold listings
   are never included regardless of keyword match.

---

### User Story 5 - Seller Manages Their Listings (Priority: P2)

A seller can view all their own listings (published and drafts), edit a published listing,
mark a listing as sold, or delete a listing.

**Why this priority**: Sellers need inventory control. Sold items staying listed causes
buyer confusion and erodes trust.

**Independent Test**: A seller marks a published listing as "Sold" and it disappears from
public browse and search results, but remains visible in the seller's listing history.

**Acceptance Scenarios**:

1. **Given** a seller visits their dashboard, **When** they view "My Listings", **Then**
   they see all published listings and drafts with their current status.
2. **Given** a seller marks a listing as "Sold", **When** confirmed, **Then** the listing
   is removed from public browse and search and marked "Sold" in their history.
3. **Given** a seller edits a published listing (e.g., updates price), **When** saved,
   **Then** the update is immediately visible on the public listing page. The sale post
   number MUST NOT change on edit.
4. **Given** a seller deletes a listing, **When** confirmed, **Then** the listing is
   removed from all public views and from the seller's dashboard.

---

### Edge Cases

- If a seller's verified badge is revoked after they have active listings, their existing
  published listings remain visible but they cannot create new listings until re-verified.
- If a photo upload exceeds the allowed file size, the system rejects it with a message
  indicating the maximum allowed size.
- Two sellers may list the same fragrance; sale post numbers distinguish each uniquely.
- Reported or suspected impression listings are handled by the Moderation module (spec 005);
  Admin removal of a listing sets its status to "Removed" (spec 008 FR-009), hiding it from
  all public views while retaining it for audit. This spec covers creation, browse, search,
  and seller management only.
- Auction listings require an additional mandatory field: auction end date and time. When
  the end date/time is reached, the listing automatically transitions to "Expired" status,
  is removed from public browse and search, and appears in the seller's listing history
  as "Expired". The seller must follow up with the buyer off-platform. No automatic "Sold"
  transition occurs — the seller marks it sold manually if a transaction completes.
- ISO listings represent what a buyer is seeking; price represents the buyer's budget.
- Swap listings: price represents any cash component of the swap. Sellers enter the cash
  amount or zero if none; the field must still be filled.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST auto-generate a unique sale post number for every listing at
  creation time in the format `PFC-XXXXX` (PFC prefix followed by a zero-padded sequential
  integer, e.g., `PFC-01042`). Users MUST NOT be able to set, edit, or reuse sale post
  numbers. The zero-padding width is a plan-stage decision (5 digits recommended).
- **FR-002**: System MUST support five listing types: Full Bottle, Decant/Split, ISO
  (In Search Of), Swap, and Auction.
- **FR-003**: System MUST enforce all mandatory fields before a listing can be published:
  fragrance name, brand, listing type, size in ml, condition, price in PKR (non-zero),
  at least one photo (minimum 1, maximum 5), and delivery details.
- **FR-004**: Auction-type listings MUST additionally require an auction end date and time.
  When the end date/time is reached, the system MUST automatically transition the listing
  to "Expired" status and remove it from all public browse and search views. The listing
  MUST remain visible in the seller's listing history as "Expired". The seller must
  manually mark it "Sold" if a transaction completes off-platform.
- **FR-005**: System MUST save any listing with missing mandatory fields as a draft;
  drafts MUST NOT appear in public browse or search.
- **FR-006**: System MUST prevent impression/expression listings through two complementary
  mechanisms: (1) "Impression" and "Expression" MUST NOT be selectable values anywhere in
  the listing form (not in listing type, brand, or any category field); (2) the seller MUST
  tick a mandatory declaration checkbox — "I confirm this listing is not an impression or
  expression" — before the publish action is enabled. A listing MUST NOT be publishable
  if the checkbox is unticked.
- **FR-007**: System MUST reject any listing with a zero or missing price, with one
  exception: Swap-type listings MAY have `price_pkr = 0` to represent a no-cash-component
  swap. All other listing types (Full Bottle, Decant/Split, ISO, Auction) MUST have a
  non-zero price.
- **FR-008**: Only users with the Verified Seller role MUST be permitted to create listings,
  with one explicit exception: ISO-type listings MAY be created and published by any
  authenticated Member regardless of role. Sellers may also post ISOs (acting as buyers).
  Unauthenticated users MUST be blocked from the create listing flow for all types.
- **FR-009**: Every published listing detail page MUST display a prominent off-platform
  payment disclaimer stating that PFC does not process or guarantee payments. This requirement
  applies to v1 only; it will be revised when on-platform payment processing is introduced
  in a future phase (Stripe, JazzCash, PayFast, or equivalent).
- **FR-010**: Unauthenticated visitors and authenticated members MUST be able to browse
  and search all published listings without restriction.
- **FR-011**: Marketplace browse MUST support filtering by: listing type, condition, price
  range (min/max in PKR), and seller verified status.
- **FR-012**: Marketplace search MUST match keywords against fragrance name and brand name
  across all published listings.
- **FR-013**: Published listings MUST be displayed in reverse chronological order (newest
  first) by default in both browse and search.
- **FR-014**: A seller MUST be able to mark their listing as "Sold", removing it from
  public view while retaining it in their listing history. Marking a listing as Sold MUST
  also automatically increment the seller's transaction count (per spec 003 FR-019).
- **FR-015**: A seller MUST be able to edit a published listing; the sale post number MUST
  remain unchanged after any edit.
- **FR-016**: A seller MUST be able to delete a listing, removing it from all public views.
- **FR-017**: The listing data model MUST include transaction-ready fields in an
  inactive/nullable state to support future commission tracking and on-platform payment
  processing without schema migration: commission rate, commission status, transaction value,
  payment provider, and payment status. These fields MUST have no UI exposure in v1.
- **FR-018**: Every published listing detail page MUST display a "Message Seller" button
  visible to any logged-in member who is not the listing owner. Unauthenticated visitors
  clicking it MUST be redirected to log in. The listing owner MUST NOT see this button on
  their own listings. The full messaging behaviour is owned by feature 006
  (`specs/006-buyer-seller-messaging/spec.md`); this requirement covers CTA presence only.
- **FR-019**: When a listing transitions to sold, expired, deleted, or removed status, any
  active conversation threads referencing that listing MUST reflect the status change — the
  listing reference in affected threads displays as "Listing no longer available". This is a
  data-event contract with features 006 and 008; no UI change is required on the listing
  page itself.
- **FR-020**: Every published listing detail page MUST display a "Leave a Review" section
  visible to any logged-in member who is not the listing owner. Unauthenticated visitors
  clicking it MUST be redirected to log in. The listing owner MUST NOT see this CTA on their
  own listings. The full review behaviour (star rating, written comment, proof image
  requirement, one-per-listing limit, editing) is owned by spec 003
  (`specs/003-seller-verification/spec.md`); this requirement covers CTA placement only.

### Key Entities

- **Listing**: Core marketplace record. Full field definitions are owned by
  `specs/008-listing-schema/spec.md`. Key attributes for marketplace behaviour: sale post
  number (system-generated, immutable, format `PFC-XXXXX`), fragrance name, brand, listing
  type, size in ml, condition, price in PKR, delivery details, status (draft / published /
  sold / expired / deleted), seller reference, creation date, last updated date, auction
  end date/time (Auction type only), quantity available (Decant/Split type; auto-transitions
  to Sold when decremented to 0), commission rate (nullable, inactive), commission status
  (nullable, inactive), transaction value (nullable, inactive), payment provider (nullable,
  inactive), payment status (nullable, inactive).
- **Photo**: Image attached to a listing. Attributes: listing reference, file reference,
  display order (primary photo shown first), upload date. Maximum 5 photos per listing;
  minimum 1 required for publication.
- **ListingFilter**: Represents a browse/search query. Attributes: keyword, type filter,
  condition filter, price range (min/max), verified seller filter, sort order.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A verified seller can complete a full listing creation — from opening the
  form to seeing it live in the marketplace — in under 5 minutes.
- **SC-002**: 100% of published listing detail pages display the off-platform payment
  disclaimer.
- **SC-003**: Zero impression/expression listings appear in the public marketplace.
- **SC-004**: Zero listings with a missing mandatory field are accessible in public browse
  or search.
- **SC-005**: Browse and search pages return results in under 2 seconds for a marketplace
  of up to 5,000 listings.
- **SC-006**: A seller marking a listing as "Sold" results in its removal from public
  browse and search within 5 seconds.
- **SC-007**: Sale post numbers are globally unique — no two listings share the same number.
- **SC-008**: 100% of draft listings are invisible to all users except the listing's creator.

## Assumptions

- Condition is a confirmed fixed set of five values: New, Like New, Excellent, Good, Fair.
  These are locked — the plan stage may add display descriptions or tooltips but the values
  themselves do not change.
- Delivery details is a free-text field at v1; structured delivery options are a future
  enhancement.
- Photo upload count: minimum 1, maximum 5 per listing. File size limit and accepted
  formats remain technical decisions for the plan stage.
- The impression/expression ban is enforced via two mechanisms: (1) impression/expression
  options are excluded from all form fields, and (2) a mandatory declaration checkbox must
  be ticked before publishing. Admin moderation remains the backstop for listings that
  slip through. Automated detection is a future enhancement.
- Additional listing fields (e.g., fragrance notes, family, hashtags) are explicitly out
  of scope for this spec but the data model must not preclude them.
- Decant/Split listings support a `quantity_available` field (positive integer ≥ 1). The
  seller manually decrements this as units sell off-platform. When quantity reaches 0, the
  listing auto-transitions to Sold. No "partially sold" status is introduced. Full field
  definition is in `specs/008-listing-schema/spec.md` FR-015.
- Swap listings with no cash component enter PKR 0 in the price field; zero is allowed
  only for Swap type — all other types require a non-zero price.
- Transaction-ready fields (FR-017) — commission rate, commission status, transaction value,
  payment provider, payment status — are all nullable with no UI exposure in v1. They exist
  to allow future introduction of commission tracking and on-platform payment gateways
  (Stripe, JazzCash, PayFast, or equivalent) without breaking schema migrations.
- Feature dependency: `006-buyer-seller-messaging` depends on listing status events from
  this feature. When a listing is sold, expired, or deleted, the messaging feature must be
  notified so conversation listing references display correctly. This event contract must
  be defined at the plan stage for both features.
