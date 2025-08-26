import 'package:flutter/material.dart';
import '../models/order_models.dart';

void showOrderDetailsBottomSheet(BuildContext context, OrderModel order) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _OrderDetailsSheet(order: order),
  );
}

class _OrderDetailsSheet extends StatelessWidget {
  final OrderModel order;
  const _OrderDetailsSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final items = order.orderItems;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 4, width: 48,
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 12),

            Row(
              children: [
                Text('Order #${order.id}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                _StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(_subtitle(order), style: TextStyle(color: Colors.grey[700])),
            ),
            const SizedBox(height: 12),

            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No items.'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final it = items[i];
                    final qty = it.quantity;
                    final price = it.unitPrice;
                    final line = it.lineTotal;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(it.menuItemName ?? 'Item #${it.menuItemId}'),
                      subtitle: Text('${price.toStringAsFixed(2)} KM • x$qty'),
                      trailing: Text(line.toStringAsFixed(2) + ' KM',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  },
                ),
              ),

            const Divider(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${order.total.toStringAsFixed(2)} KM',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),

            if (order.reservationId != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Reservation: #${order.reservationId}'),
              ),
          ],
        ),
      ),
    );
  }

  static String _subtitle(OrderModel o) {
    String fmt(DateTime dt) {
      final d = dt.toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
    }

    final parts = <String>[
      '${o.totalQuantity} item(s)',
      '${o.total.toStringAsFixed(2)} KM',
      fmt(o.createdAt),
      if (o.userName != null) o.userName!,
    ];
    return parts.join(' • ');
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final text = orderStatusToString(status);
    final color = _color(status);
    return Chip(
      label: Text(text),
      backgroundColor: color.withOpacity(0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }

  static Color _color(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return Colors.amber.shade800;
      case OrderStatus.preparing: return Colors.orange.shade800;
      case OrderStatus.ready: return Colors.blue.shade700;
      case OrderStatus.completed: return Colors.green.shade700;
      case OrderStatus.cancelled: return Colors.red.shade600;
    }
  }
}
