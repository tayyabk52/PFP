import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../iso/data/iso_model.dart';
import '../../iso/providers/iso_provider.dart';
import '../../sellers/data/models/seller_profile_model.dart';
import '../../sellers/providers/seller_provider.dart';
import '../data/conversation_repository.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  final String userId;
  const UserProfilePage({super.key, required this.userId});

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  bool _isMessaging = false;

  Future<void> _onMessageTap() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      context.go('/login?redirect=/u/${widget.userId}');
      return;
    }
    setState(() => _isMessaging = true);
    final conversationId =
        await ConversationRepository().getOrCreateConversation(widget.userId);
    if (!mounted) return;
    setState(() => _isMessaging = false);
    if (conversationId != null) {
      context.push('/dashboard/messages/$conversationId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(sellerProfileProvider(widget.userId));

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.onBackground,
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/iso'),
                  ),
                  const SizedBox(height: 16),
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load profile',
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
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () =>
                        ref.invalidate(sellerProfileProvider(widget.userId)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off_outlined,
                        size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      'User not found',
                      style: GoogleFonts.notoSerif(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final currentUser = ref.watch(currentUserProvider);
        final isOwnProfile = currentUser?.id == widget.userId;
        final showMessageButton = !isOwnProfile;

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
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: AppColors.surfaceContainerLow.withValues(alpha: 0.92),
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.onBackground),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/marketplace'),
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
                          _buildHeroHeader(profile, showMessageButton),
                          if (profile.isVerifiedSeller ||
                              profile.transactionCount > 0) ...[
                            const SizedBox(height: 16),
                            _buildTrustChips(profile),
                          ],
                          if (profile.isVerifiedSeller) ...[
                            const SizedBox(height: 16),
                            _buildStatsBar(profile),
                            const SizedBox(height: 16),
                            _buildReviewsSection(profile),
                            const SizedBox(height: 16),
                            _buildActiveListings(context, profile),
                          ],
                          const SizedBox(height: 24),
                          _buildActiveIsos(context, profile),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroHeader(SellerProfile profile, bool showMessageButton) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 760;

        final avatar = CircleAvatar(
          radius: isDesktop ? 48 : 40,
          backgroundColor: AppColors.surfaceContainerLow,
          backgroundImage: profile.avatarUrl != null
              ? CachedNetworkImageProvider(profile.avatarUrl!)
              : null,
          child: profile.avatarUrl == null
              ? Text(
                  _initials(profile.displayNameOrFallback),
                  style: GoogleFonts.notoSerif(
                    fontSize: isDesktop ? 30 : 26,
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
                fontSize: isDesktop ? 28 : 24,
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
              alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
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
            if (showMessageButton && isDesktop) ...[
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  onPressed: _isMessaging ? null : _onMessageTap,
                  icon: _isMessaging
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Icon(Icons.mail_outline_rounded, size: 18),
                  label: Text(
                    'MESSAGE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );

        return Container(
          color: AppColors.card,
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 40 : 24,
            32,
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
                    const SizedBox(height: 16),
                    identityBlock,
                    if (showMessageButton) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                          ),
                          onPressed: _isMessaging ? null : _onMessageTap,
                          icon: _isMessaging
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.mail_outline_rounded, size: 18),
                          label: Text(
                            'MESSAGE',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildTrustChips(SellerProfile profile) {
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

  Widget _buildStatsBar(SellerProfile profile) {
    final statsAsync = ref.watch(sellerStatsProvider(profile.id));
    return statsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) => LayoutBuilder(
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
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: items,
                  ),
          );
        },
      ),
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

  Widget _buildReviewsSection(SellerProfile profile) {
    final reviewsAsync = ref.watch(sellerReviewsProvider(profile.id));
    return reviewsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (reviews) => Column(
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
      ),
    );
  }

  Widget _buildReviewCard(SellerReview review) {
    final timeAgo = _relativeDate(review.submittedAt);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 16,
                  color:
                      i < review.rating ? AppColors.goldAccent : AppColors.textMuted,
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: AppColors.onBackground,
              ),
            ),
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

  Widget _buildActiveListings(BuildContext context, SellerProfile profile) {
    final listingsAsync = ref.watch(sellerListingsProvider(profile.id));
    return listingsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (listings) => LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 760;
          final hPadding = isDesktop ? 40.0 : 24.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
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
                  padding: EdgeInsets.symmetric(horizontal: hPadding),
                  child: Text(
                    'No active listings',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              else if (isDesktop)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPadding),
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
                )
              else
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: hPadding - 4),
                    itemCount: listings.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) =>
                        _buildListingCard(context, listings[index]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, Map<String, dynamic> listing) {
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
                            color: AppColors.surfaceContainerLow),
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

  Widget _buildActiveIsos(BuildContext context, SellerProfile profile) {
    final isosAsync = ref.watch(isoPostsForUserProvider(profile.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'ACTIVE ISO REQUESTS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        isosAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (isos) {
            if (isos.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'No active ISO requests',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              );
            }
            return Column(
              children: isos
                  .map((iso) => _IsoRow(iso: iso))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
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

// ---------------------------------------------------------------------------
// _IsoRow — small ISO row card for the profile page
// ---------------------------------------------------------------------------

class _IsoRow extends StatelessWidget {
  final IsoPost iso;
  const _IsoRow({required this.iso});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/iso/${iso.id}'),
      child: Container(
        color: AppColors.surfaceContainerLow,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    iso.fragranceName,
                    style: GoogleFonts.notoSerif(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    iso.brand,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (iso.budgetPkr > 0)
              Text(
                'PKR ${iso.budgetPkr}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              )
            else
              Text(
                'Flexible',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
