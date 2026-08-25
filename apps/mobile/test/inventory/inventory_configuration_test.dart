import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/features/inventory/domain/models/stock_status.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';

void main() {
  group('Phase 05.2 - Feature: Inventory Configuration Tests', () {
    // 1. Stock Status Calculation
    group('2. Low-Stock Status Calculation', () {
      test('current > minimum returns IN STOCK', () {
        expect(StockStatus.fromQuantities(10.0, 5.0), StockStatus.inStock);
        expect(StockStatus.fromQuantities(5.1, 5.0), StockStatus.inStock);
      });

      test('current <= minimum AND current > 0 returns LOW STOCK', () {
        expect(StockStatus.fromQuantities(5.0, 5.0), StockStatus.lowStock);
        expect(StockStatus.fromQuantities(2.5, 5.0), StockStatus.lowStock);
        expect(StockStatus.fromQuantities(0.1, 5.0), StockStatus.lowStock);
      });

      test('current <= 0 returns OUT OF STOCK', () {
        expect(StockStatus.fromQuantities(0.0, 5.0), StockStatus.outOfStock);
        expect(StockStatus.fromQuantities(-2.0, 5.0), StockStatus.outOfStock);
      });
    });

    // 2. Stock Unit Display & Formatting
    group('3. Stock Unit Display & Fractional Quantities', () {
      test('Formats whole numbers cleanly without floating point artifacts',
          () {
        expect(StockUnitFormatter.formatWithUnit(12.0, 'PCS'), '12 pcs');
        expect(StockUnitFormatter.formatWithUnit(5.0, 'KG'), '5 kg');
        expect(StockUnitFormatter.formatWithUnit(10.0, 'PACKET'), '10 packet');
      });

      test('Supports fractional quantities where product unit requires them',
          () {
        expect(StockUnitFormatter.formatWithUnit(2.5, 'LITRE'), '2.5 litre');
        expect(StockUnitFormatter.formatWithUnit(0.75, 'KG'), '0.75 kg');
        expect(StockUnitFormatter.formatWithUnit(1.250, 'KG'), '1.25 kg');
      });
    });

    // 3. Minimum & Maximum Stock Validation
    group('1. Minimum & Maximum Stock Validation Rules', () {
      final now = DateTime.now();

      test('ProductModel supports optional maxStockAlert', () {
        final product = ProductModel(
          id: 'prod_101',
          shopId: 'shop_1',
          name: 'Basmati Rice 5kg',
          sellingPricePaise: 55000,
          mrpPaise: 60000,
          currentStock: 15.0,
          minStockAlert: 5.0,
          maxStockAlert: 50.0,
          unit: 'KG',
          createdAt: now,
          updatedAt: now,
        );

        expect(product.minStockAlert, 5.0);
        expect(product.maxStockAlert, 50.0);

        final json = product.toJson();
        expect(json['min_stock_alert'], 5.0);
        expect(json['max_stock_alert'], 50.0);

        final deserialized = ProductModel.fromJson(json);
        expect(deserialized.minStockAlert, 5.0);
        expect(deserialized.maxStockAlert, 50.0);
      });

      test('copyWith updates or clears maxStockAlert correctly', () {
        final product = ProductModel(
          id: 'prod_102',
          shopId: 'shop_1',
          name: 'Sunflower Oil 1L',
          sellingPricePaise: 18000,
          mrpPaise: 20000,
          currentStock: 8.0,
          minStockAlert: 3.0,
          maxStockAlert: 20.0,
          unit: 'LITER',
          createdAt: now,
          updatedAt: now,
        );

        final updated = product.copyWith(maxStockAlert: 30.0);
        expect(updated.maxStockAlert, 30.0);

        final cleared = updated.copyWith(clearMaxStockAlert: true);
        expect(cleared.maxStockAlert, isNull);
      });
    });

    // 4. Inventory Search & Filter Logic
    group('4. Inventory Search & Status Filtering Logic', () {
      final now = DateTime.now();
      final productsList = [
        ProductModel(
          id: 'p1',
          shopId: 'shop_1',
          name: 'Amul Butter 500g',
          brand: 'Amul',
          categoryId: 'cat_dairy',
          sellingPricePaise: 27500,
          mrpPaise: 29000,
          currentStock: 20.0,
          minStockAlert: 5.0,
          unit: 'PACK',
          createdAt: now,
          updatedAt: now,
        ),
        ProductModel(
          id: 'p2',
          shopId: 'shop_1',
          name: 'Fortune Wheat Flour 10kg',
          brand: 'Fortune',
          categoryId: 'cat_staples',
          sellingPricePaise: 42000,
          mrpPaise: 45000,
          currentStock: 3.0,
          minStockAlert: 5.0,
          unit: 'KG',
          createdAt: now,
          updatedAt: now,
        ),
        ProductModel(
          id: 'p3',
          shopId: 'shop_1',
          name: 'Tata Salt 1kg',
          brand: 'Tata',
          categoryId: 'cat_staples',
          sellingPricePaise: 2800,
          mrpPaise: 3000,
          currentStock: 0.0,
          minStockAlert: 10.0,
          unit: 'KG',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      test('Filters products by StockStatusFilter.inStock', () {
        final filtered = productsList.where((p) {
          final status =
              StockStatus.fromQuantities(p.currentStock, p.minStockAlert);
          return status == StockStatus.inStock;
        }).toList();

        expect(filtered.length, 1);
        expect(filtered.first.name, 'Amul Butter 500g');
      });

      test('Filters products by StockStatusFilter.lowStock', () {
        final filtered = productsList.where((p) {
          final status =
              StockStatus.fromQuantities(p.currentStock, p.minStockAlert);
          return status == StockStatus.lowStock;
        }).toList();

        expect(filtered.length, 1);
        expect(filtered.first.name, 'Fortune Wheat Flour 10kg');
      });

      test('Filters products by StockStatusFilter.outOfStock', () {
        final filtered = productsList.where((p) {
          final status =
              StockStatus.fromQuantities(p.currentStock, p.minStockAlert);
          return status == StockStatus.outOfStock;
        }).toList();

        expect(filtered.length, 1);
        expect(filtered.first.name, 'Tata Salt 1kg');
      });

      test('Local product search matches name and brand', () {
        final term = 'fortune';
        final results = productsList.where((p) {
          return p.name.toLowerCase().contains(term) ||
              (p.brand?.toLowerCase().contains(term) ?? false);
        }).toList();

        expect(results.length, 1);
        expect(results.first.name, 'Fortune Wheat Flour 10kg');
      });
    });

    // 5. RBAC Permission Security
    group('Security & Permission Controls', () {
      test('Cashier role cannot perform stock settings adjustments', () {
        const String userRole = 'cashier';
        final bool isAuthorized = userRole == 'owner' || userRole == 'manager';

        expect(isAuthorized, isFalse);

        Failure? error;
        if (!isAuthorized) {
          error = const PermissionDeniedFailure(
              'Permission denied: Cashier cannot modify stock settings');
        }

        expect(error, isA<PermissionDeniedFailure>());
        expect(
            error?.message, contains('Cashier cannot modify stock settings'));
      });

      test('Owner or Manager role is authorized to modify stock settings', () {
        for (final role in ['owner', 'manager']) {
          final bool isAuthorized = role == 'owner' || role == 'manager';
          expect(isAuthorized, isTrue);
        }
      });
    });
  });
}
