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
          ..where((t) => t.status.equals('PENDING'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Watch count of pending operations for UI badge
  Stream<int> watchPendingCount() {
    final count = syncQueueTable.operationId.count();
    return (selectOnly(syncQueueTable)
          ..addColumns([count])
          ..where(syncQueueTable.status.equals('PENDING')))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  /// Mark operation as synced
  Future<void> markOperationSynced(String opId) {
    return (update(syncQueueTable)..where((t) => t.operationId.equals(opId)))
        .write(const SyncQueueTableCompanion(status: Value('SYNCED')));
  }

  /// Update retry count and last error on failure
  Future<void> recordOperationFailure(String opId, String error) {
    return customUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1, last_error = ? WHERE operation_id = ?',
      variables: [Variable.withString(error), Variable.withString(opId)],
      updates: {syncQueueTable},
    );
  }
}
