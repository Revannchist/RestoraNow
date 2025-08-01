import 'package:flutter/material.dart';
import '../models/user_image_model.dart';
import '../core/user_image_api_service.dart';

class UserImageProvider with ChangeNotifier {
  final UserImageApiService _api = UserImageApiService();
  final Map<int, UserImageModel?> _imageMap = {};

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  UserImageModel? getImageForUser(int userId) => _imageMap[userId];

  Future<void> fetchUserImage(int userId) async {
    if (_imageMap.containsKey(userId)) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final image = await _api.getByUserId(userId);
      _imageMap[userId] = image;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadOrUpdateImage(UserImageModel image) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      UserImageModel response;
      if (image.id == 0) {
        response = await _api.insert(image.toJson());
      } else {
        response = await _api.update(image.id, image.toJson());
      }

      _imageMap[image.userId] = response;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUserImage(int id, int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.delete(id);
      _imageMap[userId] = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
