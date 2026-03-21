import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'sidebar_nav.dart';
import 'bottom_nav.dart';

/// Adaptive layout shell.
/// > 1024px: persistent left sidebar + content area
/// >= 600px and <= 1024px: collapsed icon-only sidebar + content area
/// < 600px: content area + bottom navigation bar
class AppShell extends StatelessWidget {
  final Widget child;
  final bool isAdmin;

  const AppShell({
    super.key,
    required this.child,
    this.isAdmin = false,
  });

  static const double _desktopBreakpoint = 1024;
  static const double _tabletBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Desktop: persistent full sidebar
    if (width > _desktopBreakpoint) {
      return Scaffold(
        backgroundColor: AppColors.surfaceContainerLow,
        body: Row(
          children: [
            SidebarNav(isAdmin: isAdmin),
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
            SidebarNav(isAdmin: isAdmin, collapsed: true),
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
      bottomNavigationBar: PfcBottomNav(isAdmin: isAdmin),
    );
  }
}
