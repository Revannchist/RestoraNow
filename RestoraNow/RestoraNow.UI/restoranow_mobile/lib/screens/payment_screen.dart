import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/base/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';

import '../providers/payment_provider.dart';
import '../models/payment_models.dart';
import 'paypal_approve_screen.dart';

enum _PayMethod { paypal, cash }

class PaymentScreen extends StatefulWidget {
  final int? reservationId;
  const PaymentScreen({super.key, this.reservationId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  _PayMethod _method = _PayMethod.paypal; // default to PayPal

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
                    // adjust the currency label if you want to read it from .env
                    label: Text(
                      'Total: ${cart.totalPrice.toStringAsFixed(2)} USD',
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
            subtitle: Text('PayPal • Cash on delivery'),
          ),
          RadioListTile<_PayMethod>(
            value: _PayMethod.paypal,
            groupValue: _method,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _method = v);
            },
            title: const Text('Pay with PayPal'),
            subtitle: const Text('Secure card/wallet via PayPal'),
            secondary: const Icon(Icons.account_balance_wallet_outlined),
          ),
          RadioListTile<_PayMethod>(
            value: _PayMethod.cash,
            groupValue: _method,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _method = v);
            },
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
                            final auth = context.read<AuthProvider>();
                            if (!auth.isAuthenticated) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Session expired. Please sign in again.',
                                  ),
                                ),
                              );
                              Navigator.pushReplacementNamed(context, '/login');
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

                            final userId = auth.userId;
                            if (userId == null) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not read user id from token.',
                                  ),
                                ),
                              );
                              return;
                            }

                            // 1) Create the order on the backend
                            final menuItemIds = context
                                .read<CartProvider>()
                                .toMenuItemIds();

                            // If placeOrder throws on failure (recommended), this will jump to catch.
                            // If your placeOrder returns null instead, change its signature to non-nullable.
                            late final order;
                            try {
                              order = await context
                                  .read<OrderProvider>()
                                  .placeOrder(
                                    userId: userId,
                                    reservationId: widget.reservationId,
                                    menuItemIds: menuItemIds,
                                  );
                            } catch (e) {
                              if (!mounted) return;
                              final err =
                                  context.read<OrderProvider>().error ??
                                  'Failed to create order: $e';
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(err)));
                              return;
                            }

                            if (!mounted) return;

                            // 2) Branch by method
                            if (_method == _PayMethod.cash) {
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
                              return;
                            }

                            // 3) PayPal flow
                            try {
                              final payProv = context.read<PaymentProvider>();
                              final created = await payProv.createPaypalOrder(
                                order.id,
                              ); // id is non-nullable

                              final payment = await Navigator.of(context)
                                  .push<PaymentResponse?>(
                                    MaterialPageRoute(
                                      builder: (_) => PaypalApproveScreen(
                                        approveUrl: created.approveUrl,
                                        providerOrderId:
                                            created.providerOrderId,
                                      ),
                                    ),
                                  );

                              if (!mounted) return;

                              if (payment != null &&
                                  (payment.status?.toLowerCase() ==
                                      'completed')) {
                                context.read<CartProvider>().clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Payment completed for order #${order.id}.',
                                    ),
                                  ),
                                );
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/orders');
                              } else if (payment == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Payment canceled.'),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Payment failed (status: ${payment.status ?? 'unknown'}).',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('PayPal error: $e')),
                              );
                            }
                          },
                    child: Text(
                      _method == _PayMethod.cash
                          ? 'Place order (Cash)'
                          : 'Pay with PayPal',
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
