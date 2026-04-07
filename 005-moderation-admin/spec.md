# Feature Specification: Moderation & Admin Tools

**Feature Branch**: `005-moderation-admin`
**Created**: 2026-03-18
**Status**: Draft
**Input**: User description: "Moderation and admin tools — member ban and suspension
management, scam and dispute report submission with system-assigned case ID and status
tracking visible to reporter, admin review and resolution workflow"

## Clarifications

### Session 2026-03-18

- Q: Can a report target a specific listing or review (in addition to the user), or does every report always target just a user? → A: Reports can optionally reference a specific listing or review in addition to the user — the target is optional so general user-level reports still work.
- Q: Should there be a limit on how many reports a single member can submit within a given time window? → A: Two-tier limit — soft cap: member is warned when they have 5 or more open/unresolved reports but may still submit after confirming; hard cap: maximum 10 report submissions per member per calendar day, after which further submissions are blocked until the next day.
- Q: How should the system handle two Admins acting on the same case simultaneously? → A: Last write wins — no locking. A complete, chronological activity log (status changes, notes added, actions taken, with Admin identity and timestamp) MUST be visible on the case detail page to all Admins so any Admin reviewing a case can see all prior actions before making a decision.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Member Submits a Scam or Dispute Report (Priority: P1)

A member has been scammed or has a dispute with another user — they paid for a fragrance
that never arrived, received a fake, or the seller is unresponsive. They file a report on
PFC, describing what happened and uploading any evidence (screenshots, photos). The system
immediately assigns a unique case ID and the member can track resolution status on their
end.

**Why this priority**: Scam reporting is the platform's primary safety enforcement mechanism
and a direct fulfilment of the Constitution's community safety principle. Without it, buyers
have no recourse and the platform has no visibility into bad actors.

**Independent Test**: A logged-in member can submit a scam report against a user, see a
unique case ID assigned immediately, and see the case status ("Open") on their reports page
— all before Admin takes any action.

**Acceptance Scenarios**:

1. **Given** a logged-in member opens the report form, **When** they select a report type
   (Scam / Dispute / Fake Listing / Other), name the reported user, optionally reference a
   specific listing or review, fill in a description, optionally attach evidence, and submit,
   **Then** the system assigns a unique case ID, sets status to "Open", and shows the member
   a confirmation with their case ID.
2. **Given** a report has been submitted, **When** the member visits "My Reports",
   **Then** they see all their submitted reports with case ID, report type, submission
   date, and current status (Open / Under Review / Resolved / Closed).
3. **Given** a member submits a report, **When** the report is created, **Then** the
   reported user is not notified — only Admin receives the alert.
4. **Given** a member tries to submit a report without filling in the description,
   **When** they attempt to submit, **Then** the system blocks submission and highlights
   the required field.
5. **Given** a member submits a report against a user they have already reported with
   an open case, **When** they try to create a duplicate report for the same listing/user,
   **Then** the system warns them that an open case already exists and shows the existing
   case ID, but still allows submission if they confirm.

---

### User Story 2 - Admin Reviews and Resolves a Report (Priority: P1)

An Admin opens the moderation queue, reviews incoming reports, investigates the evidence,
and takes action: resolving the case with a note, escalating it, or closing it as
unfounded. The reporter can see the status change and resolution note.

**Why this priority**: Reports are meaningless without an Admin workflow to act on them.
The queue and resolution flow are what give the system functional value.

**Independent Test**: An Admin can open the moderation queue, view a specific report with
all submitted details and evidence, change the status to "Under Review", add a resolution
note, mark it "Resolved", and the reporter immediately sees the updated status and note
on their end.

**Acceptance Scenarios**:

1. **Given** an Admin opens the moderation queue, **When** the page loads, **Then** all
   open reports are shown sorted by submission date (oldest first), each with case ID,
   report type, reported user, reporter, and submission date.
2. **Given** an Admin opens a specific report, **When** the detail page loads, **Then**
   they see: case ID, report type, description, any attached evidence, reporter identity,
   reported user identity (and optionally targeted listing/review), submission date, and a
   complete chronological activity log showing every status change and note added by any
   Admin, with the acting Admin's name and timestamp on each entry.
3. **Given** an Admin updates a case status (e.g., to "Under Review" or "Resolved"),
   **When** saved, **Then** the new status is immediately visible to the reporter on their
   "My Reports" page.
4. **Given** an Admin resolves a case, **When** they add a resolution note and mark it
   "Resolved", **Then** the note is visible to the reporter (without revealing any
   confidential Admin-only details).
5. **Given** an Admin closes a case as unfounded, **When** they add a closing reason and
   mark it "Closed", **Then** the reporter sees status "Closed" and the public-facing
   closing reason.
6. **Given** a non-Admin user attempts to access the moderation queue, **When** the action
   is attempted, **Then** the system denies access with a permission error.

---

### User Story 3 - Admin Bans a Member (Priority: P1)

An Admin bans a member following a confirmed scam, repeated violations, or other serious
misconduct. A banned member cannot log in, their listings are hidden from public view, and
their profile shows a "banned" indicator. The ban is permanent unless reversed by Admin.

**Why this priority**: Banning is the ultimate enforcement tool. Without it, confirmed
scammers remain active on the platform indefinitely.

**Independent Test**: An Admin bans a member; that member immediately cannot log in, their
published listings disappear from public browse and search, and their profile shows a
banned status.

**Acceptance Scenarios**:

1. **Given** an Admin opens a member's profile or a report case, **When** they click "Ban
   Member", enter a reason, and confirm, **Then** the member's account status is set to
   Banned, they are logged out of all active sessions immediately, and cannot log in again.
2. **Given** a member has been banned, **When** their published listings are viewed by
   any other user, **Then** the listings are hidden from public browse and search (but
   retained in Admin view for record purposes).
3. **Given** a banned member attempts to log in, **When** they submit their credentials,
   **Then** they see the message "Your account has been permanently banned. Contact support
   for more information." and are denied access.
4. **Given** an Admin reviews the ban history for a member, **When** the ban log is viewed,
   **Then** it shows: banned by (Admin reference), ban date, ban reason, and whether the
   ban has been reversed.

---

### User Story 4 - Admin Suspends a Member (Priority: P2)

An Admin issues a temporary suspension to a member for a less severe violation. During the
suspension period the member cannot log in, but the suspension lifts automatically on the
end date. Suspensions are an intermediate step between a warning and a permanent ban.

**Why this priority**: A permanent ban is a blunt instrument. Suspensions allow proportional
enforcement for first-time or minor violations — important for maintaining community trust
without being overly harsh.

**Independent Test**: An Admin suspends a member for 7 days; the member cannot log in during
that period, sees a suspension message with the end date, and can log in normally once the
suspension expires.

**Acceptance Scenarios**:

1. **Given** an Admin opens a member's profile, **When** they click "Suspend Member",
   enter a reason, set an end date, and confirm, **Then** the member's status is set to
   Suspended, they are logged out immediately, and cannot log in until the end date.
2. **Given** a suspended member attempts to log in, **When** they submit credentials,
   **Then** they see "Your account is suspended until [DATE]. Contact support for more
   information." and are denied access.
3. **Given** a suspension end date is reached, **When** the member next attempts to log in,
   **Then** their account is automatically reinstated and they can log in normally.
4. **Given** an Admin wants to lift a suspension early, **When** they click "Lift
   Suspension" on the member's profile and confirm, **Then** the member's status returns
   to Active immediately.

---

### User Story 5 - Admin Removes a Listing or Review (Priority: P2)

An Admin removes a specific listing (e.g., impression/clone, fraudulent listing) or a
review (e.g., fake review, abusive content) from public view. The removal is logged with
a reason. The seller or reviewer is not automatically notified but sees the content gone.

**Why this priority**: Banning a user is not always the right response — sometimes a single
piece of content needs to be removed without penalising the whole account. This is essential
for the impression/clone ban enforcement.

**Independent Test**: An Admin removes a published listing; it immediately disappears from
public browse and search, the seller's listing count decreases, and the removal is recorded
in the Admin action log with a reason.

**Acceptance Scenarios**:

1. **Given** an Admin views a published listing, **When** they click "Remove Listing",
   enter a reason, and confirm, **Then** the listing is immediately hidden from all public
   views and marked as "Removed by Admin" in the seller's listing history.
2. **Given** an Admin removes a review, **When** confirmed with a reason, **Then** the
   review is removed from the seller's profile and the average rating recalculates.
3. **Given** a listing or review has been Admin-removed, **When** the content creator
   views their own dashboard, **Then** they see the item marked "Removed" with a generic
   reason (e.g., "Violated community guidelines") but not the Admin's internal notes.
4. **Given** an Admin views the action log, **When** filtering by listing removals,
   **Then** every removal shows: content reference, removed by (Admin), removal date, and
   internal reason.

---

### User Story 6 - Admin Views the Full Moderation Dashboard (Priority: P2)

An Admin needs a single view to see all pending reports, recent bans, recent suspensions,
and recently removed content — to understand the health and safety state of the platform
at a glance.

**Why this priority**: Without a summary dashboard, Admin must navigate multiple separate
queues to understand what needs attention. A dashboard makes moderation sustainable as the
community grows.

**Independent Test**: An Admin opens the moderation dashboard and sees counts and recent
items for: open reports, bans issued this week, suspensions active now, and listings removed
this week — all from a single page.

**Acceptance Scenarios**:

1. **Given** an Admin opens the moderation dashboard, **When** the page loads, **Then**
   they see summary counts for: open reports, reports under review, active suspensions,
   and total bans to date.
2. **Given** an Admin views the dashboard, **When** they click any summary count,
   **Then** they are taken to the filtered list view for that category.
3. **Given** new reports are submitted, **When** the Admin views the dashboard,
   **Then** the open report count reflects the latest state without requiring a page
   refresh (or updates on next load at minimum).

---

### Edge Cases

- Can a banned user appeal? — At v1 there is no formal appeal workflow. The banned user
  sees a support contact message. Admin can manually reverse a ban at any time.
- What if two Admins update the same case simultaneously? — Last write wins; no locking is
  applied. Both actions are captured in the case activity log with their respective Admin
  identities and timestamps. Any Admin re-opening the case will see the full prior history
  before taking further action.
- What if the reported user is already banned when a report is reviewed? — The case can
  still be resolved; Admin marks it resolved with a note that the user is already banned.
- Can a member report an Admin? — No; the report system targets member accounts only.
  Admin accounts are managed at the platform operator level.
- Can the same listing be reported multiple times by different users? — Yes; each reporter
  gets their own case ID. Admin sees all reports linked to the same listing/user.
- What happens to an open report when the reported user is banned? — The case remains open
  until Admin explicitly resolves or closes it; banning does not auto-close reports.
- What if a suspension is set with a past end date by mistake? — The system must reject
  suspension end dates that are in the past or equal to today.
- What if a member hits the 10-report daily cap mid-submission? — The system blocks the
  submission, displays the daily limit message, and does not create a partial report. The
  member retains their data in the form until they navigate away.
- What if a member with 5+ open cases tries to submit without confirming the soft-cap
  warning? — Submission remains blocked at the confirmation step until they explicitly
  acknowledge the warning.
- Can Admin see who reported a user? — Yes, Admin sees full reporter identity. The reported
  user never sees who reported them.
- What happens to a suspended seller's active listings? — Listings remain visible during
  suspension (suspension is account access only). Admin can separately remove listings if
  needed.

## Requirements *(mandatory)*

### Functional Requirements

**Report Submission**

- **FR-001**: Any authenticated member MUST be able to submit a report. Report types MUST
  include: Scam, Dispute, Fake Listing, and Other. A report MUST always name a reported user.
  A report MAY additionally reference a specific listing or review as the subject of the
  complaint. The listing/review reference is optional — general user-level reports with no
  specific content target are permitted.
- **FR-002**: Every submitted report MUST receive a system-assigned unique case ID
  immediately upon submission.
- **FR-003**: Reports MUST require a description (mandatory). Evidence attachments
  (images, screenshots) are optional.
- **FR-003a**: A member MUST NOT be able to submit more than 10 reports per calendar day.
  Upon reaching the daily limit, further submission attempts MUST be blocked with a clear
  message until the next calendar day.
- **FR-003b**: If a member already has 5 or more open or unresolved reports at the time of
  submission, the system MUST display a warning ("You have 5 or more open cases. Are you
  sure you want to submit another?") and require an explicit confirmation before proceeding.
  This is a soft prompt — it does not block submission.
- **FR-004**: The reporter MUST be able to view all their submitted reports with case ID,
  report type, submission date, and current status on a "My Reports" page.
- **FR-005**: Report status MUST be visible to the reporter in real time (or on page
  load). Status values: Open, Under Review, Resolved, Closed.
- **FR-006**: Resolution notes added by Admin MUST be visible to the reporter. Internal
  Admin notes MUST NOT be visible to the reporter.
- **FR-007**: The reported user MUST NOT be notified when a report is filed against them.

**Admin Moderation Queue**

- **FR-008**: Admin MUST have access to a moderation queue showing all open and in-progress
  reports, sorted by submission date (oldest first) by default.
- **FR-009**: Admin MUST be able to filter the queue by report type and status.
- **FR-010**: Admin MUST be able to update case status (Open → Under Review → Resolved /
  Closed) and add both a public resolution note (visible to reporter) and an internal note
  (Admin-only).
- **FR-011**: Every action taken on a case — status changes, public resolution notes added,
  internal Admin notes added — MUST be recorded in an immutable activity log with the acting
  Admin's identity and a timestamp. This full activity log MUST be displayed on the case
  detail page in chronological order, visible to all Admin users, so any Admin reviewing or
  acting on the case can see the complete history of prior decisions before proceeding.
  Last-write-wins applies when two Admins act simultaneously; no locking mechanism is used.

**Bans**

- **FR-012**: Admin MUST be able to permanently ban any member account. A ban reason MUST
  be recorded.
- **FR-013**: A banned member MUST be immediately logged out of all active sessions and
  MUST NOT be able to log in again until the ban is reversed.
- **FR-014**: A banned member attempting to log in MUST see a clear suspension/ban message.
- **FR-015**: A banned member's published listings MUST be hidden from all public browse
  and search views. The listings are retained in Admin view.
- **FR-016**: Admin MUST be able to reverse a ban at any time, immediately restoring the
  member's login access.
- **FR-017**: All ban actions (ban and reversal) MUST be logged with Admin identity,
  timestamp, and reason.

**Suspensions**

- **FR-018**: Admin MUST be able to suspend a member for a defined period by setting a
  suspension end date. The end date MUST be in the future.
- **FR-019**: A suspended member MUST be immediately logged out and MUST NOT be able to
  log in until the suspension end date is reached or the suspension is lifted early.
- **FR-020**: A suspended member attempting to log in MUST see a message stating their
  account is suspended until a specific date.
- **FR-021**: Suspensions MUST expire automatically at the end date, restoring login
  access without Admin intervention.
- **FR-022**: Admin MUST be able to lift a suspension early at any time.
- **FR-023**: All suspension actions (suspend, lift, expiry) MUST be logged with Admin
  identity, timestamp, and reason.

**Content Removal**

- **FR-024**: Admin MUST be able to remove any published listing from public view, with a
  mandatory reason recorded internally. Removal MUST transition the listing's status to
  `Removed` (spec 008 FR-009) — a distinct sixth status value — hiding it from all public
  browse, search, and detail-page views while retaining the full record in Admin view.
  The seller sees it in their listing history as "Removed by Admin".
- **FR-025**: Admin MUST be able to remove any published review from a seller's profile,
  with a mandatory reason recorded internally.
- **FR-026**: Removed content MUST remain accessible to Admin for record purposes. It MUST
  NOT appear in any public view.
- **FR-027**: A content creator (seller or reviewer) MUST see their removed item marked
  "Removed" in their own dashboard with a generic public reason. Internal Admin notes MUST
  NOT be shown to them.
- **FR-028**: All content removal actions MUST be logged with Admin identity, content
  reference, timestamp, and internal reason.

**Moderation Dashboard**

- **FR-029**: Admin MUST have access to a moderation dashboard showing summary counts for:
  open reports, reports under review, active suspensions, and total bans.
- **FR-030**: Each dashboard summary MUST link to the corresponding filtered list view.

### Key Entities

- **Report**: A member's complaint about another user or content. Attributes: case ID
  (system-generated, unique), report type (Scam / Dispute / Fake Listing / Other),
  reporter reference, reported user reference (mandatory), target type (listing / review /
  none — nullable), target reference (listing or review ID — nullable; populated only when
  target type is listing or review), description, evidence attachments (optional), status
  (Open / Under Review / Resolved / Closed), public resolution note, internal Admin note,
  submission date, last updated date.
- **CaseActivityLog**: Immutable log of every action taken on a report — status changes,
  public notes added, internal notes added. Displayed in full on the case detail page to all
  Admins. Attributes: report reference, action type (status change / public note / internal
  note), previous status (nullable — only for status change entries), new status (nullable),
  note content (nullable — for note entries), performed by (Admin reference), timestamp.
- **BanRecord**: Permanent record of a member's ban. Attributes: member reference, banned
  by (Admin reference), ban date, ban reason, reversal date (nullable), reversed by
  (Admin reference, nullable).
- **SuspensionRecord**: Record of a temporary suspension. Attributes: member reference,
  suspended by (Admin reference), suspension date, suspension end date, reason, lifted
  early (boolean), lifted by (Admin reference, nullable), lift date (nullable).
- **ModerationActionLog**: Immutable audit log for all Admin moderation actions (content
  removals, bans, suspensions). Attributes: action type, target reference (user/listing/
  review), performed by (Admin reference), timestamp, internal reason.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A member can submit a scam or dispute report — from opening the form to
  receiving a case ID — in under 3 minutes.
- **SC-002**: 100% of submitted reports receive a unique case ID immediately upon
  submission (zero reports without a case ID).
- **SC-003**: A banned member is logged out of all sessions and cannot log in within
  5 seconds of the ban being applied.
- **SC-004**: A suspended member's login is restored automatically within 60 seconds of
  the suspension end date passing, with no Admin intervention.
- **SC-005**: 100% of Admin moderation actions (bans, suspensions, removals, status
  changes) are recorded in the audit log with timestamp and Admin identity.
- **SC-006**: The moderation queue is accessible to Admin and loads within 2 seconds.
- **SC-007**: A reporter can see a status update on their case within 5 seconds of Admin
  making the change.

## Assumptions

- There is no formal appeal workflow for bans at v1. Banned users see a support contact
  message and must contact Admin directly (e.g., via email). An appeal system is a future
  enhancement.
- A suspended seller's active listings remain publicly visible during the suspension period.
  Suspension only blocks login access. Admin can separately remove listings if needed.
- The report system targets member accounts and listings only. Reporting an Admin account
  is out of scope.
- Multiple users can report the same person or listing. Each generates a separate case with
  its own case ID. Admin sees all related reports linked to the same target.
- Evidence attachments on reports support the same formats as listing photos (images only).
  Document uploads (PDFs, screenshots as images) are supported; raw file types like .pdf
  are not required at v1.
- "Internal Admin notes" on cases are visible only to Admin users and are never shown to
  the reporter or the reported user.
- The moderation dashboard summary counts update on page load at minimum; real-time push
  updates are a future enhancement.
- Notification to reporters when their case status changes is out of scope for v1 (they
  must manually check "My Reports"). Email/push notifications are a future enhancement.
