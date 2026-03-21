import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_app/core/router/route_guards.dart';

void main() {
  group('RouteGuards.getRedirect', () {
    test('unauthenticated user accessing /dashboard redirects to /login', () {
      final result = RouteGuards.getRedirect(
        location: '/dashboard',
        role: null,
        isAuthenticated: false,
        hasSellerApplication: false,
      );
      expect(result, '/login');
    });

    test('unauthenticated user accessing /admin redirects to /login', () {
      final result = RouteGuards.getRedirect(
        location: '/admin',
        role: null,
        isAuthenticated: false,
        hasSellerApplication: false,
      );
      expect(result, '/login');
    });

    test('unauthenticated user accessing /register/seller-apply redirects to /register', () {
      final result = RouteGuards.getRedirect(
        location: '/register/seller-apply',
        role: null,
        isAuthenticated: false,
        hasSellerApplication: false,
      );
      expect(result, '/register');
    });

    test('member accessing /admin redirects to /dashboard', () {
      final result = RouteGuards.getRedirect(
        location: '/admin',
        role: 'member',
        isAuthenticated: true,
        hasSellerApplication: false,
      );
      expect(result, '/dashboard');
    });

    test('member accessing /dashboard/create-listing redirects to /dashboard', () {
      final result = RouteGuards.getRedirect(
        location: '/dashboard/create-listing',
        role: 'member',
        isAuthenticated: true,
        hasSellerApplication: false,
      );
      expect(result, '/dashboard');
    });

    test('member with existing application accessing /register/seller-apply redirects to /dashboard/verification', () {
      final result = RouteGuards.getRedirect(
        location: '/register/seller-apply',
        role: 'member',
        isAuthenticated: true,
        hasSellerApplication: true,
      );
      expect(result, '/dashboard/verification');
    });

    test('seller accessing /dashboard/create-listing is allowed', () {
      final result = RouteGuards.getRedirect(
        location: '/dashboard/create-listing',
        role: 'seller',
        isAuthenticated: true,
        hasSellerApplication: false,
      );
      expect(result, isNull);
    });

    test('seller accessing /register/seller-apply redirects to /dashboard/verification', () {
      final result = RouteGuards.getRedirect(
        location: '/register/seller-apply',
        role: 'seller',
        isAuthenticated: true,
        hasSellerApplication: true,
      );
      expect(result, '/dashboard/verification');
    });

    test('admin can access /admin', () {
      final result = RouteGuards.getRedirect(
        location: '/admin',
        role: 'admin',
        isAuthenticated: true,
        hasSellerApplication: false,
      );
      expect(result, isNull);
    });

    test('authenticated user accessing /marketplace is allowed', () {
      final result = RouteGuards.getRedirect(
        location: '/marketplace',
        role: 'member',
        isAuthenticated: true,
        hasSellerApplication: false,
      );
      expect(result, isNull);
    });

    test('admin can access /dashboard/create-listing', () {
      final result = RouteGuards.getRedirect(
        location: '/dashboard/create-listing',
        role: 'admin',
        isAuthenticated: true,
        hasSellerApplication: false,
      );
      expect(result, isNull);
    });
  });
}
