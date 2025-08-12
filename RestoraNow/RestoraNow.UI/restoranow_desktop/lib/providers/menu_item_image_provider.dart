// lib/providers/menu_item_image_provider.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/menu_item_image_model.dart';
import '../core/menu_item_image_api_service.dart';

class MenuItemImageProvider with ChangeNotifier {
  final MenuItemImageApiService _api = MenuItemImageApiService();

  /// Raw models by menu item
  final Map<int, List<MenuItemImageModel>> _imagesByMenuItemId = {};

  /// One-time fetch guard (prevents repeated fetches during scrolling)
  final Set<int> _requestedOnce = {};

  /// Decoded first-image bytes cache per menu item (prevents re-decoding)
  final Map<int, Uint8List?> _firstBytesCache = {};

  List<MenuItemImageModel> getImagesForMenuItem(int menuItemId) =>
      _imagesByMenuItemId[menuItemId] ?? [];

  /// Returns cached decoded bytes for the first image (if any).
  /// Decodes only once per item until invalidated.
  Uint8List? getFirstImageBytes(int menuItemId) {
    if (_firstBytesCache.containsKey(menuItemId)) {
      return _firstBytesCache[menuItemId];
    }
    final list = _imagesByMenuItemId[menuItemId];
    if (list == null || list.isEmpty) return null;

    final bytes = _decodeBase64(list.first.url);
    _firstBytesCache[menuItemId] = bytes;
    return bytes;
  }

  /// Regular fetch (will notify listeners if changed)
  Future<void> fetchImages(int menuItemId) async {
    try {
      final results = await _api.get(filter: {'MenuItemId': menuItemId.toString()});
      final old = _imagesByMenuItemId[menuItemId] ?? const <MenuItemImageModel>[];
      final next = results.items;

      // If IDs are identical -> skip notify to reduce rebuild noise
      final oldIds = old.map((e) => e.id).toList();
      final newIds = next.map((e) => e.id).toList();
      final changed = !listEquals(oldIds, newIds);

      _imagesByMenuItemId[menuItemId] = next;

      // Invalidate decoded bytes if first image changed (id or url)
      final oldFirst = old.isNotEmpty ? old.first.url : null;
      final newFirst = next.isNotEmpty ? next.first.url : null;
      if (oldFirst != newFirst) {
        _firstBytesCache.remove(menuItemId);
      }

      if (changed || oldFirst != newFirst) {
        notifyListeners();
      }
    } catch (_) {
      _imagesByMenuItemId[menuItemId] = [];
      _firstBytesCache.remove(menuItemId);
      notifyListeners();
    }
  }

  /// Fire-and-forget one-time fetch (useful in list/picker to avoid refetch loops)
  Future<void> fetchImagesOnce(int menuItemId) async {
    if (_requestedOnce.contains(menuItemId)) return;
    _requestedOnce.add(menuItemId);
    await fetchImages(menuItemId);
  }

  Future<void> uploadImage(MenuItemImageModel image) async {
    try {
      final created = await _api.insert(image.toJson());
      _imagesByMenuItemId.putIfAbsent(image.menuItemId, () => []).add(created);
      _firstBytesCache.remove(image.menuItemId);
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
      _firstBytesCache.remove(image.menuItemId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> deleteImage(int imageId, int menuItemId) async {
    try {
      await _api.delete(imageId);
      _imagesByMenuItemId[menuItemId]?.removeWhere((image) => image.id == imageId);
      _firstBytesCache.remove(menuItemId);
      notifyListeners();
    } catch (_) {}
  }

  // ---- helpers ----
  Uint8List? _decodeBase64(String base64String) {
    final regex = RegExp(r'data:image/[^;]+;base64,');
    final cleaned = base64String.replaceAll(regex, '');
    try {
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }
}
