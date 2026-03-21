/// Pure redirect logic — no Flutter/Supabase dependencies.
/// Testable in isolation. AppRouter calls this in go_router redirect callback.
abstract class RouteGuards {
  static const _protectedDashboardPrefix = '/dashboard';
  static const _adminPrefix = '/admin';
  static const _sellerApplyRoute = '/register/seller-apply';
  static const _sellerCreateListing = '/dashboard/create-listing';

  /// Returns a redirect path, or null if navigation is allowed.
  static String? getRedirect({
    required String location,
    required String? role,
    required bool isAuthenticated,
    required bool hasSellerApplication,
  }) {
    final isAdmin = role == 'admin';
    final isSeller = role == 'seller';

    // Unauthenticated guards
    if (!isAuthenticated) {
      if (location.startsWith(_protectedDashboardPrefix)) return '/login';
      if (location.startsWith(_adminPrefix)) return '/login';
      if (location == _sellerApplyRoute) return '/register';
      return null;
    }

    // Admin-only routes
    if (location.startsWith(_adminPrefix) && !isAdmin) return '/dashboard';

    // Seller-only routes
    if (location == _sellerCreateListing && !isSeller && !isAdmin) {
      return '/dashboard';
    }

    // Seller apply — redirect if already has an application or is already a seller
    if (location == _sellerApplyRoute) {
      if (isSeller || hasSellerApplication) return '/dashboard/verification';
      return null;
    }

    return null;
  }
}
