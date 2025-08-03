import 'package:flutter/material.dart';
import '../models/table_model.dart';
import '../core/table_api_service.dart';
import '../models/search_result.dart';

class TableProvider with ChangeNotifier {
  final TableApiService _apiService = TableApiService();

  List<TableModel> _items = [];
  bool _isLoading = false;
  String? _error;

  int? _restaurantIdFilter;
  int? _capacityFilter;
  bool? _isAvailableFilter;

  int _totalCount = 0;
  int _currentPage = 1;
  int _pageSize = 10;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalCount / _pageSize).ceil();

  List<TableModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _totalCount;

  void setPage(int page) {
    _currentPage = page;
    fetchItems();
  }

  void setPageSize(int size) {
    _pageSize = size;
    _currentPage = 1;
    fetchItems();
  }

  void setFilters({
    int? restaurantId,
    int? capacity,
    bool? isAvailable,
  }) {
    _restaurantIdFilter = restaurantId;
    _capacityFilter = capacity;
    _isAvailableFilter = isAvailable;
    _currentPage = 1;
    fetchItems();
  }

  Future<void> fetchItems({String? sortBy, bool ascending = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final filter = <String, String>{};

      if (_restaurantIdFilter != null) {
        filter['RestaurantId'] = _restaurantIdFilter.toString();
      }
      if (_capacityFilter != null) {
        filter['Capacity'] = _capacityFilter.toString();
      }
      if (_isAvailableFilter != null) {
        filter['IsAvailable'] = _isAvailableFilter.toString();
      }

      final SearchResult<TableModel> result = await _apiService.get(
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

  Future<TableModel?> createItem(TableModel item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _apiService.insert(item.toRequestJson());
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

  Future<void> updateItem(TableModel item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final TableModel updated = await _apiService.update(
        item.id,
        item.toRequestJson(),
      );
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) _items[index] = updated;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteItem(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete(id);
      _items.removeWhere((i) => i.id == id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}