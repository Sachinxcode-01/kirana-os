import 'package:drift/drift.dart';

@DataClassName('UserProfileData')
class UserProfilesTable extends Table {
  @override
  String get tableName => 'user_profiles';

  TextColumn get id => text()();
  TextColumn get fullName => text().withLength(min: 1, max: 255)();
  TextColumn get email => text().withLength(min: 1, max: 255)();
  TextColumn get phone => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('owner'))();
  TextColumn get activeShopId => text().nullable()();
  TextColumn get activeShopName => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('SYNCED'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
