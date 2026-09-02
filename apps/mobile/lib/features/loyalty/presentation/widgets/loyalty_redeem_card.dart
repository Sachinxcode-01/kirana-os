import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../providers/loyalty_provider.dart';

class LoyaltyRedeemCard extends ConsumerWidget {
  final int cartSubtotalPaise;

  const LoyaltyRedeemCard({
    super.key,
    required this.cartSubtotalPaise,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(loyaltySettingsProvider);
    final loyaltyState = ref.watch(loyaltyCheckoutNotifierProvider);
    final notifier = ref.read(loyaltyCheckoutNotifierProvider.notifier);

    if (!settings.isEnabled || loyaltyState.customerPoints <= 0) {
      return const SizedBox.shrink();
    }

    final double rupeeValue = (loyaltyState.customerPoints * settings.redemptionValuePaise) / 100.0;
    final bool canRedeem = loyaltyState.customerPoints >= settings.minPointsToRedeem;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: KiranaSpacing.xs),
      padding: const EdgeInsets.all(KiranaSpacing.md),
      decoration: BoxDecoration(
        color: KiranaColors.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: KiranaRadius.borderMd,
        border: Border.all(
          color: loyaltyState.isApplied
              ? KiranaColors.secondary
              : KiranaColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: KiranaColors.secondary, size: 20),
                  const SizedBox(width: KiranaSpacing.xs),
                  Text(
                    'Loyalty Points Balance',
                    style: KiranaTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: KiranaColors.neutral900,
                    ),
                  ),
                ],
              ),
              Text(
                '⭐ ${loyaltyState.customerPoints} pts (₹${rupeeValue.toStringAsFixed(2)})',
                style: KiranaTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: KiranaColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: KiranaSpacing.xs),
          if (loyaltyState.isApplied) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Applied: -₹${(loyaltyState.discountPaise / 100).toStringAsFixed(2)} Discount',
                  style: KiranaTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: KiranaColors.success,
                  ),
                ),
                TextButton(
                  onPressed: () => notifier.clearRedemption(),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: KiranaColors.error,
                  ),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ] else if (!canRedeem) ...[
            Text(
              'Minimum ${settings.minPointsToRedeem} points required to redeem rewards.',
              style: KiranaTypography.labelSmall.copyWith(
                color: KiranaColors.neutral600,
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Redeem points for instant discount on this bill.',
                    style: KiranaTypography.labelSmall.copyWith(
                      color: KiranaColors.neutral700,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => notifier.applyMaxRedemption(cartSubtotalPaise),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Redeem Max'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KiranaColors.secondary,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
