import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  static const _kJwtKey = 'jwt';
  static const _kJwtExpKey = 'jwt_exp';

  /// Kept static so BaseProvider can read it at call time.
  static String? token;
  DateTime? expiresAt;

  bool _restoring = true;
  bool get restoring => _restoring;

  AuthProvider() {
    _restore();
  }

  /// Consider token expired if <30s remain (mobile safety margin).
  bool get isAuthenticated {
    final exp = expiresAt;
    if (token == null || exp == null) return false;
    return DateTime.now().isBefore(exp.subtract(const Duration(seconds: 30)));
  }

  String? _error;
  String? get error => _error;

  // ---- Helpers ----

  Uri _uri(String path) {
    final base = dotenv.env['API_URL'] ?? '';
    final needsSlash = base.isNotEmpty && !base.endsWith('/');
    return Uri.parse('$base${needsSlash ? '/' : ''}$path');
  }

  Map<String, dynamic>? _tryJson(String s) {
    try {
      final d = jsonDecode(s);
      return d is Map<String, dynamic> ? d : null;
    } catch (_) {
      return null;
    }
  }

  String _extractError(Map<String, dynamic>? body, String fallback) {
    if (body == null) return fallback;
    if (body['message'] is String) return body['message'] as String;
    if (body['Message'] is String) return body['Message'] as String;
    final errors = body['errors'] ?? body['Errors'];
    if (errors is Iterable) {
      return errors.map((e) => e.toString()).join('\n');
    }
    return fallback;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_kJwtKey);
      final savedExp = prefs.getString(_kJwtExpKey);
      if (savedToken != null && savedExp != null) {
        final parsedExp = DateTime.tryParse(savedExp);
        if (parsedExp != null) {
          token = savedToken;
          expiresAt = parsedExp;
        }
      }
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  // ---- API ----

  Future<bool> login(String email, String password) async {
    final uri = _uri('Auth/login');
    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        token = data['token'];
        // backend returns ISO string under "expires"
        expiresAt = DateTime.parse(data['expires']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kJwtKey, token!);
        await prefs.setString(_kJwtExpKey, expiresAt!.toIso8601String());

        _error = null;
        notifyListeners();
        return true;
      } else {
        final body = _tryJson(response.body);
        _error = _extractError(body, "Login failed");
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Register a user. Returns true on 200 OK.
  /// Backend response (on success): { "message": "Successfully registered." }
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    final uri = _uri('Auth/register');
    try {
      final payload = {
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "password": password,
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          "phoneNumber": phoneNumber.trim(),
      };

      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        _error = null;
        notifyListeners();
        return true;
      } else {
        final body = _tryJson(res.body);
        _error = _extractError(body, "Registration failed");
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    token = null;
    expiresAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kJwtKey);
    await prefs.remove(_kJwtExpKey);
    notifyListeners();
  }

  // ===== JWT helpers =====

  Map<String, dynamic>? get _payload {
    final t = token;
    if (t == null) return null;
    try {
      final parts = t.split('.');
      if (parts.length != 3) return null;
      String pad(String s) =>
          s.padRight(s.length + (4 - s.length % 4) % 4, '=');
      final jsonStr = utf8.decode(base64Url.decode(pad(parts[1])));
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String? get username =>
      _payload?['unique_name']?.toString() ??
      _payload?['username']?.toString() ??
      _payload?['name']?.toString();

  String? get email =>
      _payload?['email']?.toString() ??
      _payload?['upn']?.toString() ??
      _payload?['preferred_username']?.toString();

  /// Robust userId extraction. Handles common ASP.NET / JWT claim keys.
  int? get userId {
    final p = _payload;
    if (p == null) return null;
    for (final key in const [
      'nameid',
      'sub',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameid',
      'userId',
      'id',
    ]) {
      final raw = p[key];
      if (raw == null) continue;
      final s = raw.toString();
      final n = int.tryParse(s);
      if (n != null) return n;
    }
    return null;
  }
}
