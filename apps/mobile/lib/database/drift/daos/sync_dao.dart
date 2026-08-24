import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [SyncQueueTable])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  /// Fetch pending sync operations ordered by creation time
  Future<List<SyncQueueData>> getPendingOperations({int limit = 25}) {
    return (select(syncQueueTable)
          ..where(
              (t) => t.status.equals('PENDING') | t.status.equals('RETRYING'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Watch count of pending operations for UI badge
  Stream<int> watchPendingCount() {
    final count = syncQueueTable.operationId.count();
    return (selectOnly(syncQueueTable)
          ..addColumns([count])
          ..where(syncQueueTable.status.equals('PENDING') |
              syncQueueTable.status.equals('RETRYING')))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  /// Enqueue an operation atomically
  Future<void> enqueueOperation(SyncQueueTableCompanion operation) async {
    await into(syncQueueTable).insertOnConflictUpdate(operation);
  }

  /// Mark operation as synced
  Future<void> markOperationSynced(String opId) {
    return (update(syncQueueTable)..where((t) => t.operationId.equals(opId)))
        .write(const SyncQueueTableCompanion(status: Value('SYNCED')));
  }

  /// Mark operation as in progress
  Future<void> markOperationInProgress(String opId) {
    return (update(syncQueueTable)..where((t) => t.operationId.equals(opId)))
        .write(const SyncQueueTableCompanion(status: Value('IN_PROGRESS')));
  }

  /// Mark operation permanently failed (e.g. 4xx validation error)
  Future<void> markOperationFailed(String opId, String error) {
    return (update(syncQueueTable)..where((t) => t.operationId.equals(opId)))
        .write(SyncQueueTableCompanion(
      status: const Value('FAILED'),
      lastError: Value(error),
    ));
  }

  /// Update retry count and last error on temporary failure
  Future<void> recordOperationFailure(String opId, String error) {
    return customUpdate(
      "UPDATE sync_queue SET retry_count = retry_count + 1, last_error = ?, status = 'PENDING' WHERE operation_id = ?",
      variables: [Variable.withString(error), Variable.withString(opId)],
      updates: {syncQueueTable},
    );
  }
}
