import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/errors/result.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/domain/models/product_model.dart';
import '../../data/datasources/stock_local_data_source.dart';
import '../../data/datasources/stock_remote_data_source.dart';
import '../../data/repositories/stock_repository_impl.dart';
import '../../domain/models/stock_overview_model.dart';
import '../../domain/repositories/stock_repository.dart';

final stockLocalDataSourceProvider = Provider<StockLocalDataSource>((ref) {
  return StockLocalDataSource();
});

final stockRemoteDataSourceProvider = Provider<StockRemoteDataSource>((ref) {
  return StockRemoteDataSource();
});

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  final local = ref.watch(stockLocalDataSourceProvider);
  final remote = ref.watch(stockRemoteDataSourceProvider);
  final conn = ref.watch(connectivityServiceProvider);
  return StockRepositoryImpl(
    localDataSource: local,
    remoteDataSource: remote,
    connectivityService: conn,
  );
});

class StockOverviewState {
  final List<ProductModel> products;
  final StockOverviewFilter filter;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int totalCount;
  final int inStockCount;
  final int lowStockCount;
  final int outOfStockCount;
  final bool isOffline;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  const StockOverviewState({
    this.products = const [],
    this.filter = const StockOverviewFilter(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.totalCount = 0,
    this.inStockCount = 0,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.isOffline = false,
    this.lastSyncedAt,
    this.errorMessage,
  });

  StockOverviewState copyWith({
    List<ProductModel>? products,
    StockOverviewFilter? filter,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? totalCount,
    int? inStockCount,
    int? lowStockCount,
    int? outOfStockCount,
    bool? isOffline,
    DateTime? lastSyncedAt,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return StockOverviewState(
      products: products ?? this.products,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
      inStockCount: inStockCount ?? this.inStockCount,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      outOfStockCount: outOfStockCount ?? this.outOfStockCount,
      isOffline: isOffline ?? this.isOffline,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class StockOverviewNotifier extends StateNotifier<StockOverviewState> {
  final Ref _ref;
  StreamSubscription<ProductModel>? _realtimeSubscription;

  StockOverviewNotifier(this._ref) : super(const StockOverviewState()) {
    loadStock(refresh: true);
    _initRealtimeSubscription();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  void _initRealtimeSubscription() {
    final authState = _ref.read(authNotifierProvider);
    final shopId = authState.activeShopId ?? 'shop_demo';
    final repo = _ref.read(stockRepositoryProvider);

    _realtimeSubscription =
        repo.subscribeToStockUpdates(shopId).listen((updatedProduct) {
      updateProductInPlace(updatedProduct);
    });
  }

  Future<void> loadStock({bool refresh = false}) async {
    final authState = _ref.read(authNotifierProvider);
    final shopId = authState.activeShopId ?? 'shop_demo';
    final repo = _ref.read(stockRepositoryProvider);

    final currentFilter =
        refresh ? state.filter.copyWith(page: 1) : state.filter;

    state = state.copyWith(
      isLoading: refresh,
      filter: currentFilter,
      clearErrorMessage: true,
    );

    final res = await repo.getStockOverview(
      shopId: shopId,
      filter: currentFilter,
    );

    switch (res) {
      case Success(:final data):
        state = state.copyWith(
          products: data.products,
          totalCount: data.totalCount,
          inStockCount: data.inStockCount,
          lowStockCount: data.lowStockCount,
          outOfStockCount: data.outOfStockCount,
          hasMore: data.hasMore,
          isOffline: data.isOffline,
          lastSyncedAt: data.lastSyncedAt,
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
    final repo = _ref.read(stockRepositoryProvider);

    final nextPage = state.filter.page + 1;
    final nextFilter = state.filter.copyWith(page: nextPage);

    state = state.copyWith(isLoadingMore: true, filter: nextFilter);

    final res = await repo.getStockOverview(
      shopId: shopId,
      filter: nextFilter,
    );

    switch (res) {
      case Success(:final data):
        state = state.copyWith(
          products: [...state.products, ...data.products],
          hasMore: data.hasMore,
          totalCount: data.totalCount,
          isOffline: data.isOffline,
          lastSyncedAt: data.lastSyncedAt,
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
    loadStock(refresh: true);
  }

  void setStatusFilter(StockStatus? status) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        statusFilter: status,
        clearStatusFilter: status == null,
        page: 1,
      ),
    );
    loadStock(refresh: true);
  }

  void setCategoryFilter(String? categoryId) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        categoryId: categoryId,
        clearCategoryId: categoryId == null || categoryId.isEmpty,
        page: 1,
      ),
    );
    loadStock(refresh: true);
  }

  void clearFilters() {
    state = state.copyWith(
      filter: const StockOverviewFilter(),
    );
    loadStock(refresh: true);
  }

  void updateProductInPlace(ProductModel updated) {
    final list = List<ProductModel>.from(state.products);
    final index = list.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      list[index] = updated;
      state = state.copyWith(products: list);
    } else {
      loadStock(refresh: true);
    }
  }
}

final stockOverviewNotifierProvider =
    StateNotifierProvider<StockOverviewNotifier, StockOverviewState>(
  (ref) => StockOverviewNotifier(ref),
);
