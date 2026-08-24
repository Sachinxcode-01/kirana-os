import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/customers_table.dart';
import '../tables/credit_transactions_table.dart';
import '../tables/sync_queue_table.dart';

part 'customers_dao.g.dart';

@DriftAccessor(
  tables: [
    CustomersTable,
    CreditTransactionsTable,
    SyncQueueTable,
  ],
)
class CustomersDao extends DatabaseAccessor<AppDatabase>
    with _$CustomersDaoMixin {
  CustomersDao(super.db);

  /// Watch all customers with search filter
  Stream<List<CustomerData>> watchCustomers(String shopId,
      [String query = '']) {
    final selectQuery = select(customersTable)
      ..where((t) => t.shopId.equals(shopId));

    if (query.isNotEmpty) {
      selectQuery
          .where((t) => t.name.like('%$query%') | t.phone.like('%$query%'));
    }

    return (selectQuery..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// Get single customer by ID
  Future<CustomerData?> getCustomerById(String id) {
    return (select(customersTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
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

  /// Upsert customer
  Future<void> upsertCustomer(CustomersTableCompanion customer) async {
    await into(customersTable).insertOnConflictUpdate(customer);
  }
}
