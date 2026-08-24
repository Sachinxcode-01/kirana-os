import '../../../../database/drift/database.dart';

class CustomerLocalDataSource {
  final AppDatabase _db;

  CustomerLocalDataSource(this._db);

  Stream<List<CustomerData>> watchCustomers(String shopId,
      [String query = '']) {
    return _db.customersDao.watchCustomers(shopId, query);
  }

  Future<CustomerData?> getCustomerById(String id) {
    return _db.customersDao.getCustomerById(id);
  }

  Future<void> upsertCustomer(CustomersTableCompanion customer) {
    return _db.customersDao.upsertCustomer(customer);
  }

  Future<void> recordCreditPayment({
    required String customerId,
    required int amountPaise,
    required CreditTransactionsTableCompanion transactionRecord,
    required SyncQueueTableCompanion syncOp,
  }) {
    return _db.customersDao.recordCreditPayment(
      customerId: customerId,
      amountPaise: amountPaise,
      transactionRecord: transactionRecord,
      syncOp: syncOp,
    );
  }

  Future<void> enqueueSyncOperation(SyncQueueTableCompanion syncOp) {
    return _db.syncDao.enqueueOperation(syncOp);
  }
}
