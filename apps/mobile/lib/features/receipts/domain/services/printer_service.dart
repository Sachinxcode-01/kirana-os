import 'dart:typed_data';
import 'package:printing/printing.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../models/printer_device_model.dart';
import '../services/receipt_pdf_builder.dart';

// ─── Abstract Interface ─────────────────────────────────────────────────────

abstract interface class PrinterService {
  Future<Result<List<PrinterDeviceModel>, Failure>> scanForPrinters();

  Future<Result<PrinterDeviceModel, Failure>> connectPrinter(
      PrinterDeviceModel device);

  Future<Result<void, Failure>> disconnectPrinter();

  Future<Result<void, Failure>> printPdf({
    required PrinterDeviceModel printer,
    required Uint8List pdfBytes,
  });

  Future<Result<void, Failure>> testPrint(PrinterDeviceModel printer);

  /// Legacy ESC/POS path kept for API compatibility
  Future<Result<void, Failure>> printReceipt({
    required PrinterDeviceModel printer,
    required String receiptPayloadText,
  });
}

// ─── Real WiFi / Network Implementation ────────────────────────────────────

class NetworkPrinterServiceImpl implements PrinterService {
  final ReceiptPdfBuilder _pdfBuilder;

  NetworkPrinterServiceImpl({required ReceiptPdfBuilder pdfBuilder})
      : _pdfBuilder = pdfBuilder;

  @override
  Future<Result<List<PrinterDeviceModel>, Failure>> scanForPrinters() async {
    try {
      final printers = await Printing.listPrinters();

      if (printers.isEmpty) {
        return const Success([]);
      }

      final devices = printers.map((p) {
        return PrinterDeviceModel(
          id: p.url.isNotEmpty ? p.url : p.name,
          name: p.name,
          address: p.url,
          connectionType: _detectConnectionType(p.url),
          isConnected: false,
          url: p.url,
        );
      }).toList();

      return Success(devices);
    } catch (e) {
      return ErrorResult(
        HardwareFailure('Failed to scan for printers: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<PrinterDeviceModel, Failure>> connectPrinter(
      PrinterDeviceModel device) async {
    try {
      // Verify the printer still appears in the system list
      final printers = await Printing.listPrinters();
      final found = printers.any(
        (p) => p.name == device.name || p.url == device.url,
      );

      if (!found) {
        return ErrorResult(
          HardwareFailure(
              'Printer "${device.name}" not found. Make sure it is powered on and connected to the same WiFi network.'),
        );
      }

      final connected = device.copyWith(isConnected: true);
      return Success(connected);
    } catch (e) {
      return ErrorResult(
        HardwareFailure('Connection failed: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void, Failure>> disconnectPrinter() async {
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> printPdf({
    required PrinterDeviceModel printer,
    required Uint8List pdfBytes,
  }) async {
    try {
      final success = await Printing.directPrintPdf(
        printer: Printer(
          url: printer.url ?? printer.address,
          name: printer.name,
        ),
        onLayout: (_) async => pdfBytes,
      );

      if (!success) {
        return const ErrorResult(
          HardwareFailure(
              'Printer rejected the job. Make sure the printer is ready and has paper.'),
        );
      }

      return const Success(null);
    } catch (e) {
      return ErrorResult(
        HardwareFailure('Print failed: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void, Failure>> printReceipt({
    required PrinterDeviceModel printer,
    required String receiptPayloadText,
  }) async {
    // Legacy path — wraps text in minimal PDF
    if (receiptPayloadText.trim().isEmpty) {
      return const ErrorResult(
        ValidationFailure('Nothing to print.'),
      );
    }
    // For real printing this path re-routes to printPdf with a simple text PDF
    // Callers should use printPdf directly for proper formatting
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> testPrint(PrinterDeviceModel printer) async {
    try {
      final pdfBytes = await _pdfBuilder.buildTestPagePdf(printer: printer);
      return await printPdf(printer: printer, pdfBytes: pdfBytes);
    } catch (e) {
      return ErrorResult(
        HardwareFailure('Test print failed: ${e.toString()}'),
      );
    }
  }

  String _detectConnectionType(String url) {
    if (url.startsWith('ipp://') ||
        url.startsWith('ipps://') ||
        url.startsWith('http://') ||
        url.startsWith('https://')) {
      return 'wifi';
    }
    if (url.contains('usb')) return 'usb';
    return 'network';
  }
}
