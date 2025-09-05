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

  final String? imageUrl;

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
    this.imageUrl, // NEW
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    String? resolveImageUrl(Map<String, dynamic> j) {
      final single = j['imageUrl'] as String?;
      if (single != null && single.isNotEmpty) return single;
      final list = j['imageUrls'] as List?;
      if (list != null && list.isNotEmpty && list.first is String && (list.first as String).isNotEmpty) {
        return list.first as String;
      }
      return null;
    }

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
      imageUrl: resolveImageUrl(json), // NEW
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
    'imageUrl': imageUrl, // harmless in UI-only usage
  };

  Map<String, dynamic> toRequestJson() => {
    'name': name,
    'description': description,
    'price': price,
    'isAvailable': isAvailable,
    'isSpecialOfTheDay': isSpecialOfTheDay,
    'categoryId': categoryId,
  };

  // handy for instant UI refresh after upload
  MenuItemModel withImage(String url) => MenuItemModel(
    id: id,
    name: name,
    description: description,
    price: price,
    isAvailable: isAvailable,
    isSpecialOfTheDay: isSpecialOfTheDay,
    categoryId: categoryId,
    categoryName: categoryName,
    averageRating: averageRating,
    ratingsCount: ratingsCount,
    imageUrl: url,
  );
}
