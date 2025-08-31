class RestaurantReviewModel {
  final int id;
  final int userId;
  final String? userName;
  final String? userEmail;
  final int restaurantId;
  final String? restaurantName;
  final int rating; // 1..5
  final String? comment;
  final DateTime createdAt;

  RestaurantReviewModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    required this.restaurantId,
    this.restaurantName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory RestaurantReviewModel.fromJson(Map<String, dynamic> json) {
    return RestaurantReviewModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      restaurantId: json['restaurantId'] as int,
      restaurantName: json['restaurantName'] as String?,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class RestaurantReviewRequest {
  final int userId;
  final int restaurantId;
  final int rating; // 1..5
  final String? comment;

  RestaurantReviewRequest({
    required this.userId,
    required this.restaurantId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'restaurantId': restaurantId,
    'rating': rating,
    'comment': comment,
  };
}
