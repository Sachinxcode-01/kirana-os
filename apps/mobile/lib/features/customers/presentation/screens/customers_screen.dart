import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/core/extensions/num_extensions.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';

class CustomerEntry {
  final String id;
  final String name;
  final String phone;
  final int debtPaise;
  final int limitPaise;

  const CustomerEntry({
    required this.id,
    required this.name,
    required this.phone,
    required this.debtPaise,
    required this.limitPaise,
  });
}

final customersListProvider = Provider<List<CustomerEntry>>((ref) {
  return const [
    CustomerEntry(
      id: 'c_1',
      name: 'Ramesh Gupta',
      phone: '9845011223',
      debtPaise: 125000, // ₹1,250.00
      limitPaise: 500000,
    ),
    CustomerEntry(
      id: 'c_2',
      name: 'Dr. Srinivas Rao',
      phone: '9845033445',
      debtPaise: 340000, // ₹3,400.00
      limitPaise: 1000000,
    ),
    CustomerEntry(
      id: 'c_3',
      name: 'Smt. Lakshmi Devi',
      phone: '9845055667',
      debtPaise: 0,
      limitPaise: 300000,
    ),
  ];
});

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(KiranaSpacing.md),
            child: AppTextField(
              hint: 'Search by customer name or phone...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: KiranaSpacing.md),
              itemCount: customers.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: KiranaSpacing.sm),
              itemBuilder: (context, index) {
                final c = customers[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: KiranaColors.primaryContainer,
                      child: Text(
                        c.name[0],
                        style: const TextStyle(
                          color: KiranaColors.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(c.name, style: KiranaTypography.titleMedium),
                    subtitle: Text('Phone: ${c.phone}',
                        style: KiranaTypography.bodySmall),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          c.debtPaise > 0
                              ? c.debtPaise.toRupeesString()
                              : 'No Due',
                          style: KiranaTypography.priceTabular.copyWith(
                            color: c.debtPaise > 0
                                ? KiranaColors.secondary
                                : KiranaColors.success,
                          ),
                        ),
                        Text('Limit ${c.limitPaise.toRupeesString()}',
                            style: KiranaTypography.labelSmall),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
