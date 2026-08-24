import 'package:flutter/material.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportOptions = [
      (
        'Day-End Z-Report',
        'Reconcile drawer cash & total receipts',
        Icons.summarize
      ),
      (
        'Sales & Profit Summary',
        'Item-wise margins and revenue',
        Icons.trending_up
      ),
      (
        'GST Tax Summary (GSTR-1)',
        'B2B/B2C tax slab breakdown for CA',
        Icons.account_balance
      ),
      (
        'Fast-Moving Inventory',
        'Top 20 revenue generating SKUs',
        Icons.insights
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Business Analytics')),
      body: ListView.separated(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        itemCount: reportOptions.length,
        separatorBuilder: (_, __) => const SizedBox(height: KiranaSpacing.sm),
        itemBuilder: (context, index) {
          final (title, subtitle, icon) = reportOptions[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(icon, size: 20)),
              title: Text(title, style: KiranaTypography.titleMedium),
              subtitle: Text(subtitle, style: KiranaTypography.bodySmall),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}
