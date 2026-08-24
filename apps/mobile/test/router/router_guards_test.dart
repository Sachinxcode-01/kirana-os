import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/features/auth/domain/models/auth_state_model.dart';

void main() {
  group('Router Redirect & Navigation Guard Invariants', () {
    String? computeRedirect({
      required AuthStateModel authState,
      required String matchedLocation,
    }) {
      if (authState.isInitializing) {
        return matchedLocation == '/splash' ? null : '/splash';
      }

      final isAuthRoute = matchedLocation == '/login' ||
          matchedLocation == '/register' ||
          matchedLocation == '/forgot-password' ||
          matchedLocation == '/reset-password' ||
          matchedLocation == '/auth' ||
          matchedLocation == '/splash';

      final isOnboardingRoute =
          matchedLocation == '/onboarding' || matchedLocation == '/shop-setup';

      if (!authState.isAuthenticated) {
        if (isAuthRoute) return null;
        return '/login';
      }

      if (!authState.hasActiveShop) {
        if (isOnboardingRoute) return null;
        return '/onboarding';
      }

      if (isAuthRoute || isOnboardingRoute) {
        return '/dashboard';
      }

      return null;
    }

    test('Initializing state redirects any route to /splash', () {
      final state = AuthStateModel.initializing();
      expect(computeRedirect(authState: state, matchedLocation: '/dashboard'),
          '/splash');
      expect(computeRedirect(authState: state, matchedLocation: '/splash'),
          isNull);
    });

    test(
        'Unauthenticated user attempting to open /dashboard is redirected to /login',
        () {
      final state = AuthStateModel.unauthenticated();
      expect(computeRedirect(authState: state, matchedLocation: '/dashboard'),
          '/login');
      expect(computeRedirect(authState: state, matchedLocation: '/billing'),
          '/login');
      expect(
          computeRedirect(authState: state, matchedLocation: '/login'), isNull);
      expect(computeRedirect(authState: state, matchedLocation: '/register'),
          isNull);
    });

    test('Authenticated user without active shop is redirected to /onboarding',
        () {
      final state = AuthStateModel.authenticatedWithoutShop(
        const UserModel(id: 'u1', email: 'new@store.com', role: 'owner'),
      );

      expect(computeRedirect(authState: state, matchedLocation: '/dashboard'),
          '/onboarding');
      expect(computeRedirect(authState: state, matchedLocation: '/login'),
          '/onboarding');
      expect(computeRedirect(authState: state, matchedLocation: '/onboarding'),
          isNull);
      expect(computeRedirect(authState: state, matchedLocation: '/shop-setup'),
          isNull);
    });

    test('Authenticated user with active shop is allowed to access /dashboard',
        () {
      final state = AuthStateModel.authenticatedWithShop(
        user: const UserModel(
            id: 'u1', email: 'owner@store.com', role: 'owner', shopId: 's1'),
        shopId: 's1',
        shopName: 'Super Store',
      );

      expect(computeRedirect(authState: state, matchedLocation: '/dashboard'),
          isNull);
      expect(computeRedirect(authState: state, matchedLocation: '/billing'),
          isNull);
      expect(computeRedirect(authState: state, matchedLocation: '/login'),
          '/dashboard');
      expect(computeRedirect(authState: state, matchedLocation: '/onboarding'),
          '/dashboard');
    });
  });
}
