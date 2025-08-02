import '../models/user_image_model.dart';
import '../providers/base/base_provider.dart';

class UserImageApiService extends BaseProvider<UserImageModel> {
  UserImageApiService() : super("UserImage");

  @override
  UserImageModel fromJson(Map<String, dynamic> json) {
    return UserImageModel.fromJson(json);
  }

  Future<UserImageModel?> getByUserId(int userId) async {
    final results = await get(filter: {'UserId': userId});
    if (results.items.isNotEmpty) {
      return results.items.first;
    }
    return null;
  }
}
