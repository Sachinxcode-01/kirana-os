import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/features/auth/domain/models/auth_state_model.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';
import 'package:kirana_mobile/features/purchases/data/datasources/purchase_local_data_source.dart';
import 'package:kirana_mobile/features/purchases/data/datasources/purchase_remote_data_source.dart';
import 'package:kirana_mobile/features/purchases/data/repositories/purchase_repository_impl.dart';
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
  group('KIRANAOS Phase 07.1 — Purchase Foundation Tests', () {
    late PurchaseLocalDataSource localDataSource;
    late PurchaseRemoteDataSource remoteDataSource;
    late MockConnectivityService connectivityService;
    late PurchaseRepositoryImpl repository;

    final now = DateTime.now();

    final sampleProduct1 = ProductModel(
      id: 'prod_atta_5kg',
      shopId: 'shop_alpha',
      name: 'Fortune Wheat Atta 5kg',
      unit: 'pcs',
      sellingPricePaise: 25000,
      purchasePricePaise: 21000, // ₹210.00
      mrpPaise: 26000,
      currentStock: 10.0,
      minStockAlert: 5.0,
      createdAt: now,
      updatedAt: now,
    );

    final sampleProduct2 = ProductModel(
      id: 'prod_oil_1l',
      shopId: 'shop_alpha',
      name: 'Dhara Mustard Oil 1L',
      unit: 'pcs',
      sellingPricePaise: 18000,
      purchasePricePaise: 15000, // ₹150.00
      mrpPaise: 19000,
      currentStock: 5.0,
      minStockAlert: 3.0,
      createdAt: now,
      updatedAt: now,
    );

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

    test('1. Creates a purchase draft and persists locally', () async {
      final res = await repository.createDraft(
        shopId: 'shop_alpha',
        cashierId: 'user_owner',
        supplierReference: 'INV-METRO-001',
      );

      expect(res, isA<Success<PurchaseModel, Failure>>());
      final draft = (res as Success<PurchaseModel, Failure>).data;
      expect(draft.isDraft, isTrue);
      expect(draft.shopId, equals('shop_alpha'));
      expect(draft.supplierReference, equals('INV-METRO-001'));
      expect(draft.items, isEmpty);

      // Retrieve persisted draft
      final fetchRes = await repository.getPurchaseById(draft.id);
      expect(fetchRes, isA<Success<PurchaseModel?, Failure>>());
      final fetched = (fetchRes as Success<PurchaseModel?, Failure>).data;
      expect(fetched, isNotNull);
      expect(fetched!.id, equals(draft.id));
    });

    test(
        '2. Adds product items, edits quantity & purchase price, and calculates total accurately',
        () async {
      final draftRes = await repository.createDraft(
        shopId: 'shop_alpha',
        cashierId: 'user_owner',
      );
      var draft = (draftRes as Success<PurchaseModel, Failure>).data;

      // Add item 1: 5 units of Atta @ ₹210.00 (21000 paise) = 105000 paise (₹1,050.00)
      final item1 = PurchaseItemModel.create(
        id: 'item_1',
        purchaseId: draft.id,
        productId: sampleProduct1.id,
        productName: sampleProduct1.name,
        unit: sampleProduct1.unit,
        quantity: 5.0,
        purchasePricePaise: sampleProduct1.purchasePricePaise,
      );

      // Add item 2: 10 units of Oil @ ₹150.00 (15000 paise) = 150000 paise (₹1,500.00)
      final item2 = PurchaseItemModel.create(
        id: 'item_2',
        purchaseId: draft.id,
        productId: sampleProduct2.id,
        productName: sampleProduct2.name,
        unit: sampleProduct2.unit,
        quantity: 10.0,
        purchasePricePaise: sampleProduct2.purchasePricePaise,
      );

      draft = draft.copyWith(items: [item1, item2]);
      await repository.saveDraft(draft);

      // Verify grand total calculation
      expect(
          draft.subtotalPaise, equals(255000)); // 105000 + 150000 = ₹2,550.00
      expect(draft.totalPaise, equals(255000));

      // Edit item 1 quantity to 10
      final updatedItem1 = item1.copyWith(quantity: 10.0);
      draft = draft.copyWith(items: [updatedItem1, item2]);
      await repository.saveDraft(draft);

      // New Total: 10 * 21000 + 10 * 15000 = 210000 + 150000 = 360000 paise (₹3,600.00)
      expect(draft.totalPaise, equals(360000));

      // Remove item 2
      draft = draft.copyWith(items: [updatedItem1]);
      await repository.saveDraft(draft);
      expect(draft.items.length, equals(1));
      expect(draft.totalPaise, equals(210000));
    });

    test('3. Confirms purchase stock-in transaction server-authoritatively',
        () async {
      final draftRes = await repository.createDraft(
        shopId: 'shop_alpha',
        cashierId: 'user_owner',
      );
      var draft = (draftRes as Success<PurchaseModel, Failure>).data;

      final item = PurchaseItemModel.create(
        id: 'item_1',
        purchaseId: draft.id,
        productId: sampleProduct1.id,
        productName: sampleProduct1.name,
        quantity: 20.0,
        purchasePricePaise: 21000,
      );

      draft = draft.copyWith(items: [item]);
      await repository.saveDraft(draft);

      final confirmRes = await repository.confirmPurchaseStockIn(
        shopId: 'shop_alpha',
        userRole: 'owner',
        currentUserId: 'user_owner',
        purchase: draft,
        idempotencyKey: 'idemp_key_1001',
      );

      expect(confirmRes, isA<Success<PurchaseModel, Failure>>());
      final completed = (confirmRes as Success<PurchaseModel, Failure>).data;
      expect(completed.isCompleted, isTrue);
      expect(completed.idempotencyKey, equals('idemp_key_1001'));
    });

    test(
        '4. Blocks offline stock-in confirmation without faking stock increase',
        () async {
      connectivityService.setStatus(ConnectivityStatus.offline);

      final draftRes = await repository.createDraft(
        shopId: 'shop_alpha',
        cashierId: 'user_owner',
      );
      var draft = (draftRes as Success<PurchaseModel, Failure>).data;

      final item = PurchaseItemModel.create(
        id: 'item_1',
        purchaseId: draft.id,
        productId: sampleProduct1.id,
        productName: sampleProduct1.name,
        quantity: 5.0,
        purchasePricePaise: 21000,
      );
      draft = draft.copyWith(items: [item]);

      final confirmRes = await repository.confirmPurchaseStockIn(
        shopId: 'shop_alpha',
        userRole: 'owner',
        currentUserId: 'user_owner',
        purchase: draft,
        idempotencyKey: 'idemp_offline_1',
      );

      expect(confirmRes, isA<ErrorResult<PurchaseModel, Failure>>());
      final failure =
          (confirmRes as ErrorResult<PurchaseModel, Failure>).failure;
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, contains('Network connection required'));
    });

    test('5. Enforces Shop Isolation and RBAC Permission Checks', () async {
      final draftRes = await repository.createDraft(
        shopId: 'shop_alpha',
        cashierId: 'user_cashier_1',
      );
      var draft = (draftRes as Success<PurchaseModel, Failure>).data;
      draft = draft.copyWith(items: [
        PurchaseItemModel.create(
          id: 'item_1',
          purchaseId: draft.id,
          productId: sampleProduct1.id,
          productName: sampleProduct1.name,
          quantity: 2.0,
          purchasePricePaise: 21000,
        )
      ]);

      // Mismatched shop ID
      final shopMismatchRes = await repository.confirmPurchaseStockIn(
        shopId: 'shop_beta',
        userRole: 'owner',
        currentUserId: 'user_owner',
        purchase: draft,
        idempotencyKey: 'idemp_mismatch',
      );
      expect(shopMismatchRes, isA<ErrorResult<PurchaseModel, Failure>>());
      expect(
        (shopMismatchRes as ErrorResult<PurchaseModel, Failure>).failure,
        isA<PermissionDeniedFailure>(),
      );

      // Unauthorized Cashier Role (requires Owner, Manager, or Inventory Staff)
      final roleDeniedRes = await repository.confirmPurchaseStockIn(
        shopId: 'shop_alpha',
        userRole: 'cashier',
        currentUserId: 'user_cashier_1',
        purchase: draft,
        idempotencyKey: 'idemp_role_denied',
      );
      expect(roleDeniedRes, isA<ErrorResult<PurchaseModel, Failure>>());
      expect(
        (roleDeniedRes as ErrorResult<PurchaseModel, Failure>).failure,
        isA<PermissionDeniedFailure>(),
      );
    });

    testWidgets(
        '6. Renders PurchasesScreen and PurchaseDraftScreen with stock-in flow',
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
            purchaseRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: PurchasesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Purchases Screen Header
      expect(find.text('Purchases & Inward Goods'), findsOneWidget);
      expect(find.text('New Purchase'), findsOneWidget);

      // Tap on "+ New Purchase" button
      await tester.tap(find.text('New Purchase').first);
      await tester.pumpAndSettle();

      // Verify Purchase Draft Screen
      expect(find.text('New Purchase Inward'), findsOneWidget);
      expect(find.text('CONFIRM STOCK-IN'), findsOneWidget);
    });
  });
}

class AuthNotifierMock extends StateNotifier<AuthStateModel>
    implements AuthNotifier {
  AuthNotifierMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
