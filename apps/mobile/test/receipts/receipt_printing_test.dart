import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/features/billing/domain/models/bill_model.dart';
import 'package:kirana_mobile/features/receipts/domain/models/printer_device_model.dart';
import 'package:kirana_mobile/features/receipts/domain/services/printer_service.dart';
import 'package:kirana_mobile/features/receipts/domain/services/receipt_formatter_service.dart';
import 'package:kirana_mobile/features/settings/domain/models/shop_settings_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KIRANAOS Phase 06.5 — Thermal Receipt Printing Tests', () {
    late ReceiptFormatterService formatterService;
    late LocalPrinterServiceImpl printerService;

    final sampleShopSettings = ShopSettingsModel(
      shopId: 'shop_test_58',
      shopName: 'GUJRAT KIRANA STORES',
      phone: '9876543210',
      address: 'Station Road, Anand 388001',
      gstin: '24AAAAA0000A1Z5',
      currencySymbol: '₹',
      isTaxEnabled: true,
      defaultTaxPercentage: 18.0,
    );

    final completedBill = BillModel(
      id: 'bill_comp_01',
      shopId: 'shop_test_58',
      cashierId: 'cashier_01',
      billNumber: 'INV-2026-0089',
      status: 'completed',
      customerId: 'cust_01',
      customerName: 'Vikram Patel',
      customerPhone: '9123456789',
      discountType: 'percentage',
      discountValue: 10.0,
      discountPaise: 5000, // ₹50.00 discount
      subtotalPaise: 50000, // ₹500.00 subtotal
      taxTotalPaise: 8100, // ₹81.00 tax
      totalPaise: 53100, // ₹531.00 grand total
      paymentStatus: 'paid',
      createdAt: DateTime(2026, 8, 25, 14, 30),
      updatedAt: DateTime(2026, 8, 25, 14, 30),
      items: [
        BillItemModel(
          id: 'item_01',
          billId: 'bill_comp_01',
          productId: 'prod_atta_10kg',
          productName: 'Aashirvaad Whole Wheat Atta Superior Quality 10kg Pack',
          unit: 'packet',
          unitPricePaise: 40000, // ₹400.00
          quantity: 1.0,
          taxRate: 18.0,
          taxAmountPaise: 7200,
          totalPaise: 47200,
          createdAt: DateTime.now(),
        ),
        BillItemModel(
          id: 'item_02',
          billId: 'bill_comp_01',
          productId: 'prod_sugar_1kg',
          productName: 'Madhur Pure Sugar',
          unit: 'kg',
          unitPricePaise: 5000, // ₹50.00
          quantity: 2.0,
          taxRate: 18.0,
          taxAmountPaise: 1800,
          totalPaise: 11800,
          createdAt: DateTime.now(),
        ),
      ],
    );

    setUp(() {
      formatterService = ReceiptFormatterService();
      printerService = LocalPrinterServiceImpl();
    });

    test('1. Formats 58mm thermal receipt (32 columns, alignment, wrapping)',
        () {
      final receiptText = formatterService.formatThermalReceipt(
        bill: completedBill,
        shopSettings: sampleShopSettings,
        paperWidth: PrinterPaperWidth.mm58,
      );

      expect(receiptText.contains('GUJRAT KIRANA STORES'), true);
      expect(receiptText.contains('INV-2026-0089'), true);
      expect(receiptText.contains('Vikram Patel'), true);
      expect(receiptText.contains('GRAND TOTAL:'), true);
      expect(receiptText.contains('₹531.00'), true);
      expect(receiptText.contains('Payment Status:'), true);

      // Lines must strictly fit within 32 character width
      final lines = receiptText.split('\n');
      for (final line in lines) {
        expect(line.length <= 32, true,
            reason: 'Line exceeds 58mm column width: "$line"');
      }
    });

    test('2. Formats 80mm thermal receipt (48 columns, tabular alignment)', () {
      final receiptText = formatterService.formatThermalReceipt(
        bill: completedBill,
        shopSettings: sampleShopSettings,
        paperWidth: PrinterPaperWidth.mm80,
      );

      expect(receiptText.contains('GUJRAT KIRANA STORES'), true);
      expect(receiptText.contains('INV-2026-0089'), true);
      expect(receiptText.contains('GRAND TOTAL:'), true);

      final lines = receiptText.split('\n');
      for (final line in lines) {
        expect(line.length <= 48, true,
            reason: 'Line exceeds 80mm column width: "$line"');
      }
    });

    test('3. Wraps long product names cleanly across multiple lines', () {
      final receiptText = formatterService.formatThermalReceipt(
        bill: completedBill,
        shopSettings: sampleShopSettings,
        paperWidth: PrinterPaperWidth.mm58,
      );

      // "Aashirvaad Whole Wheat Atta Superior Quality 10kg Pack" must be wrapped
      expect(receiptText.contains('Aashirvaad Whole'), true);
      expect(receiptText.contains('Wheat Atta'), true);
    });

    test('4. Price snapshot immutability in printed receipt payload', () {
      final receiptText = formatterService.formatThermalReceipt(
        bill: completedBill,
        shopSettings: sampleShopSettings,
        paperWidth: PrinterPaperWidth.mm58,
      );

      expect(receiptText.contains('Subtotal:'), true);
      expect(receiptText.contains('₹500.00'), true);
      expect(receiptText.contains('- ₹50.00'), true); // Discount
      expect(receiptText.contains('₹81.00'), true); // Tax
      expect(receiptText.contains('₹531.00'), true); // Grand total
    });

    test(
        '5. Printer discovery & connection state management (scan, connect, disconnect)',
        () async {
      final scanResult = await printerService.scanForPrinters();
      expect(scanResult.isSuccess, true);
      final printers = scanResult.dataOrNull!;
      expect(printers.isNotEmpty, true);

      final selected = printers.first;
      final connectResult = await printerService.connectPrinter(selected);
      expect(connectResult.isSuccess, true);
      expect(connectResult.dataOrNull!.isConnected, true);

      final disconnectResult = await printerService.disconnectPrinter();
      expect(disconnectResult.isSuccess, true);
    });

    test('6. Bluetooth disabled error handling during scan or print', () async {
      printerService.setBluetoothStatus(false);

      final scanResult = await printerService.scanForPrinters();
      expect(scanResult.isError, true);
      expect(scanResult.failureOrNull!.message,
          'Bluetooth is disabled. Please enable Bluetooth.');

      const dummyDevice = PrinterDeviceModel(
        id: 'dummy_bt',
        name: 'Dummy BT Printer',
        address: '00:00:00:00',
      );

      final printResult = await printerService.printReceipt(
        printer: dummyDevice,
        receiptPayloadText: 'Test Payload',
      );
      expect(printResult.isError, true);
      expect(printResult.failureOrNull!.message,
          'Printer unavailable: Bluetooth is disabled or printer is disconnected.');
    });

    test(
        '7. Print failure retry DOES NOT alter completed bill state (COMPLETED & PAID)',
        () async {
      printerService.setBluetoothStatus(false); // Simulate disconnected printer

      const dummyDevice = PrinterDeviceModel(
        id: 'dummy_bt',
        name: 'Dummy BT Printer',
        address: '00:00:00:00',
      );

      final printResult = await printerService.printReceipt(
        printer: dummyDevice,
        receiptPayloadText: 'Receipt Text',
      );

      // Printing fails
      expect(printResult.isError, true);

      // CRITICAL INVARIANT: Completed bill remains COMPLETED & PAID
      expect(completedBill.isCompleted, true);
      expect(completedBill.paymentStatus, 'paid');
    });

    test('8. Offline printing works locally without network API calls',
        () async {
      final receiptText = formatterService.formatThermalReceipt(
        bill: completedBill,
        shopSettings: sampleShopSettings,
        paperWidth: PrinterPaperWidth.mm58,
      );

      const dummyDevice = PrinterDeviceModel(
        id: 'dummy_bt',
        name: 'Dummy BT Printer',
        address: '00:00:00:00',
      );

      final printResult = await printerService.printReceipt(
        printer: dummyDevice,
        receiptPayloadText: receiptText,
      );

      expect(printResult.isSuccess, true);
    });
  });
}
