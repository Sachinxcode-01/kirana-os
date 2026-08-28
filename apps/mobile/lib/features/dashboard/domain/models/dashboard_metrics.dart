class TopProductItem {
  final String productName;
  final double quantitySold;

  const TopProductItem({
    required this.productName,
    required this.quantitySold,
  });

  factory TopProductItem.fromJson(Map<String, dynamic> json) {
    return TopProductItem(
      productName: json['product_name'] as String? ??
          json['productName'] as String? ??
          '',
      quantitySold:
          (json['quantity_sold'] ?? json['quantitySold'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_name': productName,
        'quantity_sold': quantitySold,
      };
}

class SalesTrendItem {
  final String dateStr;
  final String dayLabel;
  final BigInt totalPaise;

  const SalesTrendItem({
    required this.dateStr,
    required this.dayLabel,
    required this.totalPaise,
  });

  factory SalesTrendItem.fromJson(Map<String, dynamic> json) {
    final rawTotal = json['total_paise'] ?? json['totalPaise'];
    BigInt parsedTotal = BigInt.zero;
    if (rawTotal is BigInt) {
      parsedTotal = rawTotal;
    } else if (rawTotal is int) {
      parsedTotal = BigInt.from(rawTotal);
    } else if (rawTotal is String) {
      parsedTotal = BigInt.tryParse(rawTotal) ?? BigInt.zero;
    }

    return SalesTrendItem(
      dateStr: json['date_str'] as String? ?? json['dateStr'] as String? ?? '',
      dayLabel:
          json['day_label'] as String? ?? json['dayLabel'] as String? ?? '',
      totalPaise: parsedTotal,
    );
  }

  Map<String, dynamic> toJson() => {
        'date_str': dateStr,
        'day_label': dayLabel,
        'total_paise': totalPaise.toString(),
      };
}

class RecentBillItem {
  final String id;
  final String billNumber;
  final BigInt totalPaise;
  final String paymentStatus;
  final String? customerName;
  final DateTime createdAt;

  const RecentBillItem({
    required this.id,
    required this.billNumber,
    required this.totalPaise,
    required this.paymentStatus,
    this.customerName,
    required this.createdAt,
  });

  factory RecentBillItem.fromJson(Map<String, dynamic> json) {
    final rawTotal = json['totalPaise'] ?? json['total_paise'];
    BigInt parsedTotal = BigInt.zero;
    if (rawTotal is BigInt) {
      parsedTotal = rawTotal;
    } else if (rawTotal is int) {
      parsedTotal = BigInt.from(rawTotal);
    } else if (rawTotal is String) {
      parsedTotal = BigInt.tryParse(rawTotal) ?? BigInt.zero;
    }

    final rawCreated = json['createdAt'] ?? json['created_at'];
    DateTime created = DateTime.now();
    if (rawCreated is String) {
      created = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else if (rawCreated is DateTime) {
      created = rawCreated;
    }

    return RecentBillItem(
      id: json['id'] as String? ?? '',
      billNumber:
          json['billNumber'] as String? ?? json['bill_number'] as String? ?? '',
      totalPaise: parsedTotal,
      paymentStatus: json['paymentStatus'] as String? ??
          json['payment_status'] as String? ??
          'paid',
      customerName:
          json['customerName'] as String? ?? json['customer_name'] as String?,
      createdAt: created,
    );
  }
}

class DashboardMetrics {
  final BigInt todaySalesPaise;
  final int todayBillsCount;
  final int? yesterdayBillsCount;
  final List<TopProductItem> topProducts;
  final List<SalesTrendItem> salesTrend;
  final BigInt totalUdhaarOutstandingPaise;
  final int lowStockItemsCount;
  final List<RecentBillItem> recentBills;
  final DateTime? lastSyncedAt;
  final bool isOffline;

  const DashboardMetrics({
    required this.todaySalesPaise,
    required this.todayBillsCount,
    this.yesterdayBillsCount,
    this.topProducts = const [],
    this.salesTrend = const [],
    required this.totalUdhaarOutstandingPaise,
    required this.lowStockItemsCount,
    required this.recentBills,
    this.lastSyncedAt,
    this.isOffline = false,
  });

  factory DashboardMetrics.empty() {
    return DashboardMetrics(
      todaySalesPaise: BigInt.zero,
      todayBillsCount: 0,
      yesterdayBillsCount: null,
      topProducts: const [],
      salesTrend: const [],
      totalUdhaarOutstandingPaise: BigInt.zero,
      lowStockItemsCount: 0,
      recentBills: const [],
      lastSyncedAt: null,
      isOffline: false,
    );
  }

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    final rawTodaySales = json['todaySalesPaise'] ?? json['today_sales_paise'];
    BigInt todaySales = BigInt.zero;
    if (rawTodaySales is BigInt) {
      todaySales = rawTodaySales;
    } else if (rawTodaySales is int) {
      todaySales = BigInt.from(rawTodaySales);
    } else if (rawTodaySales is String) {
      todaySales = BigInt.tryParse(rawTodaySales) ?? BigInt.zero;
    }

    final rawUdhaar =
        json['totalUdhaarOutstandingPaise'] ?? json['total_udhaar_paise'];
    BigInt udhaar = BigInt.zero;
    if (rawUdhaar is BigInt) {
      udhaar = rawUdhaar;
    } else if (rawUdhaar is int) {
      udhaar = BigInt.from(rawUdhaar);
    } else if (rawUdhaar is String) {
      udhaar = BigInt.tryParse(rawUdhaar) ?? BigInt.zero;
    }

    final rawTopProducts = json['topProducts'] as List<dynamic>? ?? [];
    final topProds = rawTopProducts
        .map((e) => TopProductItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawTrend = json['salesTrend'] as List<dynamic>? ?? [];
    final trendList = rawTrend
        .map((e) => SalesTrendItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawRecent = json['recentBills'] as List<dynamic>? ?? [];
    final recentList = rawRecent
        .map((e) => RecentBillItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawServerTs = json['serverTimestamp'];
    DateTime? syncedAt;
    if (rawServerTs is String) {
      syncedAt = DateTime.tryParse(rawServerTs);
    }

    return DashboardMetrics(
      todaySalesPaise: todaySales,
      todayBillsCount:
          (json['todayBillsCount'] ?? json['today_bills_count'] ?? 0) as int,
      yesterdayBillsCount: json['yesterdayBillsCount'] as int? ??
          json['yesterday_bills_count'] as int?,
      topProducts: topProds,
      salesTrend: trendList,
      totalUdhaarOutstandingPaise: udhaar,
      lowStockItemsCount:
          (json['lowStockItemsCount'] ?? json['low_stock_count'] ?? 0) as int,
      recentBills: recentList,
      lastSyncedAt: syncedAt ?? DateTime.now(),
      isOffline: false,
    );
  }

  DashboardMetrics copyWith({
    BigInt? todaySalesPaise,
    int? todayBillsCount,
    int? yesterdayBillsCount,
    List<TopProductItem>? topProducts,
    List<SalesTrendItem>? salesTrend,
    BigInt? totalUdhaarOutstandingPaise,
    int? lowStockItemsCount,
    List<RecentBillItem>? recentBills,
    DateTime? lastSyncedAt,
    bool? isOffline,
  }) {
    return DashboardMetrics(
      todaySalesPaise: todaySalesPaise ?? this.todaySalesPaise,
      todayBillsCount: todayBillsCount ?? this.todayBillsCount,
      yesterdayBillsCount: yesterdayBillsCount ?? this.yesterdayBillsCount,
      topProducts: topProducts ?? this.topProducts,
      salesTrend: salesTrend ?? this.salesTrend,
      totalUdhaarOutstandingPaise:
          totalUdhaarOutstandingPaise ?? this.totalUdhaarOutstandingPaise,
      lowStockItemsCount: lowStockItemsCount ?? this.lowStockItemsCount,
      recentBills: recentBills ?? this.recentBills,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}
