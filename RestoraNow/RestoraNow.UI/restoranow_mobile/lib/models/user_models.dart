class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? phoneNumber;
  final List<String> roles;
  final String? imageUrl;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
    this.phoneNumber,
    this.roles = const [],
    this.imageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as int,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
    username: json['username'] as String,
    isActive: json['isActive'] as bool? ?? true,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastLoginAt: json['lastLoginAt'] != null
        ? DateTime.parse(json['lastLoginAt'] as String)
        : null,
    phoneNumber: json['phoneNumber'] as String?,
    roles:
        (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    imageUrl: json['imageUrl'] as String?,
  );

  Map<String, dynamic> toRequestJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phoneNumber': phoneNumber,
    'isActive': isActive,
  };
}

// Mobile "me" response (matches your MeResponse)
class MeModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String? phoneNumber;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  MeModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    this.phoneNumber,
    this.imageUrl,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory MeModel.fromJson(Map<String, dynamic> json) => MeModel(
    id: json['id'] as int,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
    username: json['username'] as String,
    phoneNumber: json['phoneNumber'] as String?,
    imageUrl: json['imageUrl'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastLoginAt: json['lastLoginAt'] != null
        ? DateTime.parse(json['lastLoginAt'] as String)
        : null,
  );
}
