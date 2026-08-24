import 'package:flutter/material.dart';
import 'package:kirana_mobile/core/extensions/num_extensions.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final suppliers = [
      ('Metro Cash & Carry Wholesale', '9845012345', 1200000), // ₹12,000 pending
      ('Hindustan Unilever Dist.', '9845098765', 0),
      ('ITC Agro Distributors', '9988776655', 450000), // ₹4,500 pending
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers Ledger')),
      body: ListView.separated(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        itemCount: suppliers.length,
        separatorBuilder: (_, __) => const SizedBox(height: KiranaSpacing.sm),
        itemBuilder: (context, index) {
          final (name, phone, payable) = suppliers[index];
          return Card(
            child: ListTile(
              title: Text(name, style: KiranaTypography.titleMedium),
              subtitle: Text('Phone: $phone', style: KiranaTypography.bodySmall),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    payable > 0 ? 'Payable ${payable.toRupeesString()}' : 'Settled',
                    style: KiranaTypography.labelLarge.copyWith(
                      color: payable > 0 ? KiranaColors.secondary : KiranaColors.success,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
