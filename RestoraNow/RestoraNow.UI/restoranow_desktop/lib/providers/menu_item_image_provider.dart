import 'package:flutter/material.dart';
import '../models/menu_item_image_model.dart';
import '../core/menu_item_image_api_service.dart';

class MenuItemImageProvider with ChangeNotifier {
  final MenuItemImageApiService _api = MenuItemImageApiService();

  final Map<int, List<MenuItemImageModel>> _imagesByMenuItemId = {};

  List<MenuItemImageModel> getImagesForMenuItem(int menuItemId) =>
      _imagesByMenuItemId[menuItemId] ?? [];

  Future<void> fetchImages(int menuItemId) async {
    try {
      final results = await _api.get(
        filter: {'MenuItemId': menuItemId.toString()},
      );
      _imagesByMenuItemId[menuItemId] = results.items;
      notifyListeners();
    } catch (_) {
      _imagesByMenuItemId[menuItemId] = [];
    }
  }

  Future<void> uploadImage(MenuItemImageModel image) async {
    try {
      final created = await _api.insert(image.toJson());
      _imagesByMenuItemId.putIfAbsent(image.menuItemId, () => []).add(created);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateImage(MenuItemImageModel image) async {
    try {
      final updated = await _api.update(image.id, image.toJson());
      final list = _imagesByMenuItemId[image.menuItemId];
      if (list != null) {
        final index = list.indexWhere((i) => i.id == image.id);
        if (index != -1) list[index] = updated;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> deleteImage(int imageId, int menuItemId) async {
    try {
      await _api.delete(imageId);
      _imagesByMenuItemId[menuItemId]
          ?.removeWhere((image) => image.id == imageId);
      notifyListeners();
    } catch (_) {}
  }
}
