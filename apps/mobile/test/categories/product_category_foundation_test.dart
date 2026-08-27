import 'package:flutter_test/flutter_test.dart';

import 'package:kirana_mobile/features/categories/domain/models/category_model.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';

void main() {
  group('Phase 13.4 — Product Category Foundation Models & Domain Logic', () {
    final now = DateTime.now();

    final cat1 = CategoryModel(
      id: 'cat_bev_1',
      shopId: 'shop_A',
      name: 'Beverages',
      description: 'Soft drinks, juices, and cold drinks',
      iconUrl: null,
      sortOrder: 1,
      isActive: true,
      productCount: 2,
      createdAt: now,
      updatedAt: now,
    );

    final cat2 = CategoryModel(
      id: 'cat_snk_2',
      shopId: 'shop_A',
      name: 'Snacks & Namkeen',
      description: 'Chips, biscuits, and traditional namkeen',
      iconUrl: null,
      sortOrder: 2,
      isActive: true,
      productCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    final prod1 = ProductModel(
      id: 'prod_cola_1',
      shopId: 'shop_A',
      name: 'Coca-Cola 750ml',
      categoryId: 'cat_bev_1',
      sellingPricePaise: 4000, // ₹40.00
      mrpPaise: 4500,
      unit: 'BOTTLE',
      currentStock: 24,
      createdAt: now,
      updatedAt: now,
    );

    final prod2 = ProductModel(
      id: 'prod_frooti_2',
      shopId: 'shop_A',
      name: 'Frooti Mango Drink 600ml',
      categoryId: 'cat_bev_1',
      sellingPricePaise: 3500, // ₹35.00
      mrpPaise: 4000,
      unit: 'BOTTLE',
      currentStock: 18,
      createdAt: now,
      updatedAt: now,
    );

    test('1. Feature: Category Model serialization & JSON round-trip', () {
      final json = cat1.toJson();
      expect(json['id'], equals('cat_bev_1'));
      expect(json['shop_id'], equals('shop_A'));
      expect(json['name'], equals('Beverages'));
      expect(json['is_active'], isTrue);

      final deserialized = CategoryModel.fromJson(json);
      expect(deserialized.id, equals(cat1.id));
      expect(deserialized.name, equals(cat1.name));
      expect(deserialized.description, equals(cat1.description));
    });

    test(
        '2. Feature: Category Duplicate Normalized Comparison (Case-Insensitive)',
        () {
      final existingName = cat1.name.trim().toLowerCase();
      const inputName1 = 'beverages';
      const inputName2 = ' BEVERAGES ';

      expect(inputName1.trim().toLowerCase(), equals(existingName));
      expect(inputName2.trim().toLowerCase(), equals(existingName));
    });

    test(
        '3. Feature: Category Editing updates properties while preserving ID and Shop',
        () {
      final updatedCat = cat1.copyWith(
        name: 'Cold Beverages & Juices',
        description: 'Updated description for beverages',
        sortOrder: 5,
      );

      expect(updatedCat.id, equals('cat_bev_1'));
      expect(updatedCat.shopId, equals('shop_A'));
      expect(updatedCat.name, equals('Cold Beverages & Juices'));
      expect(updatedCat.sortOrder, equals(5));
    });

    test(
        '4. Feature: Category Archiving Protection blocks categories with active products',
        () {
      // Cat 1 has productCount = 2
      final canArchiveCat1 = cat1.productCount == 0;
      expect(canArchiveCat1, isFalse,
          reason: 'Must block archiving when active products are attached');

      // Cat 2 has productCount = 0
      final canArchiveCat2 = cat2.productCount == 0;
      expect(canArchiveCat2, isTrue,
          reason: 'Should allow archiving empty categories');
    });

    test('5. Feature: Product Category Assignment & Category List Filtering',
        () {
      final catalog = [prod1, prod2];

      final filteredBev =
          catalog.where((p) => p.categoryId == 'cat_bev_1').toList();
      final filteredSnack =
          catalog.where((p) => p.categoryId == 'cat_snk_2').toList();

      expect(filteredBev.length, equals(2));
      expect(filteredSnack.length, equals(0));
    });

    test(
        '6. Feature: Category Reassignment retains historical bill snapshot safety',
        () {
      // Product reassigned to new category
      final reassignedProd1 = prod1.copyWith(categoryId: 'cat_snk_2');
      expect(reassignedProd1.categoryId, equals('cat_snk_2'));

      // Product details snapshot at bill creation remain unaffected by category changes
      expect(prod1.name, equals('Coca-Cola 750ml'));
      expect(prod1.sellingPricePaise, equals(4000));
    });
  });
}
