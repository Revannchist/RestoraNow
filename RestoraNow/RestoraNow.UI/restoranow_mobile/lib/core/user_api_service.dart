import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../providers/base/base_provider.dart';
import '../providers/base/auth_provider.dart';
import '../core/api_exception.dart';
import '../models/user_model.dart';

class UserApiService extends BaseProvider<UserModel> {
  UserApiService() : super("User");

  @override
  UserModel fromJson(Map<String, dynamic> json) => UserModel.fromJson(json);

  // ---------- Headers / helpers ----------

  Map<String, String> _headersJson() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (AuthProvider.token != null)
          'Authorization': 'Bearer ${AuthProvider.token}',
      };

  Map<String, String> _headersAuthOnly() => {
        'Accept': 'application/json',
        if (AuthProvider.token != null)
          'Authorization': 'Bearer ${AuthProvider.token}',
      };

  Future<http.Response> _send(Future<http.Response> Function() fn) async {
    try {
      return await fn().timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw ApiException(408, 'Request timed out. Check your network.');
    } on SocketException catch (e) {
      throw ApiException(503, 'Network error: ${e.message}');
    } catch (e) {
      throw ApiException(500, 'Unexpected error: $e');
    }
  }

  dynamic _handleJson(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    _throwApi(res);
  }

  void _handleNoContentOrOk(http.Response res) {
    if (res.statusCode == 204 ||
        (res.statusCode >= 200 && res.statusCode < 300)) {
      return;
    }
    _throwApi(res);
  }

  Never _throwApi(http.Response res) {
    String message = 'Error ${res.statusCode}: ${res.reasonPhrase ?? 'Request failed'}';
    try {
      if (res.body.isNotEmpty) {
        final body = jsonDecode(res.body);
        if (body is Map) {
          if (body['message'] is String && (body['message'] as String).trim().isNotEmpty) {
            message = body['message'];
          } else if (body['errors'] is Map) {
            final errors = body['errors'] as Map;
            for (final entry in errors.entries) {
              final list = entry.value;
              if (list is List) {
                for (final item in list) {
                  if (item is String && item.trim().isNotEmpty) {
                    message = item;
                    break;
                  }
                }
              }
            }
          } else {
            message = res.body;
          }
        } else {
          message = res.body;
        }
      }
    } catch (_) {}
    throw ApiException(res.statusCode, message);
  }

  // ---------- Endpoints (use .env API_URL robustly) ----------

  // GET user/me
  Future<MeModel> getMe() async {
    final url = buildApiUri('user/me');
    final res = await _send(() => http.get(url, headers: _headersAuthOnly()));
    final json = _handleJson(res);
    return MeModel.fromJson(json as Map<String, dynamic>);
  }

  // PUT user/me
  Future<MeModel> updateMe(Map<String, dynamic> body) async {
    final url = buildApiUri('user/me');
    final res = await _send(
      () => http.put(url, headers: _headersJson(), body: jsonEncode(body)),
    );
    final json = _handleJson(res);
    return MeModel.fromJson(json as Map<String, dynamic>);
  }

  // PATCH user/me/password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final url = buildApiUri('user/me/password');
    final res = await _send(
      () => http.patch(
        url,
        headers: _headersJson(),
        body: jsonEncode({
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        }),
      ),
    );
    _handleNoContentOrOk(res);
  }

  // PATCH user/me/email
  Future<void> changeEmail({required String newEmail, String? currentPassword}) async {
    final url = buildApiUri('user/me/email');
    final res = await _send(
      () => http.patch(
        url,
        headers: _headersJson(),
        body: jsonEncode({
          "newEmail": newEmail,
          if (currentPassword != null) "currentPassword": currentPassword,
        }),
      ),
    );
    _handleNoContentOrOk(res);
  }

  // PUT user/me/image  (URL or data URI)
  Future<MeModel> upsertMyImageUrl(String urlOrDataUri) async {
    final url = buildApiUri('user/me/image');
    final res = await _send(
      () => http.put(
        url,
        headers: _headersJson(),
        body: jsonEncode({'url': urlOrDataUri}),
      ),
    );
    final json = _handleJson(res);
    return MeModel.fromJson(json as Map<String, dynamic>);
  }

  // DELETE user/me/image
  Future<void> deleteMyImage() async {
    final url = buildApiUri('user/me/image');
    final res = await _send(() => http.delete(url, headers: _headersAuthOnly()));
    _handleNoContentOrOk(res);
  }

  // Optional: PUT user/me/image/file (multipart)
  Future<MeModel> uploadMyImageFile(File file) async {
    final uri = buildApiUri('user/me/image/file');
    final req = http.MultipartRequest('PUT', uri);

    // Auth header only; let MultipartRequest set its own Content-Type boundary
    final token = AuthProvider.token;
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.headers['Accept'] = 'application/json';

    req.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await req.send().timeout(const Duration(seconds: 20));
    final res = await http.Response.fromStream(streamed);
    final json = _handleJson(res);
    return MeModel.fromJson(json as Map<String, dynamic>);
  }
}
