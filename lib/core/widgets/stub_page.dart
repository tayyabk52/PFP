import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Temporary placeholder for routes not yet implemented.
/// Replace with real page widget as each feature is built.
class StubPage extends StatelessWidget {
  final String title;
  const StubPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction_rounded,
                size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headlineSm),
            const SizedBox(height: 8),
            Text('Coming soon', style: AppTextStyles.bodyMd),
          ],
        ),
      ),
    );
  }
}
