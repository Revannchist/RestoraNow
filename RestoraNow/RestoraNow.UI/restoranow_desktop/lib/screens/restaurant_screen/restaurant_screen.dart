import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../layouts/main_layout.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/table_provider.dart';
import '../../widgets/pagination_controls.dart';

import '../../widgets/table_dialogs.dart' as tbl;
import '../../widgets/restaurant_dialogs.dart' as rest;

// overlays
import '../../widgets/helpers/error_dialog_helper.dart' as msg;
import '../../core/api_exception.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  final TextEditingController _capacityController = TextEditingController();
  final FocusNode _capacityFocus = FocusNode();
  bool? _isAvailable;

  String? _lastTableError;
  String? _lastRestaurantError;

  @override
  void initState() {
    super.initState();
    context.read<TableProvider>().fetchItems();
    context.read<RestaurantProvider>().fetchRestaurant();

    _capacityFocus.addListener(() {
      if (!_capacityFocus.hasFocus) _applyFilters();
    });
  }

  void _applyFilters() {
    final capacity = int.tryParse(_capacityController.text);
    context.read<TableProvider>().setFilters(
      capacity: capacity,
      isAvailable: _isAvailable,
    );
  }

  @override
  void dispose() {
    _capacityFocus.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------- Restaurant card only rebuilds on RestaurantProvider changes
          Consumer<RestaurantProvider>(
            builder: (context, rp, _) {
              if (rp.error != null &&
                  rp.error!.isNotEmpty &&
                  rp.error != _lastRestaurantError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  msg.showOverlayMessage(context, rp.error!);
                  _lastRestaurantError = rp.error;
                });
              }
              final r = rp.restaurant;
              return Card(
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Restaurant Info',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                rest.showEditRestaurantDialog(context),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Name: ${r?.name ?? ''}'),
                      if ((r?.address?.isNotEmpty ?? false))
                        Text('Address: ${r!.address}'),
                      if ((r?.phoneNumber?.isNotEmpty ?? false))
                        Text('Phone: ${r!.phoneNumber}'),
                      if ((r?.email?.isNotEmpty ?? false))
                        Text('Email: ${r!.email}'),
                      if ((r?.description?.isNotEmpty ?? false))
                        Text('Description: ${r!.description}'),
                    ],
                  ),
                ),
              );
            },
          ),

          // -------- Add button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => tbl.showCreateTableDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Table'),
                ),
              ],
            ),
          ),

          // -------- Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _capacityController,
                    focusNode: _capacityFocus,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Search by minimum capacity',
                    ),
                    onSubmitted: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 8),
                ToggleButtons(
                  isSelected: [
                    _isAvailable == null,
                    _isAvailable == true,
                    _isAvailable == false,
                  ],
                  onPressed: (index) {
                    setState(() => _isAvailable = [null, true, false][index]);
                    _applyFilters();
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('All'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Available'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Unavailable'),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Consumer<TableProvider>(
                  builder: (_, tp, __) => TextButton(
                    onPressed: () {
                      _capacityController.clear();
                      setState(() => _isAvailable = null);
                      tp.setFilters(); // clears filters
                    },
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // -------- Tables list + pagination (only rebuilds on TableProvider)
          Expanded(
            child: Consumer<TableProvider>(
              builder: (context, tp, _) {
                if (tp.error != null &&
                    tp.error!.isNotEmpty &&
                    tp.error != _lastTableError) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    msg.showOverlayMessage(context, tp.error!);
                    _lastTableError = tp.error;
                  });
                }

                final isFirstLoad = tp.isLoading && tp.items.isEmpty;

                return Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: isFirstLoad
                          ? const Center(child: CircularProgressIndicator())
                          : (tp.items.isEmpty
                                ? const Center(child: Text('No tables found'))
                                : ListView.builder(
                                    key: ValueKey(tp.items.length),
                                    itemCount: tp.items.length,
                                    itemBuilder: (context, index) {
                                      final t = tp.items[index];
                                      return Card(
                                        color: Theme.of(context).cardColor,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: ListTile(
                                          title: Text(
                                            'Table #${t.tableNumber}',
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Capacity: ${t.capacity}'),
                                              if ((t.location?.isNotEmpty ??
                                                  false))
                                                Text('Location: ${t.location}'),
                                              if ((t.notes?.isNotEmpty ??
                                                  false))
                                                Text('Notes: ${t.notes}'),
                                            ],
                                          ),
                                          leading: Icon(
                                            t.isAvailable
                                                ? Icons.event_seat
                                                : Icons.block,
                                            color: t.isAvailable
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                          trailing: Wrap(
                                            spacing: 4,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  size: 18,
                                                ),
                                                onPressed: () =>
                                                    tbl.showUpdateTableDialog(
                                                      context,
                                                      t,
                                                    ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  size: 18,
                                                ),
                                                color: Colors.red,
                                                onPressed: () => _confirmDelete(
                                                  context,
                                                  t.id,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  )),
                    ),

                    if (tp.isLoading && tp.items.isNotEmpty)
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
          ),

          // Pagination
          Consumer<TableProvider>(
            builder: (context, tp, _) => PaginationControls(
              currentPage: tp.currentPage,
              totalPages: tp.totalPages,
              pageSize: tp.pageSize,
              onPageChange: (page) => tp.setPage(page),
              onPageSizeChange: (size) => tp.setPageSize(size),
            ),
          ),
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
        content: const Text('Are you sure you want to delete this table?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<TableProvider>().deleteItem(id);
                if (mounted) {
                  Navigator.pop(context);
                  msg.showOverlayMessage(
                    context,
                    'Table deleted',
                    type: msg.AppMessageType.success,
                  );
                }
              } on ApiException catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                msg.showAnyErrorOnTop(context, e);
              } catch (_) {
                if (!mounted) return;
                Navigator.pop(context);
                msg.showOverlayMessage(
                  context,
                  'Something went wrong. Please try again.',
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
