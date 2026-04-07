import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/data/conversation_repository.dart';
import '../data/models/listing_model.dart';
import '../providers/listing_provider.dart';
import '../../sellers/pages/widgets/review_bottom_sheet.dart';

class ListingDetailPage extends ConsumerStatefulWidget {
  final String listingId;
  const ListingDetailPage({super.key, required this.listingId});

  @override
  ConsumerState<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends ConsumerState<ListingDetailPage> {
  final _pageController = PageController();
  int _currentPhotoIndex = 0;
  bool _messagingLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingDetailProvider(widget.listingId));

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
      child: listingAsync.when(
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
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load listing',
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
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/marketplace'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.ghostBorderBase),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      data: (listing) {
        if (listing == null) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        'Listing not found',
                        style: GoogleFonts.notoSerif(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This listing may have been removed or is no longer available.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                              color: AppColors.ghostBorderBase),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.surface,
          bottomNavigationBar: _buildStickyActions(listing),
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(listing),
              SliverToBoxAdapter(
                child: _buildContent(listing),
              ),
            ],
          ),
        );
      },
    ),
    );
  }

  // ---------------------------------------------------------------------------
  // SliverAppBar — photo carousel
  // ---------------------------------------------------------------------------

  SliverAppBar _buildSliverAppBar(Listing listing) {
    final hasPhotos = listing.photos.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/marketplace'),
      ),
      title: Text(
        listing.fragranceName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.notoSerif(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.onPrimary,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Main photo carousel
            if (hasPhotos)
              PageView.builder(
                controller: _pageController,
                itemCount: listing.photos.length,
                onPageChanged: (index) {
                  setState(() => _currentPhotoIndex = index);
                },
                itemBuilder: (context, index) {
                  final photo = listing.photos[index];
                  return CachedNetworkImage(
                    imageUrl: photo.fileUrl,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 200),
                    placeholder: (_, __) => const ColoredBox(
                      color: AppColors.surfaceContainerLow,
                    ),
                    errorWidget: (_, __, ___) => const ColoredBox(
                      color: AppColors.surfaceContainerLow,
                    ),
                  );
                },
              )
            else
              Container(
                color: AppColors.surfaceContainerLow,
                child: const Center(
                  child: Icon(Icons.image_outlined,
                      size: 48, color: AppColors.textMuted),
                ),
              ),

            // Auction countdown badge (top-left) — only when active
            if (listing.isAuctionActive)
              Positioned(
                top: 56,
                left: 16,
                child: _buildAuctionBadge(listing.auctionEndAt!),
              ),

            // Page indicator dots (bottom-center)
            if (hasPhotos && listing.photos.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(listing.photos.length, (index) {
                    final isActive = index == _currentPhotoIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.onPrimary
                            : AppColors.onPrimary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),

            // Thumbnail strip (bottom)
            if (hasPhotos && listing.photos.length > 1)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: _buildThumbnailStrip(listing),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionBadge(DateTime endAt) {
    final now = DateTime.now();
    final diff = endAt.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    final minutes = diff.inMinutes.remainder(60);
    final label = 'Ends In: ${days}d ${hours}h ${minutes}m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailStrip(Listing listing) {
    final thumbs = listing.photos.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(thumbs.length, (index) {
          final isSelected = index == _currentPhotoIndex;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppColors.onPrimary : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: CachedNetworkImage(
                  imageUrl: thumbs[index].fileUrl,
                  fit: BoxFit.cover,
                  fadeInDuration: Duration.zero,
                  errorWidget: (_, __, ___) => const ColoredBox(
                      color: AppColors.surfaceContainerHighest),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main content
  // ---------------------------------------------------------------------------

  Widget _buildContent(Listing listing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(listing),
        _buildPricingCard(listing),
        _buildSellerCard(listing),
        _buildSecurityAdvisory(),
        _buildOlfactoryNarrative(listing),
        const SizedBox(height: 32),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section 1 — Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(Listing listing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ARCHIVE REGISTRY',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  listing.fragranceName,
                  style: GoogleFonts.notoSerif(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  listing.brand,
                  style: GoogleFonts.notoSerif(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.surfaceContainerLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SALE POST NUMBER',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '#${listing.salePostNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 2 — Pricing & Details card
  // ---------------------------------------------------------------------------

  Widget _buildPricingCard(Listing listing) {
    final priceDisplay = listing.listingType == ListingType.swap &&
            listing.pricePkr == 0
        ? 'Swap — No Cash Component'
        : 'PKR ${NumberFormat('#,###').format(listing.pricePkr)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: brand info + price
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.brand.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Eau de Parfum',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 13, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              'Authentic Item Only',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    priceDisplay,
                    style: GoogleFonts.inter(
                      fontSize: listing.listingType == ListingType.swap &&
                              listing.pricePkr == 0
                          ? 15
                          : 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.surfaceContainerLow),
              const SizedBox(height: 20),

              // Detail fields grid (2-column)
              _buildDetailGrid(listing),

              // Condition notes / delivery details
              if (listing.conditionNotes != null ||
                  listing.deliveryDetails != null) ...[
                const SizedBox(height: 16),
                const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.surfaceContainerLow),
                const SizedBox(height: 16),
                _buildNotesField(listing),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailGrid(Listing listing) {
    final fields = <_DetailField>[];

    if (listing.fragranceFamily != null) {
      fields.add(_DetailField('Fragrance Family', listing.fragranceFamily!));
    }

    if (listing.vintageYear != null) {
      fields.add(_DetailField('Vintage Year', listing.vintageYear.toString()));
    }

    final sizeInt = listing.sizeMl.toInt();
    final sizeLabel = listing.sizeMl == sizeInt.toDouble()
        ? '${sizeInt}ml'
        : '${listing.sizeMl}ml';
    fields.add(_DetailField('Size', sizeLabel));

    fields.add(_DetailField(
        'Condition', listing.condition?.value ?? 'Not specified'));

    fields.add(_DetailField('Listing Type', listing.listingType.value));

    if (listing.listingType == ListingType.decantSplit &&
        listing.quantityAvailable != null) {
      fields.add(_DetailField(
          'Quantity Available', listing.quantityAvailable!.toString()));
    }

    if (listing.isAuction && listing.auctionEndAt != null) {
      final formatted =
          DateFormat('d MMM yyyy, h:mm a').format(listing.auctionEndAt!);
      fields.add(_DetailField('Auction Ends', formatted));
    }

    if (fields.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 0,
      runSpacing: 0,
      children: List.generate(fields.length, (index) {
        return SizedBox(
          width: MediaQuery.of(context).size.width / 2 - 36,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fields[index].label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  fields[index].value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onBackground,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNotesField(Listing listing) {
    final notes = listing.conditionNotes ?? listing.deliveryDetails ?? '';
    final label =
        listing.conditionNotes != null ? 'Condition Notes' : 'Delivery Details';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          notes,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.65,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section 3 — Seller card
  // ---------------------------------------------------------------------------

  Widget _buildSellerCard(Listing listing) {
    final seller = listing.seller;
    if (seller == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        onTap: () {
          final code = seller.pfcSellerCode ?? seller.id;
          context.push('/sellers/$code');
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(seller),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          seller.displayNameOrFallback,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                          ),
                        ),
                        if (seller.isVerifiedSeller) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.verified,
                              size: 16, color: AppColors.goldAccent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${seller.transactionCount} Successful Sale${seller.transactionCount == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (seller.city != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            seller.city!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(SellerInfo seller) {
    final initials = seller.displayNameOrFallback
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    if (seller.avatarUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: seller.avatarUrl!,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 150),
          errorWidget: (_, __, ___) => _buildInitialsAvatar(initials),
        ),
      );
    }
    return _buildInitialsAvatar(initials);
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGradientEnd,
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onPrimary,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 4 — Security advisory
  // ---------------------------------------------------------------------------

  Widget _buildSecurityAdvisory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: const Border(
            left: BorderSide(color: AppColors.error, width: 4),
          ),
          color: AppColors.errorContainer.withValues(alpha: 0.4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_rounded,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SECURITY ADVISORY',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'This transaction requires manual payment (Bank Transfer / JazzCash / EasyPaisa). PFC does not provide escrow. Verify seller reputation before transacting.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sticky bottom action bar — always visible, never hidden by scroll
  // ---------------------------------------------------------------------------

  Widget _buildStickyActions(Listing listing) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwner = currentUser != null && currentUser.id == listing.sellerId;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: isOwner
              ? _buildOwnerActions(listing)
              : _buildBuyerActions(listing),
        ),
      ),
    );
  }

  Widget _buildOwnerActions(Listing listing) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: const RoundedRectangleBorder(),
              ),
              onPressed: () =>
                  context.go('/dashboard/my-listings/${listing.id}/edit'),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(
                'EDIT LISTING',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: AppColors.ghostBorderBase, width: 1),
                shape: const RoundedRectangleBorder(),
                foregroundColor: AppColors.primary,
              ),
              onPressed: () => context.go('/dashboard/my-listings'),
              icon: const Icon(Icons.inventory_2_outlined, size: 16),
              label: Text(
                'MY LISTINGS',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _messageSeller(Listing listing) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      // Redirect to login, return here after
      context.push('/login?redirect=/marketplace/${listing.id}');
      return;
    }

    setState(() => _messagingLoading = true);
    try {
      final repo = ConversationRepository();
      final conversationId =
          await repo.getOrCreateConversation(listing.sellerId);
      if (!mounted) return;
      if (conversationId != null) {
        // FR-003: attach this listing as a reference to the thread
        try {
          await repo.addListingToConversation(conversationId, listing.id);
        } catch (_) {
          // Non-fatal: listing ref fails silently (e.g. already attached,
          // cap reached, or seller mismatch edge case)
        }
        if (!mounted) return;
        context.push('/dashboard/messages/$conversationId');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start conversation. Please try again.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start conversation. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _messagingLoading = false);
    }
  }

  Widget _buildBuyerActions(Listing listing) {
    return Row(
      children: [
        // Message Seller — primary action
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: const RoundedRectangleBorder(),
              ),
              onPressed:
                  _messagingLoading ? null : () => _messageSeller(listing),
              icon: _messagingLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.chat_outlined, size: 16),
              label: Text(
                'MESSAGE SELLER',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Leave a Review — secondary action
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: AppColors.ghostBorderBase, width: 1),
                shape: const RoundedRectangleBorder(),
                foregroundColor: AppColors.primary,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (_) => ReviewBottomSheet(
                    listingId: listing.id,
                    sellerId: listing.sellerId,
                    fragranceName: listing.fragranceName,
                    brand: listing.brand,
                  ),
                );
              },
              icon: const Icon(Icons.star_outline, size: 16),
              label: Text(
                'REVIEW',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section 6 — Olfactory narrative / notes
  // ---------------------------------------------------------------------------

  Widget _buildOlfactoryNarrative(Listing listing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        color: AppColors.surfaceContainerLow,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FRAGRANCE COMPOSITION',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 16),

            if (listing.fragranceFamily != null) ...[
              _buildCompositionRow(
                  'Fragrance Family', listing.fragranceFamily!),
              const SizedBox(height: 12),
            ],

            if (listing.vintageYear != null) ...[
              _buildCompositionRow(
                  'Vintage Year', listing.vintageYear.toString()),
              const SizedBox(height: 12),
            ],

            if (listing.fragranceNotes != null) ...[
              Text(
                'NOTES',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                listing.fragranceNotes!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
            ],

            if (listing.fragranceFamily == null &&
                listing.fragranceNotes == null &&
                listing.vintageYear == null)
              Text(
                'Detailed fragrance notes not provided by seller.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMuted,
                  height: 1.6,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompositionRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onBackground,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _DetailField {
  final String label;
  final String value;
  const _DetailField(this.label, this.value);
}
