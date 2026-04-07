# Feature Specification: Seller Verification

**Feature Branch**: `003-seller-verification`
**Created**: 2026-03-18
**Status**: Draft
**Input**: User description: "Seller verification — admin manually grants and revokes
verified seller badge, public legit sellers list searchable without authentication,
seller profiles showing transaction count, reviews, badge status, and member since date"

## Clarifications

### Session 2026-03-18

- Q: Should the spec include a formal seller application flow with gov ID upload, or does Admin still initiate verification proactively? → A: Hybrid — Admin can still proactively verify without a request; but a formal application flow is now in scope at v1. All sellers (new and existing Facebook group sellers) must be signed up on the platform first (spec 001). Upon or after signup they submit a verification application including: full legal name, CNIC number, CNIC front and back images (securely stored, Admin-only), phone number, city, and seller type checkboxes (BNIB / Decanter / Vial — schema-extensible). Existing Facebook group sellers additionally select "I am an existing PFC Facebook seller" and provide their Facebook-assigned seller ID and Facebook profile URL. Admin reviews the application and approves or rejects it.
- Q: Should verified sellers be assigned a unique PFC seller code, and how should existing Facebook group sellers be treated? → A: Yes — every verified seller receives a system-generated PFC seller code (e.g., PFC-XXXX) upon first approval, displayed on their profile and the Legit Sellers List, and searchable. Sellers who were authenticated on the original PFC Facebook group additionally receive a "Legacy Facebook Seller" badge displayed on their profile, indicating their established history on the Facebook community. New sellers (no Facebook history) have the PFC code only.
- Q: After an application is approved or rejected, how long should CNIC data be retained? → A: Retain CNIC images and number while the seller account is active; purge CNIC data 1 year after account closure or permanent ban; rejected applications and their CNIC data are purged after 90 days.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Member Submits a Seller Verification Application (Priority: P1)

A member who wants to sell on PFC submits a verification application. If they are a new
seller, they fill in their personal details, upload their CNIC (front and back), and select
the type(s) of items they sell. If they are an existing authenticated seller from the PFC
Facebook group, they additionally declare this, provide their Facebook-assigned seller ID
and Facebook profile URL, which gives Admin a faster reference for their track record.

**Why this priority**: The application is the entry point to the entire verification pipeline.
Without it, Admin has no structured record to review, no gov ID on file, and no audit trail
for how a seller was onboarded.

**Independent Test**: A logged-in member can open the seller application form, fill in all
required fields, upload CNIC images, and submit — receiving a confirmation that their
application is pending Admin review.

**Acceptance Scenarios**:

1. **Given** a logged-in member (not yet a Seller) opens the seller application form,
   **When** they fill in full legal name, CNIC number, CNIC front image, CNIC back image,
   phone number, city, and at least one seller type checkbox, and submit, **Then** an
   application record is created with status "Pending", and the member sees a confirmation
   that their application is under review.
2. **Given** a member is an existing PFC Facebook group seller, **When** they fill the
   application form, **Then** they can optionally tick "I am an existing PFC Facebook seller"
   and provide their Facebook-assigned seller ID and Facebook profile URL; these fields are
   not required for new sellers.
3. **Given** a member submits an application with any mandatory field missing, **When** they
   attempt to submit, **Then** the system blocks submission and highlights the missing fields.
4. **Given** a member already has a pending or approved application, **When** they attempt
   to open the application form again, **Then** the system shows their current application
   status and does not allow a duplicate submission.
5. **Given** a member's application is rejected, **When** they view their application status,
   **Then** they see the rejection reason provided by Admin and can re-submit a corrected
   application.

---

### User Story 2 - Admin Grants Verified Seller Badge (Priority: P1)

An Admin reviews a pending verification application — inspecting the submitted CNIC, personal
details, and (if applicable) the Facebook seller reference. The Admin approves or rejects the
application with a reason. On approval, the member's role upgrades to Seller and they appear
on the public Legit Sellers List. Admin can also proactively verify a member without a
submitted application (e.g., for trusted known sellers), attaching their details manually.

**Why this priority**: Verification is the gate that controls who can list fragrances.
Without it, no seller can create listings (per the Marketplace spec). It is the first
Admin action needed to make the marketplace functional.

**Independent Test**: An Admin opens a pending application, reviews the submitted CNIC images
and details, approves it, and the member immediately appears on the public Legit Sellers List
with their verified badge visible on their profile.

**Acceptance Scenarios**:

1. **Given** an Admin opens a pending verification application, **When** they review the
   submitted details and CNIC images and click "Approve", **Then** the member's role is
   updated to Seller, their profile shows the verified badge, and they appear on the Legit
   Sellers List. Admin can also grant the badge directly from a member's profile without
   a submitted application (proactive verification path).
2. **Given** a Member has just been granted a verified badge, **When** they next log in,
   **Then** they can access the create listing flow that was previously unavailable.
3. **Given** the badge grant is completed, **When** the member's profile is viewed publicly,
   **Then** it displays the verified badge, the date the badge was granted, and their
   member since date.
4. **Given** a non-Admin user attempts to grant a verified badge via any means, **When**
   the action is attempted, **Then** the system rejects it with a permission error.

---

### User Story 3 - Admin Revokes Verified Seller Badge (Priority: P1)

An Admin revokes the Verified Seller badge from a seller due to a violation, complaint, or
inactivity. The seller's role returns to Member, they are removed from the Legit Sellers
List, and their active listings remain visible but they cannot create new ones.

**Why this priority**: Revocation is the enforcement mechanism that gives the verified
badge its meaning. Without revocability, the badge cannot be trusted.

**Independent Test**: An Admin revokes a seller's badge; the seller immediately disappears
from the Legit Sellers List, their profile no longer shows the badge, and they cannot
access the create listing page.

**Acceptance Scenarios**:

1. **Given** an Admin views a verified seller's profile, **When** they click "Revoke
   Verified Badge" and confirm with a reason, **Then** the seller's role reverts to Member,
   the badge is removed from their profile, and they are removed from the Legit Sellers List.
2. **Given** a seller's badge has been revoked, **When** they attempt to create a new listing,
   **Then** they are blocked with a message that their seller status has been revoked.
3. **Given** a revocation has occurred, **When** the seller's existing published listings
   are viewed, **Then** the listings remain visible but no longer display the verified badge
   next to the seller's name.
4. **Given** a badge revocation, **When** the seller views their profile, **Then** they
   see a clear message that their verified status has been revoked and instructions for
   contacting Admin for reconsideration.

---

### User Story 4 - Public Views Legit Sellers List (Priority: P1)

Any visitor (authenticated or not) opens the Legit Sellers List to see all currently
verified sellers. They can search by seller name or username. Each entry shows the seller's
name, verified badge, member since date, and transaction count.

**Why this priority**: The public Legit Sellers List is a core trust signal of the platform.
Buyers use it to vet sellers before transacting. It must be available without requiring login.

**Independent Test**: An unauthenticated visitor opens the Legit Sellers List, searches for
a seller by name, and sees the correct result with badge, member since date, and transaction
count — without being prompted to log in.

**Acceptance Scenarios**:

1. **Given** a visitor navigates to the Legit Sellers List, **When** the page loads,
   **Then** all currently verified sellers are shown, each with name, verified badge, PFC
   seller code, member since date, transaction count, and a "Legacy Facebook Seller" badge
   where applicable, without requiring authentication.
2. **Given** a visitor types a name, username, or PFC seller code into the search bar on
   the Legit Sellers List, **When** the search is submitted, **Then** only sellers matching
   that query are shown.
3. **Given** a search returns no results, **When** results are displayed, **Then** a clear
   "no sellers found" message is shown.
4. **Given** a seller's badge has been revoked, **When** the Legit Sellers List is viewed,
   **Then** that seller does NOT appear on the list.

---

### User Story 5 - Visitor Views a Seller Profile (Priority: P2)

A buyer wants to vet a seller before transacting. They visit the seller's public profile
page, which shows the verified badge (if active), transaction count, average review rating,
individual reviews from buyers, badge status, and member since date.

**Why this priority**: Profiles give buyers the context to trust a seller. This builds on
the Legit Sellers List (P1) by providing deeper per-seller information.

**Independent Test**: A visitor can navigate to any seller's profile page without logging
in and see the badge status, transaction count, reviews, and member since date.

**Acceptance Scenarios**:

1. **Given** a visitor opens a seller's profile page, **When** the page loads, **Then**
   they see: display name, PFC seller code, verified badge (if active), "Legacy Facebook
   Seller" badge (if applicable), member since date, transaction count, average review
   score, and a list of reviews left by buyers.
2. **Given** a seller has no reviews yet, **When** their profile is viewed, **Then** a
   "No reviews yet" message is shown instead of an empty section.
3. **Given** a seller's badge has been revoked, **When** their profile is viewed, **Then**
   the verified badge is NOT shown, but the profile remains publicly accessible (their
   history is visible).
4. **Given** a visitor is on a listing page, **When** they click the seller's name,
   **Then** they are taken to that seller's public profile page.

---

### User Story 6 - Buyer Leaves a Review for a Listing (Priority: P2)

After receiving a fragrance purchased on PFC, a buyer leaves a review tied to that specific
listing. They provide a star rating, a written comment, and at least one proof image (a photo
of the received item) to confirm the transaction was real. The review appears on the seller's
profile showing which listing it relates to, making each review traceable to a real purchase.

**Why this priority**: Per-listing reviews with proof images are the primary defence against
fake reviews and the main trust signal for future buyers. Without them, the seller profile
has limited credibility.

**Independent Test**: A logged-in member opens a listing page, submits a review with a
1–5 rating, a written comment, and at least one proof image. The review appears on the
seller's profile showing the listing name/type alongside the rating, comment, and proof image.

**Acceptance Scenarios**:

1. **Given** a logged-in member views a listing page, **When** they submit a review with
   a star rating (1–5), a written comment, and at least one proof image, **Then** the review
   is published on the seller's profile showing: the listing name, type, and size; the
   rating; the comment; and the proof image(s).
2. **Given** a member tries to submit a review without uploading a proof image, **When**
   they attempt to publish, **Then** the system blocks submission and shows a message that
   at least one proof image is required.
3. **Given** a member has already reviewed a specific listing, **When** they attempt to
   submit another review for the same listing, **Then** the system shows their existing
   review and offers to edit it instead of creating a duplicate.
4. **Given** a member has purchased from the same seller multiple times (different listings),
   **When** they leave a review on each listing, **Then** each review appears separately
   on the seller's profile, each linked to its respective listing.
5. **Given** an unauthenticated visitor attempts to leave a review, **When** they click
   the review action, **Then** they are prompted to log in before continuing.
6. **Given** a seller views their own listing, **When** they attempt to submit a review
   on it, **Then** the system blocks self-reviews with an appropriate message.

---

### Edge Cases

- What if a rejected applicant re-submits within the 90-day window before their previous
  CNIC data is purged? — The previous application's CNIC data is superseded by the new
  submission. The 90-day purge clock resets from the new rejection date if rejected again.
- What if an account is closed before the 1-year post-closure retention window ends and
  someone requests their data be deleted earlier? — Data deletion requests are handled
  by Admin manually; no automated early-delete flow exists at v1.
- What if the same CNIC number is submitted by two different accounts? — The system MUST
  flag duplicate CNIC numbers to Admin during application review. Admin decides whether this
  is a legitimate second account or an attempt to circumvent a previous ban/rejection.
- Can a seller re-apply for verification after revocation? — Yes; Admin can re-grant the
  badge at any time. There is no automated cooldown. The badge grant history should record
  all grants and revocations with timestamps and reasons.
- What if a verified seller is banned? — A ban (handled by Moderation) supersedes the
  verified badge. Banned users cannot log in at all; their badge status becomes irrelevant.
- What happens to reviews if a seller is banned or their account is deleted? — Reviews
  remain visible on the profile for historical record; they are not deleted.
- Can Admin edit or delete reviews? — Yes; Admin can remove reviews that violate community
  rules (e.g., spam, abusive content). This is covered by Moderation tools (spec 005).
- Is transaction count manually tracked or automatic? — Transaction count is incremented
  when a seller marks a listing as "Sold" in the Marketplace (spec 002 FR-014). It is not
  manually editable.
- What is the review character limit? — Review text is capped at 500 characters at v1.
- What counts as valid proof image? — Any photo of the received item (fragrance bottle,
  decant, or package). The buyer chooses what to photograph; the system only enforces that
  at least one image is uploaded. Admin can remove reviews with clearly invalid proof via
  Moderation tools.
- Can a buyer review a listing that was never marked "Sold"? — Assumption: any authenticated
  member can submit a review on any listing (not gated to verified purchasers at v1), but
  the proof image requirement acts as the practical barrier against fabricated reviews.

## Requirements *(mandatory)*

### Functional Requirements

**Verification Application**

- **FR-001**: Any authenticated member who is not yet a Seller MUST be able to submit a
  seller verification application through the platform.
- **FR-002**: The application MUST collect the following mandatory fields: full legal name,
  CNIC number (text), CNIC front image, CNIC back image, phone number, city, and at least
  one seller type (BNIB / Decanter / Vial — multi-select checkboxes; schema is extensible
  for future seller type additions).
- **FR-003**: If the applicant is an existing PFC Facebook group seller, they MAY
  optionally declare this by ticking "I am an existing PFC Facebook seller" and providing
  their Facebook-assigned seller ID and Facebook profile URL. These fields are NOT mandatory
  for new sellers.
- **FR-004**: CNIC images MUST be stored securely with access restricted to Admin users
  only. CNIC images and CNIC number MUST NOT be exposed via any public-facing API or UI.
  Data retention rules: (1) For approved sellers — CNIC data is retained for the lifetime
  of the active account and purged 1 year after account closure or permanent ban.
  (2) For rejected applications — CNIC data is purged automatically 90 days after rejection.
  The system MUST enforce these purge schedules without requiring manual Admin intervention.
- **FR-005**: A member with a pending or approved application MUST NOT be able to submit
  a duplicate application. A member whose application was rejected MAY re-submit a corrected
  application.
- **FR-006**: Admin MUST be able to view all pending applications in a queue, review each
  application's submitted details and CNIC images, and either approve or reject the
  application with a mandatory reason recorded for rejection.
- **FR-007**: On rejection, the applicant MUST be able to see the rejection reason from
  their application status page so they know what to correct before re-submitting.

**Badge Grant and Revocation**

- **FR-008**: Only Admin MUST be able to grant or revoke the Verified Seller badge. No
  automated or peer-grant path exists. Admin MAY approve a submitted application OR
  proactively grant the badge directly from a member's profile (for trusted known sellers).
- **FR-009**: Granting the badge MUST upgrade the user's role from Member to Seller
  immediately, without requiring a separate role assignment step. At the moment of first
  approval, the system MUST auto-generate a unique, immutable PFC seller code in the format
  `PFC-XXXX` (where XXXX is a zero-padded sequential number). This code MUST NOT change on
  badge revocation, re-grant, or any other event.
- **FR-010**: If the approved seller indicated they are an existing PFC Facebook group seller
  (and provided a valid Facebook seller ID), their profile MUST display a "Legacy Facebook
  Seller" badge in addition to the standard Verified Seller badge. This legacy badge indicates
  they were authenticated in the original PFC Facebook community before the platform launched.
- **FR-011**: The PFC seller code MUST be displayed on the seller's public profile and on
  their entry in the Legit Sellers List. The Legit Sellers List search (FR-015) MUST also
  support searching by PFC seller code.
- **FR-012**: Revoking the badge MUST immediately downgrade the user's role from Seller
  to Member, blocking new listing creation while preserving existing published listings.
- **FR-013**: Every grant and revocation MUST be recorded with a timestamp, the Admin who
  performed the action, and a mandatory reason field.

**Legit Sellers List**

- **FR-014**: The Legit Sellers List MUST be publicly accessible without authentication
  and MUST show only currently verified sellers.
- **FR-015**: The Legit Sellers List MUST support text search by seller name, username,
  or PFC seller code.
- **FR-016**: Each entry on the Legit Sellers List MUST display: seller display name, PFC
  seller code, verified badge indicator, "Legacy Facebook Seller" badge (where applicable),
  member since date, and transaction count.

**Seller Profiles**

- **FR-017**: Seller profiles MUST be publicly accessible without authentication.
- **FR-018**: Seller profiles MUST display: display name, PFC seller code, verified badge
  status, "Legacy Facebook Seller" badge (if applicable), member since date, transaction
  count, average review rating, and individual reviews. Each review entry MUST show the
  listing it relates to (listing name, type, and size), the buyer's rating, comment, and
  proof image(s).
- **FR-019**: Transaction count on a seller's profile MUST be automatically incremented
  when the seller marks a listing as "Sold" in the Marketplace (spec 002 FR-014). It MUST
  NOT be manually editable by any user including Admin.

**Reviews**

- **FR-020**: Authenticated members MUST be able to leave one review per listing. Each
  review MUST include a star rating (1–5), a written comment (max 500 characters), and
  at least one proof image showing the received item. Reviews without a proof image MUST
  be rejected at submission.
- **FR-021**: A member MUST be able to edit their own previously submitted review for a
  listing (rating, comment, and proof images). They MUST NOT be able to submit a second
  separate review for the same listing. A buyer who has purchased from the same seller
  multiple times (different listings) MAY leave a separate review for each listing.
- **FR-022**: A seller MUST NOT be able to leave a review on their own listings.

**Audit**

- **FR-023**: Badge grant history (all grants and revocations with timestamps, admin, and
  reason) MUST be visible to Admin. It MUST NOT be visible to public users or the seller.

### Key Entities

- **SellerApplication**: A member's request to become a verified seller. Attributes:
  applicant reference, full legal name, CNIC number (encrypted at rest), CNIC front image
  reference (secure storage, Admin-only), CNIC back image reference (secure storage,
  Admin-only), phone number, city, seller types (BNIB / Decanter / Vial — multi-value,
  extensible), is_existing_fb_seller (boolean), fb_seller_id (nullable), fb_profile_url
  (nullable), application status (pending / approved / rejected), submission date, reviewed
  by (Admin reference — nullable), review date (nullable), rejection reason (nullable).
- **SellerBadge**: Represents the current verified status of a user. Attributes: user
  reference, pfc_seller_code (assigned once on first grant — immutable), status (active /
  revoked), granted date, granted by (Admin reference), last action date, last action by
  (Admin reference), last action reason.
- **BadgeAuditLog**: Historical record of every badge action. Attributes: user reference,
  action (granted / revoked), performed by (Admin reference), timestamp, reason.
- **SellerProfile**: Public-facing seller information. Attributes: user reference, display
  name, pfc_seller_code (system-generated, immutable, unique — e.g., PFC-0001), member
  since date, transaction count (derived from sold listings), average rating (derived from
  reviews), verified badge status (active / revoked), is_legacy_fb_seller (boolean —
  true if the seller was authenticated on the PFC Facebook group before the platform).
- **Review**: A buyer's assessment tied to a specific listing transaction. Attributes:
  reviewer reference, seller reference, listing reference, rating (1–5), comment
  (max 500 chars), proof images (one or more), submitted date, last edited date.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An Admin can grant or revoke a verified badge — from finding the user to
  completing the action — in under 2 minutes.
- **SC-002**: Badge grant or revocation takes effect immediately — the Legit Sellers List
  and seller profile reflect the new status within 5 seconds.
- **SC-003**: 100% of badge grants and revocations are recorded in the audit log with
  timestamp, Admin identity, and reason.
- **SC-004**: The Legit Sellers List is accessible and loads within 2 seconds for
  unauthenticated visitors.
- **SC-005**: Zero revoked sellers appear on the Legit Sellers List.
- **SC-006**: A buyer can submit a review (with proof image) and see it appear on the
  seller's profile — showing the linked listing details — within 5 seconds of submission.
- **SC-007**: Transaction count on a seller's profile accurately reflects the number of
  listings that seller has marked as "Sold", with zero manual overrides possible.
- **SC-008**: Zero reviews without at least one proof image are published. The proof image
  requirement is enforced 100% of the time at submission.
- **SC-009**: 100% of verified sellers have a unique PFC seller code assigned at first
  approval — zero verified sellers exist without a code.
- **SC-010**: A buyer can look up any verified seller by PFC seller code on the Legit
  Sellers List and find exactly one matching result.

## Assumptions

- The verification application flow is now in scope at v1. Members submit applications with
  CNIC and personal details; Admin reviews and approves or rejects. Admin retains the ability
  to proactively grant badges without a submitted application (e.g., for known trusted sellers).
- CNIC data (images and number) is sensitive personal data: encrypted at rest, accessible
  only by Admin, never exposed in public API responses. Retention: approved sellers' CNIC
  data is kept while the account is active and purged 1 year after account closure or
  permanent ban; rejected applications' CNIC data is auto-purged after 90 days. Purge
  schedules must be enforced by the system automatically, not manually by Admin.
- Seller types (BNIB / Decanter / Vial) are the initial set derived from the PFC Facebook
  group's existing categorisation. These are stored as a multi-value field; new types can
  be added to the schema without breaking existing records.
- Facebook seller IDs and profile URLs are optional reference fields for existing community
  sellers; they are used by Admin for cross-reference only and are never shown publicly.
- "Transaction count" is derived from Sold listings in the Marketplace module (spec 002
  FR-014). The two features have a data dependency: transaction count will only be accurate
  once the Marketplace "mark as sold" flow is implemented. Auction listings that expire
  without being manually marked Sold by the seller are NOT counted — transaction count only
  increments on an explicit Sold transition.
- Star ratings use a 1–5 integer scale. Half-star ratings are not supported at v1.
- Average rating is calculated across all per-listing reviews for the seller; it updates
  when a review is submitted or edited.
- Reviews are not gated to verified purchasers at v1 — any authenticated member may review
  any listing. The mandatory proof image (photo of the received item) is the primary
  anti-fake-review control. Gating reviews to confirmed purchasers is a future enhancement.
- "Proof image" means a photo of the received item (bottle, decant, or package). The system
  enforces that at least one image is uploaded; it does not validate image content. Admin
  moderation handles clearly invalid proof images.
- Admin can delete reviews that violate community rules, but this action is governed by
  the Moderation module (spec 005). This spec only covers review submission and editing
  by buyers.
- Seller profiles are always public; there is no private or hidden profile option in v1.
- The PFC seller code format is `PFC-XXXX` (4-digit zero-padded sequential integer, e.g.,
  PFC-0001). The sale post number format is `PFC-XXXXX` (5-digit zero-padded) per spec 008.
  Both share the `PFC-` prefix. At plan stage, the team should confirm whether a distinct
  prefix for seller codes (e.g., `PFCS-XXXX`) is preferred to avoid user confusion when
  both identifiers are shared in the Facebook group.
