import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../billing/domain/models/bill_model.dart';
import '../../../settings/presentation/providers/shop_settings_provider.dart';
import '../../domain/services/pdf_export_share_service.dart';
import '../../domain/services/pdf_receipt_service.dart';

class PdfReceiptPreviewScreen extends ConsumerWidget {
  final BillModel bill;
  final bool isOfflineCached;

  const PdfReceiptPreviewScreen({
    super.key,
    required this.bill,
    this.isOfflineCached = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfService = ref.watch(pdfReceiptServiceProvider);
    final shareService = ref.watch(pdfExportShareServiceProvider);
    final shopSettings = ref.watch(shopSettingsNotifierProvider).settings;

    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Preview #${bill.billNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share PDF',
            onPressed: () async {
              final pdfBytes = await pdfService.generateReceiptPdf(
                bill: bill,
                shopSettings: shopSettings,
              );
              await shareService.sharePdf(
                pdfBytes: pdfBytes,
                fileName: 'Receipt_${bill.billNumber}',
                subject: 'Bill Receipt #${bill.billNumber}',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Save PDF',
            onPressed: () async {
              final pdfBytes = await pdfService.generateReceiptPdf(
                bill: bill,
                shopSettings: shopSettings,
              );
              final file = await shareService.savePdfToTempFolder(
                pdfBytes: pdfBytes,
                fileName: 'Receipt_${bill.billNumber}',
              );
              if (context.mounted && file != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Saved PDF to temporary storage: ${file.path}'),
                    backgroundColor: KiranaColors.success,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (isOfflineCached)
            Container(
              width: double.infinity,
              color: KiranaColors.warning.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(
                horizontal: KiranaSpacing.md,
                vertical: KiranaSpacing.xs,
              ),
              child: Row(
                children: [
                  const Icon(Icons.offline_pin_outlined,
                      size: 16, color: KiranaColors.warning),
                  const SizedBox(width: KiranaSpacing.xs),
                  Text(
                    'Offline Cached Bill · Generated from local storage',
                    style: KiranaTypography.bodySmall.copyWith(
                      color: KiranaColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: PdfPreview(
              build: (format) => pdfService.generateReceiptPdf(
                bill: bill,
                shopSettings: shopSettings,
              ),
              allowPrinting: true,
              allowSharing: true,
              canChangeOrientation: false,
              canChangePageFormat: false,
              pdfFileName: 'Receipt_${bill.billNumber}.pdf',
            ),
          ),
        ],
      ),
    );
  }
}
