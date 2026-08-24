import 'package:flutter/widgets.dart';
import 'animation_config.dart';
import 'animation_durations.dart';

/// Convenient extensions on [BuildContext] for animation safety.
extension AnimationContextExtension on BuildContext {
  /// Whether the user requested reduced motion in system accessibility settings.
  bool get prefersReducedMotion => MediaQuery.of(this).disableAnimations;

  /// Returns [duration] or [Duration.zero] if reduced motion is preferred.
  Duration safeDuration(Duration duration) =>
      AnimationConfig.getSafeDuration(this, duration);

  /// Safe micro duration (<=120ms).
  Duration get microDuration => safeDuration(AnimationDurations.micro);

  /// Safe quick duration (<=180ms).
  Duration get quickDuration => safeDuration(AnimationDurations.quick);

  /// Safe standard duration (<=240ms).
  Duration get standardDuration => safeDuration(AnimationDurations.standard);
}
