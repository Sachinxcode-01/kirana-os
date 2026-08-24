import 'package:drift/drift.dart';
import '../../../../database/drift/database.dart';
import '../../domain/models/shop_model.dart';

class ShopLocalDataSource {
  final AppDatabase _db;

  ShopLocalDataSource(this._db);

  Future<void> saveShop(ShopModel shop, {required String ownerId}) async {
    await _db.into(_db.shopsTable).insertOnConflictUpdate(
          ShopsTableCompanion(
            id: Value(shop.id),
            name: Value(shop.name),
            ownerId: Value(ownerId),
            phone: Value(shop.phone),
            email: Value(shop.email),
            gstin: Value(shop.gstin),
            fssaiLicense: Value(shop.fssaiLicense),
            address: Value(shop.address),
            city: Value(shop.city),
            state: Value(shop.state),
            pincode: Value(shop.pincode),
            upiId: Value(shop.upiId),
            currency: Value(shop.currency),
            createdAt: Value(shop.createdAt),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<ShopModel?> getShopById(String shopId) async {
    final query = _db.select(_db.shopsTable)..where((tbl) => tbl.id.equals(shopId));
    final shop = await query.getSingleOrNull();
    if (shop == null) return null;

    return ShopModel(
      id: shop.id,
      name: shop.name,
      phone: shop.phone,
      email: shop.email,
      gstin: shop.gstin,
      fssaiLicense: shop.fssaiLicense,
      address: shop.address,
      city: shop.city,
      state: shop.state,
      pincode: shop.pincode,
      upiId: shop.upiId,
      currency: shop.currency,
      createdAt: shop.createdAt,
    );
  }
}
