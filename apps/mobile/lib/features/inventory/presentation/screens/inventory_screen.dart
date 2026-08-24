import 'package:flutter/material.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lowStockItems = [
      ('Fortune Sunflower Oil 1L', 3.0, 10.0),
      ('Amul Butter 100g', 2.0, 15.0),
      ('Good Day Cashew Cookies 100g', 4.0, 20.0),
      ('Tata Tea Gold 250g', 1.0, 8.0),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory & Stock Alerts')),
      body: ListView(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        children: [
          Card(
            color: KiranaColors.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(KiranaSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: KiranaColors.error),
                  const SizedBox(width: KiranaSpacing.md),
                  Expanded(
                    child: Text(
                      '4 products are running below minimum safety stock.',
                      style: KiranaTypography.bodyMedium.copyWith(
                        color: KiranaColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KiranaSpacing.lg),
          const Text('Critical Stock Items',
              style: KiranaTypography.titleLarge),
          const SizedBox(height: KiranaSpacing.sm),
          ...lowStockItems.map((item) {
            final (name, current, min) = item;
            return Card(
              margin: const EdgeInsets.only(bottom: KiranaSpacing.sm),
              child: ListTile(
                title: Text(name, style: KiranaTypography.titleMedium),
                subtitle: Text(
                  'Current Stock: ${current.toInt()} pcs (Min: ${min.toInt()} pcs)',
                  style: KiranaTypography.bodySmall,
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KiranaColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(64, 36),
                  ),
                  onPressed: () {},
                  child: const Text('Adjust'),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
