import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/features/billing/domain/models/bill_model.dart';
import 'package:kirana_mobile/features/receipts/domain/models/printer_device_model.dart';
import 'package:kirana_mobile/features/receipts/domain/services/printer_service.dart';
import 'package:kirana_mobile/features/receipts/domain/services/receipt_formatter_service.dart';
import 'package:kirana_mobile/features/receipts/presentation/providers/printer_provider.dart';
import 'package:kirana_mobile/features/settings/presentation/screens/printer_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalPrinterServiceImpl printerService;
  late ReceiptFormatterService formatterService;
  late BillModel testBill;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    printerService = LocalPrinterServiceImpl();
    formatterService = ReceiptFormatterService();

    testBill = BillModel(
      id: 'bill-uuid-99999',
      shopId: 'shop-uuid-12345',
      cashierId: 'user-uuid-11111',
      billNumber: 'BILL-2026-008',
      status: 'completed',
      paymentStatus: 'paid',
      items: [
        BillItemModel(
          id: 'item-1',
          billId: 'bill-uuid-99999',
          productId: 'prod-1',
          productName: 'Aashirvaad Atta 5kg',
          unit: 'kg',
          quantity: 2.0,
          unitPricePaise: 25000,
          taxRate: 5.0,
          taxAmountPaise: 2500,
          totalPaise: 47500,
          createdAt: DateTime(2026, 8, 27, 10, 30),
        ),
      ],
      subtotalPaise: 50000,
      discountPaise: 5000,
      taxTotalPaise: 2500,
      totalPaise: 47500,
      createdAt: DateTime(2026, 8, 27, 10, 30),
      updatedAt: DateTime(2026, 8, 27, 10, 30),
    );
  });

  group('KIRANAOS Phase 12.9 — Thermal Receipt Printing Tests', () {
    test('1. Bluetooth discovery and printer connection state management',
        () async {
      final container = ProviderContainer(
        overrides: [
          printerServiceProvider.overrideWithValue(printerService),
        ],
      );

      final notifier = container.read(printerNotifierProvider.notifier);

      // 1. Discovery
      await notifier.scanPrinters();
      final state1 = container.read(printerNotifierProvider);
      expect(state1.availablePrinters, isNotEmpty);
      expect(state1.isConnected, isFalse);

      // 2. Connection
      final target = state1.availablePrinters.first;
      final connected = await notifier.selectAndConnectPrinter(target);
      final state2 = container.read(printerNotifierProvider);

      expect(connected, isTrue);
      expect(state2.isConnected, isTrue);
      expect(state2.selectedPrinter?.name, equals(target.name));

      // 3. Disconnect
      await notifier.disconnectPrinter();
      final state3 = container.read(printerNotifierProvider);
      expect(state3.isConnected, isFalse);
      expect(state3.selectedPrinter, isNull);
    });

    test('2. Bluetooth disabled error handling during scan', () async {
      printerService.setBluetoothStatus(false);

      final container = ProviderContainer(
        overrides: [
          printerServiceProvider.overrideWithValue(printerService),
        ],
      );

      final notifier = container.read(printerNotifierProvider.notifier);
      await notifier.scanPrinters();
      final state = container.read(printerNotifierProvider);

      expect(state.errorMessage, contains('Bluetooth is disabled'));
      expect(state.availablePrinters, isEmpty);
    });

    test('3. Bluetooth permission denied error handling', () async {
      printerService.setBluetoothPermission(false);

      final container = ProviderContainer(
        overrides: [
          printerServiceProvider.overrideWithValue(printerService),
        ],
      );

      final notifier = container.read(printerNotifierProvider.notifier);
      await notifier.scanPrinters();
      final state = container.read(printerNotifierProvider);

      expect(state.errorMessage, contains('permission denied'));
    });

    test('4. Test Print transmission execution', () async {
      final container = ProviderContainer(
        overrides: [
          printerServiceProvider.overrideWithValue(printerService),
        ],
      );

      final notifier = container.read(printerNotifierProvider.notifier);
      await notifier.scanPrinters();
      final target =
          container.read(printerNotifierProvider).availablePrinters.first;
      await notifier.selectAndConnectPrinter(target);

      final success = await notifier.sendTestPrint();
      final state = container.read(printerNotifierProvider);

      expect(success, isTrue);
      expect(state.successMessage, contains('Test print sent successfully'));
    });

    test('5. Dynamic thermal receipt paper width formatting (58mm vs 80mm)',
        () {
      final text58 = formatterService.formatThermalReceipt(
        bill: testBill,
        paperWidth: PrinterPaperWidth.mm58,
      );

      final text80 = formatterService.formatThermalReceipt(
        bill: testBill,
        paperWidth: PrinterPaperWidth.mm80,
      );

      expect(text58, contains('BILL-2026-008'));
      expect(text80, contains('BILL-2026-008'));
      expect(text58.contains('Item'), isTrue);
      expect(text80.contains('Item Name'), isTrue);
    });

    test('6. Authoritative completed bill receipt printing works 100% offline',
        () async {
      final container = ProviderContainer(
        overrides: [
          printerServiceProvider.overrideWithValue(printerService),
        ],
      );

      final notifier = container.read(printerNotifierProvider.notifier);
      await notifier.scanPrinters();
      final target =
          container.read(printerNotifierProvider).availablePrinters.first;
      await notifier.selectAndConnectPrinter(target);

      final printed = await notifier.printReceipt(testBill);
      final state = container.read(printerNotifierProvider);

      expect(printed, isTrue);
      expect(state.successMessage, contains('Receipt printed successfully'));
    });

    testWidgets(
        '7. Renders PrinterSettingsScreen with status badge and paper width choice',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            printerServiceProvider.overrideWithValue(printerService),
          ],
          child: const MaterialApp(
            home: PrinterSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Thermal Printer Settings'), findsOneWidget);
      expect(find.text('CONNECTED PRINTER'), findsOneWidget);
      expect(find.text('DISCONNECTED'), findsOneWidget);
      expect(find.text('58mm (32 Columns)'), findsOneWidget);
      expect(find.text('80mm (48 Columns)'), findsOneWidget);
      expect(find.text('Scan Bluetooth'), findsOneWidget);
    });
  });
}
