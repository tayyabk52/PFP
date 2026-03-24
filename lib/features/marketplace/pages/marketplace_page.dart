import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/profile_provider.dart';
import '../data/models/listing_model.dart';
import '../providers/listing_provider.dart';
import 'widgets/listing_card.dart';

// ---------------------------------------------------------------------------
// Sticky filter bar delegate
// ---------------------------------------------------------------------------

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final ListingType? selectedType;
  final ValueChanged<ListingType?> onTypeSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onRefineTap;
  final bool hasActiveFilters;
  final int? resultCount;

  const _FilterBarDelegate({
    required this.selectedType,
    required this.onTypeSelected,
    required this.searchController,
    required this.onSearchSubmitted,
    required this.onRefineTap,
    required this.hasActiveFilters,
    this.resultCount,
  });

  static const double _height = 112.0;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(_FilterBarDelegate old) =>
      selectedType != old.selectedType ||
      resultCount != old.resultCount ||
      hasActiveFilters != old.hasActiveFilters;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: _height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.ghostBorderBase.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: Column(
            children: [
              // Pills row
              SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Refine button
                      GestureDetector(
                        onTap: onRefineTap,
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          color: AppColors.primary,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.tune_rounded,
                                size: 14,
                                color: AppColors.onPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'REFINE',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.0,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                              if (hasActiveFilters) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.goldAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _TypePill(
                                label: 'All',
                                isActive: selectedType == null,
                                onTap: () => onTypeSelected(null),
                              ),
                              const SizedBox(width: 8),
                              ...ListingType.values.where((t) => t != ListingType.iso).map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _TypePill(
                                    label: _pillLabel(t),
                                    isActive: selectedType == t,
                                    onTap: () => onTypeSelected(t),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (resultCount != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          '$resultCount Results',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: searchController,
                    onSubmitted: onSearchSubmitted,
                    textInputAction: TextInputAction.search,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.onBackground,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search fragrances…',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_outlined,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  String _pillLabel(ListingType t) => switch (t) {
        ListingType.fullBottle => 'Full Bottles',
        ListingType.decantSplit => 'Decants',
        ListingType.iso => 'ISO',
        ListingType.swap => 'Swaps',
        ListingType.auction => 'Auctions',
      };
}

// ---------------------------------------------------------------------------
// Type pill widget
// ---------------------------------------------------------------------------

class _TypePill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TypePill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.onPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MarketplacePage
// ---------------------------------------------------------------------------

class MarketplacePage extends ConsumerStatefulWidget {
  const MarketplacePage({super.key});

  @override
  ConsumerState<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends ConsumerState<MarketplacePage> {
  ListingType? _selectedType;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTypeSelected(ListingType? type) {
    setState(() => _selectedType = type);
    ref.read(listingFiltersProvider.notifier).update(
          (f) => f.copyWith(
            type: type,
            clearType: type == null,
          ),
        );
  }

  void _onSearchSubmitted(String value) {
    final keyword = value.trim().isEmpty ? null : value.trim();
    ref.read(listingFiltersProvider.notifier).update(
          (f) => keyword != null
              ? f.copyWith(keyword: keyword)
              : f.copyWith(clearKeyword: true),
        );
  }

  bool _hasActiveFilters(ListingFilters f) =>
      f.condition != null ||
      f.minPricePkr != null ||
      f.maxPricePkr != null ||
      f.verifiedOnly;

  void _showFilterDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      builder: (ctx) => _FilterDrawer(
        currentFilters: ref.read(listingFiltersProvider),
        onApply: (updated) {
          ref.read(listingFiltersProvider.notifier).state = updated;
          setState(() => _selectedType = updated.type);
        },
      ),
    );
  }

  int _columnCount(double width) {
    if (width < 480) return 2;
    if (width < 720) return 3;
    if (width < 1024) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(listingFiltersProvider);
    final listingsAsync = ref.watch(listingsProvider(filters));
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 600;

    final hPadding = screenWidth < 480 ? 16.0 : 24.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: isNarrow
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              onPressed: () {
                final role = ref.read(currentProfileProvider).valueOrNull?['role'] as String?;
                final isSeller = role == 'seller' || role == 'admin';
                context.go(isSeller ? '/dashboard/create-listing' : '/iso/create');
              },
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(listingsProvider(filters));
        },
        child: CustomScrollView(
        cacheExtent: 800,
        slivers: [
          // ----------------------------------------------------------------
          // Hero SliverAppBar
          // ----------------------------------------------------------------
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: screenWidth >= 600 ? 600.0 : 500.0,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'The Olfactory Archive',
              style: GoogleFonts.notoSerif(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.onPrimary,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _HeroBackground(screenWidth: screenWidth),
            ),
          ),

          // ----------------------------------------------------------------
          // Sticky filter bar
          // ----------------------------------------------------------------
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterBarDelegate(
              selectedType: _selectedType,
              onTypeSelected: _onTypeSelected,
              searchController: _searchController,
              onSearchSubmitted: _onSearchSubmitted,
              onRefineTap: _showFilterDrawer,
              hasActiveFilters: _hasActiveFilters(filters),
              resultCount: listingsAsync.valueOrNull?.length,
            ),
          ),

          // ----------------------------------------------------------------
          // Grid / states
          // ----------------------------------------------------------------
          listingsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Something went wrong.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      err.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        onPressed: () => ref.invalidate(listingsProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            data: (listings) {
              if (listings.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No listings found',
                          style: GoogleFonts.notoSerif(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final columns = _columnCount(screenWidth);

              // Compute the exact card width at this screen size so the grid
              // cell height is always sufficient. Formula:
              //   cardWidth = (availableWidth - gaps) / columns
              //   cellHeight = image(4:5) + contentBlock
              // contentBlock = 12 top-pad + name + brand + chips-row + footer
              //               + 12 bottom-pad ≈ 144 px (with 8 px buffer).
              const double crossSpacing = 16;
              // mainAxisExtent = image (4:5 ratio) + content block.
              // Content block = 24px padding + name + brand + chips + footer.
              // 140px gives the Spacer comfortable room so footer never crowds,
              // even with pixel-exact Inter metrics at height:1.2.
              const double contentBlock = 140;
              final cardWidth = (screenWidth - 2 * hPadding -
                      (columns - 1) * crossSpacing) /
                  columns;
              // mainAxisExtent is preferred over childAspectRatio: it sets the
              // cell height directly in pixels, independent of float rounding.
              final cellHeight = cardWidth * (5 / 4) + contentBlock;

              return SliverPadding(
                padding: EdgeInsets.fromLTRB(hPadding, 24, hPadding, 24),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: crossSpacing,
                    mainAxisSpacing: 16,
                    mainAxisExtent: cellHeight,
                  ),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return ListingCard(
                      listing: listing,
                      onTap: () => context.push('/marketplace/${listing.id}'),
                    );
                  },
                ),
              );
            },
          ),

          // ----------------------------------------------------------------
          // Security advisory + footer
          // ----------------------------------------------------------------
          const SliverToBoxAdapter(
            child: _Footer(),
          ),
        ],
      ),
      ),
    ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero background
// ---------------------------------------------------------------------------

class _HeroBackground extends StatelessWidget {
  final double screenWidth;

  const _HeroBackground({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final isWide = screenWidth >= 600;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Dark gradient at the top to ensure AppBar text legibility
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          Positioned.fill(
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Eyebrow
                  Text(
                    'Premium Collection \u2014 Est. 2024',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.5,
                      color: AppColors.goldAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Headline
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Curating Pakistan\u2019s\nFinest Scents.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSerif(
                        fontSize: isWide ? 44 : 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Discover authentic fragrances from trusted Pakistani sellers.\n'
                      'Buy, sell, and swap within the PFC community.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.onPrimary.withValues(alpha: 0.80),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Footer: security advisory + branding
// ---------------------------------------------------------------------------

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security advisory card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: const Border(
                left: BorderSide(
                  color: AppColors.primary,
                  width: 4,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Advisory',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All transactions are off-platform. PFC does not process '
                        'or guarantee payments. Always verify seller credentials '
                        'and exercise due diligence before transferring funds.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Footer branding
          Center(
            child: Column(
              children: [
                Text(
                  'The Olfactory Archive',
                  style: GoogleFonts.notoSerif(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pakistan Fragrance Community \u00b7 Est. 2024',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter drawer — bottom sheet for condition, price, verified seller
// ---------------------------------------------------------------------------

class _FilterDrawer extends StatefulWidget {
  final ListingFilters currentFilters;
  final ValueChanged<ListingFilters> onApply;

  const _FilterDrawer({
    required this.currentFilters,
    required this.onApply,
  });

  @override
  State<_FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<_FilterDrawer> {
  static const double _maxPrice = 150000;

  ListingCondition? _condition;
  RangeValues _priceRange = const RangeValues(0, _maxPrice);
  bool _verifiedOnly = false;

  @override
  void initState() {
    super.initState();
    _condition = widget.currentFilters.condition;
    _priceRange = RangeValues(
      (widget.currentFilters.minPricePkr ?? 0).toDouble(),
      (widget.currentFilters.maxPricePkr ?? _maxPrice).toDouble(),
    );
    _verifiedOnly = widget.currentFilters.verifiedOnly;
  }

  void _reset() => setState(() {
        _condition = null;
        _priceRange = const RangeValues(0, _maxPrice);
        _verifiedOnly = false;
      });

  void _apply() {
    widget.onApply(ListingFilters(
      type: widget.currentFilters.type,
      keyword: widget.currentFilters.keyword,
      condition: _condition,
      minPricePkr: _priceRange.start > 0 ? _priceRange.start.toInt() : null,
      maxPricePkr:
          _priceRange.end < _maxPrice ? _priceRange.end.toInt() : null,
      verifiedOnly: _verifiedOnly,
    ));
    Navigator.of(context).pop();
  }

  String _fmt(double v) =>
      v >= _maxPrice ? 'PKR 150K+' : 'PKR ${NumberFormat('#,###').format(v.toInt())}';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
          child: Row(
            children: [
              Text(
                'Refine Archive',
                style: GoogleFonts.notoSerif(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        const Divider(height: 1, thickness: 1, color: AppColors.surfaceContainerLow),

        // Scrollable body
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Price Range ──────────────────────────────────────────
                const _SectionLabel('Price Range (PKR)'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fmt(_priceRange.start),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      _fmt(_priceRange.end),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.surfaceContainerHighest,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withValues(alpha: 0.10),
                    trackHeight: 2,
                  ),
                  child: RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: _maxPrice,
                    divisions: 150,
                    onChanged: (v) => setState(() => _priceRange = v),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Condition ────────────────────────────────────────────
                const _SectionLabel('Condition'),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ListingCondition.values.map((c) {
                    final active = _condition == c;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _condition = active ? null : c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        color: active
                            ? AppColors.primary
                            : AppColors.surfaceContainerLow,
                        child: Text(
                          c.value.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            color: active
                                ? AppColors.onPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // ── Verified Seller ──────────────────────────────────────
                const _SectionLabel('Seller'),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => setState(() => _verifiedOnly = !_verifiedOnly),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(16),
                    color: _verifiedOnly
                        ? AppColors.primary.withValues(alpha: 0.06)
                        : AppColors.surfaceContainerLow,
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified,
                          size: 18,
                          color: _verifiedOnly
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified Sellers Only',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _verifiedOnly
                                      ? AppColors.primary
                                      : AppColors.onBackground,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Show listings from PFC-verified sellers',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _verifiedOnly,
                          onChanged: (v) => setState(() => _verifiedOnly = v),
                          activeThumbColor: AppColors.onPrimary,
                          activeTrackColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Footer actions
        Container(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, 16 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.ghostBorderBase),
                      shape: const RoundedRectangleBorder(),
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: _reset,
                    child: Text(
                      'RESET ALL',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: const RoundedRectangleBorder(),
                    ),
                    onPressed: _apply,
                    child: Text(
                      'APPLY FILTERS',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section label helper
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: AppColors.textSecondary,
      ),
    );
  }
}
