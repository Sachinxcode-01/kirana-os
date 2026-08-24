import 'package:flutter/material.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      ('Atta, Rice & Grains', Icons.grain, 124),
      ('Edible Oils & Ghee', Icons.water_drop, 48),
      ('Masalas & Spices', Icons.soup_kitchen, 86),
      ('Snacks & Biscuits', Icons.cookie, 152),
      ('Dairy & Bread', Icons.egg_alt, 35),
      ('Personal Care & Soaps', Icons.clean_hands, 72),
      ('Cleaning & Detergents', Icons.cleaning_services, 54),
      ('Beverages & Tea/Coffee', Icons.coffee, 40),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: ListView.separated(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: KiranaSpacing.sm),
        itemBuilder: (context, index) {
          final (name, icon, count) = categories[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(icon, size: 20),
              ),
              title: Text(name, style: KiranaTypography.titleMedium),
              trailing: Text('$count items', style: KiranaTypography.bodySmall),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}
