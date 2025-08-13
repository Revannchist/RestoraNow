import '../providers/base/base_provider.dart';
import '../models/analytics_models.dart';

class AnalyticsApiService extends BaseProvider<SummaryResponse> {
  AnalyticsApiService() : super("Analytics");

  @override
  SummaryResponse fromJson(Map<String, dynamic> json) =>
      SummaryResponse.fromJson(json);

  Map<String, String> _q({
    DateTime? from,
    DateTime? to,
    String? groupBy,
    int? take,
  }) {
    final q = <String, String>{};
    if (from != null) q['from'] = from.toUtc().toIso8601String();
    if (to != null) q['to'] = to.toUtc().toIso8601String();
    if (groupBy != null) q['groupBy'] = groupBy;
    if (take != null) q['take'] = '$take';
    return q;
  }

  Future<SummaryResponse> getSummary({DateTime? from, DateTime? to}) {
    return getOneCustom<SummaryResponse>(
      'Analytics/summary',
      SummaryResponse.fromJson,
      query: _q(from: from, to: to),
    );
  }

  Future<List<RevenueByPeriodResponse>> getRevenueByPeriod({
    DateTime? from,
    DateTime? to,
    String groupBy = 'day',
  }) {
    return getListCustom<RevenueByPeriodResponse>(
      'Analytics/revenue/by-period',
      RevenueByPeriodResponse.fromJson,
      query: _q(from: from, to: to, groupBy: groupBy),
    );
  }

  Future<List<RevenueByCategoryResponse>> getRevenueByCategory({
    DateTime? from,
    DateTime? to,
  }) {
    return getListCustom<RevenueByCategoryResponse>(
      'Analytics/revenue/by-category',
      RevenueByCategoryResponse.fromJson,
      query: _q(from: from, to: to),
    );
  }

  Future<List<TopProductResponse>> getTopProducts({
    DateTime? from,
    DateTime? to,
    int take = 5,
  }) {
    return getListCustom<TopProductResponse>(
      'Analytics/top-products',
      TopProductResponse.fromJson,
      query: _q(from: from, to: to, take: take),
    );
  }
}
