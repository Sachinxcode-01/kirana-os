import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/supplier_model.dart';
import '../providers/supplier_provider.dart';

class RecordSupplierPaymentDialog extends ConsumerStatefulWidget {
  final SupplierModel supplier;

  const RecordSupplierPaymentDialog({super.key, required this.supplier});

  static Future<bool?> show(BuildContext context, SupplierModel supplier) {
    return showDialog<bool>(
      context: context,
      builder: (context) => RecordSupplierPaymentDialog(supplier: supplier),
    );
  }

  @override
  ConsumerState<RecordSupplierPaymentDialog> createState() =>
      _RecordSupplierPaymentDialogState();
}

class _RecordSupplierPaymentDialogState
    extends ConsumerState<RecordSupplierPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  String _paymentMethod = 'Bank';
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  static String _formatRupees(int paise) {
    final double rupees = paise / 100.0;
    return '₹${rupees.toStringAsFixed(2)}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final rupeesText = _amountController.text.trim();
    final double? rupees = double.tryParse(rupeesText);
    if (rupees == null || rupees <= 0) {
      setState(() {
        _errorMessage = 'Enter a valid payment amount greater than zero';
      });
      return;
    }

    final amountPaise = (rupees * 100).round();
    final authState = ref.read(authNotifierProvider);
    final shopId = authState.activeShopId;
    if (shopId == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final repo = ref.read(supplierRepositoryProvider);
    final result = await repo.recordSupplierPayment(
      supplierId: widget.supplier.id,
      shopId: shopId,
      amountPaise: amountPaise,
      paymentMethod: _paymentMethod,
      notes: _notesController.text,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ref.read(suppliersListNotifierProvider.notifier).loadSuppliers();
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage = result.failureOrNull?.message ??
            'Failed to record supplier payment';
      });
    }
  }

  void _setAmount(double rupees) {
    _amountController.text = rupees.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final debtPaise = widget.supplier.currentBalancePaise;
    final debtRupees = debtPaise / 100.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: KiranaRadius.borderLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(KiranaSpacing.xl),
          child: SingleChildScrollView(
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
                        'Record Supplier Payment',
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

                  // Supplier Banner
                  Container(
                    padding: const EdgeInsets.all(KiranaSpacing.md),
                    decoration: BoxDecoration(
                      color:
                          KiranaColors.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: KiranaRadius.borderMd,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: KiranaColors.primary,
                          foregroundColor: Colors.white,
                          child: Text(widget.supplier.name[0].toUpperCase()),
                        ),
                        const SizedBox(width: KiranaSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.supplier.name,
                                style: KiranaTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Phone: ${widget.supplier.phone}',
                                  style: KiranaTypography.bodySmall),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Payable Balance',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: KiranaColors.neutral600)),
                            Text(
                              _formatRupees(debtPaise),
                              style: KiranaTypography.titleMedium.copyWith(
                                color: KiranaColors.primary,
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
                        ),
                      ),
                    ),
                    const SizedBox(height: KiranaSpacing.md),
                  ],

                  // Payment Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Payment Paid (₹) *',
                      hintText: 'e.g. 5000',
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
                      return null;
                    },
                  ),
                  const SizedBox(height: KiranaSpacing.xs),

                  Wrap(
                    spacing: KiranaSpacing.xs,
                    children: [
                      if (debtRupees >= 1000)
                        ActionChip(
                          label: const Text('₹1,000'),
                          onPressed: () => _setAmount(1000),
                        ),
                      if (debtRupees >= 5000)
                        ActionChip(
                          label: const Text('₹5,000'),
                          onPressed: () => _setAmount(5000),
                        ),
                      ActionChip(
                        avatar:
                            const Icon(Icons.check_circle_outline, size: 16),
                        label: Text('Full (${_formatRupees(debtPaise)})'),
                        onPressed: () => _setAmount(debtRupees),
                      ),
                    ],
                  ),
                  const SizedBox(height: KiranaSpacing.md),

                  // Payment Method
                  const Text('Payment Mode',
                      style: KiranaTypography.labelLarge),
                  const SizedBox(height: KiranaSpacing.xs),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Bank',
                        label: Text('Bank Transfer'),
                        icon: Icon(Icons.account_balance),
                      ),
                      ButtonSegment(
                        value: 'UPI',
                        label: Text('UPI'),
                        icon: Icon(Icons.qr_code),
                      ),
                      ButtonSegment(
                        value: 'Cash',
                        label: Text('Cash'),
                        icon: Icon(Icons.payments_outlined),
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

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes / UTR Reference (Optional)',
                      hintText: 'e.g. NEFT UTR #998811',
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
                              horizontal: 20, vertical: 12),
                        ),
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
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
