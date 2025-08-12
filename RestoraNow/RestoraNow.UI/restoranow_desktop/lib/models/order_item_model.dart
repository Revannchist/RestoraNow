class OrderItemModel {
  final int id;
  final int orderId;
  final int menuItemId;
  final int quantity;
  final double unitPrice;

  /// Server-calculated if your mapper exposes it; else null
  final double? totalPrice;

  /// Nice label for UI; read from flattened field OR nested menuItem.name
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
    // Nested menuItem (if included by the API)
    final menu = json['menuItem'] as Map<String, dynamic>?;
    return OrderItemModel(
      id: json['id'] ?? 0,
      orderId: json['orderId'] ?? 0,
      menuItemId: json['menuItemId'] ?? 0,
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

  /// Client-side fallback if `totalPrice` isn't provided
  double get lineTotal => totalPrice ?? (unitPrice * quantity);

  /// For OrderItem endpoints (not used for your create/update order which sends menuItemIds)
  Map<String, dynamic> toRequestJson() => {
        'orderId': orderId,
        'menuItemId': menuItemId,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}
