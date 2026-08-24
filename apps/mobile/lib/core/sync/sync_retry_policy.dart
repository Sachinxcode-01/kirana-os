import 'dart:math';

/// Calculates exponential backoff schedules and classifies sync failures.
abstract final class SyncRetryPolicy {
  static const int maxRetries = 5;
  static const Duration initialBackoff = Duration(seconds: 2);
  static const Duration maxBackoff = Duration(seconds: 60);

  /// Calculates backoff delay based on retry count.
  static Duration getBackoffDelay(int retryCount) {
    if (retryCount <= 0) return Duration.zero;
    if (retryCount >= maxRetries) return maxBackoff;

    final exponentialSeconds =
        initialBackoff.inSeconds * pow(2, retryCount - 1).toInt();
    final clampedSeconds = min(exponentialSeconds, maxBackoff.inSeconds);
    return Duration(seconds: clampedSeconds);
  }

  /// Determines if an error is permanently non-retryable (e.g. 4xx validation).
  static bool isPermanentFailure(Object error) {
    final str = error.toString().toLowerCase();
    return str.contains('invalid_foreign_key') ||
        str.contains('check constraint') ||
        str.contains('400') ||
        str.contains('bad request');
  }
}
