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

  String? _lastError;
  String? get lastError => _lastError;

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

  /// Convenience getter: the first image's raw URL/data-URL (if any).
  String? getFirstImageUrl(int menuItemId) {
    final list = _imagesByMenuItemId[menuItemId];
    if (list == null || list.isEmpty) return null;
    return list.first.url;
  }

  /// Regular fetch (will notify listeners if changed)
  Future<void> fetchImages(int menuItemId) async {
    try {
      _lastError = null;
      final results = await _api.get(
        filter: {'MenuItemId': menuItemId.toString()},
      );
      final old =
          _imagesByMenuItemId[menuItemId] ?? const <MenuItemImageModel>[];
      final next = results.items;

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
    } catch (e) {
      _lastError = e.toString();
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

  /// Upload a new image WITHOUT enforcing single-image rule (legacy helper).
  Future<MenuItemImageModel?> uploadImage(MenuItemImageModel image) async {
    try {
      _lastError = null;
      final created = await _api.insert(image.toJson());
      _imagesByMenuItemId.putIfAbsent(image.menuItemId, () => []).add(created);
      _firstBytesCache.remove(image.menuItemId);
      notifyListeners();
      return created;
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }

  /// Enforce "ONE IMAGE PER MENU ITEM":
  /// - Deletes any existing image(s) for the item
  /// - Uploads the provided one
  Future<MenuItemImageModel?> uploadOrReplaceImage(
    MenuItemImageModel image,
  ) async {
    try {
      _lastError = null;

      // 1) fetch current images for this item
      final existing = await _api.get(
        filter: {'MenuItemId': image.menuItemId.toString()},
      );

      // 2) delete them (usually 0 or 1)
      for (final img in existing.items) {
        await _api.delete(img.id);
      }

      // 3) insert new one
      final created = await _api.insert(image.toJson());

      // 4) update caches
      _imagesByMenuItemId[image.menuItemId] = [created];
      _firstBytesCache.remove(image.menuItemId);
      notifyListeners();
      return created;
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }

  /// Convenience for dialogs: pass a data URL directly.
  Future<MenuItemImageModel?> replaceWithDataUrl({
    required int menuItemId,
    required String dataUrl,
    String? description,
  }) {
    return uploadOrReplaceImage(
      MenuItemImageModel(
        id: 0,
        menuItemId: menuItemId,
        url: dataUrl,
        description: description,
      ),
    );
  }

  Future<bool> updateImage(MenuItemImageModel image) async {
    try {
      _lastError = null;
      final updated = await _api.update(image.id, image.toJson());
      final list = _imagesByMenuItemId[image.menuItemId];
      if (list != null) {
        final index = list.indexWhere((i) => i.id == image.id);
        if (index != -1) list[index] = updated;
      }
      _firstBytesCache.remove(image.menuItemId);
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> deleteImage(int imageId, int menuItemId) async {
    try {
      _lastError = null;
      await _api.delete(imageId);
      _imagesByMenuItemId[menuItemId]?.removeWhere(
        (image) => image.id == imageId,
      );
      _firstBytesCache.remove(menuItemId);
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<int> deleteAllForMenuItem(int menuItemId) async {
    try {
      _lastError = null;
      final existing = await _api.get(
        filter: {'MenuItemId': menuItemId.toString()},
      );
      for (final img in existing.items) {
        await _api.delete(img.id);
      }
      _imagesByMenuItemId[menuItemId] = [];
      _firstBytesCache.remove(menuItemId);
      notifyListeners();
      return existing.items.length;
    } catch (e) {
      _lastError = e.toString();
      return 0;
    }
  }

  void clearCacheFor(int menuItemId) {
    _imagesByMenuItemId.remove(menuItemId);
    _firstBytesCache.remove(menuItemId);
    _requestedOnce.remove(menuItemId);
    notifyListeners();
  }

  // ---- helpers ----
  Uint8List? _decodeBase64(String base64String) {
    // strip data URI; also strip whitespace/newlines if any
    final cleaned = base64String
        .replaceAll(RegExp(r'^data:image/[^;]+;base64,'), '')
        .replaceAll(RegExp(r'\s'), '');
    try {
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }
}
