# Feature Specification: Local Pickup with Map Location

**Feature Branch**: `007-local-pickup-maps`
**Created**: 2026-03-18
**Status**: Draft
**Input**: User description: "i also want local pickup to be added as option but with free maps
integration that will help buyers (optionally) add the pickup location if available. Manual entry
+ fetch location via the user's current GPS is also available so its clearly marked if he wants
to use his current location as pickup. We will list it with spec 002 then carefully"

**Related feature**: `002-marketplace-listings` — This feature extends the listing entity defined
in spec 002 by adding an optional, structured pickup location field. At plan stage, spec 002's
listing data model MUST be updated to include a `pickup_location` reference. The delivery details
field in spec 002 covers general shipping/courier information; local pickup is a separate,
map-enabled field layered on top. All listing creation and editing flows are owned by spec 002;
this spec owns only the pickup location sub-feature within those flows.

## Clarifications

### Session 2026-03-18

- Q: Should manual address entries also show a map pin at v1 (requiring geocoding), or is text-only acceptable for manually entered addresses? → A: Geocode manual addresses at v1 — all pickup listings show a map pin regardless of input method.
- Q: Should manual address entry also require an explicit acknowledgment that the address will be publicly visible? → A: Yes — same consent prompt for both GPS and manual entry; one consistent "this address will be publicly visible" acknowledgment regardless of input method.
- Q: Should the map display the seller's exact saved location or an approximate area pin to protect seller privacy? → A: Approximate area pin — map shows a neighbourhood-level pin (fuzzed ~500m–1km); the exact address is shown as text alongside, but the map pin is approximate.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Seller Adds a Pickup Location to a Listing (Priority: P1)

A verified seller is creating or editing a listing and wants to offer local pickup as an option.
They can type in an address manually, or tap a button to use their device's current GPS location
as the pickup point. Before saving a GPS-derived location, they are shown a clear warning that
the location will be publicly visible on the listing and must confirm before proceeding.

**Why this priority**: Local pickup is the core value of this feature. Without the ability to
add a location, buyers cannot discover or plan pickups, making the rest of the feature pointless.

**Independent Test**: A verified seller can add a pickup location (manual address) to a new
listing and see it saved and visible on the listing detail page.

**Acceptance Scenarios**:

1. **Given** a verified seller is on the create or edit listing form, **When** they expand the
   "Offer Local Pickup" option, **Then** they are presented with a location input area containing
   a free-text address field and a "Use My Current Location" button.
2. **Given** a seller types a pickup address manually and saves the listing, **When** the listing
   is published or updated, **Then** the pickup address is stored with the listing and displayed
   on the public listing detail page.
3. **Given** a seller enters a pickup address (by either manual text or GPS), **When** they attempt
   to save the location, **Then** the system displays a confirmation prompt: "This address will be
   publicly visible to all buyers on this listing." The seller MUST confirm before the location is
   saved. This applies to both input methods.
4. **Given** a seller confirms use of GPS location, **When** confirmed, **Then** the GPS
   coordinates and a human-readable address are saved as the listing's pickup location.
5. **Given** a seller does not expand or fill the pickup location option, **When** the listing is
   saved or published, **Then** no pickup location is stored and the listing shows no pickup
   option — pickup is entirely optional.
6. **Given** a seller's device denies GPS permission, **When** they click "Use My Current
   Location", **Then** the system shows a clear message that GPS access was denied and falls back
   to manual address entry only.

---

### User Story 2 - Buyer Views Pickup Location on a Listing (Priority: P1)

A buyer browsing a listing sees that pickup is available. They can view the pickup location on
an embedded map and read the address. This helps them decide if the location is convenient
before contacting the seller.

**Why this priority**: If buyers cannot see the location clearly, the pickup option has no
discovery value. This story must be live simultaneously with US1.

**Independent Test**: An unauthenticated visitor opens a listing that has a pickup location set
and sees a map pin and the address displayed on the listing detail page.

**Acceptance Scenarios**:

1. **Given** a listing has a pickup location set, **When** any visitor (authenticated or not)
   opens the listing detail page, **Then** a "Local Pickup Available" badge and the seller's
   address are prominently displayed alongside a map showing a location pin.
2. **Given** a listing has no pickup location, **When** a visitor opens the listing detail page,
   **Then** no map, badge, or pickup section is displayed.
3. **Given** a visitor applies the "Local Pickup Available" filter in marketplace browse,
   **When** the filter is applied, **Then** only listings with a pickup location set are shown.
4. **Given** a listing with a pickup location is displayed, **When** the map loads, **Then** it
   shows a pin at an approximate area location (fuzzed ~500m–1km from the exact address) using a
   freely available, no-cost map provider. The map is interactive (zoomable and pannable) but no
   routing or directions are provided at v1. The exact address is shown as text separately.

---

### User Story 3 - Seller Updates or Removes Pickup Location (Priority: P2)

A seller who previously offered pickup changes their situation — they moved, or they no longer
want to offer pickup. They update the address or remove the pickup option entirely from a
published listing.

**Why this priority**: Stale or incorrect pickup addresses create a poor buyer experience and
erode trust. Sellers must be able to keep their location data current.

**Independent Test**: A seller removes a pickup location from a published listing and the map,
address, and "Local Pickup Available" badge immediately disappear from the public listing page.

**Acceptance Scenarios**:

1. **Given** a seller edits a published listing that has a pickup location, **When** they clear
   the address field and save, **Then** the pickup location is removed from the listing and no
   longer shown to buyers.
2. **Given** a seller updates the pickup address on a published listing, **When** saved, **Then**
   the new address and map pin are immediately visible on the public listing detail page.
3. **Given** a seller removes a pickup location, **When** saved, **Then** the listing no longer
   appears in the "Local Pickup Available" filter results.
4. **Given** a seller edits a pickup address, **When** saved, **Then** the listing's sale post
   number MUST NOT change (consistent with spec 002 FR-015).

---

### Edge Cases

- If a seller provided a GPS location and later re-opens the listing to edit, the map shows the
  previously saved pin. The seller can update or remove it; no automatic location refresh occurs.
- GPS coordinates can be stale if the seller has moved. No automatic location tracking is done;
  the seller is solely responsible for keeping the address current.
- Each listing has its own independent pickup location. A seller with multiple listings must set
  pickup per listing; there is no "copy pickup location from another listing" feature at v1.
- If a listing is deleted, the pickup location data is deleted along with it.
- ISO listings represent what a buyer is seeking; offering a pickup location on an ISO listing is
  allowed but unusual. The system does not restrict pickup to specific listing types.
- Coordinates derived from a manual address entry (via geocoding at plan stage) may not be
  perfectly precise. The seller's typed address is the authoritative pickup reference; the map pin
  is a visual aid only.
- The display pin is fuzzed from exact coordinates — the fuzz radius (~500m–1km) means the pin
  may fall in an adjacent street or block. Buyers are expected to confirm the exact meeting point
  with the seller via messaging before arranging pickup.
- If the map provider is unavailable, the address text MUST still be displayed as a fallback.
  The listing must remain fully functional without the map.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Pickup location MUST be an optional field on all listing types defined in spec 002.
  Sellers MUST NOT be required to set a pickup location to publish a listing.
- **FR-002**: A seller MUST be able to enter a pickup address as free text (street address, area,
  city). The system MUST geocode the entered address to coordinates so that a map pin is displayed
  for all pickup listings regardless of input method. No address validation or geocoding accuracy
  guarantee is required — the pin is a best-effort visual aid.
- **FR-003**: A seller MUST be able to use their device's current GPS coordinates as the pickup
  location via a clearly labelled "Use My Current Location" action.
- **FR-004**: Before saving any pickup location — whether entered manually or via GPS — the system
  MUST display a visible confirmation prompt stating "This address will be publicly visible to all
  buyers on this listing." The seller MUST explicitly confirm before the location is saved.
  The same prompt applies to both input methods.
- **FR-005**: If GPS access is unavailable or denied by the device, the system MUST display a
  clear message and allow the seller to enter an address manually instead. The GPS failure MUST
  NOT block the seller from using manual entry.
- **FR-006**: Every listing detail page where pickup is set MUST display:
  (a) a "Local Pickup Available" badge,
  (b) the seller's pickup address as plain text (exact, as entered),
  (c) an interactive map with a pin at an approximate location — fuzzed by approximately
  500m–1km from the exact coordinates — to protect seller privacy. The map pin indicates the
  general area; the address text is the authoritative pickup reference.
- **FR-007**: The map display MUST use a freely available, no-cost map provider. No paid mapping
  APIs or services are permitted at v1.
- **FR-008**: The map and pickup address MUST be publicly visible — no login required to view.
- **FR-009**: Marketplace browse MUST include a "Local Pickup Available" filter option. Applying
  this filter MUST return only listings that have a pickup location stored.
- **FR-010**: A seller MUST be able to update or remove a pickup location from any published
  listing at any time. Changes MUST be reflected immediately on the public listing page.
- **FR-011**: If the map provider fails to load, the pickup address text MUST still be displayed
  as a fallback. The listing detail page MUST remain fully usable without the map.
- **FR-012**: Pickup location data (address text, coordinates) MUST be stored as part of the
  listing record and persist across all edits to other listing fields, unless explicitly removed
  by the seller.
- **FR-013**: Deleting a listing (per spec 002 FR-016) MUST also delete the associated pickup
  location data.

### Key Entities

- **PickupLocation**: Optional sub-record of a Listing. Attributes: listing reference, address
  (free text as entered by seller — exact, authoritative), latitude (exact — from GPS or geocoded;
  nullable), longitude (exact — from GPS or geocoded; nullable), display_latitude (fuzzed ~500m–1km
  from exact; used for map pin display only), display_longitude (fuzzed; used for map pin display
  only), location source (manual / gps), visibility_consent_acknowledged (boolean — true if seller
  confirmed the public visibility prompt; required for both manual and GPS entries), created date,
  updated date.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A seller can add a pickup location (via manual entry or GPS) to a listing in under
  60 seconds from opening the pickup field.
- **SC-002**: 100% of listings with a saved pickup location display a map pin and the address
  on the listing detail page.
- **SC-003**: The "Local Pickup Available" browse filter returns only and all listings with a
  pickup location — zero false positives or false negatives.
- **SC-004**: The pickup location map loads and displays the pin within 3 seconds on the listing
  detail page under normal network conditions.
- **SC-005**: A seller removing a pickup location sees the map, badge, and address disappear
  from the public listing within 5 seconds of saving.
- **SC-006**: If the map provider is unavailable, the pickup address text is still visible to
  100% of buyers visiting the listing page.

## Assumptions

- Pickup location is entirely optional; no listing type is required to have it. Sellers choose
  to offer pickup at their discretion.
- At v1, no directions or routing are provided — the map shows a pin only. Navigation assistance
  (e.g., "Get Directions") is a future enhancement.
- The "free maps" requirement is interpreted as: the map provider must have a no-cost usage tier
  sufficient for the expected v1 traffic. OpenStreetMap-based solutions (e.g., Leaflet with OSM
  tiles) are the assumed approach at plan stage; the spec does not mandate a provider.
- Address geocoding (converting a typed address to coordinates for map display) is required at v1
  for all manual-entry addresses. Every pickup listing MUST display a map pin regardless of
  whether the location was entered manually or via GPS. Geocoding accuracy is best-effort; the
  seller's typed address remains the authoritative reference. The geocoding provider will be
  selected at plan stage (must be free-tier compatible).
- Sellers are responsible for keeping their pickup address current. No automatic expiry or
  staleness warning is applied at v1.
- Pickup location coordinates are stored at listing level, not profile level. A seller running
  multiple listings can have a different pickup location per listing.
- The GPS confirmation prompt (FR-004) satisfies the seller's privacy consent for that listing.
  No platform-wide location tracking or storage beyond the listing record is performed.
- Integration with spec 002: at plan stage, spec 002's Listing entity must be extended with an
  optional `pickup_location` reference, and the listing creation/edit form must include the
  pickup location sub-section. The browse filter in spec 002 (FR-011) must be extended to include
  the "Local Pickup Available" filter option defined here in FR-009.
