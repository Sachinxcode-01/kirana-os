import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../database/drift/database.dart';
import '../network/connectivity_service.dart';
import '../network/connectivity_status.dart';
import '../utils/app_logger.dart';
import 'sync_retry_policy.dart';

/// Orchestrates background synchronization between local Drift SQLite queue and Supabase Cloud.
class SyncEngine {
  final AppDatabase _db;
  final ConnectivityService _connectivityService;
  final supabase.SupabaseClient? _supabaseClient;
  StreamSubscription<ConnectivityStatus>? _connSubscription;
  bool _isProcessing = false;

  SyncEngine({
    required AppDatabase db,
    required ConnectivityService connectivityService,
    supabase.SupabaseClient? supabaseClient,
  })  : _db = db,
        _connectivityService = connectivityService,
        _supabaseClient = supabaseClient;

  supabase.SupabaseClient get _supabase {
    if (_supabaseClient != null) return _supabaseClient;
    return supabase.Supabase.instance.client;
  }

  /// Initialize connectivity watcher and auto-sync triggers.
  void start() {
    _connSubscription = _connectivityService.statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        AppLogger.i('Network restored -> Triggering background sync queue',
            tag: 'SyncEngine');
        processPendingQueue();
      }
    });
    // Initial trigger
    processPendingQueue();
  }

  /// Process pending local queue in batches with exponential backoff & idempotency
  Future<void> processPendingQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final isOnline = await _connectivityService.isOnline();
      if (!isOnline) {
        AppLogger.d('Device is offline -> skipping sync execution',
            tag: 'SyncEngine');
        return;
      }

      final pendingOps = await _db.syncDao.getPendingOperations(limit: 25);
      if (pendingOps.isEmpty) {
        AppLogger.d('Sync queue is clear', tag: 'SyncEngine');
        return;
      }

      AppLogger.i('Processing ${pendingOps.length} pending sync operations',
          tag: 'SyncEngine');

      for (final op in pendingOps) {
        await _processSingleOperation(op);
      }
    } catch (e, st) {
      AppLogger.e('Unexpected sync queue processing error: $e',
          tag: 'SyncEngine', error: e, stackTrace: st);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processSingleOperation(SyncQueueData op) async {
    try {
      await _db.syncDao.markOperationInProgress(op.operationId);
      final payloadMap = jsonDecode(op.payload) as Map<String, dynamic>;

      // Dispatch to Supabase RPC / table based on entity
      try {
        final rpcPayload = [
          {
            'operation_id': op.operationId,
            'shop_id': op.shopId,
            'entity_type': op.entityType,
            'operation_type': op.operationType,
            'client_timestamp': op.createdAt.toIso8601String(),
            'payload': payloadMap,
          }
        ];

        await _supabase
            .rpc('process_sync_batch', params: {'p_operations': rpcPayload});
        await _db.syncDao.markOperationSynced(op.operationId);
        AppLogger.i(
            'Operation ${op.operationId} successfully synced (${op.entityType})',
            tag: 'SyncEngine');
      } catch (cloudErr) {
        if (SyncRetryPolicy.isPermanentFailure(cloudErr)) {
          AppLogger.e('Permanent failure for op ${op.operationId}: $cloudErr',
              tag: 'SyncEngine');
          await _db.syncDao
              .markOperationFailed(op.operationId, cloudErr.toString());
        } else {
          AppLogger.w(
              'Temporary failure for op ${op.operationId}, scheduling retry: $cloudErr',
              tag: 'SyncEngine');
          await _db.syncDao
              .recordOperationFailure(op.operationId, cloudErr.toString());
        }
      }
    } catch (e) {
      AppLogger.e('Failed to process queue item ${op.operationId}: $e',
          tag: 'SyncEngine');
      await _db.syncDao.recordOperationFailure(op.operationId, e.toString());
    }
  }

  Future<void> syncNow() => processPendingQueue();

  void dispose() {
    _connSubscription?.cancel();
  }
}
