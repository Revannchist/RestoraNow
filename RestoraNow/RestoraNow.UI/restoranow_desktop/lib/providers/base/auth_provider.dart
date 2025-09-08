import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthProvider with ChangeNotifier {
  static String? token; // used by your BaseProvider
  DateTime? expiresAt;

  bool get isAuthenticated =>
      token != null && DateTime.now().isBefore(expiresAt ?? DateTime.now());

  String? _error;
  String? get error => _error;

  // ---- Helpers for role checks ----
  bool hasRole(String role) => rolesSet.contains(role.toLowerCase());

  bool hasAnyRole(Iterable<String> allowed) => rolesSet
      .intersection(allowed.map((e) => e.toLowerCase()).toSet())
      .isNotEmpty;

  bool get isStaffOrAdmin => hasAnyRole(const ['Admin', 'Staff']);

  /// Centralized per-route access check using [routePermissions].
  /// Routes not listed require authentication by default.
  bool canAccessRoute(String route) {
    final allowed = routePermissions[route];
    if (allowed == null) return isAuthenticated;
    return isAuthenticated && hasAnyRole(allowed);
  }

  Future<bool> login(String email, String password) async {
    final uri = Uri.parse("${dotenv.env['API_URL']}Auth/login");

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        token = data['token'];
        expiresAt = DateTime.parse(data['expires']);

        // Decode immediately so UI can check roles before proceeding.
        _decodePayload();

        // Enforce desktop-access rule: only Admin/Staff may use the app.
        if (!hasAnyRole(const ['Admin', 'Staff'])) {
          token = null;
          expiresAt = null;
          _cachedPayload = null;
          _error = 'This app is only for Admin/Staff.';
          notifyListeners();
          return false;
        }

        _error = null;
        notifyListeners();
        return true;
      } else {
        final body = _safeJson(response.body);
        _error = body["message"]?.toString() ?? "Login failed";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void logout() {
    token = null;
    expiresAt = null;
    _cachedPayload = null;
    notifyListeners();
  }

  // ---- JWT payload decoding ----
  Map<String, dynamic>? _cachedPayload;
  Map<String, dynamic>? get _payload => _cachedPayload ?? _decodePayload();

  Map<String, dynamic>? _decodePayload() {
    if (token == null) return _cachedPayload = null;
    try {
      final parts = token!.split('.');
      if (parts.length != 3) return _cachedPayload = null;
      String pad(String s) =>
          s.padRight(s.length + (4 - s.length % 4) % 4, '=');
      final jsonStr = utf8.decode(base64Url.decode(pad(parts[1])));
      return _cachedPayload = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return _cachedPayload = null;
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

  int? get userId {
    final raw = _payload?['nameid']?.toString() ?? _payload?['sub']?.toString();
    return raw == null ? null : int.tryParse(raw);
  }

  /// Collect roles from multiple possible claim keys and normalize.
  List<String> get roles {
    final p = _payload;
    if (p == null) return const [];
    const keys = [
      'role',
      'roles',
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/role',
    ];

    final found = <String>[];
    for (final k in keys) {
      final v = p[k];
      if (v == null) continue;
      if (v is List) {
        found.addAll(v.map((e) => e.toString()));
      } else {
        found.add(v.toString());
      }
    }
    // de-dupe, keep original case
    final seen = <String>{};
    return found.where((r) => seen.add(r)).toList();
  }

  /// Lowercased, unique set of roles.
  Set<String> get rolesSet => roles
      .map((r) => r.trim().toLowerCase())
      .where((r) => r.isNotEmpty)
      .toSet();

  Map<String, dynamic> _safeJson(String body) {
    try {
      final d = jsonDecode(body);
      return d is Map<String, dynamic> ? d : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}

// Central route permissions (single source of truth)
const routePermissions = <String, List<String>>{
  '/home': ['Admin', 'Staff'],
  '/users': ['Admin'], // admin-only
  '/menu': ['Admin', 'Staff'],
  '/restaurant': ['Admin', 'Staff'],
  '/reviews': ['Admin', 'Staff'],
  '/reservations': ['Admin', 'Staff'],
  '/orders': ['Admin', 'Staff'],
  '/profile': ['Admin', 'Staff'],
  // '/login' intentionally omitted
};
