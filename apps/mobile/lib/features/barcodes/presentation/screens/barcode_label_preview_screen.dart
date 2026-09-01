import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/colors.dart';

class BarcodeLabelPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String title;

  const BarcodeLabelPreviewScreen({
    super.key,
    required this.pdfBytes,
    this.title = 'Barcode Labels Preview',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: KiranaColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share PDF',
            onPressed: () async {
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: 'kirana_barcode_labels_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => pdfBytes,
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        dynamicLayout: false,
        pdfFileName: 'kirana_barcode_labels.pdf',
      ),
    );
  }
}
