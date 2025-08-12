import '../models/order_models.dart';
import '../providers/base/base_provider.dart';

class OrderApiService extends BaseProvider<OrderModel> {
  OrderApiService() : super('Order');

  @override
  OrderModel fromJson(Map<String, dynamic> json) => OrderModel.fromJson(json);

  // If you later add a PATCH endpoint, you could implement:
  // Future<OrderModel> patchStatus(int id, OrderStatus status) async {
  //   final body = {'status': orderStatusToString(status)};
  //   final res = await customPatch('$basePath/$id/status', body);
  //   return fromJson(res);
  // }
}
