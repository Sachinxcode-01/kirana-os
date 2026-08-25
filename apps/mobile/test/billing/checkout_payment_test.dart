import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/features/billing/data/datasources/billing_local_data_source.dart';
import 'package:kirana_mobile/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:kirana_mobile/features/billing/data/repositories/billing_repository_impl.dart';
import 'package:kirana_mobile/features/billing/domain/models/payment_model.dart';
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

  group('KIRANAOS Phase 06.3 — Checkout + Payment Foundation Tests', () {
    late BillingLocalDataSource localDataSource;
    late BillingRemoteDataSource remoteDataSource;
    late TestConnectivityService connectivityService;
    late BillingRepository repository;

    late CreateDraftBillUseCase createDraftUseCase;
    late CalculateBillTotalsUseCase calculatorUseCase;
    late AddProductToBillUseCase addProductUseCase;
    late ValidateBillUseCase validateBillUseCase;
    late CompleteSaleCheckoutUseCase completeCheckoutUseCase;

    final sampleProduct1 = ProductModel(
      id: 'prod_301',
      shopId: 'shop_test_3',
      name: 'Aashirvaad Atta 5kg',
      categoryId: 'cat_staples',
      sellingPricePaise: 25000, // ₹250.00
      mrpPaise: 27000,
      unit: 'packet',
      currentStock: 10.0,
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
      validateBillUseCase = ValidateBillUseCase();
      completeCheckoutUseCase = CompleteSaleCheckoutUseCase(
        repository: repository,
        connectivityService: connectivityService,
        validateBillUseCase: validateBillUseCase,
      );
    });

    test('1. Cash payment checkout completes bill atomically', () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_3',
        cashierId: 'user_cashier_1',
        userRole: 'cashier',
      );
      var draft = draftResult.dataOrNull!;

      draft = addProductUseCase.execute(
        bill: draft,
        product: sampleProduct1,
        quantity: 2.0, // Total = ₹500.00 (50000 paise)
        isTaxEnabled: false,
      );

      final payment = PaymentModel(
        id: 'pay_101',
        shopId: 'shop_test_3',
        billId: draft.id,
        mode: 'cash',
        amountPaise: draft.totalPaise,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final checkoutResult = await completeCheckoutUseCase.execute(
        bill: draft,
        payment: payment,
        activeShopId: 'shop_test_3',
        userRole: 'cashier',
        idempotencyKey: 'idempotency_test_101',
      );

      expect(checkoutResult.isSuccess, true);
      final completed = checkoutResult.dataOrNull!;
      expect(completed.isCompleted, true);
      expect(completed.paymentStatus, 'paid');
    });

    test('2. UPI payment checkout completes bill atomically', () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_3',
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

      final payment = PaymentModel(
        id: 'pay_102',
        shopId: 'shop_test_3',
        billId: draft.id,
        mode: 'upi_qr',
        amountPaise: draft.totalPaise,
        status: 'pending',
        referenceNumber: 'UPI_REF_9876543210',
        createdAt: DateTime.now(),
      );

      final checkoutResult = await completeCheckoutUseCase.execute(
        bill: draft,
        payment: payment,
        activeShopId: 'shop_test_3',
        userRole: 'cashier',
        idempotencyKey: 'idempotency_test_102',
      );

      expect(checkoutResult.isSuccess, true);
      expect(checkoutResult.dataOrNull!.isCompleted, true);
    });

    test('3. Card payment checkout completes bill atomically', () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_3',
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

      final payment = PaymentModel(
        id: 'pay_103',
        shopId: 'shop_test_3',
        billId: draft.id,
        mode: 'card',
        amountPaise: draft.totalPaise,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final checkoutResult = await completeCheckoutUseCase.execute(
        bill: draft,
        payment: payment,
        activeShopId: 'shop_test_3',
        userRole: 'cashier',
        idempotencyKey: 'idempotency_test_103',
      );

      expect(checkoutResult.isSuccess, true);
      expect(checkoutResult.dataOrNull!.isCompleted, true);
    });

    test(
        '4. BLOCKS OFFLINE CHECKOUT: returns "Reconnect to complete this sale."',
        () async {
      connectivityService.status = ConnectivityStatus.offline;

      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_3',
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

      final payment = PaymentModel(
        id: 'pay_offline_1',
        shopId: 'shop_test_3',
        billId: draft.id,
        mode: 'cash',
        amountPaise: draft.totalPaise,
        createdAt: DateTime.now(),
      );

      final checkoutResult = await completeCheckoutUseCase.execute(
        bill: draft,
        payment: payment,
        activeShopId: 'shop_test_3',
        userRole: 'cashier',
        idempotencyKey: 'idempotency_offline_1',
      );

      expect(checkoutResult.isError, true);
      expect(checkoutResult.failureOrNull, isA<NetworkFailure>());
      expect(checkoutResult.failureOrNull!.message,
          'Reconnect to complete this sale.');
    });

    test('5. Rejects empty bill or zero quantity item checkout', () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_3',
        cashierId: 'user_cashier_1',
        userRole: 'cashier',
      );
      final emptyDraft = draftResult.dataOrNull!;

      final payment = PaymentModel(
        id: 'pay_empty_1',
        shopId: 'shop_test_3',
        billId: emptyDraft.id,
        mode: 'cash',
        amountPaise: 0,
        createdAt: DateTime.now(),
      );

      final checkoutResult = await completeCheckoutUseCase.execute(
        bill: emptyDraft,
        payment: payment,
        activeShopId: 'shop_test_3',
        userRole: 'cashier',
        idempotencyKey: 'idempotency_empty_1',
      );

      expect(checkoutResult.isError, true);
      expect(checkoutResult.failureOrNull, isA<ValidationFailure>());
      expect(checkoutResult.failureOrNull!.message,
          'Bill must contain at least one product item.');
    });

    test('6. Restricts INVENTORY_STAFF from performing checkout', () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_3',
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

      final payment = PaymentModel(
        id: 'pay_perm_1',
        shopId: 'shop_test_3',
        billId: draft.id,
        mode: 'cash',
        amountPaise: draft.totalPaise,
        createdAt: DateTime.now(),
      );

      final checkoutResult = await completeCheckoutUseCase.execute(
        bill: draft,
        payment: payment,
        activeShopId: 'shop_test_3',
        userRole: 'inventory_staff',
        idempotencyKey: 'idempotency_perm_1',
      );

      expect(checkoutResult.isError, true);
      expect(checkoutResult.failureOrNull, isA<PermissionDeniedFailure>());
    });

    test('7. Prevents duplicate submission on rapid double tap', () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_3',
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

      final payment = PaymentModel(
        id: 'pay_double_1',
        shopId: 'shop_test_3',
        billId: draft.id,
        mode: 'cash',
        amountPaise: draft.totalPaise,
        createdAt: DateTime.now(),
      );

      // Execute rapid consecutive checkouts
      final future1 = completeCheckoutUseCase.execute(
        bill: draft,
        payment: payment,
        activeShopId: 'shop_test_3',
        userRole: 'cashier',
        idempotencyKey: 'idempotency_double_1',
      );

      final future2 = completeCheckoutUseCase.execute(
        bill: draft,
        payment: payment,
        activeShopId: 'shop_test_3',
        userRole: 'cashier',
        idempotencyKey: 'idempotency_double_1',
      );

      final results = await Future.wait([future1, future2]);

      final hasSuccess = results.any((r) => r.isSuccess);
      final hasDuplicateError = results.any((r) =>
          r.isError &&
          r.failureOrNull!.message ==
              'Checkout transaction is already processing.');

      expect(hasSuccess, true);
      expect(hasDuplicateError, true);
    });

    test(
        '8. Idempotency protection: retrying completed bill returns existing result',
        () async {
      final draftResult = await createDraftUseCase.execute(
        shopId: 'shop_test_3',
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

      final payment = PaymentModel(
        id: 'pay_idemp_1',
        shopId: 'shop_test_3',
        billId: draft.id,
        mode: 'cash',
        amountPaise: draft.totalPaise,
        createdAt: DateTime.now(),
      );

      final firstRes = await completeCheckoutUseCase.execute(
        bill: draft,
        payment: payment,
        activeShopId: 'shop_test_3',
        userRole: 'cashier',
        idempotencyKey: 'idempotency_key_repeat',
      );

      final completedBill = firstRes.dataOrNull!;

      // Wait > 500ms to bypass local throttle
      await Future.delayed(const Duration(milliseconds: 600));

      final secondRes = await completeCheckoutUseCase.execute(
        bill: completedBill,
        payment: payment,
        activeShopId: 'shop_test_3',
        userRole: 'cashier',
        idempotencyKey: 'idempotency_key_repeat',
      );

      expect(secondRes.isSuccess, true);
      expect(secondRes.dataOrNull!.id, completedBill.id);
      expect(secondRes.dataOrNull!.isCompleted, true);
    });
  });
}
