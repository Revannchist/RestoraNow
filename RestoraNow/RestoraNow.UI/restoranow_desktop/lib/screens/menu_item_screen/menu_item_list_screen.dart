import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../layouts/main_layout.dart';
import '../../providers/menu_item_provider.dart';
import '../../providers/menu_item_image_provider.dart';
import '../../providers/menu_category_provider.dart';
import '../../widgets/menu_item_dialogs.dart';
import '../../widgets/pagination_controls.dart';
import '../../models/menu_item_model.dart';

// Errors/snacks
import '../../widgets/helpers/error_dialog_helper.dart' as msg;
import '../../core/api_exception.dart';

class MenuItemListScreen extends StatefulWidget {
  const MenuItemListScreen({super.key});

  @override
  State<MenuItemListScreen> createState() => _MenuItemListScreenState();
}

class _MenuItemListScreenState extends State<MenuItemListScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  Timer? _debounce;

  bool? _isAvailable;
  bool? _isSpecial;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MenuItemProvider>();
    final imageProvider = context.read<MenuItemImageProvider>();
    final categoryProvider = context.read<MenuCategoryProvider>();

    categoryProvider.fetchCategories(); // preload categories

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
    context.read<MenuItemProvider>().setFilters(
          name: _nameController.text,
          isAvailable: _isAvailable,
          isSpecial: _isSpecial,
          categoryId: _selectedCategoryId,
        );
  }

  void _debouncedApply(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _applyFilters);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameFocus.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Consumer3<MenuItemProvider, MenuItemImageProvider, MenuCategoryProvider>(
        builder: (context, provider, imageProvider, categoryProvider, child) {
          final isFirstLoad = provider.isLoading && provider.items.isEmpty;

          return Column(
            children: [
              // Add button
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => showCreateMenuItemDialog(context),
                      child: const Text('Add Menu Item'),
                    ),
                  ],
                ),
              ),

              // Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        decoration: const InputDecoration(
                          labelText: 'Search by name',
                        ),
                        onChanged: _debouncedApply,
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Category
                    DropdownButton<int?>(
                      value: _selectedCategoryId,
                      hint: const Text('Category'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('All categories')),
                        ...categoryProvider.categories.map(
                          (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedCategoryId = v);
                        _applyFilters();
                      },
                    ),
                    const SizedBox(width: 8),

                    // Available
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

                    // Special
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

                    TextButton(
                      onPressed: () {
                        _nameController.clear();
                        setState(() {
                          _isAvailable = null;
                          _isSpecial = null;
                          _selectedCategoryId = null;
                        });
                        context.read<MenuItemProvider>().setFilters();
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),

              // List + overlay loader + errors
              Expanded(
                child: Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: isFirstLoad
                          ? const Center(child: CircularProgressIndicator())
                          : _buildListOrState(context, provider, imageProvider, categoryProvider),
                    ),

                    if (provider.isLoading && provider.items.isNotEmpty)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                  ],
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
          );
        },
      ),
    );
  }

  Widget _buildListOrState(
    BuildContext context,
    MenuItemProvider provider,
    MenuItemImageProvider imageProvider,
    MenuCategoryProvider categoryProvider,
  ) {
    if (provider.error != null && provider.items.isEmpty) {
      return Center(child: Text('Error: ${provider.error}'));
    }
    if (provider.items.isEmpty) {
      return const Center(child: Text('No menu items found'));
    }

    return ListView.builder(
      key: ValueKey(provider.items.length),
      itemCount: provider.items.length,
      itemBuilder: (context, index) {
        final item = provider.items[index];
        final images = imageProvider.getImagesForMenuItem(item.id);
        final categoryName =
            item.categoryName ?? categoryProvider.getById(item.categoryId)?.name ?? 'Unknown';

        return Card(
          color: Theme.of(context).cardColor,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(item.name),
            subtitle: Text('$categoryName - \$${item.price.toStringAsFixed(2)}'),
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
                  onPressed: () async {
                    if (categoryProvider.categories.isEmpty) {
                      await categoryProvider.fetchCategories();
                    }

                    final fullItem = MenuItemModel(
                      id: item.id,
                      name: item.name,
                      description: item.description,
                      price: item.price,
                      isAvailable: item.isAvailable,
                      isSpecialOfTheDay: item.isSpecialOfTheDay,
                      categoryId: item.categoryId,
                      categoryName: categoryProvider.getById(item.categoryId)?.name,
                      imageUrls: item.imageUrls,
                    );

                    showUpdateMenuItemDialog(context, fullItem);
                  },
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
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this menu item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<MenuItemProvider>().deleteItem(id);
                if (!context.mounted) return;
                Navigator.pop(context);
                msg.showSnackMessage(context, 'Menu item deleted', type: msg.AppMessageType.success);
              } on ApiException catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context);
                msg.showApiErrorOverlay(context, e);
              } catch (_) {
                if (!context.mounted) return;
                Navigator.pop(context);
                msg.showSnackMessage(context, 'Something went wrong. Please try again.');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
