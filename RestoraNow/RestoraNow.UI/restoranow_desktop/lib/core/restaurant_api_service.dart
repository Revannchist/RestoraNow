import '../models/restaurant_model.dart';
import '../providers/base/base_provider.dart';

class RestaurantApiService extends BaseProvider<RestaurantModel> {
  RestaurantApiService() : super('Restaurant');

  @override
  RestaurantModel fromJson(Map<String, dynamic> json) {
    return RestaurantModel.fromJson(json);
  }
}
