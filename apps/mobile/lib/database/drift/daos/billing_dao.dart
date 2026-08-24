import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/bills_table.dart';
import '../tables/bill_items_table.dart';
import '../tables/payments_table.dart';
import '../tables/products_table.dart';
import '../tables/sync_queue_table.dart';

part 'billing_dao.g.dart';

@DriftAccessor(
  tables: [
    BillsTable,
    BillItemsTable,
    PaymentsTable,
    ProductsTable,
    SyncQueueTable,
  ],
)
class BillingDao extends DatabaseAccessor<AppDatabase> with _$BillingDaoMixin {
  BillingDao(super.db);

  /// Atomic Checkout Transaction: Saves bill, items, payments, decrements stock, and enlists in sync queue.
  Future<void> createBillTransaction({
    required BillsTableCompanion bill,
    required List<BillItemsTableCompanion> items,
    required List<PaymentsTableCompanion> payments,
    required SyncQueueTableCompanion syncOp,
  }) async {
    await transaction(() async {
      // 1. Insert Bill Record
      await into(billsTable).insert(bill);

      // 2. Insert Bill Items & Decrement Local Stock
      for (final item in items) {
        await into(billItemsTable).insert(item);

        // Decrement Product Stock
        final productId = item.productId.value;
        final qty = item.quantity.value;
        await customUpdate(
          'UPDATE products SET current_stock = current_stock - ? WHERE id = ?',
          variables: [Variable.withReal(qty), Variable.withString(productId)],
          updates: {productsTable},
        );
      }

      // 3. Insert Payment Records
      for (final payment in payments) {
        await into(paymentsTable).insert(payment);
      }

      // 4. Enlist in Outbound Sync Queue
      await into(syncQueueTable).insert(syncOp);
    });
  }

  /// Watch recent bills for history view
  Stream<List<BillData>> watchRecentBills(String shopId) {
    return (select(billsTable)
          ..where((t) => t.shopId.equals(shopId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(50))
        .watch();
  }
}
