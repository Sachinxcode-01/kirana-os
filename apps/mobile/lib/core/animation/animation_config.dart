import 'package:flutter/widgets.dart';
import 'animation_curves.dart';
import 'animation_durations.dart';

/// Global animation configuration and accessibility enforcement.
abstract final class AnimationConfig {
  /// Whether animations are globally enabled (defaults to true).
  static bool enableAnimations = true;

  /// Returns whether animations should run based on system and app flags.
  static bool shouldAnimate(BuildContext context) {
    if (!enableAnimations) return false;
    return !MediaQuery.of(context).disableAnimations;
  }

  /// Returns the safe duration, respecting reduced motion settings.
  static Duration getSafeDuration(BuildContext context, Duration duration) {
    return shouldAnimate(context) ? duration : Duration.zero;
  }

  /// Default transition curve.
  static const Curve defaultCurve = AnimationCurves.enter;

  /// Default micro duration.
  static const Duration defaultMicro = AnimationDurations.micro;
}
