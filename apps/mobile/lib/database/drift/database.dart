import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/shops_table.dart';
import 'tables/user_profiles_table.dart';
import 'tables/products_table.dart';
import 'tables/product_barcodes_table.dart';
import 'tables/categories_table.dart';
import 'tables/customers_table.dart';
import 'tables/bills_table.dart';
import 'tables/bill_items_table.dart';
import 'tables/payments_table.dart';
import 'tables/credit_transactions_table.dart';
import 'tables/inventory_movements_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/suppliers_table.dart';
import 'tables/purchases_table.dart';
import 'tables/purchase_items_table.dart';

import 'daos/products_dao.dart';
import 'daos/billing_dao.dart';
import 'daos/customers_dao.dart';
import 'daos/sync_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/suppliers_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    ShopsTable,
    UserProfilesTable,
    ProductsTable,
    ProductBarcodesTable,
    CategoriesTable,
    CustomersTable,
    BillsTable,
    BillItemsTable,
    PaymentsTable,
    CreditTransactionsTable,
    InventoryMovementsTable,
    SyncQueueTable,
    SuppliersTable,
    PurchasesTable,
    PurchaseItemsTable,
  ],
  daos: [
    ProductsDao,
    BillingDao,
    CustomersDao,
    SyncDao,
    CategoriesDao,
    SuppliersDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(userProfilesTable);
          }
          if (from < 3) {
            await m.addColumn(shopsTable, shopsTable.logoUrl);
            await m.addColumn(shopsTable, shopsTable.receiptName);
          }
          if (from < 4) {
            await m.addColumn(customersTable, customersTable.email);
            await m.addColumn(customersTable, customersTable.notes);
            await m.addColumn(customersTable, customersTable.isArchived);
          }
          if (from < 5) {
            await m.addColumn(productsTable,
                (productsTable as dynamic).sku as GeneratedColumn<Object>);
          }
          if (from < 6) {
            await m.createTable(suppliersTable);
            await m.createTable(purchasesTable);
            await m.createTable(purchaseItemsTable);
          }
        },
        beforeOpen: (details) async {
          // Enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'kirana_os_db',
      native: const DriftNativeOptions(
        shareAcrossIsolates: true,
      ),
    );
  }
}
