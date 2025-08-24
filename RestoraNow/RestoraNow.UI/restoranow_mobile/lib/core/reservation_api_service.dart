import '../providers/base/base_provider.dart';
import '../models/reservation_model.dart';

class ReservationApiService extends BaseProvider<ReservationModel> {
  // Backend route attribute is [Route("api/reservation")] (lowercase)
  ReservationApiService() : super("reservation");

  @override
  ReservationModel fromJson(Map<String, dynamic> json) =>
      ReservationModel.fromJson(json);

  // GET /api/reservation?UserId=123
  Future<List<ReservationModel>> getMyReservations(int userId) async {
    final result = await get(filter: {'UserId': userId}, page: 1, pageSize: 100);
    return result.items;
  }

  // Convenience: GET /api/reservation/{id}
  Future<ReservationModel> getById(int id) => super.getById(id);

  // POST /api/reservation  (MUST include userId)
  Future<ReservationModel> createReservation(
    Map<String, dynamic> payload,
    int userId,
  ) async {
    final body = Map<String, dynamic>.from(payload);
    body['userId'] = userId; // <- inject caller id
    return await insert(body);
  }

  // PUT /api/reservation/{id} (MUST include userId)
  Future<ReservationModel> updateReservation(
    int id,
    Map<String, dynamic> payload,
    int userId,
  ) async {
    final body = Map<String, dynamic>.from(payload);
    body['userId'] = userId;
    return await update(id, body);
  }

  // "Cancel" = PUT with status changed to Cancelled (no PATCH endpoint on backend)
  Future<ReservationModel> cancelReservation(int id) async {
    final current = await getById(id);

    // Build a full request body the backend expects (TimeSpan as "HH:mm:ss")
    final body = {
      'userId': current.userId,
      'tableId': current.tableId,
      'reservationDate': current.reservationDate.toIso8601String(),
      'reservationTime': current.reservationTime, // "HH:mm:ss"
      'guestCount': current.guestCount,
      'specialRequests': current.specialRequests,
      'status': 'Cancelled', // JsonStringEnumConverter accepts the string
    };

    return await update(id, body);
  }
}
