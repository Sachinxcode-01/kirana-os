import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../products/domain/models/product_model.dart';
import '../../../staff/domain/models/staff_member_model.dart';
import '../models/bill_model.dart';
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
    // 1. RBAC authorization check
    final role = StaffRoleExtension.fromString(userRole);
    if (role == StaffRole.inventoryStaff) {
      return const ErrorResult(
        PermissionDeniedFailure(
          'Inventory staff members are not authorized to create bills.',
        ),
      );
    }

    // 2. Double-tap submission prevention (ignore calls within 500ms)
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
    int subtotal = 0;
    int taxTotal = 0;

    final updatedItems = bill.items.map((item) {
      final itemSubtotal = (item.unitPricePaise * item.quantity).round();
      final effectiveTaxRate = isTaxEnabled ? item.taxRate : 0.0;

      final itemTax = effectiveTaxRate > 0
          ? ((itemSubtotal * (effectiveTaxRate / 100.0))).round()
          : 0;

      final itemTotal = itemSubtotal + itemTax;

      subtotal += itemSubtotal;
      taxTotal += itemTax;

      return item.copyWith(
        taxRate: effectiveTaxRate,
        taxAmountPaise: itemTax,
        totalPaise: itemTotal,
      );
    }).toList();

    final grandTotal =
        (subtotal + taxTotal - bill.discountPaise).clamp(0, 999999999);

    return bill.copyWith(
      items: updatedItems,
      subtotalPaise: subtotal,
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
