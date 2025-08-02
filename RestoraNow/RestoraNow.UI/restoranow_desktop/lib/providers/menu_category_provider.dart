import 'package:flutter/material.dart';
import '../core/menu_category_api_service.dart';
import '../models/menu_category_model.dart';

class MenuCategoryProvider with ChangeNotifier {
  final MenuCategoryApiService _api = MenuCategoryApiService();
  List<MenuCategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<MenuCategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCategories({bool onlyActive = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.get(
        filter: onlyActive ? {'IsActive': 'true'} : null,
        pageSize: 100, // Fetch a large enough list
      );
      _categories = result.items;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  MenuCategoryModel? getById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
