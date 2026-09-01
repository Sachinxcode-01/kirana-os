import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/loyalty_models.dart';

final loyaltyConfigProvider =
    StateProvider<LoyaltyProgramConfig>((ref) => const LoyaltyProgramConfig());

class LoyaltyState {
  final Map<String, CustomerLoyaltyProfile> profiles;
  final List<LoyaltyLedgerEntry> ledger;
  final bool isLoading;
  final String? errorMessage;

  const LoyaltyState({
    this.profiles = const {},
    this.ledger = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  LoyaltyState copyWith({
    Map<String, CustomerLoyaltyProfile>? profiles,
    List<LoyaltyLedgerEntry>? ledger,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LoyaltyState(
      profiles: profiles ?? this.profiles,
      ledger: ledger ?? this.ledger,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class LoyaltyNotifier extends StateNotifier<LoyaltyState> {
  LoyaltyNotifier() : super(const LoyaltyState());

  CustomerLoyaltyProfile getOrCreateProfile(String customerId, String shopId) {
    if (state.profiles.containsKey(customerId)) {
      return state.profiles[customerId]!;
    }
    final initial = CustomerLoyaltyProfile(
      customerId: customerId,
      shopId: shopId,
    );
    final updated = Map<String, CustomerLoyaltyProfile>.from(state.profiles)
      ..[customerId] = initial;
    state = state.copyWith(profiles: updated);
    return initial;
  }

  void recordPointsEarned({
    required String customerId,
    required String shopId,
    required String billId,
    required int pointsEarned,
    required int billAmountPaise,
    String? description,
  }) {
    if (pointsEarned <= 0) return;

    final profile = getOrCreateProfile(customerId, shopId);
    final newBalance = profile.pointBalance + pointsEarned;
    final newEarned = profile.totalPointsEarned + pointsEarned;
    final newSpend = profile.lifetimeSpendPaise + billAmountPaise;
    final newTier = LoyaltyTier.fromSpend(newSpend);

    final updatedProfile = profile.copyWith(
      pointBalance: newBalance,
      totalPointsEarned: newEarned,
      lifetimeSpendPaise: newSpend,
      tier: newTier,
      lastActivityAt: DateTime.now(),
    );

    final entry = LoyaltyLedgerEntry(
      id: 'lyt_${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId,
      shopId: shopId,
      billId: billId,
      pointsEarned: pointsEarned,
      pointsRedeemed: 0,
      balanceAfter: newBalance,
      description: description ?? 'Earned from Bill #$billId',
      createdAt: DateTime.now(),
    );

    final updatedProfiles =
        Map<String, CustomerLoyaltyProfile>.from(state.profiles)
          ..[customerId] = updatedProfile;

    state = state.copyWith(
      profiles: updatedProfiles,
      ledger: [entry, ...state.ledger],
    );
  }

  void recordPointsRedeemed({
    required String customerId,
    required String shopId,
    required String billId,
    required int pointsRedeemed,
    String? description,
  }) {
    if (pointsRedeemed <= 0) return;

    final profile = getOrCreateProfile(customerId, shopId);
    final newBalance = (profile.pointBalance - pointsRedeemed).clamp(0, 999999);
    final newRedeemed = profile.totalPointsRedeemed + pointsRedeemed;

    final updatedProfile = profile.copyWith(
      pointBalance: newBalance,
      totalPointsRedeemed: newRedeemed,
      lastActivityAt: DateTime.now(),
    );

    final entry = LoyaltyLedgerEntry(
      id: 'lyt_${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId,
      shopId: shopId,
      billId: billId,
      pointsEarned: 0,
      pointsRedeemed: pointsRedeemed,
      balanceAfter: newBalance,
      description: description ?? 'Redeemed on Bill #$billId',
      createdAt: DateTime.now(),
    );

    final updatedProfiles =
        Map<String, CustomerLoyaltyProfile>.from(state.profiles)
          ..[customerId] = updatedProfile;

    state = state.copyWith(
      profiles: updatedProfiles,
      ledger: [entry, ...state.ledger],
    );
  }
}

final loyaltyNotifierProvider =
    StateNotifierProvider<LoyaltyNotifier, LoyaltyState>((ref) {
  return LoyaltyNotifier();
});

final customerLoyaltyProfileProvider =
    Provider.family<CustomerLoyaltyProfile, ({String customerId, String shopId})>(
        (ref, params) {
  final state = ref.watch(loyaltyNotifierProvider);
  return state.profiles[params.customerId] ??
      CustomerLoyaltyProfile(
        customerId: params.customerId,
        shopId: params.shopId,
      );
});
