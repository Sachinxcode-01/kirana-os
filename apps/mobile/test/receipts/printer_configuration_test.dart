import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/features/billing/domain/models/bill_model.dart';
import 'package:kirana_mobile/features/receipts/domain/models/printer_device_model.dart';
import 'package:kirana_mobile/features/receipts/domain/services/printer_service.dart';
import 'package:kirana_mobile/features/receipts/domain/services/receipt_formatter_service.dart';
import 'package:kirana_mobile/features/receipts/presentation/providers/printer_provider.dart';
import 'package:kirana_mobile/features/settings/presentation/screens/printer_settings_screen.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';

// ─── Mock PrinterService ─────────────────────────────────────────────────────

class MockPrinterService extends Mock implements PrinterService {}

// ─── Fake PrinterDeviceModel for fallback registration ───────────────────────

class FakePrinterDeviceModel extends Fake implements PrinterDeviceModel {}

// ─── Test Data ────────────────────────────────────────────────────────────────

final _testPrinter = PrinterDeviceModel(
  id: 'wifi-printer-01',
  name: 'Test WiFi Printer',
  address: 'ipp://192.168.1.100:631/ipp/print',
  connectionType: 'wifi',
  url: 'ipp://192.168.1.100:631/ipp/print',
  paperWidth: PrinterPaperWidth.mm80,
  pageFormat: PrinterPageFormat.roll80mm,
  isColor: true,
  copies: 1,
);

final _testBill = BillModel(
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

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPrinterService mockPrinterService;
  final formatterService = ReceiptFormatterService();

  setUpAll(() {
    registerFallbackValue(FakePrinterDeviceModel());
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockPrinterService = MockPrinterService();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        printerServiceProvider.overrideWithValue(mockPrinterService),
      ],
    );
  }

  group('KiranaOS WiFi Printer — Unit Tests', () {
    test('1. Scan returns discovered WiFi printers', () async {
      when(() => mockPrinterService.scanForPrinters())
          .thenAnswer((_) async => Success([_testPrinter]));

      final container = makeContainer();
      final notifier = container.read(printerNotifierProvider.notifier);

      await notifier.scanPrinters();
      final state = container.read(printerNotifierProvider);

      expect(state.availablePrinters, isNotEmpty);
      expect(state.availablePrinters.first.name, equals('Test WiFi Printer'));
      expect(state.isConnected, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('2. Scan error — hardware failure is surfaced as errorMessage',
        () async {
      when(() => mockPrinterService.scanForPrinters())
          .thenAnswer((_) async => const ErrorResult(
                HardwareFailure('No printers found on network.'),
              ));

      final container = makeContainer();
      await container.read(printerNotifierProvider.notifier).scanPrinters();
      final state = container.read(printerNotifierProvider);

      expect(state.errorMessage, contains('No printers found'));
      expect(state.availablePrinters, isEmpty);
    });

    test('3. Connect printer — marks printer as connected', () async {
      when(() => mockPrinterService.scanForPrinters())
          .thenAnswer((_) async => Success([_testPrinter]));
      when(() => mockPrinterService.connectPrinter(any())).thenAnswer(
          (_) async => Success(_testPrinter.copyWith(isConnected: true)));

      final container = makeContainer();
      final notifier = container.read(printerNotifierProvider.notifier);

      await notifier.scanPrinters();
      final target =
          container.read(printerNotifierProvider).availablePrinters.first;
      final success = await notifier.selectAndConnectPrinter(target);
      final state = container.read(printerNotifierProvider);

      expect(success, isTrue);
      expect(state.isConnected, isTrue);
      expect(state.selectedPrinter?.name, equals('Test WiFi Printer'));
    });

    test('4. Connect fails — error shown, not connected', () async {
      when(() => mockPrinterService.connectPrinter(any()))
          .thenAnswer((_) async => const ErrorResult(
                HardwareFailure('Printer not reachable on network.'),
              ));

      final container = makeContainer();
      final notifier = container.read(printerNotifierProvider.notifier);

      final success = await notifier.selectAndConnectPrinter(_testPrinter);
      final state = container.read(printerNotifierProvider);

      expect(success, isFalse);
      expect(state.isConnected, isFalse);
      expect(state.errorMessage, contains('not reachable'));
    });

    test('5. Disconnect clears selected printer', () async {
      when(() => mockPrinterService.connectPrinter(any())).thenAnswer(
          (_) async => Success(_testPrinter.copyWith(isConnected: true)));
      when(() => mockPrinterService.disconnectPrinter())
          .thenAnswer((_) async => const Success(null));

      final container = makeContainer();
      final notifier = container.read(printerNotifierProvider.notifier);

      await notifier.selectAndConnectPrinter(_testPrinter);
      expect(container.read(printerNotifierProvider).isConnected, isTrue);

      await notifier.disconnectPrinter();
      final state = container.read(printerNotifierProvider);

      expect(state.isConnected, isFalse);
      expect(state.selectedPrinter, isNull);
    });

    test('6. Print settings: color mode toggles correctly', () async {
      final container = makeContainer();
      final notifier = container.read(printerNotifierProvider.notifier);

      expect(container.read(printerNotifierProvider).isColor, isTrue);

      notifier.setColorMode(false);
      expect(container.read(printerNotifierProvider).isColor, isFalse);

      notifier.setColorMode(true);
      expect(container.read(printerNotifierProvider).isColor, isTrue);
    });

    test('7. Print settings: page format updates correctly', () async {
      final container = makeContainer();
      final notifier = container.read(printerNotifierProvider.notifier);

      notifier.setPageFormat(PrinterPageFormat.a4);
      expect(container.read(printerNotifierProvider).pageFormat,
          equals(PrinterPageFormat.a4));

      notifier.setPageFormat(PrinterPageFormat.roll58mm);
      expect(container.read(printerNotifierProvider).pageFormat,
          equals(PrinterPageFormat.roll58mm));
    });

    test('8. Copies clamped between 1 and 9', () async {
      final container = makeContainer();
      final notifier = container.read(printerNotifierProvider.notifier);

      notifier.setCopies(0);
      expect(container.read(printerNotifierProvider).copies, equals(1));

      notifier.setCopies(15);
      expect(container.read(printerNotifierProvider).copies, equals(9));

      notifier.setCopies(3);
      expect(container.read(printerNotifierProvider).copies, equals(3));
    });

    test('9. Print without selected printer returns error', () async {
      final container = makeContainer();
      final notifier = container.read(printerNotifierProvider.notifier);

      final result = await notifier.printReceipt(_testBill);
      final state = container.read(printerNotifierProvider);

      expect(result, isFalse);
      expect(state.errorMessage, contains('No printer selected'));
    });

    test('10. Test print succeeds when printer is connected', () async {
      when(() => mockPrinterService.connectPrinter(any())).thenAnswer(
          (_) async => Success(_testPrinter.copyWith(isConnected: true)));
      when(() => mockPrinterService.testPrint(any()))
          .thenAnswer((_) async => const Success(null));

      final container = makeContainer();
      final notifier = container.read(printerNotifierProvider.notifier);

      await notifier.selectAndConnectPrinter(_testPrinter);
      final result = await notifier.sendTestPrint();
      final state = container.read(printerNotifierProvider);

      expect(result, isTrue);
      expect(state.successMessage, contains('Test page sent'));
    });

    test('11. Receipt formatter generates correct text for 58mm paper', () {
      final text = formatterService.formatThermalReceipt(
        bill: _testBill,
        paperWidth: PrinterPaperWidth.mm58,
      );
      expect(text, contains('BILL-2026-008'));
      expect(text, contains('Aashirvaad'));
      expect(text, contains('GRAND TOTAL'));
    });

    test('12. Receipt formatter generates correct text for 80mm paper', () {
      final text = formatterService.formatThermalReceipt(
        bill: _testBill,
        paperWidth: PrinterPaperWidth.mm80,
      );
      expect(text, contains('BILL-2026-008'));
      expect(text, contains('Item Name'));
    });
  });

  group('KiranaOS WiFi Printer — Widget Tests', () {
    testWidgets('13. PrinterSettingsScreen renders key sections',
        (WidgetTester tester) async {
      when(() => mockPrinterService.scanForPrinters())
          .thenAnswer((_) async => const Success([]));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            printerServiceProvider.overrideWithValue(mockPrinterService),
          ],
          child: const MaterialApp(
            home: PrinterSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // AppBar
      expect(find.text('WiFi Printer Setup'), findsOneWidget);
      // Active Printer Card
      expect(find.text('ACTIVE PRINTER'), findsOneWidget);
      expect(find.text('NO PRINTER'), findsOneWidget);
      // Print Settings Card
      expect(find.text('PRINT SETTINGS'), findsOneWidget);
      // Color/B&W buttons
      expect(find.text('🎨 Color'), findsOneWidget);
      expect(find.text('⬛ B&W'), findsOneWidget);
      // Scan button
      expect(find.text('Scan Network'), findsOneWidget);
    });

    testWidgets('14. Scanning shows progress indicator',
        (WidgetTester tester) async {
      // Completer to control when scan resolves
      when(() => mockPrinterService.scanForPrinters()).thenAnswer(
        (_) async {
          await Future<void>.delayed(const Duration(seconds: 5));
          return const Success([]);
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            printerServiceProvider.overrideWithValue(mockPrinterService),
          ],
          child: const MaterialApp(home: PrinterSettingsScreen()),
        ),
      );

      await tester.tap(find.text('Scan Network'));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Settle the delayed future to clean up the test timer
      await tester.pump(const Duration(seconds: 6));
    });
  });
}
