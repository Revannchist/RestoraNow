import 'package:flutter/foundation.dart';

import '../core/restaurant_review_api_service.dart';
import '../models/restaurant_review_model.dart.dart';
import '../models/search_result.dart';

class RestaurantReviewProvider with ChangeNotifier {
  final _api = RestaurantReviewApiService();

  // State
  bool _isLoading = false;
  bool _submitting = false;
  String? _error;

  List<RestaurantReviewModel> _reviews = <RestaurantReviewModel>[];
  int _totalCount = 0;

  // Getters
  bool get isLoading => _isLoading;
  bool get submitting => _submitting;
  String? get error => _error;

  List<RestaurantReviewModel> get reviews => List.unmodifiable(_reviews);
  int get totalCount => _totalCount;

  double get averageRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<int>(0, (s, r) => s + r.rating);
    return sum / _reviews.length;
  }

  RestaurantReviewModel? myReviewFor(int userId) {
    try {
      return _reviews.firstWhere((r) => r.userId == userId);
    } catch (_) {
      return null;
    }
  }

  // Actions

  Future<void> fetchForRestaurant(
    int restaurantId, {
    int page = 1,
    int pageSize = 50,
    int? minRating,
    int? maxRating,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final SearchResult<RestaurantReviewModel> res = await _api.get(
        filter: {
          'RestaurantId': '$restaurantId',
          if (minRating != null) 'MinRating': '$minRating',
          if (maxRating != null) 'MaxRating': '$maxRating',
        },
        page: page,
        pageSize: pageSize,
        sortBy: 'CreatedAt',
        ascending: false,
      );

      _reviews = res.items;
      _totalCount = res.totalCount;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createReview({
    required int userId,
    required int restaurantId,
    required int rating, // 1..5
    String? comment,
  }) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _api.insert({
        'userId': userId,
        'restaurantId': restaurantId,
        'rating': rating,
        'comment': comment,
      });

      // Upsert locally (replace if same user already has a review)
      final idx = _reviews.indexWhere((r) => r.id == created.id);
      if (idx >= 0) {
        _reviews[idx] = created;
      } else {
        // If your backend allows only one review per user/restaurant,
        // replace any previous by same user.
        final oldIdx = _reviews.indexWhere(
          (r) => r.userId == userId && r.restaurantId == restaurantId,
        );
        if (oldIdx >= 0) {
          _reviews[oldIdx] = created;
        } else {
          _reviews.insert(0, created);
          _totalCount += 1;
        }
      }

      _submitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReview({
    required int id,
    required int userId,
    required int restaurantId,
    required int rating,
    String? comment,
  }) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _api.update(id, {
        'userId': userId,
        'restaurantId': restaurantId,
        'rating': rating,
        'comment': comment,
      });

      final idx = _reviews.indexWhere((r) => r.id == id);
      if (idx >= 0) _reviews[idx] = updated;

      _submitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReview(int id) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      await _api.delete(id);
      final idx = _reviews.indexWhere((r) => r.id == id);
      if (idx >= 0) {
        _reviews.removeAt(idx);
        _totalCount = _totalCount > 0 ? _totalCount - 1 : 0;
      }
      _submitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Convenience: clear state (e.g., on logout).
  void reset() {
    _isLoading = false;
    _submitting = false;
    _error = null;
    _reviews = <RestaurantReviewModel>[];
    _totalCount = 0;
    notifyListeners();
  }
}
