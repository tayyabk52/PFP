import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class PfcBottomNav extends StatelessWidget {
  final bool isAdmin;
  final bool isSeller;
  /// 'Pending', 'Approved', 'Rejected', or null (no application).
  final String? applicationStatus;
  const PfcBottomNav({
    super.key,
    this.isAdmin = false,
    this.isSeller = false,
    this.applicationStatus,
  });

  @override
  Widget build(BuildContext context) {
    String location = '';
    try {
      location = GoRouterState.of(context).uri.toString();
    } on Error {
      // No GoRouter in tree (e.g. during tests)
    }

    return NavigationBar(
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.primary.withValues(alpha: 0.1),
      selectedIndex: _indexFromLocation(location),
      onDestinationSelected: (index) =>
          context.go(_routeFromIndex(index)),
      destinations: _buildDestinations(),
    );
  }

  List<NavigationDestination> _buildDestinations() {
    if (isAdmin) {
      return const [
        NavigationDestination(
            icon: Icon(Icons.dashboard_outlined), label: 'Admin'),
        NavigationDestination(
            icon: Icon(Icons.storefront_outlined), label: 'Market'),
        NavigationDestination(
            icon: Icon(Icons.flag_outlined), label: 'Reports'),
        NavigationDestination(
            icon: Icon(Icons.person_outline), label: 'Profile'),
      ];
    }

    if (isSeller) {
      return const [
        NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Market'),
        NavigationDestination(icon: Icon(Icons.search_outlined), label: 'ISO'),
        NavigationDestination(icon: Icon(Icons.list_alt_outlined), label: 'My Listings'),
        NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ];
    }

    // Member — only show verification tab if they have an application
    return [
      const NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Market'),
      const NavigationDestination(icon: Icon(Icons.search_outlined), label: 'ISO'),
      const NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'Dashboard'),
      if (applicationStatus != null) _verificationDestination(),
      const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
    ];
  }

  /// Returns the appropriate verification/seller tab for members.
  NavigationDestination _verificationDestination() {
    return switch (applicationStatus) {
      'Pending' => const NavigationDestination(
          icon: Icon(Icons.hourglass_top_rounded), label: 'Status'),
      'Rejected' => const NavigationDestination(
          icon: Icon(Icons.refresh_rounded), label: 'Reapply'),
      _ => const NavigationDestination(
          icon: Icon(Icons.verified_outlined), label: 'Verify'),
    };
  }

  int _indexFromLocation(String location) {
    if (isAdmin) {
      if (location.startsWith('/admin/reports')) return 2;
      if (location.startsWith('/admin')) return 0;
      if (location.startsWith('/marketplace')) return 1;
      return 3;
    }
    if (isSeller) {
      if (location.startsWith('/marketplace')) return 0;
      if (location.startsWith('/iso')) return 1;
      if (location.startsWith('/dashboard/my-listings')) return 2;
      if (location.startsWith('/dashboard')) return 3;
      return 4;
    }
    // member
    final hasVerifyTab = applicationStatus != null;
    if (location.startsWith('/marketplace')) return 0;
    if (location.startsWith('/iso')) return 1;
    if (hasVerifyTab &&
        (location.startsWith('/dashboard/verification') ||
            location.startsWith('/register/seller-apply'))) {
      return 3;
    }
    if (location.startsWith('/dashboard')) return 2;
    return 0;
  }

  String _routeFromIndex(int index) {
    if (isAdmin) {
      return ['/admin', '/marketplace', '/admin/reports', '/dashboard/profile'][index];
    }
    if (isSeller) {
      return ['/marketplace', '/iso', '/dashboard/my-listings', '/dashboard', '/dashboard/profile'][index];
    }
    // Member — only include verify route when application exists
    if (applicationStatus != null) {
      final verifyRoute = switch (applicationStatus) {
        'Pending' => '/dashboard/verification',
        'Rejected' => '/dashboard/verification',
        _ => '/register/seller-apply',
      };
      return ['/marketplace', '/iso', '/dashboard', verifyRoute, '/dashboard/profile'][index];
    }
    return ['/marketplace', '/iso', '/dashboard', '/dashboard/profile'][index];
  }
}
