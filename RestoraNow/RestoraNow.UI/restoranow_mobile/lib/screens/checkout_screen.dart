import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import 'payment_screen.dart';

class CheckoutScreen extends StatelessWidget {
  final int? reservationId;
  final String? deliveryAddress;

  const CheckoutScreen({
    super.key,
    this.reservationId,
    this.deliveryAddress,
  });

  bool _looksLikePickup(String? s) {
    if (s == null) return false;
    final t = s.toLowerCase();
    return t.contains('pick up') || t.contains('pickup');
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orderProv = context.watch<OrderProvider>();

    final items = cart.items.values.toList();
    final totalQty = cart.totalQty;
    final totalPrice = cart.totalPrice;

    final isReservation = reservationId != null;
    final isPickup = !isReservation && _looksLikePickup(deliveryAddress);
    final isDelivery = !isReservation && !isPickup;

    final addressText = (deliveryAddress?.trim().isNotEmpty ?? false)
        ? deliveryAddress!.trim()
        : null;

    IconData _modeIcon() {
      if (isReservation) return Icons.event_seat;
      if (isPickup) return Icons.storefront;
      return Icons.local_shipping;
    }

    String _modeTitle() {
      if (isReservation) return 'Attached to reservation #$reservationId';
      if (isPickup) return 'Pick up at restaurant';
      return 'Delivery / Takeaway';
    }

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
                      Icon(_modeIcon()),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _modeTitle(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDelivery)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: const Text('Delivery address',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          addressText ?? 'No delivery address provided',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: addressText == null
                                ? Theme.of(context).colorScheme.error
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (isPickup)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      child: const ListTile(
                        leading: Icon(Icons.storefront),
                        title: Text('Pickup',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Pick up at restaurant'),
                      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: orderProv.submitting ? null : () => Navigator.of(context).maybePop(),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (items.isEmpty || orderProv.submitting)
                              ? null
                              : () {
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
