import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/suppliers_table.dart';
import '../tables/purchases_table.dart';
import '../tables/purchase_items_table.dart';
import '../tables/products_table.dart';
import '../tables/inventory_movements_table.dart';
import '../tables/sync_queue_table.dart';

part 'suppliers_dao.g.dart';

@DriftAccessor(
  tables: [
    SuppliersTable,
    PurchasesTable,
    PurchaseItemsTable,
    ProductsTable,
    InventoryMovementsTable,
    SyncQueueTable,
  ],
)
class SuppliersDao extends DatabaseAccessor<AppDatabase>
    with _$SuppliersDaoMixin {
  SuppliersDao(super.db);

  /// Stream of all active or archived suppliers with optional search filter
  Stream<List<SupplierData>> watchSuppliers(
    String shopId, {
    String query = '',
    bool includeArchived = false,
  }) {
    final selectQuery = select(suppliersTable)
      ..where((t) => t.shopId.equals(shopId));

    if (!includeArchived) {
      selectQuery.where((t) => t.isArchived.equals(false));
    }

    if (query.isNotEmpty) {
      final clean = query.trim();
      selectQuery.where((t) =>
          t.name.like('%$clean%') |
          t.phone.like('%$clean%') |
          t.gstin.like('%$clean%'));
    }

    return (selectQuery..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// Get single supplier by ID
  Future<SupplierData?> getSupplierById(String id) {
    return (select(suppliersTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Find supplier by phone for duplicate validation
  Future<SupplierData?> findSupplierByPhone(String shopId, String phone) {
    return (select(suppliersTable)
          ..where((t) =>
              t.shopId.equals(shopId) &
              t.phone.equals(phone) &
              t.isArchived.equals(false)))
        .getSingleOrNull();
  }

  /// Upsert supplier
  Future<void> upsertSupplier(SuppliersTableCompanion supplier) async {
    await into(suppliersTable).insertOnConflictUpdate(supplier);
  }

  /// Archive supplier
  Future<void> archiveSupplier(String id) async {
    await (update(suppliersTable)..where((t) => t.id.equals(id))).write(
      const SuppliersTableCompanion(isArchived: Value(true)),
    );
  }

  /// Atomic Record Stock Purchase (Inward Entry)
  /// - Inserts Purchase Header & Line Items
  /// - Automatically INCREASES product inventory stock count
  /// - Logs Inventory Movement ('purchase')
  /// - Increases Supplier Payable Debt Balance (if supplier attached)
  /// - Enlists in Sync Queue
  Future<void> recordPurchaseTransaction({
    required PurchasesTableCompanion purchase,
    required List<PurchaseItemsTableCompanion> items,
    required List<InventoryMovementsTableCompanion> movements,
    required List<({String productId, double qtyAdded})> stockUpdates,
    required SyncQueueTableCompanion syncOp,
    String? supplierId,
    int? totalPaise,
  }) async {
    await transaction(() async {
      // 1. Insert Purchase Record
      await into(purchasesTable).insert(purchase);

      // 2. Insert Purchase Line Items
      for (final item in items) {
        await into(purchaseItemsTable).insert(item);
      }

      // 3. Increment Product Inventory Stock Count
      for (final update in stockUpdates) {
        await customUpdate(
          'UPDATE products SET current_stock = current_stock + ? WHERE id = ?',
          variables: [
            Variable.withReal(update.qtyAdded),
            Variable.withString(update.productId),
          ],
          updates: {db.productsTable},
        );
      }

      // 4. Log Inventory Movements
      for (final movement in movements) {
        await into(db.inventoryMovementsTable).insert(movement);
      }

      // 5. Update Supplier Payable Balance (if supplier attached)
      if (supplierId != null && totalPaise != null && totalPaise > 0) {
        await customUpdate(
          'UPDATE suppliers SET current_balance_paise = current_balance_paise + ? WHERE id = ?',
          variables: [
            Variable.withBigInt(BigInt.from(totalPaise)),
            Variable.withString(supplierId),
          ],
          updates: {suppliersTable},
        );
      }

      // 6. Enlist in Sync Queue
      await into(syncQueueTable).insert(syncOp);
    });
  }

  /// Atomic Record Payment Paid to Supplier (Settlement)
  Future<void> recordSupplierPayment({
    required String supplierId,
    required int amountPaise,
    required SyncQueueTableCompanion syncOp,
  }) async {
    await transaction(() async {
      // Decrement supplier payable balance
      await customUpdate(
        'UPDATE suppliers SET current_balance_paise = current_balance_paise - ? WHERE id = ?',
        variables: [
          Variable.withBigInt(BigInt.from(amountPaise)),
          Variable.withString(supplierId),
        ],
        updates: {suppliersTable},
      );

      // Enlist sync operation
      await into(syncQueueTable).insert(syncOp);
    });
  }

  /// Stream of past purchase orders for shop
  Stream<List<PurchaseData>> watchPurchases(String shopId) {
    return (select(purchasesTable)
          ..where((t) => t.shopId.equals(shopId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Get purchase line items for a specific purchase
  Future<List<PurchaseItemData>> getPurchaseItems(String purchaseId) {
    return (select(purchaseItemsTable)
          ..where((t) => t.purchaseId.equals(purchaseId)))
        .get();
  }
}
