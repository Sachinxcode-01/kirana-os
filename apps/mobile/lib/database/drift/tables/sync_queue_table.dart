import 'package:drift/drift.dart';

@DataClassName('SyncQueueData')
class SyncQueueTable extends Table {
  @override
  String get tableName => 'sync_queue';

  TextColumn get operationId => text()(); // Client UUID v4 (Idempotency Key)
  TextColumn get shopId => text()();
  TextColumn get entityType =>
      text()(); // 'bill', 'product', 'customer', 'credit_txn'
  TextColumn get entityId => text()();
  TextColumn get operationType => text()(); // 'CREATE', 'UPDATE', 'DELETE'
  TextColumn get payload => text()(); // JSON string
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get status => text()
      .withDefault(const Constant('PENDING'))(); // PENDING, SYNCED, FAILED

  @override
  Set<Column> get primaryKey => {operationId};
}
