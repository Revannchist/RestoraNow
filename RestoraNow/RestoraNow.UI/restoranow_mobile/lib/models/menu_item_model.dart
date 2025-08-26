class MenuItemModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final bool isAvailable;
  final bool isSpecialOfTheDay;
  final int categoryId;
  final String? categoryName;
  final List<String> imageUrls;

  MenuItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.isAvailable = true,
    this.isSpecialOfTheDay = false,
    required this.categoryId,
    this.categoryName,
    this.imageUrls = const [],
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      isAvailable: json['isAvailable'] ?? true,
      isSpecialOfTheDay: json['isSpecialOfTheDay'] ?? false,
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'isAvailable': isAvailable,
      'isSpecialOfTheDay': isSpecialOfTheDay,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'imageUrls': imageUrls,
    };
  }

  // For Create/Update requests (omit `id`, `categoryName`, `imageUrls`)
  Map<String, dynamic> toRequestJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'isAvailable': isAvailable,
      'isSpecialOfTheDay': isSpecialOfTheDay,
      'categoryId': categoryId,
    };
  }
}
