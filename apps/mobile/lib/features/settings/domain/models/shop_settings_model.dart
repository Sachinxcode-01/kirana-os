class BusinessDayHours {
  final bool isOpen;
  final String openTime;
  final String closeTime;

  const BusinessDayHours({
    this.isOpen = true,
    this.openTime = '09:00',
    this.closeTime = '21:00',
  });

  BusinessDayHours copyWith({
    bool? isOpen,
    String? openTime,
    String? closeTime,
  }) {
    return BusinessDayHours(
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'is_open': isOpen,
        'open_time': openTime,
        'close_time': closeTime,
      };

  factory BusinessDayHours.fromJson(Map<String, dynamic> json) =>
      BusinessDayHours(
        isOpen: json['is_open'] as bool? ?? true,
        openTime: json['open_time'] as String? ?? '09:00',
        closeTime: json['close_time'] as String? ?? '21:00',
      );
}

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
  final String currencyCode;
  final String currencySymbol;
  final int decimalPrecision;
  final bool isTaxEnabled;
  final double defaultTaxPercentage;

  // 3. Default Bill Settings
  final String billPrefix;
  final int nextInvoiceNumber;
  final bool showShopAddress;
  final bool showCustomerDetails;
  final bool showTaxInformation;

  // 4. Business Hours (Monday - Sunday)
  final Map<String, BusinessDayHours> businessHours;

  const ShopSettingsModel({
    required this.shopId,
    required this.shopName,
    required this.phone,
    this.address,
    this.city,
    this.state = 'Karnataka',
    this.pincode,
    this.gstin,
    this.currencyCode = 'INR',
    this.currencySymbol = '₹',
    this.decimalPrecision = 2,
    this.isTaxEnabled = true,
    this.defaultTaxPercentage = 0.0,
    this.billPrefix = 'INV-',
    this.nextInvoiceNumber = 1001,
    this.showShopAddress = true,
    this.showCustomerDetails = true,
    this.showTaxInformation = true,
    this.businessHours = const {
      'monday': BusinessDayHours(),
      'tuesday': BusinessDayHours(),
      'wednesday': BusinessDayHours(),
      'thursday': BusinessDayHours(),
      'friday': BusinessDayHours(),
      'saturday': BusinessDayHours(),
      'sunday': BusinessDayHours(),
    },
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
    String? currencyCode,
    String? currencySymbol,
    int? decimalPrecision,
    bool? isTaxEnabled,
    double? defaultTaxPercentage,
    String? billPrefix,
    int? nextInvoiceNumber,
    bool? showShopAddress,
    bool? showCustomerDetails,
    bool? showTaxInformation,
    Map<String, BusinessDayHours>? businessHours,
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
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      decimalPrecision: decimalPrecision ?? this.decimalPrecision,
      isTaxEnabled: isTaxEnabled ?? this.isTaxEnabled,
      defaultTaxPercentage: defaultTaxPercentage ?? this.defaultTaxPercentage,
      billPrefix: billPrefix ?? this.billPrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      showShopAddress: showShopAddress ?? this.showShopAddress,
      showCustomerDetails: showCustomerDetails ?? this.showCustomerDetails,
      showTaxInformation: showTaxInformation ?? this.showTaxInformation,
      businessHours: businessHours ?? this.businessHours,
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
        'currency_code': currencyCode,
        'currency_symbol': currencySymbol,
        'decimal_precision': decimalPrecision,
        'is_tax_enabled': isTaxEnabled,
        'default_tax_percentage': defaultTaxPercentage,
        'bill_prefix': billPrefix,
        'next_invoice_number': nextInvoiceNumber,
        'show_shop_address': showShopAddress,
        'show_customer_details': showCustomerDetails,
        'show_tax_information': showTaxInformation,
        'business_hours': businessHours.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory ShopSettingsModel.fromJson(Map<String, dynamic> json) {
    Map<String, BusinessDayHours> hoursMap = {
      'monday': const BusinessDayHours(),
      'tuesday': const BusinessDayHours(),
      'wednesday': const BusinessDayHours(),
      'thursday': const BusinessDayHours(),
      'friday': const BusinessDayHours(),
      'saturday': const BusinessDayHours(),
      'sunday': const BusinessDayHours(),
    };

    if (json['business_hours'] != null) {
      try {
        final rawMap = json['business_hours'] as Map<String, dynamic>;
        hoursMap = rawMap.map(
          (k, v) => MapEntry(
            k.toLowerCase(),
            BusinessDayHours.fromJson(v as Map<String, dynamic>),
          ),
        );
      } catch (_) {}
    }

    return ShopSettingsModel(
      shopId: json['shop_id'] as String? ?? json['id'] as String? ?? '',
      shopName: json['shop_name'] as String? ?? json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String? ?? 'Karnataka',
      pincode: json['pincode'] as String?,
      gstin: json['gstin'] as String?,
      currencyCode: json['currency_code'] as String? ?? 'INR',
      currencySymbol: json['currency_symbol'] as String? ??
          json['currency'] as String? ??
          '₹',
      decimalPrecision: json['decimal_precision'] as int? ?? 2,
      isTaxEnabled: json['is_tax_enabled'] as bool? ?? true,
      defaultTaxPercentage:
          (json['default_tax_percentage'] as num?)?.toDouble() ?? 0.0,
      billPrefix: json['bill_prefix'] as String? ?? 'INV-',
      nextInvoiceNumber: json['next_invoice_number'] as int? ?? 1001,
      showShopAddress: json['show_shop_address'] as bool? ?? true,
      showCustomerDetails: json['show_customer_details'] as bool? ?? true,
      showTaxInformation: json['show_tax_information'] as bool? ?? true,
      businessHours: hoursMap,
    );
  }
}
