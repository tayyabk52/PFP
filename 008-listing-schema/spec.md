# Feature Specification: Listing Schema & Data Model

**Feature Branch**: `008-listing-schema`
**Created**: 2026-03-18
**Status**: Draft
**Input**: Define a detailed, future-proof listing schema ensuring every listing field is
captured completely, all field rules are unambiguous, and the data model can accommodate
future enhancements without structural rework.

**Scope**: This spec defines the complete data structure of a Listing record — every field,
its constraints, validation rules, lifecycle states, and extensibility hooks. It does NOT
define marketplace browse/search functionality (see `specs/002-marketplace-listings/spec.md`),
messaging (see `specs/006-buyer-seller-messaging/spec.md`), or local pickup (see
`specs/007-local-pickup-maps/spec.md`). Those features reference and extend this schema.

**Related features**:
- `002-marketplace-listings` — defines the create/browse/search/manage behaviours that act
  on the Listing entity defined here. Any field added here must be reflected in 002's FR-003
  mandatory field list when activated.
- `006-buyer-seller-messaging` — reads listing status events from this schema. When a listing
  transitions to Sold, Expired, or Deleted, the conversation reference must update.
- `007-local-pickup-maps` — extends the Listing entity with an optional `pickup_location`
  reference defined as a nullable field in this schema.
- `005-moderation-admin` — Admin holds override authority on listing status transitions
  outside the standard lifecycle.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Seller Provides Complete Fragrance Information (Priority: P1)

A verified seller creates a listing and is presented with fields for all information a buyer
needs: fragrance name, brand, listing type, exact size in ml, condition, price, delivery
options, and photos. The form adapts per listing type — Auction shows an end date/time field;
Swap shows cash-component guidance; ISO labels the price field as "Max Budget". The seller
must tick a declaration that the item is not an impression or expression before publishing.

**Why this priority**: Completeness of a listing directly determines buyer confidence.
Missing or ambiguous fields are the primary cause of post-transaction disputes. This is the
supply-side foundation of the entire marketplace.

**Independent Test**: A verified seller can create one of each of the five listing types —
each with all type-appropriate fields — and each record contains the expected field values
when retrieved, including five null future-ready fields and a system-generated sale post
number.

**Acceptance Scenarios**:

1. **Given** a verified seller submits a Full Bottle listing with all mandatory fields,
   **When** the listing is created, **Then** the record contains: sale post number
   (system-generated, immutable), fragrance name, brand, listing type = Full Bottle, size
   in ml, condition, price in PKR (non-zero), delivery details, at least one photo,
   status = Published, seller reference, `created_at`, `published_at`, and
   `impression_declaration_accepted = true`.
2. **Given** a verified seller submits an Auction listing with all mandatory fields including
   a future end date/time, **When** created, **Then** the record contains a non-null
   `auction_end_at` set to the specified future timestamp.
3. **Given** a verified seller creates a Swap listing with no cash component and enters
   PKR 0, **When** submitted, **Then** the listing is accepted and saved with
   `price_pkr = 0`.
4. **Given** a seller submits a non-Swap listing (Full Bottle, Decant, ISO, or Auction)
   with `price_pkr = 0`, **When** validated, **Then** the system rejects it with a message
   that price must be non-zero.
5. **Given** a published listing of any type is retrieved, **When** queried for the five
   future-ready fields (`commission_rate`, `commission_status`, `transaction_value`,
   `payment_provider`, `payment_status`), **Then** all five return null with no error and
   no UI exposure.
6. **Given** a seller attempts to publish without ticking the impression declaration,
   **When** they click Publish, **Then** the system prevents publication and prompts them
   to tick the declaration.

---

### User Story 2 - Buyer Views Complete Listing Details (Priority: P1)

A buyer viewing a listing detail page can see every piece of information about the item:
fragrance name, brand, listing type, size in ml, condition, price, delivery options, all
uploaded photos with the primary photo shown first, the sale post number, and the seller's
verified status. For Auction listings, remaining time until close is visible. ISO listings
are clearly labelled as "In Search Of" so buyers understand the poster is seeking to purchase.

**Why this priority**: Buyers need sufficient information to make a confident purchase
decision without messaging the seller for basics. An information-complete listing is the
primary quality bar of the marketplace.

**Independent Test**: A buyer can open a listing detail page for each listing type and find
— without additional interaction — fragrance name, brand, type, size, condition, price,
delivery details, photos (primary first), sale post number, and seller verified status.

**Acceptance Scenarios**:

1. **Given** a published listing of any type, **When** a buyer views it, **Then** all fields
   defined for that listing type are visible and clearly labelled on the detail page.
2. **Given** an Auction listing with a future `auction_end_at`, **When** a buyer views it,
   **Then** the remaining time until the auction closes is displayed.
3. **Given** an ISO listing, **When** any user views it, **Then** it is clearly labelled as
   "In Search Of" and the price is labelled "Max Budget (PKR)" rather than "Price".
4. **Given** a listing with 3 photos, **When** a buyer views it, **Then** the photo with
   `display_order = 1` is shown as the primary/cover image and all 3 photos are accessible.
5. **Given** a listing with `display_order = 1` photo reordered by the seller after
   publication, **When** any user views the listing, **Then** the new `display_order = 1`
   photo is shown as the cover without requiring the listing to be republished.

---

### User Story 3 - Platform Extends Listing Fields Without Breaking Existing Records (Priority: P2)

As PFC evolves, new listing attributes (fragrance family, fragrance notes, hashtags, vintage
year, condition notes, decant quantity) can be added to the listing form and record without
invalidating any existing published listings. Older listing records display new fields as
empty or "Not specified" rather than causing errors.

**Why this priority**: Future-proofing the schema protects years of listing history. Forcing
sellers to re-enter listings when new fields are added would destroy community goodwill and
historic data.

**Independent Test**: A listing created today is still valid, browsable, and correctly
displayed after the `fragrance_family` field is introduced — the field shows as absent or
"Not specified" on the old record without any error.

**Acceptance Scenarios**:

1. **Given** an existing listing record without `fragrance_family`, **When** the platform
   introduces that field, **Then** the listing displays "Not specified" for that field and
   does NOT require re-submission.
2. **Given** a seller leaves an optional extensibility field empty when creating a new
   listing after that field is activated, **When** the listing is submitted, **Then** it
   publishes successfully with that field as null.
3. **Given** any extensibility field defined in FR-016 is queried on a v1 listing record,
   **Then** the record returns null rather than an error.

---

### User Story 4 - Commission and Payment Fields Activate Without Migration (Priority: P2)

When PFC introduces commission tracking or on-platform payment processing, activation
requires no structural changes to existing listing records. The required fields already
exist in every listing record as null values; they simply become active and UI-visible.
No listing data is lost or invalidated.

**Why this priority**: This is the Transaction-Ready Architecture principle from the PFC
Constitution (Principle IV). Retrofitting commission and payment fields into thousands of
existing listings after launch carries significant rework and data-loss risk.

**Independent Test**: Every listing record — regardless of creation date — can be queried for
all five future-ready fields and receives null without an error.

**Acceptance Scenarios**:

1. **Given** any listing created in v1, **When** `commission_rate` is set on that listing
   during commission activation, **Then** no schema migration is required and the field
   accepts the value correctly.
2. **Given** any listing created in v1, **When** `payment_provider` is set to an active
   gateway (e.g., JazzCash), **Then** no schema migration is required and the value persists.
3. **Given** a v1 listing record, **When** all five future-ready fields are queried,
   **Then** all return null with no error.

---

### Edge Cases

- An Auction listing's `auction_end_at` cannot be in the past at publish time; submitting a
  past end date/time must be rejected with a clear message.
- A Swap listing may have `price_pkr = 0` for a no-cash-component swap; zero is invalid for
  all other listing types.
- An ISO listing's price represents the buyer's maximum budget, not a seller's asking price.
  The price field label must reflect this in the creation form and on the listing detail page.
- If a seller's verified badge is revoked after publishing, the existing listing records
  remain published but the seller's verified badge is not shown on those listings. The seller
  cannot create new listings. The listing schema must support a live verified-status check at
  display time, not only at creation time.
- Photo display order is significant: `display_order = 1` is the cover image on listing
  cards and search results. Reordering photos must persist the new order without creating
  new listing records or republishing the listing.
- For Decant/Split and Full Bottle listings, `quantity_available` must always be a positive
  integer at publication time (minimum 1). Setting it to 0 triggers auto-transition to Sold.
  Setting it to a negative value must be rejected. Sellers may increase quantity after
  publication (e.g., they split more from the bottle, or locate additional sealed bottles);
  no upper limit is enforced at v1.
- Two sellers may list the same fragrance simultaneously; uniqueness exists only at the sale
  post number level.
- A Draft listing must not expose any field value in public browse or search, regardless of
  how many fields are populated.
- `last_updated_at` is updated on every edit. `created_at` and `published_at` are immutable
  once set.
- Deleted listings retain their sale post numbers permanently; a deleted listing's sale post
  number is never reused or reassigned. The same applies to Removed listings.
- When a listing reaches Sold, Expired, Deleted, or Removed status, any active conversation
  threads referencing that listing must surface the listing as "Listing no longer available"
  per `specs/006-buyer-seller-messaging/spec.md`. This spec defines the status fields that
  trigger that event; the messaging behaviour is owned by feature 006.
- When Admin sets a listing to Removed, the listing is hidden from all public browse, search,
  and listing-detail views. The seller sees it in their listing history as "Removed by Admin".
  The record is retained in Admin view for audit. The moderation audit log (spec 005) holds
  the removing Admin's identity, timestamp, and internal reason — these are not stored on the
  listing record itself.

---

## Requirements *(mandatory)*

### Functional Requirements

#### Core Record Fields

- **FR-001**: The system MUST auto-generate a unique sale post number for every listing at
  creation time. The sale post number MUST be immutable after creation — it MUST NOT change
  on edit, status transition, or any other event. Users MUST NOT be able to set or override
  this value. The format is a `PFC-` prefix followed by a zero-padded sequential integer
  (e.g., `PFC-00001`, `PFC-01042`). This format is human-readable and instantly recognisable
  when sellers reference their posts in the Facebook group. The zero-padding width is a
  plan-stage decision (5 digits recommended for up to 99,999 listings).

- **FR-002**: Every listing record MUST store the following core fields: sale post number,
  fragrance name, brand, listing type, size in ml, condition, price in PKR, delivery details,
  status, seller reference, `impression_declaration_accepted`, `created_at`,
  `last_updated_at`.

- **FR-003**: The listing MUST support exactly five listing types: Full Bottle, Decant/Split,
  ISO (In Search Of), Swap, and Auction. No other types are valid in v1.

- **FR-004**: Condition MUST be stored as one of five enumerated values: New, Like New,
  Excellent, Good, or Fair. An optional `condition_notes` free-text field (nullable) MUST
  also exist on the record for future activation; it has no UI in v1.

- **FR-005**: Price MUST be stored in PKR as a non-negative integer.
  - Zero price (`price_pkr = 0`) is valid ONLY for Swap-type listings.
  - All other listing types (Full Bottle, Decant/Split, ISO, Auction) MUST reject a zero
    or missing price at submission.
  - For ISO listings, the price field stores the buyer's maximum budget; the label "Max
    Budget (PKR)" MUST be used wherever this field is displayed or labelled for ISO listings.

- **FR-006**: Delivery details MUST be stored as free text in v1. The field is mandatory for
  publication. A structured delivery options field (e.g., courier name, in-hand, local
  pickup) is a future enhancement; the schema MUST NOT preclude adding structure later.

#### Photos

- **FR-007**: Each listing MUST support between 1 and 5 photos. A listing MUST NOT be
  published with zero photos. Each photo record MUST store: listing reference, file
  reference, `display_order` (positive integer, unique per listing), and `uploaded_at`
  timestamp.

- **FR-008**: The photo with `display_order = 1` is the primary/cover image and MUST be
  used as the thumbnail in listing cards, search results, and any listing preview. The
  seller MUST be able to reorder photos post-publication by updating `display_order` values
  without republishing or changing the listing's `last_updated_at` with a status event.

#### Status Lifecycle

- **FR-009**: Listing status MUST be one of six enumerated values: Draft, Published, Sold,
  Expired, Deleted, Removed. The ONLY valid status transitions are:
  - Draft → Published (seller action; requires all mandatory fields complete AND
    `impression_declaration_accepted = true`)
  - Published → Sold (seller action; OR system action when a Decant/Split or Full Bottle
    listing's `quantity_available` is decremented to 0)
  - Published → Expired (system action only; valid for Auction type when `auction_end_at`
    is reached)
  - Published → Deleted (seller action)
  - Draft → Deleted (seller action)
  - Published → Removed (Admin action only; via moderation tooling in
    `specs/005-moderation-admin/spec.md`; listing is hidden from all public views but
    retained in Admin view and the seller's listing history as "Removed by Admin")
  - Any other transition MUST be rejected at the application layer.

- **FR-010**: The listing record MUST store the following lifecycle timestamps:
  - `created_at` — set at record creation; immutable thereafter.
  - `published_at` — set when the listing first transitions to Published; immutable
    thereafter (does NOT update on re-publish if a future draft → published → draft →
    published flow is supported).
  - `last_updated_at` — updated on every field edit.
  - `sold_at` — set when status transitions to Sold; null otherwise.
  - `expired_at` — set when status transitions to Expired; null otherwise.
  - `deleted_at` — set when status transitions to Deleted; null otherwise (soft-delete;
    record is retained for audit).
  - `removed_at` — set when status transitions to Removed (Admin action); null otherwise.
    The removing Admin's reference and internal reason are stored in the moderation audit
    log (spec 005), not on the listing record itself.

#### Auction-Specific

- **FR-011**: Auction-type listings MUST store an `auction_end_at` timestamp field. This
  field is mandatory for Auction listings and MUST be null for all other listing types.
  At publish time, `auction_end_at` MUST be a future date/time; past values MUST be
  rejected. When the platform clock reaches `auction_end_at`, the system MUST automatically
  transition the listing to Expired status and set `expired_at`.

#### Impression and Expression Ban

- **FR-012**: "Impression" and "Expression" MUST NOT appear as selectable values in any
  listing form field, including brand, fragrance name autocomplete, or any future category
  field. These terms MUST be on a system blocklist applied at the form and validation layers.

- **FR-013**: The `impression_declaration_accepted` field MUST be stored on every listing
  record (boolean). Any listing transitioning to Published status MUST have this field set
  to `true`. The system MUST prevent the Draft → Published transition if this field is
  `false` or absent.

#### Future-Ready Fields (Transaction-Ready Architecture)

- **FR-014**: Every listing record MUST store the following five fields. All are nullable
  with no UI exposure in v1. Their presence is mandatory in the schema from day one per
  PFC Constitution Principle IV:
  - `commission_rate` — the commission percentage to be applied when commission is activated
    (numeric, nullable, e.g., 5.0 for 5%).
  - `commission_status` — tracks commission state when active (enumerable, nullable; future
    values: Pending, Calculated, Collected, Waived).
  - `transaction_value` — the agreed sale price recorded when a transaction is confirmed
    off-platform or on-platform (numeric in PKR, nullable).
  - `payment_provider` — the payment gateway identifier if on-platform payment is used
    (text, nullable; e.g., "jazzcash", "easypaisa", "stripe").
  - `payment_status` — the payment gateway transaction state (enumerable, nullable; future
    values: Pending, Completed, Failed, Refunded).

#### Extensibility Fields (Schema-Reserved, v1 Inactive)

- **FR-015**: The listing schema MUST reserve the following fields as nullable with no UI
  in v1. Activating any of these fields MUST require only an application-layer change (form
  + display), not a schema migration:
  - `fragrance_family` — fragrance classification (enumerable; initial values: Oriental,
    Woody, Floral, Fresh, Fougère, Chypre, Gourmand, Aquatic).
  - `fragrance_notes` — structured or free-text top/heart/base notes (text or array,
    nullable).
  - `hashtags` — user-defined searchable tags (array of strings, nullable; moderation
    blocklist required at activation time).
  - `vintage_year` — year the fragrance was produced or released (4-digit integer, nullable).
  - `condition_notes` — optional free text elaborating on the condition entry (text,
    nullable; e.g., "box missing, cap present, no scratches").
  - `quantity_available` — number of units available; seller-editable for Decant/Split and
    Full Bottle listing types only (positive integer, default 1 for all types). For
    Decant/Split listings, a seller may offer multiple identical decants from the same bottle
    as a single listing (e.g., "10 × 5 ml available"). For Full Bottle listings, a seller
    may have multiple identical sealed bottles available (e.g., "3 bottles of the same
    fragrance"). The seller manually decrements this value as units sell off-platform. When
    a seller sets `quantity_available` to 0, the system MUST auto-transition the listing to
    Sold status. The listing remains in Published status until quantity reaches 0 — no
    "partially sold" status is introduced; the listing is simply Published with a lower
    quantity count. Swap, ISO, and Auction listing types MUST have `quantity_available = 1`
    and the field MUST NOT be editable by the seller for these types. Auction listings
    MUST always have `quantity_available = 1`; multi-unit auctions are not supported at v1.

#### Cross-Feature Schema Contracts

- **FR-016**: The listing schema MUST include an optional `pickup_location` reference field
  (nullable). Full pickup location behaviour is specified in
  `specs/007-local-pickup-maps/spec.md`. Any listing is valid with or without a pickup
  location reference.

- **FR-017**: When a listing's status transitions to Sold, Expired, Deleted, or Removed,
  the system MUST emit an event or update a field that `specs/006-buyer-seller-messaging/spec.md`
  can observe to mark the listing reference in affected conversation threads as
  "Listing no longer available". The exact event mechanism (field flag vs. event bus) is a
  plan-stage decision; this spec defines the contract that the state change must be
  observable by feature 006.

---

### Key Entities

- **Listing**: The central marketplace record. Contains all fields defined in FR-002 through
  FR-017. Uniquely identified by a system-generated sale post number. Related to: one Seller
  (via `seller_id`), one to five Photos (ordered by `display_order`), optionally one pickup
  location reference.

- **Photo**: Image attached to a Listing. Attributes: listing reference (`listing_id`), file
  reference (`file_id` or URL), `display_order` (positive integer, unique per listing),
  `uploaded_at` timestamp. Constraints: maximum 5 per listing; minimum 1 required for
  publication; `display_order = 1` is the cover image.

- **ListingType** *(enumeration)*: Full Bottle | Decant/Split | ISO | Swap | Auction

- **ListingCondition** *(enumeration)*: New | Like New | Excellent | Good | Fair

- **ListingStatus** *(enumeration)*: Draft | Published | Sold | Expired | Deleted | Removed

- **FragranceFamily** *(extensibility enumeration, v1 inactive)*:
  Oriental | Woody | Floral | Fresh | Fougère | Chypre | Gourmand | Aquatic

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every listing record — regardless of type — can be retrieved and all defined
  fields returned without error, including all five future-ready fields (as null in v1).

- **SC-002**: Zero listings reach Published status without
  `impression_declaration_accepted = true`.

- **SC-003**: Zero Swap-type listings are rejected for `price_pkr = 0`; zero non-Swap
  listings are accepted with `price_pkr = 0`.

- **SC-004**: 100% of Auction listings have a non-null `auction_end_at`; 100% of
  non-Auction listings have `auction_end_at = null`.

- **SC-005**: 100% of listing card and search-result thumbnails display the photo with
  `display_order = 1` as the cover image.

- **SC-006**: When commission or payment fields are activated in a future phase, zero
  existing listing records require structural migration — the fields exist on 100% of records
  from creation.

- **SC-007**: Each extensibility field defined in FR-015 can be activated (form added +
  displayed) with no schema migration on the Listing entity.

- **SC-008**: Status transitions outside the valid set in FR-009 are rejected 100% of the
  time at the application layer (Admin-initiated Removed transitions are the only permitted
  override path).

- **SC-013**: A listing set to Removed by Admin is invisible in 100% of public browse,
  search, and detail-page requests within 5 seconds of the Admin action.

- **SC-009**: Sale post numbers are globally unique across 100% of listing records, including
  soft-deleted records. No sale post number is ever reused.

- **SC-010**: Every lifecycle timestamp (`created_at`, `published_at`, `last_updated_at`,
  `sold_at`, `expired_at`, `deleted_at`) is accurately set and immutable where specified —
  zero records have `created_at` or `published_at` overwritten after first set.

- **SC-011**: When a Decant/Split or Full Bottle listing's `quantity_available` is
  decremented to 0, the listing automatically transitions to Sold status — 100% of the
  time, with no manual seller action required.

- **SC-012**: Sale post numbers follow the `PFC-XXXXX` format on 100% of listing records;
  zero records carry a bare integer or non-PFC-prefixed sale post number.

---

## Assumptions

- Condition enum values — New, Like New, Excellent, Good, Fair — are confirmed for v1. The
  plan stage may add display descriptions or tooltips but the five values are fixed.
- Photo file formats accepted are JPEG, PNG, and WEBP. Maximum file size per photo (e.g.,
  5 MB) is a plan-stage technical decision and does not affect this schema spec.
- Delivery details is free text in v1. Structured delivery options are a future enhancement;
  `007-local-pickup-maps` covers one structured delivery sub-type.
- The `fragrance_family` enumeration (FR-015) may expand at activation time. The values
  listed are a recommended starting set, not a locked constraint.
- `hashtags` will require a moderation blocklist at activation time to prevent abuse. This
  is an activation-phase concern and not a v1 constraint.
- Deleted listings use soft-delete: the record is retained for audit, with `deleted_at` set.
  Hard-delete is not permitted. Sale post numbers on deleted listings are permanently retired.
- Seller verified-status is checked at display time from the Seller entity, not stored on
  the Listing record. If a seller's badge is revoked, all their listing cards automatically
  stop showing the verified badge without updating individual listing records.
- Admin status-transition overrides are fully defined in `specs/005-moderation-admin/spec.md`.
  This spec only establishes that such overrides exist and are the only mechanism for
  transitions outside the standard lifecycle.
- `quantity_available` default value is 1 for all listing types. Seller-editable for
  Decant/Split and Full Bottle; fixed at 1 and non-editable for Swap, ISO, and Auction.
- The event contract with `006-buyer-seller-messaging` (FR-017) — specifically whether to
  use a status field, a dedicated flag, or an event bus — is a plan-stage decision. This
  spec defines only that the state change must be observable.
