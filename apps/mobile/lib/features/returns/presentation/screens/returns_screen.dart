import 'package:flutter/material.dart';
import 'package:kirana_mobile/core/extensions/num_extensions.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Returns & Refunds')),
      body: ListView(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(KiranaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Process Customer Return', style: KiranaTypography.titleLarge),
                  const SizedBox(height: KiranaSpacing.xs),
                  const Text(
                    'Scan returned item or enter invoice number to restore stock and issue refund note.',
                    style: KiranaTypography.bodyMedium,
                  ),
                  const SizedBox(height: KiranaSpacing.lg),
                  AppButton(
                    label: 'Scan Item for Return',
                    icon: Icons.qr_code_scanner,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KiranaSpacing.xl),
          const Text('Recent Return Notes', style: KiranaTypography.titleLarge),
          const SizedBox(height: KiranaSpacing.sm),
          Card(
            child: ListTile(
              title: const Text('Aashirvaad Atta 5kg (Pack Damaged)'),
              subtitle: const Text('Refund Note #RN-0824-01 • Cash Refund'),
              trailing: Text(
                24500.toRupeesString(),
                style: KiranaTypography.priceTabular.copyWith(
                  color: KiranaColors.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
