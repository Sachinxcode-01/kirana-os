import 'package:flutter/material.dart';
import 'package:kirana_mobile/core/extensions/num_extensions.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final invoices = [
      ('INV-20260824-0042', 'Cash Sale', 35700, '24 Aug 2026, 07:15 PM', 'Paid'),
      ('INV-20260824-0041', 'Ramesh Gupta (Udhaar)', 125000, '24 Aug 2026, 06:40 PM', 'Udhaar'),
      ('INV-20260824-0040', 'UPI Payment', 8400, '24 Aug 2026, 06:22 PM', 'Paid'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Recent Invoices & Bills')),
      body: ListView.separated(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        itemCount: invoices.length,
        separatorBuilder: (_, __) => const SizedBox(height: KiranaSpacing.sm),
        itemBuilder: (context, index) {
          final (inv, customer, total, time, status) = invoices[index];
          return Card(
            child: ListTile(
              title: Text(inv, style: KiranaTypography.titleMedium),
              subtitle: Text('$customer • $time', style: KiranaTypography.bodySmall),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    total.toRupeesString(),
                    style: KiranaTypography.priceTabular.copyWith(
                      color: KiranaColors.primary,
                    ),
                  ),
                  Text(
                    status,
                    style: KiranaTypography.labelSmall.copyWith(
                      color: status == 'Paid'
                          ? KiranaColors.success
                          : KiranaColors.secondary,
                    ),
                  ),
                ],
              ),
              onTap: () {
                _showInvoiceModal(context, inv, total);
              },
            ),
          );
        },
      ),
    );
  }

  void _showInvoiceModal(BuildContext context, String inv, int total) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(KiranaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Invoice: $inv', style: KiranaTypography.titleLarge),
            const SizedBox(height: KiranaSpacing.xs),
            Text('Total: ${total.toRupeesString()}', style: KiranaTypography.headlineMedium),
            const SizedBox(height: KiranaSpacing.xl),
            AppButton(
              label: 'Print Thermal Receipt (ESC/POS)',
              icon: Icons.print,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            const SizedBox(height: KiranaSpacing.md),
            AppButton(
              label: 'Share Digital Bill on WhatsApp',
              icon: Icons.share,
              variant: AppButtonVariant.outlined,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
