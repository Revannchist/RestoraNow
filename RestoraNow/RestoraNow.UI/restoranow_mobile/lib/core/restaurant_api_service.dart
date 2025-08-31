import '../models/restaurant_model.dart';
import '../providers/base/base_provider.dart';

class RestaurantApiService extends BaseProvider<RestaurantModel> {
  RestaurantApiService() : super('Restaurant');

  @override
  RestaurantModel fromJson(Map<String, dynamic> json) {
    return RestaurantModel.fromJson(json);
  }

  Future<RestaurantModel?> getSingle() async {
    final result = await get(page: 1, pageSize: 1);
    return result.items.isNotEmpty ? result.items.first : null;
  }
}
