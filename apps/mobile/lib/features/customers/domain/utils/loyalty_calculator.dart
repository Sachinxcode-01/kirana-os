import 'dart:math';
import '../models/loyalty_models.dart';

class LoyaltyCalculator {
  /// Calculate points earned from a bill purchase taking customer tier into account
  static int calculateEarnedPoints({
    required int billTotalPaise,
    required LoyaltyTier tier,
    LoyaltyProgramConfig config = const LoyaltyProgramConfig(),
  }) {
    if (!config.isEnabled || billTotalPaise <= 0 || config.earnRatePaise <= 0) {
      return 0;
    }

    final basePoints = billTotalPaise ~/ config.earnRatePaise;
    final totalPoints = (basePoints * tier.bonusMultiplier).floor();
    return max(0, totalPoints);
  }

  /// Calculate the maximum points a customer can redeem against a bill
  static int calculateMaxRedeemablePoints({
    required int billTotalPaise,
    required int customerPointBalance,
    LoyaltyProgramConfig config = const LoyaltyProgramConfig(),
  }) {
    if (!config.isEnabled ||
        billTotalPaise <= 0 ||
        customerPointBalance < config.minRedeemPoints ||
        config.pointValuePaise <= 0) {
      return 0;
    }

    // Maximum discount percentage allowed (e.g. max 50% of bill total)
    final maxDiscountPaise = (billTotalPaise * config.maxRedeemPercent) ~/ 100;
    final maxPointsAllowedByBill = maxDiscountPaise ~/ config.pointValuePaise;

    return min(customerPointBalance, maxPointsAllowedByBill);
  }

  /// Calculate the cash discount value in Paise for a given number of redeemed points
  static int calculateDiscountPaise({
    required int pointsToRedeem,
    LoyaltyProgramConfig config = const LoyaltyProgramConfig(),
  }) {
    if (!config.isEnabled || pointsToRedeem <= 0) {
      return 0;
    }
    return pointsToRedeem * config.pointValuePaise;
  }
}
