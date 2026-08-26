import 'purchase_item_model.dart';

class PurchaseModel {
  final String id;
  final String shopId;
  final String purchaseNumber;
  final String? supplierId;
  final String? supplierName;
  final String? supplierReference;
  final String status; // 'draft', 'completed'
  final List<PurchaseItemModel> items;
  final int subtotalPaise;
  final int taxTotalPaise;
  final int totalPaise;
  final String? idempotencyKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PurchaseModel({
    required this.id,
    required this.shopId,
    required this.purchaseNumber,
    this.supplierId,
    this.supplierName,
    this.supplierReference,
    this.status = 'draft',
    this.items = const [],
    this.subtotalPaise = 0,
    this.taxTotalPaise = 0,
    this.totalPaise = 0,
    this.idempotencyKey,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDraft => status == 'draft';
  bool get isCompleted => status == 'completed';

  static int calculateSubtotal(List<PurchaseItemModel> items) {
    return items.fold<int>(0, (sum, i) => sum + i.totalPaise);
  }

  factory PurchaseModel.create({
    required String id,
    required String shopId,
    required String purchaseNumber,
    String? supplierId,
    String? supplierName,
    String? supplierReference,
    String status = 'draft',
    List<PurchaseItemModel> items = const [],
    int taxTotalPaise = 0,
    String? idempotencyKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final subtotal = calculateSubtotal(items);
    final total = subtotal + taxTotalPaise;
    final now = DateTime.now();
    return PurchaseModel(
      id: id,
      shopId: shopId,
      purchaseNumber: purchaseNumber,
      supplierId: supplierId,
      supplierName: supplierName,
      supplierReference: supplierReference,
      status: status,
      items: items,
      subtotalPaise: subtotal,
      taxTotalPaise: taxTotalPaise,
      totalPaise: total,
      idempotencyKey: idempotencyKey,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  PurchaseModel copyWith({
    String? id,
    String? shopId,
    String? purchaseNumber,
    String? supplierId,
    bool clearSupplier = false,
    String? supplierName,
    String? supplierReference,
    bool clearSupplierReference = false,
    String? status,
    List<PurchaseItemModel>? items,
    int? subtotalPaise,
    int? taxTotalPaise,
    int? totalPaise,
    String? idempotencyKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final newItems = items ?? this.items;
    final newSubtotal = subtotalPaise ?? calculateSubtotal(newItems);
    final newTax = taxTotalPaise ?? this.taxTotalPaise;
    final newTotal = totalPaise ?? (newSubtotal + newTax);

    return PurchaseModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      purchaseNumber: purchaseNumber ?? this.purchaseNumber,
      supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
      supplierName: clearSupplier ? null : (supplierName ?? this.supplierName),
      supplierReference: clearSupplierReference
          ? null
          : (supplierReference ?? this.supplierReference),
      status: status ?? this.status,
      items: newItems,
      subtotalPaise: newSubtotal,
      taxTotalPaise: newTax,
      totalPaise: newTotal,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shop_id': shopId,
        'purchase_number': purchaseNumber,
        'supplier_id': supplierId,
        'supplier_name': supplierName,
        'supplier_reference': supplierReference,
        'status': status,
        'subtotal_paise': subtotalPaise,
        'tax_total_paise': taxTotalPaise,
        'total_paise': totalPaise,
        'idempotency_key': idempotencyKey,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemList = rawItems
        .map((i) => PurchaseItemModel.fromJson(i as Map<String, dynamic>))
        .toList();
    final subtotal = json['subtotal_paise'] != null
        ? (json['subtotal_paise'] as num).toInt()
        : calculateSubtotal(itemList);
    final tax = (json['tax_total_paise'] as num?)?.toInt() ?? 0;
    final total = json['total_paise'] != null
        ? (json['total_paise'] as num).toInt()
        : (subtotal + tax);

    return PurchaseModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      purchaseNumber: json['purchase_number'] as String? ?? 'PUR-001',
      supplierId: json['supplier_id'] as String?,
      supplierName: json['supplier_name'] as String? ??
          json['supplier_name_snapshot'] as String?,
      supplierReference: json['supplier_reference'] as String?,
      status: json['status'] as String? ?? 'draft',
      items: itemList,
      subtotalPaise: subtotal,
      taxTotalPaise: tax,
      totalPaise: total,
      idempotencyKey: json['idempotency_key'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
