import 'package:drift/drift.dart';

@DataClassName('BillData')
class BillsTable extends Table {
  @override
  String get tableName => 'bills';

  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get billNumber => text().withLength(min: 1, max: 50)();
  TextColumn get customerId => text().nullable()();
  TextColumn get cashierId => text()();
  Int64Column get subtotalPaise => int64()();
  Int64Column get taxTotalPaise => int64().clientDefault(() => BigInt.zero)();
  Int64Column get discountPaise => int64().clientDefault(() => BigInt.zero)();
  Int64Column get totalPaise => int64()();
  TextColumn get paymentStatus => text().withDefault(const Constant('paid'))();
  BoolColumn get isCancelled => boolean().withDefault(const Constant(false))();
  TextColumn get cancellationReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {shopId, billNumber}
      ];
}
