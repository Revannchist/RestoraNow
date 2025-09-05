import 'package:flutter/material.dart';

import '../core/menu_item_review_api_service.dart';
import '../models/menu_item_review_model.dart';
import '../models/search_result.dart';

class MenuItemReviewProvider with ChangeNotifier {
  final MenuItemReviewApiService _apiService = MenuItemReviewApiService();

  List<MenuItemReviewModel> _items = [];
  bool _isLoading = false;
  String? _error;

  int? _userIdFilter;
  int? _menuItemIdFilter;
  int? _minRatingFilter;
  int? _maxRatingFilter;

  int _totalCount = 0;
  int _currentPage = 1;
  int _pageSize = 10;

  // Getters
  List<MenuItemReviewModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get totalPages => (_totalCount / _pageSize).ceil();

  // Pagination
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
  void setFilters({
    int? userId,
    int? menuItemId,
    int? minRating,
    int? maxRating,
  }) {
    _userIdFilter = userId;
    _menuItemIdFilter = menuItemId;
    _minRatingFilter = minRating;
    _maxRatingFilter = maxRating;
    _currentPage = 1;
    fetchItems();
  }

  Future<void> refresh() => fetchItems();

  // Fetch
  Future<void> fetchItems({String? sortBy, bool ascending = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final filter = <String, String>{};
      if (_userIdFilter != null) filter['UserId'] = _userIdFilter.toString();
      if (_menuItemIdFilter != null) {
        filter['MenuItemId'] = _menuItemIdFilter.toString();
      }
      if (_minRatingFilter != null) {
        filter['MinRating'] = _minRatingFilter.toString();
      }
      if (_maxRatingFilter != null) {
        filter['MaxRating'] = _maxRatingFilter.toString();
      }

      final SearchResult<MenuItemReviewModel> res = await _apiService.get(
        filter: filter,
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: sortBy,
        ascending: ascending,
      );

      _items = res.items;
      _totalCount = res.totalCount;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create
  Future<MenuItemReviewModel?> createItem(MenuItemReviewModel item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _apiService.insert(item.toRequestJson());
      _items.add(created);
      _totalCount += 1;
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
  Future<void> updateItem(MenuItemReviewModel item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _apiService.update(item.id, item.toRequestJson());
      final i = _items.indexWhere((x) => x.id == item.id);
      if (i != -1) _items[i] = updated;
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
      await _apiService.delete(id);
      _items.removeWhere((x) => x.id == id);
      if (_totalCount > 0) _totalCount -= 1;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
