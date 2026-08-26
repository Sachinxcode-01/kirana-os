import 'package:flutter/material.dart';
import 'bill_model.dart';

enum PaymentFilter {
  all,
  cash,
  upi,
  card,
}

extension PaymentFilterExtension on PaymentFilter {
  String get label {
    switch (this) {
      case PaymentFilter.all:
        return 'ALL';
      case PaymentFilter.cash:
        return 'CASH';
      case PaymentFilter.upi:
        return 'UPI';
      case PaymentFilter.card:
        return 'CARD';
    }
  }

  String? get dbValue {
    switch (this) {
      case PaymentFilter.all:
        return null;
      case PaymentFilter.cash:
        return 'cash';
      case PaymentFilter.upi:
        return 'upi_qr';
      case PaymentFilter.card:
        return 'card';
    }
  }

  static PaymentFilter fromString(String? raw) {
    if (raw == null) return PaymentFilter.all;
    switch (raw.toLowerCase().trim()) {
      case 'cash':
        return PaymentFilter.cash;
      case 'upi':
      case 'upi_qr':
        return PaymentFilter.upi;
      case 'card':
        return PaymentFilter.card;
      default:
        return PaymentFilter.all;
    }
  }
}

enum BillStatusFilter {
  all,
  completed,
  failed,
  cancelled,
}

extension BillStatusFilterExtension on BillStatusFilter {
  String get label {
    switch (this) {
      case BillStatusFilter.all:
        return 'ALL';
      case BillStatusFilter.completed:
        return 'COMPLETED';
      case BillStatusFilter.failed:
        return 'FAILED';
      case BillStatusFilter.cancelled:
        return 'CANCELLED';
    }
  }

  String? get dbValue {
    switch (this) {
      case BillStatusFilter.all:
        return null;
      case BillStatusFilter.completed:
        return 'completed';
      case BillStatusFilter.failed:
        return 'failed';
      case BillStatusFilter.cancelled:
        return 'cancelled';
    }
  }

  static BillStatusFilter fromString(String? raw) {
    if (raw == null) return BillStatusFilter.all;
    switch (raw.toLowerCase().trim()) {
      case 'completed':
      case 'paid':
        return BillStatusFilter.completed;
      case 'failed':
        return BillStatusFilter.failed;
      case 'cancelled':
        return BillStatusFilter.cancelled;
      default:
        return BillStatusFilter.all;
    }
  }
}

class BillHistoryFilter {
  final String? search;
  final DateTimeRange? dateRange;
  final PaymentFilter paymentFilter;
  final BillStatusFilter statusFilter;
  final String? cashierId;
  final int page;
  final int pageSize;

  const BillHistoryFilter({
    this.search,
    this.dateRange,
    this.paymentFilter = PaymentFilter.all,
    this.statusFilter = BillStatusFilter.all,
    this.cashierId,
    this.page = 0,
    this.pageSize = 20,
  });

  bool get hasActiveFilters =>
      (search != null && search!.trim().isNotEmpty) ||
      dateRange != null ||
      paymentFilter != PaymentFilter.all ||
      statusFilter != BillStatusFilter.all ||
      (cashierId != null && cashierId!.isNotEmpty);

  BillHistoryFilter copyWith({
    String? search,
    bool clearSearch = false,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    PaymentFilter? paymentFilter,
    BillStatusFilter? statusFilter,
    String? cashierId,
    bool clearCashierId = false,
    int? page,
    int? pageSize,
  }) {
    return BillHistoryFilter(
      search: clearSearch ? null : (search ?? this.search),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      paymentFilter: paymentFilter ?? this.paymentFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      cashierId: clearCashierId ? null : (cashierId ?? this.cashierId),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class BillHistoryResult {
  final List<BillModel> bills;
  final bool hasMore;
  final int totalCount;
  final bool isOffline;
  final bool isPartialOfflineHistory;

  const BillHistoryResult({
    required this.bills,
    required this.hasMore,
    required this.totalCount,
    this.isOffline = false,
    this.isPartialOfflineHistory = false,
  });
}
