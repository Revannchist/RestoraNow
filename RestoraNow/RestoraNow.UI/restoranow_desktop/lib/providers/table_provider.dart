import 'package:flutter/material.dart';

import '../models/table_model.dart';
import '../models/search_result.dart';
import '../core/table_api_service.dart';
import '../../core/api_exception.dart'; // <-- small class: ApiException(int statusCode, String message)

class TableProvider with ChangeNotifier {
  final TableApiService _apiService = TableApiService();

  // ---- state ---------------------------------------------------------------
  List<TableModel> _items = [];
  bool _isLoading = false;
  String? _error;

  int? _restaurantIdFilter;
  int? _capacityFilter;
  bool? _isAvailableFilter;

  int _totalCount = 0;
  int _currentPage = 1;
  int _pageSize = 10;

  // ---- getters -------------------------------------------------------------
  List<TableModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get totalPages => (_totalCount / _pageSize).ceil();

  // ---- paging / filters ----------------------------------------------------
  void setPage(int page) {
    _currentPage = page;
    fetchItems();
  }

  void setPageSize(int size) {
    _pageSize = size;
    _currentPage = 1;
    fetchItems();
  }

  void setFilters({int? restaurantId, int? capacity, bool? isAvailable}) {
    _restaurantIdFilter = restaurantId;
    _capacityFilter = capacity;
    _isAvailableFilter = isAvailable;
    _currentPage = 1;
    fetchItems();
  }

  // ---- queries -------------------------------------------------------------
  Future<void> fetchItems({String? sortBy, bool ascending = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final filter = <String, String>{};
      if (_restaurantIdFilter != null)
        filter['RestaurantId'] = _restaurantIdFilter.toString();
      if (_capacityFilter != null)
        filter['Capacity'] = _capacityFilter.toString();
      if (_isAvailableFilter != null)
        filter['IsAvailable'] = _isAvailableFilter.toString();

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
      // Keep list screens resilient; show an inline error if you want.
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TableModel?> createItem(TableModel item) async {
    // no _isLoading toggles here; the dialog controls its own spinner
    try {
      final created = await _apiService.insert(item.toRequestJson());
      _items.insert(0, created);
      _totalCount++;
      notifyListeners(); // only on success
      return created;
    } on ApiException {
      rethrow; // let the dialog show the SnackBar
    } catch (_) {
      rethrow;
    }
  }

  Future<void> updateItem(TableModel item) async {
    try {
      final updated = await _apiService.update(item.id, item.toRequestJson());
      final i = _items.indexWhere((t) => t.id == item.id);
      if (i != -1) {
        _items[i] = updated;
        notifyListeners(); // only on success
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _apiService.delete(id);
      _items.removeWhere((t) => t.id == id);
      if (_totalCount > 0) _totalCount--;
      notifyListeners(); // only on success
    } on ApiException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }
}
