// models/user_image_model.dart
class UserImageModel {
  final int id;
  final String url;
  final String? description;
  final int userId;

  UserImageModel({
    required this.id,
    required this.url,
    this.description,
    required this.userId,
  });

  factory UserImageModel.fromJson(Map<String, dynamic> json) {
    return UserImageModel(
      id: json['id'],
      url: json['url'],
      description: json['description'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'description': description,
      'userId': userId,
    };
  }
}
