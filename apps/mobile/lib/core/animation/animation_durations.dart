/// Centralized animation duration tokens for KiranaOS.
/// Strictly bounded between 100ms and 320ms to prevent POS checkout latency.
abstract final class AnimationDurations {
  /// Instant micro-interaction (Button press, checkbox tick, cart badge bounce)
  static const Duration micro = Duration(milliseconds: 120);

  /// Small UI transition (Accordion expand, bottom sheet slide, toast entry)
  static const Duration quick = Duration(milliseconds: 180);

  /// Standard screen transition & modal dialog presentation
  static const Duration standard = Duration(milliseconds: 240);

  /// Celebratory success checkmark animation
  static const Duration success = Duration(milliseconds: 320);

  /// Shimmer skeleton cycle duration
  static const Duration shimmer = Duration(milliseconds: 1200);
}
