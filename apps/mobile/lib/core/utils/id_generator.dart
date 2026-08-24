import 'package:uuid/uuid.dart';
import 'date_formatter.dart';

/// Cryptographically random ID and sequence generator for POS records.
abstract final class IdGenerator {
  static const Uuid _uuid = Uuid();

  /// Generates a standard UUID v4 string.
  static String generateUuid() => _uuid.v4();

  /// Generates an idempotent operation ID for sync items.
  static String generateSyncOpId() => _uuid.v4();

  /// Generates a human-readable unique bill number (e.g. "INV-20260824-9182").
  static String generateBillNumber([DateTime? date]) {
    final now = date ?? DateTime.now();
    final datePrefix = DateFormatter.formatForBillNumber(now);
    final randomSuffix = (1000 + (DateTime.now().microsecond % 9000)).toString();
    return 'INV-$datePrefix-$randomSuffix';
  }
}
