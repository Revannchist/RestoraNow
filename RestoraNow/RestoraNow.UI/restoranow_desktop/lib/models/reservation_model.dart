enum ReservationStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  noShow,
}

class ReservationModel {
  final int id;
  final int userId;
  final String? userName;
  final int tableId;
  final String? tableNumber;
  final DateTime reservationDate;
  final String reservationTime; // store as "HH:mm:ss"
  final int guestCount;
  final ReservationStatus status;
  final String? specialRequests;
  final DateTime? confirmedAt;

  ReservationModel({
    required this.id,
    required this.userId,
    this.userName,
    required this.tableId,
    this.tableNumber,
    required this.reservationDate,
    required this.reservationTime,
    required this.guestCount,
    required this.status,
    this.specialRequests,
    this.confirmedAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      tableId: json['tableId'],
      tableNumber: json['tableNumber'],
      reservationDate: DateTime.parse(json['reservationDate']),
      reservationTime: json['reservationTime'] is Map
          ? _parseTicks(json['reservationTime']['ticks'])
          : json['reservationTime'],
      guestCount: json['guestCount'],
      status: _parseStatus(json['status']),
      specialRequests: json['specialRequests'],
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'reservationDate': reservationDate.toIso8601String(),
      'reservationTime': reservationTime, // "HH:mm:ss"
      'guestCount': guestCount,
      'status': status.name[0].toUpperCase() + status.name.substring(1),
      'specialRequests': specialRequests,
      'confirmedAt': confirmedAt?.toIso8601String(),
    };
  }

  static ReservationStatus _parseStatus(dynamic value) {
    if (value is int) {
      return ReservationStatus.values[value];
    } else if (value is String) {
      return ReservationStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => ReservationStatus.pending,
      );
    }
    return ReservationStatus.pending;
  }

  static String _parseTicks(dynamic ticks) {
    if (ticks is int) {
      // Convert ticks -> HH:mm:ss (1 tick = 100ns)
      final micros = ticks ~/ 10;
      final d = Duration(microseconds: micros);
      final h = d.inHours.toString().padLeft(2, '0');
      final m = (d.inMinutes % 60).toString().padLeft(2, '0');
      final s = (d.inSeconds % 60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
    return '00:00:00';
  }
}
