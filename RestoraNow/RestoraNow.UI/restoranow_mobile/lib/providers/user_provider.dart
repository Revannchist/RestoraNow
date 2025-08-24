// lib/providers/user_provider.dart
import 'dart:io';
import 'dart:convert';           // <-- add
import 'dart:typed_data';        // <-- add
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // optional if you resolve relative URLs
import '../core/user_api_service.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final UserApiService _apiService = UserApiService();

  MeModel? _currentUser;
  bool _isLoading = false;
  bool _imageBusy = false;
  int _avatarVersion = 0; // for cache-busting (network URLs only)
  String? _error;

  MeModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get imageBusy => _imageBusy;
  String? get error => _error;

  /// If imageUrl is a data URI, return raw (no cache-bust).
  /// If it's http(s), resolve + add ?v= for cache-busting.
  String? get avatarUrl {
    final raw = _currentUser?.imageUrl;
    if (raw == null || raw.isEmpty) return null;

    // data URI? leave as-is; UI will use avatarBytes
    if (raw.startsWith('data:image/')) return raw;

    // if you store relative paths, resolve with .env base
    final abs = _resolveUrl(raw);
    if (abs == null) return null;

    return _withCacheBust(abs, _avatarVersion);
  }

  /// Bytes for data URI images. UI will use Image.memory when this is non-null.
  Uint8List? get avatarBytes {
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

  Future<void> fetchMe() async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      _currentUser = await _apiService.getMe();
      // debug:
      // print('raw imageUrl=${_currentUser?.imageUrl} | avatarUrl=$avatarUrl | avatarBytes=${avatarBytes?.length}');
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<bool> updateMe(Map<String, dynamic> payload) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      _currentUser = await _apiService.updateMe(payload);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      await _apiService.changePassword(currentPassword, newPassword);
      _error = null; notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString(); notifyListeners();
      return false;
    }
  }

  Future<bool> changeEmail(String currentPassword, String newEmail) async {
    try {
      await _apiService.changeEmail(newEmail: newEmail, currentPassword: currentPassword);
      _error = null; notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString(); notifyListeners();
      return false;
    }
  }

  Future<bool> uploadMyImageFile(File file) async {
    _imageBusy = true; _error = null; notifyListeners();
    try {
      _currentUser = await _apiService.uploadMyImageFile(file);
      _avatarVersion++; // only affects network URLs
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _imageBusy = false; notifyListeners();
    }
  }

  Future<bool> upsertMyImageUrl(String url) async {
    _imageBusy = true; _error = null; notifyListeners();
    try {
      _currentUser = await _apiService.upsertMyImageUrl(url);
      _avatarVersion++;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _imageBusy = false; notifyListeners();
    }
  }

  Future<bool> deleteMyImage() async {
    _imageBusy = true; _error = null; notifyListeners();
    try {
      await _apiService.deleteMyImage();
      _currentUser = await _apiService.getMe();
      _avatarVersion++;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _imageBusy = false; notifyListeners();
    }
  }

  // -------- optional helpers for relative URLs --------
  String? _resolveUrl(String? u) {
    if (u == null || u.isEmpty) return null;
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    final base = dotenv.env['FILE_BASE_URL'] ?? dotenv.env['API_BASE_URL'];
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
