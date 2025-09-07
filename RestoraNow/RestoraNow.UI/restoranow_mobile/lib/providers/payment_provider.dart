import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../core/payment_api_service.dart';
import '../models/payment_models.dart';

class PaymentProvider extends ChangeNotifier {
  PaymentProvider({Future<String?> Function()? getJwt})
    : _api = PaymentApiService(
        apiBase: (dotenv.env['API_URL'] ?? 'http://10.0.2.2:5294/api/'),
        getJwt: getJwt,
      );

  final PaymentApiService _api;

  bool _busy = false;
  String? _error;
  bool get busy => _busy;
  String? get error => _error;

  Future<CreatePaypalOrderResult> createPaypalOrder(
    int orderId, {
    String? currency,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.createPaypalOrder(orderId, currency: currency);
      return res;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<PaymentResponse> capturePaypalOrder(String token) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.capturePaypalOrder(token);
      return res;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
