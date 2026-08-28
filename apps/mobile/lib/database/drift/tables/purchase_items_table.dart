import 'package:drift/drift.dart';

@DataClassName('PurchaseItemData')
class PurchaseItemsTable extends Table {
  @override
  String get tableName => 'purchase_items';

  TextColumn get id => text()();
  TextColumn get purchaseId => text()();
  TextColumn get productId => text()();
  RealColumn get quantity => real()();
  Int64Column get purchasePricePaise => int64()();
  RealColumn get taxRate => real()();
  Int64Column get totalPaise => int64()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
