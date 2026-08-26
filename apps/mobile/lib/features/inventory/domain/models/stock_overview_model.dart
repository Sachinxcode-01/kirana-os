import '../../../products/domain/models/product_model.dart';

enum StockStatus {
  inStock,
  lowStock,
  outOfStock;

  String get label {
    switch (this) {
      case StockStatus.inStock:
        return 'IN STOCK';
      case StockStatus.lowStock:
        return 'LOW STOCK';
      case StockStatus.outOfStock:
        return 'OUT OF STOCK';
    }
  }

  static StockStatus fromQuantities(double current, double minAlert) {
    if (current <= 0) {
      return StockStatus.outOfStock;
    } else if (current <= minAlert) {
      return StockStatus.lowStock;
    } else {
      return StockStatus.inStock;
    }
  }
}

extension ProductStockStatusExt on ProductModel {
  StockStatus get stockStatus =>
      StockStatus.fromQuantities(currentStock, minStockAlert);
}

class StockOverviewFilter {
  final String? search;
  final StockStatus? statusFilter;
  final String? categoryId;
  final int page;
  final int pageSize;

  const StockOverviewFilter({
    this.search,
    this.statusFilter,
    this.categoryId,
    this.page = 1,
    this.pageSize = 20,
  });

  bool get hasActiveFilters =>
      (search != null && search!.trim().isNotEmpty) ||
      statusFilter != null ||
      (categoryId != null && categoryId!.isNotEmpty);

  StockOverviewFilter copyWith({
    String? search,
    bool clearSearch = false,
    StockStatus? statusFilter,
    bool clearStatusFilter = false,
    String? categoryId,
    bool clearCategoryId = false,
    int? page,
    int? pageSize,
  }) {
    return StockOverviewFilter(
      search: clearSearch ? null : (search ?? this.search),
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class StockOverviewResult {
  final List<ProductModel> products;
  final int totalCount;
  final int inStockCount;
  final int lowStockCount;
  final int outOfStockCount;
  final bool hasMore;
  final bool isOffline;
  final DateTime? lastSyncedAt;

  const StockOverviewResult({
    required this.products,
    required this.totalCount,
    required this.inStockCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.hasMore,
    this.isOffline = false,
    this.lastSyncedAt,
  });
}
