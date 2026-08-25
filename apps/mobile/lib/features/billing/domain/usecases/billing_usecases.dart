import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/connectivity_status.dart';
import '../../../products/domain/models/product_model.dart';
import '../../../staff/domain/models/staff_member_model.dart';
import '../models/bill_model.dart';
import '../models/payment_model.dart';
import '../repositories/billing_repository.dart';

class CreateDraftBillUseCase {
  final BillingRepository _repository;
  DateTime? _lastCreationTime;

  CreateDraftBillUseCase(this._repository);

  Future<Result<BillModel, Failure>> execute({
    required String shopId,
    required String cashierId,
    required String userRole,
    String? billNumber,
  }) async {
    final role = StaffRoleExtension.fromString(userRole);
    if (role == StaffRole.inventoryStaff) {
      return const ErrorResult(
        PermissionDeniedFailure(
          'Inventory staff members are not authorized to create bills.',
        ),
      );
    }

    final now = DateTime.now();
    if (_lastCreationTime != null &&
        now.difference(_lastCreationTime!).inMilliseconds < 500) {
      return const ErrorResult(
        ValidationFailure('Bill creation request is already processing.'),
      );
    }
    _lastCreationTime = now;

    return _repository.createDraftBill(
      shopId: shopId,
      cashierId: cashierId,
      billNumber: billNumber,
    );
  }
}

class CalculateBillTotalsUseCase {
  BillModel execute({
    required BillModel bill,
    required bool isTaxEnabled,
    double defaultTaxPercentage = 0.0,
  }) {
    // 1. Calculate raw Subtotal from items
    int subtotal = 0;
    for (final item in bill.items) {
      subtotal += (item.unitPricePaise * item.quantity).round();
    }

    // 2. Compute Discount in Paise from Subtotal
    int discountPaise = 0;
    if (bill.discountType == 'percentage') {
      final cappedValue = bill.discountValue.clamp(0.0, 100.0);
      discountPaise =
          ((subtotal * (cappedValue / 100.0))).round().clamp(0, subtotal);
    } else if (bill.discountType == 'fixed') {
      discountPaise = bill.discountValue.toInt().clamp(0, subtotal);
    }

    // 3. Compute Tax in Paise
    int taxTotal = 0;
    final updatedItems = bill.items.map((item) {
      final itemSubtotal = (item.unitPricePaise * item.quantity).round();
      final effectiveTaxRate = isTaxEnabled ? item.taxRate : 0.0;

      final itemTax = effectiveTaxRate > 0
          ? ((itemSubtotal * (effectiveTaxRate / 100.0))).round()
          : 0;

      final itemTotal = itemSubtotal + itemTax;

      taxTotal += itemTax;

      return item.copyWith(
        taxRate: effectiveTaxRate,
        taxAmountPaise: itemTax,
        totalPaise: itemTotal,
      );
    }).toList();

    // 4. Calculate Grand Total: Subtotal - Discount + Tax
    final grandTotal =
        (subtotal - discountPaise + taxTotal).clamp(0, 999999999);

    return bill.copyWith(
      items: updatedItems,
      subtotalPaise: subtotal,
      discountPaise: discountPaise,
      taxTotalPaise: taxTotal,
      totalPaise: grandTotal,
      updatedAt: DateTime.now(),
    );
  }
}

class AddProductToBillUseCase {
  final CalculateBillTotalsUseCase _calculator;

  AddProductToBillUseCase(this._calculator);

  BillModel execute({
    required BillModel bill,
    required ProductModel product,
    double quantity = 1.0,
    required bool isTaxEnabled,
    double defaultTaxPercentage = 0.0,
  }) {
    if (quantity <= 0) return bill;

    final existingIndex =
        bill.items.indexWhere((i) => i.productId == product.id);

    final taxRateSnapshot = isTaxEnabled ? defaultTaxPercentage : 0.0;
    final now = DateTime.now();

    List<BillItemModel> updatedItems;

    if (existingIndex >= 0) {
      final existing = bill.items[existingIndex];
      final newQty = existing.quantity + quantity;
      final itemSubtotal = (existing.unitPricePaise * newQty).round();
      final itemTax = existing.taxRate > 0
          ? ((itemSubtotal * (existing.taxRate / 100.0))).round()
          : 0;

      final updatedItem = existing.copyWith(
        quantity: newQty,
        taxAmountPaise: itemTax,
        totalPaise: itemSubtotal + itemTax,
      );

      updatedItems = List.from(bill.items)..[existingIndex] = updatedItem;
    } else {
      final itemId = 'item_${now.millisecondsSinceEpoch}_${product.id}';
      final itemSubtotal = (product.sellingPricePaise * quantity).round();
      final itemTax = taxRateSnapshot > 0
          ? ((itemSubtotal * (taxRateSnapshot / 100.0))).round()
          : 0;

      final newItem = BillItemModel(
        id: itemId,
        billId: bill.id,
        productId: product.id,
        productName: product.name,
        unit: product.unit,
        unitPricePaise: product.sellingPricePaise,
        quantity: quantity,
        taxRate: taxRateSnapshot,
        taxAmountPaise: itemTax,
        totalPaise: itemSubtotal + itemTax,
        createdAt: now,
      );

      updatedItems = [...bill.items, newItem];
    }

    final billWithItems = bill.copyWith(items: updatedItems);
    return _calculator.execute(
      bill: billWithItems,
      isTaxEnabled: isTaxEnabled,
      defaultTaxPercentage: defaultTaxPercentage,
    );
  }
}

class UpdateBillItemQuantityUseCase {
  final CalculateBillTotalsUseCase _calculator;

  UpdateBillItemQuantityUseCase(this._calculator);

  BillModel execute({
    required BillModel bill,
    required String itemId,
    required double newQuantity,
    required bool isTaxEnabled,
    double defaultTaxPercentage = 0.0,
  }) {
    if (newQuantity <= 0) {
      final updatedItems = bill.items.where((i) => i.id != itemId).toList();
      return _calculator.execute(
        bill: bill.copyWith(items: updatedItems),
        isTaxEnabled: isTaxEnabled,
        defaultTaxPercentage: defaultTaxPercentage,
      );
    }

    final updatedItems = bill.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    return _calculator.execute(
      bill: bill.copyWith(items: updatedItems),
      isTaxEnabled: isTaxEnabled,
      defaultTaxPercentage: defaultTaxPercentage,
    );
  }
}

class RemoveBillItemUseCase {
  final CalculateBillTotalsUseCase _calculator;

  RemoveBillItemUseCase(this._calculator);

  BillModel execute({
    required BillModel bill,
    required String itemId,
    required bool isTaxEnabled,
    double defaultTaxPercentage = 0.0,
  }) {
    final updatedItems = bill.items.where((i) => i.id != itemId).toList();
    return _calculator.execute(
      bill: bill.copyWith(items: updatedItems),
      isTaxEnabled: isTaxEnabled,
      defaultTaxPercentage: defaultTaxPercentage,
    );
  }
}

class ApplyBillDiscountUseCase {
  final CalculateBillTotalsUseCase _calculator;

  ApplyBillDiscountUseCase(this._calculator);

  Result<BillModel, Failure> execute({
    required BillModel bill,
    required String discountType, // 'none', 'percentage', 'fixed'
    required double discountValue,
    required bool isTaxEnabled,
    double defaultTaxPercentage = 0.0,
  }) {
    if (discountType == 'percentage') {
      if (discountValue < 0.0 || discountValue > 100.0) {
        return const ErrorResult(
          ValidationFailure('Percentage discount must be between 0% and 100%.'),
        );
      }
    } else if (discountType == 'fixed') {
      if (discountValue < 0.0) {
        return const ErrorResult(
          ValidationFailure('Discount amount cannot be negative.'),
        );
      }
      if (discountValue > bill.subtotalPaise) {
        return const ErrorResult(
          ValidationFailure('Discount amount cannot exceed the bill subtotal.'),
        );
      }
    } else if (discountType != 'none') {
      return const ErrorResult(
        ValidationFailure('Invalid discount type specified.'),
      );
    }

    final updatedBill = bill.copyWith(
      discountType: discountType,
      discountValue: discountValue,
    );

    final calculated = _calculator.execute(
      bill: updatedBill,
      isTaxEnabled: isTaxEnabled,
      defaultTaxPercentage: defaultTaxPercentage,
    );

    return Success(calculated);
  }
}

class AttachCustomerToBillUseCase {
  BillModel execute({
    required BillModel bill,
    required String customerId,
    required String customerName,
    required String customerPhone,
  }) {
    return bill.copyWith(
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      updatedAt: DateTime.now(),
    );
  }
}

class RemoveCustomerFromBillUseCase {
  BillModel execute(BillModel bill) {
    return bill.copyWith(
      clearCustomer: true,
      updatedAt: DateTime.now(),
    );
  }
}

class ValidateBillUseCase {
  Result<void, Failure> execute({
    required BillModel bill,
    required String activeShopId,
    required String userRole,
  }) {
    final role = StaffRoleExtension.fromString(userRole);
    if (role == StaffRole.inventoryStaff) {
      return const ErrorResult(
        PermissionDeniedFailure(
          'Inventory staff members are not authorized to process bills.',
        ),
      );
    }

    if (bill.shopId != activeShopId) {
      return const ErrorResult(
        PermissionDeniedFailure(
            'Cannot modify bill belonging to another shop.'),
      );
    }

    if (bill.items.isEmpty) {
      return const ErrorResult(
        ValidationFailure('Bill must contain at least one product item.'),
      );
    }

    for (final item in bill.items) {
      if (item.quantity <= 0) {
        return ErrorResult(
          ValidationFailure(
              'Invalid quantity for product "${item.productName}".'),
        );
      }
      if (item.unitPricePaise < 0) {
        return ErrorResult(
          ValidationFailure('Invalid price for product "${item.productName}".'),
        );
      }
    }

    if (bill.discountPaise < 0 || bill.discountPaise > bill.subtotalPaise) {
      return const ErrorResult(
        ValidationFailure('Invalid discount applied to bill.'),
      );
    }

    return const Success(null);
  }
}

class SaveDraftBillUseCase {
  final BillingRepository _repository;

  SaveDraftBillUseCase(this._repository);

  Future<Result<BillModel, Failure>> execute(BillModel bill) {
    if (bill.id.trim().isEmpty) {
      return Future.value(
        const ErrorResult(ValidationFailure('Invalid bill ID.')),
      );
    }
    return _repository.saveDraftBill(bill);
  }
}

class CompleteSaleCheckoutUseCase {
  final BillingRepository _repository;
  final ConnectivityService _connectivityService;
  final ValidateBillUseCase _validateBillUseCase;
  DateTime? _lastCheckoutTime;

  CompleteSaleCheckoutUseCase({
    required BillingRepository repository,
    required ConnectivityService connectivityService,
    required ValidateBillUseCase validateBillUseCase,
  })  : _repository = repository,
        _connectivityService = connectivityService,
        _validateBillUseCase = validateBillUseCase;

  Future<Result<BillModel, Failure>> execute({
    required BillModel bill,
    required PaymentModel payment,
    required String activeShopId,
    required String userRole,
    required String idempotencyKey,
  }) async {
    // 1. OFFLINE CHECKOUT BLOCKED
    if (_connectivityService.currentStatus == ConnectivityStatus.offline) {
      return const ErrorResult(
        NetworkFailure('Reconnect to complete this sale.'),
      );
    }

    // 2. Validate Bill & RBAC Permissions
    final validation = _validateBillUseCase.execute(
      bill: bill,
      activeShopId: activeShopId,
      userRole: userRole,
    );
    if (validation.isError) {
      return ErrorResult(validation.failureOrNull!);
    }

    // 3. Double-tap duplicate submission prevention
    final now = DateTime.now();
    if (_lastCheckoutTime != null &&
        now.difference(_lastCheckoutTime!).inMilliseconds < 500) {
      return const ErrorResult(
        ValidationFailure('Checkout transaction is already processing.'),
      );
    }
    _lastCheckoutTime = now;

    return _repository.completeSaleCheckout(
      bill: bill,
      payment: payment,
      idempotencyKey: idempotencyKey,
    );
  }
}
