import 'package:flutter/material.dart';
import '../animation/animation_curves.dart';
import '../animation/animation_extensions.dart';

/// Production-ready smooth state transition wrapper.
/// Transitions between Loading, Content, Empty, and Error states without jarring layout shifts.
class StateTransitionSwitcher extends StatelessWidget {
  final Widget child;
  final Duration? duration;
  final ValueKey? stateKey;

  const StateTransitionSwitcher({
    super.key,
    required this.child,
    this.duration,
    this.stateKey,
  });

  @override
  Widget build(BuildContext context) {
    if (context.prefersReducedMotion) {
      return child;
    }

    final effectiveDuration = duration ?? context.quickDuration;

    return AnimatedSwitcher(
      duration: effectiveDuration,
      switchInCurve: AnimationCurves.enter,
      switchOutCurve: AnimationCurves.exit,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: stateKey ?? child.key ?? ValueKey(child.runtimeType),
        child: child,
      ),
    );
  }
}
