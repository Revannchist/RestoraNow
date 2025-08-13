import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// AuthProvider manages login and the current JWT token.
class AuthProvider with ChangeNotifier {
  static String? token; // Accessible globally by BaseProvider
  DateTime? expiresAt;

  bool get isAuthenticated =>
      token != null && DateTime.now().isBefore(expiresAt ?? DateTime.now());
  String? _error;
  String? get error => _error;

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
        _error = null;
        notifyListeners();
        return true;
      } else {
        final body = jsonDecode(response.body);
        _error = body["message"] ?? "Login failed";
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
    notifyListeners();
  }

  // ===== Add below fields in AuthProvider =====
  Map<String, dynamic>? get _payload {
    if (token == null) return null;
    try {
      final parts = token!.split('.');
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

  int? get userId {
    final raw = _payload?['nameid']?.toString() ?? _payload?['sub']?.toString();
    return raw == null ? null : int.tryParse(raw);
  }

  List<String> get roles {
    final p = _payload;
    if (p == null) return const [];
    final r = p['role'] ?? p['roles'];
    if (r == null) return const [];
    if (r is List) return r.map((e) => e.toString()).toList();
    return [r.toString()];
  }
  // ============================================
}
