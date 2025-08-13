// models/analytics_models.dart
class SummaryResponse {
  final double totalRevenue;
  final int reservations;
  final double avgRating;
  final int newUsers;

  SummaryResponse({
    required this.totalRevenue,
    required this.reservations,
    required this.avgRating,
    required this.newUsers,
  });

  factory SummaryResponse.fromJson(Map<String, dynamic> j) => SummaryResponse(
    totalRevenue: (j['totalRevenue'] as num?)?.toDouble() ?? 0,
    reservations: (j['reservations'] as num?)?.toInt() ?? 0,
    avgRating: (j['avgRating'] as num?)?.toDouble() ?? 0,
    newUsers: (j['newUsers'] as num?)?.toInt() ?? 0,
  );
}

class RevenueByPeriodResponse {
  final DateTime period;
  final double revenue;

  RevenueByPeriodResponse({required this.period, required this.revenue});

  factory RevenueByPeriodResponse.fromJson(Map<String, dynamic> j) =>
      RevenueByPeriodResponse(
        period: DateTime.parse(j['period'] as String),
        revenue: (j['revenue'] as num).toDouble(),
      );
}

class RevenueByCategoryResponse {
  final int categoryId;
  final String categoryName;
  final double revenue;
  final double share;

  RevenueByCategoryResponse({
    required this.categoryId,
    required this.categoryName,
    required this.revenue,
    required this.share,
  });

  factory RevenueByCategoryResponse.fromJson(Map<String, dynamic> j) =>
      RevenueByCategoryResponse(
        categoryId: (j['categoryId'] as num).toInt(),
        categoryName: j['categoryName'] as String,
        revenue: (j['revenue'] as num).toDouble(),
        share: (j['share'] as num).toDouble(),
      );
}

class TopProductResponse {
  final int menuItemId;
  final String productName;
  final String categoryName;
  final int soldQty;
  final double revenue;

  TopProductResponse({
    required this.menuItemId,
    required this.productName,
    required this.categoryName,
    required this.soldQty,
    required this.revenue,
  });

  factory TopProductResponse.fromJson(Map<String, dynamic> j) =>
      TopProductResponse(
        menuItemId: (j['menuItemId'] as num).toInt(),
        productName: j['productName'] as String,
        categoryName: j['categoryName'] as String,
        soldQty: (j['soldQty'] as num).toInt(),
        revenue: (j['revenue'] as num).toDouble(),
      );
}