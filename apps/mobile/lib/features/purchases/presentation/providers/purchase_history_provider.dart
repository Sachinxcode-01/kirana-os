import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/result.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/purchase_history_filter.dart';
import '../../domain/models/purchase_model.dart';
import 'purchase_provider.dart';

class PurchaseHistoryState {
  final List<PurchaseModel> purchases;
  final PurchaseHistoryFilter filter;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int totalCount;
  final bool isOffline;
  final bool isPartialOfflineHistory;
  final String? errorMessage;

  const PurchaseHistoryState({
    this.purchases = const [],
    this.filter = const PurchaseHistoryFilter(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.totalCount = 0,
    this.isOffline = false,
    this.isPartialOfflineHistory = false,
    this.errorMessage,
  });

  PurchaseHistoryState copyWith({
    List<PurchaseModel>? purchases,
    PurchaseHistoryFilter? filter,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? totalCount,
    bool? isOffline,
    bool? isPartialOfflineHistory,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PurchaseHistoryState(
      purchases: purchases ?? this.purchases,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
      isOffline: isOffline ?? this.isOffline,
      isPartialOfflineHistory:
          isPartialOfflineHistory ?? this.isPartialOfflineHistory,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PurchaseHistoryNotifier extends StateNotifier<PurchaseHistoryState> {
  final Ref _ref;

  PurchaseHistoryNotifier(this._ref) : super(const PurchaseHistoryState()) {
    loadPurchases(refresh: true);
  }

  Future<void> loadPurchases({bool refresh = false}) async {
    final authState = _ref.read(authNotifierProvider);
    final shopId = authState.activeShopId ?? 'shop_demo';
    final repo = _ref.read(purchaseRepositoryProvider);

    final currentFilter =
        refresh ? state.filter.copyWith(page: 1) : state.filter;

    state = state.copyWith(
      isLoading: refresh,
      filter: currentFilter,
      clearErrorMessage: true,
    );

    final res = await repo.getPurchaseHistory(
      shopId: shopId,
      filter: currentFilter,
    );

    switch (res) {
      case Success(:final data):
        state = state.copyWith(
          purchases: data.purchases,
          hasMore: data.hasMore,
          totalCount: data.totalCount,
          isOffline: data.isOffline,
          isPartialOfflineHistory: data.isPartialOfflineHistory,
          isLoading: false,
        );
      case ErrorResult(:final failure):
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final authState = _ref.read(authNotifierProvider);
    final shopId = authState.activeShopId ?? 'shop_demo';
    final repo = _ref.read(purchaseRepositoryProvider);

    final nextPage = state.filter.page + 1;
    final nextFilter = state.filter.copyWith(page: nextPage);

    state = state.copyWith(isLoadingMore: true, filter: nextFilter);

    final res = await repo.getPurchaseHistory(
      shopId: shopId,
      filter: nextFilter,
    );

    switch (res) {
      case Success(:final data):
        state = state.copyWith(
          purchases: [...state.purchases, ...data.purchases],
          hasMore: data.hasMore,
          totalCount: data.totalCount,
          isOffline: data.isOffline,
          isPartialOfflineHistory: data.isPartialOfflineHistory,
          isLoadingMore: false,
        );
      case ErrorResult(:final failure):
        state = state.copyWith(
          isLoadingMore: false,
          errorMessage: failure.message,
        );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        search: query,
        clearSearch: query.trim().isEmpty,
        page: 1,
      ),
    );
    loadPurchases(refresh: true);
  }

  void setStatusFilter(PurchaseStatusFilter status) {
    state = state.copyWith(
      filter: state.filter.copyWith(statusFilter: status, page: 1),
    );
    loadPurchases(refresh: true);
  }

  void setDateRange(DateTimeRange? dateRange) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        dateRange: dateRange,
        clearDateRange: dateRange == null,
        page: 1,
      ),
    );
    loadPurchases(refresh: true);
  }

  void setSupplierFilter(String? supplierId) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        supplierId: supplierId,
        clearSupplierId: supplierId == null || supplierId.isEmpty,
        page: 1,
      ),
    );
    loadPurchases(refresh: true);
  }

  void clearFilters() {
    state = state.copyWith(
      filter: const PurchaseHistoryFilter(),
    );
    loadPurchases(refresh: true);
  }
}

final purchaseHistoryNotifierProvider =
    StateNotifierProvider<PurchaseHistoryNotifier, PurchaseHistoryState>(
  (ref) => PurchaseHistoryNotifier(ref),
);
