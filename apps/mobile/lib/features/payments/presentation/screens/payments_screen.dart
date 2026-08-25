import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kirana_mobile/core/extensions/num_extensions.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/features/billing/presentation/providers/billing_provider.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingState = ref.watch(billingNotifierProvider);
    final totalPaise = billingState.activeDraft?.totalPaise ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Payment Mode')),
      body: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: KiranaColors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(KiranaSpacing.lg),
                child: Column(
                  children: [
                    const Text('Total Bill Payable',
                        style: KiranaTypography.labelSmall),
                    const SizedBox(height: KiranaSpacing.xs),
                    Text(
                      totalPaise.toRupeesString(),
                      style: KiranaTypography.displayTotal.copyWith(
                        color: KiranaColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: KiranaSpacing.xl),
            _PaymentOptionCard(
              icon: Icons.money,
              title: 'Cash Payment',
              subtitle: 'Exact cash or enter tendered amount',
              color: KiranaColors.success,
              onTap: () {
                context.go('/bills');
              },
            ),
            const SizedBox(height: KiranaSpacing.md),
            _PaymentOptionCard(
              icon: Icons.qr_code,
              title: 'Dynamic UPI QR',
              subtitle: 'Customer scans with PhonePe, GPay, Paytm',
              color: KiranaColors.primary,
              onTap: () {
                context.go('/bills');
              },
            ),
            const SizedBox(height: KiranaSpacing.md),
            _PaymentOptionCard(
              icon: Icons.account_balance_wallet,
              title: 'Add to Udhaar (Khata)',
              subtitle: 'Record to customer credit ledger',
              color: KiranaColors.secondary,
              onTap: () {
                context.go('/bills');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(KiranaSpacing.md),
        leading: Container(
          padding: const EdgeInsets.all(KiranaSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: KiranaTypography.titleMedium),
        subtitle: Text(subtitle, style: KiranaTypography.bodySmall),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
