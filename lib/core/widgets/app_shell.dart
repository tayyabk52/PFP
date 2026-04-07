import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../widgets/sidebar_nav.dart';
import '../widgets/bottom_nav.dart';
import '../../features/auth/providers/profile_provider.dart';

/// Adaptive layout shell.
/// > 1024px: persistent left sidebar + content area
/// >= 600px and <= 1024px: collapsed icon-only sidebar + content area
/// < 600px: content area + bottom navigation bar
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  static const double _desktopBreakpoint = 1024;
  static const double _tabletBreakpoint = 600;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final role = profileAsync.valueOrNull?['role'] as String? ?? 'member';
    final isAdmin = role == 'admin';
    final isSeller = role == 'seller';
    final applicationStatus = ref.watch(sellerApplicationStatusProvider);

    final width = MediaQuery.of(context).size.width;

    // Desktop: persistent full sidebar
    if (width > _desktopBreakpoint) {
      return Scaffold(
        backgroundColor: AppColors.surfaceContainerLow,
        body: Row(
          children: [
            SidebarNav(
              isAdmin: isAdmin,
              isSeller: isSeller,
              applicationStatus: applicationStatus,
            ),
            Expanded(
              child: Container(
                color: AppColors.surface,
                child: child,
              ),
            ),
          ],
        ),
      );
    }

    // Tablet: collapsible icon-only sidebar
    if (width >= _tabletBreakpoint) {
      return Scaffold(
        backgroundColor: AppColors.surfaceContainerLow,
        body: Row(
          children: [
            SidebarNav(
              isAdmin: isAdmin,
              isSeller: isSeller,
              collapsed: true,
              applicationStatus: applicationStatus,
            ),
            Expanded(
              child: Container(
                color: AppColors.surface,
                child: child,
              ),
            ),
          ],
        ),
      );
    }

    // Mobile: bottom navigation bar
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: child,
      bottomNavigationBar: PfcBottomNav(
        isAdmin: isAdmin,
        isSeller: isSeller,
        applicationStatus: applicationStatus,
      ),
    );
  }
}
