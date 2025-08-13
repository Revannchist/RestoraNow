import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';
import '../../models/search_result.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  final String _endpoint;

  static final String _baseUrl =
      dotenv.env['API_URL'] ?? 'http://localhost:5294/api/';
  BaseProvider(this._endpoint);

  /*
  late final String _baseUrl;
  
  BaseProvider(this._endpoint) {
    _baseUrl = const String.fromEnvironment(
      "baseUrl",
      defaultValue: "http://localhost:5294/api/",
    );
  }
  */

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
        if (filter != null) ...filter,
        'Page': '$page',
        'PageSize': '$pageSize',
        //'RetrieveAll': 'true',
        if (sortBy != null) 'SortBy': sortBy,
        if (sortBy != null) 'Ascending': ascending.toString(),
      },
    );

    debugPrint(
      "→ [BaseProvider] Fetching page $page with pageSize $pageSize for $_endpoint",
    );
    debugPrint("→ [BaseProvider] Full request URL: $uri");

    final headers = _createHeaders();
    _logRequest("GET", uri);

    final response = await http.get(uri, headers: headers);
    _logResponse(response);

    if (_isValidResponse(response)) {
      final data = jsonDecode(response.body);
      return SearchResult<T>(
        totalCount: data['totalCount'],
        items: List<T>.from(data['items'].map((e) => fromJson(e))),
      );
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<T> getById(int id) async {
    final uri = Uri.parse("$_baseUrl$_endpoint/$id");
    final response = await http.get(uri, headers: _createHeaders());
    _logRequest("GET", uri);
    _logResponse(response);

    if (_isValidResponse(response)) {
      return fromJson(jsonDecode(response.body));
    } else {
      //throw Exception(_extractErrorMessage(response));
      throw response;
    }
  }

  Future<T> insert(dynamic request) async {
    final uri = Uri.parse("$_baseUrl$_endpoint");
    final response = await http.post(
      uri,
      headers: _createHeaders(),
      body: jsonEncode(request),
    );
    _logRequest("POST", uri, body: jsonEncode(request));
    _logResponse(response);

    if (_isValidResponse(response)) {
      return fromJson(jsonDecode(response.body));
    } else {
      //throw Exception(_extractErrorMessage(response));
      throw response;
    }
  }

  Future<T> update(int id, dynamic request) async {
    final uri = Uri.parse("$_baseUrl$_endpoint/$id");
    final response = await http.put(
      uri,
      headers: _createHeaders(),
      body: jsonEncode(request),
    );
    _logRequest("PUT", uri, body: jsonEncode(request));
    _logResponse(response);

    if (_isValidResponse(response)) {
      return fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<void> delete(int id) async {
    final uri = Uri.parse("$_baseUrl$_endpoint/$id");
    final response = await http.delete(uri, headers: _createHeaders());
    _logRequest("DELETE", uri);
    _logResponse(response);

    if (!_isValidResponse(response)) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  // Headers with JWT support
  Map<String, String> _createHeaders() {
    final token = AuthProvider.token; // Make sure token is set after login
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Helpers
  bool _isValidResponse(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('message')) {
        return body['message'];
      }
    } catch (_) {}
    return 'Error ${response.statusCode}: ${response.reasonPhrase}';
  }

  void _logRequest(String method, Uri uri, {String? body}) {
    debugPrint("[$method] $uri");
    if (body != null) debugPrint("Body: $body");
  }

  void _logResponse(http.Response response) {
    debugPrint("Response: ${response.statusCode}");
    debugPrint(response.body);
  }

  //--Analytics
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
    if (_isValidResponse(res)) return jsonDecode(res.body);
    throw Exception(_extractErrorMessage(res));
  }

  /// For parsing a single object
  @protected
  Future<R> getOneCustom<R>(
    String relativePath,
    R Function(Map<String, dynamic>) fromJson, {
    Map<String, String>? query,
  }) async {
    final body = await getJson(relativePath, query: query);
    return fromJson(body as Map<String, dynamic>);
  }

  /// For parsing a list of objects
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