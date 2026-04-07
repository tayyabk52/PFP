# PFC Platform — Design Specification
**Date:** 2026-03-22 (updated)
**Project:** Pakistan Fragrance Community (PFC)
**Platform:** Flutter — web + mobile, single codebase

---

## 1. Overview

PFC is a structured platform for Pakistani fragrance enthusiasts that complements the existing PFC Facebook group. It does not replace Facebook — it adds features FB cannot offer: a verified marketplace, seller trust system, scam reporting, and a fragrance knowledge base.

**Launch target:** Under 1,000 users, web + mobile simultaneously.
**Monetisation:** Free at launch. Commission model introduced later (infrastructure built in from day one).
**Payments:** Off-platform only (EasyPaisa, JazzCash, bank transfer). Platform does not mediate payments.

---

## 2. Current Build State (as of 2026-03-22)

### Completed
| Area | Status |
|---|---|
| Flutter project setup, theme system (AppColors, AppTextStyles, AppTheme) | ✅ Done |
| AppShell — adaptive layout (desktop sidebar, tablet icon-sidebar, mobile bottom nav) | ✅ Done |
| Landing page (`/`) — hero, sign in, register, browse links | ✅ Done |
| Auth — login page (email + password) | ✅ Done |
| Auth — register page (name, email, password, OTP inline, role selector) | ✅ Done |
| Route guards — pure `RouteGuards.getRedirect()` + full test coverage | ✅ Done |
| Seller apply flow — `/register/seller-apply` (CNIC upload, full form, Supabase submit) | ✅ Done |
| Verification status page — `/dashboard/verification` (premium responsive redesign) | ✅ Done |
| Supabase — `cnic-docs` storage bucket, RLS policies, table-level GRANTs | ✅ Done |
| Post-seller-apply redirect fix — provider invalidation + route bypass | ✅ Done |

### Remaining (all currently StubPage)
Marketplace, listing detail, create listing, sellers list, seller profile, dashboard home, my listings, my ISO posts, messages, profile, reviews, reports, knowledge base, admin panel (all routes).

---

## 3. User Roles

| Role | Access |
|---|---|
| **Member** | Browse, buy, post reviews, report scams, submit ISO posts, message sellers |
| **Seller** | All member permissions + create listings. Requires admin-approved verification. |
| **Admin** | Full control: bans, suspensions, seller verification, content management, dispute resolution |

Role stored in `profiles.role` (`member` | `seller` | `admin`). Always read from Supabase — never stored in local state.

---

## 4. Tech Stack

| Concern | Choice | Reason |
|---|---|---|
| Framework | Flutter (web + mobile) | Single codebase, adaptive layout already built |
| Backend | Supabase | Postgres relations, Auth, Storage, Realtime |
| State management | Riverpod | Compile-safe, handles async Supabase streams, role-based access |
| Navigation | go_router | Official Flutter recommendation, route guards |
| Theme | Deep Emerald + Light Grey ("Olfactory Archive") | Premium, heritage feel |
| Navigation layout | AppShell — persistent sidebar (desktop), icon sidebar (tablet), bottom nav (mobile) | Already implemented |

---

## 5. Architecture — Feature-First

```
lib/
├── core/
│   ├── router/
│   │   ├── app_router.dart          ← go_router config + redirect guards ✅
│   │   └── route_guards.dart        ← pure redirect logic, fully tested ✅
│   ├── supabase/
│   │   └── supabase_client.dart     ← Supabase singleton ✅
│   ├── theme/
│   │   ├── app_theme.dart           ✅
│   │   ├── app_colors.dart          ✅
│   │   └── app_text_styles.dart     ✅
│   └── widgets/
│       ├── app_shell.dart           ← adaptive sidebar/bottom-nav shell ✅
│       ├── sidebar.dart             ✅
│       ├── bottom_nav.dart          ✅
│       ├── stub_page.dart           ← placeholder (replaced as features ship)
│       └── app_button.dart
│
├── features/
│   ├── auth/                        ✅ Done
│   │   ├── data/auth_repository.dart
│   │   ├── providers/
│   │   │   ├── auth_provider.dart
│   │   │   └── profile_provider.dart
│   │   └── pages/
│   │       ├── login_page.dart
│   │       ├── register_page.dart
│   │       └── widgets/ (auth_card, auth_text_field)
│   │
│   ├── landing/                     ✅ Done
│   │   └── landing_page.dart
│   │
│   ├── seller_apply/                ✅ Done
│   │   ├── data/seller_apply_repository.dart
│   │   └── pages/
│   │       ├── seller_apply_page.dart
│   │       └── verification_status_page.dart
│   │
│   ├── marketplace/                 ← NEXT
│   │   ├── data/
│   │   │   ├── listing_repository.dart
│   │   │   └── models/listing_model.dart
│   │   ├── providers/
│   │   │   └── listing_provider.dart
│   │   └── pages/
│   │       ├── marketplace_page.dart
│   │       ├── listing_detail_page.dart
│   │       ├── create_listing_page.dart
│   │       └── widgets/listing_card.dart
│   │
│   ├── sellers/
│   │   └── pages/
│   │       ├── sellers_list_page.dart
│   │       └── seller_profile_page.dart
│   │
│   ├── dashboard/
│   │   └── pages/
│   │       ├── dashboard_home_page.dart
│   │       ├── my_listings_page.dart
│   │       ├── my_profile_page.dart
│   │       ├── my_reviews_page.dart
│   │       ├── reports_page.dart
│   │       └── iso_page.dart
│   │
│   ├── messaging/
│   │   ├── data/messaging_repository.dart
│   │   ├── providers/messaging_provider.dart
│   │   └── pages/
│   │       ├── inbox_page.dart
│   │       └── conversation_page.dart
│   │
│   ├── knowledge_base/
│   │   └── pages/
│   │       ├── knowledge_home_page.dart
│   │       ├── community_guides_page.dart
│   │       ├── fake_detection_guide_page.dart
│   │       └── glossary_page.dart
│   │
│   └── admin/
│       └── pages/
│           ├── admin_home_page.dart
│           ├── user_management_page.dart
│           ├── seller_applications_page.dart
│           ├── seller_application_detail_page.dart
│           ├── listing_moderation_page.dart
│           ├── reports_tracker_page.dart
│           └── knowledge_management_page.dart
│
└── main.dart
```

---

## 6. Pages & Routes

### Public (unauthenticated)
| Route | Page | Status |
|---|---|---|
| `/` | Landing — hero, featured listings, legit sellers preview | ✅ Done |
| `/login` | Login | ✅ Done |
| `/register` | Register + OTP inline + role selector | ✅ Done |
| `/marketplace` | Browse listings — filterable grid | Stub |
| `/marketplace/:id` | Listing detail | Stub |
| `/sellers` | Legit sellers list (searchable) | Stub |
| `/sellers/:code` | Seller public profile | Stub |
| `/knowledge` | Knowledge base home | Stub |
| `/knowledge/guides` | Community guides | Stub |
| `/knowledge/fake-detection/:slug` | Fake detection guide | Stub |
| `/knowledge/glossary` | Glossary dictionary | Stub |

### Registration Flow (auth-required, no sidebar)
| Route | Page | Status |
|---|---|---|
| `/register/seller-apply` | Seller application — CNIC upload, details | ✅ Done |

### Member Dashboard (auth-gated, AppShell)
| Route | Page | Status |
|---|---|---|
| `/dashboard` | Home — recent listings, activity | Stub |
| `/dashboard/my-listings` | My listings (non-ISO) | Stub |
| `/dashboard/create-listing` | Create listing (seller only) | Stub |
| `/dashboard/messages` | Inbox | Stub |
| `/dashboard/messages/:id` | Conversation thread | Stub |
| `/dashboard/profile` | Profile & settings | Stub |
| `/dashboard/reviews` | My received reviews | Stub |
| `/dashboard/reports` | Submit + track scam reports | Stub |
| `/dashboard/iso` | My ISO posts | Stub |
| `/dashboard/verification` | Seller application status | ✅ Done |

### Admin (role-gated, AppShell isAdmin)
| Route | Page | Status |
|---|---|---|
| `/admin` | Admin overview | Stub |
| `/admin/users` | User management | Stub |
| `/admin/sellers` | Verified sellers list | Stub |
| `/admin/sellers/applications` | Applications list | Stub |
| `/admin/sellers/applications/:id` | Review application | Stub |
| `/admin/listings` | Listing moderation | Stub |
| `/admin/reports` | Dispute/case tracker | Stub |
| `/admin/knowledge` | Guides + glossary management | Stub |

---

## 7. Route Guards

Enforced in `RouteGuards.getRedirect()` (pure, fully tested):

```
Unauthenticated  → /dashboard/*, /admin/*, /register/seller-apply → /login or /register

Member           → /admin/* → /dashboard
                   /dashboard/create-listing → /dashboard
                   /register/seller-apply with existing application → /dashboard/verification

Seller           → /admin/* → /dashboard
                   /dashboard/create-listing allowed
                   /register/seller-apply → /dashboard/verification

Admin            → all routes allowed

Setup incomplete → most routes → /register
                   (bypass: /register, /register/seller-apply, /dashboard/verification)
```

---

## 8. Seller Onboarding Flow (Complete)

```
/register → name, email, password, OTP inline, role selector
  → Member → profile setup complete → /dashboard
  → Seller → /register/seller-apply
               Full legal name, CNIC front/back (uploaded to cnic-docs bucket)
               Phone, city, seller types, existing FB seller fields
             → Submit → seller_applications row (Pending) + invalidate providers
             → /dashboard/verification
```

**Verification states:**
| Status | Message |
|---|---|
| `Pending` | Application under review (48–72 hours) |
| `Under Review` | Admin is actively reviewing |
| `Action Required` | Admin note shown from badge_audit_log + resubmit |
| `Approved` | Verified badge active |
| `Rejected` | Reason from rejection_reason |

---

## 9. Key Business Rules

- **No impressions/clones.** `impression_declaration_accepted` checkbox mandatory. Enforced in UI + blocked from form options.
- **Price mandatory** for all non-ISO, non-Swap listings. Postgres check + UI enforcement.
- **Sale post number auto-generated.** `PFC-00001` format via Postgres sequence. Immutable.
- **Case number auto-generated.** `PFC-CASE-00001` format.
- **Off-platform payments.** Disclaimer on every listing detail page.
- **No inbox-for-price.** Price required; "contact for price" not permitted.
- **ISO listings** open to all authenticated members (not seller-only).
- **Swap listings** allow `price_pkr = 0` (zero = no cash component).

---

## 10. Database Schema

Existing Supabase schema (production). Key tables:

`profiles`, `listings`, `listing_photos`, `bids`, `auction_notifications`, `reviews`, `review_photos`, `reports`, `report_evidence`, `case_activity_log`, `conversations`, `messages`, `conversation_listings`, `seller_applications`, `badge_audit_log`, `community_guides`, `fake_detection_guides`, `glossary_terms`, `otp_attempts`, `pickup_locations`

**`badge_audit_log` columns:**
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| seller_application_id | uuid | FK → seller_applications |
| action | text | `'granted'` `'revoked'` `'action_required'` `'rejected'` |
| note | text | Shown to seller on Action Required |
| created_at | timestamptz | |
| created_by | uuid | FK → auth.users (admin) |

**Commission infrastructure:** Fields (`commission_rate`, `commission_status`, `transaction_value`) already on `listings` table, defaulting to inactive. No schema changes needed to activate.

**Post-v1:** `fragrances` encyclopedia table when Knowledge Base encyclopedia feature is built.

---

## 11. Visual Design System — "The Olfactory Archive"

### Color Tokens
| Token | Hex | Usage |
|---|---|---|
| Primary (Deep Emerald) | `#003527` | Hero backgrounds, primary CTAs, nav, verified badges |
| Primary gradient end | `#064e3b` | CTA button gradient (135°) |
| Secondary (Charcoal) | `#555f70` | Supporting UI, metadata |
| Gold Accent | `#e9c176` | Verified chips, EST. badges — sparingly |
| Gold Background | `#3e2b00` | Badge container fill |
| Surface | `#f9f9fc` | Page canvas |
| Surface container low | `#f3f3f6` | Section backgrounds |
| Surface container highest | `#e2e2e5` | Input fills, nested wells |
| Card surface | `#ffffff` | Cards — borderless lift |
| Body text | `#1a1c1e` | All text — never pure black |
| Ghost border | `#bfc9c3` at 15% opacity | Inputs on focus only |

### Typography
| Role | Font | Scale |
|---|---|---|
| Display / Headlines | Noto Serif | 3.5rem hero; section headers |
| Body / Labels | Inter | All functional text |
| Labels | Inter, UPPERCASE, 0.05rem spacing | Field labels, metadata chips |

### Core Rules
- **No borders / no dividers.** Depth through tonal layering (`#f3f3f6` floor → `#ffffff` card lift).
- **Inputs:** `#f3f3f6` fill, no border at rest. Focus: `#e2e2e5` fill + 1px ghost primary border.
- **Primary button:** `#003527` → `#064e3b` gradient, white text, 4px radius.
- **Roundness:** 4px cards/buttons. Pill (9999px) for status/trust chips only.
- **Spacing:** ~88px between major editorial sections.

### Key Components
- **Marketplace cards:** Aspect 4:5 image, price chip top-right, "Trusted" badge top-left (if verified seller), Noto Serif fragrance name, italic brand, metadata chips (type, ml, condition), Post # and seller name footer.
- **Listing type chips:** Color-coded pills — Full Bottle (default), Swap (emerald), ISO (secondary), Auction (gold).
- **Security advisory:** Left red border box — payment disclaimer on listing detail.
- **Impression declaration:** Dark emerald block, italic serif text, mandatory checkbox.
- **Verification roadmap:** Horizontal stepper (desktop) / vertical stepper (mobile).
- **Filter bar:** Sticky below top bar — "Refine" button + type filter pills + result count.

---

## 12. Adaptive Layout

| Screen width | Layout |
|---|---|
| > 1024px (desktop) | Persistent left sidebar |
| 600–1024px (tablet) | Collapsible sidebar (icon-only) |
| < 600px (mobile) | Bottom navigation bar |

Single `AppShell` widget handles all three. Already implemented and working.

---

## 13. Phased Build Order

See section 14 for detailed breakdown.

| Phase | Feature | Priority |
|---|---|---|
| **Phase 1** | Marketplace browse + listing detail + listing card | P1 — supply/demand core |
| **Phase 2** | Dashboard home + my listings + create listing form | P1 — seller tools |
| **Phase 3** | Sellers list + seller profile | P1 — trust layer |
| **Phase 4** | Messaging — inbox + conversation | P2 — buyer-seller contact |
| **Phase 5** | Reports + ISO posts | P2 — community safety |
| **Phase 6** | Admin panel — users, applications, moderation | P2 — ops |
| **Phase 7** | Knowledge base — guides, fake detection, glossary | P3 — editorial |
| **Phase 8** | Auctions + local pickup maps | Post-v1 |

---

## 14. Detailed Phase Plans

### Phase 1 — Marketplace (Next)

**Goal:** Public can browse and view listings. The core value proposition is visible.

**Files to create:**
```
lib/features/marketplace/
├── data/
│   ├── models/listing_model.dart       ← Listing, ListingPhoto, ListingType enum
│   └── listing_repository.dart         ← getListings (filter+search), getListing(id)
├── providers/
│   └── listing_provider.dart           ← listingsProvider, listingDetailProvider
└── pages/
    ├── marketplace_page.dart           ← browse grid, filter bar, search
    ├── listing_detail_page.dart        ← full detail, photos carousel, disclaimer, CTAs
    └── widgets/
        ├── listing_card.dart           ← 4:5 image card per design reference
        └── listing_filter_bar.dart     ← sticky type filter pills + "Refine" button
```

**Key design specs (from homepage.html):**
- Grid: 2 cols mobile, 3 cols tablet, 4-5 cols desktop
- Card: white background, 4:5 aspect image, price chip top-right, verified badge top-left
- Filter bar: sticky at top, horizontal scrollable type pills, result count
- Listing detail: photo carousel, all fields, off-platform payment disclaimer (red left-border box), "Message Seller" CTA (auth-gated), "Leave a Review" (auth-gated)

**Routes to wire:**
- `/marketplace` → `MarketplacePage`
- `/marketplace/:id` → `ListingDetailPage`

**Supabase queries:**
- `listings` table with `status = 'published'`, join `listing_photos`, join `profiles` (seller name, role)
- Filter by type, condition, price range, verified (role = 'seller')
- Order by `created_at DESC`

---

### Phase 2 — Dashboard + Create Listing

**Goal:** Sellers can create and manage listings. Members see their activity.

**Files to create:**
```
lib/features/dashboard/pages/
├── dashboard_home_page.dart       ← recent activity, quick links
└── my_listings_page.dart          ← seller's listings, mark sold, edit, delete

lib/features/marketplace/pages/
└── create_listing_page.dart       ← full form, photo upload, impression declaration
```

**Key rules:**
- Create listing gated to `seller` role (or `admin`)
- ISO listing creation open to all authenticated members
- Mandatory impression declaration checkbox
- Draft save when fields incomplete
- Auto-generated `post_number` from Postgres sequence

---

### Phase 3 — Sellers List + Seller Profile

**Goal:** Public trust layer. Anyone can browse verified sellers.

**Files to create:**
```
lib/features/sellers/pages/
├── sellers_list_page.dart         ← searchable verified sellers grid
└── seller_profile_page.dart       ← seller's active listings, reviews, verified badge, transaction count
```

**Routes:** `/sellers`, `/sellers/:code`

---

### Phase 4 — Messaging

**Goal:** Buyers can contact sellers. Uses Supabase Realtime for live updates.

**Files to create:**
```
lib/features/messaging/
├── data/messaging_repository.dart
├── providers/messaging_provider.dart  ← Realtime stream
└── pages/
    ├── inbox_page.dart
    └── conversation_page.dart
```

**Key rules:**
- Conversation linked to a listing (`conversation_listings` join table)
- When listing is sold/deleted → display "Listing no longer available" banner in thread
- Supabase Realtime subscription on `messages` table

---

### Phase 5 — Reports + ISO Posts

**Goal:** Community safety (scam reports) + buyer demand signal (ISO posts).

**Files to create:**
```
lib/features/dashboard/pages/
├── reports_page.dart              ← submit report, track case status
└── iso_page.dart                  ← my ISO posts (listing_type = 'iso')
```

**Key rules:**
- Case number auto-generated (`PFC-CASE-XXXXX`)
- Report evidence photo upload
- ISO listings appear in public marketplace with "ISO" badge
- Members (not just sellers) can create ISO listings

---

### Phase 6 — Admin Panel

**Goal:** Ops team can manage users, review seller applications, moderate listings, track disputes.

**Files to create:**
```
lib/features/admin/pages/
├── admin_home_page.dart
├── user_management_page.dart             ← ban, suspend
├── seller_applications_page.dart         ← applications list (Pending, Under Review, etc.)
├── seller_application_detail_page.dart   ← review CNIC, approve/reject, write badge_audit_log note
├── listing_moderation_page.dart          ← flag and remove listings
├── reports_tracker_page.dart             ← case tracker
└── knowledge_management_page.dart        ← CRUD guides and glossary
```

**Key rules:**
- Admin approves → `profiles.role` updated to `'seller'`
- Admin rejects → `rejection_reason` written to `seller_applications`
- All actions logged to `badge_audit_log`
- CNIC images accessed via `createSignedUrl` (private bucket)

---

### Phase 7 — Knowledge Base

**Goal:** Editorial content — guides, fake detection, glossary.

**Files to create:**
```
lib/features/knowledge_base/pages/
├── knowledge_home_page.dart
├── community_guides_page.dart
├── fake_detection_guide_page.dart     ← slug-based detail
└── glossary_page.dart                 ← searchable acronym dictionary
```

**Source tables:** `community_guides`, `fake_detection_guides`, `glossary_terms`

---

### Phase 8 — Auctions + Local Pickup (Post-v1)

**Goal:** Auction bidding system + pickup location maps.

- Auctions: `bids`, `auction_notifications`, `/admin/auctions`
- Local pickup: `pickup_locations`, map integration (Google Maps or Mapbox)
- Auto-expiry already handled by `process_expired_auctions()` pg_cron function

---

## 15. Profile & Reviews

**Profile page** (`/dashboard/profile`): display name, bio, city, avatar upload, change password.

**Reviews** (`/dashboard/reviews`): reviews received on your listings. Rating display, written comment, verified-purchase badge (requires proof photo).

Review submission lives on listing detail page. One review per listing per user. Review data from `reviews` + `review_photos` tables.
