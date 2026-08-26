import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/result.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/bill_history_filter.dart';
import '../../domain/models/bill_model.dart';
import 'billing_provider.dart';

class BillHistoryState {
  final BillHistoryFilter filter;
  final List<BillModel> bills;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool isOffline;
  final bool isPartialOfflineHistory;
  final String? errorMessage;
  final BillModel? selectedBill;

  const BillHistoryState({
    required this.filter,
    this.bills = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.isOffline = false,
    this.isPartialOfflineHistory = false,
    this.errorMessage,
    this.selectedBill,
  });

  BillHistoryState copyWith({
    BillHistoryFilter? filter,
    List<BillModel>? bills,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    bool? isOffline,
    bool? isPartialOfflineHistory,
    String? errorMessage,
    bool clearErrorMessage = false,
    BillModel? selectedBill,
    bool clearSelectedBill = false,
  }) {
    return BillHistoryState(
      filter: filter ?? this.filter,
      bills: bills ?? this.bills,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      isOffline: isOffline ?? this.isOffline,
      isPartialOfflineHistory:
          isPartialOfflineHistory ?? this.isPartialOfflineHistory,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      selectedBill:
          clearSelectedBill ? null : (selectedBill ?? this.selectedBill),
    );
  }
}

class BillHistoryNotifier extends StateNotifier<BillHistoryState> {
  final Ref _ref;
  Timer? _debounceTimer;

  BillHistoryNotifier(this._ref)
      : super(const BillHistoryState(filter: BillHistoryFilter())) {
    loadBills();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> loadBills({bool refresh = false}) async {
    final authState = _ref.read(authNotifierProvider);
    final shopId = authState.activeShopId;
    final user = authState.user;

    if (shopId == null || shopId.isEmpty || user == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No active shop context.',
      );
      return;
    }

    final targetFilter =
        refresh ? state.filter.copyWith(page: 0) : state.filter;

    state = state.copyWith(
      isLoading: targetFilter.page == 0,
      isLoadingMore: targetFilter.page > 0,
      clearErrorMessage: true,
    );

    final repo = _ref.read(billingRepositoryProvider);
    final result = await repo.getBillHistory(
      shopId: shopId,
      userRole: user.role,
      currentUserId: user.id,
      filter: targetFilter,
    );

    switch (result) {
      case Success(:final data):
        final newBills = targetFilter.page == 0
            ? data.bills
            : [...state.bills, ...data.bills];

        state = state.copyWith(
          filter: targetFilter,
          bills: newBills,
          isLoading: false,
          isLoadingMore: false,
          hasMore: data.hasMore,
          isOffline: data.isOffline,
          isPartialOfflineHistory: data.isPartialOfflineHistory,
          clearErrorMessage: true,
        );

      case ErrorResult(:final failure):
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          errorMessage: failure.message,
        );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(
      filter: state.filter.copyWith(page: state.filter.page + 1),
    );
    await loadBills();
  }

  void setSearch(String search) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(
        filter: state.filter.copyWith(
          search: search,
          clearSearch: search.trim().isEmpty,
          page: 0,
        ),
      );
      loadBills();
    });
  }

  void setDateRange(DateTimeRange? range) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        dateRange: range,
        clearDateRange: range == null,
        page: 0,
      ),
    );
    loadBills();
  }

  void setPaymentFilter(PaymentFilter paymentFilter) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        paymentFilter: paymentFilter,
        page: 0,
      ),
    );
    loadBills();
  }

  void setStatusFilter(BillStatusFilter statusFilter) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        statusFilter: statusFilter,
        page: 0,
      ),
    );
    loadBills();
  }

  void setCashierFilter(String? cashierId) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        cashierId: cashierId,
        clearCashierId: cashierId == null || cashierId.isEmpty,
        page: 0,
      ),
    );
    loadBills();
  }

  void resetFilters() {
    state = state.copyWith(
      filter: const BillHistoryFilter(),
    );
    loadBills();
  }

  void selectBill(BillModel? bill) {
    state = state.copyWith(
      selectedBill: bill,
      clearSelectedBill: bill == null,
    );
  }
}

final billHistoryNotifierProvider =
    StateNotifierProvider<BillHistoryNotifier, BillHistoryState>((ref) {
  return BillHistoryNotifier(ref);
});
