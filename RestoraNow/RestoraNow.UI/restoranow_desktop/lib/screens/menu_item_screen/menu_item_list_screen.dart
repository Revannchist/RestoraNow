import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../layouts/main_layout.dart';
import '../../providers/menu_item_provider.dart';
import '../../providers/menu_item_image_provider.dart';
import '../../widgets/menu_item_dialogs.dart';
import '../../widgets/pagination_controls.dart';

class MenuItemListScreen extends StatefulWidget {
  const MenuItemListScreen({super.key});

  @override
  State<MenuItemListScreen> createState() => _MenuItemListScreenState();
}

class _MenuItemListScreenState extends State<MenuItemListScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  bool? _isAvailable;
  bool? _isSpecial;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<MenuItemProvider>(context, listen: false);
    final imageProvider = Provider.of<MenuItemImageProvider>(context, listen: false);

    provider.fetchItems().then((_) {
      for (var item in provider.items) {
        imageProvider.fetchImages(item.id);
      }
    });

    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) _applyFilters();
    });
  }

  void _applyFilters() {
    Provider.of<MenuItemProvider>(context, listen: false).setFilters(
      name: _nameController.text,
      isAvailable: _isAvailable,
      isSpecial: _isSpecial,
    );
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Consumer2<MenuItemProvider, MenuItemImageProvider>(
        builder: (context, provider, imageProvider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        decoration: const InputDecoration(
                          labelText: 'Search by name',
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
                    ToggleButtons(
                      isSelected: [
                        _isSpecial == null,
                        _isSpecial == true,
                        _isSpecial == false,
                      ],
                      onPressed: (index) {
                        setState(() => _isSpecial = [null, true, false][index]);
                        _applyFilters();
                      },
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('All')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Special')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Regular')),
                      ],
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => showCreateMenuItemDialog(context),
                      child: const Text('Add Menu Item'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.items.length,
                  itemBuilder: (context, index) {
                    final item = provider.items[index];
                    final images = imageProvider.getImagesForMenuItem(item.id);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text('${item.categoryName} - \$${item.price.toStringAsFixed(2)}'),
                        leading: images.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.memory(
                                  _decodeBase64Image(images.first.url),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.fastfood),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => showUpdateMenuItemDialog(context, item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              color: Colors.red,
                              onPressed: () => _confirmDelete(context, item.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              PaginationControls(
                currentPage: provider.currentPage,
                totalPages: provider.totalPages,
                pageSize: provider.pageSize,
                onPageChange: (page) => provider.setPage(page),
                onPageSizeChange: (size) => provider.setPageSize(size),
              ),
            ],
          );
        },
      ),
    );
  }

  Uint8List _decodeBase64Image(String base64String) {
    final regex = RegExp(r'data:image/[^;]+;base64,');
    final cleaned = base64String.replaceAll(regex, '');
    return base64Decode(cleaned);
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this menu item?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await context.read<MenuItemProvider>().deleteItem(id);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
