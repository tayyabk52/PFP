/// Pure redirect logic — no Flutter/Supabase dependencies.
/// Testable in isolation. AppRouter calls this in go_router redirect callback.
abstract class RouteGuards {
  static const _protectedDashboardPrefix = '/dashboard';
  static const _adminPrefix = '/admin';
  static const _sellerApplyRoute = '/register/seller-apply';
  static const _verificationRoute = '/dashboard/verification';
  static const _myListingsRoute = '/dashboard/my-listings';

  /// Returns a redirect path, or null if navigation is allowed.
  ///
  /// [applicationStatus] is the seller application status:
  /// 'Pending', 'Approved', 'Rejected', or null (no application).
  static String? getRedirect({
    required String location,
    required String? role,
    required bool isAuthenticated,
    required bool profileSetupComplete,
    String? applicationStatus,
  }) {
    final isAdmin = role == 'admin';
    final isSeller = role == 'seller';
    final hasApplication = applicationStatus != null;
    final isRejected = applicationStatus == 'Rejected';

    // Unauthenticated guards
    if (!isAuthenticated) {
      if (location.startsWith(_protectedDashboardPrefix)) return '/login';
      if (location.startsWith(_adminPrefix)) return '/login';
      if (location == _sellerApplyRoute) return '/register';
      return null;
    }

    // Authenticated but profile setup not complete → must pick a role first.
    // Allow /register, /register/seller-apply, and /dashboard/verification
    // through so users can complete setup or check their application status.
    if (!profileSetupComplete &&
        location != '/register' &&
        location != _sellerApplyRoute &&
        location != _verificationRoute) {
      return '/register';
    }

    // Authenticated users should not linger on login or landing pages
    if (location == '/login' || location == '/') {
      return isAdmin ? '/admin' : '/dashboard';
    }

    // Admin-only routes
    if (location.startsWith(_adminPrefix) && !isAdmin) return '/dashboard';

    // My Listings is seller-only — members should not access it
    if (location.startsWith(_myListingsRoute) && !isSeller && !isAdmin) {
      return '/dashboard';
    }

    // Seller apply — redirect based on application status
    if (location == _sellerApplyRoute) {
      // Already a seller → go to verification (shows "Approved" status)
      if (isSeller) return _verificationRoute;
      // Has a pending application → go to verification status page
      if (hasApplication && !isRejected) return _verificationRoute;
      // Rejected or no application → allow access to reapply/apply
      return null;
    }

    return null;
  }
}
