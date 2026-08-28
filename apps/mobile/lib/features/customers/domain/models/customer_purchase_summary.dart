import '../../../../database/drift/database.dart';

class CustomerPurchaseSummary {
  final int totalPurchasesPaise;
  final int totalBillsCount;
  final BillData? lastPurchase;

  const CustomerPurchaseSummary({
    required this.totalPurchasesPaise,
    required this.totalBillsCount,
    this.lastPurchase,
  });

  bool get hasPurchases => totalBillsCount > 0 && lastPurchase != null;
}
