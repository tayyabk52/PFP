import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/seller_profile_model.dart';
import '../providers/seller_provider.dart';

class SellersListPage extends ConsumerStatefulWidget {
  const SellersListPage({super.key});

  @override
  ConsumerState<SellersListPage> createState() => _SellersListPageState();
}

class _SellersListPageState extends ConsumerState<SellersListPage> {
  String? _keyword;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final trimmed = value.trim().isEmpty ? null : value.trim();
    if (trimmed != _keyword) {
      setState(() => _keyword = trimmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellersAsync = ref.watch(sellersListProvider(_keyword));
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: CustomScrollView(
        slivers: [
          // 1. SliverAppBar — pinned, glassmorphism-like
          SliverAppBar(
            pinned: true,
            backgroundColor:
                AppColors.surfaceContainerLow.withValues(alpha: 0.92),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: AppColors.primary,
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/marketplace');
                }
              },
            ),
          ),

          // 2. Header section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 32 : 16,
                8,
                isDesktop ? 32 : 16,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE ARCHIVE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Legit Sellers',
                    style: GoogleFonts.notoSerif(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Community-verified fragrance traders.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 3. Search field
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 32 : 16,
                0,
                isDesktop ? 32 : 16,
                20,
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onBackground,
                ),
                decoration: InputDecoration(
                  hintText: 'Search sellers...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerHighest,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: AppColors.ghostBorderBase.withValues(alpha: 0.15),
                    ),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // 4. Sellers grid / list / loading / empty
          sellersAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Something went wrong. Please try again.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            data: (sellers) {
              if (sellers.isEmpty) {
                return _buildEmptyState(context);
              }

              if (!isTablet) {
                // Mobile: SliverList
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SellerCard(seller: sellers[index]),
                      ),
                      childCount: sellers.length,
                    ),
                  ),
                );
              }

              // Tablet / Desktop: SliverGrid
              final crossAxisCount = isDesktop ? 3 : 2;
              return SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 16,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _SellerCard(seller: sellers[index]),
                    childCount: sellers.length,
                  ),
                ),
              );
            },
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 56,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                _keyword != null
                    ? 'No sellers found for "$_keyword"'
                    : 'No verified sellers yet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back soon as more sellers join the community.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/marketplace'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  'Explore Marketplace',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  final SellerSummary seller;

  const _SellerCard({required this.seller});

  @override
  Widget build(BuildContext context) {
    final destination =
        seller.pfcSellerCode != null && seller.pfcSellerCode!.isNotEmpty
            ? '/sellers/${seller.pfcSellerCode}'
            : '/sellers/${seller.id}';

    return InkWell(
      onTap: () => context.push(destination),
      mouseCursor: SystemMouseCursors.click,
      hoverColor: AppColors.surfaceContainerLow.withValues(alpha: 0.3),
      child: Container(
        color: AppColors.card,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            _SellerAvatar(seller: seller),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name row + verified badge
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          seller.displayNameOrFallback,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSerif(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onBackground,
                          ),
                        ),
                      ),
                      if (seller.isVerifiedSeller) ...[
                        const SizedBox(width: 6),
                        _VerifiedBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Seller code chip
                  if (seller.pfcSellerCode != null &&
                      seller.pfcSellerCode!.isNotEmpty)
                    _SellerCodeChip(code: seller.pfcSellerCode!),

                  const SizedBox(height: 6),

                  // City + transaction count
                  Row(
                    children: [
                      if (seller.city != null && seller.city!.isNotEmpty) ...[
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          seller.city!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Icon(
                        Icons.swap_horiz_rounded,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${seller.transactionCount} deals',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerAvatar extends StatelessWidget {
  final SellerSummary seller;

  const _SellerAvatar({required this.seller});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final name = seller.displayNameOrFallback;

    if (seller.avatarUrl != null && seller.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.surfaceContainerHighest,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: seller.avatarUrl!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            placeholder: (_, __) => _InitialsAvatar(initials: _initials(name)),
            errorWidget: (_, __, ___) =>
                _InitialsAvatar(initials: _initials(name)),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.surfaceContainerHighest,
      child: _InitialsAvatar(initials: _initials(name)),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;

  const _InitialsAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Text(
      initials,
      style: GoogleFonts.notoSerif(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.goldBadgeBg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        'VERIFIED',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.goldAccent,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SellerCodeChip extends StatelessWidget {
  final String code;

  const _SellerCodeChip({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: AppColors.surfaceContainerHighest,
      child: Text(
        code,
        style: GoogleFonts.inter(
          fontSize: 10,
          letterSpacing: 1.2,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
