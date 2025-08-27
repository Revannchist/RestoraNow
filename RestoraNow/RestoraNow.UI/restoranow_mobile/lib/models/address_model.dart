class AddressModel {
  final int id;
  final int userId;
  final String street;
  final String? city;
  final String? zipCode;
  final String? country;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.userId,
    required this.street,
    this.city,
    this.zipCode,
    this.country,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      street: json['street'] ?? '',
      city: json['city'],
      zipCode: json['zipCode'],
      country: json['country'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toCreateUpdateJson() {
    return {
      'userId': userId,
      'street': street,
      'city': city,
      'zipCode': zipCode,
      'country': country,
      'isDefault': isDefault,
    };
  }
}
