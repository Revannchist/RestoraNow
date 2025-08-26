import '../providers/base/base_provider.dart';
import '../models/order_models.dart';

class OrderApiService extends BaseProvider<OrderModel> {
  OrderApiService() : super('Order');

  @override
  OrderModel fromJson(Map<String, dynamic> json) {
    return OrderModel.fromJson(json);
  }
}
