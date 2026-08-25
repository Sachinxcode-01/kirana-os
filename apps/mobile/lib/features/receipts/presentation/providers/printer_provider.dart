import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../billing/domain/models/bill_model.dart';
import '../../../settings/presentation/providers/shop_settings_provider.dart';
import '../../domain/models/printer_device_model.dart';
import '../../domain/services/printer_service.dart';
import '../../domain/services/receipt_formatter_service.dart';

class PrinterState {
  final PrinterDeviceModel? selectedPrinter;
  final List<PrinterDeviceModel> availablePrinters;
  final bool isScanning;
  final bool isConnecting;
  final bool isPrinting;
  final String? errorMessage;
  final String? successMessage;
  final PrinterPaperWidth paperWidth;

  const PrinterState({
    this.selectedPrinter,
    this.availablePrinters = const [],
    this.isScanning = false,
    this.isConnecting = false,
    this.isPrinting = false,
    this.errorMessage,
    this.successMessage,
    this.paperWidth = PrinterPaperWidth.mm58,
  });

  bool get isConnected => selectedPrinter?.isConnected ?? false;

  PrinterState copyWith({
    PrinterDeviceModel? selectedPrinter,
    List<PrinterDeviceModel>? availablePrinters,
    bool? isScanning,
    bool? isConnecting,
    bool? isPrinting,
    String? errorMessage,
    String? successMessage,
    PrinterPaperWidth? paperWidth,
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
      paperWidth: paperWidth ?? this.paperWidth,
    );
  }
}

final receiptFormatterServiceProvider =
    Provider<ReceiptFormatterService>((ref) {
  return ReceiptFormatterService();
});

final printerServiceProvider = Provider<PrinterService>((ref) {
  return LocalPrinterServiceImpl();
});

class PrinterNotifier extends StateNotifier<PrinterState> {
  final PrinterService _printerService;
  final ReceiptFormatterService _formatterService;
  final Ref _ref;

  PrinterNotifier({
    required PrinterService printerService,
    required ReceiptFormatterService formatterService,
    required Ref ref,
  })  : _printerService = printerService,
        _formatterService = formatterService,
        _ref = ref,
        super(const PrinterState()) {
    _loadSavedPrinter();
  }

  Future<void> _loadSavedPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJsonStr = prefs.getString('saved_thermal_printer');
      if (savedJsonStr != null) {
        final map = jsonDecode(savedJsonStr) as Map<String, dynamic>;
        final device = PrinterDeviceModel.fromJson(map);
        state = state.copyWith(
          selectedPrinter: device,
          paperWidth: device.paperWidth,
        );
      }
    } catch (_) {}
  }

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

  Future<bool> selectAndConnectPrinter(PrinterDeviceModel device) async {
    state = state.copyWith(isConnecting: true, clearError: true);

    final result = await _printerService.connectPrinter(device);

    if (result.isSuccess) {
      final connected = result.dataOrNull!;
      state = state.copyWith(
        isConnecting: false,
        selectedPrinter: connected,
        paperWidth: connected.paperWidth,
        successMessage: 'Connected to ${connected.name}',
      );

      // Save preference locally
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'saved_thermal_printer',
          jsonEncode(connected.toJson()),
        );
      } catch (_) {}

      return true;
    } else {
      state = state.copyWith(
        isConnecting: false,
        errorMessage: result.failureOrNull?.message,
      );
      return false;
    }
  }

  void setPaperWidth(PrinterPaperWidth width) {
    state = state.copyWith(paperWidth: width);
    if (state.selectedPrinter != null) {
      final updated = state.selectedPrinter!.copyWith(paperWidth: width);
      state = state.copyWith(selectedPrinter: updated);
    }
  }

  Future<bool> printReceipt(BillModel bill) async {
    if (state.selectedPrinter == null) {
      state = state.copyWith(
        errorMessage:
            'Printer unavailable: No printer selected. Please select a printer.',
      );
      return false;
    }

    state = state.copyWith(isPrinting: true, clearError: true);

    final settingsState = _ref.read(shopSettingsNotifierProvider);
    final shopSettings = settingsState.settings;

    final receiptText = _formatterService.formatThermalReceipt(
      bill: bill,
      shopSettings: shopSettings,
      paperWidth: state.paperWidth,
    );

    final result = await _printerService.printReceipt(
      printer: state.selectedPrinter!,
      receiptPayloadText: receiptText,
    );

    if (result.isSuccess) {
      state = state.copyWith(
        isPrinting: false,
        successMessage: 'Receipt printed successfully!',
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

  Future<bool> sendTestPrint() async {
    if (state.selectedPrinter == null) {
      state =
          state.copyWith(errorMessage: 'No printer selected for test print.');
      return false;
    }

    state = state.copyWith(isPrinting: true, clearError: true);

    final result = await _printerService.testPrint(state.selectedPrinter!);

    if (result.isSuccess) {
      state = state.copyWith(
        isPrinting: false,
        successMessage: 'Test print sent successfully!',
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

final printerNotifierProvider =
    StateNotifierProvider<PrinterNotifier, PrinterState>((ref) {
  return PrinterNotifier(
    printerService: ref.watch(printerServiceProvider),
    formatterService: ref.watch(receiptFormatterServiceProvider),
    ref: ref,
  );
});
