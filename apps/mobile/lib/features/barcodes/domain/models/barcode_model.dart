class BarcodeModel {
  final String id;
  final String shopId;
  final String productId;
  final String barcode;
  final String barcodeType;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BarcodeModel({
    required this.id,
    required this.shopId,
    required this.productId,
    required this.barcode,
    this.barcodeType = 'EAN_13',
    this.isPrimary = true,
    required this.createdAt,
    required this.updatedAt,
  });

  BarcodeModel copyWith({
    String? id,
    String? shopId,
    String? productId,
    String? barcode,
    String? barcodeType,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BarcodeModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      productId: productId ?? this.productId,
      barcode: barcode ?? this.barcode,
      barcodeType: barcodeType ?? this.barcodeType,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory BarcodeModel.fromJson(Map<String, dynamic> json) {
    return BarcodeModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      productId: json['product_id'] as String,
      barcode: json['barcode'] as String,
      barcodeType: json['barcode_type'] as String? ?? 'EAN_13',
      isPrimary: json['is_primary'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'product_id': productId,
      'barcode': barcode,
      'barcode_type': barcodeType,
      'is_primary': isPrimary,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
