import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/payment_models.dart';

class PaymentApiService {
  PaymentApiService({required String apiBase, this.getJwt})
    : _base = _sanitizeBase(apiBase);

  final Future<String?> Function()? getJwt;
  final String _base; // e.g. "http://10.0.2.2:5294/api" (no trailing slash)

  static String _sanitizeBase(String base) {
    var b = base.trim();
    if (b.endsWith('/')) b = b.substring(0, b.length - 1);
    return b;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_base$p').replace(queryParameters: query);
  }

  Future<CreatePaypalOrderResult> createPaypalOrder(
    int orderId, {
    String? currency,
  }) async {
    final uri = _uri('/payment/paypal/create/$orderId', {
      if (currency != null && currency.isNotEmpty) 'currency': currency,
    });
    debugPrint('[POST] $uri');

    final res = await http.post(uri, headers: await _headers());
    debugPrint('[POST RES] ${res.statusCode} ${res.body}');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return CreatePaypalOrderResult.fromJson(jsonDecode(res.body));
    }
    throw Exception(
      'Create PayPal order failed: ${res.statusCode} ${res.body}',
    );
  }

  Future<PaymentResponse> capturePaypalOrder(String token) async {
    final uri = _uri('/payment/paypal/capture', {'token': token});
    debugPrint('[POST] $uri');

    final res = await http.post(uri, headers: await _headers());
    debugPrint('[POST RES] ${res.statusCode} ${res.body}');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return PaymentResponse.fromJson(jsonDecode(res.body));
    }
    throw Exception('Capture failed: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, String>> _headers() async {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final jwt = await getJwt?.call();
    if (jwt != null && jwt.isNotEmpty) h['Authorization'] = 'Bearer $jwt';
    return h;
  }
}
