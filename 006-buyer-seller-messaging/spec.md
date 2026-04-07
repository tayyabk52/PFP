# Feature Specification: Buyer-Seller Messaging

**Feature Branch**: `006-buyer-seller-messaging`
**Created**: 2026-03-18
**Status**: Draft
**Input**: User description: "A message or conversation between buyers and sellers to
discuss specific listings. One thread per buyer-seller pair with multiple listing
references to avoid duplicate threads. Real-time message delivery."

**Conversation model decision**: Conversations are scoped to a buyer-seller pair — one
thread per pair regardless of how many listings are involved. The first message is always
initiated from a specific listing page and that listing is tagged to the thread. The buyer
can attach additional listings from the same seller to the existing thread at any time,
keeping all discussion in one place. This avoids inbox clutter and duplicate threads.

**Dependency on spec 002**: The listing detail page (feature 002) requires a
"Message Seller" call-to-action that initiates or opens an existing conversation,
pre-tagged with that listing. This spec defines the messaging behaviour; spec 002 owns
the listing page layout.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Buyer Initiates a Conversation from a Listing (Priority: P1)

A buyer sees a listing they are interested in and wants to ask the seller a question —
about condition, shipping cost, or whether they would negotiate price. They click
"Message Seller" on the listing page. If no conversation exists between them yet, a new
thread is created pre-tagged with that listing. If a thread already exists, they are taken
directly to the existing thread with the listing added as a reference if not already
present.

**Why this priority**: Initiating contact is the entry point of the entire messaging
feature. Without it, buyers have no way to reach sellers.

**Independent Test**: A logged-in member clicks "Message Seller" on a listing, sends a
message, and the seller receives it in their inbox with the listing reference visible in
the thread.

**Acceptance Scenarios**:

1. **Given** a logged-in member views a listing and clicks "Message Seller", **When** no
   prior conversation exists between them and the seller, **Then** a new conversation thread
   is created pre-tagged with that listing and the buyer is taken to the thread to type
   their first message.
2. **Given** a logged-in member clicks "Message Seller" on a listing when a conversation
   with that seller already exists, **When** the action is triggered, **Then** the existing
   thread opens and the listing is added as a reference if not already tagged; no duplicate
   thread is created.
3. **Given** a buyer sends their first message, **When** sent, **Then** the message appears
   in the thread immediately and the seller sees an unread conversation indicator in their
   inbox.
4. **Given** an unauthenticated visitor clicks "Message Seller", **When** triggered,
   **Then** they are prompted to log in before a conversation can be started.
5. **Given** a buyer attempts to message their own listing (seller trying to message
   themselves), **When** triggered, **Then** the "Message Seller" button is not shown to
   the listing owner.

---

### User Story 2 - Both Parties Exchange Messages in Real Time (Priority: P1)

A buyer and seller are actively discussing a listing in a thread. Messages sent by either
party appear in the conversation immediately without requiring a page refresh. Both parties
can see the full message history for that thread.

**Why this priority**: Real-time delivery is the minimum quality bar for messaging to feel
usable. Stale or delayed messages make negotiation impractical.

**Independent Test**: A buyer sends a message; the seller — with the conversation open in
another browser window — sees the message appear within 2 seconds without refreshing.

**Acceptance Scenarios**:

1. **Given** both buyer and seller have the conversation open, **When** either party sends
   a message, **Then** the message appears in both views within 2 seconds without requiring
   a page refresh.
2. **Given** a user opens a conversation thread, **When** the thread loads, **Then** the
   full message history is shown in chronological order (oldest at top, newest at bottom).
3. **Given** a user sends a message, **When** it is delivered, **Then** the message shows
   a sent timestamp. Messages read by the recipient show a "read" indicator.
4. **Given** a user is not actively viewing the conversation, **When** a new message
   arrives, **Then** an unread count indicator updates in their inbox/navigation without
   requiring a page refresh.

---

### User Story 3 - Buyer Adds Another Listing to an Existing Thread (Priority: P2)

A buyer is already in a conversation with a seller about one listing and notices another
listing from the same seller they want to ask about. Instead of starting a new thread,
they add the second listing as a reference to the existing conversation.

**Why this priority**: This is the key mechanism that prevents inbox clutter and duplicate
threads. Without it, buyers would start a new thread per listing, fragmenting the
conversation.

**Independent Test**: A buyer in an existing conversation with a seller clicks "Add
listing to this conversation", selects another listing from that seller, and the listing
appears as a tagged reference in the thread — visible to both parties — without a new
thread being created.

**Acceptance Scenarios**:

1. **Given** a buyer is viewing a conversation with a seller, **When** they click "Add
   listing to this conversation" and select another listing from the same seller, **Then**
   the listing is added as a reference to the thread and both parties can see it tagged
   in the conversation.
2. **Given** a buyer views a second listing from a seller they have an existing thread
   with, **When** they click "Message Seller" on that listing, **Then** the existing thread
   opens with the new listing added as a reference (same as US1 scenario 2).
3. **Given** a buyer tries to add a listing from a different seller to an existing thread,
   **When** triggered, **Then** the system rejects the action — listing references in a
   thread must all belong to the same seller as the thread's seller participant.
4. **Given** a listing already referenced in the thread is added again, **When** triggered,
   **Then** the system silently ignores the duplicate and does not add it twice.

---

### User Story 4 - User Views Their Conversation Inbox (Priority: P2)

A user (buyer or seller) opens their inbox to see all their active conversations. Each
conversation entry shows the other party's name, the most recent message preview, the
time of the last message, and an unread count if there are unread messages.

**Why this priority**: Without an inbox, users have no way to return to previous
conversations or know when new messages have arrived.

**Independent Test**: A seller with 3 active buyer conversations opens their inbox and
sees all 3 threads listed with the correct other-party name, last message preview, and
unread count for any with unread messages.

**Acceptance Scenarios**:

1. **Given** a logged-in user opens their inbox, **When** the page loads, **Then** all
   their conversations are shown sorted by most recent message first, each showing: the
   other party's display name, last message text preview (truncated), time of last message,
   and unread message count if any.
2. **Given** a user has no conversations, **When** they open the inbox, **Then** a clear
   "No conversations yet" message is shown.
3. **Given** a user clicks a conversation in the inbox, **When** the thread opens, **Then**
   the unread count for that conversation resets to zero and the messages are marked read.
4. **Given** a new message arrives in any thread, **When** the inbox is viewed, **Then**
   the updated thread moves to the top of the list with the latest message preview.

---

### User Story 5 - User Deletes or Archives a Conversation (Priority: P3)

A buyer or seller wants to clean up their inbox by removing a completed or unwanted
conversation. They can delete the thread from their own view; the other party's copy
is unaffected.

**Why this priority**: Inbox management is a quality-of-life feature. Not required for
launch but prevents inbox becoming cluttered over time.

**Independent Test**: A buyer deletes a conversation; it disappears from their inbox but
the seller can still see the full thread in their own inbox.

**Acceptance Scenarios**:

1. **Given** a user views a conversation, **When** they delete it and confirm, **Then** the
   conversation is removed from their inbox only. The other party's thread and full message
   history are unaffected.
2. **Given** a user has deleted a conversation, **When** the other party sends a new message,
   **Then** the deleted conversation reappears in the deleting party's inbox with the new
   message (deletion does not block future messages).

---

### Edge Cases

- Can a seller initiate a conversation? — No, with one specific exception. In general,
  only buyers initiate and sellers respond to incoming threads. Sellers do not have a
  "Message Buyer" button for cold outreach. The exception: after an Auction listing closes
  (Expired status), the seller MAY initiate a conversation with any bidder directly from
  their listing history view. A bidder's prior bid constitutes expressed intent, making
  post-close seller contact non-cold-outreach. This exception is defined in spec 009
  FR-026. In all other contexts, sellers respond only.
- Can the poster of an ISO listing be contacted directly? — No. ISO posters (acting as
  buyers) initiate contact themselves — they navigate to a matching seller's listing via
  "Suggested Listings" and use the standard "Message Seller" button. There is no "Message
  Poster" button on non-ISO listing pages for third parties to contact an ISO poster.
- What if a listing is deleted or sold while a conversation referencing it is active?
  — The listing reference in the thread shows as "Listing no longer available" but the
  conversation and all messages remain intact.
- What if a listed seller is banned while a conversation is active? — The conversation
  becomes read-only for the buyer (they can view history but cannot send new messages).
  The banned seller cannot log in at all.
- Is there a message length limit? — Yes; each message is capped at 1,000 characters.
- Can users send images or files in messages? — No; text only at v1. Image sharing
  is a future enhancement.
- What if a buyer is suspended mid-conversation? — Same as ban: conversation becomes
  read-only for both parties until suspension expires.
- Can Admin read private conversations? — No at v1; conversations are private between
  participants. Admin access to conversation content for dispute resolution is a future
  moderation enhancement.
- Is there a limit on how many listing references a thread can have? — Capped at 10
  listing references per thread to prevent abuse.

## Requirements *(mandatory)*

### Functional Requirements

**Conversation Initiation & Threading**

- **FR-001**: A logged-in member MUST be able to initiate a conversation by clicking
  "Message Seller" on any published listing they do not own.
- **FR-002**: The system MUST enforce one conversation thread per buyer-seller pair.
  If a thread already exists between the two parties, clicking "Message Seller" on any
  listing MUST open the existing thread and add the listing as a reference if not already
  present — no duplicate thread MUST be created.
- **FR-003**: Every conversation MUST be tagged with at least one listing reference (the
  listing from which it was initiated). Standalone conversations not tied to any listing
  are not permitted.
- **FR-004**: Listing references in a thread MUST all belong to the same seller (the seller
  participant of that thread). Cross-seller listing references are not permitted.
- **FR-005**: A buyer MUST be able to add additional listings from the same seller to an
  existing thread, up to a maximum of 10 listing references per thread.
- **FR-006**: The "Message Seller" button MUST NOT be visible to the listing's owner.
  Unauthenticated visitors clicking it MUST be redirected to log in.

**Message Delivery & History**

- **FR-007**: Messages MUST be delivered to the recipient in real time (without requiring
  a page refresh) when both parties have the conversation open.
- **FR-008**: Full message history for a thread MUST be persisted and available to both
  participants on every visit. Messages are not ephemeral.
- **FR-009**: Each message MUST display a sent timestamp. Messages seen by the recipient
  MUST show a "read" indicator visible to the sender.
- **FR-010**: Messages are text only at v1. Maximum length per message is 1,000 characters.
  Image or file attachments are not supported.

**Inbox**

- **FR-011**: Every authenticated user MUST have an inbox showing all their conversations,
  sorted by most recent message first.
- **FR-012**: Each inbox entry MUST show: other party's display name, last message preview
  (truncated to ~60 characters), time of last message, and unread message count.
- **FR-013**: Unread message counts MUST update in real time without requiring a page
  refresh. Opening a thread MUST mark all its messages as read and reset the count to zero.

**Listing Reference Display**

- **FR-014**: Listing references tagged to a thread MUST be displayed visibly within the
  conversation view showing: listing sale post number, fragrance name, type, and price.
- **FR-015**: If a referenced listing is deleted, sold, or expired, its reference in the
  thread MUST display as "Listing no longer available" and the conversation MUST remain
  fully accessible.

**Deletion**

- **FR-016**: A user MUST be able to delete a conversation from their own inbox. Deletion
  is one-sided — the other party's thread and message history are unaffected.
- **FR-017**: If a new message is sent to a deleted conversation, it MUST reappear in
  the deleting party's inbox with the new message.

**Access Control**

- **FR-018**: Only the two participants of a conversation MUST be able to read its
  messages. No other user, including Admin, can access conversation content at v1.
- **FR-019**: If either participant is banned or suspended, the conversation MUST become
  read-only for both parties until the restriction is lifted.

### Key Entities

- **Conversation**: A private thread between exactly one buyer and one seller. Attributes:
  buyer reference, seller reference, created date, last message date, listing references
  (one to ten, all belonging to the seller), status (active / read-only).
- **Message**: A single text message within a conversation. Attributes: conversation
  reference, sender reference, text content (max 1,000 chars), sent timestamp, read
  status (unread / read), read timestamp (nullable).
- **ConversationListingRef**: A listing attached to a conversation as context. Attributes:
  conversation reference, listing reference, attached date, display status (available /
  unavailable — updated when listing is deleted, sold, or expired).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A buyer can initiate a conversation from a listing and send their first
  message in under 60 seconds.
- **SC-002**: Messages are delivered and visible to the recipient within 2 seconds when
  both parties have the conversation open.
- **SC-003**: Zero duplicate conversation threads exist between the same buyer-seller pair.
- **SC-004**: Unread message counts in the inbox update within 3 seconds of a new message
  arriving, without requiring a page refresh.
- **SC-005**: Full message history for any conversation loads within 2 seconds.
- **SC-006**: A listing reference marked unavailable (deleted/sold/expired listing)
  is reflected in the conversation view within 5 seconds of the listing status changing.

## Assumptions

- Only buyers initiate conversations; sellers respond. Sellers do not have a "cold outreach"
  button to start conversations with buyers proactively at v1.
- Conversations are strictly private (two-party). Group conversations or broadcast
  messages are out of scope.
- Real-time message delivery relies on the database platform's real-time broadcast
  capability (to be specified in the plan stage). If the recipient is offline, messages
  are stored and shown on their next visit — there are no push/email notifications at v1.
- Text-only messages at v1. Photo sharing in messages is a future enhancement.
- Admin cannot read conversation content at v1. Providing conversation logs to Admin for
  dispute resolution is a future moderation enhancement (requires privacy policy update).
- Message cap of 1,000 characters per message is a v1 default; adjustable in future.
- Listing reference cap of 10 per thread is a practical abuse prevention measure.
- There is no message search within conversations at v1.
- The "Message Seller" CTA on listing detail pages is defined by this spec but the
  visual placement on the listing page is owned by spec 002 (Marketplace Listings).
  Spec 002 must be updated at plan stage to include this touch-point.
