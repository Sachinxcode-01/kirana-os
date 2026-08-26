enum AdjustmentReason {
  physicalCountCorrection('Physical Count Correction'),
  damaged('Damaged'),
  expired('Expired'),
  lost('Lost'),
  found('Found'),
  openingStock('Opening Stock'),
  other('Other');

  final String label;
  const AdjustmentReason(this.label);

  static AdjustmentReason fromString(String value) {
    for (final reason in AdjustmentReason.values) {
      if (reason.label.toLowerCase() == value.trim().toLowerCase() ||
          reason.name.toLowerCase() == value.trim().toLowerCase()) {
        return reason;
      }
    }
    return AdjustmentReason.other;
  }
}
