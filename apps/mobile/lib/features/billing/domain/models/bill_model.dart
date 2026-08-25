class BillItemModel {
  final String id;
  final String billId;
  final String productId;
  final String productName;
  final String unit;
  final int unitPricePaise;
  final double quantity;
  final double taxRate;
  final int taxAmountPaise;
  final int totalPaise;
  final DateTime createdAt;

  const BillItemModel({
    required this.id,
    required this.billId,
    required this.productId,
    required this.productName,
    this.unit = 'pcs',
    required this.unitPricePaise,
    required this.quantity,
    this.taxRate = 0.0,
    required this.taxAmountPaise,
    required this.totalPaise,
    required this.createdAt,
  });

  int get subtotalPaise => (unitPricePaise * quantity).round();

  BillItemModel copyWith({
    String? id,
    String? billId,
    String? productId,
    String? productName,
    String? unit,
    int? unitPricePaise,
    double? quantity,
    double? taxRate,
    int? taxAmountPaise,
    int? totalPaise,
    DateTime? createdAt,
  }) {
    return BillItemModel(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unit: unit ?? this.unit,
      unitPricePaise: unitPricePaise ?? this.unitPricePaise,
      quantity: quantity ?? this.quantity,
      taxRate: taxRate ?? this.taxRate,
      taxAmountPaise: taxAmountPaise ?? this.taxAmountPaise,
      totalPaise: totalPaise ?? this.totalPaise,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bill_id': billId,
        'product_id': productId,
        'product_name': productName,
        'unit': unit,
        'unit_price_paise': unitPricePaise,
        'quantity': quantity,
        'tax_rate': taxRate,
        'tax_amount_paise': taxAmountPaise,
        'total_paise': totalPaise,
        'created_at': createdAt.toIso8601String(),
      };

  factory BillItemModel.fromJson(Map<String, dynamic> json) => BillItemModel(
        id: json['id'] as String,
        billId: json['bill_id'] as String,
        productId: json['product_id'] as String,
        productName: json['product_name'] as String,
        unit: json['unit'] as String? ?? 'pcs',
        unitPricePaise: (json['unit_price_paise'] as num).toInt(),
        quantity: (json['quantity'] as num).toDouble(),
        taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
        taxAmountPaise: (json['tax_amount_paise'] as num?)?.toInt() ?? 0,
        totalPaise: (json['total_paise'] as num).toInt(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}

class BillModel {
  final String id;
  final String shopId;
  final String cashierId;
  final String billNumber;
  final String status; // 'draft', 'completed', 'cancelled'
  final List<BillItemModel> items;

  // Optional Customer Attachment
  final String? customerId;
  final String? customerName;
  final String? customerPhone;

  // Discount configuration
  final String discountType; // 'none', 'percentage', 'fixed'
  final double
      discountValue; // percentage (0..100) or fixed amount in rupees/paise

  final int subtotalPaise;
  final int taxTotalPaise;
  final int discountPaise;
  final int totalPaise;
  final String paymentStatus; // 'unpaid', 'paid', 'partially_paid'
  final DateTime createdAt;
  final DateTime updatedAt;

  const BillModel({
    required this.id,
    required this.shopId,
    required this.cashierId,
    required this.billNumber,
    this.status = 'draft',
    this.items = const [],
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.discountType = 'none',
    this.discountValue = 0.0,
    this.subtotalPaise = 0,
    this.taxTotalPaise = 0,
    this.discountPaise = 0,
    this.totalPaise = 0,
    this.paymentStatus = 'unpaid',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDraft => status == 'draft';
  bool get isCompleted => status == 'completed';
  bool get hasCustomer => customerId != null && customerId!.isNotEmpty;

  BillModel copyWith({
    String? id,
    String? shopId,
    String? cashierId,
    String? billNumber,
    String? status,
    List<BillItemModel>? items,
    String? customerId,
    bool clearCustomer = false,
    String? customerName,
    String? customerPhone,
    String? discountType,
    double? discountValue,
    int? subtotalPaise,
    int? taxTotalPaise,
    int? discountPaise,
    int? totalPaise,
    String? paymentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BillModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      cashierId: cashierId ?? this.cashierId,
      billNumber: billNumber ?? this.billNumber,
      status: status ?? this.status,
      items: items ?? this.items,
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      customerName: clearCustomer ? null : (customerName ?? this.customerName),
      customerPhone:
          clearCustomer ? null : (customerPhone ?? this.customerPhone),
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      subtotalPaise: subtotalPaise ?? this.subtotalPaise,
      taxTotalPaise: taxTotalPaise ?? this.taxTotalPaise,
      discountPaise: discountPaise ?? this.discountPaise,
      totalPaise: totalPaise ?? this.totalPaise,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shop_id': shopId,
        'cashier_id': cashierId,
        'bill_number': billNumber,
        'status': status,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'discount_type': discountType,
        'discount_value': discountValue,
        'subtotal_paise': subtotalPaise,
        'tax_total_paise': taxTotalPaise,
        'discount_paise': discountPaise,
        'total_paise': totalPaise,
        'payment_status': paymentStatus,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory BillModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return BillModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      cashierId: json['cashier_id'] as String,
      billNumber: json['bill_number'] as String,
      status: json['status'] as String? ?? 'draft',
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      discountType: json['discount_type'] as String? ?? 'none',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      subtotalPaise: (json['subtotal_paise'] as num?)?.toInt() ?? 0,
      taxTotalPaise: (json['tax_total_paise'] as num?)?.toInt() ?? 0,
      discountPaise: (json['discount_paise'] as num?)?.toInt() ?? 0,
      totalPaise: (json['total_paise'] as num?)?.toInt() ?? 0,
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      items: rawItems
          .map((i) => BillItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}
