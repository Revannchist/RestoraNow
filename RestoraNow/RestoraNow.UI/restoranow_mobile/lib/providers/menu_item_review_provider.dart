import 'package:flutter/foundation.dart';

import '../core/menu_item_review_api_service.dart';
import '../models/menu_item_review_model.dart';
import '../models/search_result.dart';

class MenuItemReviewProvider with ChangeNotifier {
  final MenuItemReviewApiService _api = MenuItemReviewApiService();

  // Cache by menu item
  final Map<int, List<MenuItemReviewModel>> _byItem = {};
  final Map<int, int> _totalByItem = {};
  final Map<int, bool> _loadingByItem = {};
  final Map<int, String?> _errorByItem = {};

  // -------- Getters --------
  List<MenuItemReviewModel> reviewsFor(int menuItemId) =>
      _byItem[menuItemId] ?? const [];

  int totalFor(int menuItemId) => _totalByItem[menuItemId] ?? 0;

  bool isLoading(int menuItemId) => _loadingByItem[menuItemId] ?? false;

  String? errorFor(int menuItemId) => _errorByItem[menuItemId];

  MenuItemReviewModel? myReviewFor({
    required int menuItemId,
    required int userId,
  }) {
    final list = _byItem[menuItemId];
    if (list == null) return null;
    try {
      return list.firstWhere((r) => r.userId == userId);
    } catch (_) {
      return null;
    }
  }

  double? averageFor(int menuItemId) {
    final list = _byItem[menuItemId];
    if (list == null || list.isEmpty) return null;
    final sum = list.fold<int>(0, (acc, r) => acc + r.rating);
    return sum / list.length;
  }

  // -------- Fetch --------
  Future<void> fetchForMenuItem(
    int menuItemId, {
    int page = 1,
    int pageSize = 20,
    int? minRating,
    int? maxRating,
  }) async {
    _loadingByItem[menuItemId] = true;
    _errorByItem[menuItemId] = null;
    notifyListeners();

    final filter = <String, String>{'MenuItemId': '$menuItemId'};
    if (minRating != null) filter['MinRating'] = '$minRating';
    if (maxRating != null) filter['MaxRating'] = '$maxRating';

    try {
      final SearchResult<MenuItemReviewModel> res = await _api.get(
        filter: filter,
        page: page,
        pageSize: pageSize,
      );

      // Keep newest first by CreatedAt if server isn't already doing it
      final sorted = List<MenuItemReviewModel>.from(res.items)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (page <= 1) {
        _byItem[menuItemId] = sorted;
      } else {
        final current = List<MenuItemReviewModel>.from(
          _byItem[menuItemId] ?? const [],
        );
        final existingIds = current.map((e) => e.id).toSet();
        for (final r in sorted) {
          if (!existingIds.contains(r.id)) current.add(r);
        }
        current.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _byItem[menuItemId] = current;
      }

      _totalByItem[menuItemId] = res.totalCount;
      _loadingByItem[menuItemId] = false;
      notifyListeners();
    } catch (e) {
      _loadingByItem[menuItemId] = false;
      _errorByItem[menuItemId] = e.toString();
      notifyListeners();
    }
  }

  // -------- Create / Update / Delete --------

  Future<MenuItemReviewModel> create(MenuItemReviewRequest payload) async {
    final created = await _api.insert(payload.toJson());

    final list = List<MenuItemReviewModel>.from(
      _byItem[created.menuItemId] ?? const [],
    );
    final sameUserIdx = list.indexWhere((r) => r.userId == created.userId);
    if (sameUserIdx >= 0) {
      list[sameUserIdx] = created;
    } else {
      list.insert(0, created);
      _totalByItem[created.menuItemId] =
          (_totalByItem[created.menuItemId] ?? 0) + 1;
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _byItem[created.menuItemId] = list;
    notifyListeners();
    return created;
  }

  Future<MenuItemReviewModel> update(
    int id,
    MenuItemReviewRequest payload,
  ) async {
    final updated = await _api.update(id, payload.toJson());

    final list = List<MenuItemReviewModel>.from(
      _byItem[updated.menuItemId] ?? const [],
    );
    final idx = list.indexWhere((r) => r.id == id);
    if (idx >= 0) list[idx] = updated;
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _byItem[updated.menuItemId] = list;
    notifyListeners();
    return updated;
  }

  Future<void> delete(int id, int menuItemId) async {
    await _api.delete(id);

    // removeWhere returns void -> compute removed count manually
    final list = List<MenuItemReviewModel>.from(
      _byItem[menuItemId] ?? const [],
    );
    final before = list.length;
    list.removeWhere((r) => r.id == id);
    final removedCount = before - list.length; // int and non-null

    _byItem[menuItemId] = list;

    if (removedCount > 0) {
      final currentTotal = _totalByItem[menuItemId] ?? before;
      _totalByItem[menuItemId] = (currentTotal - removedCount);
    }

    notifyListeners();
  }
}
