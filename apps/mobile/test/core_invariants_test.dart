import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/animation/animation_durations.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/core/utils/currency_formatter.dart';
import 'package:kirana_mobile/core/utils/id_generator.dart';

void main() {
  group('Currency & Paise Arithmetic Invariants', () {
    test('Format paise to Indian Rupee string correctly', () {
      expect(CurrencyFormatter.formatPaise(1050), '₹10.50');
      expect(CurrencyFormatter.formatPaise(125075), '₹1,250.75');
      expect(CurrencyFormatter.formatPaise(0), '₹0.00');
    });

    test('Parse string rupees to integer paise correctly', () {
      expect(CurrencyFormatter.parseRupeesToPaise('10.50'), 1050);
      expect(CurrencyFormatter.parseRupeesToPaise('₹1,250.75'), 125075);
      expect(CurrencyFormatter.parseRupeesToPaise('44'), 4400);
    });
  });

  group('Result & Failure Pattern Invariants', () {
    test('Success result folds properly', () {
      const Result<int, Failure> result = Success(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, 42);

      final val = result.fold(
        (data) => 'Value is $data',
        (failure) => 'Failed',
      );
      expect(val, 'Value is 42');
    });

    test('Error result folds properly', () {
      const Result<int, Failure> result =
          ErrorResult(BarcodeNotFoundFailure('8901030383742'));
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<BarcodeNotFoundFailure>());

      final val = result.fold(
        (data) => 'Success',
        (failure) => failure.message,
      );
      expect(val, contains('8901030383742'));
    });
  });

  group('ID Generation & Animation Bounds Invariants', () {
    test('Generate unique bill number with date prefix', () {
      final billNo = IdGenerator.generateBillNumber();
      expect(billNo.startsWith('INV-'), isTrue);
    });

    test('Animation tokens are strictly bounded for POS responsiveness', () {
      expect(AnimationDurations.micro.inMilliseconds, lessThanOrEqualTo(150));
      expect(AnimationDurations.quick.inMilliseconds, lessThanOrEqualTo(200));
      expect(
          AnimationDurations.standard.inMilliseconds, lessThanOrEqualTo(300));
    });
  });
}
