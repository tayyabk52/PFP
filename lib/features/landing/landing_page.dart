import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/providers/auth_provider.dart';

/// Landing page — shows PFC branding and auth entry points.
/// While the session is being restored shows a loading indicator instead of
/// sign-in/register buttons so the user doesn't attempt to re-authenticate.
class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final isLoading = authAsync is AsyncLoading;

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'P',
                      style: TextStyle(
                        color: Color(0xFF003527),
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'PFC',
                  style: AppTextStyles.displaySm.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pakistan Fragrance Community',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 56),

                // While auth session is restoring, show a spinner.
                // Once resolved, show normal auth buttons.
                if (isLoading) ...[
                  const CircularProgressIndicator(
                    color: AppColors.goldAccent,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Restoring session…',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ] else ...[
                  // Sign In button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldAccent,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Sign In',
                        style: AppTextStyles.bodyLg.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Register button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: () => context.go('/register'),
                      child: Text(
                        'Create Account',
                        style: AppTextStyles.bodyLg.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Browse without account
                  GestureDetector(
                    onTap: () => context.go('/marketplace'),
                    child: Text(
                      'Browse marketplace →',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
