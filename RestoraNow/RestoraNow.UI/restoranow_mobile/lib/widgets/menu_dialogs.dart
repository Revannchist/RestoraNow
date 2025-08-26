// lib/widgets/menu_dialogs.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/base/auth_provider.dart';

void showCartSheet(BuildContext context, {int? reservationId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CartSheet(reservationId: reservationId),
  );
}

class _CartSheet extends StatelessWidget {
  final int? reservationId;
  const _CartSheet({this.reservationId});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orderProv = context.watch<OrderProvider>();
    final auth = context.watch<AuthProvider>();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 48,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const Text('Your Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            if (cart.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Cart is empty.'),
              )
            else
              Expanded( // ensures list can scroll
                child: ListView(
                  children: cart.items.values.map((ci) {
                    final item = ci.item;
                    final raw = (item.imageUrls.isNotEmpty) ? item.imageUrls.first : null;

                    Widget thumb = const _ThumbFallback();
                    if (raw != null && raw.isNotEmpty) {
                      if (raw.startsWith('data:image/')) {
                        try {
                          final cleaned = raw.replaceAll(RegExp(r'data:image/[^;]+;base64,'), '');
                          final bytes = base64Decode(cleaned);
                          if (bytes.isNotEmpty) {
                            thumb = ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(bytes, width: 54, height: 54, fit: BoxFit.cover),
                            );
                          }
                        } catch (_) {}
                      } else {
                        final url = raw
                            .replaceFirst('://localhost', '://10.0.2.2')
                            .replaceFirst('://127.0.0.1', '://10.0.2.2');
                        thumb = ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            url,
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const _ThumbFallback(),
                          ),
                        );
                      }
                    }

                    return ListTile(
                      leading: thumb,
                      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${item.price.toStringAsFixed(2)} KM • x${ci.qty}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Decrease',
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => context.read<CartProvider>().removeOne(item.id),
                          ),
                          Text('${ci.qty}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          IconButton(
                            tooltip: 'Increase',
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => context.read<CartProvider>().add(item),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${cart.totalPrice.toStringAsFixed(2)} KM',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: cart.items.isEmpty ? null : () => context.read<CartProvider>().clear(),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (cart.items.isEmpty || orderProv.submitting)
                        ? null
                        : () async {
                            final userId = auth.userId;
                            if (userId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('You must be logged in.')),
                              );
                              return;
                            }

                            final menuItemIds = context.read<CartProvider>().toMenuItemIds();
                            final order = await context.read<OrderProvider>().placeOrder(
                                  userId: userId,
                                  reservationId: reservationId,
                                  menuItemIds: menuItemIds,
                                );

                            if (order != null) {
                              context.read<CartProvider>().clear();
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Order #${order.id} created.')),
                                );
                              }
                            } else {
                              final err = context.read<OrderProvider>().error ?? 'Failed to create order.';
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                            }
                          },
                    child: orderProv.submitting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Proceed to payment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.fastfood, size: 22, color: Colors.grey),
    );
  }
}
