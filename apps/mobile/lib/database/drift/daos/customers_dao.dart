import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/customers_table.dart';
import '../tables/bills_table.dart';
import '../tables/credit_transactions_table.dart';
import '../tables/sync_queue_table.dart';

part 'customers_dao.g.dart';

@DriftAccessor(
  tables: [
    CustomersTable,
    BillsTable,
    CreditTransactionsTable,
    SyncQueueTable,
  ],
)
class CustomersDao extends DatabaseAccessor<AppDatabase>
    with _$CustomersDaoMixin {
  CustomersDao(super.db);

  /// Watch all non-archived customers with search filter (by Name or Phone)
  Stream<List<CustomerData>> watchCustomers(String shopId,
      [String query = '']) {
    final selectQuery = select(customersTable)
      ..where((t) => t.shopId.equals(shopId) & t.isArchived.equals(false));

    if (query.isNotEmpty) {
      final cleanQuery = query.trim();
      selectQuery.where(
          (t) => t.name.like('%$cleanQuery%') | t.phone.like('%$cleanQuery%'));
    }

    return (selectQuery..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// Watch customers with positive debt (> 0) sorted by debt DESC
  Stream<List<CustomerData>> watchIndebtedCustomers(String shopId,
      [String query = '']) {
    final selectQuery = select(customersTable)
      ..where((t) =>
          t.shopId.equals(shopId) &
          t.isArchived.equals(false) &
          t.currentDebtPaise.isBiggerThan(Constant(BigInt.zero)));

    if (query.isNotEmpty) {
      final cleanQuery = query.trim();
      selectQuery.where(
          (t) => t.name.like('%$cleanQuery%') | t.phone.like('%$cleanQuery%'));
    }

    return (selectQuery
          ..orderBy([(t) => OrderingTerm.desc(t.currentDebtPaise)]))
        .watch();
  }

  /// Get single customer by ID
  Future<CustomerData?> getCustomerById(String id) {
    return (select(customersTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Find customer by shopId and phone number for duplicate checking
  Future<CustomerData?> findCustomerByPhone(String shopId, String phone) {
    return (select(customersTable)
          ..where((t) =>
              t.shopId.equals(shopId) &
              t.phone.equals(phone) &
              t.isArchived.equals(false)))
        .getSingleOrNull();
  }

  /// Get completed sales history for a specific customer
  Future<List<BillData>> getCustomerSalesHistory(
      String shopId, String customerId) {
    return (select(db.billsTable)
          ..where((t) =>
              t.shopId.equals(shopId) &
              t.customerId.equals(customerId) &
              t.paymentStatus.isIn(const ['paid', 'completed']) &
              t.isCancelled.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Stream of credit ledger transactions for a customer
  Stream<List<CreditTransactionData>> watchCreditTransactions(
      String shopId, String customerId) {
    return (select(creditTransactionsTable)
          ..where(
              (t) => t.shopId.equals(shopId) & t.customerId.equals(customerId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Get shop-wide credit summary (total debt paise and count of indebted customers)
  Future<({int totalDebtPaise, int indebtedCount})> getShopCreditSummary(
      String shopId) async {
    final result = await (select(customersTable)
          ..where((t) =>
              t.shopId.equals(shopId) &
              t.isArchived.equals(false) &
              t.currentDebtPaise.isBiggerThan(Constant(BigInt.zero))))
        .get();

    int totalPaise = 0;
    for (final c in result) {
      totalPaise += c.currentDebtPaise.toInt();
    }

    return (totalDebtPaise: totalPaise, indebtedCount: result.length);
  }

  /// Archive customer (soft delete)
  Future<void> archiveCustomer(String id) async {
    await (update(customersTable)..where((t) => t.id.equals(id))).write(
      const CustomersTableCompanion(
        isArchived: Value(true),
      ),
    );
  }

  /// Atomic Credit Settlement / Payment Collection
  Future<void> recordCreditPayment({
    required String customerId,
    required int amountPaise,
    required CreditTransactionsTableCompanion transactionRecord,
    required SyncQueueTableCompanion syncOp,
  }) async {
    await transaction(() async {
      // 1. Insert credit transaction
      await into(creditTransactionsTable).insert(transactionRecord);

      // 2. Decrement customer outstanding debt
      await customUpdate(
        'UPDATE customers SET current_debt_paise = current_debt_paise - ? WHERE id = ?',
        variables: [
          Variable.withBigInt(BigInt.from(amountPaise)),
          Variable.withString(customerId)
        ],
        updates: {customersTable},
      );

      // 3. Enlist in sync queue
      await into(syncQueueTable).insert(syncOp);
    });
  }

  /// Atomic Credit Sale (Udhaar given during checkout)
  Future<void> recordCreditSale({
    required String customerId,
    required int amountPaise,
    required CreditTransactionsTableCompanion transactionRecord,
    required SyncQueueTableCompanion syncOp,
  }) async {
    await transaction(() async {
      // 1. Insert credit transaction
      await into(creditTransactionsTable).insert(transactionRecord);

      // 2. Increment customer outstanding debt
      await customUpdate(
        'UPDATE customers SET current_debt_paise = current_debt_paise + ? WHERE id = ?',
        variables: [
          Variable.withBigInt(BigInt.from(amountPaise)),
          Variable.withString(customerId)
        ],
        updates: {customersTable},
      );

      // 3. Enlist in sync queue
      await into(syncQueueTable).insert(syncOp);
    });
  }

  /// Upsert customer
  Future<void> upsertCustomer(CustomersTableCompanion customer) async {
    await into(customersTable).insertOnConflictUpdate(customer);
  }

  /// Upsert credit transaction (e.g. from cloud sync)
  Future<void> upsertCreditTransaction(
      CreditTransactionsTableCompanion txn) async {
    await into(creditTransactionsTable).insertOnConflictUpdate(txn);
  }
}
