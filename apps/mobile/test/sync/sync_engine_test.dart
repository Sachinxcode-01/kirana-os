import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/sync/conflict_resolver.dart';
import 'package:kirana_mobile/core/sync/sync_retry_policy.dart';

void main() {
  group('Sync Retry Policy & Exponential Backoff', () {
    test('Calculates exponential backoff progression accurately', () {
      expect(SyncRetryPolicy.getBackoffDelay(0), Duration.zero);
      expect(SyncRetryPolicy.getBackoffDelay(1), const Duration(seconds: 2));
      expect(SyncRetryPolicy.getBackoffDelay(2), const Duration(seconds: 4));
      expect(SyncRetryPolicy.getBackoffDelay(3), const Duration(seconds: 8));
      expect(SyncRetryPolicy.getBackoffDelay(4), const Duration(seconds: 16));
      expect(SyncRetryPolicy.getBackoffDelay(5),
          const Duration(seconds: 60)); // capped at maxRetries/maxBackoff
      expect(SyncRetryPolicy.getBackoffDelay(6),
          const Duration(seconds: 60)); // capped at 60s
    });

    test('Identifies permanent vs temporary sync failures', () {
      expect(
          SyncRetryPolicy.isPermanentFailure(
              'invalid_foreign_key violation on customer_id'),
          isTrue);
      expect(
          SyncRetryPolicy.isPermanentFailure(
              'HTTP 400 Bad Request: Check constraint failed'),
          isTrue);
      expect(
          SyncRetryPolicy.isPermanentFailure(
              'SocketException: Connection timed out'),
          isFalse);
      expect(SyncRetryPolicy.isPermanentFailure('502 Bad Gateway'), isFalse);
    });
  });

  group('Conflict Resolution Strategies', () {
    test('Last-Write-Wins (LWW) preserves newer updates', () {
      final t1 = DateTime.utc(2026, 8, 24, 10, 0, 0);
      final t2 = DateTime.utc(2026, 8, 24, 10, 5, 0);

      expect(
        ConflictResolver.shouldOverwriteLocalProduct(
          localUpdatedAt: t1,
          remoteUpdatedAt: t2,
        ),
        isTrue,
      );

      expect(
        ConflictResolver.shouldOverwriteLocalProduct(
          localUpdatedAt: t2,
          remoteUpdatedAt: t1,
        ),
        isFalse,
      );
    });

    test('Additive stock delta calculation preserves multiple offline sales',
        () {
      const initialStock = 100.0;
      const saleQtyDelta = -5.5; // Sale of 5.5 kg

      final result = ConflictResolver.applyStockDelta(
        currentCloudStock: initialStock,
        localQuantityDelta: saleQtyDelta,
      );

      expect(result, 94.5);
    });

    test('Ledger balance summation computes correct outstanding debt', () {
      final credits = [
        10000,
        25000,
        5000
      ]; // ₹100 + ₹250 + ₹50 = ₹400 (40000 paise)
      final payments = [15000, 10000]; // ₹150 + ₹100 = ₹250 (25000 paise)

      final balance = ConflictResolver.computeLedgerBalance(
        creditsGivenPaise: credits,
        paymentsReceivedPaise: payments,
      );

      expect(balance, 15000); // ₹150 remaining debt
    });
  });
}
