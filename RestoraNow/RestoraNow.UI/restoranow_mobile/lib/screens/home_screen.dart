import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import '../layouts/main_layout.dart';
import '../providers/base/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/recommendations_provider.dart';
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
  // Specials
  late Future<List<MenuItemModel>> _specialsFuture;
  final _menuApi = MenuItemApiService();

  // Track auth/user changes so we can refresh recommendations after restore/login/logout
  int? _lastUserId;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _specialsFuture = _fetchSpecials();

    // Try loading recs once after first frame (works if token was already available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_bootstrapped) {
        _bootstrapped = true;
        if (mounted) {
          context.read<RecommendationsProvider>().load(take: 10);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();

    // Wait until token restoration finishes; then react to userId changes
    if (!auth.restoring) {
      if (auth.userId != _lastUserId) {
        _lastUserId = auth.userId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<RecommendationsProvider>().load(take: 10);
          }
        });
      }
    }
  }

  Future<List<MenuItemModel>> _fetchSpecials() async {
    final SearchResult<MenuItemModel> res = await _menuApi.get(
      filter: {'IsSpecialOfTheDay': 'true', 'IsAvailable': 'true'},
      page: 1,
      pageSize: 3,
    );
    return res.items;
  }

  Future<void> _refresh() async {
    // Re-run specials
    setState(() => _specialsFuture = _fetchSpecials());
    // Re-run recommendations
    await context.read<RecommendationsProvider>().load(take: 10);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return MainLayout(
      title: 'Home',
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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

            // ===== Meal of the Day =====
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
                    onRetry: () => setState(() {
                      _specialsFuture = _fetchSpecials();
                    }),
                  );
                }
                final items = snap.data ?? const <MenuItemModel>[];
                if (items.isEmpty) {
                  return const Text('No special is set for today.');
                }
                return _HorizontalMenuScroller(items: items);
              },
            ),

            // ===== Recommended for you =====
            const SizedBox(height: 28),
            const _SectionHeader(title: 'Recommended for you'),
            const SizedBox(height: 10),

            Consumer<RecommendationsProvider>(
              builder: (context, recProv, _) {
                if (recProv.isLoading) {
                  return const _HScrollerLoading();
                }
                if (recProv.error != null) {
                  return _ErrorText(
                    "Couldn't load recommendations: ${recProv.error}",
                    onRetry: () => recProv.load(take: 10),
                  );
                }
                final items = recProv.items;
                if (items.isEmpty) {
                  final authed = context.select<AuthProvider, bool>(
                    (a) => a.isAuthenticated,
                  );
                  return Text(
                    authed
                        ? 'Your recommendations will appear here as you start ordering.'
                        : 'Sign in to see personalized picks.',
                  );
                }
                return _HorizontalMenuScroller(items: items);
              },
            ),
          ],
        ),
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
  const _ErrorText(this.text, {this.onRetry});
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Text(text, style: const TextStyle(color: Colors.red)),
      ),
      if (onRetry != null)
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
    ],
  );
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
                    imageUrl: item.imageUrl, // single image (data URI or URL)
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
  static final _firstUrlCache = <int, String?>{}; // per-item URL cache
  static final _firstBytesCache = <int, Uint8List?>{}; // bytes for data URIs

  final _imgApi = MenuItemImageApiService();

  String? _resolvedUrl;
  Uint8List? _bytes;

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
    // Prefer item-provided image
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      final raw = widget.imageUrl!;
      _resolvedUrl = raw;
      _bytes = raw.startsWith('data:image/') ? _decodeDataUri(raw) : null;
      if (mounted) setState(() {});
      return;
    }

    // Use one-time fetch/cache per item
    if (_firstUrlCache.containsKey(widget.menuItemId)) {
      _resolvedUrl = _firstUrlCache[widget.menuItemId];
      if (_resolvedUrl != null && _resolvedUrl!.startsWith('data:image/')) {
        _bytes =
            _firstBytesCache[widget.menuItemId] ??
            _decodeDataUri(_resolvedUrl!);
        _firstBytesCache[widget.menuItemId] = _bytes;
      } else {
        _bytes = null;
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
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
    }

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
