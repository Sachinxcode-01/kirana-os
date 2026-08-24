import 'package:drift/drift.dart';

@DataClassName('CustomerData')
class CustomersTable extends Table {
  @override
  String get tableName => 'customers';

  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get phone => text().withLength(min: 1, max: 20)();
  TextColumn get address => text().nullable()();
  Int64Column get creditLimitPaise =>
      int64().clientDefault(() => BigInt.from(500000))(); // Default ₹5,000.00
  Int64Column get currentDebtPaise =>
      int64().clientDefault(() => BigInt.zero)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {shopId, phone}
      ];
}
