import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/base/auth_provider.dart';
import '../providers/reservation_provider.dart';
import '../providers/address_provider.dart';
import '../providers/menu_item_review_provider.dart'; // reviews
import '../models/reservation_model.dart';
import '../models/address_model.dart';
import '../models/menu_item_model.dart';
import '../models/menu_item_review_model.dart'; // reviews
import '../screens/checkout_screen.dart';
import '../screens/addresses_screen.dart';

/// Open the cart sheet (optionally preselect a reservation).
void showCartSheet(BuildContext context, {int? reservationId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CartSheet(reservationId: reservationId),
  );
}

/// Resolve API base from .env (fallback to emulator-friendly default).
String _apiBase() {
  final v = dotenv.env['API_URL'] ?? 'http://10.0.2.2:5294/api/';
  return v.endsWith('/') ? v : '$v/';
}

/// Turn any image URL into an absolute URL using API_URL.
/// - Keeps data URIs as-is
/// - Rewrites localhost/127.0.0.1 to the host/port from API_URL
/// - Resolves relative paths against API_URL
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

class _CartSheet extends StatefulWidget {
  final int? reservationId; // If coming from "Save + Menu"
  const _CartSheet({this.reservationId});

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

enum _TargetOption { delivery, pickup, reservation }

class _CartSheetState extends State<_CartSheet> {
  _TargetOption _mode = _TargetOption.delivery;
  int? _selectedReservationId;

  // Delivery (read-only) address line; we always use the user's DEFAULT address.
  String _selectedAddressLine = '';
  bool _addrLoading = false;

  @override
  void initState() {
    super.initState();

    // If a reservation id is passed in, default to reservation mode.
    if (widget.reservationId != null) {
      _mode = _TargetOption.reservation;
      _selectedReservationId = widget.reservationId;
    }

    // Load current user's reservations and default address.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = context.read<AuthProvider>().userId;
      if (userId == null) return;

      // 1) Reservations
      await context.read<ReservationProvider>().fetchMyReservations(userId);

      final resProv = context.read<ReservationProvider>();
      final exists = resProv.reservations.any(
        (r) => r.id == _selectedReservationId,
      );
      if (_mode == _TargetOption.reservation &&
          _selectedReservationId != null &&
          !exists) {
        if (!mounted) return;
        setState(() {
          _mode = _TargetOption.delivery;
          _selectedReservationId = null;
        });
      }

      // 2) Default address → auto-select
      await _refreshDefaultAddress(userId);
    });
  }

  Future<void> _refreshDefaultAddress(int userId) async {
    setState(() => _addrLoading = true);
    await context.read<AddressProvider>().fetchByUser(userId);
    final def = context.read<AddressProvider>().defaultAddress;
    if (!mounted) return;
    setState(() {
      _selectedAddressLine = _prettyAddress(def);
      _addrLoading = false;
    });
  }

  // ---- Helpers ----
  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(String hhmmss) {
    final p = hhmmss.split(':');
    if (p.length >= 2) return '${p[0].padLeft(2, '0')}:${p[1].padLeft(2, '0')}';
    return hhmmss;
  }

  DateTime _combine(DateTime date, String hhmmss) {
    final p = hhmmss.split(':');
    final h = int.tryParse(p.elementAt(0)) ?? 0;
    final m = int.tryParse(p.elementAt(1)) ?? 0;
    final s = int.tryParse(p.elementAt(2)) ?? 0;
    return DateTime(date.year, date.month, date.day, h, m, s);
  }

  Widget _thumbFromRaw(String? raw) {
    if (raw == null || raw.isEmpty) return const _ThumbFallback();

    if (raw.startsWith('data:image/')) {
      try {
        final cleaned = raw.replaceAll(RegExp(r'data:image/[^;]+;base64,'), '');
        final bytes = base64Decode(cleaned);
        if (bytes.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(
              bytes,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
            ),
          );
        }
      } catch (_) {}
      return const _ThumbFallback();
    }

    final url = _absoluteFromEnv(raw);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _ThumbFallback(),
      ),
    );
  }

  String _prettyAddress(AddressModel? a) {
    if (a == null) return '';
    final parts = <String>[
      a.street,
      [
        if ((a.zipCode ?? '').isNotEmpty) a.zipCode!,
        if ((a.city ?? '').isNotEmpty) a.city!,
      ].where((x) => x.trim().isNotEmpty).join(' '),
      if ((a.country ?? '').isNotEmpty) a.country!,
    ].where((x) => x.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final resProv = context.watch<ReservationProvider>();
    final now = DateTime.now();

    // Eligible reservations (future + pending/confirmed)
    final eligible =
        resProv.reservations.where((r) {
          final allowed =
              r.status == ReservationStatus.pending ||
              r.status == ReservationStatus.confirmed;
          final when = _combine(r.reservationDate, r.reservationTime);
          return allowed && when.isAfter(now);
        }).toList()..sort((a, b) {
          final adt = _combine(a.reservationDate, a.reservationTime);
          final bdt = _combine(b.reservationDate, b.reservationTime);
          return adt.compareTo(bdt);
        });

    // Keep selection valid
    if (_mode == _TargetOption.reservation &&
        _selectedReservationId != null &&
        eligible.every((r) => r.id != _selectedReservationId)) {
      _selectedReservationId = null;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            height: 4,
            width: 48,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          const Text(
            'Your Cart',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'How would you like to proceed?',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 6),

          // Delivery (default address)
          RadioListTile<_TargetOption>(
            dense: true,
            value: _TargetOption.delivery,
            groupValue: _mode,
            title: const Text('Delivery / Takeaway'),
            subtitle: const Text('Use your default delivery address'),
            onChanged: (v) => setState(() {
              _mode = v!;
              _selectedReservationId = null;
            }),
          ),

          // Pickup option
          RadioListTile<_TargetOption>(
            dense: true,
            value: _TargetOption.pickup,
            groupValue: _mode,
            title: const Text('Pick up at restaurant'),
            subtitle: const Text('No address needed'),
            onChanged: (v) => setState(() {
              _mode = v!;
              _selectedReservationId = null;
            }),
          ),

          // Attach to reservation
          RadioListTile<_TargetOption>(
            dense: true,
            value: _TargetOption.reservation,
            groupValue: _mode,
            title: const Text('Attach to a reservation'),
            subtitle: (resProv.isLoading && eligible.isEmpty)
                ? const Text('Loading your reservations…')
                : (eligible.isEmpty
                      ? const Text('No eligible reservations found.')
                      : null),
            onChanged: (v) => setState(() {
              _mode = v!;
              if (eligible.length == 1) {
                _selectedReservationId = eligible.single.id;
              }
            }),
          ),

          if (_mode == _TargetOption.reservation)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                value: _selectedReservationId,
                items: eligible
                    .map(
                      (r) => DropdownMenuItem<int>(
                        value: r.id,
                        child: Text(
                          'Table ${r.tableNumber ?? r.tableId} • ${_fmtDate(r.reservationDate)} ${_fmtTime(r.reservationTime)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedReservationId = v),
                decoration: const InputDecoration(
                  labelText: 'Select reservation',
                  prefixIcon: Icon(Icons.event_seat_outlined),
                ),
              ),
            ),

          // Delivery address (read-only, always uses DEFAULT)
          if (_mode == _TargetOption.delivery)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: _DeliveryAddressView(
                loading: _addrLoading,
                addressLine: _selectedAddressLine,
                onManageAddresses: () async {
                  // User can change their default address in this screen.
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddressesScreen()),
                  );
                  final userId = context.read<AuthProvider>().userId;
                  if (userId == null || !mounted) return;
                  await _refreshDefaultAddress(userId); // re-pick default
                },
                onUseDefault: () async {
                  final userId = context.read<AuthProvider>().userId;
                  if (userId == null) return;
                  await _refreshDefaultAddress(userId);
                },
              ),
            ),

          const SizedBox(height: 8),

          // Cart list
          if (cart.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Cart is empty.'),
            )
          else
            Expanded(
              child: ListView(
                children: cart.items.values.map((ci) {
                  final item = ci.item;
                  final raw = item.imageUrl; // <-- single image

                  return ListTile(
                    leading: _thumbFromRaw(raw),
                    title: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${item.price.toStringAsFixed(2)} KM • x${ci.qty}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Decrease',
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () =>
                              context.read<CartProvider>().removeOne(item.id),
                        ),
                        Text(
                          '${ci.qty}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          tooltip: 'Increase',
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () =>
                              context.read<CartProvider>().add(item),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 8),

          // Totals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${cart.totalPrice.toStringAsFixed(2)} KM',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Actions
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(top: 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: cart.items.isEmpty
                        ? null
                        : () => context.read<CartProvider>().clear(),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: cart.items.isEmpty
                        ? null
                        : () {
                            // Validate mode
                            int? reservationId;
                            String? deliveryAddress;

                            switch (_mode) {
                              case _TargetOption.reservation:
                                if (_selectedReservationId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select a reservation.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                reservationId = _selectedReservationId;
                                break;

                              case _TargetOption.delivery:
                                if (_selectedAddressLine.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please set a default delivery address.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                deliveryAddress = _selectedAddressLine.trim();
                                break;

                              case _TargetOption.pickup:
                                // Pass a display string so Checkout can show it.
                                deliveryAddress = 'Pick up at restaurant';
                                break;
                            }

                            // Close sheet then push checkout (display-only address).
                            final nav = Navigator.of(context);
                            nav.pop();
                            Future.microtask(() {
                              nav.push(
                                MaterialPageRoute(
                                  builder: (_) => CheckoutScreen(
                                    reservationId: reservationId,
                                    deliveryAddress:
                                        deliveryAddress, // shown for Delivery or Pickup
                                  ),
                                ),
                              );
                            });
                          },
                    child: const Text('Proceed to payment'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryAddressView extends StatelessWidget {
  const _DeliveryAddressView({
    required this.loading,
    required this.addressLine,
    required this.onManageAddresses,
    required this.onUseDefault,
  });

  final bool loading;
  final String addressLine;
  final VoidCallback onManageAddresses;
  final VoidCallback onUseDefault;

  @override
  Widget build(BuildContext context) {
    if (loading) return const LinearProgressIndicator(minHeight: 2);

    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Delivery address (default)',
              prefixIcon: Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(),
            ),
            child: Text(
              addressLine.isEmpty ? 'No default address set' : addressLine,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                flex: 3,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.book_outlined),
                  label: const Text(
                    'Manage addresses',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  onPressed: onManageAddresses,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: TextButton(
                  onPressed: onUseDefault,
                  child: const Text(
                    'Use default',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.fastfood, size: 22, color: Colors.grey),
    );
  }
}

// ===================================================================
// QUICK VIEW: open a bottom sheet with full item info + qty stepper.
// ===================================================================
void showMenuItemQuickView(BuildContext context, MenuItemModel item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _ItemQuickView(item: item),
  );
}

class _ItemQuickView extends StatelessWidget {
  const _ItemQuickView({required this.item});
  final MenuItemModel item;

  @override
  Widget build(BuildContext context) {
    final qty = context.select<CartProvider, int>((c) => c.qtyOf(item.id));
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 12),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _QuickImage(raw: item.imageUrl), // <-- single image
                  ),
                  const SizedBox(height: 12),

                  // Title + price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.price.toStringAsFixed(2)} KM',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Category / badges
                  Wrap(
                    spacing: 6,
                    runSpacing: -6,
                    children: [
                      if ((item.categoryName ?? '').trim().isNotEmpty)
                        Chip(
                          label: Text(item.categoryName!),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      if (item.isSpecialOfTheDay)
                        Chip(
                          label: const Text('Special'),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.orange.withOpacity(0.12),
                          side: BorderSide(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                          labelStyle: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Chip(
                        label: Text(
                          item.isAvailable ? 'Available' : 'Unavailable',
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        backgroundColor:
                            (item.isAvailable ? Colors.green : Colors.red)
                                .withOpacity(0.1),
                      ),
                    ],
                  ),

                  // Description
                  if ((item.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      item.description!.trim(),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ✅ Reviews section
                  _ReviewSection(item: item),

                  const SizedBox(height: 16),

                  // Qty stepper
                  Row(
                    children: [
                      const Text(
                        'Quantity',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      _QtyStepperInline(item: item, qty: qty),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Footer actions
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: item.isAvailable
                          ? () {
                              final cart = context.read<CartProvider>();
                              if (cart.qtyOf(item.id) == 0) cart.add(item);
                              Navigator.pop(context);
                            }
                          : null,
                      child: Text(qty == 0 ? 'Add to cart' : 'Done'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyStepperInline extends StatelessWidget {
  const _QtyStepperInline({required this.item, required this.qty});
  final MenuItemModel item;
  final int qty;

  @override
  Widget build(BuildContext context) {
    if (!item.isAvailable) {
      return const Text('—', style: TextStyle(color: Colors.grey));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Decrease',
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: qty > 0
              ? () => context.read<CartProvider>().removeOne(item.id)
              : null,
        ),
        Text('$qty', style: const TextStyle(fontWeight: FontWeight.w600)),
        IconButton(
          tooltip: 'Increase',
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => context.read<CartProvider>().add(item),
        ),
      ],
    );
  }
}

class _QuickImage extends StatelessWidget {
  const _QuickImage({required this.raw});
  final String? raw;

  @override
  Widget build(BuildContext context) {
    if (raw == null || raw!.isEmpty) return const _QuickFallback();
    if (raw!.startsWith('data:image/')) {
      try {
        final cleaned = raw!.replaceAll(
          RegExp(r'data:image/[^;]+;base64,'),
          '',
        );
        final bytes = base64Decode(cleaned);
        if (bytes.isEmpty) return const _QuickFallback();
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        );
      } catch (_) {
        return const _QuickFallback();
      }
    }
    final url = _absoluteFromEnv(raw!);
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _QuickFallback(),
      loadingBuilder: (c, w, p) => p == null
          ? w
          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      filterQuality: FilterQuality.medium,
    );
  }
}

class _QuickFallback extends StatelessWidget {
  const _QuickFallback();
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

/// =======================
/// Reviews UI (Quick View)
/// =======================
class _ReviewSection extends StatefulWidget {
  const _ReviewSection({required this.item});
  final MenuItemModel item;

  @override
  State<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<_ReviewSection> {
  int? _rating; // 1..5
  final _commentCtrl = TextEditingController();
  bool _saving = false;
  bool _hydratedFromExisting = false; // prefill once

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuItemReviewProvider>().fetchForMenuItem(
        widget.item.id,
        pageSize: 10,
      );
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MenuItemReviewProvider>();
    final meId = context.read<AuthProvider>().userId;

    final avg = prov.averageFor(widget.item.id);
    final total = prov.totalFor(widget.item.id);
    final existing = (meId == null)
        ? null
        : prov.myReviewFor(menuItemId: widget.item.id, userId: meId);

    if (!_hydratedFromExisting && existing != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _rating ??= existing.rating;
        _commentCtrl.text = existing.comment ?? '';
        _hydratedFromExisting = true;
        setState(() {});
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: average + count
        Row(
          children: [
            _StarDisplay(value: (avg ?? 0).round()),
            const SizedBox(width: 8),
            Text(
              avg == null
                  ? 'No ratings yet'
                  : '${avg.toStringAsFixed(1)} • $total review${(total == 1) ? '' : 's'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (meId == null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
            ),
            child: const Text('Sign in to rate this meal.'),
          ),
        ] else ...[
          Row(
            children: [
              const Text(
                'Your rating:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              _StarPicker(
                value: _rating ?? existing?.rating ?? 0,
                onChanged: (v) => setState(() => _rating = v),
              ),
              if (existing != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Saved',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'Comment (optional)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    existing == null ? 'Submit review' : 'Update review',
                  ),
                  onPressed: _saving
                      ? null
                      : () async {
                          if (_rating == null && existing == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a rating (1–5).'),
                              ),
                            );
                            return;
                          }
                          final ratingToSend = _rating ?? existing!.rating;
                          if (ratingToSend < 1 || ratingToSend > 5) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Rating must be between 1 and 5.',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() => _saving = true);
                          try {
                            final req = MenuItemReviewRequest(
                              userId: meId,
                              menuItemId: widget.item.id,
                              rating: ratingToSend,
                              comment: _commentCtrl.text.trim().isEmpty
                                  ? null
                                  : _commentCtrl.text.trim(),
                            );

                            if (existing == null) {
                              await context
                                  .read<MenuItemReviewProvider>()
                                  .create(req);
                            } else {
                              await context
                                  .read<MenuItemReviewProvider>()
                                  .update(existing.id, req);
                            }

                            // Refetch to sync with server + update "other reviews" and card stars
                            await context
                                .read<MenuItemReviewProvider>()
                                .fetchForMenuItem(widget.item.id, pageSize: 10);

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thanks for your review!'),
                              ),
                            );
                            FocusScope.of(context).unfocus();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save review: $e'),
                              ),
                            );
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                ),
              ),
              const SizedBox(width: 8),
              if (existing != null)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            try {
                              await context
                                  .read<MenuItemReviewProvider>()
                                  .delete(existing.id, widget.item.id);

                              // Refetch to sync with server + update "other reviews" and card stars
                              await context
                                  .read<MenuItemReviewProvider>()
                                  .fetchForMenuItem(
                                    widget.item.id,
                                    pageSize: 10,
                                  );

                              if (!mounted) return;
                              setState(() {
                                _rating = 0;
                                _commentCtrl.clear();
                                _hydratedFromExisting = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Review deleted.'),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete: $e')),
                              );
                            } finally {
                              if (mounted) setState(() => _saving = false);
                            }
                          },
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),
          _OtherReviews(menuItemId: widget.item.id, maxItems: 5),
        ],
      ],
    );
  }
}

/// Displays filled stars (non-interactive)
class _StarDisplay extends StatelessWidget {
  const _StarDisplay({required this.value});
  final int value; // 0..5

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < value ? Icons.star : Icons.star_border,
          size: 20,
          color: Colors.amber[700],
        );
      }),
    );
  }
}

/// Interactive star picker (1..5)
class _StarPicker extends StatelessWidget {
  const _StarPicker({required this.value, required this.onChanged});
  final int value; // 0..5 (0 = none selected yet)
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final idx = i + 1;
        final filled = idx <= value;
        return IconButton(
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            filled ? Icons.star : Icons.star_border,
            color: Colors.amber[700],
          ),
          onPressed: () => onChanged(idx),
          tooltip: '$idx',
        );
      }),
    );
  }
}

class _OtherReviews extends StatelessWidget {
  const _OtherReviews({required this.menuItemId, this.maxItems = 5});
  final int menuItemId;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MenuItemReviewProvider>();
    final meId = context.read<AuthProvider>().userId;
    final isLoading = prov.isLoading(menuItemId);
    final all = prov.reviewsFor(menuItemId);

    // Exclude my own review from the "other reviews" list
    final others = (meId == null)
        ? all
        : all.where((r) => r.userId != meId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent reviews',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            if (isLoading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (others.isEmpty && !isLoading)
          Text('No reviews yet.', style: Theme.of(context).textTheme.bodySmall),
        if (others.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: others.length > maxItems ? maxItems : others.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final r = others[i];
              return _ReviewTile(review: r);
            },
          ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final MenuItemReviewModel review;

  @override
  Widget build(BuildContext context) {
    final created = review.createdAt;
    final dateStr =
        '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';
    final name = (review.userName?.trim().isNotEmpty == true)
        ? review.userName!
        : (review.userEmail ?? 'User ${review.userId}');

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber[700],
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if ((review.comment ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.comment!.trim()),
          ],
        ],
      ),
    );
  }
}
