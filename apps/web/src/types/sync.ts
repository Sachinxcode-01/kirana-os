/**
 * Shared Sync Contracts
 * Parallels packages/core_contracts/lib/sync/sync_payload.dart
 */

export type SyncEntityType =
  | "shop"
  | "product"
  | "category"
  | "customer"
  | "bill"
  | "payment"
  | "credit_transaction"
  | "inventory_movement"
  | "expense";

export type SyncOperationType = "CREATE" | "UPDATE" | "DELETE";

export type SyncQueueStatus = "PENDING" | "IN_PROGRESS" | "SYNCED" | "FAILED";

export interface SyncOperationContract {
  operationId: string; // Deterministic Client UUID v4 for idempotency
  shopId: string;
  entityType: SyncEntityType;
  entityId?: string;
  operationType: SyncOperationType;
  payload: Record<string, any>;
  clientTimestampEpochMs: number;
  retryCount?: number;
  lastError?: string;
  status?: SyncQueueStatus;
}

export interface SyncBatchResult {
  operation_id: string;
  status: "SYNCED" | "FAILED";
  error?: string;
  idempotent_duplicate?: boolean;
}
