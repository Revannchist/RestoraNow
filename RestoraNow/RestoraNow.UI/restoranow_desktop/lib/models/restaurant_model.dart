class RestaurantModel {
  final int id;
  final String name;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  RestaurantModel({
    required this.id,
    required this.name,
    this.address,
    this.phoneNumber,
    this.email,
    this.description,
    required this.isActive,
    required this.createdAt,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      description: json['description'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'email': email,
      'description': description,
      'isActive': isActive,
    };
  }
}
