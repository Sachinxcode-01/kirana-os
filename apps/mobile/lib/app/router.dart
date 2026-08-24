import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kirana_mobile/core/extensions/context_extensions.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:kirana_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:kirana_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:kirana_mobile/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:kirana_mobile/features/barcode/presentation/screens/barcode_screen.dart';
import 'package:kirana_mobile/features/billing/presentation/screens/billing_screen.dart';
import 'package:kirana_mobile/features/categories/presentation/screens/categories_screen.dart';
import 'package:kirana_mobile/features/credit/presentation/screens/credit_screen.dart';
import 'package:kirana_mobile/features/customers/presentation/screens/customers_screen.dart';
import 'package:kirana_mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:kirana_mobile/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:kirana_mobile/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:kirana_mobile/features/invoices/presentation/screens/invoices_screen.dart';
import 'package:kirana_mobile/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:kirana_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:kirana_mobile/features/payments/presentation/screens/payments_screen.dart';
import 'package:kirana_mobile/features/products/presentation/screens/products_screen.dart';
import 'package:kirana_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:kirana_mobile/features/purchases/presentation/screens/purchases_screen.dart';
import 'package:kirana_mobile/features/reports/presentation/screens/reports_screen.dart';
import 'package:kirana_mobile/features/returns/presentation/screens/returns_screen.dart';
import 'package:kirana_mobile/features/settings/presentation/screens/settings_screen.dart';
import 'package:kirana_mobile/features/shop/presentation/screens/shop_setup_screen.dart';
import 'package:kirana_mobile/features/splash/presentation/screens/splash_screen.dart';
import 'package:kirana_mobile/features/suppliers/presentation/screens/suppliers_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // 1. If initializing, allow splash
      if (authState.isInitializing) {
        return loc == '/splash' ? null : '/splash';
      }

      final isAuthRoute = loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot-password' ||
          loc == '/reset-password' ||
          loc == '/auth' ||
          loc == '/splash';

      final isOnboardingRoute = loc == '/onboarding' || loc == '/shop-setup';

      // 2. If unauthenticated, redirect to /login
      if (!authState.isAuthenticated) {
        if (isAuthRoute) return null;
        return '/login';
      }

      // 3. If authenticated without an active shop, redirect to onboarding / shop setup
      if (!authState.hasActiveShop) {
        if (isOnboardingRoute) return null;
        return '/onboarding';
      }

      // 4. If authenticated with an active shop, prevent visiting auth/onboarding routes
      if (isAuthRoute || isOnboardingRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/shop-setup',
        builder: (context, state) => const ShopSetupScreen(),
      ),

      // Adaptive App Shell Route
      ShellRoute(
        builder: (context, state, child) {
          return _AppNavigationShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/billing',
            builder: (context, state) => const BillingScreen(),
          ),
          GoRoute(
            path: '/barcode',
            builder: (context, state) => const BarcodeScannerScreen(),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductsScreen(),
          ),
          GoRoute(
            path: '/categories',
            builder: (context, state) => const CategoriesScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/purchases',
            builder: (context, state) => const PurchasesScreen(),
          ),
          GoRoute(
            path: '/suppliers',
            builder: (context, state) => const SuppliersScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/credit',
            builder: (context, state) => const CreditScreen(),
          ),
          GoRoute(
            path: '/payments',
            builder: (context, state) => const PaymentsScreen(),
          ),
          GoRoute(
            path: '/invoices',
            builder: (context, state) => const InvoicesScreen(),
          ),
          GoRoute(
            path: '/bills',
            builder: (context, state) => const InvoicesScreen(),
          ),
          GoRoute(
            path: '/returns',
            builder: (context, state) => const ReturnsScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpensesScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class _AppNavigationShell extends StatelessWidget {
  final Widget child;

  const _AppNavigationShell({required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) {
      return 0;
    }
    if (location.startsWith('/billing') || location.startsWith('/barcode')) {
      return 1;
    }
    if (location.startsWith('/products') || location.startsWith('/categories')) {
      return 2;
    }
    if (location.startsWith('/customers') || location.startsWith('/credit')) {
      return 3;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/billing');
        break;
      case 2:
        context.go('/products');
        break;
      case 3:
        context.go('/credit');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    if (context.isWideScreen) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (idx) => _onItemTapped(idx, context),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Icon(Icons.storefront,
                    color: KiranaColors.primary, size: 32),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale),
                  label: Text('POS'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: Text('Catalog'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: Text('Khata'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (idx) => _onItemTapped(idx, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Billing',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Catalog',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Khata',
          ),
        ],
      ),
    );
  }
}
