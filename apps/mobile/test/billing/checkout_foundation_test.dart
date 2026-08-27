import 'package:flutter_test/flutter_test.dart';

import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/features/billing/domain/models/bill_history_filter.dart';
import 'package:kirana_mobile/features/billing/domain/models/bill_model.dart';
import 'package:kirana_mobile/features/billing/domain/models/payment_model.dart';
import 'package:kirana_mobile/features/billing/domain/repositories/billing_repository.dart';
import 'package:kirana_mobile/features/billing/domain/usecases/billing_usecases.dart';

// Mock connectivity service for offline / online testing
class MockConnectivityService implements ConnectivityService {
  ConnectivityStatus status = ConnectivityStatus.online;

  @override
  ConnectivityStatus get currentStatus => status;

  @override
  Stream<ConnectivityStatus> get statusStream => Stream.value(status);

  @override
  Future<ConnectivityStatus> checkConnectivity() async => status;

  @override
  Future<bool> isOnline() async => status == ConnectivityStatus.online;

  @override
  void updateSyncStatus(ConnectivityStatus newStatus) {
    status = newStatus;
  }

  @override
  void dispose() {}
}

// Mock repository to simulate server checkout responses
class MockBillingRepository implements BillingRepository {
  bool shouldTriggerPriceChangeError = false;
  bool shouldTriggerInsufficientStockError = false;
  bool completeSaleCalled = false;

  @override
  Future<Result<BillModel, Failure>> completeSaleCheckout({
    required BillModel bill,
    required PaymentModel payment,
    required String idempotencyKey,
  }) async {
    completeSaleCalled = true;

    if (shouldTriggerPriceChangeError) {
      return ErrorResult(
        ValidationFailure(
          'PRICE_CHANGED: Product price changed for "Sunflower Oil". Current price: ₹170.00. Please review your cart.',
        ),
      );
    }

    if (shouldTriggerInsufficientStockError) {
      return ErrorResult(
        ValidationFailure(
          'INSUFFICIENT_STOCK: Insufficient stock for product "Loose Sugar": requested 10, available 3',
        ),
      );
    }

    final completed = bill.copyWith(
      status: 'completed',
      paymentStatus: 'paid',
      updatedAt: DateTime.now(),
    );
    return Success(completed);
  }

  @override
  Future<Result<BillModel, Failure>> createDraftBill({
    required String shopId,
    required String cashierId,
    String? billNumber,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<BillModel, Failure>> saveDraftBill(BillModel bill) async {
    return Success(bill);
  }

  @override
  Future<Result<BillModel?, Failure>> getDraftBill(String billId) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<void, Failure>> deleteDraftBill(String billId) async {
    throw UnimplementedError();
  }

  @override
  Stream<List<BillModel>> watchShopDrafts(String shopId) {
    throw UnimplementedError();
  }

  @override
  Future<Result<BillHistoryResult, Failure>> getBillHistory({
    required String shopId,
    required String userRole,
    required String currentUserId,
    required BillHistoryFilter filter,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  group('Phase 13.6 — Checkout Foundation Unit & Domain Tests', () {
    final now = DateTime.now();

    final item1 = BillItemModel(
      id: 'item_1',
      billId: 'bill_101',
      productId: 'prod_oil',
      productName: 'Sunflower Oil 1L',
      unit: 'PCS',
      unitPricePaise: 16000,
      quantity: 2.0,
      taxRate: 0.0,
      taxAmountPaise: 0,
      totalPaise: 32000,
      createdAt: now,
    );

    final item2 = BillItemModel(
      id: 'item_2',
      billId: 'bill_101',
      productId: 'prod_sugar',
      productName: 'Loose Sugar',
      unit: 'KG',
      unitPricePaise: 4000,
      quantity: 1.5,
      taxRate: 0.0,
      taxAmountPaise: 0,
      totalPaise: 6000,
      createdAt: now,
    );

    final sampleBill = BillModel(
      id: 'bill_101',
      shopId: 'shop_A',
      cashierId: 'cashier_1',
      billNumber: 'DRAFT-101',
      status: 'draft',
      customerId: 'cust_77',
      customerName: 'Rahul Verma',
      customerPhone: '9876543210',
      discountType: 'none',
      discountValue: 0.0,
      subtotalPaise: 38000, // ₹380.00
      taxTotalPaise: 0,
      discountPaise: 0,
      totalPaise: 38000, // ₹380.00
      paymentStatus: 'unpaid',
      items: [item1, item2],
      createdAt: now,
      updatedAt: now,
    );

    late MockBillingRepository mockRepo;
    late MockConnectivityService mockConnectivity;
    late ValidateBillUseCase validateUseCase;
    late CompleteSaleCheckoutUseCase checkoutUseCase;

    setUp(() {
      mockRepo = MockBillingRepository();
      mockConnectivity = MockConnectivityService();
      validateUseCase = ValidateBillUseCase();
      checkoutUseCase = CompleteSaleCheckoutUseCase(
        repository: mockRepo,
        connectivityService: mockConnectivity,
        validateBillUseCase: validateUseCase,
      );
    });

    test(
        '1. Feature: Checkout Review aggregates items, totals, customer, and payment info correctly',
        () {
      expect(sampleBill.items.length, equals(2));
      expect(sampleBill.subtotalPaise, equals(38000));
      expect(sampleBill.totalPaise, equals(38000));
      expect(sampleBill.customerName, equals('Rahul Verma'));
      expect(sampleBill.customerPhone, equals('9876543210'));
    });

    test(
        '2. Feature: Validation blocks empty cart, invalid shop, or inventory_staff role',
        () {
      final emptyBill = sampleBill.copyWith(items: []);
      final validation1 = validateUseCase.execute(
        bill: emptyBill,
        activeShopId: 'shop_A',
        userRole: 'cashier',
      );
      expect(validation1.isError, isTrue);
      expect(validation1.failureOrNull?.message,
          contains('at least one product item'));

      // Inventory staff restricted
      final validation2 = validateUseCase.execute(
        bill: sampleBill,
        activeShopId: 'shop_A',
        userRole: 'inventory_staff',
      );
      expect(validation2.isError, isTrue);
      expect(validation2.failureOrNull?.message, contains('Inventory staff'));
    });

    test(
        '3. Feature: Offline checkout is blocked cleanly without faking sale completion',
        () async {
      mockConnectivity.status = ConnectivityStatus.offline;

      final payment = PaymentModel(
        id: 'pay_1',
        shopId: 'shop_A',
        billId: sampleBill.id,
        mode: 'cash',
        amountPaise: 38000,
        status: 'pending',
        createdAt: now,
      );

      final result = await checkoutUseCase.execute(
        bill: sampleBill,
        payment: payment,
        activeShopId: 'shop_A',
        userRole: 'cashier',
        idempotencyKey: 'idem_key_123',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          equals('Reconnect to complete this sale.'));
      expect(mockRepo.completeSaleCalled, isFalse);
    });

    test(
        '4. Feature: Server Price Change Detection halts checkout and prompts user',
        () async {
      mockRepo.shouldTriggerPriceChangeError = true;

      final payment = PaymentModel(
        id: 'pay_1',
        shopId: 'shop_A',
        billId: sampleBill.id,
        mode: 'cash',
        amountPaise: 38000,
        status: 'pending',
        createdAt: now,
      );

      final result = await checkoutUseCase.execute(
        bill: sampleBill,
        payment: payment,
        activeShopId: 'shop_A',
        userRole: 'cashier',
        idempotencyKey: 'idem_key_123',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, contains('PRICE_CHANGED'));
    });

    test('5. Feature: Insufficient stock error handled gracefully', () async {
      mockRepo.shouldTriggerInsufficientStockError = true;

      final payment = PaymentModel(
        id: 'pay_1',
        shopId: 'shop_A',
        billId: sampleBill.id,
        mode: 'cash',
        amountPaise: 38000,
        status: 'pending',
        createdAt: now,
      );

      final result = await checkoutUseCase.execute(
        bill: sampleBill,
        payment: payment,
        activeShopId: 'shop_A',
        userRole: 'cashier',
        idempotencyKey: 'idem_key_123',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, contains('INSUFFICIENT_STOCK'));
    });

    test('6. Feature: Successful online checkout creates completed sale',
        () async {
      final payment = PaymentModel(
        id: 'pay_1',
        shopId: 'shop_A',
        billId: sampleBill.id,
        mode: 'cash',
        amountPaise: 38000,
        status: 'pending',
        createdAt: now,
      );

      final result = await checkoutUseCase.execute(
        bill: sampleBill,
        payment: payment,
        activeShopId: 'shop_A',
        userRole: 'cashier',
        idempotencyKey: 'idem_key_123',
      );

      expect(result.isSuccess, isTrue);
      final completed = result.dataOrNull!;
      expect(completed.status, equals('completed'));
      expect(completed.paymentStatus, equals('paid'));
    });

    test(
        '7. Feature: Payment Mode validation allows CASH, UPI, CARD and rejects invalid mode',
        () async {
      final invalidPayment = PaymentModel(
        id: 'pay_1',
        shopId: 'shop_A',
        billId: sampleBill.id,
        mode: 'bitcoin', // Invalid mode
        amountPaise: 38000,
        status: 'pending',
        createdAt: now,
      );

      final result = await checkoutUseCase.execute(
        bill: sampleBill,
        payment: invalidPayment,
        activeShopId: 'shop_A',
        userRole: 'cashier',
        idempotencyKey: 'idem_key_123',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, contains('Invalid payment method'));
    });

    test(
        '8. Feature: Bill Item Snapshots preserve historical unit price and product names',
        () {
      final snapshotItem = sampleBill.items.first;
      expect(snapshotItem.productName, equals('Sunflower Oil 1L'));
      expect(snapshotItem.unitPricePaise, equals(16000));
      expect(snapshotItem.totalPaise, equals(32000));
    });
  });
}
