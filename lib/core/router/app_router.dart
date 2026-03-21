import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/landing/landing_page.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/profile_provider.dart';
import '../widgets/app_shell.dart';
import '../widgets/stub_page.dart';
import 'route_guards.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = _RouterNotifier(ref);

  return GoRouter(
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      // Wait for auth stream to emit its first event
      if (routerNotifier._authLoading) return null;

      // Wait for role and application status to resolve
      final roleAsync = ref.read(userRoleProvider);
      final hasAppAsync = ref.read(hasSellerApplicationProvider);
      if (roleAsync is AsyncLoading || hasAppAsync is AsyncLoading) return null;

      return RouteGuards.getRedirect(
        location: state.uri.toString(),
        role: routerNotifier._role,
        isAuthenticated: routerNotifier._isAuthenticated,
        hasSellerApplication: routerNotifier._hasSellerApplication,
      );
    },
    routes: [
      // --- Public routes ---
      GoRoute(path: '/', builder: (_, __) => const LandingPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/register/seller-apply', builder: (_, __) => const StubPage(title: 'Seller Application')),
      GoRoute(path: '/marketplace', builder: (_, __) => const StubPage(title: 'Marketplace')),
      GoRoute(path: '/marketplace/:id', builder: (_, __) => const StubPage(title: 'Listing Detail')),
      GoRoute(path: '/sellers', builder: (_, __) => const StubPage(title: 'Legit Sellers')),
      GoRoute(path: '/sellers/:code', builder: (_, __) => const StubPage(title: 'Seller Profile')),
      GoRoute(path: '/knowledge', builder: (_, __) => const StubPage(title: 'Knowledge Base')),
      GoRoute(path: '/knowledge/guides', builder: (_, __) => const StubPage(title: 'Community Guides')),
      GoRoute(path: '/knowledge/fake-detection/:slug', builder: (_, __) => const StubPage(title: 'Fake Detection Guide')),
      GoRoute(path: '/knowledge/glossary', builder: (_, __) => const StubPage(title: 'Glossary')),

      // --- Dashboard (auth-gated, AppShell) ---
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const StubPage(title: 'Dashboard')),
          GoRoute(path: '/dashboard/my-listings', builder: (_, __) => const StubPage(title: 'My Listings')),
          GoRoute(path: '/dashboard/create-listing', builder: (_, __) => const StubPage(title: 'Create Listing')),
          GoRoute(path: '/dashboard/messages', builder: (_, __) => const StubPage(title: 'Inbox')),
          GoRoute(path: '/dashboard/messages/:id', builder: (_, __) => const StubPage(title: 'Conversation')),
          GoRoute(path: '/dashboard/profile', builder: (_, __) => const StubPage(title: 'Profile')),
          GoRoute(path: '/dashboard/reviews', builder: (_, __) => const StubPage(title: 'My Reviews')),
          GoRoute(path: '/dashboard/reports', builder: (_, __) => const StubPage(title: 'Reports')),
          GoRoute(path: '/dashboard/iso', builder: (_, __) => const StubPage(title: 'My ISO Posts')),
          GoRoute(path: '/dashboard/verification', builder: (_, __) => const StubPage(title: 'Verification Status')),
        ],
      ),

      // --- Admin (role-gated, AppShell) ---
      ShellRoute(
        builder: (context, state, child) => AppShell(isAdmin: true, child: child),
        routes: [
          GoRoute(path: '/admin', builder: (_, __) => const StubPage(title: 'Admin Overview')),
          GoRoute(path: '/admin/users', builder: (_, __) => const StubPage(title: 'User Management')),
          GoRoute(path: '/admin/sellers', builder: (_, __) => const StubPage(title: 'Verified Sellers')),
          GoRoute(path: '/admin/sellers/applications', builder: (_, __) => const StubPage(title: 'Seller Applications')),
          GoRoute(path: '/admin/sellers/applications/:id', builder: (_, __) => const StubPage(title: 'Application Detail')),
          GoRoute(path: '/admin/listings', builder: (_, __) => const StubPage(title: 'Listing Moderation')),
          GoRoute(path: '/admin/reports', builder: (_, __) => const StubPage(title: 'Reports Tracker')),
          GoRoute(path: '/admin/knowledge', builder: (_, __) => const StubPage(title: 'Knowledge Management')),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod state changes to GoRouter's refresh mechanism.
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  String? _role;
  bool _isAuthenticated = false;
  bool _hasSellerApplication = false;
  bool _authLoading = true; // true until auth stream emits first event

  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, next) {
      _authLoading = next is AsyncLoading;
      _isAuthenticated = next.valueOrNull?.session?.user != null;
      notifyListeners();
    });
    _ref.listen(userRoleProvider, (_, role) {
      _role = role.valueOrNull;
      notifyListeners();
    });
    _ref.listen(hasSellerApplicationProvider, (_, has) {
      _hasSellerApplication = has.valueOrNull ?? false;
      notifyListeners();
    });
  }
}
