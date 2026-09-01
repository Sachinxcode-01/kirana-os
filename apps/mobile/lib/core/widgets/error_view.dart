import 'package:flutter/material.dart';
import '../animation/animation_curves.dart';
import '../animation/animation_durations.dart';
import '../animation/animation_extensions.dart';
import '../errors/failure.dart';
import '../errors/error_handler.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_button.dart';

/// Clean, non-intrusive full-screen or card-level error state display with subtle entrance feedback.
class ErrorView extends StatefulWidget {
  final Failure? failure;
  final String? customMessage;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    this.failure,
    this.customMessage,
    this.onRetry,
  });

  @override
  State<ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<ErrorView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconScale;
  late final Animation<double> _contentOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationDurations.standard,
    );

    _iconScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: AnimationCurves.enter),
      ),
    );

    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: AnimationCurves.enter),
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
    final message = widget.customMessage ??
        (widget.failure != null
            ? ErrorHandler.getUserMessage(widget.failure!)
            : 'Something went wrong.');

    if (context.prefersReducedMotion) {
      return _buildStaticContent(message);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _iconScale,
              child: Container(
                padding: const EdgeInsets.all(KiranaSpacing.lg),
                decoration: const BoxDecoration(
                  color: KiranaColors.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: KiranaColors.error,
                ),
              ),
            ),
            const SizedBox(height: KiranaSpacing.lg),
            FadeTransition(
              opacity: _contentOpacity,
              child: Column(
                children: [
                  Text(
                    'Unable to Complete Request',
                    style: KiranaTypography.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KiranaSpacing.sm),
                  Text(
                    message,
                    style: KiranaTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (widget.onRetry != null) ...[
                    const SizedBox(height: KiranaSpacing.xl),
                    AppButton(
                      label: 'Try Again',
                      icon: Icons.refresh_rounded,
                      onPressed: widget.onRetry,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticContent(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(KiranaSpacing.lg),
              decoration: const BoxDecoration(
                color: KiranaColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: KiranaColors.error,
              ),
            ),
            const SizedBox(height: KiranaSpacing.lg),
            Text(
              'Unable to Complete Request',
              style: KiranaTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KiranaSpacing.sm),
            Text(
              message,
              style: KiranaTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: KiranaSpacing.xl),
              AppButton(
                label: 'Try Again',
                icon: Icons.refresh_rounded,
                onPressed: widget.onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
