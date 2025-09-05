import '../models/menu_item_review_model.dart';
import '../providers/base/base_provider.dart';

class MenuItemReviewApiService extends BaseProvider<MenuItemReviewModel> {
  MenuItemReviewApiService() : super('MenuItemReview');

  @override
  MenuItemReviewModel fromJson(Map<String, dynamic> json) {
    return MenuItemReviewModel.fromJson(json);
  }
}
