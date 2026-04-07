import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/listing_model.dart';
import '../../providers/my_listings_provider.dart';

class MyListingCard extends ConsumerWidget {
  final Listing listing;
  const MyListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceContainerHighest, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhoto(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        listing.fragranceName,
                        style: GoogleFonts.notoSerif(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  listing.brand,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildTypeChip(),
                    const SizedBox(width: 6),
                    Text(
                      listing.salePostNumber,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    _buildPrice(),
                  ],
                ),
                const SizedBox(height: 8),
                _buildActionRow(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto() {
    return SizedBox(
      width: 72,
      height: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: listing.primaryPhotoUrl != null
            ? Image.network(
                listing.primaryPhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceContainerLow,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: AppColors.textMuted,
                  ),
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
    );
  }

  Widget _buildStatusBadge() {
    final (color, label) = switch (listing.status) {
      ListingStatus.draft => (AppColors.textMuted, 'DRAFT'),
      ListingStatus.published => (AppColors.success, 'LIVE'),
      ListingStatus.sold => (AppColors.primary, 'SOLD'),
      ListingStatus.expired => (AppColors.textMuted, 'EXPIRED'),
      ListingStatus.deleted => (AppColors.error, 'DELETED'),
      ListingStatus.removed => (AppColors.textMuted, 'REMOVED'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: color,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTypeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: AppColors.surfaceContainerHighest,
      child: Text(
        listing.listingType.value,
        style: GoogleFonts.inter(
          fontSize: 9,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPrice() {
    final priceText = listing.pricePkr == 0
        ? 'Swap'
        : 'Rs. ${NumberFormat('#,###').format(listing.pricePkr)}';

    return Text(
      priceText,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, WidgetRef ref) {
    final actions = <Widget>[];

    switch (listing.status) {
      case ListingStatus.draft:
        actions.addAll([
          _ActionButton(
            'PUBLISH',
            Icons.publish_outlined,
            filled: true,
            onPressed: () => _publishDraft(context, ref),
          ),
          _ActionButton(
            'EDIT',
            Icons.edit_outlined,
            onPressed: () =>
                context.go('/dashboard/my-listings/${listing.id}/edit'),
          ),
          _ActionButton(
            'DELETE',
            Icons.delete_outline,
            destructive: true,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ]);
      case ListingStatus.published:
        actions.addAll([
          _ActionButton(
            'MARK SOLD',
            Icons.check_circle_outline,
            filled: true,
            onPressed: () => _confirmMarkSold(context, ref),
          ),
          _ActionButton(
            'EDIT',
            Icons.edit_outlined,
            onPressed: () =>
                context.go('/dashboard/my-listings/${listing.id}/edit'),
          ),
          _ActionButton(
            'DELETE',
            Icons.delete_outline,
            destructive: true,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ]);
      case ListingStatus.sold:
        actions.add(
          _ActionButton(
            'VIEW',
            Icons.open_in_new_outlined,
            onPressed: () => context.go('/marketplace/${listing.id}'),
          ),
        );
      case ListingStatus.expired:
      case ListingStatus.deleted:
      case ListingStatus.removed:
        break;
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions,
    );
  }

  void _confirmMarkSold(BuildContext context, WidgetRef ref) {
    final qty = listing.quantityAvailable ?? 1;
    final isMultiUnit = qty > 1;

    final title = isMultiUnit ? 'Record a Sale?' : 'Mark as Sold?';
    final body = isMultiUnit
        ? 'This will record 1 unit sold. ${qty - 1} unit${qty - 1 == 1 ? '' : 's'} will remain listed.'
        : 'This listing will be removed from the marketplace. This action cannot be undone.';
    final buttonLabel = isMultiUnit ? 'Record Sale' : 'Mark Sold';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          title,
          style: GoogleFonts.notoSerif(
            fontWeight: FontWeight.w700,
            color: AppColors.onBackground,
          ),
        ),
        content: Text(
          body,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(listingWriteRepositoryProvider);
                if (isMultiUnit) {
                  await repo.decrementQuantity(listing.id);
                } else {
                  await repo.markAsSold(listing.id);
                }
                ref.invalidate(myListingsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to update listing: $e',
                        style: GoogleFonts.inter(),
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          'Delete Listing?',
          style: GoogleFonts.notoSerif(
            fontWeight: FontWeight.w700,
            color: AppColors.onBackground,
          ),
        ),
        content: Text(
          'This listing will be permanently deleted. This cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(listingWriteRepositoryProvider)
                    .deleteListing(listing.id);
                ref.invalidate(myListingsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete listing: $e',
                          style: GoogleFonts.inter()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _publishDraft(BuildContext context, WidgetRef ref) async {
    // Validate: listing must have at least one photo
    if (listing.photos.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please add at least one photo before publishing.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Show impression declaration confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Publish Listing',
          style: GoogleFonts.notoSerif(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'By publishing, you confirm that this listing accurately represents '
          'the fragrance and its condition. Misleading listings may be removed.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text('Confirm & Publish'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await ref
          .read(listingWriteRepositoryProvider)
          .publishListing(listing.id);
      ref.invalidate(myListingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing published!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish listing: $e')),
        );
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool destructive;
  final VoidCallback? onPressed;

  const _ActionButton(
    this.label,
    this.icon, {
    required this.onPressed,
    this.filled = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    final Color? bgColor;
    final BorderSide borderSide;

    if (filled) {
      textColor = Colors.white;
      bgColor = AppColors.primary;
      borderSide = BorderSide.none;
    } else if (destructive) {
      textColor = AppColors.error;
      bgColor = Colors.transparent;
      borderSide = const BorderSide(color: AppColors.error, width: 1);
    } else {
      textColor = AppColors.textSecondary;
      bgColor = Colors.transparent;
      borderSide = const BorderSide(color: AppColors.ghostBorderBase, width: 1);
    }

    return SizedBox(
      height: 32,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 12, color: textColor),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: textColor,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: borderSide,
          ),
        ),
      ),
    );
  }
}
