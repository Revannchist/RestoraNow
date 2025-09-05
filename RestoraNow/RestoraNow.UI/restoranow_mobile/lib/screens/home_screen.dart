import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  late Future<List<MenuItemModel>> _recommendedFuture;

  final _menuApi = MenuItemApiService();

  @override
  void initState() {
    super.initState();
    _specialsFuture = _fetchSpecials();
    _recommendedFuture = _fetchRecommended();
  }

  Future<List<MenuItemModel>> _fetchSpecials() async {
    final SearchResult<MenuItemModel> res = await _menuApi.get(
      filter: {'IsSpecialOfTheDay': 'true', 'IsAvailable': 'true'},
      page: 1,
      pageSize: 3,
    );
    return res.items;
  }

  Future<List<MenuItemModel>> _fetchRecommended() async {
    final meId = context.read<AuthProvider>().userId;
    final res = await _menuApi.get(
      filter: {
        if (meId != null) 'UserId': '$meId',
        'Recommended': 'true',
        'IsAvailable': 'true',
      },
      page: 1,
      pageSize: 10,
    );

    if (res.items.isNotEmpty) return res.items;

    // Fallback: just some available items
    final alt = await _menuApi.get(
      filter: {'IsAvailable': 'true'},
      page: 1,
      pageSize: 10,
    );
    return alt.items;
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
            'Discover today’s special and picks tuned to your taste.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 24),
          const _SectionHeader(
            title: 'Meal of the Day',
            pill: _Pill(label: 'Special', color: Colors.orange),
          ),
          const SizedBox(height: 10),

          FutureBuilder<List<MenuItemModel>>(
            future: _specialsFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const _HScrollerLoading();
              }
              if (snap.hasError) {
                return _ErrorText(
                  "Couldn't load today's special: ${snap.error}",
                );
              }
              final items = snap.data ?? const <MenuItemModel>[];
              if (items.isEmpty) {
                return const Text('No special is set for today.');
              }

              return _HorizontalMenuScroller(items: items);
            },
          ),

          const SizedBox(height: 28),
          const _SectionHeader(title: 'Recommended for you'),
          const SizedBox(height: 10),

          FutureBuilder<List<MenuItemModel>>(
            future: _recommendedFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const _HScrollerLoading();
              }
              if (snap.hasError) {
                return _ErrorText(
                  "Couldn't load recommendations: ${snap.error}",
                );
              }
              final items = snap.data ?? const <MenuItemModel>[];
              if (items.isEmpty) {
                return const Text(
                  'Your recommendations will appear here as you start ordering.',
                );
              }

              return _HorizontalMenuScroller(items: items);
            },
          ),
        ],
      ),
    );
  }
}

/// Simple section header with optional pill badge.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.pill});
  final String title;
  final _Pill? pill;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        if (pill != null) ...[const SizedBox(width: 8), pill!],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Horizontal scroller of menu item cards.
class _HorizontalMenuScroller extends StatelessWidget {
  const _HorizontalMenuScroller({required this.items});
  final List<MenuItemModel> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _MenuCard(item: items[i]),
      ),
    );
  }
}

class _HScrollerLoading extends StatelessWidget {
  const _HScrollerLoading();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Row(
        children: List.generate(
          3,
          (_) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: Colors.red));
}

class _MenuCard extends StatelessWidget {
  final MenuItemModel item;
  const _MenuCard({required this.item});

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
                Expanded(
                  child: _MenuImageSmart(
                    menuItemId: item.id,
                    imageUrl: item.imageUrl, // <- single image
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
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
                        const Text(
                          'Unavailable',
                          style: TextStyle(color: Colors.grey),
                        )
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
                            Text(
                              '$qty',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

/// Smart image (single-image version):
/// 1) Uses provided imageUrl if present (data URI or http/relative/absolute).
/// 2) Else fetches the first image via MenuItemImageApiService (cached per item).
/// 3) Network URLs are resolved against API_URL from .env for localhost fixups.
class _MenuImageSmart extends StatefulWidget {
  final int menuItemId;
  final String? imageUrl;
  const _MenuImageSmart({required this.menuItemId, required this.imageUrl});

  @override
  State<_MenuImageSmart> createState() => _MenuImageSmartState();
}

class _MenuImageSmartState extends State<_MenuImageSmart> {
  static final _memBase64Cache = <String, Uint8List>{};
  static final _firstUrlCache = <int, String?>{}; // caches fetched URL
  static final _firstBytesCache =
      <int, Uint8List?>{}; // caches decoded bytes for data URIs

  final _imgApi = MenuItemImageApiService();

  String? _resolvedUrl; // final URL (from widget.imageUrl or fetched)
  Uint8List? _bytes; // decoded bytes if data URI

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _MenuImageSmart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menuItemId != widget.menuItemId ||
        oldWidget.imageUrl != widget.imageUrl) {
      _resolvedUrl = null;
      _bytes = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    // 1) If provided by the item (preferred)
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      final raw = widget.imageUrl!;
      _resolvedUrl = raw;
      if (raw.startsWith('data:image/')) {
        _bytes = _decodeDataUri(raw);
      } else {
        _bytes = null; // use network in build
      }
      if (mounted) setState(() {});
      return;
    }

    // 2) Otherwise: use per-item cache or fetch once
    if (_firstUrlCache.containsKey(widget.menuItemId)) {
      _resolvedUrl = _firstUrlCache[widget.menuItemId];
      _bytes = _resolvedUrl != null && _resolvedUrl!.startsWith('data:image/')
          ? (_firstBytesCache[widget.menuItemId] ??
                _decodeDataUri(_resolvedUrl!))
          : null;
      if (_resolvedUrl != null && _resolvedUrl!.startsWith('data:image/')) {
        _firstBytesCache[widget.menuItemId] = _bytes;
      }
      if (mounted) setState(() {});
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
        _firstUrlCache[widget.menuItemId] = url;
        _resolvedUrl = url;

        if (url.startsWith('data:image/')) {
          _bytes = _decodeDataUri(url);
          _firstBytesCache[widget.menuItemId] = _bytes;
        } else {
          _bytes = null;
        }
      } else {
        _firstUrlCache[widget.menuItemId] = null;
        _resolvedUrl = null;
        _bytes = null;
      }
      if (mounted) setState(() {});
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
    // Data URI rendered from memory
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
    }

    // Network/relative URL
    final url = _resolvedUrl;
    if (url != null && url.isNotEmpty && !url.startsWith('data:image/')) {
      final abs = _absoluteFromEnv(url);
      return Image.network(
        abs,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const _ImageFallback(),
        loadingBuilder: (c, w, p) => p == null
            ? w
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        filterQuality: FilterQuality.medium,
      );
    }

    // Fallback
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

// ---------- URL helpers using .env API_URL ----------

String _apiBase() {
  final v = (dotenv.env['API_URL'] ?? 'http://10.0.2.2:5294/api/').trim();
  return v.endsWith('/') ? v : '$v/';
}

String _absoluteFromEnv(String raw) {
  if (raw.isEmpty || raw.startsWith('data:image/')) return raw;

  Uri? parsed;
  try {
    parsed = Uri.parse(raw);
  } catch (_) {}

  if (parsed != null && parsed.hasScheme) {
    if (parsed.host == 'localhost' || parsed.host == '127.0.0.1') {
      final base = Uri.parse(_apiBase());
      return parsed
          .replace(scheme: base.scheme, host: base.host, port: base.port)
          .toString();
    }
    return raw;
  }

  final base = Uri.parse(_apiBase());
  final rel = raw.startsWith('/') ? raw.substring(1) : raw;
  return base.resolve(rel).toString();
}
