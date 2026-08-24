import 'package:drift/drift.dart';

@DataClassName('CreditTransactionData')
class CreditTransactionsTable extends Table {
  @override
  String get tableName => 'credit_transactions';

  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get customerId => text()();
  TextColumn get billId => text().nullable()();
  Int64Column get amountPaise => int64()();
  TextColumn get type => text()(); // 'credit_given', 'payment_received', 'bad_debt_writeoff'
  TextColumn get notes => text().nullable()();
  TextColumn get recordedBy => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
