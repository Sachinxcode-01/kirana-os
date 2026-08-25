import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/app/app_providers.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/products/data/datasources/product_local_data_source.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';
import '../../data/datasources/inventory_local_data_source.dart';
import '../../data/datasources/inventory_remote_data_source.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/models/inventory_movement_model.dart';
import '../../domain/models/stock_adjustment_request.dart';
import '../../domain/models/stock_status.dart';
import '../../domain/repositories/inventory_repository.dart';

final inventoryLocalDataSourceProvider =
    Provider.autoDispose<InventoryLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return InventoryLocalDataSource(db);
});

final inventoryRemoteDataSourceProvider =
    Provider.autoDispose<InventoryRemoteDataSource>((ref) {
  return InventoryRemoteDataSource();
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final localDS = ref.watch(inventoryLocalDataSourceProvider);
  final remoteDS = ref.watch(inventoryRemoteDataSourceProvider);
  final db = ref.watch(databaseProvider);
  final productLocalDS = ProductLocalDataSource(db);

  return InventoryRepositoryImpl(
    localDataSource: localDS,
    remoteDataSource: remoteDS,
    productLocalDataSource: productLocalDS,
  );
});

// Low stock products provider
final lowStockProductsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  final shopId = ref.watch(activeShopIdProvider);
  if (shopId.isEmpty) return [];

  final result = await repo.getLowStockProducts(shopId);
  return result.dataOrNull ?? [];
});

// Inventory history state notifier
class InventoryHistoryState {
  final List<InventoryMovementModel> movements;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;

  const InventoryHistoryState({
    this.movements = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
  });

  InventoryHistoryState copyWith({
    List<InventoryMovementModel>? movements,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
  }) {
    return InventoryHistoryState(
      movements: movements ?? this.movements,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }
}

class InventoryHistoryNotifier extends StateNotifier<InventoryHistoryState> {
  final InventoryRepository _repository;
  final String _shopId;
  final String? _productId;
  int _offset = 0;
  static const int _limit = 20;

  InventoryHistoryNotifier(this._repository, this._shopId, this._productId)
      : super(const InventoryHistoryState()) {
    loadNextPage();
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.getInventoryHistory(
      shopId: _shopId,
      productId: _productId,
      limit: _limit,
      offset: _offset,
    );

    if (result.isSuccess) {
      final newItems = result.dataOrNull ?? [];
      _offset += newItems.length;

      state = state.copyWith(
        movements: [...state.movements, ...newItems],
        isLoading: false,
        hasMore: newItems.length >= _limit,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failureOrNull?.message ?? 'Failed to load history',
      );
    }
  }

  Future<void> refresh() async {
    _offset = 0;
    state = const InventoryHistoryState();
    await loadNextPage();
  }
}

final inventoryHistoryProvider = StateNotifierProvider.family
    .autoDispose<InventoryHistoryNotifier, InventoryHistoryState, String?>(
        (ref, productId) {
  final repo = ref.watch(inventoryRepositoryProvider);
  final shopId = ref.watch(activeShopIdProvider);

  return InventoryHistoryNotifier(repo, shopId, productId);
});

// Stock adjustment notifier
class StockAdjustmentNotifier extends StateNotifier<AsyncValue<void>> {
  final InventoryRepository _repository;
  final Ref _ref;

  StockAdjustmentNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> adjustStock(StockAdjustmentRequest request) async {
    state = const AsyncValue.loading();

    // Check RBAC permissions: Cashier role cannot modify inventory directly
    final currentUser = _ref.read(authNotifierProvider).user;
    if (currentUser?.role == 'cashier') {
      state = AsyncValue.error(
        'Permission denied: Cashiers cannot adjust inventory',
        StackTrace.current,
      );
      return false;
    }

    final result = await _repository.adjustStock(request);

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      _ref.invalidate(lowStockProductsProvider);
      return true;
    } else {
      state = AsyncValue.error(
        result.failureOrNull?.message ?? 'Stock adjustment failed',
        StackTrace.current,
      );
      return false;
    }
  }
}

final stockAdjustmentNotifierProvider = StateNotifierProvider.autoDispose<
    StockAdjustmentNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return StockAdjustmentNotifier(repo, ref);
});

// Inventory Search and Filtering Providers
final inventorySearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

final inventoryCategoryFilterProvider =
    StateProvider.autoDispose<String?>((ref) => null);

final inventoryStatusFilterProvider =
    StateProvider.autoDispose<StockStatusFilter>(
        (ref) => StockStatusFilter.all);

final inventoryFilteredProductsStreamProvider =
    StreamProvider.autoDispose<List<ProductModel>>((ref) {
  final shopId = ref.watch(activeShopIdProvider);
  final searchQuery = ref.watch(inventorySearchQueryProvider);
  final categoryId = ref.watch(inventoryCategoryFilterProvider);
  final statusFilter = ref.watch(inventoryStatusFilterProvider);

  if (shopId.isEmpty) {
    return Stream.value([]);
  }

  final db = ref.watch(databaseProvider);
  final productLocalDS = ProductLocalDataSource(db);

  return productLocalDS.watchProducts(
    shopId,
    searchQuery: searchQuery,
    categoryId: categoryId,
    statusFilter: statusFilter,
  );
});

// Stock settings update notifier (Min/Max Stock)
class InventorySettingsNotifier extends StateNotifier<AsyncValue<void>> {
  final InventoryRepository _repository;
  final Ref _ref;

  InventorySettingsNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> updateStockSettings({
    required String productId,
    required double minStockAlert,
    double? maxStockAlert,
  }) async {
    state = const AsyncValue.loading();

    // Enforce RBAC security rules: Cashier cannot modify stock settings
    final currentUser = _ref.read(authNotifierProvider).user;
    if (currentUser?.role == 'cashier') {
      state = AsyncValue.error(
        'Permission denied: Only authorized roles (owners/managers) can modify stock settings',
        StackTrace.current,
      );
      return false;
    }

    if (minStockAlert < 0) {
      state = AsyncValue.error(
        'Minimum stock level cannot be negative',
        StackTrace.current,
      );
      return false;
    }

    if (maxStockAlert != null && maxStockAlert < 0) {
      state = AsyncValue.error(
        'Maximum stock level cannot be negative',
        StackTrace.current,
      );
      return false;
    }

    if (maxStockAlert != null && maxStockAlert < minStockAlert) {
      state = AsyncValue.error(
        'Maximum stock level must be greater than or equal to minimum stock level',
        StackTrace.current,
      );
      return false;
    }

    final result = await _repository.updateStockSettings(
      productId: productId,
      minStockAlert: minStockAlert,
      maxStockAlert: maxStockAlert,
    );

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      _ref.invalidate(lowStockProductsProvider);
      _ref.invalidate(inventoryFilteredProductsStreamProvider);
      return true;
    } else {
      state = AsyncValue.error(
        result.failureOrNull?.message ?? 'Failed to update stock settings',
        StackTrace.current,
      );
      return false;
    }
  }
}

final inventorySettingsNotifierProvider = StateNotifierProvider.autoDispose<
    InventorySettingsNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return InventorySettingsNotifier(repo, ref);
});
