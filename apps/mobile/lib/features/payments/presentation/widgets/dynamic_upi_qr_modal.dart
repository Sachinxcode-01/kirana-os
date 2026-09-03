import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';

/// Modal bottom sheet presenting a dynamic, NPCI-compliant Bharat UPI QR Code
/// with live countdown expiry timer and cashier confirmation actions.
class DynamicUpiQrModal extends ConsumerStatefulWidget {
  final String billNumber;
  final int amountPaise;
  final String merchantName;
  final String upiId;
  final Future<bool> Function() onConfirmPayment;

  const DynamicUpiQrModal({
    super.key,
    required this.billNumber,
    required this.amountPaise,
    this.merchantName = 'Sri Lakshmi Provision',
    this.upiId = 'srilakshmi.kirana@okhdfcbank',
    required this.onConfirmPayment,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String billNumber,
    required int amountPaise,
    String merchantName = 'Sri Lakshmi Provision',
    String upiId = 'srilakshmi.kirana@okhdfcbank',
    required Future<bool> Function() onConfirmPayment,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DynamicUpiQrModal(
        billNumber: billNumber,
        amountPaise: amountPaise,
        merchantName: merchantName,
        upiId: upiId,
        onConfirmPayment: onConfirmPayment,
      ),
    );
  }

  @override
  ConsumerState<DynamicUpiQrModal> createState() => _DynamicUpiQrModalState();
}

class _DynamicUpiQrModalState extends ConsumerState<DynamicUpiQrModal> {
  static const int _totalExpirySeconds = 180; // 3 minutes standard UPI timeout
  late int _remainingSeconds;
  Timer? _timer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _totalExpirySeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _restartTimer() {
    setState(() {
      _remainingSeconds = _totalExpirySeconds;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _amountRupees {
    return (widget.amountPaise / 100).toStringAsFixed(2);
  }

  /// Builds standard NPCI-compliant UPI Intent URI string
  String get _upiIntentUri {
    final encodedPn = Uri.encodeComponent(widget.merchantName);
    final encodedNote = Uri.encodeComponent('KiranaOS Bill ${widget.billNumber}');
    return 'upi://pay?pa=${widget.upiId}&pn=$encodedPn&am=$_amountRupees&cu=INR&tr=${widget.billNumber}&tn=$encodedNote';
  }

  /// Image QR code URL for visual rendering
  String get _qrImageUrl {
    final encodedPayload = Uri.encodeComponent(_upiIntentUri);
    return 'https://api.qrserver.com/v1/create-qr-code/?size=260x260&margin=8&data=$encodedPayload';
  }

  String _formatTimer(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _handleConfirm() async {
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final success = await widget.onConfirmPayment();
      if (mounted) {
        if (success) {
          HapticFeedback.heavyImpact();
          Navigator.of(context).pop(true);
        } else {
          setState(() => _isProcessing = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _copyPaymentLink() {
    Clipboard.setData(ClipboardData(text: _upiIntentUri));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UPI payment intent link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remainingSeconds == 0;
    final isUrgent = _remainingSeconds <= 30 && !isExpired;

    return Container(
      decoration: const BoxDecoration(
        color: KiranaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        KiranaSpacing.xl,
        KiranaSpacing.md,
        KiranaSpacing.xl,
        MediaQuery.of(context).viewInsets.bottom + KiranaSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: KiranaColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: KiranaSpacing.md),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: KiranaColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.qr_code_2,
                      color: KiranaColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: KiranaSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dynamic Bharat UPI QR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: KiranaColors.neutral900,
                        ),
                      ),
                      Text(
                        'Bill: ${widget.billNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: KiranaColors.neutral500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: KiranaColors.neutral600),
                onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
              ),
            ],
          ),
          const Divider(height: KiranaSpacing.lg),

          // Amount Payable Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: KiranaColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: KiranaColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Amount Payable',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: KiranaColors.neutral700,
                  ),
                ),
                Text(
                  widget.amountPaise.toRupeesString(),
                  style: KiranaTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    color: KiranaColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KiranaSpacing.lg),

          // QR Code Display Card
          Container(
            padding: const EdgeInsets.all(KiranaSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isExpired
                    ? KiranaColors.error
                    : isUrgent
                        ? KiranaColors.warning
                        : KiranaColors.primary.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isExpired
                          ? KiranaColors.error
                          : KiranaColors.primary)
                      .withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Network QR Code Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _qrImageUrl,
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 200,
                        height: 200,
                        color: KiranaColors.surfaceVariant,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        color: KiranaColors.surfaceVariant,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.qr_code, size: 64, color: KiranaColors.neutral400),
                            const SizedBox(height: KiranaSpacing.xs),
                            Text(
                              widget.upiId,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Expired Overlay
                if (isExpired)
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_off, color: Colors.white, size: 36),
                        const SizedBox(height: KiranaSpacing.xs),
                        const Text(
                          'QR Code Expired',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: KiranaSpacing.sm),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KiranaColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: _restartTimer,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Generate New'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ).animate().fadeIn(duration: 250.ms).scale(begin: const Offset(0.96, 0.96)),
          const SizedBox(height: KiranaSpacing.md),

          // Countdown & Telemetry Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isExpired
                      ? KiranaColors.error.withValues(alpha: 0.1)
                      : isUrgent
                          ? KiranaColors.warningContainer
                          : KiranaColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isExpired
                        ? KiranaColors.error
                        : isUrgent
                            ? KiranaColors.warning
                            : KiranaColors.outlineVariant,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: isExpired
                          ? KiranaColors.error
                          : isUrgent
                              ? KiranaColors.secondaryDark
                              : KiranaColors.neutral700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isExpired
                          ? 'Session timed out'
                          : 'Valid for: ${_formatTimer(_remainingSeconds)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'JetBrains Mono',
                        color: isExpired
                            ? KiranaColors.error
                            : isUrgent
                                ? KiranaColors.secondaryDark
                                : KiranaColors.neutral800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KiranaSpacing.xs),

          // Supported Apps banner
          const Text(
            'Scan with GPay, PhonePe, Paytm, BHIM, or any Banking App',
            style: TextStyle(fontSize: 11, color: KiranaColors.neutral500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KiranaSpacing.lg),

          // Cashier Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _copyPaymentLink,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Link'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: KiranaSpacing.sm),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: 'CONFIRM PAYMENT',
                  icon: Icons.check_circle_outline,
                  isLoading: _isProcessing,
                  onPressed: isExpired ? _restartTimer : _handleConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
