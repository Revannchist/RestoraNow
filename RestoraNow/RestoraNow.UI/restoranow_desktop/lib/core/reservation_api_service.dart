import '../providers/base/base_provider.dart';
import '../models/reservation_model.dart';

class ReservationApiService extends BaseProvider<ReservationModel> {
  // Keep the casing you already use (works on your GETs)
  ReservationApiService() : super('Reservation');

  @override
  ReservationModel fromJson(Map<String, dynamic> json) =>
      ReservationModel.fromJson(json);

  /// GET /api/Reservation/{id}
  Future<ReservationModel> getById(int id) => super.getById(id);

  /// Safer update: load current, apply the delta, then PUT a full body.
  Future<ReservationModel> updateMerged(
    int id,
    Map<String, dynamic> delta, {
    int? userIdOverride,
  }) async {
    final current = await getById(id);

    // Build a *complete* request body the backend expects.
    final body = <String, dynamic>{
      'userId': userIdOverride ?? current.userId,
      'tableId': current.tableId,
      'reservationDate': current.reservationDate.toIso8601String(), // ISO
      'reservationTime': current.reservationTime, // "HH:mm:ss"
      'guestCount': current.guestCount,
      'specialRequests': current.specialRequests ?? '',
      'status': _statusToApi(current.status),
      // Apply caller changes last so they override
      ...delta,
    };

    // In case caller passed enum instead of string
    final s = body['status'];
    if (s is ReservationStatus) body['status'] = _statusToApi(s);

    return await update(id, body);
  }

  /// Convenience helpers for common status changes
  Future<ReservationModel> confirmReservation(int id) =>
      updateMerged(id, {'status': 'Confirmed'});

  Future<ReservationModel> cancelReservationMerged(int id) =>
      updateMerged(id, {'status': 'Cancelled'});

  String _statusToApi(ReservationStatus s) {
    switch (s) {
      case ReservationStatus.pending:
        return 'Pending';
      case ReservationStatus.confirmed:
        return 'Confirmed';
      case ReservationStatus.cancelled:
        return 'Cancelled';
      case ReservationStatus.completed:
        return 'Completed';
      case ReservationStatus.noShow:
        return 'NoShow';
    }
  }
}
