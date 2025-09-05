import 'package:flutter/material.dart';
import '../core/menu_item_api_service.dart';
import '../models/menu_item_model.dart';
import '../models/search_result.dart';

class MenuItemProvider with ChangeNotifier {
  final _api = MenuItemApiService();

  bool _loading = false;
  String? _error;
  List<MenuItemModel> _items = [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<MenuItemModel> get items => _items;

  Future<void> fetchItems({bool onlyAvailable = true}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final SearchResult<MenuItemModel> res = await _api.get(
        filter: onlyAvailable ? {'IsAvailable': true} : null,
        page: 1,
        pageSize: 100, // adjust as needed
      );
      _items = res.items;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update the single image URL for a given menu item (or clear with null).
  /// Call this after successful upload/replace/delete so UI updates instantly.
  void updateItemImage(int itemId, String? url) {
    final i = _items.indexWhere((x) => x.id == itemId);
    if (i == -1) return;

    final m = _items[i];
    _items[i] = MenuItemModel(
      id: m.id,
      name: m.name,
      description: m.description,
      price: m.price,
      isAvailable: m.isAvailable,
      isSpecialOfTheDay: m.isSpecialOfTheDay,
      categoryId: m.categoryId,
      categoryName: m.categoryName,
      averageRating: m.averageRating,
      ratingsCount: m.ratingsCount,
      imageUrl: url, // <- set/clear single image
    );
    notifyListeners();
  }
}
