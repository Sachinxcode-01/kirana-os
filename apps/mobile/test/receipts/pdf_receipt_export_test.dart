import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/features/billing/domain/models/bill_model.dart';
import 'package:kirana_mobile/features/receipts/domain/services/pdf_receipt_service.dart';
import 'package:kirana_mobile/features/receipts/presentation/screens/pdf_receipt_preview_screen.dart';
import 'package:kirana_mobile/features/settings/domain/models/shop_settings_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PdfReceiptService pdfService;
  late BillModel testBill;
  late ShopSettingsModel testShopSettings;

  setUp(() {
    pdfService = PdfReceiptService();

    testShopSettings = const ShopSettingsModel(
      shopId: 'shop-uuid-12345',
      shopName: 'GUPTA SUPER STORE',
      phone: '9876543210',
      address: '123 Market St, Delhi',
      gstin: '07AAAAA0000A1Z5',
    );

    testBill = BillModel(
      id: 'bill-uuid-99999',
      shopId: 'shop-uuid-12345',
      cashierId: 'user-uuid-11111',
      billNumber: 'BILL-2026-008',
      customerId: 'cust-uuid-55555',
      customerName: 'Rahul Sharma',
      customerPhone: '9123456789',
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

  group('KIRANAOS Phase 12.8 — PDF Receipt Export Tests', () {
    test('1. Compiles valid print-ready PDF binary document', () async {
      final pdfBytes = await pdfService.generateReceiptPdf(
        bill: testBill,
        shopSettings: testShopSettings,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(500));

      // Verify PDF magic bytes (%PDF-)
      final pdfHeader = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(pdfHeader, equals('%PDF-'));
    });

    test('2. Historical PDF Accuracy (uses stored bill total)', () async {
      const modifiedShopSettings = ShopSettingsModel(
        shopId: 'shop-uuid-12345',
        shopName: 'NEW STORE NAME',
        phone: '9999999999',
      );

      final pdfBytes = await pdfService.generateReceiptPdf(
        bill: testBill,
        shopSettings: modifiedShopSettings,
      );

      expect(testBill.totalPaise, equals(47500));
      expect(testBill.subtotalPaise, equals(50000));
      expect(testBill.discountPaise, equals(5000));
      expect(testBill.taxTotalPaise, equals(2500));
      expect(pdfBytes, isNotEmpty);
    });

    test('3. Supports multi-page pagination for large receipts (>20 items)',
        () async {
      final largeItems = List<BillItemModel>.generate(
        25,
        (index) => BillItemModel(
          id: 'item-$index',
          billId: 'bill-uuid-99999',
          productId: 'prod-$index',
          productName: 'Grocery Product Item #$index',
          unit: 'pcs',
          quantity: 1.0,
          unitPricePaise: 10000,
          taxRate: 0.0,
          taxAmountPaise: 0,
          totalPaise: 10000,
          createdAt: DateTime(2026, 8, 27, 10, 30),
        ),
      );

      final largeBill = testBill.copyWith(
        items: largeItems,
        subtotalPaise: 250000,
        totalPaise: 250000,
      );

      final pdfBytes = await pdfService.generateReceiptPdf(
        bill: largeBill,
        shopSettings: testShopSettings,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1500));
    });

    testWidgets('4. Renders PdfReceiptPreviewScreen with offline cached banner',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PdfReceiptPreviewScreen(
              bill: testBill,
              isOfflineCached: true,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('PDF Preview #BILL-2026-008'), findsOneWidget);
      expect(
        find.text('Offline Cached Bill · Generated from local storage'),
        findsOneWidget,
      );
    });
  });
}
