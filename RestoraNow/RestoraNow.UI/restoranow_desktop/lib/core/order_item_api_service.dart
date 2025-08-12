import '../models/order_item_model.dart';
import '../providers/base/base_provider.dart';

class OrderItemApiService extends BaseProvider<OrderItemModel> {
  OrderItemApiService() : super('OrderItem');

  @override
  OrderItemModel fromJson(Map<String, dynamic> json) {
    return OrderItemModel.fromJson(json);
  }
}
