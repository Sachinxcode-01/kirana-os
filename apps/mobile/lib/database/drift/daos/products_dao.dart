import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/products_table.dart';
import '../tables/product_barcodes_table.dart';
import '../tables/categories_table.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [ProductsTable, ProductBarcodesTable, CategoriesTable])
class ProductsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductsDaoMixin {
  ProductsDao(super.db);

  /// Fast indexed barcode lookup (<15ms)
  Future<ProductData?> getProductByBarcode(
      String shopId, String barcode) async {
    final query = select(productsTable).join([
      innerJoin(
        productBarcodesTable,
        productBarcodesTable.productId.equalsExp(productsTable.id),
      ),
    ])
      ..where(productBarcodesTable.shopId.equals(shopId) &
          productBarcodesTable.barcode.equals(barcode.trim()) &
          productsTable.isActive.equals(true));

    final row = await query.getSingleOrNull();
    return row?.readTable(productsTable);
  }

  /// Live stream of active products with optional category and search filter
  Stream<List<ProductData>> watchProducts(
    String shopId, {
    String? categoryId,
    String? searchQuery,
  }) {
    final query = select(productsTable)
      ..where((t) {
        var predicate = t.shopId.equals(shopId) & t.isActive.equals(true);
        if (categoryId != null && categoryId.isNotEmpty) {
          predicate = predicate & t.categoryId.equals(categoryId);
        }
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final term = '%${searchQuery.trim().toLowerCase()}%';
          predicate = predicate &
              (t.name.lower().like(term) |
                  t.brand.lower().like(term) |
                  t.description.lower().like(term));
        }
        return predicate;
      })
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);

    return query.watch();
  }

  /// Get active products list
  Future<List<ProductData>> getProducts(
    String shopId, {
    String? categoryId,
    String? searchQuery,
  }) {
    final query = select(productsTable)
      ..where((t) {
        var predicate = t.shopId.equals(shopId) & t.isActive.equals(true);
        if (categoryId != null && categoryId.isNotEmpty) {
          predicate = predicate & t.categoryId.equals(categoryId);
        }
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final term = '%${searchQuery.trim().toLowerCase()}%';
          predicate = predicate &
              (t.name.lower().like(term) |
                  t.brand.lower().like(term) |
                  t.description.lower().like(term));
        }
        return predicate;
      })
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);

    return query.get();
  }

  /// Get product by ID
  Future<ProductData?> getProductById(String id) {
    return (select(productsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Check duplicate product name in shop (case-insensitive)
  Future<ProductData?> getProductByName(String shopId, String name) {
    return (select(productsTable)
          ..where((t) =>
              t.shopId.equals(shopId) &
              t.name.lower().equals(name.trim().toLowerCase()) &
              t.isActive.equals(true)))
        .getSingleOrNull();
  }

  /// Insert or update product
  Future<void> upsertProduct(ProductsTableCompanion product) async {
    await into(productsTable).insertOnConflictUpdate(product);
  }

  /// Soft delete / archive product
  Future<void> softDeleteProduct(String id) async {
    await (update(productsTable)..where((t) => t.id.equals(id))).write(
      ProductsTableCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ===========================================================================
  // BARCODE METHODS
  // ===========================================================================

  /// Get all barcodes for a specific product
  Future<List<ProductBarcodeData>> getBarcodesForProduct(String productId) {
    return (select(productBarcodesTable)
          ..where((t) => t.productId.equals(productId))
          ..orderBy([(t) => OrderingTerm.desc(t.isPrimary)]))
        .get();
  }

  /// Watch barcodes for a specific product
  Stream<List<ProductBarcodeData>> watchBarcodesForProduct(String productId) {
    return (select(productBarcodesTable)
          ..where((t) => t.productId.equals(productId))
          ..orderBy([(t) => OrderingTerm.desc(t.isPrimary)]))
        .watch();
  }

  /// Get barcode by shop & exact barcode string
  Future<ProductBarcodeData?> getBarcodeByValue(String shopId, String barcode) {
    return (select(productBarcodesTable)
          ..where((t) =>
              t.shopId.equals(shopId) &
              t.barcode.equals(barcode.trim().toUpperCase())))
        .getSingleOrNull();
  }

  /// Get barcode by ID
  Future<ProductBarcodeData?> getBarcodeById(String id) {
    return (select(productBarcodesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Upsert barcode entry
  Future<void> linkBarcode(ProductBarcodesTableCompanion barcode) async {
    await into(productBarcodesTable).insertOnConflictUpdate(barcode);
  }

  /// Delete single barcode by ID
  Future<void> deleteBarcode(String id) async {
    await (delete(productBarcodesTable)..where((t) => t.id.equals(id))).go();
  }

  /// Delete all barcodes for a product
  Future<void> deleteBarcodesForProduct(String productId) async {
    await (delete(productBarcodesTable)
          ..where((t) => t.productId.equals(productId)))
        .go();
  }
}
