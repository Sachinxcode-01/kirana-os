import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/app/app_providers.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kirana_mobile/features/auth/domain/models/auth_state_model.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/dashboard/presentation/widgets/dashboard_session_header.dart';
import '../auth/account_security_test.dart';

class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier(AuthStateModel initialState)
      : super(MockAccountSecurityAuthRepository(), AuthRemoteDataSource()) {
    state = initialState;
  }

  @override
  Future<void> restoreSession() async {
    // Preserve initial state for widget testing
  }
}

void main() {
  group('KIRANAOS AUTH 9 — Dashboard Session Header Tests', () {
    final mockUserOwner = const UserModel(
      id: 'usr_101',
      email: 'owner@kirana.com',
      displayName: 'Ramesh Gupta',
      role: 'owner',
      shopId: 'shop_101',
      shopName: 'Gupta Kirana Store',
    );

    final mockUserCashier = const UserModel(
      id: 'usr_102',
      email: 'cashier@kirana.com',
      displayName: 'Suresh Cashier',
      role: 'cashier',
      shopId: 'shop_101',
      shopName: 'Gupta Kirana Store',
    );

    Widget createHeaderWidget({
      required AuthStateModel authState,
      ConnectivityStatus connectivity = ConnectivityStatus.online,
      int pendingSyncCount = 0,
    }) {
      return ProviderScope(
        overrides: [
          authNotifierProvider
              .overrideWith((ref) => TestAuthNotifier(authState)),
          connectivityStatusStreamProvider.overrideWith(
            (ref) => Stream.value(connectivity),
          ),
          pendingSyncCountProvider.overrideWith(
            (ref) => Stream.value(pendingSyncCount),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DashboardSessionHeader(),
          ),
        ),
      );
    }

    testWidgets('1. Displays real user name, shop name, and OWNER role badge',
        (WidgetTester tester) async {
      final authState = AuthStateModel.authenticatedWithShop(
        user: mockUserOwner,
        shopId: 'shop_101',
        shopName: 'Gupta Kirana Store',
      );

      await tester.pumpWidget(createHeaderWidget(authState: authState));
      await tester.pumpAndSettle();

      expect(find.text('Gupta Kirana Store'), findsOneWidget);
      expect(find.textContaining('Ramesh Gupta'), findsOneWidget);
      expect(find.text('OWNER'), findsOneWidget);
      expect(find.text('ONLINE (Cloud Synced)'), findsOneWidget);
    });

    testWidgets(
        '2. Displays CASHIER role badge and OFFLINE indicator when offline',
        (WidgetTester tester) async {
      final authState = AuthStateModel.authenticatedWithShop(
        user: mockUserCashier,
        shopId: 'shop_101',
        shopName: 'Gupta Kirana Store',
      );

      await tester.pumpWidget(
        createHeaderWidget(
          authState: authState,
          connectivity: ConnectivityStatus.offline,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gupta Kirana Store'), findsOneWidget);
      expect(find.textContaining('Suresh Cashier'), findsOneWidget);
      expect(find.text('CASHIER'), findsOneWidget);
      expect(find.text('OFFLINE (Cached Data)'), findsOneWidget);
    });

    testWidgets('3. Displays SYNCING status with pending sync items count',
        (WidgetTester tester) async {
      final authState = AuthStateModel.authenticatedWithShop(
        user: mockUserOwner,
        shopId: 'shop_101',
        shopName: 'Gupta Kirana Store',
      );

      await tester.pumpWidget(
        createHeaderWidget(
          authState: authState,
          connectivity: ConnectivityStatus.syncing,
          pendingSyncCount: 3,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SYNCING (3 pending)'), findsOneWidget);
    });

    testWidgets('4. Displays SYNC ERROR when sync error occurs',
        (WidgetTester tester) async {
      final authState = AuthStateModel.authenticatedWithShop(
        user: mockUserOwner,
        shopId: 'shop_101',
        shopName: 'Gupta Kirana Store',
      );

      await tester.pumpWidget(
        createHeaderWidget(
          authState: authState,
          connectivity: ConnectivityStatus.syncError,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SYNC ERROR'), findsOneWidget);
    });
  });
}
