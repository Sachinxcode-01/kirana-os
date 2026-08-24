import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';

// --- BARCODE SCANNER BRIDGE ---
class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final _manualCodeController = TextEditingController();

  @override
  void dispose() {
    _manualCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Product Barcode')),
      body: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.xl),
        child: Column(
          children: [
            // Camera Scanner Viewport Mockup
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 240,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: KiranaColors.primaryLight,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.qr_code_2,
                          size: 64,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(height: KiranaSpacing.lg),
                    Text(
                      'Align barcode inside frame or use USB gun',
                      style: KiranaTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: KiranaSpacing.xl),

            // Manual Barcode Input Fallback
            AppTextField(
              label: 'Manual Barcode Entry',
              hint: 'e.g. 8901030383742',
              controller: _manualCodeController,
              keyboardType: TextInputType.number,
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  if (_manualCodeController.text.isNotEmpty) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            const SizedBox(height: KiranaSpacing.md),
            AppButton(
              label: 'Add Scanned Item to Cart',
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
