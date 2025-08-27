import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/base/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';

enum _PayMethod { card, cash }

class PaymentScreen extends StatefulWidget {
  final int? reservationId;
  const PaymentScreen({super.key, this.reservationId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  _PayMethod _method = _PayMethod.cash; // default to cash

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orderProv = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Chip(
                    avatar: const Icon(Icons.shopping_bag_outlined),
                    label: Text(
                      'Total: ${cart.totalPrice.toStringAsFixed(2)} KM',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          const ListTile(
            title: Text('Choose a payment method'),
            subtitle: Text('Card (coming soon) • Cash on delivery (available)'),
          ),
          RadioListTile<_PayMethod>(
            value: _PayMethod.card,
            groupValue: _method,
            onChanged: (v) => setState(() => _method = v!),
            title: const Text('Pay by card'),
            subtitle: const Text('Coming soon'),
            secondary: const Icon(Icons.credit_card),
          ),
          RadioListTile<_PayMethod>(
            value: _PayMethod.cash,
            groupValue: _method,
            onChanged: (v) => setState(() => _method = v!),
            title: const Text('Cash on delivery'),
            subtitle: const Text('Pay with cash when you receive your order'),
            secondary: const Icon(Icons.payments_outlined),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                if (orderProv.submitting)
                  const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: orderProv.submitting
                        ? null
                        : () async {
                            if (_method == _PayMethod.card) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Card payments are coming soon.',
                                  ),
                                ),
                              );
                              return;
                            }

                            // Cash on delivery: place the order now
                            final auth = context.read<AuthProvider>();
                            final userId =
                                auth.userId; // should be non-null in your flow
                            if (userId == null) {
                              // ultra-rare fallback: session lost
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Session expired. Please sign in again.',
                                    ),
                                  ),
                                );
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                              }
                              return;
                            }

                            if (cart.totalQty == 0) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Your cart is empty.'),
                                ),
                              );
                              return;
                            }

                            final menuItemIds = context
                                .read<CartProvider>()
                                .toMenuItemIds();
                            final order = await context
                                .read<OrderProvider>()
                                .placeOrder(
                                  userId: userId,
                                  reservationId: widget.reservationId,
                                  menuItemIds: menuItemIds,
                                );

                            if (!mounted) return;

                            if (order != null) {
                              context.read<CartProvider>().clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Order #${order.id} placed. Status: Pending',
                                  ),
                                ),
                              );
                              Navigator.of(
                                context,
                              ).pushReplacementNamed('/orders');
                            } else {
                              final err =
                                  context.read<OrderProvider>().error ??
                                  'Failed to create order.';
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(err)));
                            }
                          },
                    child: Text(
                      _method == _PayMethod.cash
                          ? 'Place order (Cash)'
                          : 'Pay with card',
                    ),
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
