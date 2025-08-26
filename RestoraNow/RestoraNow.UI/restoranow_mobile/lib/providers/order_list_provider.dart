import 'package:flutter/material.dart';
import '../core/order_api_service.dart';
import '../models/order_models.dart';
import '../models/search_result.dart';

enum OrdersView { current, history }

class OrderListProvider with ChangeNotifier {
  final _api = OrderApiService();

  bool _loading = false;
  String? _error;
  List<OrderModel> _all = [];
  int _totalCount = 0;

  bool get isLoading => _loading;
  String? get error => _error;
  int get totalCount => _totalCount;

  List<OrderModel> get currentOrders => _all
      .where(
        (o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.preparing ||
            o.status == OrderStatus.ready,
      )
      .toList();

  List<OrderModel> get pastOrders => _all
      .where(
        (o) =>
            o.status == OrderStatus.completed ||
            o.status == OrderStatus.cancelled,
      )
      .toList();

  Future<void> refreshForUser(int userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final SearchResult<OrderModel> res = await _api.get(
        filter: {'UserId': userId},
        page: 1,
        pageSize: 100, // adjust if needed
        sortBy: 'CreatedAt',
        ascending: false,
      );
      _all = res.items;
      _totalCount = res.totalCount;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
}
