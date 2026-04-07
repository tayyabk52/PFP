import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_app/core/router/route_guards.dart';

void main() {
  group('RouteGuards.getRedirect', () {
    test('unauthenticated user accessing /dashboard redirects to /login', () {
      final result = RouteGuards.getRedirect(
        location: '/dashboard',
        role: null,
        isAuthenticated: false,
        profileSetupComplete: true,
      );
      expect(result, '/login');
    });

    test('unauthenticated user accessing /admin redirects to /login', () {
      final result = RouteGuards.getRedirect(
        location: '/admin',
        role: null,
        isAuthenticated: false,
        profileSetupComplete: true,
      );
      expect(result, '/login');
    });

    test('unauthenticated user accessing /register/seller-apply redirects to /register', () {
      final result = RouteGuards.getRedirect(
        location: '/register/seller-apply',
        role: null,
        isAuthenticated: false,
        profileSetupComplete: true,
      );
      expect(result, '/register');
    });

    test('member accessing /admin redirects to /dashboard', () {
      final result = RouteGuards.getRedirect(
        location: '/admin',
        role: 'member',
        isAuthenticated: true,
        profileSetupComplete: true,
      );
      expect(result, '/dashboard');
    });

    test('member with pending application accessing /register/seller-apply redirects to /dashboard/verification', () {
      final result = RouteGuards.getRedirect(
        location: '/register/seller-apply',
        role: 'member',
        isAuthenticated: true,
        profileSetupComplete: true,
        applicationStatus: 'Pending',
      );
      expect(result, '/dashboard/verification');
    });

    test('member with rejected application can access /register/seller-apply', () {
      final result = RouteGuards.getRedirect(
        location: '/register/seller-apply',
        role: 'member',
        isAuthenticated: true,
        profileSetupComplete: true,
        applicationStatus: 'Rejected',
      );
      expect(result, isNull);
    });

    test('seller accessing /dashboard/create-listing is allowed', () {
      final result = RouteGuards.getRedirect(
        location: '/dashboard/create-listing',
        role: 'seller',
        isAuthenticated: true,
        profileSetupComplete: true,
      );
      expect(result, isNull);
    });

    test('seller accessing /register/seller-apply redirects to /dashboard/verification', () {
      final result = RouteGuards.getRedirect(
        location: '/register/seller-apply',
        role: 'seller',
        isAuthenticated: true,
        profileSetupComplete: true,
        applicationStatus: 'Approved',
      );
      expect(result, '/dashboard/verification');
    });

    test('admin can access /admin', () {
      final result = RouteGuards.getRedirect(
        location: '/admin',
        role: 'admin',
        isAuthenticated: true,
        profileSetupComplete: true,
      );
      expect(result, isNull);
    });

    test('authenticated user accessing /marketplace is allowed', () {
      final result = RouteGuards.getRedirect(
        location: '/marketplace',
        role: 'member',
        isAuthenticated: true,
        profileSetupComplete: true,
      );
      expect(result, isNull);
    });

    test('admin can access /dashboard/create-listing', () {
      final result = RouteGuards.getRedirect(
        location: '/dashboard/create-listing',
        role: 'admin',
        isAuthenticated: true,
        profileSetupComplete: true,
      );
      expect(result, isNull);
    });

    test('user with stale profileSetupComplete=false can reach /dashboard/verification', () {
      final result = RouteGuards.getRedirect(
        location: '/dashboard/verification',
        role: 'member',
        isAuthenticated: true,
        profileSetupComplete: false,
        applicationStatus: 'Pending',
      );
      expect(result, isNull);
    });

    test('user with profileSetupComplete=false accessing /dashboard is still sent to /register', () {
      final result = RouteGuards.getRedirect(
        location: '/dashboard',
        role: 'member',
        isAuthenticated: true,
        profileSetupComplete: false,
      );
      expect(result, '/register');
    });

    test('member with no application can access /register/seller-apply', () {
      final result = RouteGuards.getRedirect(
        location: '/register/seller-apply',
        role: 'member',
        isAuthenticated: true,
        profileSetupComplete: true,
      );
      expect(result, isNull);
    });
  });

  group('create-listing and my-listings guards', () {
    test('member can access create-listing for ISO posting', () {
      final result = RouteGuards.getRedirect(
        location: '/dashboard/create-listing',
        role: 'member',
        isAuthenticated: true,
        profileSetupComplete: true,
      );
      expect(result, isNull);
    });

    test('member cannot access my-listings', () {
      final result = RouteGuards.getRedirect(
        location: '/dashboard/my-listings',
        role: 'member',
        isAuthenticated: true,
        profileSetupComplete: true,
      );
      expect(result, equals('/dashboard'));
    });

    test('member cannot access my-listings edit route', () {
      final result = RouteGuards.getRedirect(
        location: '/dashboard/my-listings/some-uuid/edit',
        role: 'member',
        isAuthenticated: true,
        profileSetupComplete: true,
      );
      expect(result, equals('/dashboard'));
    });

    test('seller can access create-listing', () {
      final result = RouteGuards.getRedirect(
        location: '/dashboard/create-listing',
        role: 'seller',
        isAuthenticated: true,
        profileSetupComplete: true,
        applicationStatus: 'Approved',
      );
      expect(result, isNull);
    });

    test('seller can access my-listings', () {
      final result = RouteGuards.getRedirect(
        location: '/dashboard/my-listings',
        role: 'seller',
        isAuthenticated: true,
        profileSetupComplete: true,
        applicationStatus: 'Approved',
      );
      expect(result, isNull);
    });
  });
}
