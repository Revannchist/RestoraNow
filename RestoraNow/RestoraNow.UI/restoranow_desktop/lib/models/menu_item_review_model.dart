class MenuItemReviewModel {
  final int id;
  final int userId;
  final String? userName;
  final String? userEmail;

  final int menuItemId;
  final String? menuItemName;

  final int rating; // 1..5
  final String? comment;
  final DateTime createdAt;

  MenuItemReviewModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    required this.menuItemId,
    this.menuItemName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory MenuItemReviewModel.fromJson(Map<String, dynamic> json) {
    return MenuItemReviewModel(
      id: _asInt(json['id']),
      userId: _asInt(json['userId']),
      userName: json['userName'],
      userEmail: json['userEmail'],
      menuItemId: _asInt(json['menuItemId']),
      menuItemName: json['menuItemName'],
      rating: _asInt(json['rating']),
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'userEmail': userEmail,
    'menuItemId': menuItemId,
    'menuItemName': menuItemName,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Matches backend `MenuItemReviewRequest`
  Map<String, dynamic> toRequestJson() => {
    'userId': userId,
    'menuItemId': menuItemId,
    'rating': rating,
    'comment': comment,
  };
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
