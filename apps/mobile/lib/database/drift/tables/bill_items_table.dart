import 'package:drift/drift.dart';

@DataClassName('BillItemData')
class BillItemsTable extends Table {
  @override
  String get tableName => 'bill_items';

  TextColumn get id => text()();
  TextColumn get billId => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text().withLength(min: 1, max: 255)();
  RealColumn get quantity => real()();
  Int64Column get unitPricePaise => int64()();
  RealColumn get taxRate => real().withDefault(const Constant(0.0))();
  Int64Column get taxAmountPaise => int64().clientDefault(() => BigInt.zero)();
  Int64Column get totalPaise => int64()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
