import 'package:drift/drift.dart';

@DataClassName('PaymentData')
class PaymentsTable extends Table {
  @override
  String get tableName => 'payments';

  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get billId => text()();
  TextColumn get mode => text()(); // 'cash', 'upi_qr', 'credit_khata', 'card', 'split'
  Int64Column get amountPaise => int64()();
  TextColumn get referenceNumber => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
