import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/listing_model.dart';
import 'auction_countdown.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;

  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area (4:5 aspect ratio)
            AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(),
                  // Bottom scrim: ensures price chip is legible over any image.
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 72,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x52000000)],
                        ),
                      ),
                    ),
                  ),
                  _buildTopLeftBadge(),
                  _buildPriceChip(),
                ],
              ),
            ),
            // Content area — Expanded ensures it fills exactly the remaining
            // grid-cell height computed by the dynamic childAspectRatio.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFragranceName(),
                    const SizedBox(height: 4),
                    _buildBrand(),
                    const SizedBox(height: 8),
                    _buildMetadataChips(),
                    if (listing.isAuctionActive) ...[
                      const SizedBox(height: 6),
                      AuctionCountdown(endTime: listing.auctionEndAt!),
                    ],
                    const Spacer(),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final url = listing.primaryPhotoUrl;
    if (url != null) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (_, __) =>
            const ColoredBox(color: AppColors.surfaceContainerLow),
        errorWidget: (_, __, ___) =>
            const ColoredBox(color: AppColors.surfaceContainerLow),
      );
    }
    return const ColoredBox(color: AppColors.surfaceContainerLow);
  }

  Widget _buildTopLeftBadge() {
    final type = listing.listingType;

    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    if (type == ListingType.swap) {
      bgColor = AppColors.primaryGradientEnd;
      textColor = AppColors.onPrimary;
      icon = Icons.sync;
      label = 'Swap';
    } else if (type == ListingType.iso) {
      bgColor = AppColors.secondary;
      textColor = AppColors.onPrimary;
      icon = Icons.search;
      label = 'ISO';
    } else if (type == ListingType.auction) {
      bgColor = AppColors.error;
      textColor = AppColors.onPrimary;
      icon = Icons.timer_outlined;
      label = 'Auction';
    } else {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceChip() {
    final formatted = 'Rs. ${NumberFormat('#,###').format(listing.pricePkr)}';
    return Positioned(
      bottom: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          formatted,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildFragranceName() {
    return Text(
      listing.fragranceName,
      // 1 line only — cards are small; full name is shown on the detail page.
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.notoSerif(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.3,
      ),
    );
  }

  Widget _buildBrand() {
    return Text(
      listing.brand,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.notoSerif(
        fontSize: 12,
        fontStyle: FontStyle.italic,
        color: AppColors.textSecondary,
        height: 1.4,
      ),
    );
  }

  Widget _buildMetadataChips() {
    final chips = <String>[];

    // Size
    final sizeInt = listing.sizeMl.toInt();
    final sizeLabel = (listing.sizeMl == sizeInt.toDouble())
        ? '${sizeInt}ml'
        : '${listing.sizeMl}ml';
    chips.add(sizeLabel);

    // Condition
    if (listing.condition != null) {
      chips.add(listing.condition!.value);
    }
    // Note: listing type is already communicated by the image badge; omitting
    // it here avoids redundancy and keeps chips compact.

    if (chips.isEmpty) return const SizedBox.shrink();

    // Single-row layout: chips share the available width equally so the row
    // can never wrap and add unpredictable extra height.
    return Row(
      children: [
        for (int i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                chips[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    final sellerName =
        listing.seller?.displayNameOrFallback ?? 'PFC Seller';
    final postNumber = '#${listing.salePostNumber}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(
          height: 1,
          thickness: 1,
          color: AppColors.surfaceContainerLow,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                postNumber,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
              ),
            ),
            Flexible(
              child: Text(
                sellerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
