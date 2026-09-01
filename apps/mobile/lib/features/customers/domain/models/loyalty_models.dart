enum LoyaltyTier {
  bronze,
  silver,
  gold,
  platinum;

  String get displayName {
    switch (this) {
      case LoyaltyTier.bronze:
        return 'Bronze Member';
      case LoyaltyTier.silver:
        return 'Silver VIP';
      case LoyaltyTier.gold:
        return 'Gold Premium';
      case LoyaltyTier.platinum:
        return 'Platinum Elite';
    }
  }

  double get bonusMultiplier {
    switch (this) {
      case LoyaltyTier.bronze:
        return 1.0;
      case LoyaltyTier.silver:
        return 1.25;
      case LoyaltyTier.gold:
        return 1.5;
      case LoyaltyTier.platinum:
        return 2.0;
    }
  }

  int get minSpendPaise {
    switch (this) {
      case LoyaltyTier.bronze:
        return 0;
      case LoyaltyTier.silver:
        return 500000; // ₹5,000
      case LoyaltyTier.gold:
        return 2000000; // ₹20,000
      case LoyaltyTier.platinum:
        return 5000000; // ₹50,000
    }
  }

  static LoyaltyTier fromSpend(int lifetimeSpendPaise) {
    if (lifetimeSpendPaise >= 5000000) return LoyaltyTier.platinum;
    if (lifetimeSpendPaise >= 2000000) return LoyaltyTier.gold;
    if (lifetimeSpendPaise >= 500000) return LoyaltyTier.silver;
    return LoyaltyTier.bronze;
  }
}

class LoyaltyProgramConfig {
  final bool isEnabled;
  final int earnRatePaise; // spend in paise for 1 point (default 10000 = ₹100 spend -> 1 pt)
  final int pointValuePaise; // 1 point = 100 paise (₹1.00)
  final int minRedeemPoints; // min points to redeem (default 10)
  final int maxRedeemPercent; // max % of bill payable by points (default 50%)

  const LoyaltyProgramConfig({
    this.isEnabled = true,
    this.earnRatePaise = 10000,
    this.pointValuePaise = 100,
    this.minRedeemPoints = 10,
    this.maxRedeemPercent = 50,
  });

  LoyaltyProgramConfig copyWith({
    bool? isEnabled,
    int? earnRatePaise,
    int? pointValuePaise,
    int? minRedeemPoints,
    int? maxRedeemPercent,
  }) {
    return LoyaltyProgramConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      earnRatePaise: earnRatePaise ?? this.earnRatePaise,
      pointValuePaise: pointValuePaise ?? this.pointValuePaise,
      minRedeemPoints: minRedeemPoints ?? this.minRedeemPoints,
      maxRedeemPercent: maxRedeemPercent ?? this.maxRedeemPercent,
    );
  }
}

class CustomerLoyaltyProfile {
  final String customerId;
  final String shopId;
  final int pointBalance;
  final int totalPointsEarned;
  final int totalPointsRedeemed;
  final int lifetimeSpendPaise;
  final LoyaltyTier tier;
  final DateTime? lastActivityAt;

  const CustomerLoyaltyProfile({
    required this.customerId,
    required this.shopId,
    this.pointBalance = 0,
    this.totalPointsEarned = 0,
    this.totalPointsRedeemed = 0,
    this.lifetimeSpendPaise = 0,
    this.tier = LoyaltyTier.bronze,
    this.lastActivityAt,
  });

  CustomerLoyaltyProfile copyWith({
    String? customerId,
    String? shopId,
    int? pointBalance,
    int? totalPointsEarned,
    int? totalPointsRedeemed,
    int? lifetimeSpendPaise,
    LoyaltyTier? tier,
    DateTime? lastActivityAt,
  }) {
    return CustomerLoyaltyProfile(
      customerId: customerId ?? this.customerId,
      shopId: shopId ?? this.shopId,
      pointBalance: pointBalance ?? this.pointBalance,
      totalPointsEarned: totalPointsEarned ?? this.totalPointsEarned,
      totalPointsRedeemed: totalPointsRedeemed ?? this.totalPointsRedeemed,
      lifetimeSpendPaise: lifetimeSpendPaise ?? this.lifetimeSpendPaise,
      tier: tier ?? this.tier,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }
}

class LoyaltyLedgerEntry {
  final String id;
  final String customerId;
  final String shopId;
  final String? billId;
  final int pointsEarned;
  final int pointsRedeemed;
  final int balanceAfter;
  final String description;
  final DateTime createdAt;

  const LoyaltyLedgerEntry({
    required this.id,
    required this.customerId,
    required this.shopId,
    this.billId,
    this.pointsEarned = 0,
    this.pointsRedeemed = 0,
    required this.balanceAfter,
    required this.description,
    required this.createdAt,
  });
}
