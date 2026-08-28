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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Profile'),
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

                // Details Card (Address & Notes)
                if ((customer.address != null &&
                        customer.address!.isNotEmpty) ||
                    (customer.notes != null && customer.notes!.isNotEmpty)) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(KiranaSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (customer.address != null &&
                              customer.address!.isNotEmpty) ...[
                            Text(
                              'Address',
                              style: KiranaTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: KiranaColors.neutral600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              customer.address!,
                              style: KiranaTypography.bodyMedium,
                            ),
                            const SizedBox(height: KiranaSpacing.md),
                          ],
                          if (customer.notes != null &&
                              customer.notes!.isNotEmpty) ...[
                            Text(
                              'Notes',
                              style: KiranaTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: KiranaColors.neutral600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              customer.notes!,
                              style: KiranaTypography.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: KiranaSpacing.lg),
                ],

                // Sales History Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sales History',
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

                // Sales History List
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
