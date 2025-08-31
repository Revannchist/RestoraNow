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
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
