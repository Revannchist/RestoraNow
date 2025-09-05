class MenuItemModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final bool isAvailable;
  final bool isSpecialOfTheDay;
  final int categoryId;
  final String? categoryName;

  final double? averageRating; // null if no reviews
  final int ratingsCount; // 0 if none

  MenuItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.isAvailable = true,
    this.isSpecialOfTheDay = false,
    required this.categoryId,
    this.categoryName,
    this.averageRating,
    this.ratingsCount = 0,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    final avg = json['averageRating'];
    return MenuItemModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      isAvailable: json['isAvailable'] ?? true,
      isSpecialOfTheDay: json['isSpecialOfTheDay'] ?? false,
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      averageRating: (avg == null) ? null : (avg as num).toDouble(),
      ratingsCount: (json['ratingsCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'isAvailable': isAvailable,
    'isSpecialOfTheDay': isSpecialOfTheDay,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'averageRating': averageRating,
    'ratingsCount': ratingsCount,
  };

  Map<String, dynamic> toRequestJson() => {
    'name': name,
    'description': description,
    'price': price,
    'isAvailable': isAvailable,
    'isSpecialOfTheDay': isSpecialOfTheDay,
    'categoryId': categoryId,
  };
}
