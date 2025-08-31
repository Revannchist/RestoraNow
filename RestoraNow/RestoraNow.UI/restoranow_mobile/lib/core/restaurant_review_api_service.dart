import '../models/restaurant_review_model.dart.dart';
import '../providers/base/base_provider.dart';

class RestaurantReviewApiService extends BaseProvider<RestaurantReviewModel> {
  RestaurantReviewApiService() : super('Review');

  @override
  RestaurantReviewModel fromJson(Map<String, dynamic> json) {
    return RestaurantReviewModel.fromJson(json);
  }
}
