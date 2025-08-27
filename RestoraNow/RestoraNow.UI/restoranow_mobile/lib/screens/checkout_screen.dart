import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import 'payment_screen.dart';

class CheckoutScreen extends StatelessWidget {
  final int? reservationId; // null => no reservation
  const CheckoutScreen({super.key, this.reservationId});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orderProv = context.watch<OrderProvider>();

    final items = cart.items.values.toList();
    final totalQty = cart.totalQty;
    final totalPrice = cart.totalPrice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Pay'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: items.isEmpty
          ? const _EmptyCheckout()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        reservationId == null
                            ? Icons.restaurant
                            : Icons.event_seat,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reservationId == null
                              ? 'Dine in / Delivery (no reservation)'
                              : 'Attached to reservation #$reservationId',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final ci = items[i];
                      final item = ci.item;
                      final line = item.price * ci.qty;
                      return ListTile(
                        title: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${item.price.toStringAsFixed(2)} KM • x${ci.qty}',
                        ),
                        trailing: Text(
                          '${line.toStringAsFixed(2)} KM',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      );
                    },
                  ),
                ),

                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total ($totalQty item${totalQty == 1 ? '' : 's'})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${totalPrice.toStringAsFixed(2)} KM',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),

                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: orderProv.submitting
                              ? null
                              : () => Navigator.of(context).maybePop(),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (items.isEmpty || orderProv.submitting)
                              ? null
                              : () {
                                  // Just push; PaymentScreen will handle the rest.
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PaymentScreen(
                                        reservationId: reservationId,
                                      ),
                                    ),
                                  );
                                },
                          child: const Text('Continue to payment'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptyCheckout extends StatelessWidget {
  const _EmptyCheckout();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 40),
            const SizedBox(height: 12),
            const Text('Your cart is empty'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
