import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../providers/base/base_provider.dart';
import '../providers/base/auth_provider.dart';
import '../models/analytics_models.dart';

class AnalyticsApiService extends BaseProvider<SummaryResponse> {
  AnalyticsApiService() : super("Analytics");

  @override
  SummaryResponse fromJson(Map<String, dynamic> json) =>
      SummaryResponse.fromJson(json);

  // ---------- Query helper ----------
  Map<String, String> _q({
    DateTime? from,
    DateTime? to,
    String? groupBy,
    int? take,
  }) {
    final q = <String, String>{};
    if (from != null) q['from'] = from.toUtc().toIso8601String();
    if (to != null) q['to'] = to.toUtc().toIso8601String();
    if (groupBy != null) q['groupBy'] = groupBy;
    if (take != null) q['take'] = '$take';
    return q;
  }

  // ---------- JSON endpoints ----------
  Future<SummaryResponse> getSummary({DateTime? from, DateTime? to}) {
    return getOneCustom<SummaryResponse>(
      'Analytics/summary',
      SummaryResponse.fromJson,
      query: _q(from: from, to: to),
    );
  }

  Future<List<RevenueByPeriodResponse>> getRevenueByPeriod({
    DateTime? from,
    DateTime? to,
    String groupBy = 'day',
  }) {
    return getListCustom<RevenueByPeriodResponse>(
      'Analytics/revenue/by-period',
      RevenueByPeriodResponse.fromJson,
      query: _q(from: from, to: to, groupBy: groupBy),
    );
  }

  Future<List<RevenueByCategoryResponse>> getRevenueByCategory({
    DateTime? from,
    DateTime? to,
  }) {
    return getListCustom<RevenueByCategoryResponse>(
      'Analytics/revenue/by-category',
      RevenueByCategoryResponse.fromJson,
      query: _q(from: from, to: to),
    );
  }

  Future<List<TopProductResponse>> getTopProducts({
    DateTime? from,
    DateTime? to,
    int take = 5,
  }) {
    return getListCustom<TopProductResponse>(
      'Analytics/top-products',
      TopProductResponse.fromJson,
      query: _q(from: from, to: to, take: take),
    );
  }

  /// Downloads the analytics report as PDF bytes.
  Future<Uint8List> downloadReportPdf({
    DateTime? from,
    DateTime? to,
    String groupBy = 'day',
    int? take,
  }) async {
    final query = _q(from: from, to: to, groupBy: groupBy, take: take);
    final uri = buildApiUri('Analytics/report.pdf', query: query);

    // Build headers manually: ask for PDF + add Authorization if available
    final headers = <String, String>{
      'Accept': 'application/pdf',
      if (AuthProvider.token != null)
        'Authorization': 'Bearer ${AuthProvider.token}',
    };

    final res = await http.get(uri, headers: headers);

    if (res.statusCode == 200) {
      return res.bodyBytes;
    }

    // Try to surface meaningful error message
    String message =
        'PDF download failed (${res.statusCode}): ${res.reasonPhrase ?? 'Unknown error'}';
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        if (body['message'] is String &&
            (body['message'] as String).trim().isNotEmpty) {
          message = body['message'];
        } else if (body['errors'] is Map) {
          final errors = body['errors'] as Map;
          for (final entry in errors.entries) {
            final list = entry.value;
            if (list is List && list.isNotEmpty && list.first is String) {
              message = list.first as String;
              break;
            }
          }
        }
      } else if (res.body.isNotEmpty) {
        message = res.body;
      }
    } catch (_) {
      // ignore parse errors; keep default message
    }

    throw Exception(message);
  }
}
