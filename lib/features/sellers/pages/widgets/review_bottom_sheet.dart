import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/seller_provider.dart';

class ReviewBottomSheet extends ConsumerStatefulWidget {
  final String listingId;
  final String sellerId;
  final String fragranceName;
  final String brand;

  const ReviewBottomSheet({
    super.key,
    required this.listingId,
    required this.sellerId,
    required this.fragranceName,
    required this.brand,
  });

  @override
  ConsumerState<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends ConsumerState<ReviewBottomSheet> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Please select a rating');
      return;
    }
    if (_commentController.text.trim().isEmpty) {
      setState(() => _error = 'Please write a comment');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = ref.read(sellerRepositoryProvider);
      await repo.submitReview(
        listingId: widget.listingId,
        sellerId: widget.sellerId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Review submitted',
            style: GoogleFonts.inter(color: AppColors.onPrimary),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              'Leave a Review',
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            // Listing info
            Text(
              '${widget.fragranceName} by ${widget.brand}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            // Star rating
            Text(
              'RATING',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starIndex),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      starIndex <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 36,
                      color: starIndex <= _rating
                          ? AppColors.goldAccent
                          : AppColors.textMuted,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            // Comment
            Text(
              'COMMENT',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLength: 500,
              maxLines: 4,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.onBackground,
              ),
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: InputBorder.none,
                counterStyle: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const RoundedRectangleBorder(),
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.5),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Text(
                        'SUBMIT REVIEW',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
