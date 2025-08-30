import 'package:flutter/material.dart';
import '../core/order_api_service.dart';
import '../models/order_models.dart';

class OrderProvider with ChangeNotifier {
  final _api = OrderApiService();
  bool _submitting = false;
  String? _error;

  bool get submitting => _submitting;
  String? get error => _error;

  Future<OrderModel?> placeOrder({
    required int userId,
    int? reservationId,
    required List<int> menuItemIds,
  }) async {
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      final req = OrderCreateRequestModel(
        userId: userId,
        reservationId: reservationId,
        menuItemIds: menuItemIds,
      );
      final order = await _api.insert(req.toJson()); // returns OrderModel
      _submitting = false;
      notifyListeners();
      return order;
    } catch (e) {
      _submitting = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
