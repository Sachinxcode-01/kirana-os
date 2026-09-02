import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../database/drift/database.dart';
import '../../../receipts/domain/services/whats_app_service.dart';
import '../../../settings/presentation/providers/shop_settings_provider.dart';
import '../providers/credit_providers.dart';
import 'record_khata_payment_dialog.dart';

class CreditScreen extends ConsumerStatefulWidget {
  const CreditScreen({super.key});

  @override
  ConsumerState<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends ConsumerState<CreditScreen> {
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
      ref.read(indebtedCustomersQueryProvider.notifier).state = value;
    });
  }

  static String _formatRupees(int paise) {
    final double rupees = paise / 100.0;
    return '₹${rupees.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(shopCreditSummaryProvider);
    final indebtedAsync = ref.watch(indebtedCustomersStreamProvider);
    final searchQuery = ref.watch(indebtedCustomersQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Udhaar / Khata Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(shopCreditSummaryProvider);
              ref.invalidate(indebtedCustomersStreamProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Total Outstanding Debt Summary Header Card
          Padding(
            padding: const EdgeInsets.all(KiranaSpacing.md),
            child: Card(
              elevation: 2,
              color: KiranaColors.secondaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: KiranaRadius.borderMd,
              ),
              child: Padding(
                padding: const EdgeInsets.all(KiranaSpacing.lg),
                child: summaryAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Failed to load credit summary'),
                  data: (summary) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Outstanding Udhaar',
                            style: KiranaTypography.labelLarge.copyWith(
                              color: KiranaColors.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(Icons.account_balance_wallet,
                              color: KiranaColors.secondary),
                        ],
                      ),
                      const SizedBox(height: KiranaSpacing.xs),
                      Text(
                        _formatRupees(summary.totalDebtPaise),
                        style: KiranaTypography.headlineMedium.copyWith(
                          color: KiranaColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: KiranaSpacing.sm),
                      Text(
                        '${summary.indebtedCount} customer(s) have active credit balance.',
                        style: KiranaTypography.bodyMedium.copyWith(
                          color: KiranaColors.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KiranaSpacing.md),
            child: AppTextField(
              controller: _searchController,
              hint: 'Search indebted customer by name or phone...',
              prefixIcon: const Icon(Icons.search),
              onChanged: _onSearchChanged,
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(indebtedCustomersQueryProvider.notifier)
                            .state = '';
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: KiranaSpacing.sm),

          // 3. Indebted Customers List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KiranaSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Indebted Accounts',
                  style: KiranaTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Sorted by highest debt',
                  style: KiranaTypography.bodySmall.copyWith(
                    color: KiranaColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KiranaSpacing.xs),

          // 4. Indebted Customers List
          Expanded(
            child: indebtedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: KiranaColors.error),
                    const SizedBox(height: KiranaSpacing.md),
                    const Text('Failed to load indebted customer list'),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(indebtedCustomersStreamProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (customers) {
                if (customers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(KiranaSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(KiranaSpacing.lg),
                            decoration: BoxDecoration(
                              color: searchQuery.isNotEmpty
                                  ? KiranaColors.surfaceVariant
                                  : KiranaColors.successContainer
                                      .withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              searchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.check_circle_outline,
                              size: 48,
                              color: searchQuery.isNotEmpty
                                  ? KiranaColors.textSecondary
                                  : KiranaColors.success,
                            ),
                          ),
                          const SizedBox(height: KiranaSpacing.lg),
                          Text(
                            searchQuery.isNotEmpty
                                ? 'No indebted customer matches "$searchQuery"'
                                : 'All Customers Clear!',
                            style: KiranaTypography.titleLarge.copyWith(
                              color: KiranaColors.neutral800,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: KiranaSpacing.xs),
                          Text(
                            searchQuery.isNotEmpty
                                ? 'Try searching with a different name or phone number.'
                                : 'All customer accounts are clear with zero due debt.',
                            style: KiranaTypography.bodyMedium.copyWith(
                              color: KiranaColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
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
                    return _IndebtedCustomerCard(customer: customer);
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

class _IndebtedCustomerCard extends ConsumerWidget {
  final CustomerData customer;

  const _IndebtedCustomerCard({required this.customer});

  static String _formatRupees(int paise) {
    final double rupees = paise / 100.0;
    return '₹${rupees.toStringAsFixed(2)}';
  }

  void _sendWhatsAppReminder(BuildContext context, WidgetRef ref) async {
    final whatsAppService = ref.read(whatsAppServiceProvider);
    final shopSettings = ref.read(shopSettingsNotifierProvider).settings;
    final message = whatsAppService.formatKhataReminderMessage(
      customerName: customer.name,
      currentDebtPaise: customer.currentDebtPaise.toInt(),
      shopSettings: shopSettings,
    );

    final shared = await whatsAppService.shareMessage(
      message,
      subject: 'Khata Payment Reminder - ${customer.name}',
    );

    if (context.mounted && shared) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment reminder dispatched via WhatsApp'),
          backgroundColor: KiranaColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtPaise = customer.currentDebtPaise.toInt();

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
          backgroundColor: KiranaColors.secondaryContainer,
          child: Text(
            customer.name[0].toUpperCase(),
            style: const TextStyle(
              color: KiranaColors.secondary,
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
          style: KiranaTypography.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatRupees(debtPaise),
                  style: KiranaTypography.titleMedium.copyWith(
                    color: KiranaColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Limit ${_formatRupees(customer.creditLimitPaise.toInt())}',
                  style: KiranaTypography.labelSmall.copyWith(
                    color: KiranaColors.neutral600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: KiranaSpacing.xs),
            IconButton(
              icon: const Icon(Icons.chat_outlined, color: KiranaColors.success, size: 20),
              tooltip: 'WhatsApp UPI Reminder',
              onPressed: () => _sendWhatsAppReminder(context, ref),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KiranaColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => RecordKhataPaymentDialog.show(context, customer),
              child: const Text('Collect', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        onTap: () => context.push('/customers/${customer.id}'),
      ),
    );
  }
}
