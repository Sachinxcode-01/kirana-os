import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/products_table.dart';
import '../tables/product_barcodes_table.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [ProductsTable, ProductBarcodesTable])
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
          productBarcodesTable.barcode.equals(barcode) &
          productsTable.isActive.equals(true));

    final row = await query.getSingleOrNull();
    return row?.readTable(productsTable);
  }

  /// Live stream of active products for POS search
  Stream<List<ProductData>> watchProducts(String shopId) {
    return (select(productsTable)
          ..where((t) => t.shopId.equals(shopId) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Insert or update product
  Future<void> upsertProduct(ProductsTableCompanion product) async {
    await into(productsTable).insertOnConflictUpdate(product);
  }

  /// Map barcode to product
  Future<void> linkBarcode(ProductBarcodesTableCompanion barcode) async {
    await into(productBarcodesTable).insertOnConflictUpdate(barcode);
  }
}
