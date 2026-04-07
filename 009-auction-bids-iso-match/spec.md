# Feature Specification: Auction Bidding, ISO Matching & Multi-Quantity

**Feature Branch**: `009-auction-bids-iso-match`
**Created**: 2026-03-18
**Status**: Draft
**Input**: Auction bidding system (buyers place visible bids, seller picks winner after
close), ISO matching (suggested sellers shown to ISO poster and vice versa, any member can
post ISO), and Full Bottle multi-quantity support.

**Scope**: This spec defines three targeted enhancements to the listing model defined in
`specs/008-listing-schema/spec.md` and the marketplace behaviours in
`specs/002-marketplace-listings/spec.md`:
1. **Auction Bidding** — a public, visible bidding layer on Auction-type listings where
   buyers place bids, all bids are visible during and after the auction period, and the
   seller chooses their preferred bidder after close.
2. **ISO Matching** — automatic two-way discovery between ISO listings and matching
   published listings, plus opening ISO creation to all authenticated members (not just
   Verified Sellers).
3. **Full Bottle Multi-Quantity** — sellers with multiple identical bottles can list
   them under a single listing with a decrementable quantity counter.

**Related features**:
- `008-listing-schema` — This spec extends the Listing entity and adds a new Bid entity.
  Spec 008 FR-009 (status transitions), FR-010 (timestamps), FR-015 (extensibility fields),
  and the `ListingStatus` enum all require updates per this spec.
- `002-marketplace-listings` — FR-008 (Seller-only access) requires an ISO exception per
  this spec. Browse and search behaviour is unchanged.
- `006-buyer-seller-messaging` — Auction close contact flow uses existing messaging;
  no new messaging behaviour is introduced.
- `003-seller-verification` — Transaction count logic (spec 003 FR-019) is unchanged;
  it still increments on Sold regardless of whether the listing was an auction or not.

---

## Clarifications

### Session 2026-03-18

- Q: Are bidder identities (display names) visible publicly on auction listings alongside
  their bid amounts? → A: Yes — display name, bid amount, and bid timestamp are all publicly
  visible. This aligns with PFC's transparency-first principle and builds community trust.
- Q: Can a seller pick any bidder (not necessarily the highest), or must they take the
  highest bid? → A: Seller chooses freely — they are shown all bids ranked highest to
  lowest and contact their preferred bidder via messaging. No mandatory winner selection.
  This is consistent with off-platform payments and gives sellers flexibility.
- Q: What is the minimum bid increment — fixed or seller-configurable? → A: System-enforced
  minimum of PKR 500 per increment. Sellers cannot change this. First bid must meet or
  exceed the starting price; each subsequent bid must exceed the current highest by at
  least PKR 500.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Buyer Places a Bid on an Active Auction (Priority: P1)

A buyer browsing an Auction listing wants to participate. They can see the current highest
bid, the list of all previous bids with each bidder's display name and timestamp, and
the time remaining. They place a bid that exceeds the current highest by at least PKR 500.
Their bid immediately appears in the public bid list. They cannot retract it.

**Why this priority**: Bidding is the core value of the entire auction enhancement. Without
it, Auction listings remain static price listings with no interactive discovery mechanism.

**Independent Test**: A logged-in member can open an active Auction listing, see the live
bid list, place a valid bid, and immediately see their bid appear at the top of the list
with their display name, amount, and timestamp — visible to any visitor without refresh.

**Acceptance Scenarios**:

1. **Given** a logged-in member views an active Auction listing, **When** the page loads,
   **Then** they see: the starting price, current highest bid amount, total bid count, time
   remaining until auction close, and a full public bid list showing each bid's display
   name, amount, and timestamp in descending order (highest first).
2. **Given** no bids have been placed yet, **When** a member views the auction, **Then**
   the bid list shows "No bids yet" and the minimum first bid is shown as equal to the
   starting price.
3. **Given** a member enters a bid amount that meets or exceeds the starting price (if
   first bid) or exceeds the current highest bid by at least PKR 500, **When** they
   confirm the bid, **Then** the bid is recorded, appears immediately at the top of the
   public bid list, and the current highest bid display updates.
4. **Given** a member enters a bid below the minimum required amount, **When** they
   attempt to confirm, **Then** the system rejects the bid and displays the minimum
   valid amount.
5. **Given** a member views their own Auction listing, **When** the page loads, **Then**
   the bid button is NOT shown — listing owners cannot bid on their own auctions.
6. **Given** an unauthenticated visitor views an Auction listing, **When** they attempt
   to place a bid, **Then** they are prompted to log in. The public bid list and current
   highest bid remain visible without login.

---

### User Story 2 - Auction Closes, Result Page Published, and Bidders Notified (Priority: P1)

The auction end date/time arrives. The system automatically transitions the listing to
Expired and immediately transforms its public page into an Auction Result Page — showing
the full ranked bid list, the seller's optional outcome note, and the final outcome once
the seller marks it Sold. All bidders who participated receive an in-platform notification
linking them directly to the result page, so they know the auction has closed without
having to check manually. After completing the transaction off-platform, the seller marks
the listing as Sold, triggering a second notification to all bidders.

**Why this priority**: The close flow is what gives the bidding system its outcome. Without
it, bids accumulate with no mechanism for the seller to act on them, and bidders are left
with no awareness of whether the auction concluded or who won.

**Independent Test**: When `auction_end_at` passes, the auction transitions to Expired,
the listing page renders as a result page with the full ranked bid list, all bidders
receive an in-platform notification linking to the result page, and the seller can add
an optional outcome note and message any bidder directly from their listing history.

**Acceptance Scenarios**:

1. **Given** an Auction listing's `auction_end_at` is reached, **When** the system
   processes the expiry, **Then** the listing status transitions to Expired, the bid input
   is removed, an "Auction Closed" banner is shown, and the page renders as the Auction
   Result Page: listing details, full ranked bid list (highest to lowest), close timestamp,
   and an empty outcome note section awaiting seller input.
2. **Given** the auction has expired, **When** any user — including previously outbid
   members — attempts to place a new bid, **Then** the system rejects it with "This
   auction has closed."
3. **Given** the auction has expired, **When** the seller views their listing history,
   **Then** they see the ranked bid list (highest to lowest) with each bidder's display
   name, bid amount, and timestamp, plus a "Message" link next to each entry to initiate
   or open a conversation with that bidder via feature 006 (post-auction seller-initiation
   exception — see FR-022), and an "Add Outcome Note" field (optional, free text, max
   200 characters) to record a brief outcome message visible on the public result page.
4. **Given** the seller contacts their chosen bidder and completes the transaction
   off-platform, **When** the seller marks the listing as Sold, **Then** the listing
   transitions to Sold status, the result page updates to show "Sold" status, the full
   bid list remains publicly visible, the seller's transaction count increments, and all
   bidders who placed bids receive a second in-platform notification: "Auction [PFC-XXXXX]
   has been sold."
5. **Given** an Auction listing expires with zero bids, **When** the seller views it,
   **Then** the result page shows "No bids received." The seller can add an outcome note
   and relist by creating a new listing. No bidder notifications are sent (no participants).
6. **Given** an Auction listing transitions to Expired, **When** the system processes
   the close, **Then** every user who placed at least one bid on that listing receives an
   in-platform notification: "Auction [PFC-XXXXX] — [Fragrance Name] has closed. View
   results." The notification links directly to the Auction Result Page.
7. **Given** the seller marks an Auction listing as Sold, **When** the transition is
   saved, **Then** every user who placed at least one bid receives an in-platform
   notification: "Auction [PFC-XXXXX] — [Fragrance Name] has been sold." The notification
   links to the result page. Bidders who already received the close notification now see
   this as a second, distinct notification.

---

### User Story 3 - All Visitors See Live Bid Activity (Priority: P1)

Anyone — authenticated or not — can visit an active Auction listing and see the complete
live bid history: who bid, how much, and when. The current highest bid and remaining time
are prominently displayed. This transparency creates competitive urgency and community
trust.

**Why this priority**: Bid visibility is what distinguishes PFC's auction from a simple
"send me your best offer" post. Public bids create social proof and competitive pressure.

**Independent Test**: An unauthenticated visitor opens an active Auction listing and sees
the full bid list with display names, amounts, and timestamps without logging in. Refreshing
the page shows new bids if any have been placed.

**Acceptance Scenarios**:

1. **Given** any visitor (authenticated or not) views an active Auction listing, **When**
   the page loads, **Then** the full bid list — display names, amounts, timestamps — is
   visible without requiring login.
2. **Given** a new bid is placed on an Auction listing, **When** any visitor viewing the
   page refreshes (or the page auto-updates), **Then** the new bid appears at the top of
   the bid list and the current highest bid display updates.
3. **Given** an Auction listing with 10+ bids, **When** a visitor views it, **Then** all
   bids are shown (no pagination limit on the bid list in v1) in descending bid-amount
   order, with ties broken by earliest timestamp.

---

### User Story 4 - Any Member Posts an ISO Listing (Priority: P1)

A fragrance buyer (Member role, not yet a Verified Seller) wants to find a specific
fragrance. They create an ISO listing describing what they want, the acceptable size,
their maximum budget, and condition preference. ISO is the only listing type open to
non-Seller accounts. A Verified Seller can also post an ISO when they are acting as
a buyer for a specific fragrance they want.

**Why this priority**: ISOs posted by buyers are the primary use case. If only Verified
Sellers could post ISOs, the feature has limited discovery value — most of the community
looking to buy would be locked out.

**Independent Test**: A logged-in Member (without Seller role) can create and publish an
ISO listing. A Verified Seller can also create an ISO listing. Both appear in the public
marketplace under listing type "ISO".

**Acceptance Scenarios**:

1. **Given** a logged-in Member (non-Seller) navigates to the create listing page,
   **When** the page loads, **Then** only "ISO" is available as a listing type — all other
   types (Full Bottle, Decant/Split, Swap, Auction) remain disabled for non-Sellers.
2. **Given** a logged-in Member fills in an ISO listing (fragrance name, brand, size,
   condition preference, max budget) and ticks the declaration, **When** they publish,
   **Then** the ISO listing is live in the marketplace and appears in the ISO filter.
3. **Given** a Verified Seller opens the create listing form, **When** they select ISO,
   **Then** the form behaviour is identical to a Member's ISO form. All other listing
   types remain available to them as normal.
4. **Given** a non-Seller member attempts to create any listing type other than ISO,
   **When** they attempt to access the creation flow, **Then** they are shown a message
   that only Verified Sellers can create that listing type.

---

### User Story 5 - ISO Poster Sees Matching Seller Listings (Priority: P1)

A member who posted an ISO listing — or any visitor viewing it — can immediately see
"Suggested Listings" on the ISO detail page: published Full Bottle, Decant/Split, Swap,
and Auction listings from verified sellers that match the same fragrance name or brand.
This eliminates the need for the ISO poster to manually search.

**Why this priority**: ISO matching is what makes the ISO feature genuinely useful.
Without it, an ISO poster must manually search for their fragrance; the platform does not
actively connect buyers with sellers.

**Independent Test**: An ISO listing for "Creed Aventus" shows a "Suggested Listings"
section containing all published Full Bottle, Decant/Split, Swap, and Auction listings
with fragrance name or brand matching "Creed Aventus", ordered by relevance.

**Acceptance Scenarios**:

1. **Given** a visitor views an ISO listing, **When** the page loads, **Then** a
   "Suggested Listings" section shows all published non-ISO listings where the fragrance
   name or brand matches the ISO's fragrance name or brand.
2. **Given** the ISO listing's fragrance name matches 5 published listings, **When** the
   suggestions render, **Then** all 5 are shown, each displaying: sale post number,
   listing type, size, condition, price (or "Max Budget" for other ISOs if shown),
   and seller's verified badge if applicable.
3. **Given** no matching published listings exist, **When** the ISO page loads, **Then**
   the "Suggested Listings" section displays "No matching listings found right now."
4. **Given** a visitor clicks a suggested listing, **When** triggered, **Then** they are
   taken to that listing's full detail page.
5. **Given** new matching listings are published after the ISO was created, **When** the
   ISO page is viewed, **Then** the newly published listings appear in the suggestions
   (suggestions are computed at display time, not fixed at ISO creation time).

---

### User Story 6 - Seller Sees Buyers Looking for Their Fragrance (Priority: P2)

A seller viewing their own Full Bottle, Decant/Split, Swap, or Auction listing — or any
visitor viewing it — can see a "Buyers Looking For This" section showing active ISO
listings that match the same fragrance. This gives sellers an immediate signal of demand
and a direct path to contact interested buyers.

**Why this priority**: This is the reciprocal of US5. Together they create a two-way
discovery loop. P2 because it adds seller-side value on top of the buyer-side value
already delivered by US5.

**Independent Test**: A Full Bottle listing for "Tom Ford Oud Wood" shows a "Buyers
Looking For This" section with all active ISO listings for the same fragrance — including
the ISO poster's display name, max budget, and a link to view their ISO.

**Acceptance Scenarios**:

1. **Given** a visitor views a Full Bottle, Decant/Split, Swap, or Auction listing,
   **When** the page loads, **Then** a "Buyers Looking For This" section shows all
   published ISO listings with matching fragrance name or brand.
2. **Given** matching ISO listings exist, **When** displayed, **Then** each entry shows:
   the ISO poster's display name, their max budget (PKR), preferred size, and a link to
   view their ISO listing. The ISO poster's verified seller badge is shown if applicable.
3. **Given** no matching ISO listings exist, **When** the listing page loads, **Then**
   the "Buyers Looking For This" section is hidden entirely (no empty state shown).
4. **Given** a logged-in member clicks "View ISO" on a buyer's entry, **When** they land
   on the ISO listing, **Then** they see the ISO detail page and its "Suggested Listings"
   section. The ISO poster (the buyer) is the one who initiates contact — there is no
   "Message Poster" button on the ISO listing for other parties to cold-contact the poster.
   If the ISO poster is interested in a seller's listing they found via "Suggested Listings",
   they navigate to that listing and use the standard "Message Seller" button.

---

### User Story 7 - Seller Lists Multiple Identical Full Bottles (Priority: P1)

A seller has 3 sealed bottles of the same fragrance in the same condition. Instead of
creating 3 separate listings, they create one Full Bottle listing and set quantity to 3.
As each bottle sells off-platform, they decrement the quantity. When quantity reaches 0,
the listing auto-transitions to Sold.

**Why this priority**: Multi-quantity Full Bottle is a common real-world scenario in
fragrance resale — importers or resellers often carry stock. Forcing 3 separate listings
creates redundant sale post numbers and clutter.

**Independent Test**: A seller creates a Full Bottle listing with quantity = 3. A buyer
contacts them; the seller decrements quantity to 2. The listing remains Published. When
decremented to 0, the listing auto-transitions to Sold.

**Acceptance Scenarios**:

1. **Given** a verified seller creates a Full Bottle listing, **When** they set
   `quantity_available` to 3, **Then** the listing is published showing "3 available"
   and the quantity field is visible on the listing detail page.
2. **Given** a Full Bottle listing with quantity = 2, **When** the seller decrements
   it to 1, **Then** the listing updates to show "1 available" and remains Published.
3. **Given** a Full Bottle listing with quantity = 1, **When** the seller decrements
   to 0 (or manually marks as Sold), **Then** the listing auto-transitions to Sold and
   is removed from public browse and search.
4. **Given** a Full Bottle listing has quantity > 1, **When** it appears in listing
   cards and search results, **Then** the quantity is displayed on the card (e.g.,
   "3 available") so buyers know stock is available.
5. **Given** a Full Bottle listing with quantity = 1 (the default), **When** it appears
   in browse and search, **Then** no quantity indicator is shown (default single-unit
   behaviour is unchanged visually).

---

### Edge Cases

- A bidder who is subsequently banned before auction close has their bids remain in the
  public bid list (historical record). The seller can still see and contact them; Admin
  handles any dispute via spec 005. No automatic bid invalidation on ban at v1. A banned
  bidder does not receive auction close/sold notifications (they cannot log in to see them).
- If a bidder deletes their account between placing a bid and auction close, their bid
  remains in the historical record (display name shown as "Deleted User") and they receive
  no notification. This is a plan-stage concern.
- The seller's outcome note on the Auction Result Page is optional and may remain empty
  forever — the result page must display correctly with no note present.
- If two bids are placed simultaneously at the same amount by different users, the system
  records both in order of receipt (timestamp). The earlier timestamp bid is ranked higher.
  The minimum increment rule means a subsequent bid of the same amount as the current
  highest is rejected regardless.
- An Auction listing with bids that expires can still be manually marked Sold by the
  seller (after contacting the chosen bidder off-platform). If the seller never marks it
  Sold, it stays Expired. No automatic Sold transition occurs.
- ISO matching is performed on fragrance name OR brand — matching either field qualifies
  a listing as a suggestion. Exact string match is used in v1; fuzzy/partial matching is
  a future enhancement.
- An ISO listing posted by a Member (non-Seller) follows the same impression declaration
  requirement as all other listing types.
- A Verified Seller who posts an ISO while acting as a buyer does not confuse their seller
  identity — the ISO is clearly labelled as "In Search Of" on their profile and in browse.
- If a Full Bottle listing has quantity = 5 and the seller decrements by more than 1 at
  once (e.g., sold 2 bottles to the same buyer), the seller enters the new quantity
  directly (e.g., 3) rather than decrementing one at a time. The system accepts any
  positive integer value at or above 1 without restriction.
- The "Suggested Listings" and "Buyers Looking For This" sections are read-only computed
  views — no data is stored. They appear or disappear based on live listing data.
- An ISO listing that expires or is deleted no longer appears in "Buyers Looking For This"
  sections on other listings.
- Full Bottle multi-quantity does not apply to Swap listings (one item offered for swap)
  or ISO listings (one request per posting). Auction listings remain fixed at quantity = 1.

---

## Requirements *(mandatory)*

### Functional Requirements

#### Auction Bidding

- **FR-001**: Any authenticated member who is not the listing owner MUST be able to place
  a bid on any Published Auction listing before its `auction_end_at`. The bid button MUST
  NOT be shown to the listing owner.

- **FR-002**: The first bid on an Auction listing MUST meet or exceed the listing's starting
  price (`price_pkr`). Each subsequent bid MUST exceed the current highest bid by at least
  PKR 500 (the system-enforced minimum bid increment). The system MUST reject any bid below
  the minimum valid amount and display the minimum required amount to the bidder.

- **FR-003**: Every bid MUST be recorded with: listing reference, bidder reference (display
  name shown publicly), bid amount (PKR), and `placed_at` timestamp. Bids MUST NOT be
  retractable or editable once confirmed.

- **FR-004**: All bids on an Auction listing MUST be publicly visible — to authenticated
  and unauthenticated visitors alike — showing each bidder's display name, bid amount, and
  timestamp. Bids are displayed in descending order by amount, with ties broken by earliest
  timestamp.

- **FR-005**: When `auction_end_at` is reached, the system MUST freeze bid acceptance
  (reject all new bids with "Auction has closed") and transition the listing to Expired
  status per spec 008 FR-009. The existing bid list remains publicly visible after close.

- **FR-006**: After auction close, the seller MUST be able to view the complete ranked bid
  list in their listing history. Each bid entry MUST include a "Message" action that opens
  or creates a conversation with that bidder via feature 006, pre-tagged with the listing.

- **FR-007**: An Auction listing's `price_pkr` field represents the **starting price** —
  the minimum amount the first bid must meet. The label on the listing creation form and
  detail page MUST read "Starting Price (PKR)" for Auction type (distinct from the "Price"
  label used on other types).

- **FR-008**: The current highest bid MUST be prominently displayed on the Auction listing
  detail page at all times (updating when new bids arrive). If no bids have been placed,
  the starting price is shown with a "No bids yet" indicator.

#### ISO — Open Access and Two-Way Matching

- **FR-009**: ISO listings MUST be the only listing type creatable by authenticated members
  without the Verified Seller role. Any authenticated member (Member or Seller role) MUST
  be able to create, publish, edit, and delete ISO listings. All other listing types remain
  restricted to Verified Sellers only.

- **FR-010**: When an ISO listing detail page is loaded, the system MUST compute and display
  a "Suggested Listings" section containing all currently Published, non-ISO listings
  (Full Bottle, Decant/Split, Swap, Auction) where the fragrance name or brand matches
  the ISO listing's fragrance name or brand (exact string match, case-insensitive).
  Suggestions are computed at display time — no data is stored.

- **FR-011**: The "Suggested Listings" section MUST display each matching listing with:
  sale post number, listing type badge, size in ml, condition, price in PKR, and the
  seller's verified badge if applicable. Each entry links to the full listing detail page.

- **FR-012**: When a Full Bottle, Decant/Split, Swap, or Auction listing detail page is
  loaded, the system MUST compute and display a "Buyers Looking For This" section containing
  all currently Published ISO listings where the fragrance name or brand matches the
  host listing's fragrance name or brand. This section MUST be hidden entirely (not shown
  as empty) when no matching ISOs exist.

- **FR-013**: Each entry in the "Buyers Looking For This" section MUST display: the ISO
  poster's display name, their max budget in PKR, preferred size, and a "View ISO" link
  to the ISO listing. The poster's verified seller badge is shown if applicable.

- **FR-014**: Both "Suggested Listings" and "Buyers Looking For This" sections MUST be
  visible to unauthenticated visitors — no login required to view suggestions.

#### Full Bottle Multi-Quantity

- **FR-015**: Full Bottle listings MUST support `quantity_available` ≥ 1, matching the
  same model already defined for Decant/Split in spec 008 FR-015. A seller with multiple
  identical bottles MAY set `quantity_available` to any positive integer at creation or
  edit time.

- **FR-016**: The seller MUST be able to update `quantity_available` on a published Full
  Bottle listing at any time, entering any positive integer. The system MUST accept direct
  quantity entry (not just increment/decrement) to support bulk updates (e.g., selling
  2 at once sets quantity from 5 to 3 directly).

- **FR-017**: When a Full Bottle listing's `quantity_available` is set to 0 by the seller,
  the system MUST automatically transition the listing to Sold status, identical to the
  behaviour defined for Decant/Split in spec 008 FR-015.

- **FR-018**: When `quantity_available > 1` on a Full Bottle listing, the quantity MUST
  be displayed on listing cards in browse/search results (e.g., "3 available") and on the
  listing detail page. When `quantity_available = 1`, no quantity indicator is displayed —
  single-unit behaviour is the visual default.

#### Cross-Feature Schema Contracts

- **FR-019**: Spec 008 FR-015 MUST be updated to allow `quantity_available` to be
  seller-editable for both Decant/Split and Full Bottle listing types. Swap, ISO, and
  Auction remain fixed at `quantity_available = 1`. The sentence "All other listing types
  MUST have `quantity_available = 1` and the field MUST NOT be editable by the seller"
  is amended to "Swap, ISO, and Auction listing types MUST have `quantity_available = 1`
  and the field MUST NOT be editable for those types."

- **FR-020**: Spec 002 FR-008 MUST be updated to add: "ISO-type listings are exempt from
  the Verified Seller restriction — any authenticated member may create, publish, and
  manage ISO listings regardless of role."

- **FR-021**: Spec 008 FR-009 status transitions are unchanged. A Full Bottle listing
  with `quantity_available = 0` follows the same Published → Sold auto-transition already
  defined for Decant/Split. No new status values are introduced by this spec.

#### Auction Result Page & Bidder Notifications

- **FR-022**: When an Auction listing transitions to Expired, its public detail page MUST
  automatically render as an Auction Result Page. The result page MUST display: the
  listing's fragrance details, the full ranked bid list (highest to lowest, with display
  name, amount, and timestamp for every bid), the close timestamp, and — if provided by
  the seller — the seller's outcome note. The result page is publicly visible to
  unauthenticated and authenticated visitors. No separate URL is used; it is the same
  listing URL rendered in its closed state.

- **FR-023**: After an Auction listing transitions to Expired, the seller MUST be able to
  add an optional free-text outcome note (maximum 200 characters) from their listing
  history view. This note is displayed on the public Auction Result Page. Suggested uses
  include: "Sale completed — thank you all for bidding", "No sale this round — relisting
  soon", or any brief message the seller wishes to share. The field is optional; the result
  page must function correctly with an empty note.

- **FR-024**: When an Auction listing transitions to Expired, the system MUST send an
  in-platform notification to every user who placed at least one bid on that listing.
  The notification text MUST read: "Auction [sale post number] — [fragrance name] has
  closed. View results." The notification MUST link directly to the Auction Result Page.
  Users who placed no bids receive no notification.

- **FR-025**: When an Auction listing transitions to Sold (seller manually marks it after
  contacting the winning bidder off-platform), the system MUST send a second in-platform
  notification to every user who placed at least one bid. The notification text MUST read:
  "Auction [sale post number] — [fragrance name] has been sold." The notification MUST
  link to the result page. This is a distinct notification from FR-024; bidders receive
  both at different times.

- **FR-026**: After an Auction listing has closed (Expired status), the seller MUST be
  able to initiate a conversation with any bidder directly from their listing history view
  using a "Message" link next to each bid entry. This is a permitted exception to the
  spec 006 buyer-initiates rule: the bidder's prior bid constitutes expressed intent, and
  the seller's post-close contact is not cold outreach. A conversation initiated this way
  MUST be pre-tagged with the Auction listing per spec 006 FR-002.

---

### Key Entities

- **Bid**: A single offer placed on an Auction listing. Attributes: listing reference
  (Auction type only), bidder reference (user), `bid_amount` (PKR integer, must meet
  minimum requirements), `placed_at` timestamp, visibility (public — all bids on an
  Auction are always public). No retraction or editing. Related to: one Auction Listing,
  one User (bidder).

- **Listing** *(extended from spec 008)*: The Auction listing sub-type gains:
  - `bid_count` (derived — count of Bid records for this listing; not stored)
  - `current_highest_bid` (derived — max `bid_amount` from Bid records; not stored)
  - The `price_pkr` field is relabelled "Starting Price" for Auction type only.
  - `min_bid_increment` is system-fixed at PKR 500; not stored per-listing.
  - `auction_outcome_note` — optional free-text seller note displayed on the Auction Result
    Page after close (text, nullable, max 200 characters; editable by seller only when
    listing is in Expired or Sold status).

  The Full Bottle sub-type gains:
  - `quantity_available` is now seller-editable (previously fixed at 1 for Full Bottle).

- **AuctionNotification**: An in-platform notification sent to a bidder when their
  auction closes or is marked sold. Attributes: recipient reference (user), listing
  reference (Auction type only), notification type (closed / sold), notification text,
  sent timestamp, read status (unread / read). One record created per bidder per event
  (close and sold are separate records). Bidders with multiple bids on the same auction
  receive one notification per event (not one per bid).

- **ISOMatch** *(computed, not stored)*: The result set shown in "Suggested Listings"
  or "Buyers Looking For This". Computed at display time by querying Published listings
  where fragrance name or brand matches the requesting listing's fragrance name or brand.
  No entity is persisted for this — it is a live read-only query.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A logged-in member can place a bid on an active Auction listing — from
  viewing the listing to seeing their bid confirmed in the public list — in under 30 seconds.

- **SC-002**: The live bid list on an Auction listing reflects newly placed bids within
  5 seconds of the bid being confirmed (on page refresh at minimum; real-time preferred).

- **SC-003**: When `auction_end_at` passes, the listing transitions to Expired and bid
  acceptance is frozen within 60 seconds — zero bids are accepted after that window.

- **SC-004**: 100% of bids below the minimum valid amount (starting price for first bid;
  current highest + PKR 500 for subsequent bids) are rejected with a clear message showing
  the minimum valid amount.

- **SC-005**: Zero bids are accepted on Expired, Sold, Deleted, or Removed Auction listings.

- **SC-006**: "Suggested Listings" on an ISO page loads within 2 seconds and shows 100%
  of matching Published listings at the time of page load.

- **SC-007**: "Buyers Looking For This" on a non-ISO listing page loads within 2 seconds
  and is hidden (not shown empty) when no matching ISOs exist — zero cases of an empty
  "Buyers Looking For This" section being displayed.

- **SC-008**: A Member (non-Seller) can publish an ISO listing — from opening the form
  to seeing it live — in under 3 minutes.

- **SC-009**: 100% of ISO creation attempts for listing types other than ISO by non-Seller
  members are rejected, with a message directing them to apply for Seller verification.

- **SC-010**: A Full Bottle listing with `quantity_available = 0` transitions to Sold
  within 5 seconds of the seller saving the zero quantity — with no manual "Mark as Sold"
  action required.

- **SC-011**: Bid list visibility requires zero authentication — 100% of auction bid
  history is readable by unauthenticated visitors.

- **SC-012**: 100% of bidders on a closed auction receive the "auction closed"
  in-platform notification within 60 seconds of the listing transitioning to Expired.
  Zero non-bidders receive the notification for any given auction.

- **SC-013**: 100% of bidders on a sold auction receive the "auction sold" in-platform
  notification within 60 seconds of the seller marking it Sold. The notification is
  a distinct entry from the close notification — bidders who received both can
  differentiate them in their notification inbox.

---

## Assumptions

- The minimum bid increment of PKR 500 is a fixed system constant in v1. It applies to all
  Auction listings equally regardless of starting price. A seller listing a PKR 100,000
  bottle and a seller listing a PKR 5,000 bottle both have the same PKR 500 step. A
  configurable per-listing increment is a future enhancement.
- The first bid must equal or exceed the starting price (not starting price + PKR 500).
  After the first bid, each new bid must exceed the current highest by PKR 500.
- Bid identity (display name) is always public. There is no anonymous bidding option at v1.
  Bidder phone numbers, emails, or other personal details are never shown — only display
  name and bid amount.
- After auction close the seller contacts their chosen bidder via the "Message" link in
  their listing history (FR-026 post-auction exception). Simultaneously, all bidders
  receive a close notification linking to the result page — they may also initiate contact
  via the standard "Message Seller" path. There is no "Accept Bid" button that creates any
  platform-side record. The entire post-close payment flow is off-platform; the platform
  provides the ranked bid list, outcome note, messaging, and notifications. This is
  consistent with the off-platform payment model.
- ISO matching uses exact (case-insensitive) string matching on fragrance name OR brand
  in v1. Partial matching, synonym handling, and typo correction are future enhancements.
- ISO suggestions shown on a listing page are capped at 20 entries in v1 to prevent
  performance issues on popular fragrances; beyond 20, a "View all matches" link is shown.
  This cap applies to both "Suggested Listings" and "Buyers Looking For This" sections.
- A Member who posts an ISO listing and later becomes a Verified Seller retains their ISO
  listing — no conversion or republishing is required.
- Full Bottle multi-quantity does not introduce a per-unit price; the price represents the
  price per bottle. If a seller wants to offer bulk discount they adjust the price manually.
- The "Buyers Looking For This" section on non-ISO listings is intentionally hidden (not
  shown as empty) when no ISOs match, to keep listing pages clean. The "Suggested Listings"
  section on ISO pages always shows (with a "no results" message if empty) because the ISO
  poster specifically needs to know whether matches exist.
- All ISO-matching logic is read-only computation at display time. No persistent
  relationship or notification is created between an ISO poster and a matching listing.
  Notification when a new matching listing is published is a future enhancement.
- Spec 002 FR-020 (Leave a Review CTA) does not apply to ISO listings — you cannot review
  a listing where you were the buyer looking for something. The review CTA is suppressed
  on ISO listing detail pages.
- **ISO contact initiation (Q1 resolution)**: There is no "Message Poster" button on
  non-ISO listing pages for visitors to cold-contact an ISO poster. The ISO poster (acting
  as buyer) is the one who initiates contact — they navigate from their own "Suggested
  Listings" section to the seller's listing and use the standard "Message Seller" button.
  The "Buyers Looking For This" section on non-ISO listings provides a "View ISO" link only.
- **Suggested Listings contact flow (Q3 resolution)**: The "Suggested Listings" section
  on an ISO listing page contains click-through links to each matched listing's full detail
  page only. There is no inline "Message Seller" button within the section itself. The
  ISO poster navigates to the listing's own page to initiate messaging from there.
- In-platform notifications (auction close/sold) are delivered within the platform only
  at v1. No email or SMS notifications are sent for auction events. Bidders must have a
  platform account and be logged in to see notifications; offline delivery is a future
  enhancement.
