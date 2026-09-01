import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/features/customers/domain/models/loyalty_models.dart';
import 'package:kirana_mobile/features/customers/domain/utils/loyalty_calculator.dart';
import 'package:kirana_mobile/features/customers/presentation/providers/loyalty_provider.dart';

void main() {
  group('LoyaltyTier Classification Tests', () {
    test('Correctly maps lifetime spend in paise to tiers', () {
      expect(LoyaltyTier.fromSpend(0), LoyaltyTier.bronze);
      expect(LoyaltyTier.fromSpend(499900), LoyaltyTier.bronze); // ₹4,999.00
      expect(LoyaltyTier.fromSpend(500000), LoyaltyTier.silver); // ₹5,000.00
      expect(LoyaltyTier.fromSpend(1999900), LoyaltyTier.silver); // ₹19,999.00
      expect(LoyaltyTier.fromSpend(2000000), LoyaltyTier.gold); // ₹20,000.00
      expect(LoyaltyTier.fromSpend(4999900), LoyaltyTier.gold); // ₹49,999.00
      expect(LoyaltyTier.fromSpend(5000000), LoyaltyTier.platinum); // ₹50,000.00
      expect(LoyaltyTier.fromSpend(10000000), LoyaltyTier.platinum); // ₹100,000.00
    });
  });

  group('LoyaltyCalculator Invariants Tests', () {
    test('calculateEarnedPoints respects earn rate and tier multipliers', () {
      const cfg = LoyaltyProgramConfig(
        earnRatePaise: 10000, // 1 point per ₹100
      );

      // Bronze: ₹450 -> 4 * 1.0 = 4 pts
      expect(
        LoyaltyCalculator.calculateEarnedPoints(
          billTotalPaise: 45000,
          tier: LoyaltyTier.bronze,
          config: cfg,
        ),
        4,
      );

      // Silver (1.25x): ₹450 -> 4 * 1.25 = 5 pts
      expect(
        LoyaltyCalculator.calculateEarnedPoints(
          billTotalPaise: 45000,
          tier: LoyaltyTier.silver,
          config: cfg,
        ),
        5,
      );

      // Gold (1.5x): ₹450 -> 4 * 1.5 = 6 pts
      expect(
        LoyaltyCalculator.calculateEarnedPoints(
          billTotalPaise: 45000,
          tier: LoyaltyTier.gold,
          config: cfg,
        ),
        6,
      );

      // Platinum (2.0x): ₹450 -> 4 * 2.0 = 8 pts
      expect(
        LoyaltyCalculator.calculateEarnedPoints(
          billTotalPaise: 45000,
          tier: LoyaltyTier.platinum,
          config: cfg,
        ),
        8,
      );
    });

    test('calculateMaxRedeemablePoints caps redemption by max % and point balance', () {
      const cfg = LoyaltyProgramConfig(
        pointValuePaise: 100, // 1 pt = ₹1
        minRedeemPoints: 10,
        maxRedeemPercent: 50, // max 50% of bill total
      );

      // Bill = ₹200 (20000 paise). Max 50% discount = ₹100 = 100 points.
      // Customer has 40 points -> can redeem full 40 points.
      expect(
        LoyaltyCalculator.calculateMaxRedeemablePoints(
          billTotalPaise: 20000,
          customerPointBalance: 40,
          config: cfg,
        ),
        40,
      );

      // Customer has 200 points -> capped at 100 points (50% of ₹200)
      expect(
        LoyaltyCalculator.calculateMaxRedeemablePoints(
          billTotalPaise: 20000,
          customerPointBalance: 200,
          config: cfg,
        ),
        100,
      );

      // Customer has 5 points (< min 10 points threshold) -> 0 points
      expect(
        LoyaltyCalculator.calculateMaxRedeemablePoints(
          billTotalPaise: 20000,
          customerPointBalance: 5,
          config: cfg,
        ),
        0,
      );
    });

    test('calculateDiscountPaise computes exact integer paise discount', () {
      const cfg = LoyaltyProgramConfig(pointValuePaise: 100);
      expect(
        LoyaltyCalculator.calculateDiscountPaise(
          pointsToRedeem: 35,
          config: cfg,
        ),
        3500, // ₹35.00
      );
    });
  });

  group('LoyaltyNotifier State Tests', () {
    test('Recording points earned updates balance, lifetime spend, and creates ledger entry', () {
      final notifier = LoyaltyNotifier();

      notifier.recordPointsEarned(
        customerId: 'cust-101',
        shopId: 'shop-01',
        billId: 'bill-501',
        pointsEarned: 15,
        billAmountPaise: 150000, // ₹1,500
      );

      final profile = notifier.state.profiles['cust-101'];
      expect(profile, isNotNull);
      expect(profile!.pointBalance, 15);
      expect(profile.totalPointsEarned, 15);
      expect(profile.lifetimeSpendPaise, 150000);
      expect(profile.tier, LoyaltyTier.bronze);
      expect(notifier.state.ledger.length, 1);
      expect(notifier.state.ledger.first.pointsEarned, 15);

      // Now redeem 10 points
      notifier.recordPointsRedeemed(
        customerId: 'cust-101',
        shopId: 'shop-01',
        billId: 'bill-502',
        pointsRedeemed: 10,
      );

      final updatedProfile = notifier.state.profiles['cust-101']!;
      expect(updatedProfile.pointBalance, 5);
      expect(updatedProfile.totalPointsRedeemed, 10);
      expect(notifier.state.ledger.length, 2);
    });
  });
}
