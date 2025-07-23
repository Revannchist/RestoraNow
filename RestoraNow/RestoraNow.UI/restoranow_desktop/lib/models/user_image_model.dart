class UserImageModel {
  final int id;
  final String url;
  final String? description;
  final int userId;
  final String? username;

  UserImageModel({
    required this.id,
    required this.url,
    this.description,
    required this.userId,
    this.username,
  });

  factory UserImageModel.fromJson(Map<String, dynamic> json) {
    return UserImageModel(
      id: json['id'],
      url: json['url'],
      description: json['description'],
      userId: json['userId'],
      username: json['username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'description': description,
      'userId': userId,
      'username': username,
    };
  }
}