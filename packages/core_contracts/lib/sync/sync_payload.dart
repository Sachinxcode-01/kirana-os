/// Entity types supported by the offline sync queue.
enum SyncEntityType {
  shop('shop'),
  product('product'),
  category('category'),
  customer('customer'),
  bill('bill'),
  payment('payment'),
  creditTransaction('credit_transaction'),
  inventoryMovement('inventory_movement'),
  expense('expense');

  final String wireName;
  const SyncEntityType(this.wireName);

  static SyncEntityType fromWireName(String wireName) {
    return SyncEntityType.values.firstWhere(
      (e) => e.wireName == wireName,
      orElse: () => throw ArgumentError('Unknown SyncEntityType: $wireName'),
    );
  }
}

/// Operation types in the sync pipeline.
enum SyncOperationType {
  create('CREATE'),
  update('UPDATE'),
  delete('DELETE');

  final String wireName;
  const SyncOperationType(this.wireName);
}

/// State of an individual sync queue operation.
enum SyncQueueStatus {
  pending('PENDING'),
  inProgress('IN_PROGRESS'),
  synced('SYNCED'),
  failed('FAILED');

  final String wireName;
  const SyncQueueStatus(this.wireName);
}

/// Invariant definition of a sync queue item.
final class SyncOperationContract {
  final String operationId; // Client UUID v4 for idempotency
  final String shopId;
  final SyncEntityType entityType;
  final String entityId;
  final SyncOperationType operationType;
  final Map<String, dynamic> payload;
  final int clientTimestampEpochMs;
  final int retryCount;
  final String? lastError;
  final SyncQueueStatus status;

  const SyncOperationContract({
    required this.operationId,
    required this.shopId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payload,
    required this.clientTimestampEpochMs,
    this.retryCount = 0,
    this.lastError,
    this.status = SyncQueueStatus.pending,
  });
}
