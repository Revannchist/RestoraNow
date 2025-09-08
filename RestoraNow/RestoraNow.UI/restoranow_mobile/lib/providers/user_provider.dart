import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../core/user_api_service.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final UserApiService _apiService = UserApiService();

  MeModel? _currentUser;
  bool _isLoading = false;
  bool _imageBusy = false;
  int _avatarVersion = 0; // increments after add/remove to bust caches
  String? _error;

  Uint8List? _avatarPreview; // optimistic preview before API confirms

  MeModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get imageBusy => _imageBusy;
  String? get error => _error;

  /// Expose for identity keys in UI
  int get avatarVersion => _avatarVersion;

  /// If preview is set, show it. Otherwise decode data URI (if used).
  Uint8List? get avatarBytes {
    if (_avatarPreview != null) return _avatarPreview;
    final raw = _currentUser?.imageUrl;
    if (raw == null || !raw.startsWith('data:image/')) return null;
    final comma = raw.indexOf(',');
    if (comma < 0) return null;
    try {
      final b64 = raw.substring(comma + 1);
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  /// Returns full URL with cache-busting if network-based.
  String? get avatarUrl {
    final raw = _currentUser?.imageUrl;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('data:image/')) return raw;
    final abs = _resolveUrl(raw);
    if (abs == null) return null;
    return _withCacheBust(abs, _avatarVersion);
  }

  // ----- Public API -----

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

  Future<bool> changePassword(String currentPassword, String newPassword) async {
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
      await _apiService.changeEmail(newEmail: newEmail, currentPassword: currentPassword);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Upsert by URL (or data URI). Optionally pass previewBytes to show instantly.
  Future<bool> upsertMyImageUrl(String url, {Uint8List? previewBytes}) async {
    _imageBusy = true;
    _error = null;
    if (previewBytes != null) _avatarPreview = previewBytes; // optimistic
    notifyListeners();

    try {
      await _apiService.upsertMyImageUrl(url);
      _currentUser = await _apiService.getMe();
      _avatarVersion++;        // << force new identity for network images
      _avatarPreview = null;   // clear optimistic after refetch
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _avatarPreview = null;
      notifyListeners();
      return false;
    } finally {
      _imageBusy = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMyImage() async {
    _imageBusy = true;
    _error = null;
    notifyListeners();
    try {
      await _apiService.deleteMyImage();
      _currentUser = await _apiService.getMe();
      _avatarVersion++;        // << force new identity
      _avatarPreview = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _imageBusy = false;
      notifyListeners();
    }
  }

  // ----- Helpers -----

  String? _resolveUrl(String? u) {
    if (u == null || u.isEmpty) return null;
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    final base = dotenv.env['FILE_BASE_URL'] ?? dotenv.env['API_URL'];
    if (base == null || base.isEmpty) return u;
    final left = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final right = u.startsWith('/') ? u.substring(1) : u;
    return '$left/$right';
  }

  String _withCacheBust(String url, int v) {
    final uri = Uri.parse(url);
    final qp = Map<String, String>.from(uri.queryParameters)..['v'] = '$v';
    return uri.replace(queryParameters: qp).toString();
  }
}
