import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../database/drift/database.dart';
import '../../../billing/domain/models/bill_model.dart';
import '../../../billing/presentation/widgets/bill_details_modal.dart';
import '../../../credit/presentation/providers/credit_providers.dart';
import '../../../credit/presentation/screens/record_khata_payment_dialog.dart';
import '../providers/customer_providers.dart';
import 'add_edit_customer_dialog.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  void _showBillDetails(BuildContext context, BillData billData) {
    final billModel = BillModel(
      id: billData.id,
      shopId: billData.shopId,
      cashierId: billData.cashierId,
      billNumber: billData.billNumber,
      customerId: billData.customerId,
      status: billData.isCancelled ? 'cancelled' : 'completed',
      subtotalPaise: billData.subtotalPaise.toInt(),
      taxTotalPaise: billData.taxTotalPaise.toInt(),
      discountPaise: billData.discountPaise.toInt(),
      totalPaise: billData.totalPaise.toInt(),
      paymentStatus: billData.paymentStatus,
      createdAt: billData.createdAt,
      updatedAt: billData.updatedAt,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KiranaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => BillDetailsModal(bill: billModel),
    );
  }

  static String _formatRupees(int paise) {
    final double rupees = paise / 100.0;
    return '₹${rupees.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final salesHistoryAsync =
        ref.watch(customerSalesHistoryProvider(customerId));
    final ledgerAsync = ref.watch(customerLedgerStreamProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Profile & Khata'),
        actions: [
          customerAsync.when(
            data: (customer) => customer != null
                ? IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit Customer',
                    onPressed: () async {
                      final updated = await AddEditCustomerDialog.show(
                        context,
                        customer: customer,
                      );
                      if (updated == true) {
                        ref.invalidate(customerDetailProvider(customerId));
                      }
                    },
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: KiranaColors.error),
              const SizedBox(height: KiranaSpacing.md),
              const Text('Failed to load customer profile'),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(customerDetailProvider(customerId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (customer) {
          if (customer == null) {
            return const Center(child: Text('Customer not found'));
          }

          final debtPaise = customer.currentDebtPaise.toInt();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(KiranaSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Card Header
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: KiranaRadius.borderMd,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(KiranaSpacing.lg),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: KiranaColors.primaryContainer,
                          child: Text(
                            customer.name[0].toUpperCase(),
                            style: KiranaTypography.headlineMedium.copyWith(
                              color: KiranaColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: KiranaSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name,
                                style: KiranaTypography.headlineMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone,
                                      size: 16, color: KiranaColors.neutral600),
                                  const SizedBox(width: 6),
                                  Text(
                                    customer.phone,
                                    style:
                                        KiranaTypography.titleMedium.copyWith(
                                      color: KiranaColors.neutral700,
                                    ),
                                  ),
                                ],
                              ),
                              if (customer.email != null &&
                                  customer.email!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.email_outlined,
                                        size: 16,
                                        color: KiranaColors.neutral600),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        customer.email!,
                                        style: KiranaTypography.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: KiranaSpacing.md),

                // Khata Debt & Collect Payment Card
                Card(
                  elevation: 2,
                  color: debtPaise > 0
                      ? KiranaColors.secondaryContainer.withValues(alpha: 0.6)
                      : KiranaColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: KiranaRadius.borderMd,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(KiranaSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Outstanding Debt (Udhaar)',
                                style: KiranaTypography.labelLarge.copyWith(
                                  color: KiranaColors.neutral700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                debtPaise > 0
                                    ? _formatRupees(debtPaise)
                                    : 'No Due Balance',
                                style: KiranaTypography.headlineMedium.copyWith(
                                  color: debtPaise > 0
                                      ? KiranaColors.secondary
                                      : KiranaColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Credit Limit: ${_formatRupees(customer.creditLimitPaise.toInt())}',
                                style: KiranaTypography.bodySmall.copyWith(
                                  color: KiranaColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KiranaColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onPressed: () => RecordKhataPaymentDialog.show(
                            context,
                            customer,
                          ),
                          icon: const Icon(Icons.add_card, size: 18),
                          label: const Text('Collect Payment'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: KiranaSpacing.lg),

                // Section 1: Khata Ledger Transactions History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Khata Transaction Ledger',
                      style: KiranaTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => ref
                          .invalidate(customerLedgerStreamProvider(customerId)),
                    ),
                  ],
                ),
                const SizedBox(height: KiranaSpacing.sm),

                ledgerAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(KiranaSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => Container(
                    padding: const EdgeInsets.all(KiranaSpacing.md),
                    color: KiranaColors.errorContainer,
                    child: const Text('Failed to load Khata transactions'),
                  ),
                  data: (txns) {
                    if (txns.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(KiranaSpacing.xl),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: KiranaRadius.borderMd,
                          border: Border.all(color: KiranaColors.neutral200),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.history_toggle_off,
                                size: 36, color: KiranaColors.neutral400),
                            SizedBox(height: KiranaSpacing.xs),
                            Text('No Khata transactions recorded yet',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: txns.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: KiranaSpacing.xs),
                      itemBuilder: (context, index) {
                        final txn = txns[index];
                        final isPayment = txn.type == 'payment_received';

                        return Card(
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isPayment
                                  ? KiranaColors.successContainer
                                  : KiranaColors.errorContainer,
                              child: Icon(
                                isPayment
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: isPayment
                                    ? KiranaColors.success
                                    : KiranaColors.error,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              isPayment
                                  ? 'Payment Received'
                                  : 'Udhaar Credit Sale',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${DateFormatter.formatDateTime(txn.createdAt)}${txn.notes != null ? ' • ${txn.notes}' : ''}',
                              style: KiranaTypography.bodySmall,
                            ),
                            trailing: Text(
                              '${isPayment ? '-' : '+'}${_formatRupees(txn.amountPaise.toInt())}',
                              style: KiranaTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isPayment
                                    ? KiranaColors.success
                                    : KiranaColors.error,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: KiranaSpacing.xl),

                // Section 2: Sales History Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Completed Sales History',
                      style: KiranaTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => ref
                          .invalidate(customerSalesHistoryProvider(customerId)),
                    ),
                  ],
                ),
                const SizedBox(height: KiranaSpacing.sm),

                salesHistoryAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(KiranaSpacing.xl),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => Container(
                    padding: const EdgeInsets.all(KiranaSpacing.lg),
                    decoration: BoxDecoration(
                      color: KiranaColors.errorContainer,
                      borderRadius: KiranaRadius.borderMd,
                    ),
                    child: const Text('Failed to load sales history'),
                  ),
                  data: (bills) {
                    if (bills.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(KiranaSpacing.xxl),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: KiranaRadius.borderMd,
                          border: Border.all(color: KiranaColors.neutral200),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.receipt_long_outlined,
                                size: 48, color: KiranaColors.neutral400),
                            const SizedBox(height: KiranaSpacing.sm),
                            Text(
                              'No sales yet',
                              style: KiranaTypography.titleMedium.copyWith(
                                color: KiranaColors.neutral600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: KiranaSpacing.xs),
                            const Text(
                              'Completed sales attached to this customer will appear here.',
                              style: TextStyle(
                                  fontSize: 12, color: KiranaColors.neutral500),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bills.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: KiranaSpacing.xs),
                      itemBuilder: (context, index) {
                        final bill = bills[index];
                        return Card(
                          elevation: 1,
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: KiranaColors.primaryContainer,
                              child: Icon(Icons.receipt,
                                  color: KiranaColors.primary, size: 20),
                            ),
                            title: Text(
                              '#${bill.billNumber}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${DateFormatter.formatDateTime(bill.createdAt)} • ${bill.paymentStatus.toUpperCase()}',
                              style: KiranaTypography.bodySmall,
                            ),
                            trailing: Text(
                              _formatRupees(bill.totalPaise.toInt()),
                              style: KiranaTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: KiranaColors.primary,
                              ),
                            ),
                            onTap: () => _showBillDetails(context, bill),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
