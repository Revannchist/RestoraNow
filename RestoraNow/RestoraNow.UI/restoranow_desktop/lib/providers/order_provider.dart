// lib/providers/order_provider.dart
import 'package:flutter/material.dart';
import '../core/order_api_service.dart';
import '../models/order_models.dart';
import '../models/search_result.dart';
import '../core/api_exception.dart'; // <-- add

class OrderProvider with ChangeNotifier {
  final OrderApiService _api = OrderApiService();

  List<OrderModel> _items = [];
  bool _isLoading = false;
  String? _error;

  // NEW: keep the last API error to be shown as a snack
  ApiException? _lastApiError;

  // Filters
  int? _userIdFilter;
  OrderStatus? _statusFilter;
  DateTime? _fromDateFilter;
  DateTime? _toDateFilter;

  // Paging
  int _totalCount = 0;
  int _currentPage = 1;
  int _pageSize = 10;

  // Getters
  List<OrderModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalCount / _pageSize).ceil();

  // NEW: one-shot getter that clears after read
  ApiException? consumeApiError() {
    final e = _lastApiError;
    _lastApiError = null;
    return e;
  }

  void setPage(int page) {
    _currentPage = page;
    fetchOrders();
  }

  void setPageSize(int size) {
    _pageSize = size;
    _currentPage = 1;
    fetchOrders();
  }

  void setFilters({
    int? userId,
    OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    _userIdFilter = userId;
    _statusFilter = status;
    _fromDateFilter = fromDate;
    _toDateFilter = toDate;
    _currentPage = 1;
    fetchOrders();
  }

  Future<void> fetchOrders({String? sortBy, bool ascending = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final filter = <String, String>{};
      if (_userIdFilter != null) filter['UserId'] = _userIdFilter.toString();
      if (_statusFilter != null)
        filter['Status'] = orderStatusToString(_statusFilter!);
      if (_fromDateFilter != null)
        filter['FromDate'] = _fromDateFilter!.toUtc().toIso8601String();
      if (_toDateFilter != null)
        filter['ToDate'] = _toDateFilter!.toUtc().toIso8601String();

      final SearchResult<OrderModel> result = await _api.get(
        filter: filter,
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: sortBy,
        ascending: ascending,
      );

      _items = result.items;
      _totalCount = result.totalCount;
    } catch (e) {
      // Store both a human string and a structured ApiException for snacks
      if (e is ApiException) {
        _lastApiError = e;
        _error = e.message;
      } else {
        _lastApiError = ApiException(500, e.toString());
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> createOrder(OrderCreateRequestModel req) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _api.insert(req.toJson());
      _items.add(created);
      return created;
    } catch (e) {
      if (e is ApiException) {
        _lastApiError = e;
        _error = e.message;
      } else {
        _lastApiError = ApiException(500, e.toString());
        _error = e.toString();
      }
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> updateOrder(int id, OrderUpdateRequestModel req) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _api.update(id, req.toJson());
      final i = _items.indexWhere((x) => x.id == id);
      if (i != -1) _items[i] = updated;
      return updated;
    } catch (e) {
      if (e is ApiException) {
        _lastApiError = e;
        _error = e.message;
      } else {
        _lastApiError = ApiException(500, e.toString());
        _error = e.toString();
      }
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> changeStatus(int id, OrderStatus newStatus) async {
    final existing = _items.firstWhere(
      (o) => o.id == id,
      orElse: () => throw StateError('Order $id not loaded in provider'),
    );

    final menuItemIds = buildMenuItemIdsFromItems(existing.orderItems);
    final req = OrderUpdateRequestModel(
      userId: existing.userId,
      reservationId: existing.reservationId,
      status: newStatus,
      menuItemIds: menuItemIds,
    );
    return updateOrder(id, req);
  }

  Future<void> deleteOrder(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.delete(id);
      _items.removeWhere((x) => x.id == id);
    } catch (e) {
      if (e is ApiException) {
        _lastApiError = e;
        _error = e.message;
      } else {
        _lastApiError = ApiException(500, e.toString());
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
