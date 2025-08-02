class MenuCategoryModel {
  final int id;
  final String name;
  final String? description;
  final bool isActive;

  MenuCategoryModel({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
  });

  factory MenuCategoryModel.fromJson(Map<String, dynamic> json) {
    return MenuCategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isActive: json['isActive'],
    );
  }
}
