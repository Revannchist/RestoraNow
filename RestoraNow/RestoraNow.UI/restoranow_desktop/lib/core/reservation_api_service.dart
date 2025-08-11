import '../providers/base/base_provider.dart';
import '../models/reservation_model.dart';

class ReservationApiService extends BaseProvider<ReservationModel> {
  ReservationApiService() : super("Reservation");

  @override
  ReservationModel fromJson(Map<String, dynamic> json) {
    return ReservationModel.fromJson(json);
  }
}
