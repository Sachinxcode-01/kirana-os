import 'package:drift/drift.dart';

@DataClassName('InventoryMovementData')
class InventoryMovementsTable extends Table {
  @override
  String get tableName => 'inventory_movements';

  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get productId => text()();
  RealColumn get previousQuantity => real().nullable()();
  RealColumn get quantityDelta =>
      real()(); // Negative for sales, positive for inward
  RealColumn get balanceAfter => real()();
  TextColumn get reason =>
      text()(); // 'sale', 'sale_return', 'purchase_inward', 'adjustment'
  TextColumn get adjustmentReason => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get idempotencyKey => text().nullable()();
  TextColumn get referenceId => text().nullable()();
  TextColumn get performedBy => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
