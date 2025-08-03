class TableModel {
  final int id;
  final int tableNumber;
  final int capacity;
  final String? location;
  final bool isAvailable;
  final String? notes;
  final int restaurantId;
  final String? restaurantName;

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    this.location,
    required this.isAvailable,
    this.notes,
    required this.restaurantId,
    this.restaurantName,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'],
      tableNumber: json['tableNumber'],
      capacity: json['capacity'],
      location: json['location'],
      isAvailable: json['isAvailable'],
      notes: json['notes'],
      restaurantId: json['restaurantId'],
      restaurantName: json['restaurantName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'capacity': capacity,
      'location': location,
      'isAvailable': isAvailable,
      'notes': notes,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
    };
  }

  // Optional: for creating/updating table
  Map<String, dynamic> toRequestJson() {
    return {
      'tableNumber': tableNumber,
      'capacity': capacity,
      'location': location,
      'isAvailable': isAvailable,
      'notes': notes,
      'restaurantId': restaurantId,
    };
  }
}
