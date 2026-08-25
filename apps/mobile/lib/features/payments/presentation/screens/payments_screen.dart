import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../billing/presentation/providers/billing_provider.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  String _selectedMode = 'cash';
  bool _isSubmitting = false;

  void _showConfirmationDialog(BuildContext context) {
    final billingState = ref.read(billingNotifierProvider);
    final activeDraft = billingState.activeDraft;

    if (activeDraft == null || activeDraft.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot checkout an empty bill.'),
          backgroundColor: KiranaColors.error,
        ),
      );
      return;
    }

    if (billingState.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reconnect to complete this sale.'),
          backgroundColor: KiranaColors.error,
        ),
      );
      return;
    }

    final modeLabel = _selectedMode == 'cash'
        ? 'CASH'
        : _selectedMode == 'upi_qr'
            ? 'UPI'
            : 'CARD';

    showDialog(
      context: context,
      barrierDismissible: !_isSubmitting,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Confirm Payment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bill: ${activeDraft.billNumber}',
                      style: KiranaTypography.titleMedium),
                  const SizedBox(height: KiranaSpacing.xs),
                  Text('Payment Method: $modeLabel',
                      style: KiranaTypography.bodyMedium),
                  const Divider(height: KiranaSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Items:'),
                      Text('${activeDraft.items.length}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text(activeDraft.subtotalPaise.toRupeesString()),
                    ],
                  ),
                  if (activeDraft.discountPaise > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:'),
                        Text('- ${activeDraft.discountPaise.toRupeesString()}'),
                      ],
                    ),
                  if (activeDraft.taxTotalPaise > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tax:'),
                        Text(activeDraft.taxTotalPaise.toRupeesString()),
                      ],
                    ),
                  const Divider(height: KiranaSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount Payable:',
                          style: KiranaTypography.titleMedium),
                      Text(
                        activeDraft.totalPaise.toRupeesString(),
                        style: KiranaTypography.displayTotal.copyWith(
                          color: KiranaColors.primary,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: 'CONFIRM PAYMENT',
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => _isSubmitting = true);

                          final success = await ref
                              .read(billingNotifierProvider.notifier)
                              .completeCheckout(paymentMode: _selectedMode);

                          setDialogState(() => _isSubmitting = false);

                          if (context.mounted) {
                            Navigator.of(dialogCtx).pop();

                            if (success) {
                              _showSuccessDialog(context);
                            } else {
                              final err = ref
                                      .read(billingNotifierProvider)
                                      .errorMessage ??
                                  'Payment transaction failed.';
                              _showFailureDialog(context, err);
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline,
            size: 64, color: KiranaColors.success),
        title: const Text('Payment Successful'),
        content: const Text(
          'Sale has been completed atomically and inventory updated.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/bills');
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline,
            size: 64, color: KiranaColors.error),
        title: const Text('Checkout Failed'),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingNotifierProvider);
    final totalPaise = billingState.activeDraft?.totalPaise ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout & Payment')),
      body: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (billingState.isOffline)
              Container(
                margin: const EdgeInsets.only(bottom: KiranaSpacing.md),
                padding: const EdgeInsets.all(KiranaSpacing.sm),
                decoration: BoxDecoration(
                  color: KiranaColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: KiranaColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: KiranaColors.error),
                    const SizedBox(width: KiranaSpacing.xs),
                    Expanded(
                      child: Text(
                        'Offline Mode — Reconnect to complete this sale.',
                        style: KiranaTypography.bodySmall.copyWith(
                          color: KiranaColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Card(
              color: KiranaColors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(KiranaSpacing.lg),
                child: Column(
                  children: [
                    const Text('Total Bill Payable',
                        style: KiranaTypography.labelSmall),
                    const SizedBox(height: KiranaSpacing.xs),
                    Text(
                      totalPaise.toRupeesString(),
                      style: KiranaTypography.displayTotal.copyWith(
                        color: KiranaColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: KiranaSpacing.xl),

            // Payment Options
            _PaymentOptionCard(
              icon: Icons.money,
              title: 'Cash Payment',
              subtitle: 'Pay via cash tendered',
              color: KiranaColors.success,
              isSelected: _selectedMode == 'cash',
              onTap: () => setState(() => _selectedMode = 'cash'),
            ),
            const SizedBox(height: KiranaSpacing.md),
            _PaymentOptionCard(
              icon: Icons.qr_code,
              title: 'Dynamic UPI',
              subtitle: 'Pay via GPay, PhonePe, Paytm',
              color: KiranaColors.primary,
              isSelected: _selectedMode == 'upi_qr',
              onTap: () => setState(() => _selectedMode = 'upi_qr'),
            ),
            const SizedBox(height: KiranaSpacing.md),
            _PaymentOptionCard(
              icon: Icons.credit_card,
              title: 'Card Payment',
              subtitle: 'Debit or Credit Card POS terminal',
              color: KiranaColors.secondary,
              isSelected: _selectedMode == 'card',
              onTap: () => setState(() => _selectedMode = 'card'),
            ),
            const Spacer(),

            AppButton(
              label: 'PROCEED TO CHECKOUT',
              icon: Icons.payment,
              isLoading: billingState.isLoading,
              onPressed: billingState.isOffline
                  ? null
                  : () => _showConfirmationDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(KiranaSpacing.md),
        leading: Container(
          padding: const EdgeInsets.all(KiranaSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: KiranaTypography.titleMedium),
        subtitle: Text(subtitle, style: KiranaTypography.bodySmall),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: color)
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
