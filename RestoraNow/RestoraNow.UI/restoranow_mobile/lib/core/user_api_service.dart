import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../providers/base/base_provider.dart';
import '../providers/base/auth_provider.dart';
import '../core/api_exception.dart';
import '../models/user_model.dart'; // <-- add this

class UserApiService extends BaseProvider<UserModel> {
  UserApiService() : super("User");

  @override
  UserModel fromJson(Map<String, dynamic> json) => UserModel.fromJson(json);

  // GET /api/user/me
  Future<MeModel> getMe() async {
    final res = await _send(
      () => http.get(buildApiUri("user/me"), headers: _headers()),
    );
    final json = _handleJson(res);
    return MeModel.fromJson(json as Map<String, dynamic>);
  }

  // PUT /api/user/me
  Future<MeModel> updateMe(Map<String, dynamic> body) async {
    final res = await _send(
      () => http.put(
        buildApiUri("user/me"),
        headers: _headers(),
        body: jsonEncode(body),
      ),
    );
    final json = _handleJson(res);
    return MeModel.fromJson(json as Map<String, dynamic>);
  }

  // PATCH /api/user/me/password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final res = await _send(
      () => http.patch(
        buildApiUri("user/me/password"),
        headers: _headers(),
        body: jsonEncode({
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        }),
      ),
    );
    _handleNoContentOrOk(res);
  }

  // PATCH /api/user/me/email
  Future<void> changeEmail({
    required String newEmail,
    String? currentPassword,
  }) async {
    final res = await _send(
      () => http.patch(
        buildApiUri("user/me/email"),
        headers: _headers(),
        body: jsonEncode({
          "newEmail": newEmail,
          if (currentPassword != null) "currentPassword": currentPassword,
        }),
      ),
    );
    _handleNoContentOrOk(res);
  }

  // PUT /api/user/me/image  -> returns MeResponse (JSON)
  Future<MeModel> upsertMyImageUrl(String url) async {
    final res = await _send(
      () => http.put(
        buildApiUri("user/me/image"),
        headers: _headers(),
        body: jsonEncode({'url': url}), // <— matches MeImageRequest
      ),
    );
    final json = _handleJson(res);
    return MeModel.fromJson(json as Map<String, dynamic>);
  }

  // DELETE /api/user/me/image  -> 204 No Content
  Future<void> deleteMyImage() async {
    final res = await _send(
      () => http.delete(
        buildApiUri("user/me/image"),
        headers: _headers(), // your existing helper (Authorization + Accept)
      ),
    );
    _handleNoContentOrOk(res);
  }

  // local helpers

  // PUT /api/user/me/image/file  -> returns MeResponse (JSON)
  Future<MeModel> uploadMyImageFile(File file) async {
    final uri = buildApiUri(
      "user/me/image/file",
    ); // <-- adjust if your route differs
    final req = http.MultipartRequest('PUT', uri);

    // IMPORTANT: do not set Content-Type manually for multipart
    final token = AuthProvider.token;
    if (token != null) {
      req.headers['Authorization'] = 'Bearer $token';
    }
    req.headers['Accept'] = 'application/json';

    // 'file' must match your backend parameter name: IFormFile file
    req.files.add(await http.MultipartFile.fromPath('file', file.path));

    // Send and convert to Response so you can reuse your JSON handler
    final streamed = await req.send().timeout(const Duration(seconds: 20));
    final res = await http.Response.fromStream(streamed);

    final json = _handleJson(res);
    return MeModel.fromJson(json as Map<String, dynamic>);
  }

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
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
    String message =
        'Error ${res.statusCode}: ${res.reasonPhrase ?? 'Request failed'}';
    try {
      if (res.body.isNotEmpty) {
        final body = jsonDecode(res.body);
        if (body is Map) {
          if (body['message'] is String &&
              (body['message'] as String).trim().isNotEmpty) {
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
}
