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
        pageSize: 100,
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

  // Cancel (Pending/Preparing)
  Future<bool> cancelOrderForUser({
    required int userId,
    required OrderModel order,
  }) async {
    try {
      _error = null;
      final updated = await _api.cancelWithPut(current: order, userId: userId);
      _replaceInAll(updated);
      notifyListeners();
      await refreshForUser(userId); // source of truth
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Edit items (Pending/Preparing — enforced in UI)
  Future<OrderModel?> updateOrderItemsForUser({
    required int userId,
    required OrderModel order,
    required Map<int, int> itemQuantities,
  }) async {
    try {
      _error = null;
      final updated = await _api.replaceItemsWithPut(
        current: order,
        userId: userId,
        itemQuantities: itemQuantities,
      );
      _replaceInAll(updated);
      notifyListeners();
      await refreshForUser(userId);
      return updated;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void _replaceInAll(OrderModel updated) {
    final idx = _all.indexWhere((o) => o.id == updated.id);
    if (idx != -1) {
      _all[idx] = updated;
    } else {
      _all.insert(0, updated);
    }
  }
}
