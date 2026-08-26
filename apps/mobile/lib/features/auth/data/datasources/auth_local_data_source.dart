import 'package:drift/drift.dart';
import '../../../../database/drift/database.dart';
import '../../domain/models/auth_state_model.dart';

class AuthLocalDataSource {
  final AppDatabase _db;

  AuthLocalDataSource(this._db);

  Future<void> saveUserProfile(
    UserModel user, {
    String syncStatus = 'SYNCED',
  }) async {
    await _db.into(_db.userProfilesTable).insertOnConflictUpdate(
          UserProfilesTableCompanion(
            id: Value(user.id),
            fullName: Value(user.displayName ?? user.email),
            email: Value(user.email),
            phone: Value(user.phone),
            avatarUrl: Value(user.avatarUrl),
            role: Value(user.role),
            activeShopId: Value(user.shopId),
            activeShopName: Value(user.shopName),
            syncStatus: Value(syncStatus),
            lastSyncedAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<UserModel?> getUserProfile(String userId) async {
    final query = _db.select(_db.userProfilesTable)
      ..where((tbl) => tbl.id.equals(userId));
    final profile = await query.getSingleOrNull();
    if (profile == null) return null;

    return UserModel(
      id: profile.id,
      email: profile.email,
      phone: profile.phone,
      displayName: profile.fullName,
      role: profile.role,
      avatarUrl: profile.avatarUrl,
      shopId: profile.activeShopId,
      shopName: profile.activeShopName,
    );
  }

  Future<void> clearUserProfile(String userId) async {
    await (_db.delete(_db.userProfilesTable)
          ..where((tbl) => tbl.id.equals(userId)))
        .go();
  }

  Future<void> clearAllUserProfiles() async {
    await _db.delete(_db.userProfilesTable).go();
  }
}
