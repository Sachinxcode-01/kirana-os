enum InventoryAdjustmentType {
  stockIn,
  stockOut,
  adjustment;

  String get dbReason {
    switch (this) {
      case InventoryAdjustmentType.stockIn:
        return 'purchase_inward';
      case InventoryAdjustmentType.stockOut:
        return 'stock_adjustment';
      case InventoryAdjustmentType.adjustment:
        return 'stock_adjustment';
    }
  }

  String get label {
    switch (this) {
      case InventoryAdjustmentType.stockIn:
        return 'INCREASE';
      case InventoryAdjustmentType.stockOut:
        return 'DECREASE';
      case InventoryAdjustmentType.adjustment:
        return 'ADJUSTMENT';
    }
  }
}

class InventoryMovementModel {
  final String id;
  final String shopId;
  final String productId;
  final String? productName;
  final double? previousQuantity;
  final double quantityDelta;
  final double balanceAfter;
  final String reason;
  final String? adjustmentReason;
  final String? referenceId;
  final String performedBy;
  final String? performedByName;
  final String? note;
  final String? idempotencyKey;
  final DateTime createdAt;

  const InventoryMovementModel({
    required this.id,
    required this.shopId,
    required this.productId,
    this.productName,
    this.previousQuantity,
    required this.quantityDelta,
    required this.balanceAfter,
    required this.reason,
    this.adjustmentReason,
    this.referenceId,
    required this.performedBy,
    this.performedByName,
    this.note,
    this.idempotencyKey,
    required this.createdAt,
  });

  bool get isPositive => quantityDelta > 0;

  double get computedPreviousQuantity =>
      previousQuantity ?? (balanceAfter - quantityDelta);

  String get displayReason => adjustmentReason ?? reason;

  InventoryAdjustmentType get type {
    if (reason == 'purchase_inward' || quantityDelta > 0) {
      return InventoryAdjustmentType.stockIn;
    } else if (reason == 'sale' || quantityDelta < 0) {
      return InventoryAdjustmentType.stockOut;
    }
    return InventoryAdjustmentType.adjustment;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'product_id': productId,
      'product_name': productName,
      'previous_quantity': previousQuantity ?? computedPreviousQuantity,
      'quantity_delta': quantityDelta,
      'balance_after': balanceAfter,
      'reason': reason,
      'adjustment_reason': adjustmentReason,
      'reference_id': referenceId,
      'performed_by': performedBy,
      'performed_by_name': performedByName,
      'note': note,
      'idempotency_key': idempotencyKey,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory InventoryMovementModel.fromJson(Map<String, dynamic> json) {
    final delta = (json['quantity_delta'] as num).toDouble();
    final balance = (json['balance_after'] as num).toDouble();
    final prev = json['previous_quantity'] != null
        ? (json['previous_quantity'] as num).toDouble()
        : json['previous_stock'] != null
            ? (json['previous_stock'] as num).toDouble()
            : balance - delta;

    return InventoryMovementModel(
      id: json['id'] as String? ?? json['movement_id'] as String? ?? '',
      shopId: json['shop_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String?,
      previousQuantity: prev,
      quantityDelta: delta,
      balanceAfter: balance,
      reason: json['reason'] as String? ?? 'stock_adjustment',
      adjustmentReason:
          json['adjustment_reason'] as String? ?? json['notes'] as String?,
      referenceId: json['reference_id'] as String?,
      performedBy: json['performed_by'] as String? ?? 'system',
      performedByName: json['performed_by_name'] as String?,
      note: json['notes'] as String? ?? json['note'] as String?,
      idempotencyKey: json['idempotency_key'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
