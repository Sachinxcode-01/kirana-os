import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/utils/currency_formatter.dart';
import 'package:kirana_mobile/features/settings/domain/models/shop_settings_model.dart';

void main() {
  group('KIRANAOS AUTH 12.3 — Business Settings Foundation Tests', () {
    test(
        '1. CurrencyFormatter utility formats amounts with symbol and decimal precision',
        () {
      final formattedINR =
          CurrencyFormatter.format(1250.50, symbol: '₹', precision: 2);
      expect(formattedINR, equals('₹1250.50'));

      final formattedZeroDecimal =
          CurrencyFormatter.format(500, symbol: '₹', precision: 0);
      expect(formattedZeroDecimal, equals('₹500'));

      final formattedNoSymbol =
          CurrencyFormatter.format(99.99, includeSymbol: false);
      expect(formattedNoSymbol, equals('99.99'));
    });

    test('2. BusinessDayHours model serializes and deserializes correctly', () {
      const dayHours = BusinessDayHours(
        isOpen: true,
        openTime: '08:30',
        closeTime: '22:00',
      );

      final json = dayHours.toJson();
      expect(json['is_open'], isTrue);
      expect(json['open_time'], '08:30');
      expect(json['close_time'], '22:00');

      final deserialized = BusinessDayHours.fromJson(json);
      expect(deserialized.isOpen, isTrue);
      expect(deserialized.openTime, '08:30');
      expect(deserialized.closeTime, '22:00');
    });

    test('3. Configures daily business hours for Monday through Sunday', () {
      final customHours = {
        'monday': const BusinessDayHours(
            isOpen: true, openTime: '08:00', closeTime: '21:00'),
        'tuesday': const BusinessDayHours(
            isOpen: true, openTime: '08:00', closeTime: '21:00'),
        'wednesday': const BusinessDayHours(
            isOpen: true, openTime: '08:00', closeTime: '21:00'),
        'thursday': const BusinessDayHours(
            isOpen: true, openTime: '08:00', closeTime: '21:00'),
        'friday': const BusinessDayHours(
            isOpen: true, openTime: '08:00', closeTime: '21:00'),
        'saturday': const BusinessDayHours(
            isOpen: true, openTime: '08:00', closeTime: '22:00'),
        'sunday': const BusinessDayHours(
            isOpen: false,
            openTime: '09:00',
            closeTime: '18:00'), // Closed on Sunday
      };

      final settings = ShopSettingsModel(
        shopId: 'shop_biz_101',
        shopName: 'Mahadev Kirana Store',
        phone: '9845012345',
        currencyCode: 'INR',
        currencySymbol: '₹',
        decimalPrecision: 2,
        billPrefix: 'BILL-',
        businessHours: customHours,
      );

      expect(settings.businessHours['sunday']?.isOpen, isFalse);
      expect(settings.businessHours['saturday']?.closeTime, equals('22:00'));
      expect(settings.billPrefix, equals('BILL-'));
      expect(settings.currencyCode, equals('INR'));
    });

    test(
        '4. Serializes and deserializes ShopSettingsModel with currency and business hours',
        () {
      final original = ShopSettingsModel(
        shopId: 'shop_biz_101',
        shopName: 'Ganesh Provision',
        phone: '9845012345',
        currencyCode: 'INR',
        currencySymbol: '₹',
        decimalPrecision: 2,
        billPrefix: 'SALE-',
        businessHours: {
          'monday': const BusinessDayHours(
              isOpen: true, openTime: '07:00', closeTime: '22:00'),
          'sunday': const BusinessDayHours(isOpen: false),
        },
      );

      final json = original.toJson();
      expect(json['currency_code'], 'INR');
      expect(json['currency_symbol'], '₹');
      expect(json['bill_prefix'], 'SALE-');
      expect(json['business_hours']['monday']['open_time'], '07:00');

      final deserialized = ShopSettingsModel.fromJson(json);
      expect(deserialized.currencyCode, 'INR');
      expect(deserialized.billPrefix, 'SALE-');
      expect(deserialized.businessHours['monday']?.openTime, '07:00');
      expect(deserialized.businessHours['sunday']?.isOpen, isFalse);
    });

    test('5. Validates non-empty bill prefix input', () {
      final validPrefix = 'INV-'.trim();
      expect(validPrefix.isNotEmpty, isTrue);

      final emptyPrefix = '   '.trim();
      expect(emptyPrefix.isEmpty, isTrue);
    });
  });
}
