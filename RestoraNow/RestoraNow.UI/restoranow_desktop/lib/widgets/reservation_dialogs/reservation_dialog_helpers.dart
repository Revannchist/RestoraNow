// lib/dialogs/reservation_dialog_helpers.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/user_api_service.dart';
import '../../models/user_model.dart';
import '../../models/search_result.dart';

// Single instance for lookups
final UserApiService userApi = UserApiService();

Future<List<UserModel>> searchUsers(String query) async {
  final q = query.trim();
  if (q.isEmpty) return [];
  try {
    final SearchResult<UserModel> res = await userApi.get(
      filter: {
        'Username': q, // email-as-username
        'Name': q, // first/last name
        'RetrieveAll': 'true',
      },
      page: 1,
      pageSize: 10,
    );
    return res.items;
  } catch (_) {
    return [];
  }
}

String displayUser(UserModel u) {
  final first = u.firstName.trim();
  final last = u.lastName.trim();
  final name = [first, last].where((s) => s.isNotEmpty).join(' ');
  if (name.isNotEmpty) return name;

  final email = u.email.trim();
  if (email.isNotEmpty) return email; // fallback if no name

  return 'User #${u.id}';
}

// -------- Date / Time helpers --------
String formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

bool isValidDate(String s) {
  try {
    final d = DateTime.parse(s);
    return formatDate(d) == s; // strict yyyy-MM-dd
  } catch (_) {
    return false;
  }
}

DateTime? tryParseDate(String s) {
  if (!isValidDate(s)) return null;
  try {
    return DateTime.parse(s);
  } catch (_) {
    return null;
  }
}

bool isValidTime(String s) {
  final re = RegExp(r'^\d{2}:\d{2}:\d{2}$');
  if (!re.hasMatch(s)) return false;
  final parts = s.split(':').map(int.parse).toList();
  final h = parts[0], m = parts[1], sec = parts[2];
  return h >= 0 && h < 24 && m >= 0 && m < 60 && sec >= 0 && sec < 60;
}

String formatTimeOfDay(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

TimeOfDay? parseTimeOfDay(String s) {
  if (!isValidTime(s)) return null;
  final parts = s.split(':').map(int.parse).toList();
  return TimeOfDay(hour: parts[0], minute: parts[1]);
}

// -------- Server error mapping --------
void mapServerErrors(http.Response response, Map<String, String?> fieldErrors) {
  try {
    final errorData = jsonDecode(response.body);
    if (errorData is Map && errorData['errors'] is Map) {
      final errors = Map<String, dynamic>.from(errorData['errors']);
      errors.forEach((key, value) {
        final field = key.toString().toLowerCase();
        final msg = (value is List && value.isNotEmpty)
            ? value.first.toString()
            : value.toString();
        if (field.contains('userid')) {
          fieldErrors['userId'] = msg;
        } else if (field.contains('tableid')) {
          fieldErrors['tableId'] = msg;
        } else if (field.contains('reservationdate') ||
            field.contains('date')) {
          fieldErrors['reservationDate'] = msg;
        } else if (field.contains('reservationtime') ||
            field.contains('time')) {
          fieldErrors['reservationTime'] = msg;
        } else if (field.contains('guestcount')) {
          fieldErrors['guestCount'] = msg;
        } else if (field.contains('specialrequests')) {
          fieldErrors['specialRequests'] = msg;
        } else if (field.contains('status')) {
          fieldErrors['status'] = msg;
        } else {
          fieldErrors['general'] = msg;
        }
      });
    } else {
      fieldErrors['general'] = 'Unexpected error occurred.';
    }
  } catch (_) {
    fieldErrors['general'] = 'Unexpected error occurred.';
  }
}