import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class PfcBottomNav extends StatelessWidget {
  final bool isAdmin;
  const PfcBottomNav({super.key, this.isAdmin = false});

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
          context.go(_routeFromIndex(index, isAdmin)),
      destinations: isAdmin
          ? const [
              NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined), label: 'Admin'),
              NavigationDestination(
                  icon: Icon(Icons.storefront_outlined), label: 'Market'),
              NavigationDestination(
                  icon: Icon(Icons.flag_outlined), label: 'Reports'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline), label: 'Profile'),
            ]
          : const [
              NavigationDestination(
                  icon: Icon(Icons.storefront_outlined), label: 'Archive'),
              NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined), label: 'Market'),
              NavigationDestination(
                  icon: Icon(Icons.verified_outlined), label: 'Verify'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline), label: 'Vault'),
            ],
    );
  }

  int _indexFromLocation(String location) {
    if (isAdmin) {
      if (location.startsWith('/admin/reports')) return 2;
      if (location.startsWith('/admin')) return 0;
      return 3;
    }
    if (location.startsWith('/marketplace')) return 0;
    if (location.startsWith('/dashboard/verification')) return 2;
    if (location.startsWith('/dashboard')) return 1;
    return 0;
  }

  String _routeFromIndex(int index, bool admin) {
    if (admin) {
      return [
        '/admin',
        '/marketplace',
        '/admin/reports',
        '/dashboard/profile'
      ][index];
    }
    return [
      '/marketplace',
      '/dashboard',
      '/dashboard/verification',
      '/dashboard/profile'
    ][index];
  }
}
