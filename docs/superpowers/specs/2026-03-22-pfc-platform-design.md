# PFC Platform — Design Specification
**Date:** 2026-03-22
**Project:** Pakistan Fragrance Community (PFC)
**Platform:** Flutter Web (mobile later, single codebase)

---

## 1. Overview

PFC is a structured web platform for Pakistani fragrance enthusiasts that complements the existing PFC Facebook group. It does not replace Facebook — it adds features FB cannot offer: a verified marketplace, seller trust system, scam reporting, and a fragrance knowledge base.

**Launch target:** Under 1,000 users, web-first.
**Monetisation:** Free at launch. Commission model introduced later (infrastructure built in from day one).
**Payments:** Off-platform only (EasyPaisa, JazzCash, bank transfer). Platform does not mediate payments.

---

## 2. User Roles

| Role | Access |
|---|---|
| **Member** | Browse, buy, post reviews, report scams, submit ISO posts, message sellers |
| **Seller** | All member permissions + create listings. Requires admin-approved verification. |
| **Admin** | Full control: bans, suspensions, seller verification, content management, dispute resolution |

Role is stored in `profiles.role` (`member` | `seller` | `admin`). Always read from Supabase — never stored in local state.

---

## 3. Tech Stack

| Concern | Choice | Reason |
|---|---|---|
| Framework | Flutter (web + mobile) | Single codebase for web now, mobile later |
| Backend | Supabase | Postgres relations, Auth, Storage, Realtime |
| State management | Riverpod | Compile-safe, handles multiple Supabase streams, role-based access |
| Navigation | go_router | Official Flutter recommendation, route guards |
| Theme | Cream & Gold (light premium) | Warm, approachable, premium community feel |
| Navigation layout | Left sidebar (adaptive) | Persistent on desktop, bottom nav on mobile |

---

## 4. Architecture — Feature-First

```
lib/
├── core/
│   ├── router/
│   │   └── app_router.dart          ← go_router config + redirect guards
│   ├── supabase/
│   │   └── supabase_client.dart     ← Supabase init + singleton
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   └── widgets/
│       ├── app_shell.dart           ← adaptive sidebar/bottom-nav shell
│       ├── sidebar.dart
│       └── app_button.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── pages/
│   │       ├── login_page.dart
│   │       ├── register_page.dart
│   │       └── seller_apply_page.dart
│   │
│   ├── marketplace/
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
│   │   ├── data/
│   │   ├── providers/
│   │   └── pages/
│   │       ├── sellers_list_page.dart
│   │       └── seller_profile_page.dart
│   │
│   ├── knowledge_base/
│   │   ├── data/
│   │   ├── providers/
│   │   └── pages/
│   │       ├── knowledge_home_page.dart
│   │       ├── community_guides_page.dart
│   │       ├── fake_detection_guide_page.dart
│   │       └── glossary_page.dart
│   │
│   ├── messaging/
│   │   ├── data/
│   │   │   └── messaging_repository.dart
│   │   ├── providers/
│   │   │   └── messaging_provider.dart
│   │   └── pages/
│   │       ├── inbox_page.dart
│   │       └── conversation_page.dart
│   │
│   ├── dashboard/
│   │   ├── data/
│   │   ├── providers/
│   │   └── pages/
│   │       ├── dashboard_home_page.dart
│   │       ├── my_listings_page.dart
│   │       ├── my_profile_page.dart
│   │       ├── my_reviews_page.dart
│   │       ├── reports_page.dart
│   │       ├── iso_page.dart
│   │       └── verification_status_page.dart
│   │
│   └── admin/
│       ├── data/
│       ├── providers/
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

## 5. Pages & Routes

### Public (unauthenticated)
| Route | Page |
|---|---|
| `/` | Landing — hero, featured listings, legit sellers preview |
| `/login` | Login — email/phone + OTP |
| `/register` | Register — basic info + OTP inline (single page, no separate OTP route) |
| `/marketplace` | Browse listings — filterable grid |
| `/marketplace/:id` | Listing detail |
| `/sellers` | Legit sellers public list (searchable) |
| `/sellers/:code` | Seller public profile |
| `/knowledge` | Knowledge base home |
| `/knowledge/guides` | Community guides |
| `/knowledge/fake-detection/:slug` | Fake detection guide |
| `/knowledge/glossary` | Acronym/glossary dictionary |

### Registration Flow (auth-required, no sidebar)
| Route | Page |
|---|---|
| `/register/seller-apply` | Seller application form step 2 — CNIC upload, details. Requires authenticated session. Unauthenticated access redirects to `/register`. |

### Member Dashboard (auth-gated, sidebar layout)
| Route | Page |
|---|---|
| `/dashboard` | Home — recent listings, activity |
| `/dashboard/my-listings` | My listings (all types except ISO). Page must include a visible cross-link or tab to `/dashboard/iso`. If no non-ISO listings exist, empty state directs user to ISO page. |
| `/dashboard/create-listing` | Create listing form. **Seller role only** — member role redirects to `/dashboard`. File lives in `features/marketplace/pages/` but is routed under `/dashboard`. |
| `/dashboard/messages` | Inbox |
| `/dashboard/messages/:id` | Conversation thread |
| `/dashboard/profile` | Profile & settings |
| `/dashboard/reviews` | My received reviews |
| `/dashboard/reports` | Submit + track scam reports |
| `/dashboard/iso` | My ISO posts (listings where `listing_type = 'iso'`) |
| `/dashboard/verification` | Seller application status + resubmission. Redirects to `/dashboard` if `seller_applications.status = 'Approved'`. Not shown in sidebar once approved. |

### Admin (role-gated, separate sidebar)
| Route | Page |
|---|---|
| `/admin` | Admin overview |
| `/admin/users` | User management (ban, suspend) |
| `/admin/sellers` | Verified sellers list |
| `/admin/sellers/applications` | Seller applications list |
| `/admin/sellers/applications/:id` | Review application, request changes, approve/reject |
| `/admin/listings` | Listing moderation |
| `/admin/reports` | Dispute/case tracker |
| `/admin/knowledge` | Guides + glossary management |
| `/admin/auctions` | Auction oversight — **post-v1.** Not built in initial release. Route reserved. |

---

## 6. Route Guards

Enforced in `go_router`'s `redirect` callback, reading `authStateProvider`:

```
Unauthenticated  → /dashboard/*, /admin/*, /register/seller-apply redirect to /login

Member           → /admin/* redirects to /dashboard
                   /dashboard/create-listing redirects to /dashboard
                   /register/seller-apply:
                     - No existing application → allowed (first-time apply)
                     - Existing application (any status) → redirect to /dashboard/verification

Seller           → /admin/* redirects to /dashboard
                   /dashboard/create-listing allowed
                   /register/seller-apply redirects to /dashboard/verification

Admin            → all routes
```

---

## 7. Seller Onboarding Flow

```
/register        → Basic info (name, email/phone), OTP sent + verified inline
                 → "How will you use PFC?" (Member / Seller)
                   (OTP is a modal/inline step on /register — no separate route)

If Member        → profile setup complete → /dashboard

If Seller        → redirect to /register/seller-apply (auth session now exists)
                     Full legal name, CNIC front + back upload
                     Phone, city, seller types (full bottles / decants / both)
                     Existing FB seller? → FB profile URL + seller ID
                 → Submit → role stays 'member', seller_application row created (Pending)
                 → redirect to /dashboard (verification banner visible in sidebar)
```

**Verification states on `/dashboard/verification`:**

| Status | Message |
|---|---|
| `Pending` | Application under review |
| `Under Review` | Admin is reviewing your application |
| `Action Required` | ⚠ Admin note displayed (read from `badge_audit_log`, not inbox) + resubmit form |
| `Approved` | ✅ Verified. Badge active. Route redirects to `/dashboard`. |
| `Rejected` | ❌ Reason shown (from `seller_applications.rejection_reason`) |

**Action Required note delivery:** Admin writes a note in `badge_audit_log` (not through the messaging system). The verification page reads the latest `badge_audit_log` entry where `action = 'action_required'` and displays it inline. This has no dependency on the messaging feature.

Resubmission cycle: seller updates flagged fields → status resets to `Pending` → admin reviews again. All state changes logged in `badge_audit_log`.

---

## 8. Key Business Rules (enforced in UI + Supabase RLS)

- **Impressions/clones banned from listings.** `impression_declaration_accepted` checkbox mandatory on create listing. Cannot submit without it.
- **Price is mandatory for non-ISO listings.** UI enforces `price_pkr > 0` for all listing types except `iso`. ISO posts may have `price_pkr = 0` (seeking seller). A Postgres check or RLS policy should enforce `price_pkr > 0 WHERE listing_type != 'iso'` — do not rely on UI alone.
- **Sale post number auto-generated.** `PFC-00001` format via Postgres sequence. Never editable.
- **Case number auto-generated.** `PFC-CASE-00001` format.
- **Off-platform payments.** Disclaimer shown on every listing detail page and at checkout intent.
- **No inbox-for-price.** Price field is required; "contact for price" not permitted.

---

## 9. Database Schema

Existing Supabase schema is used as-is. Key tables:

`profiles`, `listings`, `listing_photos`, `bids`, `auction_notifications`, `reviews`, `review_photos`, `reports`, `report_evidence`, `case_activity_log`, `conversations`, `messages`, `conversation_listings`, `seller_applications`, `badge_audit_log`, `community_guides`, `fake_detection_guides`, `glossary_terms`, `otp_attempts`, `pickup_locations`

**`badge_audit_log` — required columns for step 3 + step 11 implementation:**

| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| seller_application_id | uuid | FK → seller_applications |
| action | text | `'granted'` `'revoked'` `'action_required'` `'rejected'` |
| note | text | Human-readable message shown to seller on Action Required |
| created_at | timestamptz | |
| created_by | uuid | FK → auth.users (admin) |

The verification page reads the latest row where `action = 'action_required'` to display the admin note inline.

---

**Pending addition (post-v1):** `fragrances` encyclopedia table — when Knowledge Base encyclopedia feature is built, add a structured table for fragrance name, brand, notes, longevity, sillage, concentration, year. Current fake_detection_guides uses plain text fragrance_name/brand which is fine for v1.

**Commission infrastructure:** Fields (`commission_rate`, `commission_status`, `transaction_value`) already on `listings` table, defaulting to inactive. No schema changes needed to activate commission model later.

---

## 10. Visual Design System — "The Olfactory Archive"

Source: `DesignInspo/sillage_heritage/DESIGN.md` + all screen references.

### Color Tokens
| Token | Hex | Usage |
|---|---|---|
| Primary (Deep Emerald) | `#003527` | Hero backgrounds, primary CTAs, nav, verified badges |
| Primary gradient end | `#064e3b` | CTA button gradient (135°) — velvet texture |
| Secondary (Charcoal) | `#555f70` | Supporting UI, metadata |
| Gold Accent | `#e9c176` | Verified chips, EST. badges — sparingly |
| Gold Background | `#3e2b00` | Badge container fill |
| Surface | `#f9f9fc` | Page canvas |
| Surface container low | `#f3f3f6` | Section backgrounds |
| Surface container highest | `#e2e2e5` | Input fills, nested wells |
| Card surface | `#ffffff` | Cards — creates borderless lift over floor |
| Body text | `#1a1c1e` | All text — never pure black |
| Ghost border | `#bfc9c3` at 15% opacity | Inputs on focus only |

### Typography
| Role | Font | Scale |
|---|---|---|
| Display | Noto Serif | 3.5rem — fragrance names, hero headers |
| Headlines/Titles | Noto Serif | Section headers, editorial |
| Body | Inter | All functional text |
| Labels | Inter, UPPERCASE, 0.05rem spacing | Field labels, metadata chips |

### Core Rules
- **No borders / no dividers.** Depth through tonal layering only (`#f3f3f6` floor → `#ffffff` card lift).
- **Glassmorphism nav:** surface at 80% opacity + 20px backdrop-blur.
- **Hover shadows:** `on_surface` at 5% opacity, 32px blur — soft glow, not hard drop.
- **Roundness:** `0.25rem` (4px) for cards and buttons. `9999px` pills only for status/trust chips.
- **Spacing:** `5.5rem` between major editorial sections.

### Key Components (from DesignInspo screens)
- **Marketplace cards:** Asymmetric, price top-right in label-md, name bottom-left in Noto Serif title-lg. No card borders.
- **Sale post number:** Chip style, monospace, e.g. `#PFC-2024-0042`
- **Security advisory:** Left red border box — payment disclaimer on every listing detail.
- **Impression declaration:** Dark emerald block (`#003527`), italic serif text, checkbox.
- **Verification roadmap:** Vertical stepper — Submitted → Under Review → Verified. Admin notes as left-border quote block.
- **Inputs:** `#f3f3f6` fill, no border. Focus: `#e2e2e5` fill + 1px ghost primary border.
- **Primary button:** `#003527` → `#064e3b` gradient, white text, 4px radius.
- **Navigation (desktop):** Glassmorphism top bar. **Mobile:** Bottom tab bar (Archive, Market, Verify, Vault).

---

## 11. Adaptive Layout

| Screen width | Layout |
|---|---|
| > 1024px (desktop web) | Persistent left sidebar |
| 600–1024px (tablet) | Collapsible sidebar (icon-only) |
| < 600px (mobile app) | Bottom navigation bar |

Single `AppShell` widget handles all three. Page content is written once.

---

## 12. Build Order (page by page)

1. Flutter project setup + theme + AppShell (adaptive layout)
2. Auth — login, register, OTP inline flow
3. Seller application flow — `/register/seller-apply` + `/dashboard/verification` (uses `badge_audit_log` only, no messaging dependency)
4. Marketplace — browse, listing detail, listing card
5. Create listing form (seller-role gated)
6. Seller profile + legit sellers list
7. Dashboard — home, my listings, my ISO posts
8. Messaging — inbox, conversation thread
9. Reports — submit, track
10. Knowledge base — community guides, fake detection guides, glossary
11. Admin panel — users, seller applications, listing moderation, reports tracker, knowledge management
12. Auctions — post-v1 (bids, auction_notifications, /admin/auctions)
