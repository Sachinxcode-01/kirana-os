import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class PdfExportShareService {
  Future<File?> savePdfToTempFolder({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cleanName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final file = File('${tempDir.path}/$cleanName.pdf');
      await file.writeAsBytes(pdfBytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<bool> sharePdf({
    required Uint8List pdfBytes,
    required String fileName,
    String? subject,
  }) async {
    try {
      final cleanName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '$cleanName.pdf',
        subject: subject,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final pdfExportShareServiceProvider = Provider<PdfExportShareService>((ref) {
  return PdfExportShareService();
});
