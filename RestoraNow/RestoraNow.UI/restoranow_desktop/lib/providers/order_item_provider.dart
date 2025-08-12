import 'package:flutter/material.dart';
import '../core/order_item_api_service.dart';
import '../models/order_item_model.dart';
import '../models/search_result.dart';

class OrderItemProvider with ChangeNotifier {
  final OrderItemApiService _api = OrderItemApiService();

  List<OrderItemModel> _items = [];
  bool _isLoading = false;
  String? _error;

  int? _orderIdFilter;
  int? _menuItemIdFilter;

  int _totalCount = 0;
  int _currentPage = 1;
  int _pageSize = 10;

  // Getters
  List<OrderItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalCount / _pageSize).ceil();

  // Paging
  void setPage(int page) {
    _currentPage = page;
    fetchItems();
  }

  void setPageSize(int size) {
    _pageSize = size;
    _currentPage = 1;
    fetchItems();
  }

  // Filters
  void setFilters({int? orderId, int? menuItemId}) {
    _orderIdFilter = orderId;
    _menuItemIdFilter = menuItemId;
    _currentPage = 1;
    fetchItems();
  }

  // Fetch
  Future<void> fetchItems({String? sortBy, bool ascending = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final filter = <String, String>{};
      if (_orderIdFilter != null) filter['OrderId'] = _orderIdFilter.toString();
      if (_menuItemIdFilter != null) filter['MenuItemId'] = _menuItemIdFilter.toString();

      final SearchResult<OrderItemModel> result = await _api.get(
        filter: filter,
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: sortBy,
        ascending: ascending,
      );

      _items = result.items;
      _totalCount = result.totalCount;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create
  Future<OrderItemModel?> createItem(OrderItemModel item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _api.insert(item.toRequestJson());
      _items.add(created);
      return created;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update
  Future<void> updateItem(OrderItemModel item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _api.update(item.id, item.toRequestJson());
      final idx = _items.indexWhere((x) => x.id == item.id);
      if (idx != -1) _items[idx] = updated;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete
  Future<void> deleteItem(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.delete(id);
      _items.removeWhere((x) => x.id == id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Convenience: load by a specific orderId
  Future<void> fetchByOrder(int orderId) async {
    setFilters(orderId: orderId);
  }
}
