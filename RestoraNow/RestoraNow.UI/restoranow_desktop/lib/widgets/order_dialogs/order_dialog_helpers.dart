import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/user_api_service.dart';
import '../../core/menu_item_api_service.dart';
import '../../core/reservation_api_service.dart';
import '../../models/menu_item_model.dart';
import '../../models/reservation_model.dart';
import '../../models/search_result.dart';
import '../../models/user_model.dart';

final UserApiService userApi = UserApiService();
final MenuItemApiService menuApi = MenuItemApiService();
final ReservationApiService reservationApi = ReservationApiService();

Future<List<UserModel>> searchUsers(String query) async {
  final q = query.trim();
  if (q.isEmpty) return [];
  try {
    final SearchResult<UserModel> res = await userApi.get(
      filter: {
        'Username': q, // email/username
        'Name': q,     // first/last name
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
  final fn = u.firstName.trim();
  final ln = u.lastName.trim();
  final name = [fn, ln].where((s) => s.isNotEmpty).join(' ');
  if (name.isNotEmpty) return name;
  if (u.email.trim().isNotEmpty) return u.email.trim();
  return 'User #${u.id}';
}

Future<List<MenuItemModel>> searchMenuItems(String query) async {
  final q = query.trim();
  if (q.isEmpty) return [];
  try {
    final SearchResult<MenuItemModel> res = await menuApi.get(
      filter: {
        'Name': q,
        'IsAvailable': 'true',
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

String displayMenuItem(MenuItemModel m) {
  final price = m.price.toStringAsFixed(2);
  final cat = (m.categoryName ?? '').trim();
  return cat.isNotEmpty ? '${m.name} • $cat • $price' : '${m.name} • $price';
}

/// Reservations are optional. We list by selected user (if any),
/// otherwise return empty (force user first).
Future<List<ReservationModel>> searchReservations({
  required String query,
  required int? userId,
}) async {
  if (userId == null) return [];
  try {
    final filter = <String, String>{
      'UserId': userId.toString(),
      'RetrieveAll': 'true',
    };

    // If query is numeric, treat as TableId filter (nice to have)
    final q = query.trim();
    final tableId = int.tryParse(q);
    if (tableId != null) filter['TableId'] = tableId.toString();

    final SearchResult<ReservationModel> res = await reservationApi.get(
      filter: filter,
      page: 1,
      pageSize: 10,
    );
    return res.items;
  } catch (_) {
    return [];
  }
}

String displayReservation(ReservationModel r) {
  final date =
      '${r.reservationDate.year.toString().padLeft(4, '0')}-'
      '${r.reservationDate.month.toString().padLeft(2, '0')}-'
      '${r.reservationDate.day.toString().padLeft(2, '0')}';
  final tableTxt = r.tableNumber != null ? 'Table ${r.tableNumber}' : 'Table #${r.tableId}';
  return 'Res #${r.id} • $date ${r.reservationTime} • $tableTxt (${r.guestCount} ppl)';
}

/// Map server-side validation errors (optional)
void mapServerErrors(http.Response response, Map<String, String?> fieldErrors) {
  try {
    final data = jsonDecode(response.body);
    if (data is Map && data['errors'] is Map) {
      final errs = Map<String, dynamic>.from(data['errors']);
      errs.forEach((key, value) {
        final field = key.toString().toLowerCase();
        final msg = (value is List && value.isNotEmpty) ? value.first.toString() : value.toString();
        if (field.contains('userid')) {
          fieldErrors['userId'] = msg;
        } else if (field.contains('reservationid')) {
          fieldErrors['reservationId'] = msg;
        } else if (field.contains('menuitemids')) {
          fieldErrors['menuItemIds'] = msg;
        } else {
          fieldErrors['general'] = msg;
        }
      });
    } else {
      fieldErrors['general'] = 'Unexpected error.';
    }
  } catch (_) {
    fieldErrors['general'] = 'Unexpected error.';
  }
}
