import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../layouts/main_layout.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/table_provider.dart';
import '../../widgets/pagination_controls.dart';
import '../../widgets/table_dialogs.dart';
import '../../widgets/restaurant_dialogs.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  final TextEditingController _capacityController = TextEditingController();
  final FocusNode _capacityFocus = FocusNode();
  bool? _isAvailable;

  @override
  void initState() {
    super.initState();
    Provider.of<TableProvider>(context, listen: false).fetchItems();
    Provider.of<RestaurantProvider>(context, listen: false).fetchRestaurant();

    _capacityFocus.addListener(() {
      if (!_capacityFocus.hasFocus) _applyFilters();
    });
  }

  void _applyFilters() {
    final capacity = int.tryParse(_capacityController.text);
    Provider.of<TableProvider>(context, listen: false).setFilters(
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
      child: Consumer2<RestaurantProvider, TableProvider>(
        builder: (context, restaurantProvider, tableProvider, child) {
          if (restaurantProvider.isLoading || tableProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (restaurantProvider.error != null) {
            return Center(child: Text('Error: ${restaurantProvider.error}'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
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
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: () => showEditRestaurantDialog(context),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Name: ${restaurantProvider.restaurant?.name ?? ''}'),
                      if (restaurantProvider.restaurant?.address?.isNotEmpty ?? false)
                        Text('Address: ${restaurantProvider.restaurant!.address}'),
                      if (restaurantProvider.restaurant?.phoneNumber?.isNotEmpty ?? false)
                        Text('Phone: ${restaurantProvider.restaurant!.phoneNumber}'),
                      if (restaurantProvider.restaurant?.email?.isNotEmpty ?? false)
                        Text('Email: ${restaurantProvider.restaurant!.email}'),
                      if (restaurantProvider.restaurant?.description?.isNotEmpty ?? false)
                        Text('Description: ${restaurantProvider.restaurant!.description}'),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => showCreateTableDialog(context),
                      child: const Text('Add Table'),
                    ),
                  ],
                ),
              ),
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
                        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('All')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Available')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Unavailable')),
                      ],
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        _capacityController.clear();
                        setState(() => _isAvailable = null);
                        tableProvider.setFilters();
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tableProvider.items.length,
                  itemBuilder: (context, index) {
                    final table = tableProvider.items[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text('Table #${table.tableNumber}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Capacity: ${table.capacity}'),
                            if (table.location != null && table.location!.isNotEmpty)
                              Text('Location: ${table.location}'),
                            if (table.notes != null && table.notes!.isNotEmpty)
                              Text('Notes: ${table.notes}'),
                          ],
                        ),
                        leading: Icon(
                          table.isAvailable ? Icons.event_seat : Icons.block,
                          color: table.isAvailable ? Colors.green : Colors.red,
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => showUpdateTableDialog(context, table),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              color: Colors.red,
                              onPressed: () => _confirmDelete(context, table.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              PaginationControls(
                currentPage: tableProvider.currentPage,
                totalPages: tableProvider.totalPages,
                pageSize: tableProvider.pageSize,
                onPageChange: (page) => tableProvider.setPage(page),
                onPageSizeChange: (size) => tableProvider.setPageSize(size),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
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
              await context.read<TableProvider>().deleteItem(id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
