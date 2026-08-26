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

  /// Query historical bills with filtering and pagination
  Future<List<BillData>> getHistoricalBills({
    required String shopId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    String? cashierId,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final query = select(billsTable)..where((t) => t.shopId.equals(shopId));

    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim()}%';
      query.where((t) => t.billNumber.like(term));
    }

    if (startDate != null) {
      query.where((t) => t.createdAt.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      query.where((t) => t.createdAt.isSmallerOrEqualValue(endDate));
    }

    if (cashierId != null && cashierId.isNotEmpty) {
      query.where((t) => t.cashierId.equals(cashierId));
    }

    if (status != null && status.isNotEmpty) {
      if (status == 'cancelled') {
        query.where((t) => t.isCancelled.equals(true));
      } else if (status == 'completed') {
        query.where((t) =>
            t.isCancelled.equals(false) & t.paymentStatus.equals('paid'));
      }
    }

    query
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit, offset: offset);

    return query.get();
  }

  /// Get bill items for a specific bill ID
  Future<List<BillItemData>> getBillItemsForBill(String billId) {
    return (select(billItemsTable)..where((t) => t.billId.equals(billId)))
        .get();
  }

  /// Get payments for a specific bill ID
  Future<List<PaymentData>> getPaymentsForBill(String billId) {
    return (select(paymentsTable)..where((t) => t.billId.equals(billId))).get();
  }

  /// Save / update completed bill into local Drift database
  Future<void> upsertCompletedBill({
    required BillsTableCompanion bill,
    List<BillItemsTableCompanion> items = const [],
    List<PaymentsTableCompanion> payments = const [],
  }) async {
    await transaction(() async {
      await into(billsTable).insertOnConflictUpdate(bill);
      for (final item in items) {
        await into(billItemsTable).insertOnConflictUpdate(item);
      }
      for (final payment in payments) {
        await into(paymentsTable).insertOnConflictUpdate(payment);
      }
    });
  }
}
