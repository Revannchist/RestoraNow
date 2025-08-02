import 'package:flutter/material.dart';
import '../models/menu_item_model.dart';
import '../core/menu_item_api_service.dart';
import '../models/search_result.dart';

class MenuItemProvider with ChangeNotifier {
  final MenuItemApiService _apiService = MenuItemApiService();

  List<MenuItemModel> _items = [];
  bool _isLoading = false;
  String? _error;

  String? _nameFilter;
  int? _categoryIdFilter;
  bool? _isAvailableFilter;
  bool? _isSpecialFilter;

  int _totalCount = 0;
  int _currentPage = 1;
  int _pageSize = 10;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalCount / _pageSize).ceil();

  List<MenuItemModel> get items => _items;
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
    String? name,
    int? categoryId,
    bool? isAvailable,
    bool? isSpecial,
  }) {
    _nameFilter = name;
    _categoryIdFilter = categoryId;
    _isAvailableFilter = isAvailable;
    _isSpecialFilter = isSpecial;
    _currentPage = 1;
    fetchItems();
  }

  Future<void> fetchItems({String? sortBy, bool ascending = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final filter = <String, String>{};

      if (_nameFilter != null && _nameFilter!.isNotEmpty) {
        filter['Name'] = _nameFilter!;
      }
      if (_categoryIdFilter != null) {
        filter['CategoryId'] = _categoryIdFilter.toString();
      }
      if (_isAvailableFilter != null) {
        filter['IsAvailable'] = _isAvailableFilter.toString();
      }
      if (_isSpecialFilter != null) {
        filter['IsSpecialOfTheDay'] = _isSpecialFilter.toString();
      }

      final SearchResult<MenuItemModel> result = await _apiService.get(
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

  Future<MenuItemModel?> createItem(MenuItemModel item) async {
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
    }
  }

  Future<void> updateItem(MenuItemModel item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final MenuItemModel updated = await _apiService.update(
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
