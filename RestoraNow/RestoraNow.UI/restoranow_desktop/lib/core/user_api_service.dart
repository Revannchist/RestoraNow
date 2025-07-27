import '../providers/base_provider.dart';
import '../models/user_model.dart';

class UserApiService extends BaseProvider<UserModel> {
  UserApiService() : super("User");

  @override
  UserModel fromJson(Map<String, dynamic> json) {
    return UserModel.fromJson(json);
  }
}
