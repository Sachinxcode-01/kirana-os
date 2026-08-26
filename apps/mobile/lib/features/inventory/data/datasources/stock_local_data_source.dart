import '../../../products/domain/models/product_model.dart';
import '../../domain/models/stock_overview_model.dart';

class StockLocalDataSource {
  final Map<String, ProductModel> _productStore = {};
  final Map<String, List<String>> _productBarcodesMap = {};
  DateTime? _lastSyncedAt;

  DateTime? get lastSyncedAt => _lastSyncedAt;

  Future<void> saveProducts(List<ProductModel> products) async {
    for (final p in products) {
      _productStore[p.id] = p;
    }
    _lastSyncedAt = DateTime.now();
  }

  Future<void> saveProduct(ProductModel product) async {
    _productStore[product.id] = product;
    _lastSyncedAt = DateTime.now();
  }

  Future<ProductModel?> getProductById(String id) async {
    return _productStore[id];
  }

  Future<StockOverviewResult> getStockOverview(
    String shopId, {
    StockOverviewFilter filter = const StockOverviewFilter(),
  }) async {
    final allShopProducts = _productStore.values
        .where((p) => p.shopId == shopId && p.isActive)
        .toList();

    // Summary metrics before filtering
    final totalCount = allShopProducts.length;
    final inStockCount = allShopProducts
        .where((p) => p.stockStatus == StockStatus.inStock)
        .length;
    final lowStockCount = allShopProducts
        .where((p) => p.stockStatus == StockStatus.lowStock)
        .length;
    final outOfStockCount = allShopProducts
        .where((p) => p.stockStatus == StockStatus.outOfStock)
        .length;

    var filtered = List<ProductModel>.from(allShopProducts);

    // 1. Search filter (Name, Regional Name, HSN, Barcode)
    if (filter.search != null && filter.search!.trim().isNotEmpty) {
      final q = filter.search!.trim().toLowerCase();
      filtered = filtered.where((p) {
        final nameMatch = p.name.toLowerCase().contains(q);
        final regMatch =
            p.regionalName != null && p.regionalName!.toLowerCase().contains(q);
        final hsnMatch =
            p.hsnCode != null && p.hsnCode!.toLowerCase().contains(q);

        final barcodes = _productBarcodesMap[p.id] ?? const [];
        final barcodeMatch = barcodes.any((b) => b.toLowerCase().contains(q));

        return nameMatch || regMatch || hsnMatch || barcodeMatch;
      }).toList();
    }

    // 2. Status Filter
    if (filter.statusFilter != null) {
      filtered =
          filtered.where((p) => p.stockStatus == filter.statusFilter).toList();
    }

    // 3. Category Filter
    if (filter.categoryId != null && filter.categoryId!.isNotEmpty) {
      filtered =
          filtered.where((p) => p.categoryId == filter.categoryId).toList();
    }

    filtered.sort((a, b) => a.name.compareTo(b.name));

    final startIndex = (filter.page - 1) * filter.pageSize;
    if (startIndex >= filtered.length) {
      return StockOverviewResult(
        products: const [],
        totalCount: totalCount,
        inStockCount: inStockCount,
        lowStockCount: lowStockCount,
        outOfStockCount: outOfStockCount,
        hasMore: false,
        isOffline: true,
        lastSyncedAt: _lastSyncedAt,
      );
    }

    final endIndex = (startIndex + filter.pageSize).clamp(0, filtered.length);
    final pagedList = filtered.sublist(startIndex, endIndex);

    return StockOverviewResult(
      products: pagedList,
      totalCount: totalCount,
      inStockCount: inStockCount,
      lowStockCount: lowStockCount,
      outOfStockCount: outOfStockCount,
      hasMore: endIndex < filtered.length,
      isOffline: true,
      lastSyncedAt: _lastSyncedAt,
    );
  }
}
