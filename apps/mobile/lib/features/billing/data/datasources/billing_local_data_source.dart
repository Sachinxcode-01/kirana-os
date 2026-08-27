import 'package:drift/drift.dart';
import '../../../../database/drift/daos/billing_dao.dart';
import '../../../../database/drift/database.dart';
import '../../domain/models/bill_history_filter.dart';
import '../../domain/models/bill_model.dart';
import '../../domain/models/payment_model.dart';

class BillingLocalDataSource {
  final BillingDao? _billingDao;
  final Map<String, BillModel> _draftStore = {};
  final Map<String, BillModel> _completedStore = {};

  BillingLocalDataSource([BillingDao? billingDao]) : _billingDao = billingDao;

  Future<BillModel?> getDraftBill(String billId) async {
    return _draftStore[billId] ?? _completedStore[billId];
  }

  Future<List<BillModel>> getShopDrafts(String shopId) async {
    return _draftStore.values
        .where((b) => b.shopId == shopId && b.isDraft)
        .toList();
  }

  Future<void> saveDraftBill(BillModel bill) async {
    if (bill.isDraft) {
      _draftStore[bill.id] = bill;
    } else {
      _completedStore[bill.id] = bill;
    }

    if (_billingDao != null) {
      final billCompanion = BillsTableCompanion.insert(
        id: bill.id,
        shopId: bill.shopId,
        billNumber: bill.billNumber,
        cashierId: bill.cashierId,
        subtotalPaise: BigInt.from(bill.subtotalPaise),
        taxTotalPaise: Value(BigInt.from(bill.taxTotalPaise)),
        discountPaise: Value(BigInt.from(bill.discountPaise)),
        totalPaise: BigInt.from(bill.totalPaise),
        customerId: Value(bill.customerId),
        paymentStatus: Value(bill.paymentStatus),
        isCancelled: Value(bill.status == 'cancelled'),
        createdAt: Value(bill.createdAt),
        updatedAt: Value(bill.updatedAt),
      );

      final itemCompanions = bill.items
          .map((i) => BillItemsTableCompanion.insert(
                id: i.id,
                billId: bill.id,
                productId: i.productId,
                productName: i.productName,
                quantity: i.quantity,
                unitPricePaise: BigInt.from(i.unitPricePaise),
                taxRate: Value(i.taxRate),
                taxAmountPaise: Value(BigInt.from(i.taxAmountPaise)),
                totalPaise: BigInt.from(i.totalPaise),
                createdAt: Value(i.createdAt),
              ))
          .toList();

      await _billingDao.upsertCompletedBill(
        bill: billCompanion,
        items: itemCompanions,
      );
    }
  }

  Future<void> deleteDraftBill(String billId) async {
    _draftStore.remove(billId);
    _completedStore.remove(billId);
  }

  Future<List<BillModel>> getHistoricalBills({
    required String shopId,
    required BillHistoryFilter filter,
  }) async {
    if (_billingDao != null) {
      try {
        final rawBills = await _billingDao.getHistoricalBills(
          shopId: shopId,
          search: filter.search,
          startDate: filter.dateRange?.start,
          endDate: filter.dateRange?.end,
          cashierId: filter.cashierId,
          status: filter.statusFilter.dbValue,
          limit: filter.pageSize,
          offset: filter.page * filter.pageSize,
        );

        final List<BillModel> results = [];
        for (final b in rawBills) {
          final items = await _billingDao.getBillItemsForBill(b.id);
          final itemModels = items
              .map((i) => BillItemModel(
                    id: i.id,
                    billId: i.billId,
                    productId: i.productId,
                    productName: i.productName,
                    unitPricePaise: i.unitPricePaise.toInt(),
                    quantity: i.quantity,
                    taxRate: i.taxRate,
                    taxAmountPaise: i.taxAmountPaise.toInt(),
                    totalPaise: i.totalPaise.toInt(),
                    createdAt: i.createdAt,
                  ))
              .toList();

          results.add(BillModel(
            id: b.id,
            shopId: b.shopId,
            cashierId: b.cashierId,
            billNumber: b.billNumber,
            status: b.isCancelled ? 'cancelled' : 'completed',
            items: itemModels,
            customerId: b.customerId,
            subtotalPaise: b.subtotalPaise.toInt(),
            taxTotalPaise: b.taxTotalPaise.toInt(),
            discountPaise: b.discountPaise.toInt(),
            totalPaise: b.totalPaise.toInt(),
            paymentStatus: b.paymentStatus,
            createdAt: b.createdAt,
            updatedAt: b.updatedAt,
          ));
        }
        if (results.isNotEmpty) {
          return _applyFiltersInMemory(results, filter);
        }
      } catch (_) {
        // Fallback to memory store if DAO throws or table missing
      }
    }

    final allCompleted =
        _completedStore.values.where((b) => b.shopId == shopId).toList();
    return _applyFiltersInMemory(allCompleted, filter);
  }

  List<BillModel> _applyFiltersInMemory(
    List<BillModel> bills,
    BillHistoryFilter filter,
  ) {
    var filtered = bills.toList();

    // 1. Search term (bill number, customer phone, customer name)
    if (filter.search != null && filter.search!.trim().isNotEmpty) {
      final term = filter.search!.trim().toLowerCase();
      filtered = filtered.where((b) {
        final numMatch = b.billNumber.toLowerCase().contains(term);
        final nameMatch = b.customerName != null &&
            b.customerName!.toLowerCase().contains(term);
        final phoneMatch =
            b.customerPhone != null && b.customerPhone!.contains(term);
        return numMatch || nameMatch || phoneMatch;
      }).toList();
    }

    // 2. Date Range
    if (filter.dateRange != null) {
      final start = filter.dateRange!.start;
      final end = filter.dateRange!.end.add(const Duration(days: 1));
      filtered = filtered
          .where((b) => b.createdAt.isAfter(start) && b.createdAt.isBefore(end))
          .toList();
    }

    // 3. Payment Filter
    if (filter.paymentFilter != PaymentFilter.all) {
      // In local model filtering
      final expectedMode = filter.paymentFilter.dbValue;
      if (expectedMode != null) {
        // match payment status or items
      }
    }

    // 4. Status Filter
    if (filter.statusFilter != BillStatusFilter.all) {
      final expectedStatus = filter.statusFilter.dbValue;
      if (expectedStatus != null) {
        filtered = filtered
            .where((b) => b.status.toLowerCase() == expectedStatus)
            .toList();
      }
    }

    // 5. Cashier Filter
    if (filter.cashierId != null && filter.cashierId!.isNotEmpty) {
      filtered =
          filtered.where((b) => b.cashierId == filter.cashierId).toList();
    }

    // Sort by created_at DESC
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Pagination
    final startIdx = filter.page * filter.pageSize;
    if (startIdx >= filtered.length) return [];
    final endIdx = (startIdx + filter.pageSize).clamp(0, filtered.length);
    return filtered.sublist(startIdx, endIdx);
  }

  Future<void> cacheBills(List<BillModel> bills) async {
    for (final bill in bills) {
      _completedStore[bill.id] = bill;
    }
  }

  Future<void> saveCompletedPayment(PaymentModel payment) async {
    if (_billingDao != null) {
      final paymentCompanion = PaymentsTableCompanion.insert(
        id: payment.id,
        shopId: payment.shopId,
        billId: payment.billId,
        mode: payment.mode,
        amountPaise: BigInt.from(payment.amountPaise),
        status: Value(payment.status),
        referenceNumber: Value(payment.referenceNumber),
        createdAt: Value(payment.createdAt),
        updatedAt: Value(payment.updatedAt),
      );
      await _billingDao.upsertPayment(paymentCompanion);
    }
  }
}
