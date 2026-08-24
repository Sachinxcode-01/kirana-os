/// Strategy handlers for offline-to-cloud data conflict resolution.
abstract final class ConflictResolver {
  /// Last-Write-Wins (LWW) resolution for master catalog attributes.
  static bool shouldOverwriteLocalProduct({
    required DateTime localUpdatedAt,
    required DateTime remoteUpdatedAt,
  }) {
    return remoteUpdatedAt.isAfter(localUpdatedAt);
  }

  /// Additive stock delta calculation to prevent offline sales overwriting cloud stock.
  static double applyStockDelta({
    required double currentCloudStock,
    required double localQuantityDelta,
  }) {
    return currentCloudStock + localQuantityDelta;
  }

  /// Ledger-derived balance summation for customer Khata accounts.
  static int computeLedgerBalance({
    required List<int> creditsGivenPaise,
    required List<int> paymentsReceivedPaise,
  }) {
    final totalCredit = creditsGivenPaise.fold(0, (sum, val) => sum + val);
    final totalPayment = paymentsReceivedPaise.fold(0, (sum, val) => sum + val);
    return totalCredit - totalPayment;
  }
}
