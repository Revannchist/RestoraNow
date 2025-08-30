import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';

import '../../layouts/main_layout.dart';
import '../../providers/order_provider.dart';
import '../../widgets/pagination_controls.dart';
import '../../widgets/order_dialogs/order_dialogs.dart';

import '../../models/order_models.dart';
import '../../models/user_model.dart';
import '../../widgets/order_dialogs/order_dialog_helpers.dart' as helpers;

// overlay toasts
import '../../widgets/helpers/error_dialog_helper.dart' as msg;
import '../../core/api_exception.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // User filter (typeahead)
  final TextEditingController _userCtrl = TextEditingController();
  int? _selectedUserId;
  String? _userError;

  // Status + Date range
  OrderStatus? _status; // enum
  DateTimeRange? _range;

  // guard so we don’t spam overlays
  String? _lastErrorShown;

  // track per-order busy state when changing status
  final Set<int> _busyOrders = <int>{};

  @override
  void initState() {
    super.initState();
    Provider.of<OrderProvider>(context, listen: false).fetchOrders();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    super.dispose();
  }

  // ---- Helpers ----
  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  void _applyFilters() {
    final from = _range == null ? null : _startOfDay(_range!.start);
    final to   = _range == null ? null : _endOfDay(_range!.end);

    Provider.of<OrderProvider>(context, listen: false).setFilters(
      userId: _selectedUserId,
      status: _status,
      fromDate: from,
      toDate: to,
    );
  }

  void _setQuickRangeToday() {
    final now = DateTime.now();
    setState(() => _range = DateTimeRange(start: _startOfDay(now), end: _endOfDay(now)));
    _applyFilters();
  }

  void _setQuickRangeLastNDays(int n) {
    final now = DateTime.now();
    final start = _startOfDay(now.subtract(Duration(days: n - 1)));
    final end   = _endOfDay(now);
    setState(() => _range = DateTimeRange(start: start, end: end));
    _applyFilters();
  }

  void _setQuickRangeThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final nextMonth = (now.month == 12)
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);
    final end = _endOfDay(nextMonth.subtract(const Duration(days: 1)));
    setState(() => _range = DateTimeRange(start: start, end: end));
    _applyFilters();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial = _range ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initial,
      useRootNavigator: true,
    );

    if (picked != null) {
      setState(() => _range = picked);
      _applyFilters();
    }
  }

  void _resetFilters() {
    _userCtrl.clear();
    _selectedUserId = null;
    _userError = null;

    setState(() {
      _status = null;
      _range = null;
    });

    Provider.of<OrderProvider>(context, listen: false).setFilters();
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return "${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year} "
        "${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}";
  }

  double _orderTotal(Iterable<OrderItemModel> items) {
    double sum = 0;
    for (final it in items) {
      sum += (it.totalPrice ?? (it.quantity * it.unitPrice));
    }
    return sum;
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.ready:
        return Colors.teal;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  // ---------- Inline status change ----------
  List<_StatusAction> _actionsFor(OrderStatus current) {
    final actions = <_StatusAction>[];
    switch (current) {
      case OrderStatus.pending:
        actions.add(_StatusAction(OrderStatus.preparing, 'Move to Preparing', Icons.play_arrow_rounded));
        break;
      case OrderStatus.preparing:
        actions.add(_StatusAction(OrderStatus.ready, 'Mark Ready', Icons.check_rounded));
        break;
      case OrderStatus.ready:
        actions.add(_StatusAction(OrderStatus.completed, 'Complete Order', Icons.check_circle_rounded));
        break;
      case OrderStatus.completed:
        break;
      case OrderStatus.cancelled:
        break;
    }
    if (current != OrderStatus.cancelled) {
      actions.add(_StatusAction(OrderStatus.cancelled, 'Cancel Order', Icons.cancel_rounded));
    }
    return actions;
  }

  Future<void> _changeStatusInline(int orderId, OrderStatus target) async {
    if (_busyOrders.contains(orderId)) return;
    setState(() => _busyOrders.add(orderId));
    try {
      await context.read<OrderProvider>().changeStatus(orderId, target);
      if (!mounted) return;
      msg.showOverlayMessage(
        context,
        'Status updated to ${orderStatusToString(target)}',
        type: msg.AppMessageType.success,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      msg.showAnyErrorOnTop(context, e);
    } catch (_) {
      if (!mounted) return;
      msg.showOverlayMessage(context, 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busyOrders.remove(orderId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          // show provider errors as overlay (once)
          if (provider.error != null &&
              provider.error!.isNotEmpty &&
              provider.error != _lastErrorShown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              msg.showOverlayMessage(context, provider.error!);
              _lastErrorShown = provider.error;
            });
          }

          final isFirstLoad = provider.isLoading && provider.items.isEmpty;

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Actions
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => showCreateOrderDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Order'),
                        ),
                      ],
                    ),
                  ),

                  // Filters
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // ---- User typeahead (filters by picked user ID) ----
                        SizedBox(
                          width: 260,
                          child: TypeAheadField<UserModel>(
                            suggestionsCallback: helpers.searchUsers,
                            itemBuilder: (context, u) => ListTile(
                              dense: true,
                              title: Text(helpers.displayUser(u)),
                              subtitle: u.email.isNotEmpty ? Text(u.email) : null,
                              trailing: Text('ID: ${u.id}'),
                            ),
                            onSelected: (u) {
                              _selectedUserId = u.id;
                              _userError = null;
                              _userCtrl.text = helpers.displayUser(u);
                              _applyFilters();
                            },
                            builder: (context, controller, focusNode) {
                              controller.text = _userCtrl.text;
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Filter by User (email/name)',
                                  isDense: true,
                                  errorText: _userError,
                                  suffixIcon: _userCtrl.text.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'Clear',
                                          onPressed: () {
                                            _userCtrl.clear();
                                            _selectedUserId = null;
                                            _applyFilters();
                                          },
                                          icon: const Icon(Icons.close),
                                        ),
                                ),
                                onChanged: (_) {
                                  _selectedUserId = null;
                                  if (_userError != null) setState(() => _userError = null);
                                },
                                onSubmitted: (_) {
                                  final maybeId = int.tryParse(_userCtrl.text.trim());
                                  _selectedUserId = maybeId;
                                  _applyFilters();
                                },
                              );
                            },
                            debounceDuration: const Duration(milliseconds: 300),
                          ),
                        ),

                        // ---- Status ----
                        DropdownButton<OrderStatus?>(
                          value: _status,
                          hint: const Text('Status'),
                          onChanged: (v) {
                            setState(() => _status = v);
                            _applyFilters();
                          },
                          items: const [
                            DropdownMenuItem<OrderStatus?>(value: null, child: Text('All')),
                            DropdownMenuItem<OrderStatus?>(value: OrderStatus.pending, child: Text('Pending')),
                            DropdownMenuItem<OrderStatus?>(value: OrderStatus.preparing, child: Text('Preparing')),
                            DropdownMenuItem<OrderStatus?>(value: OrderStatus.ready, child: Text('Ready')),
                            DropdownMenuItem<OrderStatus?>(value: OrderStatus.completed, child: Text('Completed')),
                            DropdownMenuItem<OrderStatus?>(value: OrderStatus.cancelled, child: Text('Cancelled')),
                          ],
                        ),

                        // ---- Quick date chips ----
                        Wrap(
                          spacing: 6,
                          children: [
                            ChoiceChip(
                              label: const Text('Today'),
                              selected: _range != null &&
                                  _startOfDay(DateTime.now()) == _startOfDay(_range!.start) &&
                                  _startOfDay(DateTime.now()) == _startOfDay(_range!.end),
                              onSelected: (_) => _setQuickRangeToday(),
                            ),
                            ChoiceChip(
                              label: const Text('Last 7 days'),
                              selected: false,
                              onSelected: (_) => _setQuickRangeLastNDays(7),
                            ),
                            ChoiceChip(
                              label: const Text('This month'),
                              selected: false,
                              onSelected: (_) => _setQuickRangeThisMonth(),
                            ),
                          ],
                        ),

                        // ---- Custom range ----
                        OutlinedButton.icon(
                          onPressed: _pickDateRange,
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _range == null
                                ? 'Custom range'
                                : '${_range!.start.toLocal().toString().substring(0, 10)} → '
                                  '${_range!.end.toLocal().toString().substring(0, 10)}',
                          ),
                        ),

                        TextButton(onPressed: _resetFilters, child: const Text('Reset')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Orders list
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: isFirstLoad
                          ? const Center(child: CircularProgressIndicator())
                          : (provider.items.isEmpty
                              ? const Center(child: Text('No orders found'))
                              : ListView.builder(
                                  key: ValueKey(provider.items.length),
                                  itemCount: provider.items.length,
                                  itemBuilder: (context, index) {
                                    final order = provider.items[index];
                                    final total = _orderTotal(order.orderItems);
                                    final actions = _actionsFor(order.status);
                                    final isBusy = _busyOrders.contains(order.id);

                                    return Card(
                                      color: Theme.of(context).cardColor,
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: ExpansionTile(
                                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                                        title: Row(
                                          children: [
                                            Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 8),
                                            Chip(
                                              label: Text(orderStatusToString(order.status)),
                                              backgroundColor: _statusColor(order.status).withOpacity(0.12),
                                              labelStyle: TextStyle(
                                                color: _statusColor(order.status),
                                                fontWeight: FontWeight.w600,
                                              ),
                                              visualDensity: VisualDensity.compact,
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                        subtitle: Text(
                                          'User: ${order.userName ?? 'User #${order.userId}'} • '
                                          '${_formatDate(order.createdAt)} • '
                                          'Total: ${total.toStringAsFixed(2)}',
                                        ),
                                        trailing: Wrap(
                                          spacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            // <-- status menu to the LEFT of the pen
                                            if (isBusy)
                                              const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: Padding(
                                                  padding: EdgeInsets.all(2),
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              )
                                            else if (actions.isNotEmpty)
                                              PopupMenuButton<_StatusAction>(
                                                tooltip: 'Change status',
                                                icon: const Icon(Icons.sync_alt, size: 18),
                                                itemBuilder: (ctx) => actions
                                                    .map(
                                                      (a) => PopupMenuItem<_StatusAction>(
                                                        value: a,
                                                        child: Row(
                                                          children: [
                                                            Icon(a.icon, size: 18),
                                                            const SizedBox(width: 8),
                                                            Text(a.label),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                                onSelected: (a) => _changeStatusInline(order.id, a.target),
                                              ),

                                            // pen (edit)
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 18),
                                              onPressed: () => showUpdateOrderDialog(context, order),
                                            ),

                                            // delete
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 18),
                                              color: Colors.red,
                                              onPressed: () => _confirmDelete(context, order.id),
                                            ),
                                          ],
                                        ),
                                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                        children: [
                                          if (order.orderItems.isEmpty)
                                            const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text('No items in this order.'),
                                            )
                                          else
                                            Column(
                                              children: [
                                                const SizedBox(height: 8),
                                                _buildItemsHeader(context),
                                                const Divider(height: 16),
                                                ...order.orderItems.map(_buildItemRow).toList(),
                                                const Divider(height: 16),
                                                Align(
                                                  alignment: Alignment.centerRight,
                                                  child: Text(
                                                    'Order Total: ${total.toStringAsFixed(2)}',
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                )),
                    ),
                  ),

                  // Pagination
                  PaginationControls(
                    currentPage: provider.currentPage,
                    totalPages: provider.totalPages,
                    pageSize: provider.pageSize,
                    onPageChange: (page) => provider.setPage(page),
                    onPageSizeChange: (size) => provider.setPageSize(size),
                  ),
                ],
              ),

              // slim loader on top while paging/filtering
              if (provider.isLoading && provider.items.isNotEmpty)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemsHeader(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('Item', style: style)),
          Expanded(flex: 2, child: Text('Qty', style: style)),
          Expanded(flex: 3, child: Text('Unit Price', style: style)),
          Expanded(flex: 3, child: Text('Line Total', style: style)),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItemModel it) {
    final lineTotal = (it.totalPrice ?? (it.quantity * it.unitPrice)).toDouble();
    final title = (it.menuItemName == null || it.menuItemName!.isEmpty) ? '#${it.menuItemId}' : it.menuItemName!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(title)),
          Expanded(flex: 2, child: Text('${it.quantity}')),
          Expanded(flex: 3, child: Text(it.unitPrice.toStringAsFixed(2))),
          Expanded(flex: 3, child: Text(lineTotal.toStringAsFixed(2))),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await context.read<OrderProvider>().deleteOrder(id);
                if (!mounted) return;
                Navigator.pop(context);
                msg.showOverlayMessage(context, 'Order deleted', type: msg.AppMessageType.success);
              } on ApiException catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                msg.showAnyErrorOnTop(context, e);
              } catch (_) {
                if (!mounted) return;
                Navigator.pop(context);
                msg.showOverlayMessage(context, 'Something went wrong. Please try again.');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Small helper for popup actions
class _StatusAction {
  final OrderStatus target;
  final String label;
  final IconData icon;
  const _StatusAction(this.target, this.label, this.icon);
}
