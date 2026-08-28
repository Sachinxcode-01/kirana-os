import '../../../../database/drift/database.dart';
import '../../domain/models/supplier_model.dart';

class SupplierLocalDataSource {
  final AppDatabase? _db;

  SupplierLocalDataSource([this._db]);

  Stream<List<SupplierData>> watchSuppliers(
    String shopId, {
    String query = '',
    bool includeArchived = false,
  }) {
    if (_db == null) return Stream.value([]);
    return _db.suppliersDao.watchSuppliers(
      shopId,
      query: query,
      includeArchived: includeArchived,
    );
  }

  Future<SupplierData?> getSupplierById(String id) async {
    if (_db == null) return null;
    return _db.suppliersDao.getSupplierById(id);
  }

  Future<SupplierData?> findSupplierByPhone(String shopId, String phone) async {
    if (_db == null) return null;
    return _db.suppliersDao.findSupplierByPhone(shopId, phone);
  }

  Future<List<SupplierModel>> getSuppliers(
    String shopId, {
    bool includeArchived = false,
    String? searchQuery,
  }) async {
    if (_db == null) return [];
    final list = await _db.suppliersDao
        .watchSuppliers(
          shopId,
          query: searchQuery ?? '',
          includeArchived: includeArchived,
        )
        .first;

    return list
        .map((s) => SupplierModel(
              id: s.id,
              shopId: s.shopId,
              name: s.name,
              contactPerson: s.contactPerson,
              phone: s.phone,
              email: s.email,
              address: s.address,
              gstin: s.gstin,
              notes: s.notes,
              currentBalancePaise: s.currentBalancePaise.toInt(),
              isArchived: s.isArchived,
              createdAt: s.createdAt,
              updatedAt: s.updatedAt,
            ))
        .toList();
  }

  Future<void> saveSupplier(SuppliersTableCompanion supplier) async {
    if (_db == null) return;
    await _db.suppliersDao.upsertSupplier(supplier);
  }

  Future<void> archiveSupplier(String id) async {
    if (_db == null) return;
    await _db.suppliersDao.archiveSupplier(id);
  }

  Future<void> recordPurchaseTransaction({
    required PurchasesTableCompanion purchase,
    required List<PurchaseItemsTableCompanion> items,
    required List<InventoryMovementsTableCompanion> movements,
    required List<({String productId, double qtyAdded})> stockUpdates,
    required SyncQueueTableCompanion syncOp,
    String? supplierId,
    int? totalPaise,
  }) async {
    if (_db == null) return;
    await _db.suppliersDao.recordPurchaseTransaction(
      purchase: purchase,
      items: items,
      movements: movements,
      stockUpdates: stockUpdates,
      syncOp: syncOp,
      supplierId: supplierId,
      totalPaise: totalPaise,
    );
  }

  Future<void> recordSupplierPayment({
    required String supplierId,
    required int amountPaise,
    required SyncQueueTableCompanion syncOp,
  }) async {
    if (_db == null) return;
    await _db.suppliersDao.recordSupplierPayment(
      supplierId: supplierId,
      amountPaise: amountPaise,
      syncOp: syncOp,
    );
  }

  Stream<List<PurchaseData>> watchPurchases(String shopId) {
    if (_db == null) return Stream.value([]);
    return _db.suppliersDao.watchPurchases(shopId);
  }

  Future<List<PurchaseItemData>> getPurchaseItems(String purchaseId) async {
    if (_db == null) return [];
    return _db.suppliersDao.getPurchaseItems(purchaseId);
  }
}
