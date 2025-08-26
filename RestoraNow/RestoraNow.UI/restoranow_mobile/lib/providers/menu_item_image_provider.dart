import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../models/menu_item_image_model.dart';
import '../core/menu_item_image_api_service.dart';
import '../models/search_result.dart';

class MenuItemImageProvider with ChangeNotifier {
  final _api = MenuItemImageApiService();

  final Map<int, List<MenuItemImageModel>> _byMenuItemId = {};
  final Map<int, Uint8List?> _firstBytesCache = {};
  final Set<int> _requestedOnce = {};

  List<MenuItemImageModel> imagesFor(int menuItemId) =>
      _byMenuItemId[menuItemId] ?? const [];

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

  Future<void> fetchImages(int menuItemId) async {
    try {
      final SearchResult<MenuItemImageModel> res = await _api.get(
        filter: {'MenuItemId': menuItemId.toString()},
        page: 1,
        pageSize: 20,
      );
      _byMenuItemId[menuItemId] = res.items;

      // Invalidate cached decoded bytes if first changed
      _firstBytesCache.remove(menuItemId);
      notifyListeners();
    } catch (_) {
      _byMenuItemId[menuItemId] = const [];
      _firstBytesCache.remove(menuItemId);
      notifyListeners();
    }
  }

  /// Fire-and-forget guard to avoid refetching during rebuilds
  Future<void> fetchImagesOnce(int menuItemId) async {
    if (_requestedOnce.contains(menuItemId)) return;
    _requestedOnce.add(menuItemId);
    await fetchImages(menuItemId);
  }

  Uint8List? _decodeBase64(String value) {
    final cleaned = value.replaceAll(RegExp(r'data:image/[^;]+;base64,'), '');
    try {
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }
}
