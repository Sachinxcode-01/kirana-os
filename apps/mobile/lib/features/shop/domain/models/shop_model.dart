class ShopModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? gstin;
  final String? fssaiLicense;
  final String? address;
  final String? city;
  final String state;
  final String? pincode;
  final String? upiId;
  final String? logoUrl;
  final String? receiptName;
  final String currency;
  final DateTime createdAt;

  const ShopModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.gstin,
    this.fssaiLicense,
    this.address,
    this.city,
    this.state = 'Karnataka',
    this.pincode,
    this.upiId,
    this.logoUrl,
    this.receiptName,
    this.currency = 'INR',
    required this.createdAt,
  });

  /// Display name for receipts & bills (falls back to shop name if not specified)
  String get effectiveReceiptName =>
      (receiptName != null && receiptName!.trim().isNotEmpty)
          ? receiptName!.trim()
          : name;

  ShopModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? gstin,
    String? fssaiLicense,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? upiId,
    String? logoUrl,
    bool clearLogoUrl = false,
    String? receiptName,
    bool clearReceiptName = false,
    String? currency,
    DateTime? createdAt,
  }) {
    return ShopModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstin: gstin ?? this.gstin,
      fssaiLicense: fssaiLicense ?? this.fssaiLicense,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      upiId: upiId ?? this.upiId,
      logoUrl: clearLogoUrl ? null : (logoUrl ?? this.logoUrl),
      receiptName: clearReceiptName ? null : (receiptName ?? this.receiptName),
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
