import 'package:flutter/material.dart';
import '../errors/failure.dart';
import '../errors/error_handler.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_button.dart';

/// Clean, non-intrusive full-screen or card-level error state display.
class ErrorView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final message = customMessage ??
        (failure != null
            ? ErrorHandler.getUserMessage(failure!)
            : 'Something went wrong.');

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
            if (onRetry != null) ...[
              const SizedBox(height: KiranaSpacing.xl),
              AppButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
