import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/core/extensions/num_extensions.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';

class CreditScreen extends ConsumerWidget {
  const CreditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Udhaar / Khata Ledger')),
      body: ListView(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        children: [
          Card(
            color: KiranaColors.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(KiranaSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Outstanding Udhaar', style: KiranaTypography.labelSmall),
                  const SizedBox(height: KiranaSpacing.xs),
                  Text(
                    3850000.toRupeesString(), // ₹38,500.00
                    style: KiranaTypography.displayTotal.copyWith(
                      color: KiranaColors.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: KiranaSpacing.md),
                  const Text(
                    '18 customers have active credit balances.',
                    style: KiranaTypography.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KiranaSpacing.lg),
          const Text('Recent Udhaar Accounts', style: KiranaTypography.titleLarge),
          const SizedBox(height: KiranaSpacing.sm),
          Card(
            child: ListTile(
              title: const Text('Ramesh Gupta'),
              subtitle: const Text('Last transaction: 2 days ago'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    125000.toRupeesString(),
                    style: KiranaTypography.priceTabular.copyWith(
                      color: KiranaColors.secondary,
                    ),
                  ),
                  const Text('Pending', style: KiranaTypography.labelSmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: KiranaSpacing.xl),
          AppButton(
            label: 'Send WhatsApp Payment Reminders',
            icon: Icons.send,
            variant: AppButtonVariant.secondary,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
