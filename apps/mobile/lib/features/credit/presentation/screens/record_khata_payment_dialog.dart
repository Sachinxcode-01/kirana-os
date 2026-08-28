import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../database/drift/database.dart';
import '../../../customers/presentation/providers/customer_providers.dart';
import '../providers/credit_providers.dart';

class RecordKhataPaymentDialog extends ConsumerStatefulWidget {
  final CustomerData customer;

  const RecordKhataPaymentDialog({super.key, required this.customer});

  static Future<bool?> show(BuildContext context, CustomerData customer) {
    return showDialog<bool>(
      context: context,
      builder: (context) => RecordKhataPaymentDialog(customer: customer),
    );
  }

  @override
  ConsumerState<RecordKhataPaymentDialog> createState() =>
      _RecordKhataPaymentDialogState();
}

class _RecordKhataPaymentDialogState
    extends ConsumerState<RecordKhataPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  String _paymentMethod = 'Cash';
  bool _isSaving = false;
  bool _isSuccess = false;
  int _paidPaise = 0;
  int _remainingPaise = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {});
  }

  static String _formatRupees(int paise) {
    final double rupees = paise / 100.0;
    return '₹${rupees.toStringAsFixed(2)}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final rupeesText = _amountController.text.trim();
    final double? rupees = double.tryParse(rupeesText);
    final debtPaise = widget.customer.currentDebtPaise.toInt();

    if (rupees == null || rupees <= 0) {
      setState(() {
        _errorMessage = 'Enter a valid payment amount greater than zero';
      });
      return;
    }

    final amountPaise = (rupees * 100).round();
    if (amountPaise > debtPaise) {
      setState(() {
        _errorMessage =
            'Payment amount cannot exceed outstanding balance of ${_formatRupees(debtPaise)}';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final creditRepo = ref.read(creditRepositoryProvider);
    final result = await creditRepo.recordCreditPayment(
      customerId: widget.customer.id,
      amountPaise: amountPaise,
      paymentMethod: _paymentMethod,
      notes: _notesController.text,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ref.invalidate(customerDetailProvider(widget.customer.id));
      ref.invalidate(customerSalesHistoryProvider(widget.customer.id));
      ref.invalidate(customerLedgerStreamProvider(widget.customer.id));
      ref.invalidate(customerPurchaseSummaryProvider(widget.customer.id));
      ref.invalidate(shopCreditSummaryProvider);
      ref.invalidate(indebtedCustomersStreamProvider);

      setState(() {
        _isSaving = false;
        _isSuccess = true;
        _paidPaise = amountPaise;
        _remainingPaise = (debtPaise - amountPaise).clamp(0, debtPaise);
      });
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage =
            result.failureOrNull?.message ?? 'Failed to record payment';
      });
    }
  }

  void _setAmount(double rupees) {
    _amountController.text = rupees.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final debtPaise = widget.customer.currentDebtPaise.toInt();
    final debtRupees = debtPaise / 100.0;

    final double enteredRupees =
        double.tryParse(_amountController.text.trim()) ?? 0.0;
    final int enteredPaise = (enteredRupees * 100).round();
    final int previewRemainingPaise =
        (debtPaise - enteredPaise).clamp(0, debtPaise);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: KiranaRadius.borderLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(KiranaSpacing.xl),
          child: _isSuccess
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 64, color: KiranaColors.success),
                    const SizedBox(height: KiranaSpacing.md),
                    Text(
                      'Payment Recorded Successfully',
                      style: KiranaTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: KiranaColors.success,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: KiranaSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(KiranaSpacing.md),
                      decoration: BoxDecoration(
                        color: KiranaColors.surfaceVariant,
                        borderRadius: KiranaRadius.borderMd,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Paid Amount:'),
                              Text(
                                _formatRupees(_paidPaise),
                                style: KiranaTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: KiranaColors.success,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: KiranaSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Remaining Due:'),
                              Text(
                                _remainingPaise == 0
                                    ? 'Settled (₹0)'
                                    : _formatRupees(_remainingPaise),
                                style: KiranaTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _remainingPaise == 0
                                      ? KiranaColors.success
                                      : KiranaColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KiranaSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KiranaColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Record Customer Payment',
                              style: KiranaTypography.headlineMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                          ],
                        ),
                        const SizedBox(height: KiranaSpacing.sm),

                        // Customer Summary Banner
                        Container(
                          padding: const EdgeInsets.all(KiranaSpacing.md),
                          decoration: BoxDecoration(
                            color: KiranaColors.secondaryContainer
                                .withValues(alpha: 0.5),
                            borderRadius: KiranaRadius.borderMd,
                            border: Border.all(
                                color: KiranaColors.secondary
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: KiranaColors.secondary,
                                foregroundColor: Colors.white,
                                child:
                                    Text(widget.customer.name[0].toUpperCase()),
                              ),
                              const SizedBox(width: KiranaSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.customer.name,
                                      style:
                                          KiranaTypography.titleMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Phone: ${widget.customer.phone}',
                                      style: KiranaTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Amount Due',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: KiranaColors.neutral600)),
                                  Text(
                                    _formatRupees(debtPaise),
                                    style:
                                        KiranaTypography.titleMedium.copyWith(
                                      color: KiranaColors.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: KiranaSpacing.md),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(KiranaSpacing.md),
                            decoration: BoxDecoration(
                              color: KiranaColors.errorContainer,
                              borderRadius: KiranaRadius.borderSm,
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red[900],
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: KiranaSpacing.md),
                        ],

                        // Payment Amount Input
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Payment Amount (₹) *',
                            hintText: 'e.g. 500',
                            prefixIcon: Icon(Icons.currency_rupee),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter payment amount';
                            }
                            final amt = double.tryParse(val.trim());
                            if (amt == null || amt <= 0) {
                              return 'Enter a valid positive amount';
                            }
                            if ((amt * 100).round() > debtPaise) {
                              return 'Cannot exceed amount due of ${_formatRupees(debtPaise)}';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: KiranaSpacing.xs),

                        // Quick Action Amount Chips
                        Wrap(
                          spacing: KiranaSpacing.xs,
                          children: [
                            if (debtRupees >= 500)
                              ActionChip(
                                label: const Text('₹500'),
                                onPressed: () => _setAmount(500),
                              ),
                            if (debtRupees >= 1000)
                              ActionChip(
                                label: const Text('₹1,000'),
                                onPressed: () => _setAmount(1000),
                              ),
                            ActionChip(
                              avatar: const Icon(Icons.check_circle_outline,
                                  size: 16),
                              label: Text('Full (${_formatRupees(debtPaise)})'),
                              onPressed: () => _setAmount(debtRupees),
                            ),
                          ],
                        ),
                        const SizedBox(height: KiranaSpacing.md),

                        // Live Payment Breakdown Summary Preview Card
                        if (enteredPaise > 0) ...[
                          Container(
                            padding: const EdgeInsets.all(KiranaSpacing.sm),
                            decoration: BoxDecoration(
                              color: KiranaColors.primaryContainer
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: KiranaColors.primary
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Amount Due:',
                                        style: TextStyle(fontSize: 12)),
                                    Text(_formatRupees(debtPaise),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Payment Amount:',
                                        style: TextStyle(fontSize: 12)),
                                    Text('-${_formatRupees(enteredPaise)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: KiranaColors.success)),
                                  ],
                                ),
                                const Divider(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Remaining Due:',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                      previewRemainingPaise == 0
                                          ? 'Settled (₹0)'
                                          : _formatRupees(
                                              previewRemainingPaise),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: previewRemainingPaise == 0
                                            ? KiranaColors.success
                                            : KiranaColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: KiranaSpacing.md),
                        ],

                        // Payment Method Selector
                        const Text('Payment Method',
                            style: KiranaTypography.labelLarge),
                        const SizedBox(height: KiranaSpacing.xs),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'Cash',
                              label: Text('Cash'),
                              icon: Icon(Icons.payments_outlined),
                            ),
                            ButtonSegment(
                              value: 'UPI',
                              label: Text('UPI'),
                              icon: Icon(Icons.qr_code),
                            ),
                            ButtonSegment(
                              value: 'Card',
                              label: Text('Card'),
                              icon: Icon(Icons.credit_card),
                            ),
                          ],
                          selected: {_paymentMethod},
                          onSelectionChanged: (set) {
                            setState(() {
                              _paymentMethod = set.first;
                            });
                          },
                        ),
                        const SizedBox(height: KiranaSpacing.md),

                        // Notes / Remarks
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes / Reference (Optional)',
                            hintText:
                                'e.g. UPI Ref #12345 or Cash handed in shop',
                            prefixIcon: Icon(Icons.note_alt_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: KiranaSpacing.xl),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: KiranaSpacing.md),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KiranaColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              onPressed: _isSaving ? null : _submit,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle),
                              label: const Text('Record Payment'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
