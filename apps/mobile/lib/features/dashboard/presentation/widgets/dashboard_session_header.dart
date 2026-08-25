import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kirana_mobile/app/app_providers.dart';
import 'package:kirana_mobile/core/extensions/context_extensions.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/staff/domain/models/staff_member_model.dart';

class DashboardSessionHeader extends ConsumerWidget {
  const DashboardSessionHeader({super.key});

  String _formatRole(String? rawRole) {
    if (rawRole == null || rawRole.isEmpty) return 'OWNER';
    return StaffRoleExtension.fromString(rawRole).label;
  }

  Color _getRoleBadgeColor(String? rawRole) {
    final role = StaffRoleExtension.fromString(rawRole ?? 'owner');
    switch (role) {
      case StaffRole.owner:
        return KiranaColors.primary;
      case StaffRole.manager:
        return KiranaColors.secondary;
      case StaffRole.cashier:
        return KiranaColors.neutral700;
      case StaffRole.inventoryStaff:
        return Colors.teal;
    }
  }

  Widget _buildConnectivityBadge({
    required ConnectivityStatus connectivity,
    required int pendingSyncCount,
  }) {
    Color dotColor;
    String labelText;

    if (connectivity == ConnectivityStatus.offline) {
      dotColor = KiranaColors.warning;
      labelText = 'OFFLINE (Cached Data)';
    } else if (connectivity == ConnectivityStatus.syncing ||
        pendingSyncCount > 0) {
      dotColor = Colors.blue;
      labelText = pendingSyncCount > 0
          ? 'SYNCING ($pendingSyncCount pending)'
          : 'SYNCING...';
    } else if (connectivity == ConnectivityStatus.syncError) {
      dotColor = KiranaColors.error;
      labelText = 'SYNC ERROR';
    } else {
      dotColor = KiranaColors.success;
      labelText = 'ONLINE (Cloud Synced)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dotColor.withValues(alpha: 0.1),
        borderRadius: KiranaRadius.borderPill,
        border: Border.all(color: dotColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            labelText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: dotColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    final connectivity =
        ref.watch(connectivityStatusStreamProvider).valueOrNull ??
            ConnectivityStatus.online;
    final pendingSyncCount =
        ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;

    final userName = user?.displayName ?? user?.email ?? 'Store Owner';
    final shopName = authState.activeShopName ?? 'My Kirana Store';
    final roleLabel = _formatRole(user?.role);
    final roleColor = _getRoleBadgeColor(user?.role);
    final avatarUrl = user?.avatarUrl;

    if (context.isWideScreen) {
      // Wide Screen (Tablet / Desktop Expanded Header)
      return Container(
        padding: const EdgeInsets.all(KiranaSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: KiranaRadius.borderMd,
          border: Border.all(color: KiranaColors.neutral200),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () => context.push('/profile'),
              borderRadius: BorderRadius.circular(30),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: KiranaColors.primaryContainer,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                onBackgroundImageError: avatarUrl != null && avatarUrl.isNotEmpty
                    ? (e, st) {}
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: KiranaTypography.titleLarge.copyWith(
                          color: KiranaColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: KiranaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          shopName,
                          style: KiranaTypography.headlineMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: KiranaSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: KiranaRadius.borderPill,
                          border: Border.all(
                              color: roleColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Logged in as $userName (${user?.email ?? ''})',
                    style: KiranaTypography.bodyMedium
                        .copyWith(color: KiranaColors.neutral600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: KiranaSpacing.md),
            _buildConnectivityBadge(
              connectivity: connectivity,
              pendingSyncCount: pendingSyncCount,
            ),
          ],
        ),
      );
    }

    // Compact Mobile Header
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KiranaSpacing.md,
        vertical: KiranaSpacing.sm,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.push('/profile'),
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: KiranaColors.primaryContainer,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              onBackgroundImageError: avatarUrl != null && avatarUrl.isNotEmpty
                  ? (e, st) {}
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: KiranaTypography.titleMedium.copyWith(
                        color: KiranaColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: KiranaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        shopName,
                        style: KiranaTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: KiranaRadius.borderPill,
                        border:
                            Border.all(color: roleColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: roleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        userName,
                        style: KiranaTypography.bodySmall
                            .copyWith(color: KiranaColors.neutral600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildConnectivityBadge(
                      connectivity: connectivity,
                      pendingSyncCount: pendingSyncCount,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
