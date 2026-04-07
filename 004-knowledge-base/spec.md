# Feature Specification: Knowledge Base

**Feature Branch**: `004-knowledge-base`
**Created**: 2026-03-18
**Status**: Draft
**Input**: User description: "Knowledge base — fragrance encyclopedia with notes, longevity
and sillage, user-written reviews, admin-published fake detection guides, and glossary of
community acronyms (BNIB, ISO, SOTD etc)"

**Scope decision**: The full fragrance encyclopedia is deferred to a future phase. At v1
the Knowledge Base is a Community Reference Library with three sections: Fake Detection
Guides, Community Guides, and Glossary. Listing-level reviews and fragrance transaction
context already live on seller profiles and listing pages; this module covers reference
content that no other module provides. A fragrance index (Option B) may be introduced as
a v2 enhancement once the community is large enough to populate it organically.

**Contribution model**: Fake Detection Guides can be submitted by any authenticated member
via a structured form, then reviewed and approved by Admin before publication. Admin can
also author guides directly. This community-contribution model scales better than
Admin-only authorship and taps into member expertise on specific fragrances.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Visitor Reads a Fake Detection Guide (Priority: P1)

A buyer is about to purchase a popular fragrance (e.g., Creed Aventus, Dior Sauvage) and
wants to know how to verify authenticity before paying. They find the guide for that
fragrance on PFC, read through the admin-curated checklist of authenticity markers (batch
codes, box printing, scent profile, bottle details), and feel confident going into the
transaction.

**Why this priority**: Fake fragrances are a major problem in the Pakistani market. The
fake detection guides are the highest-value content PFC offers that no other platform
provides. They are also the strongest signal that PFC is a serious, trustworthy community.

**Independent Test**: An unauthenticated visitor can open the Fake Detection Guides section,
browse guides by fragrance name, open a guide, and read through the full authenticity
checklist — all without logging in.

**Acceptance Scenarios**:

1. **Given** a visitor navigates to the Knowledge Base, **When** they open the Fake
   Detection Guides section, **Then** they see a list of guides sorted by most recently
   published, each showing the fragrance name, brand, and publication date.
2. **Given** a visitor searches for a specific fragrance in the guides section, **When**
   the search is submitted, **Then** only guides matching that fragrance name or brand
   are shown.
3. **Given** a visitor opens a guide, **When** the page loads, **Then** they see the full
   guide content: authenticity markers, photos illustrating real vs. fake differences, and
   the date the guide was published or last updated by Admin.
4. **Given** no guide exists for a searched fragrance, **When** results are shown, **Then**
   a "no guide found" message is shown with a link to report a suspected fake via the
   Moderation module.
---

### User Story 2 - Member Submits a Fake Detection Guide (Priority: P1)

A knowledgeable member has spotted a fake version of a popular fragrance and wants to help
the community. They open the guide submission form, which walks them through a structured
set of sections (box differences, bottle differences, scent profile, batch code guide) with
dedicated image upload fields for each section. They submit the completed guide for Admin
review.

**Why this priority**: Member-contributed guides scale the Knowledge Base far beyond what
Admin alone can produce, and members often have deeper hands-on knowledge of specific
fragrances than Admin. The structured form ensures all submissions meet a consistent
quality standard.

**Independent Test**: A logged-in member can open the guide submission form, fill in all
required sections with text and at least one comparison photo, submit it, and see it
appear in their "My Submissions" page with status "Pending Review" — without it being
publicly visible yet.

**Acceptance Scenarios**:

1. **Given** a logged-in member opens the guide submission form, **When** they complete
   all required sections (fragrance name, brand, and at least one structured section with
   a comparison photo) and submit, **Then** the submission enters the Admin review queue
   with status "Pending Review" and appears in the member's "My Submissions" list.
2. **Given** a member submits a guide, **When** the submission is created, **Then** it
   is NOT visible in the public Fake Detection Guides list until Admin approves it.
3. **Given** a member's submission is pending review, **When** they view "My Submissions",
   **Then** they see the fragrance name, submission date, and current status (Pending
   Review / Approved / Rejected).
4. **Given** a member submits a guide without uploading at least one comparison photo,
   **When** they attempt to submit, **Then** the system blocks submission and highlights
   the missing photo requirement.
5. **Given** a guide for a specific fragrance already exists and is published, **When** a
   member submits a new guide for the same fragrance, **Then** the system warns them a
   guide already exists and asks them to confirm they want to submit an update/alternative.

---

### User Story 3 - Admin Reviews and Publishes a Member-Submitted Guide (Priority: P1)

An Admin opens the guide submission queue, reviews a member's submission for accuracy and
quality, optionally edits it for clarity or corrections, and either approves (publishing
it immediately) or rejects it with feedback. Published member-contributed guides credit
the submitting member by display name.

**Why this priority**: The approval gate ensures quality and prevents misinformation from
reaching the public. Without it, member contributions could cause harm if inaccurate.

**Independent Test**: An Admin can open a pending guide submission, edit its content,
approve it, and see it appear in the public Fake Detection Guides list credited to the
member. If rejected, the member sees "Rejected" status and the feedback reason.

**Acceptance Scenarios**:

1. **Given** an Admin opens the guide submission queue, **When** the page loads, **Then**
   all pending member submissions are shown with fragrance name, submitter name, and
   submission date, sorted oldest first.
2. **Given** an Admin opens a specific submission, **When** reviewing, **Then** they can
   edit any section of the guide, add or replace photos, and either approve or reject it.
3. **Given** an Admin approves a submission, **When** confirmed, **Then** the guide is
   published to the public Fake Detection Guides list, credited as "Contributed by
   [member display name], reviewed by Admin", with publication date set to approval date.
4. **Given** an Admin rejects a submission, **When** they provide a rejection reason and
   confirm, **Then** the submission status changes to "Rejected", the rejection reason is
   visible to the member in "My Submissions", and the guide does not appear publicly.
5. **Given** an Admin authors a guide directly (not from a member submission), **When**
   published, **Then** it is credited as "PFC Admin" with no member attribution.

---

### User Story 4 - Admin Authors a Guide Directly (Priority: P2)

An Admin creates a Fake Detection Guide or Community Guide directly from scratch — without
a member submission — when they have the knowledge or want to cover a gap urgently.

**Why this priority**: Admin-direct authorship is the fallback for guides that no member
has submitted, and is the only path for Community Guides (how-to articles). Lower priority
than the member contribution flow since that is the primary content pipeline.

**Independent Test**: An Admin can create a new guide with title, content, and photos, save
it as a draft, preview it, publish it, and see it immediately appear in the public list.

**Acceptance Scenarios**:

1. **Given** an Admin opens the guide creation form, **When** they fill in all required
   fields and publish, **Then** the guide appears in the public list immediately, credited
   as "PFC Admin".
2. **Given** an Admin is writing a guide, **When** they save it as a draft, **Then** the
   draft is accessible in the Admin panel but does not appear publicly.
3. **Given** an Admin publishes a guide, **When** they later need to update it, **Then**
   they can edit the guide and the updated version replaces the old one with "last updated"
   date shown to readers.
4. **Given** an Admin deletes a published guide, **When** confirmed, **Then** the guide is
   removed from the public list and any direct links show a "guide not found" page.

---

### User Story 5 - Visitor Reads a Community Guide (Priority: P2)

A new community member wants to understand how to safely buy a decant, what to check when
receiving a fragrance, or how to pack a bottle for shipping. They browse the Community
Guides section and find practical how-to articles written by Admin.

**Why this priority**: Community guides provide onboarding value for new members and reduce
common mistakes (damage during shipping, failing to verify before paying). They differentiate
PFC from a plain classifieds board.

**Independent Test**: An unauthenticated visitor can browse Community Guides, open any
guide, and read the full content without being prompted to log in.

**Acceptance Scenarios**:

1. **Given** a visitor opens the Community Guides section, **When** the page loads,
   **Then** all published guides are shown, each with a title, brief description, and
   publication date.
2. **Given** a visitor opens a community guide, **When** the page loads, **Then** the full
   article is shown with headings, body text, and any embedded images.
3. **Given** a visitor searches community guides by keyword, **When** the search is
   submitted, **Then** guides matching the keyword in title or body are returned.

---

### User Story 6 - Visitor Looks Up a Glossary Term (Priority: P2)

A new member encounters an unfamiliar term in a listing or discussion — "BNIB", "ISO",
"SOTD", "EDP", "chypre" — and looks it up in the Glossary. They find the definition and
any relevant context for how the term is used in the PFC community.

**Why this priority**: The fragrance hobby has a steep vocabulary curve. A glossary removes
a major barrier for new Pakistani community members who are unfamiliar with hobby shorthand.

**Independent Test**: An unauthenticated visitor opens the Glossary, searches "BNIB", and
sees the full definition without logging in.

**Acceptance Scenarios**:

1. **Given** a visitor opens the Glossary, **When** the page loads, **Then** all glossary
   terms are shown in alphabetical order, each with the term and a short definition.
2. **Given** a visitor types a term into the Glossary search, **When** searching, **Then**
   matching terms are shown in real time (or on submit) with their definitions.
3. **Given** a visitor searches for a term that does not exist, **When** results are shown,
   **Then** a "term not found" message is shown with a prompt to suggest a new term.

---

### User Story 7 - Admin Manages Glossary Terms (Priority: P2)

Admin can add new glossary terms, edit existing definitions, or remove outdated entries.
Members can suggest new terms but cannot publish them directly — Admin approves before
publication.

**Why this priority**: The glossary must stay accurate and community-relevant. Admin control
ensures quality; member suggestions surface terms Admin may not think of.

**Acceptance Scenarios**:

1. **Given** an Admin opens the Glossary management panel, **When** they add a new term
   with a definition and save, **Then** the term immediately appears in the public Glossary.
2. **Given** an Admin edits an existing term, **When** saved, **Then** the updated
   definition replaces the old one publicly.
3. **Given** an authenticated member submits a term suggestion (term + definition), **When**
   submitted, **Then** the suggestion appears in an Admin review queue and does NOT appear
   in the public Glossary until Admin approves it.
4. **Given** Admin approves a member-suggested term, **When** approved, **Then** it is
   published to the Glossary immediately.

---

### Edge Cases

- What if a fake detection guide becomes outdated (e.g., a new fake batch is released)?
  Admin can edit and re-publish. The "last updated" date signals freshness to readers.
- What if two members submit guides for the same fragrance? — Both appear in the Admin
  review queue. Admin approves the better one (or merges content) and rejects the other
  with a reason. Only one published guide per fragrance is shown publicly.
- Can a member edit their submission after it has been rejected? — No; a rejected
  submission is closed. The member must submit a new guide incorporating the feedback.
- Can a member see who reviewed their submission? — They see "Reviewed by Admin" but not
  the specific Admin's identity.
- Can visitors link directly to a specific guide or glossary term? — Yes; each guide and
  each glossary term has a stable, shareable URL.
- What if Admin deletes a guide that is linked from a listing page? — The link shows a
  "guide not found" page. No cascading deletion of listings.
- What happens to a member's term suggestion if Admin never reviews it? — Suggestions
  remain in the queue indefinitely until Admin action. There is no automatic expiry at v1.
- Can there be duplicate glossary terms? — No; the system must reject a new term if an
  identical term already exists (case-insensitive match).
- What content formats are supported in guides? — Rich text (headings, bold, bullet lists,
  embedded images). No video embeds at v1.

## Requirements *(mandatory)*

### Functional Requirements

**Fake Detection Guides**

- **FR-001**: Any authenticated member MUST be able to submit a Fake Detection Guide via
  a structured submission form. The form MUST include the following required sections:
  fragrance name, brand, and at least one of the structured content sections (box/packaging
  differences, bottle differences, scent profile differences, batch code guide). Each
  section MUST support text input and an optional image upload. At least one comparison
  photo (real vs. fake) MUST be uploaded across all sections before submission is allowed.
- **FR-002**: Every member-submitted guide MUST enter an Admin review queue with status
  "Pending Review". It MUST NOT appear publicly until Admin approves it.
- **FR-003**: Admin MUST be able to view all pending submissions in a review queue, edit
  any section of a submission, and either approve or reject it with a mandatory reason.
- **FR-004**: On approval, the guide MUST be published immediately to the public Fake
  Detection Guides list, credited as "Contributed by [member display name], reviewed by
  Admin", with publication date set to the approval date.
- **FR-005**: On rejection, the submitting member MUST see "Rejected" status and the
  rejection reason in their "My Submissions" view. The guide MUST NOT appear publicly.
- **FR-006**: Admin MUST also be able to author Fake Detection Guides directly (without
  a member submission). Admin-authored guides are published with "PFC Admin" credit.
- **FR-007**: Each Fake Detection Guide MUST include: fragrance name, brand, structured
  content sections with text and images, at least one comparison photo, publication date,
  last updated date, and contributor credit (member or Admin).
- **FR-008**: Fake Detection Guides MUST support draft status for Admin-authored guides —
  drafts are only visible in the Admin panel and MUST NOT appear publicly.
- **FR-009**: All published Fake Detection Guides MUST be publicly accessible without
  authentication.
- **FR-010**: The Fake Detection Guides list MUST support text search by fragrance name
  or brand.
- **FR-011**: Each guide MUST have a stable, shareable URL that remains valid after edits.
- **FR-012**: Only one published guide per fragrance name MUST exist at a time. The system
  MUST warn members submitting a guide for a fragrance that already has a published guide.

**Community Guides**

- **FR-013**: Admin MUST be able to create, edit, publish, unpublish, and delete Community
  Guides. No other role can perform these actions (community guide authoring is Admin-only
  at v1; member contributions to Community Guides are a future enhancement).
- **FR-014**: Each Community Guide MUST include: title, brief description (shown in list
  view), rich-text body, publication date, and last updated date.
- **FR-015**: Community Guides MUST support draft status with the same visibility rules
  as Fake Detection Guides (FR-008).
- **FR-016**: All published Community Guides MUST be publicly accessible without
  authentication and MUST support keyword search by title and body text.

**Glossary**

- **FR-017**: Admin MUST be able to add, edit, and delete Glossary terms directly. Changes
  take effect immediately.
- **FR-018**: Authenticated members MUST be able to submit term suggestions (term +
  definition) that enter an Admin review queue. Suggestions MUST NOT appear publicly
  until Admin approves them.
- **FR-019**: The Glossary MUST display all published terms in alphabetical order and
  MUST support real-time or on-submit text search by term name.
- **FR-020**: Duplicate terms (case-insensitive) MUST be rejected at submission for both
  Admin additions and member suggestions.
- **FR-021**: Each glossary term MUST have a stable, shareable URL.

### Key Entities

- **FakeDetectionGuide**: Authenticity guide for a specific fragrance. Attributes: fragrance
  name, brand, structured sections (each with text body and optional images), comparison
  photos (one or more), status (pending-review / draft / published / rejected), publication
  date, last updated date, submitted by (Member or Admin reference), approved by (Admin
  reference, nullable), contributor credit (display name or "PFC Admin"), stable slug/URL.
- **GuideSubmission**: Tracks a member's guide submission through the review lifecycle.
  Attributes: guide reference, submitter reference, submission date, review status (Pending
  Review / Approved / Rejected), reviewed by (Admin reference, nullable), review date
  (nullable), rejection reason (nullable).
- **CommunityGuide**: Admin-curated how-to article. Attributes: title, brief description,
  rich-text body, embedded images, status (draft / published), publication date, last
  updated date, author (Admin reference), stable slug/URL.
- **GlossaryTerm**: A community vocabulary entry. Attributes: term (unique, case-insensitive),
  definition, status (published / pending-review), submitted by (Admin or Member reference),
  approved by (Admin reference, if member-suggested), publication date.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An unauthenticated visitor can find and open a Fake Detection Guide — from
  landing on the Knowledge Base to reading the guide — in under 60 seconds.
- **SC-002**: All Knowledge Base sections (Guides, Community Guides, Glossary) load within
  2 seconds for unauthenticated visitors.
- **SC-003**: A member can complete and submit a Fake Detection Guide via the structured
  form — from opening the form to receiving a "Pending Review" confirmation — in under
  10 minutes.
- **SC-004**: An Admin can review, edit (if needed), and approve or reject a member-submitted
  guide in under 5 minutes.
- **SC-005**: Zero pending or rejected submissions are visible in the public Fake Detection
  Guides list.
- **SC-006**: 100% of published guides and glossary terms have stable, shareable URLs that
  do not break after edits.
- **SC-007**: A member's guide submission appears in the Admin review queue within 5 seconds
  of submission.

## Assumptions

- Fake Detection Guides can be submitted by any authenticated member via the structured
  form, then approved by Admin before publication. Community Guides remain Admin-authored
  only at v1. Glossary accepts member term suggestions with Admin approval.
- The structured submission form for Fake Detection Guides enforces a standard format:
  fragrance name, brand, and sectioned content (box/packaging differences, bottle
  differences, scent profile, batch code guide). This format is the same whether submitted
  by a member or authored directly by Admin.
- Rich text in guides supports headings, bold, italic, bullet lists, and embedded images.
  Video embeds, tables, and code blocks are not required at v1.
- The Fake Detection Guides and Community Guides are separate sections with different
  purposes, but share the same underlying admin authoring workflow.
- The fragrance encyclopedia (fragrance profiles with notes, longevity, sillage, and
  community fragrance reviews) is explicitly out of scope for v1. It may be introduced
  as a v2 feature once the community is large enough to populate it organically via
  an auto-aggregation model (fragrance profile pages auto-created from listing data).
- Glossary term search operates on the term name only (not the definition body) in the
  initial implementation; full-text definition search is a future enhancement.
- There is no community discussion or commenting on Knowledge Base articles at v1.
  Comments on guides are a future enhancement.
- The Knowledge Base is read-only for all non-Admin users, except for glossary term
  suggestions.
