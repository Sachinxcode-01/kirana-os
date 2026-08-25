import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/features/billing/data/datasources/billing_local_data_source.dart';
import 'package:kirana_mobile/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:kirana_mobile/features/billing/data/repositories/billing_repository_impl.dart';
import 'package:kirana_mobile/features/billing/domain/repositories/billing_repository.dart';
import 'package:kirana_mobile/features/billing/domain/usecases/billing_usecases.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';

class TestConnectivityService implements ConnectivityService {
  ConnectivityStatus status = ConnectivityStatus.online;

  @override
  ConnectivityStatus get currentStatus => status;

  @override
  Stream<ConnectivityStatus> get statusStream => Stream.value(status);

  @override
  Future<ConnectivityStatus> checkConnectivity() async => status;

  @override
  Future<bool> isOnline() async => status != ConnectivityStatus.offline;

  @override
  void updateSyncStatus(ConnectivityStatus status) {
    this.status = status;
  }

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KIRANAOS Phase 06.1 — Billing Foundation Tests', () {
    late BillingLocalDataSource localDataSource;
    late BillingRemoteDataSource remoteDataSource;
    late TestConnectivityService connectivityService;
    late BillingRepository repository;

    late CreateDraftBillUseCase createDraftUseCase;
    late CalculateBillTotalsUseCase calculatorUseCase;
    late AddProductToBillUseCase addProductUseCase;
    late UpdateBillItemQuantityUseCase updateQuantityUseCase;
    late RemoveBillItemUseCase removeItemUseCase;
    late SaveDraftBillUseCase saveDraftUseCase;

    final sampleProduct1 = ProductModel(
      id: 'prod_101',
      shopId: 'shop_test_1',
      name: 'Aashirvaad Atta 5kg',
      categoryId: 'cat_groceries',
      sellingPricePaise: 24500, // ₹245.00
      mrpPaise: 26000,
      unit: 'kg',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final sampleProduct2 = ProductModel(
      id: 'prod_102',
      shopId: 'shop_test_1',
      name: 'Tata Salt 1kg',
      categoryId: 'cat_groceries',
      sellingPricePaise: 2800, // ₹28.00
      mrpPaise: 3000,
      unit: 'kg',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      localDataSource = BillingLocalDataSource();
      remoteDataSource = BillingRemoteDataSource();
      connectivityService = TestConnectivityService();
      repository = BillingRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
        connectivityService: connectivityService,
      );

      createDraftUseCase = CreateDraftBillUseCase(repository);
      calculatorUseCase = CalculateBillTotalsUseCase();
      addProductUseCase = AddProductToBillUseCase(calculatorUseCase);
      updateQuantityUseCase = UpdateBillItemQuantityUseCase(calculatorUseCase);
      removeItemUseCase = RemoveBillItemUseCase(calculatorUseCase);
      saveDraftUseCase = SaveDraftBillUseCase(repository);
    });

    test('1. Creates draft bill with unique ID and DRAFT status', () async {
      final result = await createDraftUseCase.execute(
        shopId: 'shop_test_1',
        cashierId: 'user_cashier_1',
        userRole: 'cashier',
      );

      expect(result.isSuccess, true);
      final draft = result.dataOrNull!;
      expect(draft.id.startsWith('draft_'), true);
      expect(draft.shopId, 'shop_test_1');
      expect(draft.cashierId, 'user_cashier_1');
      expect(draft.isDraft, true);
      expect(draft.items, isEmpty);
      expect(draft.totalPaise, 0);
    });

    test('2. Adds product to draft bill using price snapshot', () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_1',
        cashierId: 'user_cashier_1',
        userRole: 'owner',
      );
      final draft = draftResult.dataOrNull!;

      final updatedDraft = addProductUseCase.execute(
        bill: draft,
        product: sampleProduct1,
        quantity: 1.0,
        isTaxEnabled: false,
      );

      expect(updatedDraft.items.length, 1);
      final item = updatedDraft.items.first;
      expect(item.productId, 'prod_101');
      expect(item.productName, 'Aashirvaad Atta 5kg');
      expect(item.unitPricePaise, 24500);
      expect(item.quantity, 1.0);
      expect(updatedDraft.subtotalPaise, 24500);
      expect(updatedDraft.totalPaise, 24500);
    });

    test('3. Adding same product twice accumulates quantity', () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_1',
        cashierId: 'user_cashier_1',
        userRole: 'manager',
      );
      var draft = draftResult.dataOrNull!;

      draft = addProductUseCase.execute(
        bill: draft,
        product: sampleProduct2,
        quantity: 1.0,
        isTaxEnabled: false,
      );

      draft = addProductUseCase.execute(
        bill: draft,
        product: sampleProduct2,
        quantity: 2.0,
        isTaxEnabled: false,
      );

      expect(draft.items.length, 1);
      final item = draft.items.first;
      expect(item.quantity, 3.0);
      expect(draft.subtotalPaise, 2800 * 3);
      expect(draft.totalPaise, 8400);
    });

    test('4. Increases and decreases item quantity properly', () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_1',
        cashierId: 'user_cashier_1',
        userRole: 'cashier',
      );
      var draft = draftResult.dataOrNull!;

      draft = addProductUseCase.execute(
        bill: draft,
        product: sampleProduct1,
        quantity: 1.0,
        isTaxEnabled: false,
      );

      final itemId = draft.items.first.id;

      // Increase quantity to 5
      draft = updateQuantityUseCase.execute(
        bill: draft,
        itemId: itemId,
        newQuantity: 5.0,
        isTaxEnabled: false,
      );
      expect(draft.items.first.quantity, 5.0);
      expect(draft.subtotalPaise, 24500 * 5);

      // Decrease quantity to 2
      draft = updateQuantityUseCase.execute(
        bill: draft,
        itemId: itemId,
        newQuantity: 2.0,
        isTaxEnabled: false,
      );
      expect(draft.items.first.quantity, 2.0);
      expect(draft.subtotalPaise, 24500 * 2);
    });

    test('5. Removes item from draft bill when quantity set to 0 or removed',
        () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_1',
        cashierId: 'user_cashier_1',
        userRole: 'cashier',
      );
      var draft = draftResult.dataOrNull!;

      draft = addProductUseCase.execute(
        bill: draft,
        product: sampleProduct1,
        quantity: 1.0,
        isTaxEnabled: false,
      );
      expect(draft.items.length, 1);

      final itemId = draft.items.first.id;
      draft = removeItemUseCase.execute(
        bill: draft,
        itemId: itemId,
        isTaxEnabled: false,
      );

      expect(draft.items, isEmpty);
      expect(draft.subtotalPaise, 0);
      expect(draft.totalPaise, 0);
    });

    test(
        '6. Computes deterministic subtotal, tax, and grand total in integer paise',
        () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_1',
        cashierId: 'user_cashier_1',
        userRole: 'owner',
      );
      var draft = draftResult.dataOrNull!;

      // Add Product 1: ₹245.00 x 2 = ₹490.00 (49000 paise)
      draft = addProductUseCase.execute(
        bill: draft,
        product: sampleProduct1,
        quantity: 2.0,
        isTaxEnabled: true,
        defaultTaxPercentage: 18.0,
      );

      // Add Product 2: ₹28.00 x 1 = ₹28.00 (2800 paise)
      draft = addProductUseCase.execute(
        bill: draft,
        product: sampleProduct2,
        quantity: 1.0,
        isTaxEnabled: true,
        defaultTaxPercentage: 18.0,
      );

      // Subtotal = 49000 + 2800 = 51800 paise (₹518.00)
      expect(draft.subtotalPaise, 51800);

      // Tax (18%) = 51800 * 0.18 = 9324 paise (₹93.24)
      expect(draft.taxTotalPaise, 9324);

      // Grand Total = 51800 + 9324 = 61124 paise (₹611.24)
      expect(draft.totalPaise, 61124);
    });

    test(
        '7. Price snapshot immutability (catalog price change does not affect bill item)',
        () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_1',
        cashierId: 'user_cashier_1',
        userRole: 'cashier',
      );
      var draft = draftResult.dataOrNull!;

      draft = addProductUseCase.execute(
        bill: draft,
        product: sampleProduct1, // Price: 24500 paise
        quantity: 1.0,
        isTaxEnabled: false,
      );

      // Simulate product catalog price inflation
      final updatedCatalogProduct =
          sampleProduct1.copyWith(sellingPricePaise: 30000);

      // Existing bill item retains snapshot price (24500 paise)
      expect(draft.items.first.unitPricePaise, 24500);
      expect(draft.totalPaise, 24500);
      expect(updatedCatalogProduct.sellingPricePaise, 30000);
    });

    test(
        '8. Offline draft bill persists locally without claiming sale completion',
        () async {
      connectivityService.status = ConnectivityStatus.offline;

      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_1',
        cashierId: 'user_cashier_1',
        userRole: 'cashier',
      );
      var draft = draftResult.dataOrNull!;

      draft = addProductUseCase.execute(
        bill: draft,
        product: sampleProduct1,
        quantity: 1.0,
        isTaxEnabled: false,
      );

      final saveResult = await saveDraftUseCase.execute(draft);
      expect(saveResult.isSuccess, true);
      expect(saveResult.dataOrNull!.isDraft, true);

      final fetched = await repository.getDraftBill(draft.id);
      expect(fetched.dataOrNull, isNotNull);
      expect(fetched.dataOrNull!.id, draft.id);
      expect(fetched.dataOrNull!.status, 'draft');
    });

    test(
        '9. Restricts INVENTORY_STAFF from creating bills with PermissionDeniedFailure',
        () async {
      final result = await createDraftUseCase.execute(
        shopId: 'shop_test_1',
        cashierId: 'user_inv_1',
        userRole: 'inventory_staff',
      );

      expect(result.isError, true);
      expect(result.failureOrNull, isA<PermissionDeniedFailure>());
      expect(result.failureOrNull!.message,
          'Inventory staff members are not authorized to create bills.');
    });

    test('10. Prevents duplicate bill creation on rapid double-tap', () async {
      final result1 = await createDraftUseCase.execute(
        shopId: 'shop_test_1',
        cashierId: 'user_cashier_1',
        userRole: 'cashier',
      );

      final result2 = await createDraftUseCase.execute(
        shopId: 'shop_test_1',
        cashierId: 'user_cashier_1',
        userRole: 'cashier',
      );

      expect(result1.isSuccess, true);
      expect(result2.isError, true);
      expect(result2.failureOrNull, isA<ValidationFailure>());
      expect(result2.failureOrNull!.message,
          'Bill creation request is already processing.');
    });
  });
}
