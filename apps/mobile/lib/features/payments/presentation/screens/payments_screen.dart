import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../billing/presentation/providers/billing_provider.dart';
import '../widgets/dynamic_upi_qr_modal.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  String _selectedMode = 'upi_qr';
  bool _isSubmitting = false;

  void _handleCheckout(BuildContext context) {
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

    if (_selectedMode == 'upi_qr') {
      _showDynamicUpiModal(context);
    } else {
      _showConfirmationDialog(context);
    }
  }

  void _showDynamicUpiModal(BuildContext context) {
    final activeDraft = ref.read(billingNotifierProvider).activeDraft;
    if (activeDraft == null) return;

    DynamicUpiQrModal.show(
      context,
      billNumber: activeDraft.billNumber,
      amountPaise: activeDraft.totalPaise,
      onConfirmPayment: () async {
        final success = await ref
            .read(billingNotifierProvider.notifier)
            .completeCheckout(paymentMode: 'upi_qr');

        if (success && context.mounted) {
          _showSuccessDialog(
            context,
            billNumber: activeDraft.billNumber,
            amountFormatted: activeDraft.totalPaise.toRupeesString(),
            paymentMode: 'BHARAT UPI QR',
          );
        }
        return success;
      },
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    final billingState = ref.read(billingNotifierProvider);
    final activeDraft = billingState.activeDraft;
    if (activeDraft == null) return;

    final modeLabel = _selectedMode == 'cash'
        ? 'CASH'
        : _selectedMode == 'card'
            ? 'CARD'
            : 'CREDIT (UDHAAR)';

    showDialog(
      context: context,
      barrierDismissible: !_isSubmitting,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: KiranaRadius.borderLg,
              ),
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
                      Text('${activeDraft.items.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        Text('- ${activeDraft.discountPaise.toRupeesString()}',
                            style: const TextStyle(color: KiranaColors.error)),
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
                          color: KiranaColors.primaryDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
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
                  label: 'CONFIRM SALE',
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
                              _showSuccessDialog(
                                context,
                                billNumber: activeDraft.billNumber,
                                amountFormatted:
                                    activeDraft.totalPaise.toRupeesString(),
                                paymentMode: modeLabel,
                              );
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

  void _showSuccessDialog(
    BuildContext context, {
    required String billNumber,
    required String amountFormatted,
    required String paymentMode,
  }) {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: KiranaRadius.borderXl,
        ),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: KiranaColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 64,
            color: KiranaColors.success,
          ),
        ).animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 600.ms),
        title: const Text(
          'Payment Successful',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Bill synchronized and receipt generated.',
                style: KiranaTypography.bodySmall.copyWith(
                  color: KiranaColors.neutral600,
                ),
              ),
            ),
            const Divider(height: KiranaSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bill Number:', style: TextStyle(color: KiranaColors.neutral600)),
                Text(billNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: KiranaSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount Paid:', style: TextStyle(color: KiranaColors.neutral600)),
                Text(amountFormatted,
                    style: KiranaTypography.titleMedium.copyWith(
                      color: KiranaColors.success,
                      fontWeight: FontWeight.w900,
                    )),
              ],
            ),
            const SizedBox(height: KiranaSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment Method:', style: TextStyle(color: KiranaColors.neutral600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: KiranaColors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    paymentMode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: KiranaColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              final activeDraft = ref.read(billingNotifierProvider).activeDraft;
              if (activeDraft != null) {
                context.push('/receipt', extra: activeDraft);
              } else {
                context.go('/bills');
              }
            },
            icon: const Icon(Icons.receipt_long, size: 18),
            label: const Text('VIEW RECEIPT'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KiranaColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/bills');
            },
            child: const Text('Start New Sale'),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog(BuildContext context, String message) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: KiranaRadius.borderLg,
        ),
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
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: KiranaColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: KiranaColors.error, size: 20),
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

            // Bill Total Banner Card
            Container(
              padding: const EdgeInsets.all(KiranaSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    KiranaColors.primaryContainer,
                    KiranaColors.primaryContainer.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: KiranaRadius.borderLg,
                border: Border.all(
                  color: KiranaColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  const Text('Total Bill Payable',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: KiranaColors.neutral600,
                      )),
                  const SizedBox(height: KiranaSpacing.xxs),
                  Text(
                    totalPaise.toRupeesString(),
                    style: KiranaTypography.displayTotal.copyWith(
                      color: KiranaColors.primaryDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05, end: 0),
            const SizedBox(height: KiranaSpacing.xl),

            // Payment Options Label
            const Text(
              'Select Payment Mode',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: KiranaColors.neutral800,
              ),
            ),
            const SizedBox(height: KiranaSpacing.md),

            // Dynamic UPI Card (Default & Recommended for India)
            _PaymentOptionCard(
              icon: Icons.qr_code_2,
              title: 'Dynamic Bharat UPI QR',
              subtitle: 'GPay, PhonePe, Paytm, BHIM with 3-min timer',
              badge: 'POPULAR',
              badgeColor: KiranaColors.primary,
              color: KiranaColors.primary,
              isSelected: _selectedMode == 'upi_qr',
              onTap: () => setState(() => _selectedMode = 'upi_qr'),
            ).animate().fadeIn(duration: 220.ms, delay: 50.ms).slideX(begin: 0.04, end: 0),
            const SizedBox(height: KiranaSpacing.md),

            // Cash Payment Card
            _PaymentOptionCard(
              icon: Icons.payments_outlined,
              title: 'Cash Payment',
              subtitle: 'Collect cash tendered in store register',
              color: KiranaColors.success,
              isSelected: _selectedMode == 'cash',
              onTap: () => setState(() => _selectedMode = 'cash'),
            ).animate().fadeIn(duration: 220.ms, delay: 100.ms).slideX(begin: 0.04, end: 0),
            const SizedBox(height: KiranaSpacing.md),

            // Card Payment Card
            _PaymentOptionCard(
              icon: Icons.credit_card,
              title: 'Debit / Credit Card',
              subtitle: 'Swipe or Tap on POS Card Terminal',
              color: KiranaColors.secondary,
              isSelected: _selectedMode == 'card',
              onTap: () => setState(() => _selectedMode = 'card'),
            ).animate().fadeIn(duration: 220.ms, delay: 150.ms).slideX(begin: 0.04, end: 0),
            const Spacer(),

            AppButton(
              label: _selectedMode == 'upi_qr'
                  ? 'SHOW DYNAMIC UPI QR'
                  : 'PROCEED TO CHECKOUT',
              icon: _selectedMode == 'upi_qr' ? Icons.qr_code_2 : Icons.payment,
              isLoading: billingState.isLoading,
              onPressed: billingState.isOffline
                  ? null
                  : () => _handleCheckout(context),
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
  final String? badge;
  final Color? badgeColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.badge,
    this.badgeColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 2 : 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: KiranaRadius.borderLg,
        side: BorderSide(
          color: isSelected ? color : KiranaColors.outlineVariant.withValues(alpha: 0.8),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: KiranaRadius.borderLg,
        child: Padding(
          padding: const EdgeInsets.all(KiranaSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(KiranaSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: KiranaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: KiranaTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: (badgeColor ?? color).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: badgeColor ?? color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: KiranaColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? color : KiranaColors.neutral400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
