import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../core/restaurant_api_service.dart';

class RestaurantProvider with ChangeNotifier {
  final RestaurantApiService _apiService = RestaurantApiService();

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
      final result = await _apiService.get();
      if (result.items.isNotEmpty) {
        _restaurant = result.items.first;
      } else {
        _restaurant = null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRestaurant(RestaurantModel updatedModel) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _apiService.update(updatedModel.id, updatedModel.toRequestJson());
      _restaurant = updated;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}