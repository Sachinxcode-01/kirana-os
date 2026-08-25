class ProductModel {
  final String id;
  final String shopId;
  final String name;
  final String? categoryId;
  final String? categoryName;
  final String? brand;
  final String? imageUrl;
  final String unit;
  final int sellingPricePaise;
  final int purchasePricePaise;
  final int mrpPaise;
  final double currentStock;
  final double minStockAlert;
  final String? description;
  final String? regionalName;
  final String? hsnCode;
  final double taxRatePercentage;
  final bool isTaxInclusive;
  final bool isLoose;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.shopId,
    required this.name,
    this.categoryId,
    this.categoryName,
    this.brand,
    this.imageUrl,
    this.unit = 'PCS',
    required this.sellingPricePaise,
    this.purchasePricePaise = 0,
    required this.mrpPaise,
    this.currentStock = 0.0,
    this.minStockAlert = 5.0,
    this.description,
    this.regionalName,
    this.hsnCode,
    this.taxRatePercentage = 0.0,
    this.isTaxInclusive = true,
    this.isLoose = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  ProductModel copyWith({
    String? id,
    String? shopId,
    String? name,
    String? categoryId,
    String? categoryName,
    String? brand,
    String? imageUrl,
    String? unit,
    int? sellingPricePaise,
    int? purchasePricePaise,
    int? mrpPaise,
    double? currentStock,
    double? minStockAlert,
    String? description,
    String? regionalName,
    String? hsnCode,
    double? taxRatePercentage,
    bool? isTaxInclusive,
    bool? isLoose,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      unit: unit ?? this.unit,
      sellingPricePaise: sellingPricePaise ?? this.sellingPricePaise,
      purchasePricePaise: purchasePricePaise ?? this.purchasePricePaise,
      mrpPaise: mrpPaise ?? this.mrpPaise,
      currentStock: currentStock ?? this.currentStock,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      description: description ?? this.description,
      regionalName: regionalName ?? this.regionalName,
      hsnCode: hsnCode ?? this.hsnCode,
      taxRatePercentage: taxRatePercentage ?? this.taxRatePercentage,
      isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
      isLoose: isLoose ?? this.isLoose,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      name: json['name'] as String,
      categoryId: json['category_id'] as String?,
      categoryName: json['categories'] != null
          ? (json['categories'] as Map<String, dynamic>)['name'] as String?
          : null,
      brand: json['brand'] as String?,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      unit: json['unit'] as String? ?? 'PCS',
      sellingPricePaise: (json['selling_price_paise'] as num).toInt(),
      purchasePricePaise: ((json['purchase_price_paise'] ?? 0) as num).toInt(),
      mrpPaise:
          ((json['mrp_paise'] ?? json['selling_price_paise']) as num).toInt(),
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
      minStockAlert: (json['min_stock_alert'] as num?)?.toDouble() ?? 5.0,
      description: json['description'] as String?,
      regionalName: json['regional_name'] as String?,
      hsnCode: json['hsn_code'] as String?,
      taxRatePercentage:
          (json['tax_rate_percentage'] as num?)?.toDouble() ?? 0.0,
      isTaxInclusive: json['is_tax_inclusive'] as bool? ?? true,
      isLoose: json['is_loose'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
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
      'name': name,
      'category_id': categoryId,
      'brand': brand,
      'image_url': imageUrl,
      'unit': unit,
      'selling_price_paise': sellingPricePaise,
      'purchase_price_paise': purchasePricePaise,
      'mrp_paise': mrpPaise,
      'current_stock': currentStock,
      'min_stock_alert': minStockAlert,
      'description': description,
      'regional_name': regionalName,
      'hsn_code': hsnCode,
      'tax_rate_percentage': taxRatePercentage,
      'is_tax_inclusive': isTaxInclusive,
      'is_loose': isLoose,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
