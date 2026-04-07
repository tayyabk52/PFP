import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class AuctionCountdown extends StatefulWidget {
  final DateTime endTime;

  const AuctionCountdown({super.key, required this.endTime});

  @override
  State<AuctionCountdown> createState() => _AuctionCountdownState();
}

class _AuctionCountdownState extends State<AuctionCountdown> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _computeRemaining();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final remaining = _computeRemaining();
      if (mounted) {
        setState(() => _remaining = remaining);
      }
      if (remaining.isNegative || remaining == Duration.zero) {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Duration _computeRemaining() {
    final now = DateTime.now();
    if (widget.endTime.isBefore(now)) return Duration.zero;
    return widget.endTime.difference(now);
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_off_outlined, size: 12, color: AppColors.error),
            const SizedBox(width: 4),
            Text(
              'Auction ended',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      );
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);

    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0 || days > 0) parts.add('${hours}h');
    parts.add('${minutes}m');

    final label = parts.join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 12, color: AppColors.error),
          const SizedBox(width: 4),
          Text(
            'Ends in $label',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
