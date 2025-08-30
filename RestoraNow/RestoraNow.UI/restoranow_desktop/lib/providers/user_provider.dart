import 'package:flutter/material.dart';
import '../core/user_api_service.dart';
import '../models/user_model.dart';
import '../core/api_exception.dart';
class UserProvider with ChangeNotifier {
  final UserApiService _apiService = UserApiService();
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  String? _nameFilter;
  String? _usernameFilter;
  bool? _isActiveFilter;

  int _totalCount = 0;
  int _currentPage = 1;
  int _pageSize = 10;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalCount / _pageSize).ceil();

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _totalCount;

  void setPage(int page) {
    _currentPage = page;
    fetchUsers();
  }

  Future<void> fetchUsers({String? sortBy, bool ascending = true}) async {
    _isLoading = true;
    _error = null; // clear stale error so UI doesn't show an old toast
    notifyListeners();

    try {
      final result = await _apiService.get(
        filter: {
          if (_nameFilter != null && _nameFilter!.isNotEmpty)
            'Name': _nameFilter!,
          if (_usernameFilter != null && _usernameFilter!.isNotEmpty)
            'Username': _usernameFilter!,
          if (_isActiveFilter != null) 'IsActive': _isActiveFilter.toString(),
        },
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: sortBy,
        ascending: ascending,
      );

      _users = result.items;
      _totalCount = result.totalCount;
    } on ApiException catch (e) {
      // keep raw server message/body; extractServerMessage() can prettify it
      _error = e.message;
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
    } on ApiException catch (e) {
      _error = e.message; // <-- important
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
    } on ApiException catch (e) {
      _error = e.message;
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
    } on ApiException catch (e) {
      _error = e.message; // ✅
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setPageSize(int newSize) {
    _pageSize = newSize;
    _currentPage = 1;
    fetchUsers();
  }

  void setFilters({String? name, String? username, bool? isActive}) {
    _nameFilter = name;
    _usernameFilter = username;
    _isActiveFilter = isActive;
    _currentPage = 1;
    fetchUsers();
  }

  void updateUserImageUrl(int userId, String newImageUrl) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _users[index];
      _users[index] = user.copyWith(imageUrl: newImageUrl);
      notifyListeners();
    }
  }

  void removeUserImage(int userId) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _users[index];
      _users[index] = user.copyWith(imageUrl: null);
      notifyListeners();
    }
  }
}
