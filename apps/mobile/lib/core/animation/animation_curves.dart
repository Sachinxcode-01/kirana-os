import 'package:flutter/animation.dart';

/// Centralized animation easing curves for KiranaOS.
abstract final class AnimationCurves {
  /// Standard easing for entrances (decelerating)
  static const Curve enter = Curves.easeOutCubic;

  /// Standard easing for exits (accelerating)
  static const Curve exit = Curves.easeInCubic;

  /// Snappy spring for button taps and badge increments
  static const Curve bounce = Curves.easeInOutBack;

  /// Smooth linear interpolation for progress indicators
  static const Curve linear = Curves.linear;
}
