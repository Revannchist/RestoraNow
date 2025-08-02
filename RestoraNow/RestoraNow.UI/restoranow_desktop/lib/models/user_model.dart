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
  final String? imageUrl;
  final String? password;

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
    this.imageUrl,
    this.password,
  });

  UserModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? username,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? phoneNumber,
    List<String>? roles,
    String? imageUrl,
    String? password,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      username: username ?? this.username,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      roles: roles ?? this.roles,
      imageUrl: imageUrl ?? this.imageUrl,
      password: password ?? this.password,
    );
  }

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
      imageUrl: json['imageUrl'],
      password: null,
    );
  }
}
