import 'package:drift/drift.dart';

@DataClassName('ShopData')
class ShopsTable extends Table {
  @override
  String get tableName => 'shops';

  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get ownerId => text()();
  TextColumn get phone => text().withLength(min: 1, max: 20)();
  TextColumn get email => text().nullable()();
  TextColumn get gstin => text().nullable()();
  TextColumn get fssaiLicense => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get state => text().withDefault(const Constant('Karnataka'))();
  TextColumn get pincode => text().nullable()();
  TextColumn get upiId => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
