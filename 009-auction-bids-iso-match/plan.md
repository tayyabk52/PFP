# Implementation Plan: Auction Bidding, ISO Matching & Multi-Quantity

**Branch**: `009-auction-bids-iso-match` | **Date**: 2026-03-18 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/009-auction-bids-iso-match/spec.md`

## Summary

This feature adds three enhancements to the PFC marketplace:

1. **Auction Bidding** — a public, real-time bidding system on Auction-type listings. Buyers place non-retractable bids (PKR 500 minimum increment), all bids are publicly visible, and the seller chooses their preferred bidder after close. An Auction Result Page auto-renders on close with full bid history, an optional seller outcome note, and in-platform notifications to all bidders on close and on Sold.

2. **ISO Matching** — two-way computed discovery between ISO listings and matching published listings. "Suggested Listings" appears on ISO pages; "Buyers Looking For This" appears on non-ISO pages (hidden when no matches). ISO creation is opened to all authenticated Members (not just Verified Sellers).

3. **Full Bottle Multi-Quantity** — sellers with multiple identical bottles list them under one listing with a decrementable quantity counter. Auto-transitions to Sold when quantity reaches 0. Extends the existing Decant/Split quantity model.

**Technical approach**: PostgreSQL database functions for atomic bid placement and auction expiry processing, Supabase Realtime for live bid updates and notification delivery, on-demand queries for ISO matching, and database triggers for auto-Sold transitions.

## Technical Context

**Language/Version**: TypeScript 5.x (strict mode)
**Frontend**: Next.js 14+ (App Router, React 18+)
**Backend/BaaS**: Supabase (PostgreSQL 15+, Auth, Realtime, Storage, Edge Functions)
**Storage**: Supabase Storage (photo uploads); PostgreSQL for all relational data
**Testing**: Vitest + React Testing Library (unit/component), Playwright (E2E)
**Target Platform**: Web (SSR via Next.js for SEO on listing pages)
**Project Type**: Web application (marketplace)
**Hosting**: Vercel (frontend) + Supabase (backend)
**Performance Goals**: Bid placement < 1s round-trip; bid list update < 5s; ISO matching query < 2s; notification delivery < 60s
**Constraints**: <1,000 concurrent users; YAGNI; in-platform notifications only (no email/SMS); off-platform payments (PKR)
**Scale/Scope**: <1,000 users at launch; ~5,000 listings; ~50 concurrent auction viewers max

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Pre-Phase 0 | Post-Phase 1 | Notes |
|---|-----------|-------------|-------------|-------|
| I | Transparency-First | PASS | PASS | All bids publicly visible (FR-004). Auction Result Page shows full ranked bid list to unauthenticated visitors (FR-022). Prices visible on all listings. No inbox-for-price. |
| II | Trust Through Verified Identity | PASS | PASS | Bidder display names shown publicly (FR-003). ISO exception for Members explicitly scoped — only ISO type, all others require Verified Seller (FR-009). Role enforcement via Supabase RLS. |
| III | Community Safety | PASS | PASS | ISO listings require impression declaration. Bids non-retractable (FR-003). Banned bidder handling documented. place_bid() function enforces all rules atomically. |
| IV | Transaction-Ready Architecture | PASS | PASS | New tables (bids, auction_notifications) don't affect the 5 transaction-ready fields on listings. auction_outcome_note is a new nullable column — no existing fields modified. Sold transition still increments transaction count. |
| V | Mandatory Listing Completeness | PASS | PASS | ISO listings still require all mandatory fields. Full Bottle quantity is an additional editable field, not a replacement. No mandatory field removed or relaxed. |
| VI | Simplicity & Incremental Delivery | PASS | PASS | ISO matching is a live query — no materialized views, no background sync. Notifications in-platform only. PKR 500 increment is a constant. pg_cron for expiry (no external scheduler). All designed for <1,000 users. |

**Gate result: ALL PASS. No violations.**

## Project Structure

### Documentation (this feature)

```text
specs/009-auction-bids-iso-match/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: technology decisions
├── data-model.md        # Phase 1: database schema
├── quickstart.md        # Phase 1: setup guide
├── contracts/
│   └── api.md           # Phase 1: API contracts
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
src/
├── app/
│   ├── (auth)/                    # Auth routes (login, signup, profile setup)
│   ├── (public)/
│   │   └── marketplace/           # Browse, search (spec 002)
│   ├── listings/
│   │   └── [id]/
│   │       └── page.tsx           # Listing detail — renders per type:
│   │                              #   Auction: bid list, bid form, timer, result page
│   │                              #   ISO: suggested listings section
│   │                              #   Non-ISO: buyers looking for this section
│   │                              #   Full Bottle/Decant: quantity display
│   ├── dashboard/                 # Member dashboard
│   ├── seller/
│   │   ├── dashboard/             # Seller dashboard
│   │   └── listings/
│   │       └── [id]/
│   │           └── manage/        # Manage listing: quantity, outcome note, mark sold
│   └── admin/                     # Admin panel
├── components/
│   ├── ui/                        # Base UI components (buttons, inputs, cards)
│   ├── auction/
│   │   ├── BidForm.tsx            # Bid input + validation + confirmation
│   │   ├── BidList.tsx            # Real-time bid list with subscription
│   │   ├── AuctionTimer.tsx       # Countdown to auction_end_at
│   │   ├── AuctionResultBanner.tsx # "Auction Closed" / "Sold" banner
│   │   └── OutcomeNote.tsx        # Seller's optional post-close note
│   ├── iso/
│   │   ├── SuggestedListings.tsx  # Matching listings on ISO detail page
│   │   └── BuyersLookingFor.tsx   # Matching ISOs on non-ISO detail page
│   ├── notifications/
│   │   ├── NotificationBell.tsx   # Nav bar icon with unread count
│   │   └── NotificationList.tsx   # Dropdown/page with all notifications
│   └── listings/
│       ├── QuantityControl.tsx    # Editable quantity for FB/Decant
│       └── QuantityBadge.tsx      # "3 available" badge on listing cards
├── lib/
│   ├── supabase/
│   │   ├── client.ts              # Browser Supabase client (singleton)
│   │   └── server.ts              # Server-side Supabase client (per-request)
│   ├── actions/
│   │   ├── bids.ts                # placeBid server action
│   │   ├── listings.ts            # updateQuantity, setOutcomeNote, markSold
│   │   └── notifications.ts      # markRead, markAllRead
│   └── queries/
│       ├── bids.ts                # fetchBidsForListing
│       ├── iso-matching.ts        # fetchSuggestedListings, fetchBuyersLooking
│       └── notifications.ts      # fetchNotifications, fetchUnreadCount
├── hooks/
│   ├── useBidSubscription.ts      # Realtime hook for bid list
│   ├── useNotifications.ts        # Realtime hook for notification bell
│   └── useAuctionTimer.ts         # Client-side countdown hook
└── types/
    ├── bid.ts                     # Bid type definitions
    ├── notification.ts            # AuctionNotification type definitions
    └── listing.ts                 # Extended listing types (quantity, outcome note)

supabase/
├── migrations/
│   └── 20260318_009_auction_bids_iso_match.sql  # All tables, functions, triggers, cron
├── seed.sql                                       # Test data for development
└── config.toml                                    # Supabase project config

tests/
├── unit/
│   ├── actions/                   # Server action tests
│   └── queries/                   # Query function tests
├── integration/
│   └── database/                  # Database function tests (place_bid, expiry)
└── e2e/
    ├── auction-bidding.spec.ts    # Full auction lifecycle E2E
    ├── iso-matching.spec.ts       # ISO creation + matching E2E
    └── multi-quantity.spec.ts     # Quantity management E2E
```

**Structure Decision**: Web application layout with Next.js App Router. Frontend and backend (Supabase) are logically separate — the `src/` directory contains the Next.js application, `supabase/` contains database migrations, functions, and config. The `specs/` directory holds all feature specifications and plans. Feature components are organized by domain (`auction/`, `iso/`, `notifications/`, `listings/`) rather than by technical layer, keeping related UI close together.

## Complexity Tracking

No violations. No entries needed.
