import 'package:flutter/foundation.dart';
import '../core/menu_item_recommendation_api_service.dart';
import '../models/menu_item_model.dart';

class RecommendationsProvider extends ChangeNotifier {
  final _api = MenuItemRecommendationApiService();

  bool _loading = false;
  String? _error;
  List<MenuItemModel> _items = const [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<MenuItemModel> get items => _items;

  Future<void> load({int take = 10}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _api.fetch(
        take: take,
      ); // token auto-picked from AuthProvider
    } catch (e) {
      _error = e.toString();
      _items = const [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _items = const [];
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
