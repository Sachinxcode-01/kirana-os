import 'package:flutter/material.dart';
import '../network/connectivity_status.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Global non-intrusive connectivity and sync status indicator banner.
class ConnectivityBanner extends StatelessWidget {
  final ConnectivityStatus status;
  final VoidCallback? onRetry;

  const ConnectivityBanner({
    super.key,
    required this.status,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (status == ConnectivityStatus.online) {
      return const SizedBox.shrink();
    }

    final (bgColor, icon, message) = switch (status) {
      ConnectivityStatus.offline => (
          KiranaColors.errorContainer,
          Icons.cloud_off,
          'Offline Mode — All billing saved locally'
        ),
      ConnectivityStatus.syncing => (
          KiranaColors.secondaryContainer,
          Icons.sync,
          'Syncing offline transactions with cloud...'
        ),
      ConnectivityStatus.syncError => (
          KiranaColors.warningContainer,
          Icons.sync_problem,
          'Sync error — Tap to retry'
        ),
      ConnectivityStatus.online => (
          KiranaColors.successContainer,
          Icons.cloud_done,
          'Online'
        ),
    };

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(
        horizontal: KiranaSpacing.lg,
        vertical: KiranaSpacing.xs,
      ),
      child: InkWell(
        onTap: onRetry,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: KiranaColors.textPrimary),
            const SizedBox(width: KiranaSpacing.sm),
            Text(
              message,
              style: KiranaTypography.labelSmall.copyWith(
                color: KiranaColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
