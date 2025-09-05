import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/menu_item_model.dart';
import '../providers/base/auth_provider.dart';

class MenuItemRecommendationApiService {
  String _apiBase() {
    final v = (dotenv.env['API_URL'] ?? 'http://10.0.2.2:5294/api/').trim();
    return v.endsWith('/') ? v : '$v/';
  }

  /// GET /MenuItem/recommendations?take=10
  /// If [bearerToken] is null, we fall back to AuthProvider.token.
  Future<List<MenuItemModel>> fetch({
    int take = 10,
    String? bearerToken,
  }) async {
    final uri = Uri.parse('${_apiBase()}MenuItem/recommendations?take=$take');

    final token = (bearerToken != null && bearerToken.isNotEmpty)
        ? bearerToken
        : AuthProvider.token; // <-- fallback to static token

    final headers = <String, String>{
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final resp = await http.get(uri, headers: headers);

    if (resp.statusCode == 401) {
      // Not signed in → return empty so UI can show friendly text
      return const <MenuItemModel>[];
    }
    if (resp.statusCode != 200) {
      throw Exception(
        'Recommendations failed: ${resp.statusCode} ${resp.body}',
      );
    }

    final list = (jsonDecode(resp.body) as List<dynamic>)
        .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }
}
