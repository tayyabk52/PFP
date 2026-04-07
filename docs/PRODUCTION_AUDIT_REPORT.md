# PFC Platform — Production Readiness Audit Report
**Date:** 2026-03-26 | **Audited by:** 7 parallel agents + manual verification | **Branch:** `master`

---

## Executive Summary

The PFC platform has **14 fully functional features** with solid core architecture (Riverpod state management, GoRouter navigation, Supabase backend). However, **14 stub pages** remain unimplemented, and there are **8 critical bugs** that must be fixed before production launch, plus **19 high-priority gaps** across security, data integrity, UX, and testing.

**Overall readiness: ~65% — core flows work, but not production-safe.**

---

## CRITICAL (P0) — Must Fix Before Any Public Use

### C-01: Status Case Mismatch Bug — Seller Profile Shows Zero Listings
- **File:** `lib/features/sellers/data/seller_repository.dart:62`
- **Bug:** Queries `.eq('status', 'published')` (lowercase) but DB stores `'Published'` (capitalized)
- **Impact:** Seller profile page shows 0 active listings for ALL sellers
- **Fix:** Change to `.eq('status', 'Published')`

### C-02: `/iso/create` Accessible Without Authentication
- **File:** `lib/core/router/route_guards.dart`
- **Bug:** Route guards only protect `/dashboard/*`, `/admin/*`, and `/register/seller-apply`. The `/iso/create` route is publicly accessible.
- **Impact:** Unauthenticated users can attempt to create ISO posts, leading to crashes or invalid data
- **Fix:** Add `/iso` prefix to protected routes, or add explicit guard for `/iso/create` and `/iso/:id/edit`

### C-03: No Pagination on Marketplace Browse
- **File:** `lib/features/marketplace/data/listing_repository.dart`
- **Bug:** `getListings()` fetches ALL published listings with no `.range()` or `.limit()`. Same issue in ISO board, inbox, and seller listings.
- **Impact:** App will slow/crash as listing count grows past ~100. OOM risk on low-end Android devices.
- **Fix:** Add cursor-based or offset pagination to all list queries

### C-04: `.env` Crash on Missing File
- **File:** `lib/main.dart:13`
- **Bug:** `await dotenv.load(fileName: '.env')` — if `.env` is missing (CI, fresh clone, release build), app crashes on startup with no recovery
- **Impact:** Blocks any deployment pipeline; new developers can't run the app
- **Fix:** Use `dotenv.load(mergeWith: Platform.environment)` with fallback, or compile-time `--dart-define`

### C-05: `get_unread_message_count` RPC Missing from DB
- **File:** `lib/features/dashboard/providers/member_dashboard_provider.dart:42`
- **Bug:** Dashboard calls `supabase.rpc('get_unread_message_count')` which doesn't exist. Currently caught silently (falls back to 0).
- **Impact:** Unread message badges never show. Low severity now, but will confuse users when messaging is actively used.
- **Fix:** Create the RPC in Supabase: `SELECT count(*) FROM messages WHERE read_at IS NULL AND sender_id != p_user_id AND conversation_id IN (SELECT id FROM conversations WHERE buyer_id = p_user_id OR seller_id = p_user_id)`

### C-06: `getListing()` Returns Deleted/Expired Listings
- **File:** `lib/features/marketplace/data/listing_repository.dart`
- **Bug:** Single listing detail fetch (`getListing(id)`) has no status filter — shows Deleted/Expired listings if someone has the URL
- **Impact:** Users can see listings that should be hidden
- **Fix:** Add `.in('status', ['Published', 'Sold'])` filter, or at minimum `.neq('status', 'Deleted')`

### C-07: Raw Supabase Error Strings Exposed to Users
- **Files:** Multiple — `auth_repository.dart`, `conversation_repository.dart`, `listing_write_repository.dart`
- **Bug:** Catch blocks show `'Failed to X: $e'` where `$e` is a raw `PostgrestException` or `AuthException` with internal details
- **Impact:** Exposes table names, column names, constraint names to end users. Security + UX issue.
- **Fix:** Map known error codes to user-friendly messages; log raw errors to crash reporting

### C-08: No Crash Reporting Service
- **Files:** `pubspec.yaml`, `lib/main.dart`
- **Bug:** No Sentry, Crashlytics, or any error reporting. Unhandled exceptions vanish silently.
- **Impact:** Cannot diagnose production crashes. Flying blind.
- **Fix:** Add `sentry_flutter` or `firebase_crashlytics`; wrap `runApp` in error zone

---

## HIGH (P1) — Should Fix Before Public Beta

### H-01: Seller Bottom Nav Missing Messages Tab
- **File:** `lib/core/widgets/bottom_nav.dart:50-57`
- **Issue:** Seller role has 5 nav items: Market, ISO, My Listings, Dashboard, Profile. No Messages tab.
- **Impact:** Sellers must navigate to Dashboard → Messages manually. Buyers have no easy path either.
- **Fix:** Add Messages destination for seller (and member) roles. Consider replacing one existing tab or using a 6th item.

### H-02: Zero Test Coverage for Feature Code
- **Files:** `test/` directory — only 8 test files, all for core utilities
- **Issue:** No tests for: marketplace, messaging, ISO, sellers, dashboard, auth flows, navigation
- **Existing tests:** `app_colors_test.dart`, `app_shell_test.dart`, `app_text_styles_test.dart`, `auth_provider_test.dart`, `auth_repository_test.dart`, `pakistan_city_field_test.dart`, `route_guards_test.dart`, `supabase_client_test.dart`
- **Impact:** Any code change risks regression. No CI safety net.
- **Fix:** Priority test targets: route guards (expand), listing CRUD flows, conversation repository, ISO offer flows

### H-03: No Terms of Service / Privacy Policy
- **Files:** Login/register pages have no ToS/privacy links
- **Issue:** Required for any app that collects personal data (CNIC photos, messages, location)
- **Impact:** Legal liability; app store rejection risk (Google Play requires privacy policy link)
- **Fix:** Add ToS/Privacy pages + checkbox on registration

### H-04: No Account Deletion Flow
- **Issue:** No way for users to delete their account. Required by Google Play and Apple App Store policies.
- **Impact:** App store rejection
- **Fix:** Add account deletion option in profile settings; cascade-delete or anonymize related data

### H-05: N+1 Query Pattern in Dashboard
- **File:** `lib/features/dashboard/providers/member_dashboard_provider.dart`
- **Issue:** Member dashboard fires 6+ separate Supabase queries (listings count, ISO count, messages, recent activity, etc.) in parallel but not batched
- **Impact:** Slow dashboard load, especially on poor connections. Each query is a separate HTTP round-trip.
- **Fix:** Create a single `get_dashboard_summary` RPC that returns all counts in one call

### H-06: Sequential Photo Upload
- **File:** `lib/features/marketplace/data/listing_write_repository.dart:93-125`
- **Issue:** Photos are uploaded one-at-a-time. No parallel upload.
- **Impact:** Creating a listing with 5 photos takes 5× longer than necessary
- **Fix:** Use `Future.wait()` for parallel uploads

### H-07: `schema.sql` is Stale — Doesn't Match Production
- **File:** `schema.sql`
- **Issue:** Missing tables: `sale_confirmations`, `iso_offers`, `iso_notifications`. Missing columns: `avg_rating`, `rating_count` on profiles. Missing RPCs: `confirm_sale`, `submit_review`, `decrement_listing_quantity`, `reviews_rating_stats` trigger.
- **Impact:** New developers can't understand DB structure from schema file. Migration history is the only source of truth.
- **Fix:** Dump current production schema to `schema.sql`

### H-08: Unguarded `SellerRepository.submitReview()` Bypass Path
- **File:** `lib/features/sellers/data/seller_repository.dart` (if it has a submitReview method)
- **Issue:** The `submit_review` RPC in DB enforces `sale_confirmations` check, but if any Flutter code path calls `supabase.from('reviews').insert()` directly, it bypasses the purchase verification.
- **Impact:** Potential fake reviews. Low risk since RPC is used in conversation_page, but the repository method (if present) is a bypass vector.
- **Fix:** Ensure ALL review submissions go through the `submit_review` RPC, never direct insert

### H-09: ISO Offer Bottom Sheet Closes Before Submit Completes
- **File:** `lib/features/iso/pages/iso_detail_page.dart`
- **Issue:** When submitting an ISO offer, the bottom sheet may close (Navigator.pop) before the async operation completes, losing error feedback
- **Impact:** User doesn't know if offer succeeded or failed
- **Fix:** Show loading state, await result, then pop with success/error feedback

### H-10: No Error Handling on ISO Offer Accept/Decline
- **File:** `lib/features/iso/pages/iso_detail_page.dart`
- **Issue:** `accept_iso_offer` and decline operations have no try/catch
- **Impact:** Silent failures; user thinks action succeeded when it may not have
- **Fix:** Add try/catch with SnackBar error feedback

### H-11: Message History Not Paginated
- **File:** `lib/features/profile/data/conversation_repository.dart`
- **Issue:** `getMessages()` fetches all messages for a conversation with no limit
- **Impact:** Long conversations will cause performance issues
- **Fix:** Add `.range(from, to)` with scroll-based loading

### H-12: Soft-Delete Conversation Reappear (FR-017)
- **File:** `lib/features/profile/data/conversation_repository.dart`
- **Issue:** Spec requires that deleted conversations reappear if a new message arrives. The `buyer_deleted_at`/`seller_deleted_at` columns exist but the logic to resurface isn't implemented.
- **Impact:** Users who "delete" a conversation won't see new messages from the other party

---

## MEDIUM (P2) — Fix Before GA Release

### M-01: 14 Stub Pages Still Unimplemented
| Route | Priority |
|---|---|
| `/dashboard/reviews` | P2 — Users expect to see their reviews |
| `/dashboard/reports` | P3 |
| `/knowledge` | P3 |
| `/knowledge/guides` | P3 |
| `/knowledge/fake-detection/:slug` | P3 |
| `/knowledge/glossary` | P3 |
| `/admin` (overview) | P2 — Needed for operations |
| `/admin/users` | P2 |
| `/admin/sellers` | P2 |
| `/admin/sellers/applications` | **P1** — Blocks seller onboarding |
| `/admin/sellers/applications/:id` | **P1** — Blocks seller onboarding |
| `/admin/listings` | P2 |
| `/admin/reports` | P3 |
| `/admin/knowledge` | P3 |

### M-02: No Image Compression Before Upload
- **Issue:** Photos uploaded at full camera resolution (5-10MB each)
- **Impact:** Slow uploads, high storage costs, slow listing page loads
- **Fix:** Compress to max 1200px width, 80% JPEG quality before upload

### M-03: No Offline / Poor Connection Handling
- **Issue:** No connectivity checks, no retry logic, no cached data
- **Impact:** App shows blank screens or cryptic errors on poor connections (common in Pakistan)
- **Fix:** Add connectivity_plus package; show offline banner; cache critical data

### M-04: No Pull-to-Refresh on List Pages
- **Issue:** Marketplace, ISO board, My Listings, Inbox — none have pull-to-refresh
- **Impact:** Users must navigate away and back to see updated data
- **Fix:** Wrap in `RefreshIndicator` + `ref.invalidate()`

### M-05: No Loading Skeletons / Shimmer Effects
- **Issue:** Lists show blank or spinner while loading
- **Impact:** Perceived poor performance; layout shift when data loads
- **Fix:** Add shimmer placeholder widgets matching card layout

### M-06: No Deep Link / Universal Link Support
- **Issue:** No `AndroidManifest` intent filters or iOS associated domains for `pfc.app` links
- **Impact:** Shared listing URLs open in browser, not app
- **Fix:** Configure app links in `AndroidManifest.xml` and `apple-app-site-association`

### M-07: No Push Notifications
- **Issue:** No FCM/APNs integration
- **Impact:** Users don't know about new messages, offers, or sale confirmations unless they open the app
- **Fix:** Add `firebase_messaging`; store FCM tokens in profiles table; send notifications on new message/offer/sale

---

## LOW (P3) — Nice to Have

### L-01: No Search on Marketplace Browse
- **Issue:** Marketplace has filter chips but no text search for fragrance name/brand
- **Fix:** Add search field with `ilike` query

### L-02: No Listing Share Button
- **Issue:** No way to share a listing URL via native share sheet
- **Fix:** Add `share_plus` package; generate shareable URL

### L-03: No Report/Flag Button on Listings
- **Issue:** Users can't report suspicious listings
- **Fix:** Add report button → insert into `reports` table

### L-04: No Seller Rating Display on Listing Cards
- **Issue:** Marketplace listing cards don't show seller rating
- **Fix:** Include `avg_rating` in listing query join; show star chip

### L-05: No Password Reset Flow
- **Issue:** If using email/password auth (vs OTP), no "Forgot Password" option
- **Fix:** Add Supabase `resetPasswordForEmail()` flow

### L-06: No App Version Check / Force Update
- **Issue:** No mechanism to force users to update when breaking changes ship
- **Fix:** Store min version in Supabase; check on app start

---

## Feature Completeness Matrix

| Feature | UI | Data Layer | Backend (DB) | Tests | Status |
|---|---|---|---|---|---|
| Auth (login/register/OTP) | ✅ | ✅ | ✅ | ⚠️ 2 files | **Production** (missing ToS) |
| Marketplace browse | ✅ | ✅ | ✅ | ❌ | **Needs pagination** |
| Listing detail | ✅ | ✅ | ✅ | ❌ | **Shows deleted listings** |
| Create/Edit listing | ✅ | ✅ | ✅ | ❌ | **Working** |
| My Listings + actions | ✅ | ✅ | ✅ | ❌ | **Working** (mark sold fixed) |
| Seller Dashboard | ✅ | ✅ | ✅ | ❌ | **Working** |
| Member Dashboard | ✅ | ✅ | ⚠️ | ❌ | **Working** (missing RPC) |
| Profile page | ✅ | ✅ | ✅ | ❌ | **Working** |
| Seller Profile | ✅ | ✅ | ✅ | ❌ | **Bug: 0 listings shown** |
| Sellers List | ✅ | ✅ | ✅ | ❌ | **Working** |
| User Profile | ✅ | ✅ | ✅ | ❌ | **Working** |
| ISO Board | ✅ | ✅ | ✅ | ❌ | **Working** |
| ISO Create/Edit | ✅ | ✅ | ✅ | ❌ | **Auth guard missing** |
| ISO Detail + Offers | ✅ | ✅ | ✅ | ❌ | **Missing error handling** |
| Messaging (inbox) | ✅ | ✅ | ✅ | ❌ | **Working** |
| Messaging (conversation) | ✅ | ✅ | ✅ | ❌ | **Working** (realtime fixed) |
| Sale Confirmation | ✅ | ✅ | ✅ | ❌ | **Working** |
| Review System | ✅ | ✅ | ✅ | ❌ | **Working** |
| Seller Verification | ✅ | ✅ | ✅ | ❌ | **Working** |
| My Reviews | ❌ stub | ❌ | ✅ | ❌ | **Not started** |
| Admin Panel (all) | ❌ stub | ❌ | ✅ | ❌ | **Not started** |
| Knowledge Base | ❌ stub | ❌ | ✅ | ❌ | **Not started** |
| Reports | ❌ stub | ❌ | ✅ | ❌ | **Not started** |

---

## Recommended Fix Order

### Sprint 1 (Critical bugs — 1-2 days)
1. **C-01** Fix status case mismatch (`'published'` → `'Published'`)
2. **C-02** Add auth guard for `/iso/create` and `/iso/:id/edit`
3. **C-06** Filter deleted listings from detail view
4. **C-07** Sanitize error messages (map to user-friendly text)
5. **C-04** Fix `.env` crash (use `--dart-define` or try/catch dotenv)

### Sprint 2 (High priority — 3-5 days)
6. **C-03** Add pagination to marketplace, ISO, inbox
7. **C-05** Create `get_unread_message_count` RPC
8. **H-01** Add Messages tab to bottom nav
9. **H-09/H-10** Fix ISO offer submit + accept/decline error handling
10. **C-08** Add crash reporting (Sentry)

### Sprint 3 (Admin panel — enables operations)
11. **M-01** Build `/admin/sellers/applications` (blocks seller growth)
12. **M-01** Build `/admin/users` (suspend/unsuspend)
13. **M-01** Build `/admin/listings` (moderation)

### Sprint 4 (Polish — pre-GA)
14. **H-03/H-04** Terms of Service + Account Deletion
15. **M-02** Image compression
16. **M-04** Pull-to-refresh on all lists
17. **H-02** Write tests for critical paths
18. **H-07** Refresh `schema.sql`

---

## Test Scenarios Needed (Priority Order)

### Route Guards (expand existing `route_guards_test.dart`)
- [ ] Unauthenticated → `/iso/create` should redirect to `/login`
- [ ] Member → `/dashboard/my-listings` should redirect
- [ ] Seller → `/admin` should redirect
- [ ] Deep link with redirect parameter preserved after login

### Marketplace
- [ ] Browse shows only Published listings
- [ ] Listing detail returns 404 for Deleted listings
- [ ] Filter by listing type works
- [ ] Pagination loads next page on scroll
- [ ] Create listing → Draft → Publish flow
- [ ] Mark Sold → single unit vs multi-unit
- [ ] Delete listing → soft delete, disappears from browse

### Messaging
- [ ] Send message appears in real-time for both parties
- [ ] Confirm Sale button visible only to seller for Published listings
- [ ] Confirm Sale decrements quantity correctly
- [ ] Leave Review button visible only after sale confirmation
- [ ] Review submission updates seller avg_rating
- [ ] Inbox shows correct unread counts
- [ ] Long conversation loads without OOM

### ISO
- [ ] Create ISO post (authenticated only)
- [ ] Submit offer on someone else's ISO
- [ ] Accept offer → other offers auto-declined
- [ ] Decline offer → status updates
- [ ] Withdraw own offer
- [ ] Cannot offer on own ISO

### Auth
- [ ] Register → OTP verify → profile setup → dashboard
- [ ] Login → redirect to intended page
- [ ] Seller apply → CNIC upload → pending status
- [ ] Logout → clears session → redirects to landing

---

---

## Schema & Spec Deep Dive (from Schema Audit Agent)

### Tables Missing from `schema.sql` (Exist in Production Only)
| Table | Used By | Purpose |
|---|---|---|
| `iso_offers` | `iso_write_repository.dart`, `iso_repository.dart` | Seller offers on ISO requests |
| `iso_notifications` | `iso_write_repository.dart`, `iso_repository.dart` | ISO offer notifications |
| `sale_confirmations` | `conversation_repository.dart` | Confirms sale completion before review |

### RPC Functions Called But Not Documented
| RPC | Called From | Purpose |
|---|---|---|
| `get_or_create_conversation` | `conversation_repository.dart:141` | Creates 1:1 buyer-seller thread |
| `add_listing_to_conversation` | `conversation_repository.dart:156` | Attaches listing reference to thread |
| `confirm_sale` | `conversation_repository.dart:330` | Marks sale, bumps transaction counts |
| `submit_review` | `conversation_repository.dart:361` | Submits review (enforces sale_confirmation) |
| `get_unread_message_count` | `member_dashboard_provider.dart:42` | Unread message count (MISSING from DB) |
| `decrement_listing_quantity` | `listing_write_repository.dart:181` | Atomic quantity decrement |
| `accept_iso_offer` | `iso_write_repository.dart:62` | Accepts ISO offer |

### Tables in Schema Not Used by Any Flutter Code (10 total)
`case_activity_log`, `fake_detection_guides`, `glossary_terms`, `community_guides`, `pickup_locations`, `report_evidence`, `reports`, `otp_attempts`, `bids` (minimal), `auction_notifications` (stats only)

These correspond to unbuilt features: Knowledge Base (Phase 7), Admin/Moderation (Phase 6), Auctions (Phase 8), Reports (Phase 5).

### Column Mismatches
| Issue | Severity |
|---|---|
| `listings.impression_declaration_accepted` — in schema, NOT in Flutter `Listing` model | Medium — not exposed to UI |
| `listings.commission_rate/status/transaction_value` — payment infrastructure present but inactive | Low — v2 concern |
| `listings.auction_outcome_note`, `hashtags` — in schema, not modeled in Dart | Low |
| `profiles.account_status`, `suspended_until` — in schema, not modeled in Dart | Medium — needed for ban/suspend UI |
| `profiles.verified_at`, `verified_by` — in schema, not modeled in Dart | Low |

### Schema Export Gaps (Cannot Verify from `schema.sql`)
The exported `schema.sql` is **table-definitions only**. The following critical objects are NOT visible:

| Object Type | Count Specified | Confirmable | Action |
|---|---|---|---|
| **RLS Policies** | 10+ specified across specs | ZERO visible | Must verify in Supabase dashboard |
| **Indexes** | 9 specified for `listings` table alone | ZERO visible | Must verify — without these, every browse is a full table scan |
| **Triggers** | 4+ (`listing_status_changed`, `auto_sold_on_zero_quantity`, `listing_last_updated`, `reviews_rating_stats`) | ZERO visible | Must verify |
| **Functions/RPCs** | 7 called by Flutter code | ZERO visible | Must verify |
| **Sequences** | `listing_sale_post_seq`, `report_case_seq` | Referenced in DEFAULTs only | Exist (columns work) |
| **pg_cron jobs** | `process_expired_auctions` (every 30s) | NOT visible | Must verify |

### Spec-Schema Mismatches
1. **Condition enum inconsistency:** Spec 002/008 say `New, Like New, Excellent, Good, Fair`. Data-model.md says `New, Like New, Good, Fair, Poor`. Resolve before launch.
2. **`badge_audit_log` action values:** Schema CHECK allows only `'granted' | 'revoked'`. Spec also references `'action_required'`, `'rejected'`. Mismatch.
3. **`conversation_listings` missing `display_status`:** Spec 006 requires `available | unavailable` field to show "Listing no longer available". Not in schema.
4. **`reports.resolution_note`:** Single field in schema, but spec 005 requires separate `public_note` (reporter-visible) and `internal_note` (admin-only).

### Missing Scheduled Functions
| Function | Spec Requirement | Status |
|---|---|---|
| CNIC auto-purge | 90 days post-rejection, 1 year post-closure | NOT IMPLEMENTED |
| Suspension auto-lift | Restore `account_status` when `suspended_until` passes | NOT IMPLEMENTED |
| Ban session invalidation | Revoke Supabase Auth tokens on ban | NOT IMPLEMENTED |

### Spec Feature Implementation Coverage

| Spec | Feature | Schema | Data Layer | UI | Overall |
|---|---|---|---|---|---|
| 002 | Marketplace Listings | 100% | 60% | 90% | **80%** |
| 003 | Seller Verification | 90% | 40% | 60% | **55%** |
| 004 | Knowledge Base | 100% | 0% | 0% | **15%** |
| 005 | Moderation & Admin | 80% | 0% | 0% | **10%** |
| 006 | Buyer-Seller Messaging | 90% | 80% | 80% | **80%** |
| 007 | Local Pickup Maps | 100% | 0% | 0% | **15%** |
| 008 | Listing Schema | 85% | 60% | N/A | **70%** |
| 009 | Auction/ISO/Multi-Qty | 80% | 40% (ISO) | 40% (ISO) | **35%** |

---

*Report generated from 7 parallel audit agents + 2 schema/spec deep-dive agents covering: Auth, Marketplace, Messaging, ISO, Sellers/Profiles, Dashboard/Navigation, Schema/Specs*
