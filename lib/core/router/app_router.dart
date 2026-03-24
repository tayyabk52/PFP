import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/landing/landing_page.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/profile_provider.dart';
import '../widgets/app_shell.dart';
import '../widgets/stub_page.dart';
import 'route_guards.dart';
import '../../features/seller_apply/pages/seller_apply_page.dart';
import '../../features/seller_apply/pages/verification_status_page.dart';
import '../../features/marketplace/pages/marketplace_page.dart';
import '../../features/marketplace/pages/listing_detail_page.dart';
import '../../features/marketplace/pages/create_listing_page.dart';
import '../../features/marketplace/pages/my_listings_page.dart';
import '../../features/dashboard/pages/dashboard_page.dart';
import '../../features/dashboard/pages/profile_page.dart';
import '../../features/sellers/pages/seller_profile_page.dart';
import '../../features/iso/pages/iso_board_page.dart';
import '../../features/iso/pages/iso_create_page.dart';
import '../../features/iso/pages/iso_detail_page.dart';
import '../../features/iso/pages/my_iso_posts_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = _RouterNotifier(ref);

  // Session is already available synchronously after Supabase.initialize()
  // (awaited in main). Start on /dashboard if a session exists so the user
  // never sees the landing page flash on app restart.
  final hasSession =
      Supabase.instance.client.auth.currentSession != null;

  return GoRouter(
    initialLocation: hasSession ? '/dashboard' : '/',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      // Wait for auth stream to emit its first event
      if (routerNotifier._authLoading) return null;

      // Wait for role, setup, and application status to resolve
      final roleAsync = ref.read(userRoleProvider);
      final setupAsync = ref.read(profileSetupCompleteProvider);
      final appAsync = ref.read(sellerApplicationProvider);
      if (roleAsync is AsyncLoading || setupAsync is AsyncLoading || appAsync is AsyncLoading) return null;

      return RouteGuards.getRedirect(
        location: state.uri.toString(),
        role: routerNotifier._role,
        isAuthenticated: routerNotifier._isAuthenticated,
        profileSetupComplete: routerNotifier._profileSetupComplete,
        applicationStatus: routerNotifier._applicationStatus,
      );
    },
    routes: [
      // --- Public routes ---
      GoRoute(path: '/', builder: (_, __) => const LandingPage()),
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginPage(
          redirect: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/register/seller-apply', builder: (_, __) => const SellerApplyPage()),
      GoRoute(path: '/marketplace', builder: (_, __) => const MarketplacePage()),
      GoRoute(path: '/marketplace/:id', builder: (_, state) => ListingDetailPage(listingId: state.pathParameters['id']!)),
      GoRoute(path: '/sellers', builder: (_, __) => const StubPage(title: 'Legit Sellers')),
      GoRoute(path: '/sellers/:code', builder: (_, state) => SellerProfilePage(code: state.pathParameters['code']!)),
      GoRoute(path: '/knowledge', builder: (_, __) => const StubPage(title: 'Knowledge Base')),
      GoRoute(path: '/knowledge/guides', builder: (_, __) => const StubPage(title: 'Community Guides')),
      GoRoute(path: '/knowledge/fake-detection/:slug', builder: (_, __) => const StubPage(title: 'Fake Detection Guide')),
      GoRoute(path: '/knowledge/glossary', builder: (_, __) => const StubPage(title: 'Glossary')),
      GoRoute(path: '/iso', builder: (_, __) => const IsoBoardPage()),
      GoRoute(path: '/iso/create', builder: (_, state) => IsoCreatePage(existingIsoId: state.uri.queryParameters['existingId'])),
      GoRoute(path: '/iso/:id', builder: (_, state) => IsoDetailPage(isoId: state.pathParameters['id']!)),

      // --- Dashboard (auth-gated, AppShell) ---
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/dashboard/my-listings', builder: (_, __) => const MyListingsPage()),
          GoRoute(
            path: '/dashboard/create-listing',
            builder: (_, state) => CreateListingPage(
              initialType: state.uri.queryParameters['type'],
              existingListingId: state.uri.queryParameters['editId'],
            ),
          ),
          GoRoute(
            path: '/dashboard/my-listings/:id/edit',
            builder: (_, state) => CreateListingPage(
              existingListingId: state.pathParameters['id'],
            ),
          ),
          GoRoute(path: '/dashboard/messages', builder: (_, __) => const StubPage(title: 'Inbox')),
          GoRoute(path: '/dashboard/messages/:id', builder: (_, __) => const StubPage(title: 'Conversation')),
          GoRoute(path: '/dashboard/profile', builder: (_, __) => const ProfilePage()),
          GoRoute(path: '/dashboard/reviews', builder: (_, __) => const StubPage(title: 'My Reviews')),
          GoRoute(path: '/dashboard/reports', builder: (_, __) => const StubPage(title: 'Reports')),
          GoRoute(path: '/dashboard/iso', builder: (_, __) => const MyIsoPostsPage()),
          GoRoute(
            path: '/dashboard/iso/:id/edit',
            builder: (_, state) => IsoCreatePage(existingIsoId: state.pathParameters['id']),
          ),
          GoRoute(path: '/dashboard/verification', builder: (_, __) => const VerificationStatusPage()),
        ],
      ),

      // --- Admin (role-gated, AppShell) ---
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
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
  bool _profileSetupComplete = true;
  String? _applicationStatus;
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
    _ref.listen(profileSetupCompleteProvider, (_, setup) {
      _profileSetupComplete = setup.valueOrNull ?? true;
      notifyListeners();
    });
    _ref.listen(sellerApplicationStatusProvider, (_, status) {
      _applicationStatus = status;
      notifyListeners();
    });
  }
}
