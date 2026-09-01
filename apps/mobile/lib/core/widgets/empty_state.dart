import 'package:flutter/material.dart';
import '../animation/animation_curves.dart';
import '../animation/animation_durations.dart';
import '../animation/animation_extensions.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_button.dart';

/// Clean, production-grade empty state placeholder with subtle staggered entrance.
class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconOpacity;
  late final Animation<Offset> _iconSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _descriptionOpacity;
  late final Animation<double> _actionOpacity;
  late final Animation<double> _actionScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationDurations.standard,
    );

    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: AnimationCurves.enter),
      ),
    );

    _iconSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: AnimationCurves.enter),
      ),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.75, curve: AnimationCurves.enter),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.75, curve: AnimationCurves.enter),
      ),
    );

    _descriptionOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: AnimationCurves.enter),
      ),
    );

    _actionOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: AnimationCurves.enter),
      ),
    );

    _actionScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: AnimationCurves.enter),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.prefersReducedMotion) {
      return _buildStaticContent();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Staggered Icon Entrance
            SlideTransition(
              position: _iconSlide,
              child: FadeTransition(
                opacity: _iconOpacity,
                child: Container(
                  padding: const EdgeInsets.all(KiranaSpacing.xl),
                  decoration: const BoxDecoration(
                    color: KiranaColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 48,
                    color: KiranaColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: KiranaSpacing.lg),

            // 2. Staggered Title Entrance
            SlideTransition(
              position: _titleSlide,
              child: FadeTransition(
                opacity: _titleOpacity,
                child: Text(
                  widget.title,
                  style: KiranaTypography.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: KiranaSpacing.xs),

            // 3. Staggered Description Entrance
            FadeTransition(
              opacity: _descriptionOpacity,
              child: Text(
                widget.description,
                style: KiranaTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),

            // 4. Staggered CTA Action Entrance
            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: KiranaSpacing.xl),
              FadeTransition(
                opacity: _actionOpacity,
                child: ScaleTransition(
                  scale: _actionScale,
                  child: AppButton(
                    label: widget.actionLabel!,
                    onPressed: widget.onAction,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStaticContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(KiranaSpacing.xl),
              decoration: const BoxDecoration(
                color: KiranaColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                size: 48,
                color: KiranaColors.textMuted,
              ),
            ),
            const SizedBox(height: KiranaSpacing.lg),
            Text(
              widget.title,
              style: KiranaTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KiranaSpacing.xs),
            Text(
              widget.description,
              style: KiranaTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: KiranaSpacing.xl),
              AppButton(
                label: widget.actionLabel!,
                onPressed: widget.onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
