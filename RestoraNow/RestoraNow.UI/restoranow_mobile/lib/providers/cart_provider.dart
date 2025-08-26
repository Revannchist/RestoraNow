import 'package:flutter/material.dart';
import '../models/menu_item_model.dart';

class CartItem {
  final MenuItemModel item;
  int qty;
  CartItem({required this.item, this.qty = 1});
  double get lineTotal => item.price * qty;
}

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};
  Map<int, CartItem> get items => Map.unmodifiable(_items);

  void add(MenuItemModel item, {int qty = 1}) {
    final existing = _items[item.id];
    if (existing == null) {
      _items[item.id] = CartItem(item: item, qty: qty);
    } else {
      existing.qty += qty;
    }
    notifyListeners();
  }

  // quantity helper
  int qtyOf(int menuItemId) => _items[menuItemId]?.qty ?? 0;

  // remove entire line
  void removeAll(int menuItemId) {
    if (_items.remove(menuItemId) != null) notifyListeners();
  }

  void removeOne(int menuItemId) {
    final it = _items[menuItemId];
    if (it == null) return;
    if (it.qty > 1)
      it.qty--;
    else
      _items.remove(menuItemId);
    notifyListeners();
  }

  void setQty(int menuItemId, int qty) {
    if (qty <= 0) {
      _items.remove(menuItemId);
    } else {
      _items[menuItemId]?.qty = qty;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  int get totalQty => _items.values.fold(0, (s, e) => s + e.qty);
  double get totalPrice => _items.values.fold(0.0, (s, e) => s + e.lineTotal);

  /// Duplicate IDs per quantity
  List<int> toMenuItemIds() {
    final ids = <int>[];
    _items.forEach((id, ci) {
      for (var i = 0; i < ci.qty; i++) ids.add(id);
    });
    return ids;
  }
}
