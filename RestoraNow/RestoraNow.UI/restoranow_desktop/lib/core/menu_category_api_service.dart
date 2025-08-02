import '../models/menu_category_model.dart';
import '../providers/base/base_provider.dart';

class MenuCategoryApiService extends BaseProvider<MenuCategoryModel> {
  MenuCategoryApiService() : super('MenuCategory');

  @override
  MenuCategoryModel fromJson(Map<String, dynamic> json) {
    return MenuCategoryModel.fromJson(json);
  }
}
