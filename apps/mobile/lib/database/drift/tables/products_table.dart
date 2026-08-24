import 'package:drift/drift.dart';

@DataClassName('ProductData')
class ProductsTable extends Table {
  @override
  String get tableName => 'products';

  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get regionalName => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get hsnCode => text().nullable()();
  Int64Column get mrpPaise => int64()();
  Int64Column get sellingPricePaise => int64()();
  Int64Column get purchasePricePaise =>
      int64().clientDefault(() => BigInt.zero)();
  RealColumn get taxRatePercentage => real().withDefault(const Constant(0.0))();
  BoolColumn get isTaxInclusive =>
      boolean().withDefault(const Constant(true))();
  RealColumn get currentStock => real().withDefault(const Constant(0.0))();
  RealColumn get minStockAlert => real().withDefault(const Constant(5.0))();
  BoolColumn get isLoose => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
