import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/features/billing/domain/models/bill_model.dart';
import 'package:kirana_mobile/features/receipts/domain/models/printer_device_model.dart';
import 'package:kirana_mobile/features/receipts/domain/services/receipt_formatter_service.dart';
import 'package:kirana_mobile/features/receipts/presentation/screens/completed_receipt_screen.dart';
import 'package:kirana_mobile/features/settings/domain/models/shop_settings_model.dart';

void main() {
  late ReceiptFormatterService formatterService;
  late BillModel testBill;
  late ShopSettingsModel testShopSettings;

  setUp(() {
    formatterService = ReceiptFormatterService();

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
          unitPricePaise: 25000, // ₹250.00
          taxRate: 5.0,
          taxAmountPaise: 2500, // ₹25.00
          totalPaise: 47500, // ₹475.00
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

  group('KIRANAOS Phase 12.7 — Bill Receipt Foundation Tests', () {
    test(
        '1. Receipt Preview contains full shop branding, customer and item breakdown',
        () {
      final receiptText = formatterService.formatThermalReceipt(
        bill: testBill,
        shopSettings: testShopSettings,
        paperWidth: PrinterPaperWidth.mm80,
      );

      expect(receiptText, contains('GUPTA SUPER STORE'));
      expect(receiptText, contains('BILL-2026-008'));
      expect(receiptText, contains('Rahul Sharma'));
      expect(receiptText, contains('Aashirvaad Atta 5kg'));
      expect(receiptText, contains('475.00'));
      expect(receiptText, contains('PAID'));
    });

    test(
        '2. Historical Receipt Immutability (stored bill total == receipt total)',
        () {
      const modifiedSettings = ShopSettingsModel(
        shopId: 'shop-uuid-12345',
        shopName: 'NEW STORE NAME',
        phone: '9999999999',
        address: 'New Address 456',
      );

      final receiptText = formatterService.formatThermalReceipt(
        bill: testBill,
        shopSettings: modifiedSettings,
        paperWidth: PrinterPaperWidth.mm58,
      );

      expect(testBill.subtotalPaise, equals(50000));
      expect(testBill.discountPaise, equals(5000));
      expect(testBill.taxTotalPaise, equals(2500));
      expect(testBill.totalPaise, equals(47500));
      expect(receiptText, contains('475.00'));
    });

    test('3. Share Receipt payload generation without internal database UUIDs',
        () {
      final shareText = formatterService.formatShareableText(
        bill: testBill,
        shopSettings: testShopSettings,
      );

      expect(shareText, contains('🧾 RECEIPT — GUPTA SUPER STORE'));
      expect(shareText, contains('Bill No: BILL-2026-008'));
      expect(shareText, contains('Rahul Sharma'));
      expect(shareText, contains('Aashirvaad Atta 5kg'));
      expect(shareText, contains('GRAND TOTAL: ₹475.00'));

      expect(shareText, isNot(contains('shop-uuid-12345')));
      expect(shareText, isNot(contains('bill-uuid-99999')));
      expect(shareText, isNot(contains('user-uuid-11111')));
      expect(shareText, isNot(contains('cust-uuid-55555')));
    });

    testWidgets(
        '4. Renders CompletedReceiptScreen with POS UI layout and actions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CompletedReceiptScreen(bill: testBill),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Receipt #BILL-2026-008'), findsOneWidget);
      expect(find.text('Aashirvaad Atta 5kg'), findsOneWidget);
      expect(find.text('SHARE RECEIPT'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });
}
