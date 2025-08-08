import '../models/review_model.dart';
import '../providers/base/base_provider.dart';

class ReviewApiService extends BaseProvider<ReviewModel> {
  ReviewApiService() : super('Review');

  @override
  ReviewModel fromJson(Map<String, dynamic> json) {
    return ReviewModel.fromJson(json);
  }
}
