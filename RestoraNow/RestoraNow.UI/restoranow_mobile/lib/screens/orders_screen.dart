import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../layouts/main_layout.dart';
import '../../providers/order_list_provider.dart';
import '../../providers/base/auth_provider.dart';
import '../../models/order_models.dart';
import '../../widgets/order_details_dialogs.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrdersView _view = OrdersView.current;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final uid = auth.userId;
      if (uid != null) {
        context.read<OrderListProvider>().refreshForUser(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final listProv = context.watch<OrderListProvider>();

    final orders = _view == OrdersView.current
        ? listProv.currentOrders
        : listProv.pastOrders;

    return MainLayout(
      title: 'My Orders',
      child: Column(
        children: [
          // Toggle: Current / History
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Current'),
                  selected: _view == OrdersView.current,
                  onSelected: (_) => setState(() => _view = OrdersView.current),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('History'),
                  selected: _view == OrdersView.history,
                  onSelected: (_) => setState(() => _view = OrdersView.history),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    final uid = context.read<AuthProvider>().userId;
                    if (uid != null) {
                      context.read<OrderListProvider>().refreshForUser(uid);
                    }
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: listProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : (listProv.error != null)
                    ? Center(child: Text(listProv.error!))
                    : RefreshIndicator(
                        onRefresh: () async {
                          final uid = context.read<AuthProvider>().userId;
                          if (uid != null) {
                            await context.read<OrderListProvider>().refreshForUser(uid);
                          }
                        },
                        child: orders.isEmpty
                            ? ListView(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      _view == OrdersView.current
                                          ? 'No active orders.'
                                          : 'No past orders.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.only(bottom: 12, top: 8),
                                itemCount: orders.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (_, i) => _OrderTile(order: orders[i]),
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final OrderModel order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(order.status);
    final chipColor = _chipColorFor(context, order.status);

    final subtitle = StringBuffer();
    subtitle.write('${order.totalQuantity} item(s)');
    final total = order.total;
    if (total > 0) subtitle.write(' • ${total.toStringAsFixed(2)} KM');
    subtitle.write(' • ${_fmt(order.createdAt.toLocal())}');
    if (order.reservationId != null) subtitle.write(' • Res #${order.reservationId}');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: chipColor.withOpacity(0.12),
        child: Icon(icon, color: chipColor),
      ),
      title: Text('Order #${order.id}'),
      subtitle: Text(subtitle.toString()),
      trailing: Chip(
        label: Text(orderStatusToString(order.status)),
        backgroundColor: chipColor.withOpacity(0.12),
        labelStyle: TextStyle(color: chipColor, fontWeight: FontWeight.w600),
        side: BorderSide(color: chipColor.withOpacity(0.3)),
      ),
      onTap: () => showOrderDetailsBottomSheet(context, order),
    );
  }

  static IconData _iconFor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return Icons.timelapse;
      case OrderStatus.preparing: return Icons.local_fire_department;
      case OrderStatus.ready: return Icons.check_circle_outline;
      case OrderStatus.completed: return Icons.done_all;
      case OrderStatus.cancelled: return Icons.cancel_outlined;
    }
  }

  static Color _chipColorFor(BuildContext ctx, OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return Colors.amber.shade800;
      case OrderStatus.preparing: return Colors.orange.shade800;
      case OrderStatus.ready: return Colors.blue.shade700;
      case OrderStatus.completed: return Colors.green.shade700;
      case OrderStatus.cancelled: return Colors.red.shade600;
    }
  }

  static String _fmt(DateTime dt) {
    // Simple "dd.MM.yyyy HH:mm" formatter
    final d = dt;
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
    }
}
