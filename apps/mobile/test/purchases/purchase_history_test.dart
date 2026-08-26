import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/features/auth/domain/models/auth_state_model.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/purchases/data/datasources/purchase_local_data_source.dart';
import 'package:kirana_mobile/features/purchases/data/datasources/purchase_remote_data_source.dart';
import 'package:kirana_mobile/features/purchases/data/repositories/purchase_repository_impl.dart';
import 'package:kirana_mobile/features/purchases/domain/models/purchase_history_filter.dart';
import 'package:kirana_mobile/features/purchases/domain/models/purchase_item_model.dart';
import 'package:kirana_mobile/features/purchases/domain/models/purchase_model.dart';
import 'package:kirana_mobile/features/purchases/presentation/providers/purchase_provider.dart';
import 'package:kirana_mobile/features/purchases/presentation/screens/purchases_screen.dart';

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
  group('KIRANAOS Phase 07.3 — Purchase History Tests', () {
    late PurchaseLocalDataSource localDataSource;
    late PurchaseRemoteDataSource remoteDataSource;
    late MockConnectivityService connectivityService;
    late PurchaseRepositoryImpl repository;

    setUp(() {
      localDataSource = PurchaseLocalDataSource();
      remoteDataSource = PurchaseRemoteDataSource();
      connectivityService = MockConnectivityService();
      repository = PurchaseRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
        connectivityService: connectivityService,
      );
    });

    test('1. Loads purchase history list with range pagination', () async {
      final now = DateTime.now();
      for (int i = 1; i <= 25; i++) {
        final p = PurchaseModel(
          id: 'purch_$i',
          shopId: 'shop_alpha',
          purchaseNumber: 'PUR-202608-${i.toString().padLeft(3, '0')}',
          supplierId: 'supp_1',
          supplierName: 'HUL Wholesale',
          supplierReference: 'REF-$i',
          status: i % 2 == 0 ? 'completed' : 'draft',
          items: [
            PurchaseItemModel.create(
              id: 'item_$i',
              purchaseId: 'purch_$i',
              productId: 'prod_maggi',
              productName: 'Maggi Noodles',
              unit: 'Pack',
              quantity: 5.0,
              purchasePricePaise: 1200,
            ),
          ],
          subtotalPaise: 6000,
          totalPaise: 6000,
          createdAt: now.subtract(Duration(minutes: i * 10)),
          updatedAt: now.subtract(Duration(minutes: i * 10)),
        );
        await localDataSource.saveDraft(p);
      }

      final page1Res = await repository.getPurchaseHistory(
        shopId: 'shop_alpha',
        filter: const PurchaseHistoryFilter(page: 1, pageSize: 10),
      );

      expect(page1Res, isA<Success<PurchaseHistoryResult, Failure>>());
      final result1 =
          (page1Res as Success<PurchaseHistoryResult, Failure>).data;
      expect(result1.purchases.length, equals(10));
      expect(result1.hasMore, isTrue);
      expect(result1.totalCount, equals(25));

      final page3Res = await repository.getPurchaseHistory(
        shopId: 'shop_alpha',
        filter: const PurchaseHistoryFilter(page: 3, pageSize: 10),
      );
      final result3 =
          (page3Res as Success<PurchaseHistoryResult, Failure>).data;
      expect(result3.purchases.length, equals(5));
      expect(result3.hasMore, isFalse);
    });

    test('2. Filters purchase history by status (DRAFT vs COMPLETED)',
        () async {
      final p1 = PurchaseModel(
        id: 'purch_d1',
        shopId: 'shop_alpha',
        purchaseNumber: 'PUR-DRAFT-1',
        status: 'draft',
        items: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final p2 = PurchaseModel(
        id: 'purch_c1',
        shopId: 'shop_alpha',
        purchaseNumber: 'PUR-COMP-1',
        status: 'completed',
        items: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localDataSource.saveDraft(p1);
      await localDataSource.saveDraft(p2);

      // Filter DRAFT
      final draftRes = await repository.getPurchaseHistory(
        shopId: 'shop_alpha',
        filter: const PurchaseHistoryFilter(
          statusFilter: PurchaseStatusFilter.draft,
        ),
      );
      final drafts =
          (draftRes as Success<PurchaseHistoryResult, Failure>).data.purchases;
      expect(drafts.length, equals(1));
      expect(drafts.first.status, equals('draft'));

      // Filter COMPLETED
      final compRes = await repository.getPurchaseHistory(
        shopId: 'shop_alpha',
        filter: const PurchaseHistoryFilter(
          statusFilter: PurchaseStatusFilter.completed,
        ),
      );
      final completed =
          (compRes as Success<PurchaseHistoryResult, Failure>).data.purchases;
      expect(completed.length, equals(1));
      expect(completed.first.status, equals('completed'));
    });

    test('3. Searches purchase history by purchase number or supplier name',
        () async {
      final p1 = PurchaseModel(
        id: 'purch_s1',
        shopId: 'shop_alpha',
        purchaseNumber: 'PUR-998811',
        supplierName: 'Amul Dairy Distributors',
        status: 'completed',
        items: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final p2 = PurchaseModel(
        id: 'purch_s2',
        shopId: 'shop_alpha',
        purchaseNumber: 'PUR-776655',
        supplierName: 'Nestle India Agency',
        status: 'completed',
        items: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localDataSource.saveDraft(p1);
      await localDataSource.saveDraft(p2);

      // Search by Purchase #
      final numRes = await repository.getPurchaseHistory(
        shopId: 'shop_alpha',
        filter: const PurchaseHistoryFilter(search: '998811'),
      );
      final numMatches =
          (numRes as Success<PurchaseHistoryResult, Failure>).data.purchases;
      expect(numMatches.length, equals(1));
      expect(numMatches.first.purchaseNumber, equals('PUR-998811'));

      // Search by Supplier Name
      final nameRes = await repository.getPurchaseHistory(
        shopId: 'shop_alpha',
        filter: const PurchaseHistoryFilter(search: 'Nestle'),
      );
      final nameMatches =
          (nameRes as Success<PurchaseHistoryResult, Failure>).data.purchases;
      expect(nameMatches.length, equals(1));
      expect(nameMatches.first.supplierName, contains('Nestle'));
    });

    test('4. Displays offline banner when offline', () async {
      final p = PurchaseModel(
        id: 'purch_off1',
        shopId: 'shop_alpha',
        purchaseNumber: 'PUR-OFFLINE-1',
        status: 'completed',
        items: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localDataSource.saveDraft(p);

      connectivityService.setStatus(ConnectivityStatus.offline);

      final res = await repository.getPurchaseHistory(
        shopId: 'shop_alpha',
      );
      expect(res, isA<Success<PurchaseHistoryResult, Failure>>());
      final result = (res as Success<PurchaseHistoryResult, Failure>).data;
      expect(result.isOffline, isTrue);
      expect(result.isPartialOfflineHistory, isTrue);
    });

    testWidgets(
        '5. Renders PurchasesScreen UI with filters and Stock Added badge',
        (tester) async {
      final user = UserModel(
        id: 'user_owner',
        email: 'owner@kirana.com',
        displayName: 'Owner',
        role: 'owner',
        shopId: 'shop_alpha',
        shopName: 'Alpha Kirana',
      );

      final p = PurchaseModel(
        id: 'purch_ui_1',
        shopId: 'shop_alpha',
        purchaseNumber: 'PUR-UI-55',
        supplierName: 'Parle Biscuits',
        status: 'completed',
        items: [
          PurchaseItemModel.create(
            id: 'item_ui_1',
            purchaseId: 'purch_ui_1',
            productId: 'prod_parle',
            productName: 'Parle-G 100g',
            unit: 'Pack',
            quantity: 20.0,
            purchasePricePaise: 800,
          ),
        ],
        subtotalPaise: 16000,
        totalPaise: 16000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localDataSource.saveDraft(p);

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
            purchaseRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: PurchasesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Header & Cards
      expect(find.text('Purchase History & Inward Goods'), findsOneWidget);
      expect(find.text('#PUR-UI-55'), findsOneWidget);
      expect(find.text('COMPLETED'), findsNWidgets(2));

      // Tap purchase card to open details modal
      await tester.tap(find.text('#PUR-UI-55'));
      await tester.pumpAndSettle();

      // Verify Stock Added badge and read-only notice in modal
      expect(find.text('Stock Added'), findsOneWidget);
      expect(find.text('Parle-G 100g'), findsOneWidget);
      expect(
          find.text(
              'Completed purchase records are read-only to preserve inventory audit trails.'),
          findsOneWidget);
    });
  });
}

class AuthNotifierMock extends StateNotifier<AuthStateModel>
    implements AuthNotifier {
  AuthNotifierMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
