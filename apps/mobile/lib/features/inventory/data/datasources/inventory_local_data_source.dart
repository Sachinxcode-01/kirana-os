import 'package:drift/drift.dart';
import 'package:kirana_mobile/database/drift/database.dart';
import '../../domain/models/inventory_movement_model.dart';

class InventoryLocalDataSource {
  final AppDatabase _db;

  InventoryLocalDataSource(this._db);

  Future<InventoryMovementModel> recordMovementAndStockUpdate({
    required String shopId,
    required String productId,
    required double quantityDelta,
    required String reason,
    required String performedBy,
    String? referenceId,
    String? note,
  }) async {
    return await _db.transaction(() async {
      final productQuery = _db.select(_db.productsTable)
        ..where((t) => t.id.equals(productId) & t.shopId.equals(shopId));
      final product = await productQuery.getSingleOrNull();

      if (product == null) {
        throw Exception('Product $productId not found in local database');
      }

      final previousStock = product.currentStock;
      final newStock = previousStock + quantityDelta;

      // Update product current stock
      await (_db.update(_db.productsTable)
            ..where((t) => t.id.equals(productId) & t.shopId.equals(shopId)))
          .write(
        ProductsTableCompanion(
          currentStock: Value(newStock),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Create movement log entry
      final movementId = DateTime.now().microsecondsSinceEpoch.toString();
      final now = DateTime.now();

      await _db.into(_db.inventoryMovementsTable).insert(
            InventoryMovementsTableCompanion.insert(
              id: movementId,
              shopId: shopId,
              productId: productId,
              quantityDelta: quantityDelta,
              balanceAfter: newStock,
              reason: reason,
              performedBy: performedBy,
              referenceId: Value(referenceId),
              createdAt: Value(now),
            ),
          );

      return InventoryMovementModel(
        id: movementId,
        shopId: shopId,
        productId: productId,
        productName: product.name,
        quantityDelta: quantityDelta,
        balanceAfter: newStock,
        reason: reason,
        referenceId: referenceId,
        performedBy: performedBy,
        note: note,
        createdAt: now,
      );
    });
  }

  Future<List<InventoryMovementModel>> getInventoryHistory({
    required String shopId,
    String? productId,
    int limit = 20,
    int offset = 0,
  }) async {
    final query = _db.select(_db.inventoryMovementsTable).join([
      innerJoin(
        _db.productsTable,
        _db.productsTable.id.equalsExp(_db.inventoryMovementsTable.productId),
      )
    ]);

    query.where(_db.inventoryMovementsTable.shopId.equals(shopId));
    if (productId != null && productId.isNotEmpty) {
      query.where(_db.inventoryMovementsTable.productId.equals(productId));
    }

    query.orderBy([
      OrderingTerm(
        expression: _db.inventoryMovementsTable.createdAt,
        mode: OrderingMode.desc,
      )
    ]);

    query.limit(limit, offset: offset);

    final rows = await query.get();

    return rows.map((row) {
      final movement = row.readTable(_db.inventoryMovementsTable);
      final product = row.readTable(_db.productsTable);

      return InventoryMovementModel(
        id: movement.id,
        shopId: movement.shopId,
        productId: movement.productId,
        productName: product.name,
        quantityDelta: movement.quantityDelta,
        balanceAfter: movement.balanceAfter,
        reason: movement.reason,
        referenceId: movement.referenceId,
        performedBy: movement.performedBy,
        createdAt: movement.createdAt,
      );
    }).toList();
  }

  Future<List<ProductData>> getLowStockProducts(String shopId) async {
    final query = _db.select(_db.productsTable)
      ..where((t) => t.shopId.equals(shopId) & t.isActive.equals(true));

    final products = await query.get();
    return products.where((p) => p.currentStock <= p.minStockAlert).toList();
  }
}
