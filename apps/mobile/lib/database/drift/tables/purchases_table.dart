import 'package:drift/drift.dart';

@DataClassName('PurchaseData')
class PurchasesTable extends Table {
  @override
  String get tableName => 'purchases';

  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get supplierId => text().nullable()();
  TextColumn get invoiceNumber => text()();
  DateTimeColumn get invoiceDate => dateTime()();
  Int64Column get subtotalPaise => int64()();
  Int64Column get taxTotalPaise => int64()();
  Int64Column get totalPaise => int64()();
  TextColumn get status => text()(); // 'completed', 'cancelled'
  TextColumn get supplierNameSnapshot => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
