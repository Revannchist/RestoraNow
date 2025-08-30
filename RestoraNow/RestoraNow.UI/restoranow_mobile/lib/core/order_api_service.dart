import '../providers/base/base_provider.dart';
import '../models/order_models.dart';

class OrderApiService extends BaseProvider<OrderModel> {
  OrderApiService()
    : super('Order'); // keep this matching your controller route

  @override
  OrderModel fromJson(Map<String, dynamic> json) => OrderModel.fromJson(json);

  // ---- Use existing PUT /api/Order/{id} for everything ----

  Future<OrderModel> updateOrderFull({
    required int id,
    required int userId,
    int? reservationId,
    required List<int> menuItemIds,
    required OrderStatus status,
  }) {
    return update(id, {
      'userId': userId,
      'reservationId': reservationId,
      'menuItemIds': menuItemIds,
      'status': _statusToApi(status), // API expects string
    });
  }

  // Cancel = keep items, set status Cancelled
  Future<OrderModel> cancelWithPut({
    required OrderModel current,
    required int userId,
  }) {
    return updateOrderFull(
      id: current.id,
      userId: userId,
      reservationId: current.reservationId,
      menuItemIds: _expandFromOrder(current),
      status: OrderStatus.cancelled,
    );
  }

  // Replace items = keep status, change items
  Future<OrderModel> replaceItemsWithPut({
    required OrderModel current,
    required int userId,
    required Map<int, int> itemQuantities, // menuItemId -> qty
  }) {
    return updateOrderFull(
      id: current.id,
      userId: userId,
      reservationId: current.reservationId,
      menuItemIds: _expandFromQuantities(itemQuantities),
      status: current.status,
    );
  }

  // ---- helpers ----
  List<int> _expandFromOrder(OrderModel order) {
    final ids = <int>[];
    for (final it in order.orderItems) {
      final mid = it.menuItemId;
      for (var i = 0; i < it.quantity; i++) ids.add(mid);
    }
    return ids;
  }

  List<int> _expandFromQuantities(Map<int, int> q) {
    final ids = <int>[];
    q.forEach((id, qty) {
      for (var i = 0; i < qty; i++) ids.add(id);
    });
    return ids;
  }

  String _statusToApi(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled'; // change to 'Canceled' if needed
    }
  }
}
