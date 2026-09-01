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
import 'package:kirana_mobile/core/widgets/animated_list_item.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';
import 'package:kirana_mobile/core/widgets/empty_state.dart';
import 'package:kirana_mobile/core/widgets/error_view.dart';
import 'package:kirana_mobile/core/widgets/state_transition_switcher.dart';
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
          ),          // Directory List
          Expanded(
            child: StateTransitionSwitcher(
              child: customersAsync.when(
                loading: () => const Center(
                  key: ValueKey('loading'),
                  child: CircularProgressIndicator(),
                ),
                error: (err, st) => ErrorView(
                  key: const ValueKey('error'),
                  customMessage: 'Failed to load customer directory: $err',
                  onRetry: () => ref.invalidate(customersStreamProvider),
                ),
                data: (customers) {
                  if (customers.isEmpty) {
                    if (searchQuery.isNotEmpty) {
                      return EmptyState(
                        key: const ValueKey('empty_search'),
                        icon: Icons.search_off,
                        title: 'No customers match "$searchQuery"',
                        description:
                            'Try searching with a different name or phone number.',
                        actionLabel: 'Clear Search',
                        onAction: () {
                          _searchController.clear();
                          ref.read(customerSearchQueryProvider.notifier).state =
                              '';
                        },
                      );
                    }

                    return EmptyState(
                      key: const ValueKey('empty_customers'),
                      icon: Icons.people_outline,
                      title: 'No customers added yet',
                      description:
                          'Track udhaar, credit limits, and purchase history by creating your first customer.',
                      actionLabel: '+ Add First Customer',
                      onAction: () => AddEditCustomerDialog.show(context),
                    );
                  }

                  return ListView.separated(
                    key: const ValueKey('customers_list'),
                    padding: const EdgeInsets.all(KiranaSpacing.md),
                    itemCount: customers.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: KiranaSpacing.xs),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return AnimatedListItem(
                        key: ValueKey(customer.id),
                        index: index,
                        child: _CustomerCard(customer: customer),
                      );
                    },
                  );
                },
              ),
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
