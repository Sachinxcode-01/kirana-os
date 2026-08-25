class ShopSettingsModel {
  final String shopId;

  // 1. Basic Shop Information
  final String shopName;
  final String phone;
  final String? address;
  final String? city;
  final String state;
  final String? pincode;
  final String? gstin;

  // 2. Tax & Currency Settings
  final String currencySymbol;
  final bool isTaxEnabled;
  final double defaultTaxPercentage;

  // 3. Default Bill Settings
  final String billPrefix;
  final int nextInvoiceNumber;
  final bool showShopAddress;
  final bool showCustomerDetails;
  final bool showTaxInformation;

  const ShopSettingsModel({
    required this.shopId,
    required this.shopName,
    required this.phone,
    this.address,
    this.city,
    this.state = 'Karnataka',
    this.pincode,
    this.gstin,
    this.currencySymbol = '₹',
    this.isTaxEnabled = true,
    this.defaultTaxPercentage = 0.0,
    this.billPrefix = 'INV-',
    this.nextInvoiceNumber = 1001,
    this.showShopAddress = true,
    this.showCustomerDetails = true,
    this.showTaxInformation = true,
  });

  ShopSettingsModel copyWith({
    String? shopId,
    String? shopName,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? gstin,
    String? currencySymbol,
    bool? isTaxEnabled,
    double? defaultTaxPercentage,
    String? billPrefix,
    int? nextInvoiceNumber,
    bool? showShopAddress,
    bool? showCustomerDetails,
    bool? showTaxInformation,
  }) {
    return ShopSettingsModel(
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      gstin: gstin ?? this.gstin,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      isTaxEnabled: isTaxEnabled ?? this.isTaxEnabled,
      defaultTaxPercentage: defaultTaxPercentage ?? this.defaultTaxPercentage,
      billPrefix: billPrefix ?? this.billPrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      showShopAddress: showShopAddress ?? this.showShopAddress,
      showCustomerDetails: showCustomerDetails ?? this.showCustomerDetails,
      showTaxInformation: showTaxInformation ?? this.showTaxInformation,
    );
  }

  Map<String, dynamic> toJson() => {
        'shop_id': shopId,
        'shop_name': shopName,
        'phone': phone,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'gstin': gstin,
        'currency_symbol': currencySymbol,
        'is_tax_enabled': isTaxEnabled,
        'default_tax_percentage': defaultTaxPercentage,
        'bill_prefix': billPrefix,
        'next_invoice_number': nextInvoiceNumber,
        'show_shop_address': showShopAddress,
        'show_customer_details': showCustomerDetails,
        'show_tax_information': showTaxInformation,
      };

  factory ShopSettingsModel.fromJson(Map<String, dynamic> json) =>
      ShopSettingsModel(
        shopId: json['shop_id'] as String? ?? json['id'] as String? ?? '',
        shopName: json['shop_name'] as String? ?? json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String? ?? 'Karnataka',
        pincode: json['pincode'] as String?,
        gstin: json['gstin'] as String?,
        currencySymbol: json['currency_symbol'] as String? ?? '₹',
        isTaxEnabled: json['is_tax_enabled'] as bool? ?? true,
        defaultTaxPercentage:
            (json['default_tax_percentage'] as num?)?.toDouble() ?? 0.0,
        billPrefix: json['bill_prefix'] as String? ?? 'INV-',
        nextInvoiceNumber: json['next_invoice_number'] as int? ?? 1001,
        showShopAddress: json['show_shop_address'] as bool? ?? true,
        showCustomerDetails: json['show_customer_details'] as bool? ?? true,
        showTaxInformation: json['show_tax_information'] as bool? ?? true,
      );
}
