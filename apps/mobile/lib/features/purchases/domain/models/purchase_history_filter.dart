import 'package:flutter/material.dart';
import 'purchase_model.dart';

enum PurchaseStatusFilter {
  all,
  draft,
  completed;

  String get label {
    switch (this) {
      case PurchaseStatusFilter.all:
        return 'ALL';
      case PurchaseStatusFilter.draft:
        return 'DRAFT';
      case PurchaseStatusFilter.completed:
        return 'COMPLETED';
    }
  }

  String? get dbValue {
    switch (this) {
      case PurchaseStatusFilter.all:
        return null;
      case PurchaseStatusFilter.draft:
        return 'draft';
      case PurchaseStatusFilter.completed:
        return 'completed';
    }
  }

  static PurchaseStatusFilter fromString(String? raw) {
    if (raw == null) return PurchaseStatusFilter.all;
    switch (raw.toLowerCase().trim()) {
      case 'draft':
        return PurchaseStatusFilter.draft;
      case 'completed':
        return PurchaseStatusFilter.completed;
      default:
        return PurchaseStatusFilter.all;
    }
  }
}

class PurchaseHistoryFilter {
  final String? search;
  final DateTimeRange? dateRange;
  final PurchaseStatusFilter statusFilter;
  final String? supplierId;
  final int page;
  final int pageSize;

  const PurchaseHistoryFilter({
    this.search,
    this.dateRange,
    this.statusFilter = PurchaseStatusFilter.all,
    this.supplierId,
    this.page = 1,
    this.pageSize = 20,
  });

  bool get hasActiveFilters =>
      (search != null && search!.trim().isNotEmpty) ||
      dateRange != null ||
      statusFilter != PurchaseStatusFilter.all ||
      (supplierId != null && supplierId!.isNotEmpty);

  PurchaseHistoryFilter copyWith({
    String? search,
    bool clearSearch = false,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    PurchaseStatusFilter? statusFilter,
    String? supplierId,
    bool clearSupplierId = false,
    int? page,
    int? pageSize,
  }) {
    return PurchaseHistoryFilter(
      search: clearSearch ? null : (search ?? this.search),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      statusFilter: statusFilter ?? this.statusFilter,
      supplierId: clearSupplierId ? null : (supplierId ?? this.supplierId),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class PurchaseHistoryResult {
  final List<PurchaseModel> purchases;
  final bool hasMore;
  final int totalCount;
  final bool isOffline;
  final bool isPartialOfflineHistory;

  const PurchaseHistoryResult({
    required this.purchases,
    required this.hasMore,
    required this.totalCount,
    this.isOffline = false,
    this.isPartialOfflineHistory = false,
  });
}
