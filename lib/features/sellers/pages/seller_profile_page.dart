import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/seller_profile_model.dart';
import '../providers/seller_provider.dart';

class SellerProfilePage extends ConsumerWidget {
  final String code;
  const SellerProfilePage({super.key, required this.code});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(sellerProfileProvider(code));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/marketplace');
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceContainerLow,
        body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load seller',
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off_outlined,
                        size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      'Seller not found',
                      style: GoogleFonts.notoSerif(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return _SellerProfileBody(profile: profile);
        },
      ),
    ),
    );
  }
}

class _SellerProfileBody extends ConsumerWidget {
  final SellerProfile profile;
  const _SellerProfileBody({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(sellerStatsProvider(profile.id));
    final reviewsAsync = ref.watch(sellerReviewsProvider(profile.id));
    final listingsAsync = ref.watch(sellerListingsProvider(profile.id));

    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          backgroundColor: AppColors.surfaceContainerLow.withValues(alpha: 0.92),
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.onBackground),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/marketplace');
              }
            },
          ),
          pinned: true,
        ),

        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero header
                  _buildHeroHeader(context),
                  const SizedBox(height: 16),

                  // Stats bar
                  statsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (stats) => _buildStatsBar(stats),
                  ),
                  const SizedBox(height: 8),

                  // Trust indicators
                  _buildTrustIndicators(),
                  const SizedBox(height: 24),

                  // Reviews section
                  reviewsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (reviews) => _buildReviewsSection(reviews),
                  ),
                  const SizedBox(height: 24),

                  // Active listings section
                  listingsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (listings) =>
                        _buildActiveListingsSection(context, listings),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 760;

        final avatar = CircleAvatar(
          radius: isDesktop ? 48 : 36,
          backgroundColor: AppColors.surfaceContainerLow,
          backgroundImage: profile.avatarUrl != null
              ? CachedNetworkImageProvider(profile.avatarUrl!)
              : null,
          child: profile.avatarUrl == null
              ? Text(
                  _initials(profile.displayNameOrFallback),
                  style: GoogleFonts.notoSerif(
                    fontSize: isDesktop ? 28 : 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                )
              : null,
        );

        final identityBlock = Column(
          crossAxisAlignment: isDesktop
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Text(
              profile.displayNameOrFallback,
              style: GoogleFonts.notoSerif(
                fontSize: isDesktop ? 28 : 22,
                fontWeight: FontWeight.w700,
                color: AppColors.onBackground,
              ),
              textAlign: isDesktop ? TextAlign.start : TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: isDesktop
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                if (profile.pfcSellerCode != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    color: AppColors.surfaceContainerHighest,
                    child: Text(
                      profile.pfcSellerCode!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (profile.verifiedAt != null)
                  const Icon(Icons.verified,
                      size: 20, color: AppColors.goldAccent),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment:
                  isDesktop ? WrapAlignment.start : WrapAlignment.center,
              spacing: 14,
              children: [
                if (profile.city != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        profile.city!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(
                      'Member since ${DateFormat('MMM yyyy').format(profile.createdAt)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        return Container(
          color: AppColors.card,
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 40 : 24,
            isDesktop ? 32 : 24,
            isDesktop ? 40 : 24,
            24,
          ),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    const SizedBox(width: 28),
                    Expanded(child: identityBlock),
                  ],
                )
              : Column(
                  children: [
                    avatar,
                    const SizedBox(height: 14),
                    identityBlock,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildStatsBar(SellerStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 760;
        final items = [
          _statCard('Listings', stats.totalListings.toString(), isDesktop),
          _statCard('Sold', stats.totalSales.toString(), isDesktop),
          _statCard(
            'Avg Rating',
            stats.averageRating > 0
                ? stats.averageRating.toStringAsFixed(1)
                : '--',
            isDesktop,
          ),
          _statCard('Reviews', stats.reviewCount.toString(), isDesktop),
        ];
        return Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : 20),
          child: isDesktop
              ? Row(
                  children: items
                      .map((w) => Expanded(child: w))
                      .expand((w) => [w, const SizedBox(width: 8)])
                      .toList()
                    ..removeLast(),
                )
              : Wrap(spacing: 10, runSpacing: 10, children: items),
        );
      },
    );
  }

  Widget _statCard(String label, String value, [bool isDesktop = false]) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 20 : 14,
        horizontal: isDesktop ? 16 : 10,
      ),
      color: AppColors.card,
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.notoSerif(
              fontSize: isDesktop ? 22 : 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrustIndicators() {
    final chips = <Widget>[];

    if (profile.verifiedAt != null) {
      chips.add(_trustChip(
        'Verified Seller',
        AppColors.goldAccent,
        AppColors.goldBadgeBg,
      ));
    }

    if (profile.isLegacyFbSeller) {
      chips.add(_trustChip(
        'Legacy FB Seller',
        AppColors.textSecondary,
        AppColors.surfaceContainerLow,
      ));
    }

    if (profile.transactionCount > 0) {
      chips.add(_trustChip(
        '${profile.transactionCount} Transactions',
        AppColors.textSecondary,
        AppColors.surfaceContainerLow,
      ));
    }

    if (profile.ratingCount > 0) {
      chips.add(_trustChip(
        '${profile.avgRating.toStringAsFixed(1)} ★  (${profile.ratingCount} review${profile.ratingCount == 1 ? '' : 's'})',
        AppColors.goldAccent,
        AppColors.goldBadgeBg,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _trustChip(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: bgColor,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildReviewsSection(List<SellerReview> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'REVIEWS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'No reviews yet',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          )
        else
          ...reviews.take(5).map((review) => _buildReviewCard(review)),
      ],
    );
  }

  Widget _buildReviewCard(SellerReview review) {
    final timeAgo = _relativeDate(review.submittedAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reviewer info row
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surfaceContainerLow,
                  backgroundImage: review.reviewerAvatarUrl != null
                      ? CachedNetworkImageProvider(review.reviewerAvatarUrl!)
                      : null,
                  child: review.reviewerAvatarUrl == null
                      ? Text(
                          _initials(review.reviewerNameOrFallback),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerNameOrFallback,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Stars
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 16,
                  color: i < review.rating
                      ? AppColors.goldAccent
                      : AppColors.textMuted,
                );
              }),
            ),
            const SizedBox(height: 8),
            // Comment
            Text(
              review.comment,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: AppColors.onBackground,
              ),
            ),
            // Fragrance info
            if (review.fragranceName != null) ...[
              const SizedBox(height: 8),
              Text(
                '${review.fragranceName}${review.brand != null ? ' by ${review.brand}' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveListingsSection(
    BuildContext context,
    List<Map<String, dynamic>> listings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'ACTIVE LISTINGS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (listings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'No active listings',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 760;
              if (isDesktop) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: listings.length,
                    itemBuilder: (context, index) =>
                        _buildListingCard(context, listings[index]),
                  ),
                );
              }
              return SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: listings.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      _buildListingCard(context, listings[index]),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildListingCard(
      BuildContext context, Map<String, dynamic> listing) {
    final photos = listing['listing_photos'] as List? ?? [];
    final photoUrl =
        photos.isNotEmpty ? (photos[0] as Map)['file_url'] as String? : null;
    final name = listing['fragrance_name'] as String? ?? '';
    final brand = listing['brand'] as String? ?? '';
    final price = listing['price_pkr'];
    final id = listing['id'] as String;

    return GestureDetector(
      onTap: () => context.push('/marketplace/$id'),
      child: Container(
        width: 165,
        color: AppColors.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: SizedBox(
                height: 120,
                width: 165,
                child: photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.surfaceContainerLow,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceContainerLow,
                          child: const Icon(Icons.image_not_supported_outlined,
                              color: AppColors.textMuted),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceContainerLow,
                        child: const Icon(Icons.image_outlined,
                            color: AppColors.textMuted, size: 32),
                      ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSerif(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (price != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'PKR ${NumberFormat('#,###').format(price)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
