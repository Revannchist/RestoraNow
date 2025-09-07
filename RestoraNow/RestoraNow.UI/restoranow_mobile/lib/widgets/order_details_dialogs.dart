import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order_models.dart';
import '../providers/order_list_provider.dart';
import '../providers/base/auth_provider.dart';

// reservation summary
import '../core/reservation_api_service.dart';
import '../models/reservation_model.dart';

void showOrderDetailsBottomSheet(BuildContext context, OrderModel order) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _OrderDetailsSheet(order: order),
  );
}

class _OrderDetailsSheet extends StatefulWidget {
  final OrderModel order;
  const _OrderDetailsSheet({required this.order});

  @override
  State<_OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<_OrderDetailsSheet> {
  bool _working = false;

  // Policy:
  // - Cancel: ONLY Pending
  // - Edit:   ONLY Preparing
  // - Others: no actions
  bool get _canCancel => widget.order.status == OrderStatus.pending;
  bool get _canEdit => widget.order.status == OrderStatus.preparing;

  Future<ReservationModel>? _resFuture;

  @override
  void initState() {
    super.initState();
    final rid = widget.order.reservationId;
    if (rid != null) {
      _resFuture = ReservationApiService().getById(rid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final items = order.orderItems;

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
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _subtitle(order),
                style: TextStyle(color: Colors.grey[700]),
              ),
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
                      subtitle: Text('${price.toStringAsFixed(2)} USD • x$qty'),
                      trailing: Text(
                        '${line.toStringAsFixed(2)} USD',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
              ),

            const Divider(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${order.total.toStringAsFixed(2)} USD',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            // Reservation summary (if attached)
            if (order.reservationId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FutureBuilder<ReservationModel>(
                  future: _resFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Row(
                        children: const [
                          Icon(Icons.event_seat, size: 18),
                          SizedBox(width: 8),
                          Text('Loading reservation…'),
                        ],
                      );
                    }
                    if (snap.hasError || !snap.hasData) {
                      return Row(
                        children: [
                          const Icon(Icons.event_seat, size: 18),
                          const SizedBox(width: 8),
                          Text('Reservation #${order.reservationId}'),
                        ],
                      );
                    }
                    return _ReservationSummary(res: snap.data!);
                  },
                ),
              ),

            const SizedBox(height: 12),

            if (_canCancel || _canEdit) ...[
              const Divider(height: 20),
              if (_working) const LinearProgressIndicator(minHeight: 3),

              Row(
                children: [
                  // EDIT button — ONLY when Preparing
                  if (_canEdit)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit items'),
                        onPressed: _working
                            ? null
                            : () async {
                                if (widget.order.status !=
                                    OrderStatus.preparing) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Only preparing orders can be edited.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final updatedLines = await _showEditItemsSheet(
                                  context,
                                  order,
                                );
                                if (updatedLines == null) return;

                                final uid = context.read<AuthProvider>().userId;
                                if (uid == null) return;

                                setState(() => _working = true);

                                final itemQuantities = <int, int>{};
                                for (final line in updatedLines) {
                                  itemQuantities[line.menuItemId] =
                                      line.quantity;
                                }

                                final prov = context.read<OrderListProvider>();
                                final result = await prov
                                    .updateOrderItemsForUser(
                                      userId: uid,
                                      order: order,
                                      itemQuantities: itemQuantities,
                                    );

                                setState(() => _working = false);
                                if (!mounted) return;

                                if (result != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Order updated.'),
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        prov.error ?? 'Failed to update order.',
                                      ),
                                    ),
                                  );
                                }
                              },
                      ),
                    ),

                  if (_canEdit && _canCancel) const SizedBox(width: 12),

                  // CANCEL button — ONLY when Pending
                  if (_canCancel)
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _working
                            ? null
                            : () async {
                                if (widget.order.status !=
                                    OrderStatus.pending) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Only pending orders can be canceled.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Cancel order?'),
                                    content: const Text(
                                      'You can cancel while the order is pending.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Yes, cancel'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok != true) return;

                                final uid = context.read<AuthProvider>().userId;
                                if (uid == null) return;

                                setState(() => _working = true);
                                final prov = context.read<OrderListProvider>();
                                final success = await prov.cancelOrderForUser(
                                  userId: uid,
                                  order: order,
                                );
                                setState(() => _working = false);
                                if (!mounted) return;

                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Order cancelled.'),
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        prov.error ?? 'Failed to cancel order.',
                                      ),
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<List<_EditableLine>?> _showEditItemsSheet(
    BuildContext context,
    OrderModel order,
  ) {
    final lines = order.orderItems
        .map(
          (it) => _EditableLine(
            menuItemId: it.menuItemId,
            name: it.menuItemName ?? 'Item #${it.menuItemId}',
            unitPrice: it.unitPrice,
            quantity: it.quantity,
          ),
        )
        .toList();
    return showModalBottomSheet<List<_EditableLine>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditItemsSheet(lines: lines),
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
      '${o.total.toStringAsFixed(2)} USD',
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
      case OrderStatus.pending:
        return Colors.amber.shade800;
      case OrderStatus.preparing:
        return Colors.orange.shade800;
      case OrderStatus.ready:
        return Colors.blue.shade700;
      case OrderStatus.completed:
        return Colors.green.shade700;
      case OrderStatus.cancelled:
        return Colors.red.shade600;
    }
  }
}

// ===== Edit items UI =====

class _EditableLine {
  final int menuItemId;
  final String name;
  final double unitPrice;
  int quantity;
  _EditableLine({
    required this.menuItemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
  });
}

class _EditItemsSheet extends StatefulWidget {
  final List<_EditableLine> lines;
  const _EditItemsSheet({required this.lines});

  @override
  State<_EditItemsSheet> createState() => _EditItemsSheetState();
}

class _EditItemsSheetState extends State<_EditItemsSheet> {
  late List<_EditableLine> _lines;

  @override
  void initState() {
    super.initState();
    _lines = widget.lines
        .map(
          (e) => _EditableLine(
            menuItemId: e.menuItemId,
            name: e.name,
            unitPrice: e.unitPrice,
            quantity: e.quantity,
          ),
        )
        .toList();
  }

  double get _total {
    double t = 0;
    for (final l in _lines) {
      t += l.unitPrice * l.quantity;
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
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
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Edit items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _lines.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final l = _lines[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.name),
                    subtitle: Text('${l.unitPrice.toStringAsFixed(2)} USD'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            setState(() {
                              if (l.quantity > 1) {
                                l.quantity -= 1;
                              } else {
                                _lines.removeAt(i);
                              }
                            });
                          },
                        ),
                        Text(
                          l.quantity.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => l.quantity += 1),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_total.toStringAsFixed(2)} USD',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _lines.isEmpty
                        ? null
                        : () => Navigator.pop(context, _lines),
                    child: const Text('Save'),
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

// ===== Reservation summary UI =====

class _ReservationSummary extends StatelessWidget {
  const _ReservationSummary({required this.res});
  final ReservationModel res;

  @override
  Widget build(BuildContext context) {
    final when = _combineToLocal(res.reservationDate, res.reservationTime);
    final whenStr = when != null ? _fmtDt(when) : null;

    final line1Parts = <String>[];
    if (whenStr != null) line1Parts.add(whenStr);
    line1Parts.add('${res.guestCount} guest${res.guestCount == 1 ? '' : 's'}');
    final line1 = line1Parts.join(' • ');

    final line2Parts = <String>[];
    if ((res.tableNumber ?? '').trim().isNotEmpty) {
      line2Parts.add('Table ${res.tableNumber}');
    }
    final statusText = _statusText(res.status);
    if (statusText.isNotEmpty) line2Parts.add(statusText);
    final line2 = line2Parts.join(' • ');

    final note = (res.specialRequests ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.event_seat),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Reservation #${res.id}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    _ResStatusChip(status: res.status),
                  ],
                ),
                if (line1.isNotEmpty) Text(line1),
                if (line2.isNotEmpty)
                  Text(
                    line2,
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                if (note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // helpers

  static DateTime? _combineToLocal(DateTime date, String hhmmss) {
    try {
      final parts = hhmmss.split(':');
      final h = int.parse(parts[0]);
      final m = parts.length > 1 ? int.parse(parts[1]) : 0;
      final s = parts.length > 2 ? int.parse(parts[2]) : 0;
      // If reservationDate is UTC from backend, convert; if it's already local, change this to DateTime(...)
      final utc = DateTime.utc(date.year, date.month, date.day, h, m, s);
      return utc.toLocal();
    } catch (_) {
      return null;
    }
  }

  static String _fmtDt(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  static String _statusText(ReservationStatus s) {
    switch (s) {
      case ReservationStatus.pending:
        return 'Pending';
      case ReservationStatus.confirmed:
        return 'Confirmed';
      case ReservationStatus.cancelled:
        return 'Cancelled';
      case ReservationStatus.completed:
        return 'Completed';
      case ReservationStatus.noShow:
        return 'No-show';
    }
  }
}

class _ResStatusChip extends StatelessWidget {
  const _ResStatusChip({required this.status});
  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Chip(
      label: Text(_ReservationSummary._statusText(status)),
      backgroundColor: color.withOpacity(0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      side: BorderSide(color: color.withOpacity(0.3)),
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static Color _color(ReservationStatus s) {
    switch (s) {
      case ReservationStatus.pending:
        return Colors.amber.shade800;
      case ReservationStatus.confirmed:
        return Colors.blue.shade700;
      case ReservationStatus.completed:
        return Colors.green.shade700;
      case ReservationStatus.cancelled:
        return Colors.red.shade600;
      case ReservationStatus.noShow:
        return Colors.deepOrange.shade700;
    }
  }
}
