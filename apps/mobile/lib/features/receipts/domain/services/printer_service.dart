import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../models/printer_device_model.dart';

abstract interface class PrinterService {
  Future<Result<List<PrinterDeviceModel>, Failure>> scanForPrinters();

  Future<Result<PrinterDeviceModel, Failure>> connectPrinter(
      PrinterDeviceModel device);

  Future<Result<void, Failure>> disconnectPrinter();

  Future<Result<void, Failure>> printReceipt({
    required PrinterDeviceModel printer,
    required String receiptPayloadText,
  });

  Future<Result<void, Failure>> testPrint(PrinterDeviceModel printer);
}

class LocalPrinterServiceImpl implements PrinterService {
  PrinterDeviceModel? _connectedPrinter;
  bool _isBluetoothEnabled = true;

  void setBluetoothStatus(bool enabled) {
    _isBluetoothEnabled = enabled;
  }

  @override
  Future<Result<List<PrinterDeviceModel>, Failure>> scanForPrinters() async {
    if (!_isBluetoothEnabled) {
      return const ErrorResult(
        HardwareFailure('Bluetooth is disabled. Please enable Bluetooth.'),
      );
    }

    final mockDiscoveredPrinters = [
      const PrinterDeviceModel(
        id: 'print_bt_01',
        name: 'POS Thermal Printer 58mm',
        address: '00:11:22:33:44:55',
        connectionType: 'bluetooth',
        paperWidth: PrinterPaperWidth.mm58,
      ),
      const PrinterDeviceModel(
        id: 'print_bt_02',
        name: 'Everycom EC-80mm Printer',
        address: '66:77:88:99:AA:BB',
        connectionType: 'bluetooth',
        paperWidth: PrinterPaperWidth.mm80,
      ),
      const PrinterDeviceModel(
        id: 'print_usb_01',
        name: 'TVS RP45 Thermal USB',
        address: 'USB_PORT_01',
        connectionType: 'usb',
        paperWidth: PrinterPaperWidth.mm80,
      ),
    ];

    return Success(mockDiscoveredPrinters);
  }

  @override
  Future<Result<PrinterDeviceModel, Failure>> connectPrinter(
      PrinterDeviceModel device) async {
    if (!_isBluetoothEnabled && device.connectionType == 'bluetooth') {
      return const ErrorResult(
        HardwareFailure('Bluetooth is disabled. Cannot connect printer.'),
      );
    }

    _connectedPrinter = device.copyWith(isConnected: true);
    return Success(_connectedPrinter!);
  }

  @override
  Future<Result<void, Failure>> disconnectPrinter() async {
    _connectedPrinter = null;
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> printReceipt({
    required PrinterDeviceModel printer,
    required String receiptPayloadText,
  }) async {
    if (!_isBluetoothEnabled && printer.connectionType == 'bluetooth') {
      return const ErrorResult(
        HardwareFailure(
            'Printer unavailable: Bluetooth is disabled or printer is disconnected.'),
      );
    }

    if (receiptPayloadText.trim().isEmpty) {
      return const ErrorResult(
        ValidationFailure('Malformed receipt data. Nothing to print.'),
      );
    }

    // Local printing simulation (100% offline, zero network requests)
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> testPrint(PrinterDeviceModel printer) async {
    const testPayload = '''
================================
     KIRANA OS TEST PRINT       
================================
Printer Name: Thermal POS
Width: 58mm / 80mm
Status: CONNECTED OK
Date: 25/08/2026
================================
''';

    return printReceipt(printer: printer, receiptPayloadText: testPayload);
  }
}
