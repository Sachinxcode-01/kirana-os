class PurchaseItemModel {
  final String id;
  final String purchaseId;
  final String productId;
  final String productName;
  final double quantity;
  final int purchasePricePaise;
  final double taxRate;
  final int totalPaise;
  final DateTime createdAt;

  const PurchaseItemModel({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.purchasePricePaise,
    this.taxRate = 0.0,
    required this.totalPaise,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'purchase_id': purchaseId,
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'purchase_price_paise': purchasePricePaise,
        'tax_rate': taxRate,
        'total_paise': totalPaise,
        'created_at': createdAt.toIso8601String(),
      };

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseItemModel(
      id: json['id'] as String,
      purchaseId: json['purchase_id'] as String,
      productId: json['product_id'] as String,
      productName: (json['product_name'] as String?) ?? 'Product',
      quantity: (json['quantity'] as num).toDouble(),
      purchasePricePaise: (json['purchase_price_paise'] as num).toInt(),
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      totalPaise: (json['total_paise'] as num).toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class PurchaseModel {
  final String id;
  final String shopId;
  final String? supplierId;
  final String? supplierNameSnapshot;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final int subtotalPaise;
  final int taxTotalPaise;
  final int totalPaise;
  final String status;
  final List<PurchaseItemModel> items;
  final DateTime createdAt;

  const PurchaseModel({
    required this.id,
    required this.shopId,
    this.supplierId,
    this.supplierNameSnapshot,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.subtotalPaise,
    required this.taxTotalPaise,
    required this.totalPaise,
    this.status = 'completed',
    this.items = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'shop_id': shopId,
        'supplier_id': supplierId,
        'supplier_name_snapshot': supplierNameSnapshot,
        'invoice_number': invoiceNumber,
        'invoice_date': invoiceDate.toIso8601String(),
        'subtotal_paise': subtotalPaise,
        'tax_total_paise': taxTotalPaise,
        'total_paise': totalPaise,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      supplierId: json['supplier_id'] as String?,
      supplierNameSnapshot: json['supplier_name_snapshot'] as String?,
      invoiceNumber: json['invoice_number'] as String,
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      subtotalPaise: (json['subtotal_paise'] as num).toInt(),
      taxTotalPaise: (json['tax_total_paise'] as num).toInt(),
      totalPaise: (json['total_paise'] as num).toInt(),
      status: (json['status'] as String?) ?? 'completed',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
