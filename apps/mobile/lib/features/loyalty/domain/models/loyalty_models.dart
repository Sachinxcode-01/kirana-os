/// Represents configuration settings for customer loyalty rewards program
class LoyaltySettingsModel {
  final bool isEnabled;
  final double earnRatePercentage; // e.g. 1.0 = 1 pt per ₹100
  final int redemptionValuePaise; // e.g. 100 = 1 pt = ₹1.00
  final int minPointsToRedeem;
  final int pointsExpiryDays;

  const LoyaltySettingsModel({
    this.isEnabled = true,
    this.earnRatePercentage = 1.0,
    this.redemptionValuePaise = 100,
    this.minPointsToRedeem = 50,
    this.pointsExpiryDays = 365,
  });

  LoyaltySettingsModel copyWith({
    bool? isEnabled,
    double? earnRatePercentage,
    int? redemptionValuePaise,
    int? minPointsToRedeem,
    int? pointsExpiryDays,
  }) {
    return LoyaltySettingsModel(
      isEnabled: isEnabled ?? this.isEnabled,
      earnRatePercentage: earnRatePercentage ?? this.earnRatePercentage,
      redemptionValuePaise: redemptionValuePaise ?? this.redemptionValuePaise,
      minPointsToRedeem: minPointsToRedeem ?? this.minPointsToRedeem,
      pointsExpiryDays: pointsExpiryDays ?? this.pointsExpiryDays,
    );
  }

  Map<String, dynamic> toJson() => {
        'is_enabled': isEnabled,
        'earn_rate_percentage': earnRatePercentage,
        'redemption_value_paise': redemptionValuePaise,
        'min_points_to_redeem': minPointsToRedeem,
        'points_expiry_days': pointsExpiryDays,
      };

  factory LoyaltySettingsModel.fromJson(Map<String, dynamic> json) {
    return LoyaltySettingsModel(
      isEnabled: json['is_enabled'] as bool? ?? true,
      earnRatePercentage: (json['earn_rate_percentage'] as num?)?.toDouble() ?? 1.0,
      redemptionValuePaise: (json['redemption_value_paise'] as num?)?.toInt() ?? 100,
      minPointsToRedeem: (json['min_points_to_redeem'] as num?)?.toInt() ?? 50,
      pointsExpiryDays: (json['points_expiry_days'] as num?)?.toInt() ?? 365,
    );
  }
}

/// Represents an entry in the immutable customer loyalty points ledger
class LoyaltyLedgerEntry {
  final String id;
  final String shopId;
  final String customerId;
  final String? billId;
  final String transactionType; // 'earn', 'redeem', 'manual_adjust', 'rollback'
  final int pointsChanged;
  final int balanceAfter;
  final String? notes;
  final DateTime createdAt;

  const LoyaltyLedgerEntry({
    required this.id,
    required this.shopId,
    required this.customerId,
    this.billId,
    required this.transactionType,
    required this.pointsChanged,
    required this.balanceAfter,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'shop_id': shopId,
        'customer_id': customerId,
        'bill_id': billId,
        'transaction_type': transactionType,
        'points_changed': pointsChanged,
        'balance_after': balanceAfter,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory LoyaltyLedgerEntry.fromJson(Map<String, dynamic> json) {
    return LoyaltyLedgerEntry(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      customerId: json['customer_id'] as String,
      billId: json['bill_id'] as String?,
      transactionType: json['transaction_type'] as String,
      pointsChanged: (json['points_changed'] as num).toInt(),
      balanceAfter: (json['balance_after'] as num).toInt(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
