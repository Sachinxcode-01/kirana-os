import '../../domain/models/purchase_history_filter.dart';
import '../../domain/models/purchase_model.dart';

class PurchaseLocalDataSource {
  final Map<String, PurchaseModel> _purchaseStore = {};

  Future<PurchaseModel?> getPurchaseById(String id) async {
    return _purchaseStore[id];
  }

  Future<List<PurchaseModel>> getShopPurchases(String shopId) async {
    final list =
        _purchaseStore.values.where((p) => p.shopId == shopId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<PurchaseHistoryResult> getPurchaseHistory(
    String shopId, {
    PurchaseHistoryFilter filter = const PurchaseHistoryFilter(),
  }) async {
    var filtered =
        _purchaseStore.values.where((p) => p.shopId == shopId).toList();

    // 1. Search Query Filter (Purchase #, Supplier Name, Supplier Ref)
    if (filter.search != null && filter.search!.trim().isNotEmpty) {
      final q = filter.search!.trim().toLowerCase();
      filtered = filtered.where((p) {
        final numMatch = p.purchaseNumber.toLowerCase().contains(q);
        final suppNameMatch =
            p.supplierName != null && p.supplierName!.toLowerCase().contains(q);
        final suppRefMatch = p.supplierReference != null &&
            p.supplierReference!.toLowerCase().contains(q);
        return numMatch || suppNameMatch || suppRefMatch;
      }).toList();
    }

    // 2. Status Filter (DRAFT, COMPLETED)
    if (filter.statusFilter != PurchaseStatusFilter.all) {
      final dbVal = filter.statusFilter.dbValue;
      if (dbVal != null) {
        filtered = filtered.where((p) => p.status == dbVal).toList();
      }
    }

    // 3. Supplier Filter
    if (filter.supplierId != null && filter.supplierId!.isNotEmpty) {
      filtered =
          filtered.where((p) => p.supplierId == filter.supplierId).toList();
    }

    // 4. Date Range Filter
    if (filter.dateRange != null) {
      final start = DateTime(
        filter.dateRange!.start.year,
        filter.dateRange!.start.month,
        filter.dateRange!.start.day,
      );
      final end = DateTime(
        filter.dateRange!.end.year,
        filter.dateRange!.end.month,
        filter.dateRange!.end.day,
        23,
        59,
        59,
      );
      filtered = filtered.where((p) {
        return p.createdAt
                .isAfter(start.subtract(const Duration(seconds: 1))) &&
            p.createdAt.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final totalCount = filtered.length;
    final startIndex = (filter.page - 1) * filter.pageSize;
    if (startIndex >= filtered.length) {
      return PurchaseHistoryResult(
        purchases: const [],
        hasMore: false,
        totalCount: totalCount,
        isOffline: true,
        isPartialOfflineHistory: true,
      );
    }

    final endIndex = (startIndex + filter.pageSize).clamp(0, filtered.length);
    final pagedList = filtered.sublist(startIndex, endIndex);

    return PurchaseHistoryResult(
      purchases: pagedList,
      hasMore: endIndex < filtered.length,
      totalCount: totalCount,
      isOffline: true,
      isPartialOfflineHistory: true,
    );
  }

  Future<void> saveDraft(PurchaseModel purchase) async {
    _purchaseStore[purchase.id] = purchase;
  }

  Future<void> deleteDraft(String id) async {
    _purchaseStore.remove(id);
  }
}
