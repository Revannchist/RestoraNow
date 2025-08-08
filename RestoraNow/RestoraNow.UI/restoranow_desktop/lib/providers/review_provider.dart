import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../core/review_api_service.dart';
import '../models/search_result.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewApiService _apiService = ReviewApiService();

  List<ReviewModel> _items = [];
  bool _isLoading = false;
  String? _error;

  int? _userIdFilter;
  int? _restaurantIdFilter;
  int? _minRatingFilter;
  int? _maxRatingFilter;

  int _totalCount = 0;
  int _currentPage = 1;
  int _pageSize = 10;

  // Getters
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalCount / _pageSize).ceil();

  List<ReviewModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _totalCount;

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

  // Filtering
  void setFilters({
    int? userId,
    int? restaurantId,
    int? minRating,
    int? maxRating,
  }) {
    _userIdFilter = userId;
    _restaurantIdFilter = restaurantId;
    _minRatingFilter = minRating;
    _maxRatingFilter = maxRating;
    _currentPage = 1;
    fetchItems();
  }

  // Fetch Reviews
  Future<void> fetchItems({String? sortBy, bool ascending = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final filter = <String, String>{};

      if (_userIdFilter != null) {
        filter['UserId'] = _userIdFilter.toString();
      }
      if (_restaurantIdFilter != null) {
        filter['RestaurantId'] = _restaurantIdFilter.toString();
      }
      if (_minRatingFilter != null) {
        filter['MinRating'] = _minRatingFilter.toString();
      }
      if (_maxRatingFilter != null) {
        filter['MaxRating'] = _maxRatingFilter.toString();
      }

      final SearchResult<ReviewModel> result = await _apiService.get(
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
  Future<ReviewModel?> createItem(ReviewModel item) async {
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

  // Update
  Future<void> updateItem(ReviewModel item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _apiService.update(item.id, item.toRequestJson());
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) _items[index] = updated;
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
      _items.removeWhere((i) => i.id == id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
