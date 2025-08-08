class ReviewModel {
  final int id;
  final int userId;
  final String? userName;
  final String? userEmail; // <-- add this
  final int restaurantId;
  final String? restaurantName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  ReviewModel({
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

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      userEmail: json['userEmail'], 
      restaurantId: json['restaurantId'],
      restaurantName: json['restaurantName'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail, // <-- add this
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'userId': userId,
      'restaurantId': restaurantId,
      'rating': rating,
      'comment': comment,
    };
  }
}
