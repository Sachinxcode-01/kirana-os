import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/shop/presentation/providers/shop_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final shopId = authState.activeShopId ?? '';
    final shopDetailsAsync = ref.watch(currentShopDetailsProvider(shopId));

    final displayName = user?.displayName ?? user?.email ?? 'Store Owner';
    final email = user?.email ?? '';
    final role = (user?.role ?? 'owner').toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner & Store Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KiranaSpacing.lg),
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: KiranaColors.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: KiranaColors.primary,
                  ),
                ),
                const SizedBox(height: KiranaSpacing.md),
                Text(
                  displayName,
                  style: KiranaTypography.titleLarge
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(email,
                    style: KiranaTypography.bodyMedium
                        .copyWith(color: KiranaColors.neutral600)),
                const SizedBox(height: KiranaSpacing.xs),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: KiranaColors.primary.withValues(alpha: 0.1),
                    borderRadius: KiranaRadius.borderPill,
                    border: Border.all(
                        color: KiranaColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'ROLE: $role',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: KiranaColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KiranaSpacing.xl),

          // Store Details Card
          Text(
            'Store Details',
            style: KiranaTypography.titleMedium
                .copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: KiranaSpacing.sm),
          shopDetailsAsync.when(
            data: (shop) => Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.storefront,
                        color: KiranaColors.primary),
                    title: const Text('Store Name'),
                    subtitle: Text(shop?.name ??
                        authState.activeShopName ??
                        'Not Configured'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.phone, color: KiranaColors.primary),
                    title: const Text('Store Contact Phone'),
                    subtitle: Text(shop?.phone ?? user?.phone ?? 'Not Added'),
                  ),
                  if (shop?.gstin != null && shop!.gstin!.isNotEmpty) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.receipt_long,
                          color: KiranaColors.primary),
                      title: const Text('GSTIN'),
                      subtitle: Text(shop.gstin!),
                    ),
                  ],
                  if (shop?.upiId != null && shop!.upiId!.isNotEmpty) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.qr_code_2,
                          color: KiranaColors.primary),
                      title: const Text('UPI ID for Dynamic QR'),
                      subtitle: Text(shop.upiId!),
                    ),
                  ],
                ],
              ),
            ),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(KiranaSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, st) => Card(
              child: ListTile(
                title: const Text('Store Name'),
                subtitle: Text(authState.activeShopName ?? 'Kirana Store'),
              ),
            ),
          ),
          const SizedBox(height: KiranaSpacing.xl),

          // Actions
          AppButton(
            label: 'Store Settings & Invoice Config',
            variant: AppButtonVariant.outlined,
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(height: KiranaSpacing.md),

          AppButton(
            label: 'Sign Out of KiranaOS',
            variant: AppButtonVariant.destructive,
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text(
                      'Are you sure you want to sign out? Offline data remains saved locally.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: KiranaColors.error),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign Out',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
