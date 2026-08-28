import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../billing/domain/models/bill_model.dart';
import '../../../settings/presentation/providers/shop_settings_provider.dart';
import '../../domain/models/printer_device_model.dart';
import '../../domain/services/printer_service.dart';
import '../../domain/services/receipt_pdf_builder.dart';

// ─── State ───────────────────────────────────────────────────────────────────

enum PrinterTestStatus { idle, testing, ok, failed }

class PrinterState {
  final PrinterDeviceModel? selectedPrinter;
  final List<PrinterDeviceModel> availablePrinters;
  final bool isScanning;
  final bool isConnecting;
  final bool isPrinting;
  final String? errorMessage;
  final String? successMessage;

  // Per-job settings (independent from connected device)
  final bool isColor;
  final PrinterPageFormat pageFormat;
  final int copies;
  final PrinterTestStatus testStatus;

  const PrinterState({
    this.selectedPrinter,
    this.availablePrinters = const [],
    this.isScanning = false,
    this.isConnecting = false,
    this.isPrinting = false,
    this.errorMessage,
    this.successMessage,
    this.isColor = true,
    this.pageFormat = PrinterPageFormat.roll80mm,
    this.copies = 1,
    this.testStatus = PrinterTestStatus.idle,
  });

  // Legacy compat
  PrinterPaperWidth get paperWidth => pageFormat.toPaperWidth;
  bool get isConnected => selectedPrinter?.isConnected ?? false;

  PrinterState copyWith({
    PrinterDeviceModel? selectedPrinter,
    List<PrinterDeviceModel>? availablePrinters,
    bool? isScanning,
    bool? isConnecting,
    bool? isPrinting,
    String? errorMessage,
    String? successMessage,
    bool? isColor,
    PrinterPageFormat? pageFormat,
    int? copies,
    PrinterTestStatus? testStatus,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearPrinter = false,
  }) {
    return PrinterState(
      selectedPrinter:
          clearPrinter ? null : (selectedPrinter ?? this.selectedPrinter),
      availablePrinters: availablePrinters ?? this.availablePrinters,
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      isPrinting: isPrinting ?? this.isPrinting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      isColor: isColor ?? this.isColor,
      pageFormat: pageFormat ?? this.pageFormat,
      copies: copies ?? this.copies,
      testStatus: testStatus ?? this.testStatus,
    );
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final receiptPdfBuilderProvider = Provider<ReceiptPdfBuilder>((ref) {
  return ReceiptPdfBuilder();
});

final printerServiceProvider = Provider<PrinterService>((ref) {
  final pdfBuilder = ref.watch(receiptPdfBuilderProvider);
  return NetworkPrinterServiceImpl(pdfBuilder: pdfBuilder);
});

// ─── Notifier ────────────────────────────────────────────────────────────────

class PrinterNotifier extends StateNotifier<PrinterState> {
  final PrinterService _printerService;
  final ReceiptPdfBuilder _pdfBuilder;
  final Ref _ref;

  PrinterNotifier({
    required PrinterService printerService,
    required ReceiptPdfBuilder pdfBuilder,
    required Ref ref,
  })  : _printerService = printerService,
        _pdfBuilder = pdfBuilder,
        _ref = ref,
        super(const PrinterState()) {
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJsonStr = prefs.getString('saved_wifi_printer');
      if (savedJsonStr != null) {
        final map = jsonDecode(savedJsonStr) as Map<String, dynamic>;
        final device = PrinterDeviceModel.fromJson(map);
        final pageFormat = PrinterPageFormatExtension.fromString(
            map['page_format'] as String?);
        final isColor = map['is_color'] as bool? ?? true;
        final copies = map['copies'] as int? ?? 1;
        state = state.copyWith(
          selectedPrinter: device,
          pageFormat: pageFormat,
          isColor: isColor,
          copies: copies,
        );
      }
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    try {
      if (state.selectedPrinter == null) return;
      final prefs = await SharedPreferences.getInstance();
      final map = state.selectedPrinter!
          .copyWith(
            isColor: state.isColor,
            pageFormat: state.pageFormat,
            copies: state.copies,
          )
          .toJson();
      await prefs.setString('saved_wifi_printer', jsonEncode(map));
    } catch (_) {}
  }

  // ── Scanning ──────────────────────────────────────────────────────────────

  Future<void> scanPrinters() async {
    state = state.copyWith(isScanning: true, clearError: true);

    final result = await _printerService.scanForPrinters();

    if (result.isSuccess) {
      state = state.copyWith(
        isScanning: false,
        availablePrinters: result.dataOrNull ?? [],
      );
    } else {
      state = state.copyWith(
        isScanning: false,
        errorMessage: result.failureOrNull?.message,
      );
    }
  }

  // ── Connect / Disconnect ──────────────────────────────────────────────────

  Future<bool> selectAndConnectPrinter(PrinterDeviceModel device) async {
    state = state.copyWith(isConnecting: true, clearError: true);

    final result = await _printerService.connectPrinter(device);

    if (result.isSuccess) {
      final connected = result.dataOrNull!;
      state = state.copyWith(
        isConnecting: false,
        selectedPrinter: connected,
        successMessage: '✓ Connected to ${connected.name}',
      );
      await _saveSettings();
      return true;
    } else {
      state = state.copyWith(
        isConnecting: false,
        errorMessage: result.failureOrNull?.message,
      );
      return false;
    }
  }

  Future<void> disconnectPrinter() async {
    await _printerService.disconnectPrinter();
    state = state.copyWith(
      clearPrinter: true,
      successMessage: 'Printer disconnected.',
      testStatus: PrinterTestStatus.idle,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_wifi_printer');
    } catch (_) {}
  }

  // ── Connection Test ───────────────────────────────────────────────────────

  Future<void> testConnection() async {
    if (state.selectedPrinter == null) return;
    state =
        state.copyWith(testStatus: PrinterTestStatus.testing, clearError: true);

    final result = await _printerService.connectPrinter(state.selectedPrinter!);

    if (result.isSuccess) {
      state = state.copyWith(
        testStatus: PrinterTestStatus.ok,
        selectedPrinter: result.dataOrNull,
        successMessage: '✓ Printer is reachable',
      );
    } else {
      state = state.copyWith(
        testStatus: PrinterTestStatus.failed,
        errorMessage: result.failureOrNull?.message,
      );
    }
  }

  // ── Print Settings ────────────────────────────────────────────────────────

  void setColorMode(bool isColor) {
    state = state.copyWith(isColor: isColor);
    _saveSettings();
  }

  void setPageFormat(PrinterPageFormat format) {
    state = state.copyWith(pageFormat: format);
    _saveSettings();
  }

  void setCopies(int copies) {
    final clamped = copies.clamp(1, 9);
    state = state.copyWith(copies: clamped);
    _saveSettings();
  }

  // Legacy compat
  void setPaperWidth(PrinterPaperWidth width) {
    final format = width == PrinterPaperWidth.mm58
        ? PrinterPageFormat.roll58mm
        : PrinterPageFormat.roll80mm;
    setPageFormat(format);
  }

  // ── Printing ──────────────────────────────────────────────────────────────

  Future<bool> printReceipt(BillModel bill) async {
    if (state.selectedPrinter == null) {
      state = state.copyWith(
        errorMessage: 'No printer selected. Please select a WiFi printer.',
      );
      return false;
    }

    state = state.copyWith(isPrinting: true, clearError: true);

    final settingsState = _ref.read(shopSettingsNotifierProvider);
    final shopSettings = settingsState.settings;

    // Build PDF with current settings
    final printerWithSettings = state.selectedPrinter!.copyWith(
      isColor: state.isColor,
      pageFormat: state.pageFormat,
      copies: state.copies,
    );

    bool overallSuccess = true;
    String? lastError;

    for (int i = 0; i < state.copies; i++) {
      try {
        final Uint8List pdfBytes = await _pdfBuilder.buildReceiptPdf(
          bill: bill,
          shopSettings: shopSettings,
          printerSettings: printerWithSettings,
        );

        final result = await (_printerService as NetworkPrinterServiceImpl)
            .printPdf(printer: printerWithSettings, pdfBytes: pdfBytes);

        if (!result.isSuccess) {
          overallSuccess = false;
          lastError = result.failureOrNull?.message;
          break;
        }
      } catch (e) {
        overallSuccess = false;
        lastError = e.toString();
        break;
      }
    }

    if (overallSuccess) {
      state = state.copyWith(
        isPrinting: false,
        successMessage: state.copies > 1
            ? '✓ ${state.copies} copies printed!'
            : '✓ Receipt printed!',
      );
      return true;
    } else {
      state = state.copyWith(
        isPrinting: false,
        errorMessage: lastError ?? 'Print failed.',
      );
      return false;
    }
  }

  Future<bool> sendTestPrint() async {
    if (state.selectedPrinter == null) {
      state = state.copyWith(errorMessage: 'No printer selected.');
      return false;
    }

    state = state.copyWith(isPrinting: true, clearError: true);

    final printerWithSettings = state.selectedPrinter!.copyWith(
      isColor: state.isColor,
      pageFormat: state.pageFormat,
    );

    final result = await _printerService.testPrint(printerWithSettings);

    if (result.isSuccess) {
      state = state.copyWith(
        isPrinting: false,
        successMessage: '✓ Test page sent to ${state.selectedPrinter!.name}',
      );
      return true;
    } else {
      state = state.copyWith(
        isPrinting: false,
        errorMessage: result.failureOrNull?.message,
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final printerNotifierProvider =
    StateNotifierProvider<PrinterNotifier, PrinterState>((ref) {
  return PrinterNotifier(
    printerService: ref.watch(printerServiceProvider),
    pdfBuilder: ref.watch(receiptPdfBuilderProvider),
    ref: ref,
  );
});
