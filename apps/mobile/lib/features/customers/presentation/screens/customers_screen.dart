import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kirana_mobile/app/app_providers.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/features/customers/presentation/providers/customer_providers.dart';
import 'package:kirana_mobile/features/customers/presentation/screens/add_edit_customer_dialog.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(customerSearchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);
    final searchQuery = ref.watch(customerSearchQueryProvider);
    final connectivity =
        ref.watch(connectivityStatusStreamProvider).valueOrNull ??
            ConnectivityStatus.online;
    final isOffline = connectivity == ConnectivityStatus.offline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add Customer',
            onPressed: () => AddEditCustomerDialog.show(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddEditCustomerDialog.show(context),
        backgroundColor: KiranaColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label:
            const Text('Add Customer', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Offline Banner
          if (isOffline)
            Container(
              width: double.infinity,
              color: KiranaColors.warningContainer,
              padding: const EdgeInsets.symmetric(
                horizontal: KiranaSpacing.md,
                vertical: KiranaSpacing.xs,
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off,
                      size: 16, color: KiranaColors.onSecondaryContainer),
                  SizedBox(width: KiranaSpacing.xs),
                  Text(
                    'OFFLINE • Showing cached local customers',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: KiranaColors.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),

          // Search Field
          Padding(
            padding: const EdgeInsets.all(KiranaSpacing.md),
            child: AppTextField(
              controller: _searchController,
              hint: 'Search by name or phone...',
              prefixIcon: const Icon(Icons.search),
              onChanged: _onSearchChanged,
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(customerSearchQueryProvider.notifier).state =
                            '';
                      },
                    )
                  : null,
            ),
          ),

          // Directory List
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: KiranaColors.error),
                    const SizedBox(height: KiranaSpacing.md),
                    const Text('Failed to load customer directory',
                        style: KiranaTypography.titleMedium),
                    const SizedBox(height: KiranaSpacing.lg),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(customersStreamProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (customers) {
                if (customers.isEmpty) {
                  if (searchQuery.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              size: 48, color: KiranaColors.neutral400),
                          const SizedBox(height: KiranaSpacing.md),
                          Text(
                            'No customers match "$searchQuery"',
                            style: KiranaTypography.titleMedium
                                .copyWith(color: KiranaColors.neutral700),
                          ),
                          const SizedBox(height: KiranaSpacing.xs),
                          const Text(
                            'Try searching with a different name or phone number.',
                            style: TextStyle(
                                fontSize: 12, color: KiranaColors.neutral500),
                          ),
                        ],
                      ),
                    );
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline,
                            size: 56, color: KiranaColors.neutral400),
                        const SizedBox(height: KiranaSpacing.md),
                        Text(
                          'No customers added yet',
                          style: KiranaTypography.headlineMedium.copyWith(
                            color: KiranaColors.neutral700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: KiranaSpacing.xs),
                        const Text(
                          'Tap "+ Add Customer" below to create your first customer.',
                          style: TextStyle(
                              fontSize: 13, color: KiranaColors.neutral600),
                        ),
                        const SizedBox(height: KiranaSpacing.lg),
                        ElevatedButton.icon(
                          onPressed: () => AddEditCustomerDialog.show(context),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add First Customer'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(KiranaSpacing.md),
                  itemCount: customers.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: KiranaSpacing.xs),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _CustomerCard(customer: customer);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerData customer;

  const _CustomerCard({required this.customer});

  static String _formatRupees(int paise) {
    final double rupees = paise / 100.0;
    return '₹${rupees.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final debt = customer.currentDebtPaise.toInt();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: KiranaRadius.borderMd,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KiranaSpacing.md,
          vertical: KiranaSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: KiranaColors.primaryContainer,
          child: Text(
            customer.name[0].toUpperCase(),
            style: const TextStyle(
              color: KiranaColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: KiranaTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Phone: ${customer.phone}',
          style: KiranaTypography.bodySmall.copyWith(
            color: KiranaColors.neutral600,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              debt > 0 ? _formatRupees(debt) : 'No Due',
              style: KiranaTypography.priceTabular.copyWith(
                color: debt > 0 ? KiranaColors.secondary : KiranaColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: KiranaColors.neutral400),
          ],
        ),
        onTap: () => context.push('/customers/${customer.id}'),
      ),
    );
  }
}
