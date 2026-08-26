class PurchaseItemModel {
  final String id;
  final String purchaseId;
  final String productId;
  final String productName;
  final String? barcode;
  final String unit;
  final double quantity;
  final int purchasePricePaise;
  final int totalPaise;
  final DateTime createdAt;

  const PurchaseItemModel({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    this.barcode,
    this.unit = 'pcs',
    required this.quantity,
    required this.purchasePricePaise,
    required this.totalPaise,
    required this.createdAt,
  });

  factory PurchaseItemModel.create({
    required String id,
    required String purchaseId,
    required String productId,
    required String productName,
    String? barcode,
    String unit = 'pcs',
    required double quantity,
    required int purchasePricePaise,
    DateTime? createdAt,
  }) {
    final calcTotal = (quantity * purchasePricePaise).round();
    return PurchaseItemModel(
      id: id,
      purchaseId: purchaseId,
      productId: productId,
      productName: productName,
      barcode: barcode,
      unit: unit,
      quantity: quantity,
      purchasePricePaise: purchasePricePaise,
      totalPaise: calcTotal,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  PurchaseItemModel copyWith({
    String? id,
    String? purchaseId,
    String? productId,
    String? productName,
    String? barcode,
    String? unit,
    double? quantity,
    int? purchasePricePaise,
    int? totalPaise,
    DateTime? createdAt,
  }) {
    final newQty = quantity ?? this.quantity;
    final newPrice = purchasePricePaise ?? this.purchasePricePaise;
    return PurchaseItemModel(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
      unit: unit ?? this.unit,
      quantity: newQty,
      purchasePricePaise: newPrice,
      totalPaise: totalPaise ?? (newQty * newPrice).round(),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'purchase_id': purchaseId,
        'product_id': productId,
        'product_name': productName,
        'barcode': barcode,
        'unit': unit,
        'quantity': quantity,
        'purchase_price_paise': purchasePricePaise,
        'total_paise': totalPaise,
        'created_at': createdAt.toIso8601String(),
      };

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num).toDouble();
    final price = (json['purchase_price_paise'] as num).toInt();
    final total = json['total_paise'] != null
        ? (json['total_paise'] as num).toInt()
        : (qty * price).round();

    return PurchaseItemModel(
      id: json['id'] as String,
      purchaseId: json['purchase_id'] as String? ?? '',
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? 'Product',
      barcode: json['barcode'] as String?,
      unit: json['unit'] as String? ?? 'pcs',
      quantity: qty,
      purchasePricePaise: price,
      totalPaise: total,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
