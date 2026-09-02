import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/loyalty_models.dart';
import '../../domain/services/loyalty_calculator.dart';

final loyaltySettingsProvider = StateProvider<LoyaltySettingsModel>((ref) {
  return const LoyaltySettingsModel();
});

class LoyaltyCheckoutState {
  final int customerPoints;
  final int pointsToRedeem;
  final int discountPaise;
  final bool isApplied;

  const LoyaltyCheckoutState({
    this.customerPoints = 0,
    this.pointsToRedeem = 0,
    this.discountPaise = 0,
    this.isApplied = false,
  });

  LoyaltyCheckoutState copyWith({
    int? customerPoints,
    int? pointsToRedeem,
    int? discountPaise,
    bool? isApplied,
  }) {
    return LoyaltyCheckoutState(
      customerPoints: customerPoints ?? this.customerPoints,
      pointsToRedeem: pointsToRedeem ?? this.pointsToRedeem,
      discountPaise: discountPaise ?? this.discountPaise,
      isApplied: isApplied ?? this.isApplied,
    );
  }
}

class LoyaltyCheckoutNotifier extends StateNotifier<LoyaltyCheckoutState> {
  final Ref _ref;

  LoyaltyCheckoutNotifier(this._ref) : super(const LoyaltyCheckoutState());

  void setCustomerPoints(int points) {
    state = state.copyWith(customerPoints: points, pointsToRedeem: 0, discountPaise: 0, isApplied: false);
  }

  void applyMaxRedemption(int cartSubtotalPaise) {
    final settings = _ref.read(loyaltySettingsProvider);
    if (!settings.isEnabled) return;

    final maxPoints = LoyaltyCalculator.maxRedeemablePoints(
      availablePoints: state.customerPoints,
      cartSubtotalPaise: cartSubtotalPaise,
      redemptionValuePaise: settings.redemptionValuePaise,
      minPointsThreshold: settings.minPointsToRedeem,
    );

    final discount = LoyaltyCalculator.calculateDiscountPaise(
      pointsToRedeem: maxPoints,
      redemptionValuePaise: settings.redemptionValuePaise,
    );

    state = state.copyWith(
      pointsToRedeem: maxPoints,
      discountPaise: discount,
      isApplied: maxPoints > 0,
    );
  }

  void clearRedemption() {
    state = state.copyWith(pointsToRedeem: 0, discountPaise: 0, isApplied: false);
  }
}

final loyaltyCheckoutNotifierProvider =
    StateNotifierProvider<LoyaltyCheckoutNotifier, LoyaltyCheckoutState>((ref) {
  return LoyaltyCheckoutNotifier(ref);
});
