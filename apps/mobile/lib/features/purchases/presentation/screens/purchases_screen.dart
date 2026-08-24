import 'package:flutter/material.dart';
import 'package:kirana_mobile/core/extensions/num_extensions.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final purchases = [
      ('PO-2026-004', 'Metro Cash & Carry', 4500000, '22 Aug 2026', 'Received'),
      ('PO-2026-003', 'Hindustan Unilever Dist.', 2800000, '18 Aug 2026', 'Received'),
      ('PO-2026-002', 'ITC Agro Distributors', 1950000, '12 Aug 2026', 'Received'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchases & Inward Goods'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        itemCount: purchases.length,
        separatorBuilder: (_, __) => const SizedBox(height: KiranaSpacing.sm),
        itemBuilder: (context, index) {
          final (po, vendor, amount, date, status) = purchases[index];
          return Card(
            child: ListTile(
              title: Text(vendor, style: KiranaTypography.titleMedium),
              subtitle: Text('$po • $date', style: KiranaTypography.bodySmall),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(amount.toRupeesString(), style: KiranaTypography.priceTabular),
                  Text(status, style: KiranaTypography.labelSmall),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
