import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/menu_item_model.dart';
import '../../providers/menu_item_provider.dart';
import '../../providers/menu_item_image_provider.dart';
import '../../providers/menu_category_provider.dart';
import '../../widgets/pagination_controls.dart';

/// What the picker returns to the caller (id + name + qty [+ price]).
class MenuItemPick {
  final int id;
  final String name;
  final double unitPrice;
  int qty;

  MenuItemPick({
    required this.id,
    required this.name,
    required this.unitPrice,
    this.qty = 1,
  });
}

/// Returns List<MenuItemPick> via Navigator.pop
class MenuItemMultiSelectScreen extends StatefulWidget {
  /// Used to prefill from an existing order (id -> qty).
  final Map<int, int> initialSelection;

  const MenuItemMultiSelectScreen({
    super.key,
    this.initialSelection = const {},
  });

  @override
  State<MenuItemMultiSelectScreen> createState() =>
      _MenuItemMultiSelectScreenState();
}

class _MenuItemMultiSelectScreenState extends State<MenuItemMultiSelectScreen> {
  final _searchCtrl = TextEditingController();
  final _focus = FocusNode();

  /// Working selection (id -> rich pick)
  late Map<int, MenuItemPick> _selected;

  int? _categoryId; // null = All

  @override
  void initState() {
    super.initState();

    // Build selection from incoming id->qty; names will be enriched as rows appear.
    _selected = {
      for (final e in widget.initialSelection.entries)
        e.key: MenuItemPick(
          id: e.key,
          name: 'Item #${e.key}', // placeholder until we see the row
          unitPrice: 0,
          qty: e.value,
        ),
    };

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final itemsProvider = context.read<MenuItemProvider>();
      final catProvider = context.read<MenuCategoryProvider>();

      if (catProvider.categories.isEmpty) {
        await catProvider.fetchCategories();
      }

      // Initial load (only available by default)
      itemsProvider.setFilters(isAvailable: true);
    });

    _focus.addListener(() {
      if (!_focus.hasFocus) _applyFilters();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<MenuItemProvider>().setFilters(
          name: _searchCtrl.text.trim().isEmpty
              ? null
              : _searchCtrl.text.trim(),
          categoryId: _categoryId,
          isAvailable: true,
        );
  }

  void _toggle(MenuItemModel m) {
    setState(() {
      if (_selected.containsKey(m.id)) {
        _selected.remove(m.id);
      } else {
        _selected[m.id] = MenuItemPick(
          id: m.id,
          name: m.name,
          unitPrice: m.price,
          qty: 1,
        );
      }
    });
  }

  void _qtyPlus(int id) => setState(() => _selected[id]!.qty += 1);

  void _qtyMinus(int id) {
    final p = _selected[id]!;
    if (p.qty > 1) {
      setState(() => p.qty -= 1);
    } else {
      setState(() => _selected.remove(id));
    }
  }

  int get _totalItems => _selected.values.fold(0, (a, p) => a + p.qty);

  Uint8List? _decodeBase64Maybe(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    final regex = RegExp(r'data:image/[^;]+;base64,');
    final cleaned = base64String.replaceAll(regex, '');
    try {
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Menu Items'),
        actions: [
          TextButton(
            onPressed: _selected.isEmpty
                ? null
                : () => Navigator.pop<List<MenuItemPick>>(
                      context,
                      _selected.values.toList(),
                    ),
            child: Text(
              _selected.isEmpty ? 'Confirm' : 'Confirm (${_totalItems})',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Consumer3<MenuItemProvider, MenuItemImageProvider,
          MenuCategoryProvider>(
        builder: (context, itemsProvider, imageProvider, categoryProvider, _) {
          return Column(
            children: [
              // Search + Category filter row
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _focus,
                        decoration: InputDecoration(
                          labelText: 'Search by name (e.g. Tiramisu)',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _applyFilters,
                          ),
                        ),
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Reset filters',
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _categoryId = null);
                        itemsProvider.setFilters(isAvailable: true);
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),

              // Category chips
              SizedBox(
                height: 44,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _categoryId == null,
                      onSelected: (_) {
                        setState(() => _categoryId = null);
                        _applyFilters();
                      },
                    ),
                    const SizedBox(width: 8),
                    ...categoryProvider.categories.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(c.name),
                          selected: _categoryId == c.id,
                          onSelected: (_) {
                            setState(() => _categoryId = c.id);
                            _applyFilters();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // List
              if (itemsProvider.isLoading && itemsProvider.items.isEmpty)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else if (itemsProvider.error != null)
                Expanded(
                    child: Center(child: Text('Error: ${itemsProvider.error}')))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: itemsProvider.items.length,
                    itemBuilder: (context, index) {
                      final m = itemsProvider.items[index];

                      // Lazy fetch images for visible items (first image)
                      final imgs = imageProvider.getImagesForMenuItem(m.id);
                      if (imgs.isEmpty) {
                        imageProvider.fetchImages(m.id);
                      }
                      final imgBytes =
                          imgs.isNotEmpty ? _decodeBase64Maybe(imgs.first.url) : null;

                      final selected = _selected.containsKey(m.id);
                      final qty = _selected[m.id]?.qty ?? 0;
                      final catName = m.categoryName ??
                          categoryProvider.getById(m.categoryId)?.name ??
                          'Unknown';

                      // If prefilled placeholder exists, enrich it when the row is visible
                      if (selected) {
                        final p = _selected[m.id]!;
                        if (p.name.startsWith('Item #')) {
                          _selected[m.id] = MenuItemPick(
                            id: m.id,
                            name: m.name,
                            unitPrice: m.price,
                            qty: p.qty,
                          );
                        }
                      }

                      return Card(
                        key: ValueKey(m.id),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          onTap: () => _toggle(m),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: imgBytes != null
                                ? Image.memory(
                                    imgBytes,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    color: Theme.of(context)
                                        .dividerColor
                                        .withOpacity(0.2),
                                    child: const Icon(Icons.fastfood),
                                  ),
                          ),
                          title: Text(
                            m.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            [
                              catName,
                              m.price.toStringAsFixed(2),
                              if (!m.isAvailable) 'Unavailable',
                            ].join(' • '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!selected)
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _toggle(m),
                                )
                              else
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      onPressed: () => _qtyMinus(m.id),
                                    ),
                                    Text('$qty',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.add_circle_outline),
                                      onPressed: () => _qtyPlus(m.id),
                                    ),
                                  ],
                                ),
                              Checkbox(
                                value: selected,
                                onChanged: (_) => _toggle(m),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Pagination
              PaginationControls(
                currentPage: itemsProvider.currentPage,
                totalPages: itemsProvider.totalPages,
                pageSize: itemsProvider.pageSize,
                onPageChange: (p) => itemsProvider.setPage(p),
                onPageSizeChange: (s) => itemsProvider.setPageSize(s),
              ),
              const SizedBox(height: 6),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selected.isEmpty
                      ? 'No items selected'
                      : 'Selected: $_totalItems total',
                ),
              ),
              FilledButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.pop<List<MenuItemPick>>(
                          context,
                          _selected.values.toList(),
                        ),
                child: Text(
                    _selected.isEmpty ? 'Confirm' : 'Confirm (${_totalItems})'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
