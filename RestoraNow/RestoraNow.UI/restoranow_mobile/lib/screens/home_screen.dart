import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/main_layout.dart';
import '../providers/base/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../models/menu_item_model.dart';

import '../core/menu_item_api_service.dart';
import '../core/menu_item_image_api_service.dart';
import '../models/search_result.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<MenuItemModel>> _specialsFuture;
  final _menuApi = MenuItemApiService();

  @override
  void initState() {
    super.initState();
    _specialsFuture = _fetchSpecials();
  }

  Future<List<MenuItemModel>> _fetchSpecials() async {
    final SearchResult<MenuItemModel> res = await _menuApi.get(
      filter: {
        'IsSpecialOfTheDay': 'true',
        'IsAvailable': 'true',
      },
      page: 1,
      pageSize: 3,
    );
    return res.items;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return MainLayout(
      title: 'Home',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome ${auth.username ?? 'there'}!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Dashboard placeholder for quick access to key features.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // ===== Meal of the Day =====
          Row(
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
          const SizedBox(height: 10),

          FutureBuilder<List<MenuItemModel>>(
            future: _specialsFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "Couldn't load today's special: ${snap.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              final items = snap.data ?? const <MenuItemModel>[];
              if (items.isEmpty) {
                return const Text('No special is set for today.');
              }

              return SizedBox(
                height: 240, // enough to avoid overflows
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _SpecialCard(item: items[i]),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Quick nav cards
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickCard(
                title: 'Orders',
                subtitle: 'View and manage',
                icon: Icons.receipt_long_outlined,
                onTap: () => Navigator.pushReplacementNamed(context, '/orders'),
              ),
              _QuickCard(
                title: 'Reservations',
                subtitle: 'Today’s bookings',
                icon: Icons.event_seat_outlined,
                onTap: () => Navigator.pushReplacementNamed(context, '/reservations'),
              ),
              _QuickCard(
                title: 'Menu',
                subtitle: 'Items & categories',
                icon: Icons.menu_book_outlined,
                onTap: () => Navigator.pushReplacementNamed(context, '/menu'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecialCard extends StatelessWidget {
  final MenuItemModel item;
  const _SpecialCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final qty = context.select<CartProvider, int>((c) => c.qtyOf(item.id));

    return SizedBox(
      width: 260,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: item.isAvailable ? () => cart.add(item) : null,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image uses flexible top area
                Expanded(
                  child: _MenuImageSmart(
                    menuItemId: item.id,
                    urls: item.imageUrls,
                  ),
                ),

                // Name (1–2 lines)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                // Price + stepper
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
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
                        const Text('Unavailable', style: TextStyle(color: Colors.grey))
                      else if (qty == 0)
                        IconButton(
                          tooltip: 'Add',
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => cart.add(item),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Decrease',
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => cart.removeOne(item.id),
                            ),
                            Text('$qty', style: const TextStyle(fontWeight: FontWeight.w600)),
                            IconButton(
                              tooltip: 'Increase',
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => cart.add(item),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Smart image that:
/// 1) uses provided imageUrls if present (base64 or http)
/// 2) if empty, fetches the first image via MenuItemImageApiService and caches it
class _MenuImageSmart extends StatefulWidget {
  final int menuItemId;
  final List<String> urls;
  const _MenuImageSmart({required this.menuItemId, required this.urls});

  @override
  State<_MenuImageSmart> createState() => _MenuImageSmartState();
}

class _MenuImageSmartState extends State<_MenuImageSmart> {
  static final _memBase64Cache = <String, Uint8List>{};
  static final _firstImageCache = <int, Uint8List?>{}; // menuItemId -> bytes (nullable)
  final _imgApi = MenuItemImageApiService();

  Uint8List? _bytes; // resolved bytes to display (if any)

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _MenuImageSmart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menuItemId != widget.menuItemId || oldWidget.urls != widget.urls) {
      _bytes = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    // Prefer direct urls if provided
    if (widget.urls.isNotEmpty) {
      final raw = widget.urls.first;
      if (raw.startsWith('data:image/')) {
        setState(() => _bytes = _decodeDataUri(raw));
        return;
      } else {
        // We'll use network image at build time
        setState(() => _bytes = null);
        return;
      }
    }

    // Otherwise try one-time fetch for first image
    if (_firstImageCache.containsKey(widget.menuItemId)) {
      setState(() => _bytes = _firstImageCache[widget.menuItemId]);
      return;
    }

    try {
      final result = await _imgApi.get(
        filter: {'MenuItemId': widget.menuItemId.toString()},
        page: 1,
        pageSize: 1,
      );
      if (result.items.isNotEmpty) {
        final url = result.items.first.url;
        final bytes = url.startsWith('data:image/') ? _decodeDataUri(url) : null;
        _firstImageCache[widget.menuItemId] = bytes;
        if (mounted) setState(() => _bytes = bytes);
      } else {
        _firstImageCache[widget.menuItemId] = null;
        if (mounted) setState(() => _bytes = null);
      }
    } catch (_) {
      // ignore; show fallback
    }
  }

  Uint8List? _decodeDataUri(String raw) {
    final cached = _memBase64Cache[raw];
    if (cached != null) return cached;
    try {
      final cleaned = raw.replaceAll(RegExp(r'data:image/[^;]+;base64,'), '');
      final bytes = base64Decode(cleaned);
      _memBase64Cache[raw] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prefer resolved memory bytes (base64)
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
    }

    // If urls had a http(s) URL, show it
    if (widget.urls.isNotEmpty && !widget.urls.first.startsWith('data:image/')) {
      final fixed = widget.urls.first
          .replaceFirst('://localhost', '://10.0.2.2')
          .replaceFirst('://127.0.0.1', '://10.0.2.2');
      return Image.network(
        fixed,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const _ImageFallback(),
        loadingBuilder: (c, w, p) =>
            p == null ? w : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        filterQuality: FilterQuality.medium,
      );
    }

    // Otherwise fallback
    return const _ImageFallback();
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

class _QuickCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
