import 'package:drift/drift.dart';

@DataClassName('ProductBarcodeData')
class ProductBarcodesTable extends Table {
  @override
  String get tableName => 'product_barcodes';

  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get productId => text()();
  TextColumn get barcode => text().withLength(min: 1, max: 64)();
  TextColumn get barcodeType => text().withDefault(const Constant('EAN_13'))();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {shopId, barcode}
      ];
}
