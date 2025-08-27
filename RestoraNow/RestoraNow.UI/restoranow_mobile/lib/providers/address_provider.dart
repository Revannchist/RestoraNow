import 'package:flutter/material.dart';
import '../core/address_api_service.dart';
import '../models/address_model.dart';
import '../models/search_result.dart';

class AddressProvider with ChangeNotifier {
  final _api = AddressApiService();

  // List state
  bool _loading = false;
  String? _error;
  List<AddressModel> _items = [];

  // Submit state (create/update/delete/setDefault)
  bool _submitting = false;
  String? _submitError;

  bool get isLoading => _loading;
  String? get error => _error;
  List<AddressModel> get items => _items;

  bool get isSubmitting => _submitting;
  String? get submitError => _submitError;

  AddressModel? get defaultAddress {
    for (final a in _items) {
      if (a.isDefault) return a;
    }
    return null;
  }

  /// Fetch addresses for a specific user
  Future<void> fetchByUser(int userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final SearchResult<AddressModel> res = await _api.get(
        filter: {'UserId': userId},
        page: 1,
        pageSize: 100,
      );
      _items = res.items;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Create new address
  Future<bool> add(AddressModel model) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();
    try {
      await _api.insert(model.toCreateUpdateJson());
      await fetchByUser(model.userId);
      return true;
    } catch (e) {
      _submitError = e.toString();
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  /// Update existing address
  Future<bool> edit(AddressModel model) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();
    try {
      await _api.update(model.id, model.toCreateUpdateJson());
      await fetchByUser(model.userId);
      return true;
    } catch (e) {
      _submitError = e.toString();
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  /// Delete address
  Future<bool> remove(int id, int userId) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();
    try {
      await _api.delete(id);
      await fetchByUser(userId);
      return true;
    } catch (e) {
      _submitError = e.toString();
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  /// Set selected address as default:
  /// 1) unset other defaults for the same user,
  /// 2) set this one to default,
  /// 3) refresh.
  Future<bool> setDefault(AddressModel a) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();

    try {
      // Ensure we have a fresh list to know current defaults
      if (_items.isEmpty) {
        await fetchByUser(a.userId);
      }

      // If already the only default, do nothing
      final currentDefaults =
          _items.where((x) => x.userId == a.userId && x.isDefault).toList();
      final alreadyOnlyDefault =
          a.isDefault && currentDefaults.length == 1 && currentDefaults.first.id == a.id;
      if (alreadyOnlyDefault) {
        return true;
      }

      // 1) unset other defaults
      for (final o in _items) {
        if (o.userId == a.userId && o.id != a.id && o.isDefault) {
          await _api.update(o.id, {
            ...o.toCreateUpdateJson(),
            'isDefault': false,
          });
        }
      }

      // 2) set selected as default (if not already)
      if (!a.isDefault) {
        await _api.update(a.id, {
          ...a.toCreateUpdateJson(),
          'isDefault': true,
        });
      }

      // 3) refresh
      await fetchByUser(a.userId);
      return true;
    } catch (e) {
      _submitError = e.toString();
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
