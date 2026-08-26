class SupplierModel {
  final String id;
  final String shopId;
  final String name;
  final String? contactPerson;
  final String phone;
  final String? email;
  final String? address;
  final String? gstin;
  final String? notes;
  final int currentBalancePaise;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupplierModel({
    required this.id,
    required this.shopId,
    required this.name,
    this.contactPerson,
    required this.phone,
    this.email,
    this.address,
    this.gstin,
    this.notes,
    this.currentBalancePaise = 0,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  static bool isValidPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    return clean.length >= 10;
  }

  static bool isValidEmail(String? email) {
    if (email == null || email.trim().isEmpty) return true;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());
  }

  static bool isValidGstin(String? gstin) {
    if (gstin == null || gstin.trim().isEmpty) return true;
    return gstin.trim().length == 15;
  }

  SupplierModel copyWith({
    String? id,
    String? shopId,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? gstin,
    String? notes,
    int? currentBalancePaise,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      notes: notes ?? this.notes,
      currentBalancePaise: currentBalancePaise ?? this.currentBalancePaise,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shop_id': shopId,
        'name': name,
        'contact_person': contactPerson,
        'phone': phone,
        'email': email,
        'address': address,
        'gstin': gstin,
        'notes': notes,
        'current_balance_paise': currentBalancePaise,
        'is_archived': isArchived,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      name: json['name'] as String,
      contactPerson: json['contact_person'] as String?,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
      gstin: json['gstin'] as String?,
      notes: json['notes'] as String?,
      currentBalancePaise:
          (json['current_balance_paise'] as num?)?.toInt() ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
