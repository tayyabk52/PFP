import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/profile_provider.dart';
import '../../marketplace/data/models/listing_model.dart';
import '../../marketplace/providers/my_listings_provider.dart';
import '../data/member_dashboard_repository.dart';
import '../providers/member_dashboard_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> _refreshAll(WidgetRef ref) async {
    ref.invalidate(currentProfileProvider);
    ref.invalidate(userRoleProvider);
    ref.invalidate(sellerApplicationProvider);
    await ref.read(currentProfileProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final applicationAsync = ref.watch(sellerApplicationProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        }
      },
      child: profileAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const Scaffold(
          body: Center(child: Text('Error loading profile')),
        ),
        data: (profile) {
          final role = profile?['role'] as String? ?? 'member';
          final isSeller = role == 'seller' || role == 'admin';

          if (isSeller) return _buildSellerDashboard(context, ref, profile!);

          final application = applicationAsync.valueOrNull;
          final appStatus = application?['status'] as String?;
          return _buildMemberDashboard(context, ref, profile, appStatus, application);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SELLER DASHBOARD
  // ---------------------------------------------------------------------------

  Widget _buildSellerDashboard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> profile,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _refreshAll(ref),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isMobile ? 20 : 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSellerHeader(profile),
                        SizedBox(height: isMobile ? 28 : 40),
                        _buildSellerStats(ref),
                        const SizedBox(height: 28),
                        _buildSellerActions(context),
                        const SizedBox(height: 28),
                        _buildRecentListings(context, ref),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSellerHeader(Map<String, dynamic> profile) {
    final displayName = profile['display_name'] as String? ?? 'Seller';
    final pfcCode = profile['pfc_seller_code'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          color: AppColors.surfaceContainerLow,
          child: Text(
            'SELLER ARCHIVE',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Welcome back,',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          displayName,
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            height: 1.1,
          ),
        ),
        if (pfcCode != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: AppColors.primary,
            child: Text(
              pfcCode,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSellerStats(WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final txCount =
        profileAsync.valueOrNull?['transaction_count'] as int? ?? 0;

    return listingsAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (listings) {
        final published =
            listings.where((l) => l.status == ListingStatus.published).length;
        final drafts =
            listings.where((l) => l.status == ListingStatus.draft).length;
        final sold =
            listings.where((l) => l.status == ListingStatus.sold).length;

        return LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 500 ? 4 : 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _statCard('Published', published.toString(),
                    Icons.storefront_outlined, constraints.maxWidth, cols),
                _statCard('Drafts', drafts.toString(), Icons.drafts_outlined,
                    constraints.maxWidth, cols),
                _statCard('Sold', sold.toString(), Icons.check_circle_outline,
                    constraints.maxWidth, cols),
                _statCard('Transactions', txCount.toString(),
                    Icons.swap_horiz_outlined, constraints.maxWidth, cols),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    double totalWidth,
    int cols,
  ) {
    final cardWidth = (totalWidth - (cols - 1) * 12) / cols;
    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.all(20),
        color: AppColors.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.notoSerif(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (_, constraints) {
            final cols = constraints.maxWidth > 500 ? 2 : 1;
            final cardWidth = cols > 1
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _actionCard(
                  context,
                  'Create Listing',
                  'List a new fragrance for sale',
                  Icons.add_circle_outline,
                  '/dashboard/create-listing',
                  cardWidth,
                ),
                _actionCard(
                  context,
                  'My Listings',
                  'Manage and track your listings',
                  Icons.inventory_2_outlined,
                  '/dashboard/my-listings',
                  cardWidth,
                ),
                _actionCard(
                  context,
                  'Messages',
                  'Your buyer conversations',
                  Icons.chat_bubble_outline,
                  '/dashboard/messages',
                  cardWidth,
                ),
                _actionCard(
                  context,
                  'Profile',
                  'Update your seller profile',
                  Icons.person_outline,
                  '/dashboard/profile',
                  cardWidth,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _actionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String route,
    double width,
  ) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.all(20),
          color: AppColors.surfaceContainerLow,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                color: AppColors.primary.withValues(alpha: 0.08),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onBackground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentListings(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);

    return listingsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (all) {
        final recent = all
            .where((l) => l.status == ListingStatus.published)
            .take(3)
            .toList();
        if (recent.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'RECENT LISTINGS',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/dashboard/my-listings'),
                  child: Text(
                    'VIEW ALL',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => context.go('/marketplace/${recent[i].id}'),
                  child: SizedBox(
                    width: 160,
                    child: _recentListingMiniCard(recent[i]),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _recentListingMiniCard(Listing listing) {
    return Container(
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: listing.primaryPhotoUrl != null
                ? Image.network(
                    listing.primaryPhotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceContainerHighest,
                    ),
                  )
                : Container(
                    color: AppColors.surfaceContainerHighest,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppColors.textMuted,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.fragranceName,
                  style: GoogleFonts.notoSerif(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  listing.brand,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MEMBER DASHBOARD
  // ---------------------------------------------------------------------------

  Widget _buildMemberDashboard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? profile,
    String? appStatus,
    Map<String, dynamic>? application,
  ) {
    ref.watch(memberDashboardStatsProvider); // preload for memberSince
    final unreadAsync = ref.watch(unreadMessagesCountProvider);
    final isoCountAsync = ref.watch(memberIsoCountProvider);
    final reviewsGivenAsync = ref.watch(memberReviewsGivenProvider);
    final recentConvosAsync = ref.watch(recentConversationsProvider);
    final activeIsosAsync = ref.watch(memberActiveIsosProvider);
    final pulseAsync = ref.watch(marketplacePulseProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(memberDashboardStatsProvider);
            ref.invalidate(unreadMessagesCountProvider);
            ref.invalidate(memberIsoCountProvider);
            ref.invalidate(memberReviewsGivenProvider);
            ref.invalidate(recentConversationsProvider);
            ref.invalidate(memberActiveIsosProvider);
            ref.invalidate(marketplaceOverviewProvider);
            ref.invalidate(marketplacePulseProvider);
            await _refreshAll(ref);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────────
                _memberArchiveLabel(profile),
                const SizedBox(height: 36),

                // ── Stats 2×2 gap-px grid ──────────────────────────────────
                _buildMemberStatsGrid(
                  isoCountAsync.valueOrNull ?? 0,
                  reviewsGivenAsync.valueOrNull ?? 0,
                  unreadAsync.valueOrNull ?? 0,
                  profile?['transaction_count'] as int? ?? 0,
                ),
                const SizedBox(height: 32),

                // ── Marketplace Pulse — dark emerald card ──────────────────
                _buildMarketplacePulseCard(pulseAsync.valueOrNull),
                const SizedBox(height: 32),

                // ── Verification / Become Seller ───────────────────────────
                if (appStatus == 'Pending')
                  _buildMemberPendingBanner(context)
                else if (appStatus == 'Rejected')
                  _buildMemberRejectedBanner(context, application)
                else
                  _buildMemberBecomeSellerCard(context),
                const SizedBox(height: 40),

                // ── Active ISOs — gallery style ────────────────────────────
                _buildActiveIsos(context, activeIsosAsync),

                // ── Private Salons (messages) ──────────────────────────────
                _buildPrivateSalons(context, recentConvosAsync),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Archive label + name ───────────────────────────────────────────────────

  Widget _memberArchiveLabel(Map<String, dynamic>? profile) {
    final displayName = profile?['display_name'] as String? ?? 'Member';
    final memberSince = profile?['created_at'] != null
        ? DateTime.tryParse(profile!['created_at'] as String)
        : null;
    final memberNo = (profile?['pfc_seller_code'] as String?) ??
        (memberSince != null ? memberSince.millisecondsSinceEpoch.toString().substring(7) : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          memberNo.isNotEmpty ? 'MEMBER ARCHIVE NO. $memberNo' : 'MEMBER ARCHIVE',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          displayName,
          style: GoogleFonts.notoSerif(
            fontSize: 38,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  // ── 2×2 gap-px stat grid ───────────────────────────────────────────────────

  Widget _buildMemberStatsGrid(
    int isoCount,
    int reviewsGiven,
    int unread,
    int transactions,
  ) {
    final cells = [
      _StatCell('ISOs', isoCount.toString(), false),
      _StatCell('Reviews', reviewsGiven.toString(), false),
      _StatCell('Unread', unread.toString(), true),
      _StatCell('Transactions', transactions.toString(), false),
    ];

    return Container(
      // The slate-200 background shows through as 1px gaps between cells
      color: AppColors.surfaceContainerHighest,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _statCell(cells[0])),
              const SizedBox(width: 1),
              Expanded(child: _statCell(cells[1])),
            ],
          ),
          const SizedBox(height: 1),
          Row(
            children: [
              Expanded(child: _statCell(cells[2])),
              const SizedBox(width: 1),
              Expanded(child: _statCell(cells[3])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCell(_StatCell cell) {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cell.label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cell.value,
            style: GoogleFonts.notoSerif(
              fontSize: 34,
              fontWeight: FontWeight.w300,
              color: cell.isAccent ? AppColors.warning : AppColors.primary,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Marketplace Pulse — dark emerald ──────────────────────────────────────

  Widget _buildMarketplacePulseCard(MarketplacePulseData? pulse) {
    final totalActive = pulse?.totalActive ?? 0;
    final verifiedSellers = pulse?.verifiedSellers ?? 0;
    final changeLabel = pulse?.weeklyChangeLabel ?? '—';
    final isPositive = pulse?.isPositive ?? true;
    final trendingFamily = pulse?.trendingFamily;
    final isLoading = pulse == null;

    return Container(
      padding: const EdgeInsets.all(28),
      color: AppColors.primary,
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06), width: 1),
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.04), width: 1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Text(
                    'MARKETPLACE PULSE',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF34d399),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08)),
              ),

              // Trending family (real data) or total listings fallback
              if (trendingFamily != null) ...[
                Text(
                  'TOP FAMILY',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trendingFamily,
                  style: GoogleFonts.notoSerif(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ] else ...[
                Text(
                  'ACTIVE LISTINGS',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 4),
                isLoading
                    ? Container(
                        width: 80,
                        height: 28,
                        color: Colors.white.withValues(alpha: 0.06),
                      )
                    : Text(
                        '$totalActive listings · $verifiedSellers sellers',
                        style: GoogleFonts.notoSerif(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
              ],

              const SizedBox(height: 16),

              // Week-over-week change (real)
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  isLoading
                      ? Container(
                          width: 56,
                          height: 32,
                          color: Colors.white.withValues(alpha: 0.06),
                        )
                      : Text(
                          changeLabel,
                          style: GoogleFonts.notoSerif(
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            color: isPositive
                                ? Colors.white.withValues(alpha: 0.85)
                                : const Color(0xFFfca5a5),
                          ),
                        ),
                  const SizedBox(width: 10),
                  Text(
                    'THIS WEEK',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Become a Seller — dark editorial ──────────────────────────────────────

  Widget _buildMemberBecomeSellerCard(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          Container(color: const Color(0xFF0f172a)), // slate-900
          // Gradient overlay from left
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0f172a), Colors.transparent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                Expanded(flex: 4, child: Container()),
              ],
            ),
          ),
          // Decorative right-side texture
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.42,
            child: Opacity(
              opacity: 0.15,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryGradientEnd, AppColors.primary],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Become a Seller',
                  style: GoogleFonts.notoSerif(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 190,
                  child: Text(
                    'List your fragrances, earn trust, and grow on PFC.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => context.go('/register/seller-apply'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 11),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      'APPLICATION',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberPendingBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/dashboard/verification'),
      child: Container(
        padding: const EdgeInsets.all(20),
        color: AppColors.warningContainer,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              color: AppColors.warning.withValues(alpha: 0.12),
              child: const Icon(Icons.hourglass_empty_rounded,
                  color: AppColors.warning, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verification Pending',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onBackground)),
                  const SizedBox(height: 2),
                  Text(
                      'Your seller application is under review. Tap to check status.',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberRejectedBanner(
      BuildContext context, Map<String, dynamic>? application) {
    final reason =
        application?['rejection_reason'] as String? ?? 'No reason provided.';
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.errorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                color: AppColors.error.withValues(alpha: 0.08),
                child: const Icon(Icons.cancel_outlined,
                    color: AppColors.error, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Application Not Approved',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error)),
                    const SizedBox(height: 2),
                    Text(reason,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/register/seller-apply'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: AppColors.primary,
                    child: Center(
                        child: Text('REAPPLY',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: Colors.white))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/dashboard/verification'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: AppColors.surfaceContainerLow,
                    child: Center(
                        child: Text('VIEW DETAILS',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: AppColors.textSecondary))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Active ISOs — gallery style ────────────────────────────────────────────

  Widget _buildActiveIsos(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> isosAsync,
  ) {
    return isosAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (isos) {
        if (isos.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    'Active ISOs',
                    style: GoogleFonts.notoSerif(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/dashboard/iso'),
                  child: Text(
                    'VIEW ALL',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                height: 1,
                color: AppColors.surfaceContainerLow),
            SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: isos.length,
                padding: EdgeInsets.zero,
                separatorBuilder: (_, __) => const SizedBox(width: 18),
                itemBuilder: (_, i) {
                  final iso = isos[i];
                  final isoId = iso['id'] as String;
                  final name = iso['fragrance_name'] as String? ?? '';
                  final brand = iso['brand'] as String? ?? '';
                  final status = iso['status'] as String? ?? '';
                  final isPublished = status == 'Published';

                  return GestureDetector(
                    onTap: () {
                      if (isPublished) {
                        context.push('/iso/$isoId');
                      } else {
                        context.push('/dashboard/iso/$isoId/edit');
                      }
                    },
                    child: SizedBox(
                      width: 160,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Portrait card
                          Expanded(
                            child: Container(
                              color: AppColors.card,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Placeholder — ISO listings have no photos
                                  Container(
                                    color: AppColors.surfaceContainerLow,
                                    child: Center(
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: GoogleFonts.notoSerif(
                                          fontSize: 56,
                                          fontWeight: FontWeight.w300,
                                          color: AppColors.primary
                                              .withValues(alpha: 0.15),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isPublished
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isPublished
                                    ? 'PUBLISHED'
                                    : 'DRAFT',
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: isPublished
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: GoogleFonts.notoSerif(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            brand,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  Widget _buildPrivateSalons(
    BuildContext context,
    AsyncValue<List<ConversationPreview>> convosAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                'Messages',
                style: GoogleFonts.notoSerif(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/dashboard/messages'),
              child: Text(
                'VIEW ALL',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            height: 1,
            color: AppColors.surfaceContainerLow),
        convosAsync.when(
          loading: () => const SizedBox(
            height: 72,
            child: Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (convos) {
            if (convos.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No conversations yet. Message a seller to get started.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.6,
                  ),
                ),
              );
            }
            return Column(
              children: convos.map((convo) {
                final initials = convo.otherUserName
                    .split(' ')
                    .where((w) => w.isNotEmpty)
                    .take(2)
                    .map((w) => w[0].toUpperCase())
                    .join();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => context.go('/dashboard/messages'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: convo.isUnread
                          ? const BoxDecoration(
                              color: AppColors.card,
                              border: Border(
                                left: BorderSide(
                                    color: AppColors.primary, width: 2),
                              ),
                            )
                          : BoxDecoration(
                              border: Border.all(
                                  color: AppColors.surfaceContainerHighest)),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: convo.isUnread
                                  ? AppColors.primaryGradientEnd
                                  : AppColors.surfaceContainerHighest,
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: convo.isUnread
                                      ? AppColors.onPrimary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        convo.otherUserName,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: convo.isUnread
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: convo.isUnread
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      convo.timeAgo,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  convo.lastMessageBody,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: convo.isUnread
                                        ? AppColors.onBackground
                                        : AppColors.textMuted,
                                    fontWeight: convo.isUnread
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                    height: 1.4,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// Internal data class for stat grid cells
class _StatCell {
  final String label;
  final String value;
  final bool isAccent;
  const _StatCell(this.label, this.value, this.isAccent);
}
