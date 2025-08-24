import 'package:flutter/material.dart';
import '../models/reservation_model.dart';
import '../core/reservation_api_service.dart';

class ReservationProvider with ChangeNotifier {
  final ReservationApiService _apiService = ReservationApiService();

  List<ReservationModel> _reservations = [];
  bool _isLoading = false;
  String? _error;

  List<ReservationModel> get reservations => _reservations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Now requires userId to filter
  Future<void> fetchMyReservations(int userId) async {
    _setLoading(true);
    try {
      _error = null;
      _reservations = await _apiService.getMyReservations(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Requires userId for POST /api/reservation
  Future<bool> createReservation(Map<String, dynamic> payload, int userId) async {
    return _handleAction(() async {
      final newRes = await _apiService.createReservation(payload, userId);
      _reservations.add(newRes);
    });
  }

  // Requires userId for PUT /api/reservation/{id}
  Future<bool> updateReservation(int id, Map<String, dynamic> payload, int userId) async {
    return _handleAction(() async {
      final updated = await _apiService.updateReservation(id, payload, userId);
      final idx = _reservations.indexWhere((r) => r.id == id);
      if (idx != -1) _reservations[idx] = updated;
    });
  }

  // Cancel via PUT status="Cancelled"
  Future<bool> cancelReservation(int id) async {
    return _handleAction(() async {
      final updated = await _apiService.cancelReservation(id);
      final idx = _reservations.indexWhere((r) => r.id == id);
      if (idx != -1) _reservations[idx] = updated;
    });
  }

  // --- helpers ---
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  Future<bool> _handleAction(Future<void> Function() fn) async {
    _setLoading(true);
    try {
      _error = null;
      await fn();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
