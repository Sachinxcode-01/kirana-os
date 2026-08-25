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

  group('KIRANAOS Phase 06.2 — Bill Customer & Item Controls Tests', () {
    late BillingLocalDataSource localDataSource;
    late BillingRemoteDataSource remoteDataSource;
    late TestConnectivityService connectivityService;
    late BillingRepository repository;

    late CreateDraftBillUseCase createDraftUseCase;
    late CalculateBillTotalsUseCase calculatorUseCase;
    late AddProductToBillUseCase addProductUseCase;
    late UpdateBillItemQuantityUseCase updateQuantityUseCase;
    late RemoveBillItemUseCase removeItemUseCase;
    late ApplyBillDiscountUseCase applyDiscountUseCase;
    late AttachCustomerToBillUseCase attachCustomerUseCase;
    late RemoveCustomerFromBillUseCase removeCustomerUseCase;
    late ValidateBillUseCase validateBillUseCase;
    late SaveDraftBillUseCase saveDraftUseCase;

    final sampleProduct1 = ProductModel(
      id: 'prod_201',
      shopId: 'shop_test_2',
      name: 'Fortune Sunlite Oil 1L',
      categoryId: 'cat_groceries',
      sellingPricePaise: 14000, // ₹140.00
      mrpPaise: 15000,
      unit: 'liter',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final sampleProduct2 = ProductModel(
      id: 'prod_202',
      shopId: 'shop_test_2',
      name: 'Surf Excel 1kg',
      categoryId: 'cat_groceries',
      sellingPricePaise: 12000, // ₹120.00
      mrpPaise: 13000,
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
      applyDiscountUseCase = ApplyBillDiscountUseCase(calculatorUseCase);
      attachCustomerUseCase = AttachCustomerToBillUseCase();
      removeCustomerUseCase = RemoveCustomerFromBillUseCase();
      validateBillUseCase = ValidateBillUseCase();
      saveDraftUseCase = SaveDraftBillUseCase(repository);
    });

    test('1. Allows exact quantity editing for loose/packaged items', () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_2',
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

      // Set exact loose quantity 2.5 L
      draft = updateQuantityUseCase.execute(
        bill: draft,
        itemId: itemId,
        newQuantity: 2.5,
        isTaxEnabled: false,
      );

      expect(draft.items.first.quantity, 2.5);
      expect(
          draft.subtotalPaise, (14000 * 2.5).round()); // 35000 paise (₹350.00)

      // Test item removal
      draft = removeItemUseCase.execute(
        bill: draft,
        itemId: itemId,
        isTaxEnabled: false,
      );
      expect(draft.items, isEmpty);
      expect(draft.subtotalPaise, 0);
    });

    test('2. Attaches customer and detaches customer from bill', () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_2',
        cashierId: 'user_cashier_1',
        userRole: 'cashier',
      );
      var draft = draftResult.dataOrNull!;

      expect(draft.hasCustomer, false);

      // Attach Customer
      draft = attachCustomerUseCase.execute(
        bill: draft,
        customerId: 'cust_101',
        customerName: 'Ramesh Kumar',
        customerPhone: '9876543210',
      );

      expect(draft.hasCustomer, true);
      expect(draft.customerId, 'cust_101');
      expect(draft.customerName, 'Ramesh Kumar');
      expect(draft.customerPhone, '9876543210');

      // Detach Customer
      draft = removeCustomerUseCase.execute(draft);
      expect(draft.hasCustomer, false);
      expect(draft.customerId, isNull);
    });

    test('3. Applies valid percentage discount (0% to 100%)', () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_2',
        cashierId: 'user_cashier_1',
        userRole: 'cashier',
      );
      var draft = draftResult.dataOrNull!;

      // Add Oil (₹140.00) + Surf (₹120.00) = Subtotal ₹260.00 (26000 paise)
      draft = addProductUseCase.execute(
        bill: draft,
        product: sampleProduct1,
        quantity: 1.0,
        isTaxEnabled: false,
      );
      draft = addProductUseCase.execute(
        bill: draft,
        product: sampleProduct2,
        quantity: 1.0,
        isTaxEnabled: false,
      );

      expect(draft.subtotalPaise, 26000);

      // Apply 10% percentage discount
      final discountResult = applyDiscountUseCase.execute(
        bill: draft,
        discountType: 'percentage',
        discountValue: 10.0,
        isTaxEnabled: false,
      );

      expect(discountResult.isSuccess, true);
      final discountedDraft = discountResult.dataOrNull!;
      expect(discountedDraft.discountPaise, 2600); // 10% of 26000 = 2600 paise
      expect(discountedDraft.totalPaise, 23400); // 26000 - 2600 = 23400 paise
    });

    test('4. Applies valid fixed amount discount', () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_2',
        cashierId: 'user_cashier_1',
        userRole: 'cashier',
      );
      var draft = draftResult.dataOrNull!;

      draft = addProductUseCase.execute(
        bill: draft,
        product: sampleProduct1,
        quantity: 2.0, // Subtotal: 28000 paise
        isTaxEnabled: false,
      );

      // Apply ₹50.00 (5000 paise) fixed discount
      final discountResult = applyDiscountUseCase.execute(
        bill: draft,
        discountType: 'fixed',
        discountValue: 5000.0,
        isTaxEnabled: false,
      );

      expect(discountResult.isSuccess, true);
      final discountedDraft = discountResult.dataOrNull!;
      expect(discountedDraft.discountPaise, 5000);
      expect(discountedDraft.totalPaise, 23000); // 28000 - 5000 = 23000
    });

    test('5. Rejects invalid discounts (negative, >100%, >subtotal)', () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_2',
        cashierId: 'user_cashier_1',
        userRole: 'cashier',
      );
      var draft = draftResult.dataOrNull!;

      draft = addProductUseCase.execute(
        bill: draft,
        product: sampleProduct1,
        quantity: 1.0, // Subtotal: 14000 paise
        isTaxEnabled: false,
      );

      // 1. Negative percentage
      final res1 = applyDiscountUseCase.execute(
        bill: draft,
        discountType: 'percentage',
        discountValue: -5.0,
        isTaxEnabled: false,
      );
      expect(res1.isError, true);
      expect(res1.failureOrNull, isA<ValidationFailure>());

      // 2. Percentage > 100%
      final res2 = applyDiscountUseCase.execute(
        bill: draft,
        discountType: 'percentage',
        discountValue: 120.0,
        isTaxEnabled: false,
      );
      expect(res2.isError, true);

      // 3. Fixed discount > Subtotal
      final res3 = applyDiscountUseCase.execute(
        bill: draft,
        discountType: 'fixed',
        discountValue: 20000.0, // 20000 > 14000
        isTaxEnabled: false,
      );
      expect(res3.isError, true);
      expect(res3.failureOrNull!.message,
          'Discount amount cannot exceed the bill subtotal.');
    });

    test(
        '6. Verifies deterministic calculation order: Subtotal -> Discount -> Tax -> Grand Total',
        () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_2',
        cashierId: 'user_cashier_1',
        userRole: 'owner',
      );
      var draft = draftResult.dataOrNull!;

      // Add Product: ₹100.00 (10000 paise), Tax 18%
      final product100 = sampleProduct1.copyWith(sellingPricePaise: 10000);
      draft = addProductUseCase.execute(
        bill: draft,
        product: product100,
        quantity: 2.0, // Subtotal = 20000 paise (₹200.00)
        isTaxEnabled: true,
        defaultTaxPercentage: 18.0,
      );

      // Apply ₹20.00 (2000 paise) fixed discount
      final discountResult = applyDiscountUseCase.execute(
        bill: draft,
        discountType: 'fixed',
        discountValue: 2000.0,
        isTaxEnabled: true,
        defaultTaxPercentage: 18.0,
      );

      final resultBill = discountResult.dataOrNull!;
      expect(resultBill.subtotalPaise, 20000);
      expect(resultBill.discountPaise, 2000);
      expect(resultBill.taxTotalPaise, 3600); // 18% of 20000 = 3600
      // Grand Total = 20000 - 2000 + 3600 = 21600 paise
      expect(resultBill.totalPaise, 21600);
    });

    test('7. Bill validation checks: empty items, shop ownership, user role',
        () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_2',
        cashierId: 'user_cashier_1',
        userRole: 'cashier',
      );
      var draft = draftResult.dataOrNull!;

      // 1. Validate empty items fails
      final val1 = validateBillUseCase.execute(
        bill: draft,
        activeShopId: 'shop_test_2',
        userRole: 'cashier',
      );
      expect(val1.isError, true);
      expect(val1.failureOrNull!.message,
          'Bill must contain at least one product item.');

      // Add product
      draft = addProductUseCase.execute(
        bill: draft,
        product: sampleProduct1,
        quantity: 1.0,
        isTaxEnabled: false,
      );

      // 2. Validate correct bill passes
      final val2 = validateBillUseCase.execute(
        bill: draft,
        activeShopId: 'shop_test_2',
        userRole: 'cashier',
      );
      expect(val2.isSuccess, true);

      // 3. Validate wrong shop ID fails
      final val3 = validateBillUseCase.execute(
        bill: draft,
        activeShopId: 'shop_other_999',
        userRole: 'cashier',
      );
      expect(val3.isError, true);
      expect(val3.failureOrNull, isA<PermissionDeniedFailure>());
    });

    test('8. Offline draft persists with attached customer and discount',
        () async {
      connectivityService.status = ConnectivityStatus.offline;

      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_2',
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

      draft = attachCustomerUseCase.execute(
        bill: draft,
        customerId: 'cust_202',
        customerName: 'Suresh Raina',
        customerPhone: '9123456789',
      );

      final discountRes = applyDiscountUseCase.execute(
        bill: draft,
        discountType: 'percentage',
        discountValue: 5.0,
        isTaxEnabled: false,
      );
      draft = discountRes.dataOrNull!;

      final saveResult = await saveDraftUseCase.execute(draft);
      expect(saveResult.isSuccess, true);

      final fetched = await repository.getDraftBill(draft.id);
      expect(fetched.dataOrNull, isNotNull);
      expect(fetched.dataOrNull!.customerName, 'Suresh Raina');
      expect(fetched.dataOrNull!.discountType, 'percentage');
      expect(fetched.dataOrNull!.discountValue, 5.0);
    });
  });
}
