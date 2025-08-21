import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';
import '../../models/search_result.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/api_exception.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  final String _endpoint;

  static final String _baseUrl =
      dotenv.env['API_URL'] ?? 'http://localhost:5294/api/';
  BaseProvider(this._endpoint);

  T fromJson(Map<String, dynamic> json);

  Future<SearchResult<T>> get({
    Map<String, dynamic>? filter,
    int page = 1,
    int pageSize = 10,
    String? sortBy,
    bool ascending = true,
  }) async {
    final uri = Uri.parse("$_baseUrl$_endpoint").replace(
      queryParameters: {
        if (filter != null) ...filter.map((k, v) => MapEntry(k, '$v')),
        'Page': '$page',
        'PageSize': '$pageSize',
        if (sortBy != null) 'SortBy': sortBy,
        if (sortBy != null) 'Ascending': ascending.toString(),
      },
    );

    _logRequest("GET", uri);
    final res = await http.get(uri, headers: _createHeaders());
    _logResponse(res);

    if (_isSuccess(res.statusCode)) {
      final data = _safeJson(res.body);
      return SearchResult<T>(
        totalCount: data['totalCount'] ?? 0,
        items: List<T>.from((data['items'] as List).map((e) => fromJson(e))),
      );
    }
    _throwApi(res);
  }

  Future<T> getById(int id) async {
    final uri = Uri.parse("$_baseUrl$_endpoint/$id");
    _logRequest("GET", uri);
    final res = await http.get(uri, headers: _createHeaders());
    _logResponse(res);

    if (_isSuccess(res.statusCode)) {
      return fromJson(_safeJson(res.body));
    }
    _throwApi(res);
  }

  Future<T> insert(dynamic request) async {
    final uri = Uri.parse("$_baseUrl$_endpoint");
    final body = jsonEncode(request);
    _logRequest("POST", uri, body: body);
    final res = await http.post(uri, headers: _createHeaders(), body: body);
    _logResponse(res);

    if (_isSuccess(res.statusCode)) {
      return fromJson(_safeJson(res.body));
    }
    _throwApi(res);
  }

  Future<T> update(int id, dynamic request) async {
    final uri = Uri.parse("$_baseUrl$_endpoint/$id");
    final body = jsonEncode(request);
    _logRequest("PUT", uri, body: body);
    final res = await http.put(uri, headers: _createHeaders(), body: body);
    _logResponse(res);

    if (_isSuccess(res.statusCode)) {
      return fromJson(_safeJson(res.body));
    }
    _throwApi(res);
  }

  Future<void> delete(int id) async {
    final uri = Uri.parse("$_baseUrl$_endpoint/$id");
    _logRequest("DELETE", uri);
    final res = await http.delete(uri, headers: _createHeaders());
    _logResponse(res);

    if (!_isSuccess(res.statusCode)) {
      _throwApi(res);
    }
  }

  // --------------------- Headers ---------------------

  Map<String, String> _createHeaders() {
    final token = AuthProvider.token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --------------------- Error handling ---------------------

  bool _isSuccess(int code) => code >= 200 && code < 300;

  Never _throwApi(http.Response res) {
    final message = _extractErrorMessage(res);
    throw ApiException(res.statusCode, message);
  }

  //middleware returns either:
  // - { "message": "..." }
  // - { "errors": { email:[], phone:[], general:[] } }
  String _extractErrorMessage(http.Response res) {
    try {
      final body = jsonDecode(res.body);

      if (body is Map) {
        // Preferred: simple "message"
        final msg = body['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg;

        // Validation block
        final errors = body['errors'];
        if (errors is Map) {
          // Flatten & pick first non-empty string
          for (final entry in errors.entries) {
            final list = entry.value;
            if (list is List) {
              for (final item in list) {
                if (item is String && item.trim().isNotEmpty) {
                  return item;
                }
              }
            }
          }
          // Fallback if arrays exist but empty
          return 'Validation failed.';
        }
      }

      // Body is non-empty but not in known shape
      if (res.body.isNotEmpty) return res.body;
    } catch (_) {
      // Not JSON or parse failed
    }

    return 'Error ${res.statusCode}: ${res.reasonPhrase ?? 'Request failed'}';
  }

  Map<String, dynamic> _safeJson(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException(500, 'Unexpected response shape.');
  }

  // --------------------- Logging ---------------------

  void _logRequest(String method, Uri uri, {String? body}) {
    debugPrint("[$method] $uri");
    if (body != null) debugPrint("Body: $body");
  }

  void _logResponse(http.Response response) {
    debugPrint("Response: ${response.statusCode}");
    debugPrint(response.body);
  }

  // --------------------- Extra helpers ---------------------

  @protected
  Uri buildApiUri(String relativePath, {Map<String, String>? query}) {
    final base = _baseUrl.endsWith('/') ? _baseUrl : '$_baseUrl/';
    final path = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  @protected
  Future<dynamic> getJson(
    String relativePath, {
    Map<String, String>? query,
  }) async {
    final uri = buildApiUri(relativePath, query: query);
    _logRequest("GET", uri);
    final res = await http.get(uri, headers: _createHeaders());
    _logResponse(res);
    if (_isSuccess(res.statusCode)) return jsonDecode(res.body);
    _throwApi(res);
  }

  @protected
  Future<R> getOneCustom<R>(
    String relativePath,
    R Function(Map<String, dynamic>) fromJson, {
    Map<String, String>? query,
  }) async {
    final body = await getJson(relativePath, query: query);
    return fromJson(body as Map<String, dynamic>);
  }

  @protected
  Future<List<R>> getListCustom<R>(
    String relativePath,
    R Function(Map<String, dynamic>) fromJson, {
    Map<String, String>? query,
  }) async {
    final body = await getJson(relativePath, query: query);
    final list = (body as List).cast<Map<String, dynamic>>();
    return list.map(fromJson).toList();
  }
}
