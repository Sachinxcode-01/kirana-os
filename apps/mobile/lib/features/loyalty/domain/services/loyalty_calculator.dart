/// Pure Dart loyalty calculation service avoiding floating-point rounding drift
class LoyaltyCalculator {
  const LoyaltyCalculator._();

  /// Calculates loyalty points earned on a purchase subtotal.
  /// Subtotal is in integer Paise (1 INR = 100 Paise).
  /// earnRatePercentage is e.g. 1.0 (1 point per ₹100 spent).
  static int calculatePointsEarned({
    required int subtotalPaise,
    required double earnRatePercentage,
  }) {
    if (subtotalPaise <= 0 || earnRatePercentage <= 0) return 0;
    // 1 Point per (100 / earnRatePercentage) Rupees.
    // In Paise: 1 Rupee = 100 Paise.
    // e.g. 1.0% rate: ₹100 = 10,000 Paise -> 1 Point.
    // Formula: floor(subtotalPaise * earnRatePercentage / 10000)
    final points = (subtotalPaise * earnRatePercentage) / 10000.0;
    return points.floor();
  }

  /// Calculates the discount value in integer Paise for a given number of redeemed points.
  /// e.g. 50 points * 100 Paise/point (₹1.00) = 5,000 Paise (₹50.00).
  static int calculateDiscountPaise({
    required int pointsToRedeem,
    required int redemptionValuePaise,
  }) {
    if (pointsToRedeem <= 0 || redemptionValuePaise <= 0) return 0;
    return pointsToRedeem * redemptionValuePaise;
  }

  /// Calculates the maximum points that can be redeemed for a cart.
  /// Cannot exceed customer's balance or total cart subtotal.
  static int maxRedeemablePoints({
    required int availablePoints,
    required int cartSubtotalPaise,
    required int redemptionValuePaise,
    required int minPointsThreshold,
  }) {
    if (availablePoints < minPointsThreshold || cartSubtotalPaise <= 0 || redemptionValuePaise <= 0) {
      return 0;
    }

    final maxPointsForCart = (cartSubtotalPaise / redemptionValuePaise).floor();
    return availablePoints < maxPointsForCart ? availablePoints : maxPointsForCart;
  }

  /// Validates whether customer has reached minimum redemption threshold
  static bool canRedeem({
    required int availablePoints,
    required int minPointsThreshold,
  }) {
    return availablePoints >= minPointsThreshold && availablePoints > 0;
  }
}
