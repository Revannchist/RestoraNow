import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// AuthProvider manages login and the current JWT token.
class AuthProvider with ChangeNotifier {
  static String? token; // Accessible globally by BaseProvider
  DateTime? expiresAt;

  bool get isAuthenticated => token != null && DateTime.now().isBefore(expiresAt ?? DateTime.now());
  String? _error;
  String? get error => _error;

  Future<bool> login(String email, String password) async {
    final uri = Uri.parse("${dotenv.env['API_URL']}Auth/login");
    
    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
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
}