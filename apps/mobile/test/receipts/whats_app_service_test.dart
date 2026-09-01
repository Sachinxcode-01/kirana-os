import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/features/billing/domain/models/bill_model.dart';
import 'package:kirana_mobile/features/receipts/domain/services/whats_app_service.dart';
import 'package:kirana_mobile/features/settings/domain/models/shop_settings_model.dart';

void main() {
  late WhatsAppService service;

  final sampleBill = BillModel(
    id: 'bill-001',
    shopId: 'shop-01',
    cashierId: 'cashier-01',
    billNumber: 'BILL-10023',
    customerId: 'cust-01',
    customerName: 'Rajesh Sharma',
    customerPhone: '9876543210',
    status: 'completed',
    subtotalPaise: 50000, // ₹500.00
    taxTotalPaise: 2500, // ₹25.00
    discountPaise: 5000, // ₹50.00
    totalPaise: 47500, // ₹475.00
    paymentStatus: 'paid',
    items: [
      BillItemModel(
        id: 'item-1',
        billId: 'bill-001',
        productId: 'prod-1',
        productName: 'Tata Tea Gold',
        quantity: 2,
        unit: 'PCS',
        unitPricePaise: 25000,
        taxRate: 5.0,
        taxAmountPaise: 2500,
        totalPaise: 47500,
        createdAt: DateTime(2026, 9, 1),
      ),
    ],
    createdAt: DateTime(2026, 9, 1, 14, 30),
    updatedAt: DateTime(2026, 9, 1, 14, 30),
  );

  final sampleShopSettings = const ShopSettingsModel(
    shopId: 'shop-01',
    shopName: 'Gupta Kirana & General Store',
    address: 'Shop 4, Main Market, Delhi',
    phone: '9876500000',
    gstin: '07AAAAA0000A1Z5',
  );

  setUp(() {
    service = WhatsAppService();
  });

  group('WhatsAppService Formatting & URI Tests', () {
    test('normalizePhone formats Indian mobile numbers with 91 country code', () {
      expect(WhatsAppService.normalizePhone('9876543210'), '919876543210');
      expect(WhatsAppService.normalizePhone('+91 98765 43210'), '919876543210');
      expect(WhatsAppService.normalizePhone('09876543210'), '919876543210');
      expect(WhatsAppService.normalizePhone('919876543210'), '919876543210');
    });

    test('createWhatsAppUrl generates valid click-to-chat URL with encoded text', () {
      final url = WhatsAppService.createWhatsAppUrl(
        phone: '9876543210',
        message: 'Hello *World* & Friends!',
      );
      expect(url.startsWith('https://wa.me/919876543210?text='), isTrue);
      expect(url.contains('Hello%20*World*%20%26%20Friends!'), isTrue);
    });

    test('createUpiPaymentUri builds compliant UPI Payment deep link', () {
      final upiUri = WhatsAppService.createUpiPaymentUri(
        upiId: 'guptakirana@okaxis',
        payeeName: 'Gupta Kirana',
        amountPaise: 47500, // ₹475.00
        note: 'Invoice #10023',
      );

      expect(upiUri, contains('upi://pay?pa=guptakirana@okaxis'));
      expect(upiUri, contains('pn=Gupta%20Kirana'));
      expect(upiUri, contains('am=475.00'));
      expect(upiUri, contains('cu=INR'));
      expect(upiUri, contains('tn=Invoice%20%2310023'));
    });

    test('formatReceiptMessage produces clean WhatsApp markdown receipt with loyalty points', () {
      final text = service.formatReceiptMessage(
        bill: sampleBill,
        shopSettings: sampleShopSettings,
        paymentModeLabel: 'UPI / Google Pay',
        pointsEarned: 4,
        totalLoyaltyBalance: 48,
      );

      expect(text, contains('*TAX INVOICE / RECEIPT*'));
      expect(text, contains('*Gupta Kirana & General Store*'));
      expect(text, contains('Invoice No: *#BILL-10023*'));
      expect(text, contains('*Tata Tea Gold*'));
      expect(text, contains('💰 *GRAND TOTAL: ₹475.00*'));
      expect(text, contains('Payment Mode: *UPI / Google Pay*'));
      expect(text, contains('• Points Earned Today: *+4 pts*'));
      expect(text, contains('• Total Points Balance: *48 pts*'));
    });

    test('formatKhataReminderMessage formats polite reminder with balance and UPI payment link', () {
      final text = service.formatKhataReminderMessage(
        customerName: 'Rajesh Sharma',
        currentDebtPaise: 125000, // ₹1,250.00
        shopSettings: sampleShopSettings,
        upiId: 'guptastore@icici',
      );

      expect(text, contains('Namaste *Rajesh Sharma* ji'));
      expect(text, contains('Outstanding Khata Balance: ₹1,250.00'));
      expect(text, contains('upi://pay?pa=guptastore@icici'));
      expect(text, contains('am=1250.00'));
    });
  });
}
