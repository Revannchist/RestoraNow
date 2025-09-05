class MenuItemReviewModel {
  final int id;
  final int userId;
  final String? userName;
  final String? userEmail;

  final int menuItemId;
  final String? menuItemName;

  final int rating; // 1..5
  final String? comment;
  final DateTime createdAt; // server UTC → parsed here

  const MenuItemReviewModel({
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
    final created = json['createdAt'];
    final createdAt = (created is String)
        ? (DateTime.tryParse(created)?.toLocal() ?? DateTime.now())
        : DateTime.now();

    return MenuItemReviewModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userName: json['userName'],
      userEmail: json['userEmail'],
      menuItemId: json['menuItemId'] as int,
      menuItemName: json['menuItemName'],
      rating: json['rating'] as int,
      comment: json['comment'],
      createdAt: createdAt,
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
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  MenuItemReviewModel copyWith({
    int? id,
    int? userId,
    String? userName,
    String? userEmail,
    int? menuItemId,
    String? menuItemName,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return MenuItemReviewModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      menuItemId: menuItemId ?? this.menuItemId,
      menuItemName: menuItemName ?? this.menuItemName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// POST/PUT payload
class MenuItemReviewRequest {
  final int userId;
  final int menuItemId;
  final int rating; // 1..5
  final String? comment;

  const MenuItemReviewRequest({
    required this.userId,
    required this.menuItemId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'menuItemId': menuItemId,
        'rating': rating,
        'comment': comment,
      };
}
