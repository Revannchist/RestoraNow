class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? username;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? phoneNumber;
  final List<String> roles;
  final List<String> imageUrls;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.username,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
    this.phoneNumber,
    required this.roles,
    required this.imageUrls,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      username: json['username'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      phoneNumber: json['phoneNumber'],
      roles: List<String>.from(json['roles']),
      imageUrls: List<String>.from(json['imageUrls']),
    );
  }
}
