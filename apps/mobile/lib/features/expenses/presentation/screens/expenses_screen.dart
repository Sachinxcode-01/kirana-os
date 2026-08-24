import 'package:flutter/material.dart';
import 'package:kirana_mobile/core/extensions/num_extensions.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = [
      ('Store Electricity Bill', 'Utilities', 320000, '20 Aug 2026'),
      ('Daily Tea & Staff Snacks', 'Petty Cash', 12000, '24 Aug 2026'),
      ('Auto Freight / Stock Transport', 'Logistics', 45000, '22 Aug 2026'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        itemCount: expenses.length,
        separatorBuilder: (_, __) => const SizedBox(height: KiranaSpacing.sm),
        itemBuilder: (context, index) {
          final (title, category, amount, date) = expenses[index];
          return Card(
            child: ListTile(
              title: Text(title, style: KiranaTypography.titleMedium),
              subtitle:
                  Text('$category • $date', style: KiranaTypography.bodySmall),
              trailing: Text(
                amount.toRupeesString(),
                style: KiranaTypography.priceTabular.copyWith(
                  color: KiranaColors.error,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
