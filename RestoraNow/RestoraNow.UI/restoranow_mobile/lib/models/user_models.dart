class UserImageModel {
  final int id;
  final String url;
  UserImageModel({required this.id, required this.url});

  factory UserImageModel.fromJson(Map<String, dynamic> json) =>
      UserImageModel(id: (json['id'] ?? 0) as int, url: json['url'] as String);
}

// ---------- UserModel (optional if you show avatars there) ----------
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

  // keep nested image if server sometimes sends it
  final UserImageModel? image;

  // NEW: capture flat imageUrl also
  final String? imageUrlFlat;

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
    this.image,
    this.imageUrlFlat,
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
    roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    image: (json['image'] is Map<String, dynamic>)
        ? UserImageModel.fromJson(json['image'] as Map<String, dynamic>)
        : null,
    imageUrlFlat: json['imageUrl'] as String?, // <— accept flat
  );

  Map<String, dynamic> toRequestJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phoneNumber': phoneNumber,
    'isActive': isActive,
  };

  // Use whichever exists
  String? get imageUrl => image?.url ?? imageUrlFlat;
}

// ---------- MeModel (this is the one your screen uses) ----------
class MeModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String? phoneNumber;

  // nested object if present
  final UserImageModel? image;

  // NEW: flat field if present
  final String? imageUrlFlat;

  final DateTime createdAt;
  final DateTime? lastLoginAt;

  MeModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    this.phoneNumber,
    this.image,
    this.imageUrlFlat,
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
    image: (json['image'] is Map<String, dynamic>)
        ? UserImageModel.fromJson(json['image'] as Map<String, dynamic>)
        : null,
    imageUrlFlat: json['imageUrl'] as String?, // <— accept flat
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastLoginAt: json['lastLoginAt'] != null
        ? DateTime.parse(json['lastLoginAt'] as String)
        : null,
  );

  // Single point your UI/provider use
  String? get imageUrl => image?.url ?? imageUrlFlat;
}
