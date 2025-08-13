// lib/widgets/order_dialogs/order_dialogs.dart
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';

import '../../models/order_models.dart';
import '../../models/reservation_model.dart';
import '../../models/user_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/menu_item_provider.dart';
import 'order_dialog_helpers.dart' as helpers;

import '../../screens/order_screen/menu_item_multi_select_screen.dart'
    show MenuItemMultiSelectScreen, MenuItemPick;

import '../../core/user_api_service.dart';
import '../../core/menu_item_api_service.dart';
import '../../core/reservation_api_service.dart';

void showCreateOrderDialog(BuildContext context) {
  int? selectedUserId;
  String? userError;
  TextEditingController? userCtrl;

  bool linkReservation = false;
  int? selectedReservationId;
  String? reservationError;
  TextEditingController? reservationCtrl;

  // Rich picks (name+price+qty)
  List<MenuItemPick> picks = [];

  // Helper: if picker returns Map<int,int>, make rich picks from cache
  List<MenuItemPick> _picksFromMap(Map<int, int> map, MenuItemProvider mip) {
    final out = <MenuItemPick>[];
    for (final entry in map.entries) {
      final id = entry.key;
      final qty = entry.value;
      final mi = mip.items.firstWhere(
        (m) => m.id == id,
        orElse: () => throw StateError('Menu item $id not found in cache'),
      );
      out.add(
        MenuItemPick(id: id, name: mi.name, unitPrice: mi.price, qty: qty),
      );
    }
    return out;
  }

  Future<void> _openPicker() async {
    final mip = context.read<MenuItemProvider>();
    final dynamic result = await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const MenuItemMultiSelectScreen(),
      ),
    );

    if (result == null) return;

    if (result is List<MenuItemPick>) {
      picks = result;
    } else if (result is Map<int, int>) {
      // fallback for picker returning {id: qty}
      try {
        picks = _picksFromMap(result, mip);
      } catch (_) {
        // if something missed in cache, just show ids
        picks = result.entries
            .map(
              (e) => MenuItemPick(
                id: e.key,
                name: 'Item #${e.key}',
                unitPrice: 0,
                qty: e.value,
              ),
            )
            .toList();
      }
    }
  }

  bool _validate() {
    userError = selectedUserId == null ? 'Please select a user' : null;
    return selectedUserId != null && picks.isNotEmpty;
  }

  List<int> _buildMenuItemIds() {
    final ids = <int>[];
    for (final p in picks) {
      for (var i = 0; i < p.qty; i++) ids.add(p.id);
    }
    return ids;
  }

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Create Order'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // USER
                    TypeAheadField<UserModel>(
                      suggestionsCallback: helpers.searchUsers,
                      itemBuilder: (context, u) => ListTile(
                        title: Text(helpers.displayUser(u)),
                        subtitle: u.email.isNotEmpty ? Text(u.email) : null,
                        trailing: Text('ID: ${u.id}'),
                      ),
                      onSelected: (u) {
                        selectedUserId = u.id;
                        userError = null;
                        userCtrl?.text = helpers.displayUser(u);
                        // reset reservation on user change
                        selectedReservationId = null;
                        reservationCtrl?.clear();
                        setState(() {});
                      },
                      builder: (context, controller, focusNode) {
                        userCtrl ??= controller;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'User (email/name)',
                            isDense: true,
                            errorText: userError,
                          ),
                          onChanged: (_) {
                            selectedUserId = null;
                            userError = null;
                            selectedReservationId = null;
                            reservationCtrl?.clear();
                          },
                        );
                      },
                      debounceDuration: const Duration(milliseconds: 300),
                    ),
                    const SizedBox(height: 12),

                    // RESERVATION (optional)
                    SwitchListTile(
                      value: linkReservation,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Link to existing reservation (optional)',
                      ),
                      onChanged: (v) {
                        setState(() {
                          linkReservation = v;
                          if (!linkReservation) {
                            selectedReservationId = null;
                            reservationCtrl?.clear();
                            reservationError = null;
                          }
                        });
                      },
                    ),
                    if (linkReservation)
                      TypeAheadField<ReservationModel>(
                        suggestionsCallback: (q) => helpers.searchReservations(
                          query: q,
                          userId: selectedUserId,
                        ),
                        itemBuilder: (context, r) => ListTile(
                          title: Text(helpers.displayReservation(r)),
                          trailing: Text('ID: ${r.id}'),
                        ),
                        onSelected: (r) {
                          selectedReservationId = r.id;
                          reservationError = null;
                          reservationCtrl?.text = helpers.displayReservation(r);
                          setState(() {});
                        },
                        builder: (context, controller, focusNode) {
                          reservationCtrl ??= controller;
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            readOnly: selectedUserId == null,
                            decoration: InputDecoration(
                              labelText: selectedUserId == null
                                  ? 'Select user first'
                                  : 'Search reservations',
                              isDense: true,
                              errorText: reservationError,
                            ),
                            onChanged: (_) {
                              selectedReservationId = null;
                              reservationError = null;
                            },
                          );
                        },
                        debounceDuration: const Duration(milliseconds: 250),
                      ),
                    const SizedBox(height: 12),

                    // MENU ITEMS PICKER
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await _openPicker();
                          setState(() {});
                        },
                        icon: const Icon(Icons.restaurant_menu),
                        label: const Text('Select menu items'),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Summary
                    if (picks.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('No items selected.'),
                      )
                    else
                      Column(
                        children: picks
                            .map(
                              (p) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(p.name),
                                subtitle: Text(
                                  'ID: ${p.id} • ${p.unitPrice.toStringAsFixed(2)}',
                                ),
                                trailing: Text('x${p.qty}'),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!_validate()) {
                    setState(() {});
                    return;
                  }
                  final req = OrderCreateRequestModel(
                    userId: selectedUserId!,
                    reservationId: linkReservation
                        ? selectedReservationId
                        : null,
                    menuItemIds: _buildMenuItemIds(),
                  );
                  final created = await ctx.read<OrderProvider>().createOrder(
                    req,
                  );
                  if (created != null && ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      );
    },
  );
}

void showUpdateOrderDialog(BuildContext context, OrderModel order) {
  int? selectedUserId = order.userId;
  String? userError;
  final userCtrl = TextEditingController(text: 'User #${order.userId}');

  bool linkReservation = order.reservationId != null;
  int? selectedReservationId = order.reservationId;
  String? reservationError;
  final reservationCtrl = TextEditingController(
    text: order.reservationId == null
        ? ''
        : 'Reservation #${order.reservationId}',
  );

  // status can be edited now
  OrderStatus status = order.status;

  // Build picks from existing order items (fallback names from cache)
  final cache = context.read<MenuItemProvider>().items;
  String _nameFor(int id) {
    final i = cache.indexWhere((m) => m.id == id);
    return i == -1 ? 'Item #$id' : cache[i].name;
  }

  List<MenuItemPick> picks = order.orderItems
      .map(
        (it) => MenuItemPick(
          id: it.menuItemId,
          name: _nameFor(it.menuItemId),
          unitPrice: it.unitPrice,
          qty: it.quantity,
        ),
      )
      .toList();

  // Services for prefill (nice names)
  final userApi = UserApiService();
  final menuApi = MenuItemApiService();
  final reservationApi = ReservationApiService();

  // If picker returns a Map<int,int>, convert it
  List<MenuItemPick> _picksFromMap(Map<int, int> map) {
    final out = <MenuItemPick>[];
    for (final e in map.entries) {
      final id = e.key;
      final qty = e.value;
      final cached = cache.firstWhere(
        (m) => m.id == id,
        orElse: () => throw StateError('Menu item $id missing from cache'),
      );
      out.add(
        MenuItemPick(
          id: id,
          name: cached.name,
          unitPrice: cached.price,
          qty: qty,
        ),
      );
    }
    return out;
  }

  Future<void> _openPicker() async {
    final initial = <int, int>{};
    for (final p in picks) {
      initial.update(p.id, (v) => v + p.qty, ifAbsent: () => p.qty);
    }

    final dynamic result = await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MenuItemMultiSelectScreen(initialSelection: initial),
      ),
    );

    if (result == null) return;

    if (result is List<MenuItemPick>) {
      picks = result;
    } else if (result is Map<int, int>) {
      try {
        picks = _picksFromMap(result);
      } catch (_) {
        picks = result.entries
            .map(
              (e) => MenuItemPick(
                id: e.key,
                name: 'Item #${e.key}',
                unitPrice: 0,
                qty: e.value,
              ),
            )
            .toList();
      }
    }
  }

  bool _validate() {
    userError = selectedUserId == null ? 'Please select a user' : null;
    return selectedUserId != null && picks.isNotEmpty;
  }

  List<int> _buildMenuItemIds() {
    final ids = <int>[];
    for (final p in picks) {
      for (var i = 0; i < p.qty; i++) ids.add(p.id);
    }
    return ids;
  }

  var _didPrefill = false;

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          // Prefill once
          if (!_didPrefill) {
            _didPrefill = true;
            Future.microtask(() async {
              try {
                final u = await userApi.getById(order.userId);
                userCtrl.text = helpers.displayUser(u);

                if (order.reservationId != null) {
                  final r = await reservationApi.getById(order.reservationId!);
                  reservationCtrl.text = helpers.displayReservation(r);
                }

                final unresolvedIds = picks
                    .where((p) => p.name.startsWith('Item #'))
                    .map((p) => p.id)
                    .toSet()
                    .toList();

                if (unresolvedIds.isNotEmpty) {
                  final fetched = await Future.wait(
                    unresolvedIds.map((id) async {
                      final mi = await menuApi.getById(id);
                      return {'id': id, 'name': mi.name, 'price': mi.price};
                    }),
                  );

                  final byId = <int, Map<String, dynamic>>{};
                  for (final row in fetched) {
                    byId[row['id'] as int] = row;
                  }

                  if (byId.isNotEmpty) {
                    for (var i = 0; i < picks.length; i++) {
                      final p = picks[i];
                      final m = byId[p.id];
                      if (m != null) {
                        picks[i] = MenuItemPick(
                          id: p.id,
                          name: (m['name'] as String),
                          unitPrice: (m['price'] as num).toDouble(),
                          qty: p.qty,
                        );
                      }
                    }
                  }
                }
              } catch (_) {
                // ignore
              } finally {
                if (ctx.mounted) setState(() {});
              }
            });
          }

          return AlertDialog(
            title: Text('Update Order #${order.id}'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // USER
                    TypeAheadField<UserModel>(
                      suggestionsCallback: helpers.searchUsers,
                      itemBuilder: (context, u) => ListTile(
                        title: Text(helpers.displayUser(u)),
                        subtitle: u.email.isNotEmpty ? Text(u.email) : null,
                        trailing: Text('ID: ${u.id}'),
                      ),
                      onSelected: (u) {
                        selectedUserId = u.id;
                        userError = null;
                        userCtrl.text = helpers.displayUser(u);
                        selectedReservationId = null;
                        reservationCtrl.clear();
                        setState(() {});
                      },
                      builder: (context, controller, focusNode) {
                        controller.text = userCtrl.text;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'User (email/name)',
                            isDense: true,
                            errorText: userError,
                          ),
                          onChanged: (_) {
                            selectedUserId = null;
                            userError = null;
                            selectedReservationId = null;
                            reservationCtrl.clear();
                          },
                        );
                      },
                      debounceDuration: const Duration(milliseconds: 300),
                    ),
                    const SizedBox(height: 12),

                    // STATUS (editable on update)
                    DropdownButtonFormField<OrderStatus>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(
                          value: OrderStatus.pending,
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: OrderStatus.preparing,
                          child: Text('Preparing'),
                        ),
                        DropdownMenuItem(
                          value: OrderStatus.ready,
                          child: Text('Ready'),
                        ),
                        DropdownMenuItem(
                          value: OrderStatus.completed,
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: OrderStatus.cancelled,
                          child: Text('Cancelled'),
                        ),
                      ],
                      onChanged: (v) => setState(() => status = v ?? status),
                    ),
                    const SizedBox(height: 12),

                    // RESERVATION (optional)
                    SwitchListTile(
                      value: linkReservation,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Link to existing reservation (optional)',
                      ),
                      onChanged: (v) {
                        setState(() {
                          linkReservation = v;
                          if (!linkReservation) {
                            selectedReservationId = null;
                            reservationCtrl.clear();
                            reservationError = null;
                          }
                        });
                      },
                    ),
                    if (linkReservation)
                      TypeAheadField<ReservationModel>(
                        suggestionsCallback: (q) => helpers.searchReservations(
                          query: q,
                          userId: selectedUserId,
                        ),
                        itemBuilder: (context, r) => ListTile(
                          title: Text(helpers.displayReservation(r)),
                          trailing: Text('ID: ${r.id}'),
                        ),
                        onSelected: (r) {
                          selectedReservationId = r.id;
                          reservationError = null;
                          reservationCtrl.text = helpers.displayReservation(r);
                          setState(() {});
                        },
                        builder: (context, controller, focusNode) {
                          controller.text = reservationCtrl.text;
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            readOnly: selectedUserId == null,
                            decoration: InputDecoration(
                              labelText: selectedUserId == null
                                  ? 'Select user first'
                                  : 'Search reservations',
                              isDense: true,
                              errorText: reservationError,
                            ),
                            onChanged: (_) {
                              selectedReservationId = null;
                              reservationError = null;
                            },
                          );
                        },
                        debounceDuration: const Duration(milliseconds: 250),
                      ),
                    const SizedBox(height: 12),

                    // MENU ITEMS PICKER
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await _openPicker();
                          setState(() {});
                        },
                        icon: const Icon(Icons.restaurant_menu),
                        label: const Text('Edit menu items'),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Summary
                    if (picks.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('No items selected.'),
                      )
                    else
                      Column(
                        children: picks
                            .map(
                              (p) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(p.name),
                                subtitle: Text(
                                  'ID: ${p.id} • ${p.unitPrice.toStringAsFixed(2)}',
                                ),
                                trailing: Text('x${p.qty}'),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!_validate()) {
                    setState(() {});
                    return;
                  }
                  final req = OrderUpdateRequestModel(
                    userId: selectedUserId!,
                    reservationId: linkReservation
                        ? selectedReservationId
                        : null,
                    status: status,
                    menuItemIds: _buildMenuItemIds(),
                  );
                  final updated = await ctx.read<OrderProvider>().updateOrder(
                    order.id,
                    req,
                  );
                  if (updated != null && ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      );
    },
  );
}
