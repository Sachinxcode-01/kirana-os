class LowStockAlertModel {
  final String id;
  final String shopId;
  final String productId;
  final String productName;
  final String? barcode;
  final double currentQuantity;
  final double minimumQuantity;
  final String unit;
  final String status; // 'low_stock', 'out_of_stock'
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LowStockAlertModel({
    required this.id,
    required this.shopId,
    required this.productId,
    required this.productName,
    this.barcode,
    required this.currentQuantity,
    required this.minimumQuantity,
    this.unit = 'PCS',
    required this.status,
    this.isRead = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOutOfStock => status == 'out_of_stock' || currentQuantity <= 0;
  bool get isLowStock => !isOutOfStock;

  /// Urgency ratio helper: lower ratio means higher urgency.
  /// Out-of-stock items have ratio 0.0 (highest priority).
  double get urgencyRatio {
    if (isOutOfStock) return 0.0;
    if (minimumQuantity <= 0) return 1.0;
    return currentQuantity / minimumQuantity;
  }

  LowStockAlertModel copyWith({
    String? id,
    String? shopId,
    String? productId,
    String? productName,
    String? barcode,
    double? currentQuantity,
    double? minimumQuantity,
    String? unit,
    String? status,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LowStockAlertModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      minimumQuantity: minimumQuantity ?? this.minimumQuantity,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory LowStockAlertModel.fromJson(Map<String, dynamic> json) {
    String pName = 'Product';
    String? pBarcode;
    String pUnit = 'PCS';

    if (json['products'] != null && json['products'] is Map<String, dynamic>) {
      final pMap = json['products'] as Map<String, dynamic>;
      pName = pMap['name'] as String? ?? 'Product';
      pUnit = pMap['unit'] as String? ?? 'PCS';
    } else if (json['product_name'] != null) {
      pName = json['product_name'] as String;
    }

    return LowStockAlertModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      productId: json['product_id'] as String,
      productName: pName,
      barcode: pBarcode ?? json['barcode'] as String?,
      currentQuantity: (json['current_quantity'] as num).toDouble(),
      minimumQuantity: (json['minimum_quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? pUnit,
      status: json['status'] as String? ?? 'low_stock',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shop_id': shopId,
        'product_id': productId,
        'current_quantity': currentQuantity,
        'minimum_quantity': minimumQuantity,
        'status': status,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
