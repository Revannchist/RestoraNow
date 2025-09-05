import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import '../../layouts/main_layout.dart';
import '../../providers/menu_item_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_item_review_provider.dart';
import '../../models/menu_item_model.dart';
import '../../widgets/menu_dialogs.dart'; // showCartSheet + showMenuItemQuickView

class MenuScreen extends StatefulWidget {
  final int? reservationId;
  const MenuScreen({super.key, this.reservationId});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String? _selectedCategory; // null = All

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuItemProvider>().fetchItems(onlyAvailable: true);
    });
  }

  Future<void> _refresh() async {
    await context.read<MenuItemProvider>().fetchItems(onlyAvailable: true);
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuItemProvider>();
    final cart = context.watch<CartProvider>();

    return MainLayout(
      title: 'Menu',
      cartReservationId: widget.reservationId, // pass through to AppBar cart
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: Stack(
        children: [
          if (menu.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (menu.error != null)
            Center(child: Text(menu.error!))
          else
            RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96, top: 8),
                children: [
                  // ===== Specials (Meal of the Day) =====
                  _SpecialsRow(
                    items: menu.items
                        .where((m) => m.isSpecialOfTheDay)
                        .toList(),
                  ),

                  const SizedBox(height: 12),

                  // ===== Category filter bar =====
                  _CategoryFilterBar(
                    items: menu.items,
                    selectedCategory: _selectedCategory,
                    onSelected: (cat) =>
                        setState(() => _selectedCategory = cat),
                  ),

                  const SizedBox(height: 4),

                  // ===== Category sections (filtered if a chip is selected) =====
                  _CategoryList(
                    items: menu.items,
                    filterCategory: _selectedCategory,
                  ),
                ],
              ),
            ),

          // Sticky cart button
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ElevatedButton(
              onPressed: cart.totalQty == 0
                  ? null
                  : () => showCartSheet(
                      context,
                      reservationId: widget.reservationId,
                    ),
              child: Text(
                cart.totalQty == 0
                    ? 'Cart is empty'
                    : 'Cart (${cart.totalQty}) • ${cart.totalPrice.toStringAsFixed(2)} KM',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Specials row ----------
class _SpecialsRow extends StatelessWidget {
  final List<MenuItemModel> items;
  const _SpecialsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Row(
            children: [
              const Text(
                'Meal of the Day',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Special',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) =>
                SizedBox(width: 260, child: _MenuItemCard(item: items[i])),
          ),
        ),
      ],
    );
  }
}

// ---------- Category filter chips ----------
class _CategoryFilterBar extends StatelessWidget {
  final List<MenuItemModel> items;
  final String? selectedCategory;
  final void Function(String?) onSelected;

  const _CategoryFilterBar({
    required this.items,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final catsSet = <String>{};
    for (final it in items) {
      final c = (it.categoryName ?? 'Other').trim().isNotEmpty
          ? it.categoryName!
          : 'Other';
      catsSet.add(c);
    }
    final cats = catsSet.toList()..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selectedCategory == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...cats.map(
            (c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(c),
                selected: selectedCategory == c,
                onSelected: (_) => onSelected(c),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Category list (optionally filtered) ----------
class _CategoryList extends StatelessWidget {
  final List<MenuItemModel> items;
  final String? filterCategory; // null => show all
  const _CategoryList({required this.items, this.filterCategory});

  @override
  Widget build(BuildContext context) {
    final byCat = <String, List<MenuItemModel>>{};
    for (final it in items) {
      final key = (it.categoryName ?? 'Other').trim().isNotEmpty
          ? it.categoryName!
          : 'Other';
      (byCat[key] ??= []).add(it);
    }

    final categories = (filterCategory == null)
        ? (byCat.keys.toList()..sort())
        : byCat.keys.where((k) => k == filterCategory).toList();

    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No items for the selected category.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (ctx, i) {
        final cat = categories[i];
        final catItems = (byCat[cat] ?? [])
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  cat,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Grid of items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: catItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    mainAxisExtent: 250, // space for image + text + controls
                  ),
                  itemBuilder: (ctx, idx) => _MenuItemCard(item: catItems[idx]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------- Menu item card ----------
class _MenuItemCard extends StatelessWidget {
  final MenuItemModel item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        // Open QUICK VIEW popup (always)
        onTap: () => showMenuItemQuickView(context, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(child: _MenuItemImage(item: item)),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
              child: _ItemRatingLine(item: item),
            ),

            // Price + qty controls
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.price.toStringAsFixed(2)} KM',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (!item.isAvailable)
                    const Text(
                      'Unavailable',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Selector<CartProvider, int>(
                      selector: (_, c) => c.qtyOf(item.id),
                      builder: (ctx, qty, _) {
                        if (qty == 0) {
                          return _SmallIconButton(
                            icon: Icons.add_circle_outline,
                            onPressed: () => cart.add(item),
                          );
                        }
                        return _QtyStepper(
                          qty: qty,
                          onDec: () => cart.removeOne(item.id),
                          onInc: () => cart.add(item),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Image widget separated so it doesn't rebuild when qty changes.
// Also caches base64 -> bytes and keeps old frame while loading.
class _MenuItemImage extends StatelessWidget {
  final MenuItemModel item;
  const _MenuItemImage({required this.item});

  @override
  Widget build(BuildContext context) {
    final raw = item.imageUrl; // <-- single image
    if (raw == null || raw.isEmpty) return const _ImageFallback();

    if (raw.startsWith('data:image/')) {
      final bytes = _MemImgCache.fromDataUri(raw);
      if (bytes == null || bytes.isEmpty) return const _ImageFallback();
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
    } else {
      final url = _absoluteFromEnvLocal(raw);
      return Image.network(
        url,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const _ImageFallback(),
        loadingBuilder: (c, w, p) => p == null
            ? w
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        filterQuality: FilterQuality.medium,
      );
    }
  }
}

// ---------- helpers: env-aware image URL ----------
String _apiBaseLocal() {
  final v = dotenv.env['API_URL'] ?? 'http://10.0.2.2:5294/api/';
  return v.endsWith('/') ? v : '$v/';
}

String _absoluteFromEnvLocal(String raw) {
  if (raw.isEmpty || raw.startsWith('data:image/')) return raw;

  Uri? parsed;
  try {
    parsed = Uri.parse(raw);
  } catch (_) {}

  if (parsed != null && parsed.hasScheme) {
    if (parsed.host == 'localhost' || parsed.host == '127.0.0.1') {
      final base = Uri.parse(_apiBaseLocal());
      return parsed
          .replace(scheme: base.scheme, host: base.host, port: base.port)
          .toString();
    }
    return raw;
  }

  final base = Uri.parse(_apiBaseLocal());
  final rel = raw.startsWith('/') ? raw.substring(1) : raw;
  return base.resolve(rel).toString();
}

// simple in-memory cache for decoded base64 (prevents flicker)
class _MemImgCache {
  static final _map = <String, Uint8List>{};

  static Uint8List? fromDataUri(String raw) {
    if (_map.containsKey(raw)) return _map[raw];
    try {
      final cleaned = raw.replaceAll(RegExp(r'data:image/[^;]+;base64,'), '');
      final bytes = base64Decode(cleaned);
      _map[raw] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }
}

// compact 32x32 icon button
class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _SmallIconButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onDec;
  final VoidCallback onInc;
  const _QtyStepper({
    required this.qty,
    required this.onDec,
    required this.onInc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SmallIconButton(icon: Icons.remove_circle_outline, onPressed: onDec),
        const SizedBox(width: 6),
        Text('$qty', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        _SmallIconButton(icon: Icons.add_circle_outline, onPressed: onInc),
      ],
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.fastfood, size: 28, color: Colors.grey),
      ),
    );
  }
}

// ---------- Live rating line (uses provider, falls back to item fields) ----------
class _RatingVM {
  final double? avg;
  final int total;
  const _RatingVM(this.avg, this.total);
}

class _ItemRatingLine extends StatelessWidget {
  const _ItemRatingLine({required this.item});
  final MenuItemModel item;

  @override
  Widget build(BuildContext context) {
    return Selector<MenuItemReviewProvider, _RatingVM>(
      selector: (_, p) => _RatingVM(p.averageFor(item.id), p.totalFor(item.id)),
      builder: (ctx, vm, _) {
        double? avg = vm.avg ?? item.averageRating;
        int total = (vm.avg != null || vm.total > 0)
            ? vm.total
            : item.ratingsCount;

        if (avg == null || total <= 0) return const SizedBox.shrink();

        return Row(
          children: [
            Icon(Icons.star, size: 14, color: Colors.amber[700]),
            const SizedBox(width: 4),
            Text(
              '${avg.toStringAsFixed(1)} ($total)',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}
