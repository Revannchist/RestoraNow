import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../core/menu_item_image_api_service.dart';
import '../models/menu_item_image_model.dart';
import '../models/search_result.dart';

class MenuItemImageProvider with ChangeNotifier {
  final MenuItemImageApiService _api = MenuItemImageApiService();

  /// Cache of images per menu item id (we enforce single image per item).
  final Map<int, List<MenuItemImageModel>> _byMenuItemId = {};

  /// Decoded bytes cache for the FIRST image per menu item (for list thumbs).
  final Map<int, Uint8List?> _firstBytesCache = {};

  /// Prevent redundant fetches during rebuild/scroll.
  final Set<int> _requestedOnce = {};

  // ------------------- Public getters -------------------

  /// Current images for a menu item (empty list if none).
  List<MenuItemImageModel> imagesFor(int menuItemId) =>
      _byMenuItemId[menuItemId] ?? const [];

  /// Convenience: first image's decoded bytes (cached).
  Uint8List? firstBytesFor(int menuItemId) {
    if (_firstBytesCache.containsKey(menuItemId)) {
      return _firstBytesCache[menuItemId];
    }
    final imgs = _byMenuItemId[menuItemId];
    if (imgs == null || imgs.isEmpty) return null;

    final bytes = _decodeBase64(imgs.first.url);
    _firstBytesCache[menuItemId] = bytes;
    return bytes;
  }

  /// Convenience: first image's raw URL/dataURL (no decoding).
  String? firstUrlFor(int menuItemId) {
    final list = _byMenuItemId[menuItemId];
    return (list == null || list.isEmpty) ? null : list.first.url;
  }

  // ------------------- Fetch -------------------

  /// Fetch all images for a menu item (not guarded).
  Future<void> fetchImages(int menuItemId) async {
    final old = _byMenuItemId[menuItemId] ?? const <MenuItemImageModel>[];

    try {
      final SearchResult<MenuItemImageModel> res = await _api.get(
        filter: {'MenuItemId': menuItemId.toString()},
        page: 1,
        pageSize: 20,
      );

      _byMenuItemId[menuItemId] = res.items;

      // Invalidate first-bytes cache if first image changed.
      final oldFirst = old.isNotEmpty ? old.first.url : null;
      final newFirst = res.items.isNotEmpty ? res.items.first.url : null;
      if (oldFirst != newFirst) {
        _firstBytesCache.remove(menuItemId);
      }

      // Notify if list changed (by id) or first changed.
      final changed = !_sameIds(old, res.items);
      if (changed || oldFirst != newFirst) notifyListeners();
    } catch (_) {
      // On failure, keep old list but clear first-bytes cache to avoid stale thumbs.
      _firstBytesCache.remove(menuItemId);
      notifyListeners();
      rethrow;
    }
  }

  /// One-time fetch guard; safe to call from item builders.
  Future<void> fetchImagesOnce(int menuItemId) async {
    if (_requestedOnce.contains(menuItemId)) return;
    _requestedOnce.add(menuItemId);
    await fetchImages(menuItemId);
  }

  // ------------------- CRUD helpers -------------------

  /// Insert a new image record. We enforce a single image per menu item,
  /// so we *replace* any existing list locally with the created image.
  Future<MenuItemImageModel> uploadImage(MenuItemImageModel image) async {
    final created = await _api.insert(image.toJson());
    _byMenuItemId[image.menuItemId] = [created]; // enforce single image
    _firstBytesCache.remove(image.menuItemId);
    notifyListeners();
    return created;
  }

  /// Update an image record (keeps single-image invariant).
  Future<MenuItemImageModel> updateImage(MenuItemImageModel image) async {
    final updated = await _api.update(image.id, image.toJson());
    _byMenuItemId[image.menuItemId] = [updated]; // ensure only one remains
    _firstBytesCache.remove(image.menuItemId);
    notifyListeners();
    return updated;
  }

  /// Delete a single image.
  Future<void> deleteImage(int imageId, int menuItemId) async {
    await _api.delete(imageId);
    _byMenuItemId[menuItemId]?.removeWhere((e) => e.id == imageId);
    _firstBytesCache.remove(menuItemId);
    notifyListeners();
  }

  /// Delete *all* images for a given menu item (used when “Remove Image” selected).
  Future<void> deleteAllForMenuItem(int menuItemId) async {
    final list = List<MenuItemImageModel>.from(
      _byMenuItemId[menuItemId] ?? const [],
    );
    for (final img in list) {
      await _api.delete(img.id);
    }
    _byMenuItemId[menuItemId] = const [];
    _firstBytesCache.remove(menuItemId);
    notifyListeners();
  }

  /// Ensure **exactly one** image: delete existing and insert a new data-URL.
  Future<MenuItemImageModel> replaceWithDataUrl({
    required int menuItemId,
    required String dataUrl,
    String? description,
  }) async {
    // Delete all (server + local cache)
    await deleteAllForMenuItem(menuItemId);

    // Insert the new one
    final created = await _api.insert(
      MenuItemImageModel(
        id: 0,
        menuItemId: menuItemId,
        url: dataUrl,
        description: description,
      ).toJson(),
    );

    _byMenuItemId[menuItemId] = [created];
    _firstBytesCache.remove(menuItemId); // force re-decode for fresh bytes
    notifyListeners();
    return created;
  }

  // ------------------- Internal helpers -------------------

  Uint8List? _decodeBase64(String value) {
    final cleaned = value.replaceAll(RegExp(r'data:image/[^;]+;base64,'), '');
    try {
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  bool _sameIds(List<MenuItemImageModel> a, List<MenuItemImageModel> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}
