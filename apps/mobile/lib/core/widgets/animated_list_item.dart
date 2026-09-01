import 'package:flutter/material.dart';
import '../animation/animation_curves.dart';
import '../animation/animation_durations.dart';
import '../animation/animation_extensions.dart';

/// Performance-optimized staggered item entrance for ListView and GridView items.
/// Animates only initial visible items (index < 8) to preserve 60/120fps scrolling on large datasets.
class AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration? duration;

  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.duration,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    final animDuration = widget.duration ?? AnimationDurations.quick;
    _controller = AnimationController(
      vsync: this,
      duration: animDuration,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationCurves.enter,
      ),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationCurves.enter,
      ),
    );

    // Stagger delay only for the first 8 visible items
    if (widget.index < 8) {
      final delayMs = widget.index * 30;
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.prefersReducedMotion || widget.index >= 8) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
