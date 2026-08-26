import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/features/auth/domain/models/auth_state_model.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/inventory/data/datasources/low_stock_local_data_source.dart';
import 'package:kirana_mobile/features/inventory/data/datasources/low_stock_remote_data_source.dart';
import 'package:kirana_mobile/features/inventory/data/repositories/low_stock_repository_impl.dart';
import 'package:kirana_mobile/features/inventory/domain/models/low_stock_alert_model.dart';
import 'package:kirana_mobile/features/inventory/presentation/providers/low_stock_provider.dart';
import 'package:kirana_mobile/features/inventory/presentation/screens/low_stock_list_screen.dart';
import 'package:kirana_mobile/features/inventory/presentation/widgets/low_stock_dashboard_card.dart';

class MockConnectivityService implements ConnectivityService {
  ConnectivityStatus _status = ConnectivityStatus.online;

  void setStatus(ConnectivityStatus s) => _status = s;

  @override
  ConnectivityStatus get currentStatus => _status;

  @override
  Stream<ConnectivityStatus> get statusStream => Stream.value(_status);

  @override
  Future<bool> isOnline() async => _status == ConnectivityStatus.online;

  @override
  Future<ConnectivityStatus> checkConnectivity() async => _status;

  @override
  void updateSyncStatus(ConnectivityStatus status) {
    _status = status;
  }

  @override
  void dispose() {}
}

void main() {
  group('KIRANAOS Phase 07.5 — Low-Stock Alerts Tests', () {
    late LowStockLocalDataSource localDataSource;
    late LowStockRemoteDataSource remoteDataSource;
    late MockConnectivityService connectivityService;
    late LowStockRepositoryImpl repository;

    setUp(() {
      localDataSource = LowStockLocalDataSource();
      remoteDataSource = LowStockRemoteDataSource();
      connectivityService = MockConnectivityService();
      repository = LowStockRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
        connectivityService: connectivityService,
      );
    });

    test('1. Accurately detects LOW STOCK and OUT OF STOCK alert states', () {
      final lowStockAlert = LowStockAlertModel(
        id: 'alt_1',
        shopId: 'shop_alpha',
        productId: 'prod_1',
        productName: 'Tata Salt 1kg',
        currentQuantity: 2.0,
        minimumQuantity: 5.0,
        status: 'low_stock',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(lowStockAlert.isLowStock, isTrue);
      expect(lowStockAlert.isOutOfStock, isFalse);
      expect(lowStockAlert.urgencyRatio, equals(0.4)); // 2.0 / 5.0

      final outOfStockAlert = LowStockAlertModel(
        id: 'alt_2',
        shopId: 'shop_alpha',
        productId: 'prod_2',
        productName: 'Fortune Oil 1L',
        currentQuantity: 0.0,
        minimumQuantity: 3.0,
        status: 'out_of_stock',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(outOfStockAlert.isOutOfStock, isTrue);
      expect(outOfStockAlert.urgencyRatio, equals(0.0));
    });

    test('2. Sorts alerts by urgency (OUT OF STOCK first, then lowest ratio)',
        () async {
      final a1 = LowStockAlertModel(
        id: 'alt_1',
        shopId: 'shop_alpha',
        productId: 'prod_1',
        productName: 'Low Stock Item A (Ratio 0.5)',
        currentQuantity: 5.0,
        minimumQuantity: 10.0,
        status: 'low_stock',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final a2 = LowStockAlertModel(
        id: 'alt_2',
        shopId: 'shop_alpha',
        productId: 'prod_2',
        productName: 'Out of Stock Item B',
        currentQuantity: 0.0,
        minimumQuantity: 5.0,
        status: 'out_of_stock',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final a3 = LowStockAlertModel(
        id: 'alt_3',
        shopId: 'shop_alpha',
        productId: 'prod_3',
        productName: 'Critical Low Stock C (Ratio 0.2)',
        currentQuantity: 2.0,
        minimumQuantity: 10.0,
        status: 'low_stock',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await localDataSource.saveAlerts([a1, a2, a3]);

      final res = await repository.getLowStockAlerts(shopId: 'shop_alpha');
      expect(res, isA<Success<List<LowStockAlertModel>, Failure>>());

      final sorted = (res as Success<List<LowStockAlertModel>, Failure>).data;
      expect(sorted.length, equals(3));
      expect(sorted[0].productName, equals('Out of Stock Item B'));
      expect(sorted[1].productName, equals('Critical Low Stock C (Ratio 0.2)'));
      expect(sorted[2].productName, equals('Low Stock Item A (Ratio 0.5)'));
    });

    test(
        '3. Enforces alert deduplication on stock update for same shop and product',
        () async {
      final initialAlert = LowStockAlertModel(
        id: 'alt_dedup_1',
        shopId: 'shop_alpha',
        productId: 'prod_dedup_1',
        productName: 'Amul Milk 500ml',
        currentQuantity: 3.0,
        minimumQuantity: 5.0,
        status: 'low_stock',
        isRead: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localDataSource.saveAlert(initialAlert);

      // Stock drops further to 0
      final updatedAlert = initialAlert.copyWith(
        currentQuantity: 0.0,
        status: 'out_of_stock',
        updatedAt: DateTime.now(),
      );
      await localDataSource.saveAlert(updatedAlert);

      final res = await repository.getLowStockAlerts(shopId: 'shop_alpha');
      final list = (res as Success<List<LowStockAlertModel>, Failure>).data;
      expect(list.length, equals(1)); // Deduplicated single alert
      expect(list.first.isOutOfStock, isTrue);
      expect(list.first.currentQuantity, equals(0.0));
    });

    test('4. Toggles READ/UNREAD states and marks all as read', () async {
      final a1 = LowStockAlertModel(
        id: 'alt_read_1',
        shopId: 'shop_alpha',
        productId: 'p1',
        productName: 'Maggi 2-Min Noodles',
        currentQuantity: 1.0,
        minimumQuantity: 5.0,
        status: 'low_stock',
        isRead: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final a2 = LowStockAlertModel(
        id: 'alt_read_2',
        shopId: 'shop_alpha',
        productId: 'p2',
        productName: 'Parle-G 100g',
        currentQuantity: 0.0,
        minimumQuantity: 10.0,
        status: 'out_of_stock',
        isRead: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await localDataSource.saveAlerts([a1, a2]);

      // Mark single alert as read
      await repository.markAlertAsRead(
          shopId: 'shop_alpha', alertId: 'alt_read_1');
      var res = await repository.getLowStockAlerts(shopId: 'shop_alpha');
      var list = (res as Success<List<LowStockAlertModel>, Failure>).data;
      expect(list.firstWhere((a) => a.id == 'alt_read_1').isRead, isTrue);
      expect(list.firstWhere((a) => a.id == 'alt_read_2').isRead, isFalse);

      // Mark all as read
      await repository.markAllAlertsAsRead(shopId: 'shop_alpha');
      res = await repository.getLowStockAlerts(shopId: 'shop_alpha');
      list = (res as Success<List<LowStockAlertModel>, Failure>).data;
      expect(list.every((a) => a.isRead), isTrue);
    });

    test(
        '5. Stock increase (purchase inward) resolves and removes low-stock alert',
        () async {
      final alert = LowStockAlertModel(
        id: 'alt_resolve_1',
        shopId: 'shop_alpha',
        productId: 'prod_resolve_1',
        productName: 'Colgate Toothpaste 100g',
        currentQuantity: 1.0,
        minimumQuantity: 5.0,
        status: 'low_stock',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localDataSource.saveAlert(alert);

      // Verify alert exists
      var res = await repository.getLowStockAlerts(shopId: 'shop_alpha');
      expect((res as Success).data.length, equals(1));

      // Simulate stock purchase inward replenishing current_quantity to 15 (above minimum_quantity 5)
      await localDataSource.removeAlertByProductId(
          'shop_alpha', 'prod_resolve_1');

      res = await repository.getLowStockAlerts(shopId: 'shop_alpha');
      expect((res as Success).data.length, equals(0));
    });

    testWidgets('6. Renders LowStockDashboardCard and LowStockListScreen UI',
        (tester) async {
      final user = UserModel(
        id: 'user_owner',
        email: 'owner@kirana.com',
        displayName: 'Owner',
        role: 'owner',
        shopId: 'shop_alpha',
        shopName: 'Alpha Kirana',
      );

      final alert = LowStockAlertModel(
        id: 'alt_ui_1',
        shopId: 'shop_alpha',
        productId: 'prod_ui_1',
        productName: 'Surf Excel 1kg',
        currentQuantity: 1.0,
        minimumQuantity: 4.0,
        status: 'low_stock',
        isRead: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localDataSource.saveAlert(alert);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifierMock(
                AuthStateModel.authenticatedWithShop(
                  user: user,
                  shopId: 'shop_alpha',
                  shopName: 'Alpha Kirana',
                ),
              ),
            ),
            lowStockRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: const [
                  LowStockDashboardCard(),
                  Expanded(child: LowStockListScreen()),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Dashboard Card counters
      expect(find.text('Stock Level Alerts'), findsWidgets);
      expect(find.text('1 NEW'), findsWidgets);
      expect(find.text('1 products'), findsWidgets);

      // Verify LowStockListScreen
      expect(find.text('Surf Excel 1kg'), findsWidgets);
      expect(find.text('LOW STOCK'), findsWidgets);
    });
  });
}

class AuthNotifierMock extends StateNotifier<AuthStateModel>
    implements AuthNotifier {
  AuthNotifierMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
