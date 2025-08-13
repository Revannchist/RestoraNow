import 'package:flutter/material.dart';
import '../core/analytics_api_service.dart';
import '../models/analytics_models.dart';

class AnalyticsProvider with ChangeNotifier {
  final AnalyticsApiService _api = AnalyticsApiService();

  SummaryResponse? _summary;
  List<RevenueByPeriodResponse> _revByPeriod = [];
  List<RevenueByCategoryResponse> _revByCategory = [];
  List<TopProductResponse> _topProducts = [];

  bool _isLoading = false;
  String? _error;

  DateTime? _from;
  DateTime? _to;
  String _groupBy = 'day';
  int _topTake = 5;

  // Getters
  SummaryResponse? get summary => _summary;
  List<RevenueByPeriodResponse> get revByPeriod => _revByPeriod;
  List<RevenueByCategoryResponse> get revByCategory => _revByCategory;
  List<TopProductResponse> get topProducts => _topProducts;

  bool get isLoading => _isLoading;
  String? get error => _error;

  DateTime? get from => _from;
  DateTime? get to => _to;
  String get groupBy => _groupBy;
  int get topTake => _topTake;

  Future<void> fetchAll() async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      // include the whole selected end date
      final toInclusive = _to == null
          ? null
          : DateTime(_to!.year, _to!.month, _to!.day, 23, 59, 59, 999);

      _summary = await _api.getSummary(from: _from, to: toInclusive);
      _revByPeriod = await _api.getRevenueByPeriod(
        from: _from, to: toInclusive, groupBy: _groupBy,
      );
      _revByCategory = await _api.getRevenueByCategory(from: _from, to: toInclusive);
      _topProducts = await _api.getTopProducts(from: _from, to: toInclusive, take: _topTake);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  // Mutators (same UX as your user provider)
  void setRange({DateTime? from, DateTime? to}) {
    _from = from; _to = to; fetchAll();
  }
  void setGroupBy(String v) { _groupBy = v; fetchAll(); }
  void setTopTake(int v) { _topTake = v; fetchAll(); }
}
