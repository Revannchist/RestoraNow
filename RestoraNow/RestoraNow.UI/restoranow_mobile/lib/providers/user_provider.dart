import 'package:flutter/material.dart';
import '../core/user_api_service.dart';
import '../models/user_models.dart'; // contains MeModel & (optionally) UserModel

class UserProvider with ChangeNotifier {
  final UserApiService _apiService = UserApiService();

  MeModel? _currentUser; // <-- use MeModel, not UserModel
  bool _isLoading = false;
  String? _error;

  MeModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMe() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _apiService.getMe();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMe(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _apiService.updateMe(payload);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _apiService.changePassword(currentPassword, newPassword);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeEmail(String currentPassword, String newEmail) async {
    try {
      await _apiService.changeEmail(
        newEmail: newEmail, // <-- named params
        currentPassword: currentPassword, // <-- named params
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
