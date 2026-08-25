enum InventoryAdjustmentType {
  stockIn,
  stockOut,
  adjustment;

  String get dbReason {
    switch (this) {
      case InventoryAdjustmentType.stockIn:
        return 'purchase_inward';
      case InventoryAdjustmentType.stockOut:
        return 'adjustment';
      case InventoryAdjustmentType.adjustment:
        return 'adjustment';
    }
  }

  String get label {
    switch (this) {
      case InventoryAdjustmentType.stockIn:
        return 'STOCK IN';
      case InventoryAdjustmentType.stockOut:
        return 'STOCK OUT';
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
  final double quantityDelta;
  final double balanceAfter;
  final String reason;
  final String? referenceId;
  final String performedBy;
  final String? performedByName;
  final String? note;
  final DateTime createdAt;

  const InventoryMovementModel({
    required this.id,
    required this.shopId,
    required this.productId,
    this.productName,
    required this.quantityDelta,
    required this.balanceAfter,
    required this.reason,
    this.referenceId,
    required this.performedBy,
    this.performedByName,
    this.note,
    required this.createdAt,
  });

  bool get isPositive => quantityDelta > 0;

  InventoryAdjustmentType get type {
    if (reason == 'purchase_inward' || quantityDelta > 0) {
      return InventoryAdjustmentType.stockIn;
    } else if (reason == 'sale' ||
        (reason == 'adjustment' && quantityDelta < 0)) {
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
      'quantity_delta': quantityDelta,
      'balance_after': balanceAfter,
      'reason': reason,
      'reference_id': referenceId,
      'performed_by': performedBy,
      'performed_by_name': performedByName,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory InventoryMovementModel.fromJson(Map<String, dynamic> json) {
    return InventoryMovementModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String? ?? '',
      productId: json['product_id'] as String,
      productName: json['product_name'] as String?,
      quantityDelta: (json['quantity_delta'] as num).toDouble(),
      balanceAfter: (json['balance_after'] as num).toDouble(),
      reason: json['reason'] as String? ?? 'adjustment',
      referenceId: json['reference_id'] as String?,
      performedBy: json['performed_by'] as String? ?? 'system',
      performedByName: json['performed_by_name'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
