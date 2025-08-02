class MenuItemImageModel {
  final int id;
  final int menuItemId;
  final String url;
  final String? description;

  MenuItemImageModel({
    required this.id,
    required this.menuItemId,
    required this.url,
    this.description,
  });

  factory MenuItemImageModel.fromJson(Map<String, dynamic> json) {
    return MenuItemImageModel(
      id: json['id'],
      menuItemId: json['menuItemId'],
      url: json['url'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menuItemId': menuItemId,
      'url': url,
      'description': description,
    };
  }
}
