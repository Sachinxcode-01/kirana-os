import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/features/auth/domain/models/auth_state_model.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/billing/data/datasources/billing_local_data_source.dart';
import 'package:kirana_mobile/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:kirana_mobile/features/billing/data/repositories/billing_repository_impl.dart';
import 'package:kirana_mobile/features/billing/domain/models/bill_history_filter.dart';
import 'package:kirana_mobile/features/billing/domain/models/bill_model.dart';
import 'package:kirana_mobile/features/billing/presentation/providers/billing_provider.dart';
import 'package:kirana_mobile/features/billing/presentation/screens/bill_history_screen.dart';

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
  group('KIRANAOS Phase 06.6 — Bill History Foundation Tests', () {
    late BillingLocalDataSource localDataSource;
    late BillingRemoteDataSource remoteDataSource;
    late MockConnectivityService connectivityService;
    late BillingRepositoryImpl repository;

    final now = DateTime.now();
    final sampleBill1 = BillModel(
      id: 'bill_001',
      shopId: 'shop_alpha',
      cashierId: 'user_cashier_1',
      billNumber: 'INV-1001',
      status: 'completed',
      customerName: 'Ramesh Kumar',
      customerPhone: '9876543210',
      totalPaise: 45000,
      subtotalPaise: 45000,
      paymentStatus: 'paid',
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now.subtract(const Duration(hours: 2)),
      items: [
        BillItemModel(
          id: 'item_1',
          billId: 'bill_001',
          productId: 'prod_1',
          productName: 'Atta 5kg',
          unitPricePaise: 25000,
          quantity: 1,
          taxAmountPaise: 0,
          totalPaise: 25000,
          createdAt: now,
        ),
        BillItemModel(
          id: 'item_2',
          billId: 'bill_001',
          productId: 'prod_2',
          productName: 'Mustard Oil 1L',
          unitPricePaise: 20000,
          quantity: 1,
          taxAmountPaise: 0,
          totalPaise: 20000,
          createdAt: now,
        ),
      ],
    );

    final sampleBill2 = BillModel(
      id: 'bill_002',
      shopId: 'shop_alpha',
      cashierId: 'user_cashier_2',
      billNumber: 'INV-1002',
      status: 'cancelled',
      customerName: 'Suresh Patel',
      customerPhone: '9123456789',
      totalPaise: 12000,
      subtotalPaise: 12000,
      paymentStatus: 'unpaid',
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(days: 1)),
    );

    final sampleBillOtherShop = BillModel(
      id: 'bill_003',
      shopId: 'shop_beta',
      cashierId: 'user_cashier_1',
      billNumber: 'INV-9001',
      status: 'completed',
      totalPaise: 5000,
      subtotalPaise: 5000,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() async {
      localDataSource = BillingLocalDataSource();
      remoteDataSource = BillingRemoteDataSource();
      connectivityService = MockConnectivityService();
      repository = BillingRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
        connectivityService: connectivityService,
      );

      // Seed local storage with sample bills
      await localDataSource.saveDraftBill(sampleBill1);
      await localDataSource.saveDraftBill(sampleBill2);
      await localDataSource.saveDraftBill(sampleBillOtherShop);
    });

    test('1. Loads completed bill list with shop isolation', () async {
      final res = await repository.getBillHistory(
        shopId: 'shop_alpha',
        userRole: 'owner',
        currentUserId: 'user_owner',
        filter: const BillHistoryFilter(),
      );

      expect(res, isA<Success<BillHistoryResult, Failure>>());
      final result = (res as Success<BillHistoryResult, Failure>).data;
      expect(result.bills.length, equals(2));
      expect(result.bills.any((b) => b.id == 'bill_003'), isFalse);
    });

    test(
        '2. Debounced search filters by bill number, customer name, and customer phone',
        () async {
      // Bill number search
      final searchNumRes = await repository.getBillHistory(
        shopId: 'shop_alpha',
        userRole: 'owner',
        currentUserId: 'user_owner',
        filter: const BillHistoryFilter(search: '1001'),
      );
      final numBills =
          (searchNumRes as Success<BillHistoryResult, Failure>).data.bills;
      expect(numBills.length, equals(1));
      expect(numBills.first.billNumber, equals('INV-1001'));

      // Customer name search
      final searchNameRes = await repository.getBillHistory(
        shopId: 'shop_alpha',
        userRole: 'owner',
        currentUserId: 'user_owner',
        filter: const BillHistoryFilter(search: 'Ramesh'),
      );
      final nameBills =
          (searchNameRes as Success<BillHistoryResult, Failure>).data.bills;
      expect(nameBills.length, equals(1));
      expect(nameBills.first.customerName, equals('Ramesh Kumar'));

      // Customer phone search
      final searchPhoneRes = await repository.getBillHistory(
        shopId: 'shop_alpha',
        userRole: 'owner',
        currentUserId: 'user_owner',
        filter: const BillHistoryFilter(search: '9123456789'),
      );
      final phoneBills =
          (searchPhoneRes as Success<BillHistoryResult, Failure>).data.bills;
      expect(phoneBills.length, equals(1));
      expect(phoneBills.first.customerPhone, equals('9123456789'));
    });

    test('3. Filters by status (COMPLETED vs CANCELLED)', () async {
      final completedRes = await repository.getBillHistory(
        shopId: 'shop_alpha',
        userRole: 'owner',
        currentUserId: 'user_owner',
        filter:
            const BillHistoryFilter(statusFilter: BillStatusFilter.completed),
      );
      final completedBills =
          (completedRes as Success<BillHistoryResult, Failure>).data.bills;
      expect(completedBills.length, equals(1));
      expect(completedBills.first.id, equals('bill_001'));

      final cancelledRes = await repository.getBillHistory(
        shopId: 'shop_alpha',
        userRole: 'owner',
        currentUserId: 'user_owner',
        filter:
            const BillHistoryFilter(statusFilter: BillStatusFilter.cancelled),
      );
      final cancelledBills =
          (cancelledRes as Success<BillHistoryResult, Failure>).data.bills;
      expect(cancelledBills.length, equals(1));
      expect(cancelledBills.first.id, equals('bill_002'));
    });

    test(
        '4. Restricts Cashiers from accessing bills of another cashier if specified',
        () async {
      final res = await repository.getBillHistory(
        shopId: 'shop_alpha',
        userRole: 'cashier',
        currentUserId: 'user_cashier_1',
        filter: const BillHistoryFilter(cashierId: 'user_cashier_2'),
      );

      expect(res, isA<ErrorResult<BillHistoryResult, Failure>>());
      final err = (res as ErrorResult<BillHistoryResult, Failure>).failure;
      expect(err, isA<PermissionDeniedFailure>());
    });

    test('5. Serves cached bills offline with isOffline indicator banner',
        () async {
      connectivityService.setStatus(ConnectivityStatus.offline);

      final res = await repository.getBillHistory(
        shopId: 'shop_alpha',
        userRole: 'owner',
        currentUserId: 'user_owner',
        filter: const BillHistoryFilter(),
      );

      expect(res, isA<Success<BillHistoryResult, Failure>>());
      final result = (res as Success<BillHistoryResult, Failure>).data;
      expect(result.isOffline, isTrue);
      expect(result.isPartialOfflineHistory, isTrue);
      expect(result.bills.isNotEmpty, isTrue);
    });

    testWidgets('6. Renders BillHistoryScreen with bill details modal',
        (tester) async {
      final user = UserModel(
        id: 'user_owner',
        email: 'owner@kirana.com',
        displayName: 'Owner',
        role: 'owner',
        shopId: 'shop_alpha',
        shopName: 'Alpha Kirana',
      );

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
            billingRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: BillHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Bill History Title & List Elements
      expect(find.text('Bill History'), findsOneWidget);
      expect(find.text('#INV-1001'), findsOneWidget);
      expect(
          find.text('Customer: Ramesh Kumar • ${sampleBill1.createdAt.year}'),
          findsNothing);

      // Tap on Bill to open Bill Details Modal
      await tester.tap(find.text('#INV-1001'));
      await tester.pumpAndSettle();

      // Verify Bill Details breakdown
      expect(find.text('Bill #INV-1001'), findsOneWidget);
      expect(find.text('Atta 5kg'), findsOneWidget);
      expect(find.text('VIEW RECEIPT'), findsOneWidget);
      expect(find.text('PRINT'), findsOneWidget);
    });
  });
}

class AuthNotifierMock extends StateNotifier<AuthStateModel>
    implements AuthNotifier {
  AuthNotifierMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
