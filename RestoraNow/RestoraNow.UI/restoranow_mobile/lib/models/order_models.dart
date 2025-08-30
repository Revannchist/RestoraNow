// ---------- Status ----------
enum OrderStatus { pending, preparing, ready, completed, cancelled }

OrderStatus _parseOrderStatusDynamic(dynamic s) {
  // Accept both ints (0..4) and strings ("Pending", "pending", etc.)
  if (s is int) {
    if (s >= 0 && s < OrderStatus.values.length) {
      return OrderStatus.values[s];
    }
    return OrderStatus.pending;
  }
  final str = (s ?? '').toString().toLowerCase();
  switch (str) {
    case 'pending':
      return OrderStatus.pending;
    case 'preparing':
      return OrderStatus.preparing;
    case 'ready':
      return OrderStatus.ready;
    case 'completed':
      return OrderStatus.completed;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
}

String orderStatusToString(OrderStatus s) {
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
      return 'Cancelled';
  }
}

// ---------- OrderItem ----------
class OrderItemModel {
  final int id;
  final int orderId;
  final int menuItemId;
  final int quantity;
  final double unitPrice;

  /// Optional server-calculated; UI can fall back to qty * unitPrice
  final double? totalPrice;

  /// Friendly label for UI; can come flattened or from nested menuItem
  final String? menuItemName;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.quantity,
    required this.unitPrice,
    this.totalPrice,
    this.menuItemName,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final menu = json['menuItem'] as Map<String, dynamic>?; // from ThenInclude
    return OrderItemModel(
      id: json['id'] ?? 0,
      orderId: json['orderId'] ?? 0,
      menuItemId: json['menuItemId'] ?? (menu?['id'] ?? 0),
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      menuItemName: json['menuItemName'] ?? menu?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'menuItemId': menuItemId,
    'quantity': quantity,
    'unitPrice': unitPrice,
    if (totalPrice != null) 'totalPrice': totalPrice,
    if (menuItemName != null) 'menuItemName': menuItemName,
  };

  double get lineTotal => totalPrice ?? (unitPrice * quantity);
}

// ---------- Order ----------
class OrderModel {
  final int id;
  final int userId;
  final String? userName; // nice display if available/derived
  final int? reservationId;
  final DateTime createdAt;
  final OrderStatus status;
  final List<OrderItemModel> orderItems;

  OrderModel({
    required this.id,
    required this.userId,
    this.userName,
    this.reservationId,
    required this.createdAt,
    required this.status,
    this.orderItems = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // createdAt: accept ISO string or unix ms
    final createdRaw = json['createdAt'];
    DateTime created;
    if (createdRaw is String) {
      created =
          DateTime.tryParse(createdRaw)?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    } else if (createdRaw is int) {
      created = DateTime.fromMillisecondsSinceEpoch(createdRaw, isUtc: true);
    } else {
      created = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    // items
    final items = ((json['orderItems'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OrderItemModel.fromJson)
        .toList();

    // derive userName if not flattened
    String? name = json['userName'];
    if (name == null || name.trim().isEmpty) {
      final user = json['user'] as Map<String, dynamic>?;
      if (user != null) {
        final first = (user['firstName'] ?? '').toString().trim();
        final last = (user['lastName'] ?? '').toString().trim();
        final email = (user['email'] ?? '').toString().trim();
        final composed = [first, last].where((s) => s.isNotEmpty).join(' ');
        name = composed.isNotEmpty
            ? composed
            : (email.isNotEmpty ? email : null);
      }
    }

    return OrderModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? (json['user']?['id'] ?? 0),
      userName: name,
      reservationId: json['reservationId'] ?? (json['reservation']?['id']),
      createdAt: created,
      status: _parseOrderStatusDynamic(json['status']),
      orderItems: items,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'reservationId': reservationId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'status': orderStatusToString(status),
    'orderItems': orderItems.map((e) => e.toJson()).toList(),
  };

  double get total => orderItems.fold(0.0, (sum, it) => sum + it.lineTotal);
  int get totalQuantity => orderItems.fold(0, (sum, it) => sum + it.quantity);
}

// ---------- Create & Update DTOs ----------
class OrderCreateRequestModel {
  final int userId;
  final int? reservationId;
  final List<int> menuItemIds;

  OrderCreateRequestModel({
    required this.userId,
    this.reservationId,
    required this.menuItemIds,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'reservationId': reservationId,
    'menuItemIds': menuItemIds,
  };
}

class OrderUpdateRequestModel {
  final int userId;
  final int? reservationId;
  final OrderStatus status;
  final List<int> menuItemIds;

  OrderUpdateRequestModel({
    required this.userId,
    this.reservationId,
    required this.status,
    required this.menuItemIds,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'reservationId': reservationId,
    'status': orderStatusToString(status),
    'menuItemIds': menuItemIds,
  };
}

// ---------- Helpers ----------
List<int> buildMenuItemIdsFromMap(Map<int, int> qtyById) {
  final ids = <int>[];
  qtyById.forEach((id, qty) {
    for (var i = 0; i < qty; i++) ids.add(id);
  });
  return ids;
}

List<int> buildMenuItemIdsFromItems(List<OrderItemModel> items) {
  final ids = <int>[];
  for (final it in items) {
    for (var i = 0; i < it.quantity; i++) {
      ids.add(it.menuItemId);
    }
  }
  return ids;
}

