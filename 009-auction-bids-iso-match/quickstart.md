# Quickstart: Auction Bidding, ISO Matching & Multi-Quantity

**Feature**: 009-auction-bids-iso-match
**Date**: 2026-03-18

---

## Prerequisites

- Node.js 18+
- npm or pnpm
- Supabase CLI (`npx supabase`)
- Supabase project (local or hosted)
- Next.js project initialized with Supabase client configured

## Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Next.js 14+ (App Router), React, TypeScript |
| Backend | Supabase (PostgreSQL, Auth, Realtime, Storage, Edge Functions) |
| Database | PostgreSQL 15+ (via Supabase) |
| Hosting | Vercel (frontend) + Supabase (backend) |
| Testing | Vitest, React Testing Library, Playwright |

## Setup Steps

### 1. Database Migration

Apply the migration that creates the `bids` and `auction_notifications` tables,
adds `auction_outcome_note` to `listings`, and creates all functions/triggers:

```bash
npx supabase migration new 009_auction_bids_iso_match
# Edit the generated SQL file with the migration from data-model.md
npx supabase db push        # hosted
# OR
npx supabase db reset       # local (resets and re-applies all migrations)
```

### 2. Enable Realtime

In Supabase Dashboard → Database → Replication, enable Realtime for:
- `bids` table (INSERT events)
- `auction_notifications` table (INSERT events)

Or via SQL:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE bids;
ALTER PUBLICATION supabase_realtime ADD TABLE auction_notifications;
```

### 3. Enable pg_cron

In Supabase Dashboard → Database → Extensions, enable `pg_cron`.

Then schedule the auction expiry job:
```sql
SELECT cron.schedule(
  'process-expired-auctions',
  '30 seconds',
  'SELECT process_expired_auctions()'
);
```

### 4. Environment Variables

```env
# Already set if Supabase is configured
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key  # server-side only
```

### 5. Key File Locations

```
src/
├── app/
│   └── listings/
│       └── [id]/
│           └── page.tsx          # Listing detail (renders auction/ISO/FB differently)
├── components/
│   ├── auction/
│   │   ├── BidForm.tsx           # Bid input + validation + submit
│   │   ├── BidList.tsx           # Live bid list with realtime subscription
│   │   ├── AuctionTimer.tsx      # Countdown to auction_end_at
│   │   └── AuctionResultPage.tsx # Post-close result view
│   ├── iso/
│   │   ├── SuggestedListings.tsx # Matching seller listings on ISO page
│   │   └── BuyersLookingFor.tsx  # Matching ISOs on seller listing page
│   ├── notifications/
│   │   ├── NotificationBell.tsx  # Nav bar unread count + dropdown
│   │   └── NotificationList.tsx  # Full notification list
│   └── listings/
│       └── QuantityControl.tsx   # Quantity input for FB/Decant
├── lib/
│   ├── supabase/
│   │   ├── client.ts             # Browser Supabase client
│   │   └── server.ts             # Server-side Supabase client
│   └── actions/
│       ├── bids.ts               # placeBid server action
│       ├── listings.ts           # updateQuantity, setOutcomeNote
│       └── notifications.ts     # markRead, markAllRead
└── hooks/
    ├── useBidSubscription.ts     # Realtime bid list hook
    └── useNotifications.ts       # Realtime notification hook

supabase/
├── migrations/
│   └── 20260318_009_auction_bids_iso_match.sql
└── config.toml
```

## Testing

```bash
# Unit tests (Vitest)
npx vitest run src/lib/actions/

# Component tests (Vitest + RTL)
npx vitest run src/components/auction/

# E2E tests (Playwright)
npx playwright test tests/e2e/auction.spec.ts
npx playwright test tests/e2e/iso-matching.spec.ts
npx playwright test tests/e2e/multi-quantity.spec.ts
```

## Verification Checklist

- [ ] A logged-in user can place a bid on an active auction (bid appears in list immediately)
- [ ] Bid below minimum is rejected with correct minimum amount shown
- [ ] Listing owner cannot see bid button on their own auction
- [ ] Unauthenticated visitors see full bid list but get login prompt on bid attempt
- [ ] When auction_end_at passes, listing transitions to Expired within 60 seconds
- [ ] All bidders receive "auction closed" notification within 60 seconds of expiry
- [ ] Seller can add outcome note on expired auction (visible on result page)
- [ ] Seller can message any bidder from listing history after close
- [ ] Marking auction as Sold sends second notification to all bidders
- [ ] ISO listing shows "Suggested Listings" with matching published listings
- [ ] Non-ISO listing shows "Buyers Looking For This" (hidden when no matches)
- [ ] Member (non-Seller) can create ISO listing; other types are disabled
- [ ] Full Bottle listing supports quantity > 1; quantity shows on listing card
- [ ] Setting quantity to 0 auto-transitions listing to Sold
