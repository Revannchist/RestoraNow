import '../models/menu_item_image_model.dart';
import '../providers/base/base_provider.dart';

class MenuItemImageApiService extends BaseProvider<MenuItemImageModel> {
  MenuItemImageApiService() : super('MenuItemImage');

  @override
  MenuItemImageModel fromJson(Map<String, dynamic> json) {
    return MenuItemImageModel.fromJson(json);
  }
}
