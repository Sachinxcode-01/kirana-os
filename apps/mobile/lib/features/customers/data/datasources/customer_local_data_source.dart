import '../../../../database/drift/database.dart';

class CustomerLocalDataSource {
  final AppDatabase _db;

  CustomerLocalDataSource(this._db);

  Stream<List<CustomerData>> watchCustomers(String shopId,
      [String query = '']) {
    return _db.customersDao.watchCustomers(shopId, query);
  }

  Stream<List<CustomerData>> watchIndebtedCustomers(String shopId,
      [String query = '']) {
    return _db.customersDao.watchIndebtedCustomers(shopId, query);
  }

  Stream<List<CreditTransactionData>> watchCreditTransactions(
      String shopId, String customerId) {
    return _db.customersDao.watchCreditTransactions(shopId, customerId);
  }

  Future<CustomerData?> getCustomerById(String id) {
    return _db.customersDao.getCustomerById(id);
  }

  Future<CustomerData?> findCustomerByPhone(String shopId, String phone) {
    return _db.customersDao.findCustomerByPhone(shopId, phone);
  }

  Future<List<BillData>> getCustomerSalesHistory(
      String shopId, String customerId) {
    return _db.customersDao.getCustomerSalesHistory(shopId, customerId);
  }

  Future<({int totalDebtPaise, int indebtedCount})> getShopCreditSummary(
      String shopId) {
    return _db.customersDao.getShopCreditSummary(shopId);
  }

  Future<void> upsertCustomer(CustomersTableCompanion customer) {
    return _db.customersDao.upsertCustomer(customer);
  }

  Future<void> archiveCustomer(String id) {
    return _db.customersDao.archiveCustomer(id);
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

  Future<void> recordCreditSale({
    required String customerId,
    required int amountPaise,
    required CreditTransactionsTableCompanion transactionRecord,
    required SyncQueueTableCompanion syncOp,
  }) {
    return _db.customersDao.recordCreditSale(
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
