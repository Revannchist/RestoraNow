import 'package:flutter/foundation.dart';
import '../core/restaurant_api_service.dart';
import '../models/restaurant_model.dart';

class RestaurantProvider with ChangeNotifier {
  final _api = RestaurantApiService();

  RestaurantModel? _restaurant;
  bool _isLoading = false;
  String? _error;

  RestaurantModel? get restaurant => _restaurant;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRestaurant() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _restaurant = await _api.getSingle();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
