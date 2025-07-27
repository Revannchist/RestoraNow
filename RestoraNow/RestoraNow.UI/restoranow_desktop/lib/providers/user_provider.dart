import 'package:flutter/material.dart';
import '../core/user_api_service.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final UserApiService _apiService = UserApiService();
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  int _totalCount = 0;

  int _currentPage = 1;
  int _pageSize = 10;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalCount / _pageSize).ceil();

  void setPage(int page) {
    _currentPage = page;
    fetchUsers(page: page, pageSize: _pageSize);
  }

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _totalCount;

  Future<void> fetchUsers({
    String? name,
    String? username,
    bool? isActive,
    int page = 1,
    int pageSize = 10,
    String? sortBy,
    bool ascending = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.get(
        filter: {
          if (name != null) 'Name': name,
          if (username != null) 'Username': username,
          if (isActive != null) 'IsActive': isActive.toString(),
        },
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        ascending: ascending,
      );

      _users = result.items;
      _totalCount = result.totalCount;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUser(UserModel user, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _apiService.insert({
        'firstName': user.firstName,
        'lastName': user.lastName,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'isActive': user.isActive,
        'roles': user.roles,
        'password': password,
      });
      _users.add(created);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(UserModel user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _apiService.update(user.id, {
        'firstName': user.firstName,
        'lastName': user.lastName,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'isActive': user.isActive,
        'roles': user.roles,
        if (user.password != null) 'password': user.password,
      });

      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = updated;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete(id);
      _users.removeWhere((u) => u.id == id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
