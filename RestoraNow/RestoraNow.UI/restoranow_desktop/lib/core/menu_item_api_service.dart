import '../providers/base/base_provider.dart';
import '../models/menu_item_model.dart';

class MenuItemApiService extends BaseProvider<MenuItemModel> {
  MenuItemApiService() : super("MenuItem");

  @override
  MenuItemModel fromJson(Map<String, dynamic> json) {
    return MenuItemModel.fromJson(json);
  }
}
