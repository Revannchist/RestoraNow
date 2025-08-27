import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/base/auth_provider.dart';
import '../providers/reservation_provider.dart';
import '../models/reservation_model.dart';
import '../screens/checkout_screen.dart';

/// Open the cart sheet (optionally preselect a reservation).
void showCartSheet(BuildContext context, {int? reservationId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CartSheet(reservationId: reservationId),
  );
}

class _CartSheet extends StatefulWidget {
  final int? reservationId; // If coming from "Save + Menu"
  const _CartSheet({this.reservationId});

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

enum _TargetOption { delivery, reservation }

class _CartSheetState extends State<_CartSheet> {
  _TargetOption _mode = _TargetOption.delivery;
  int? _selectedReservationId;

  @override
  void initState() {
    super.initState();

    // If a reservation id is passed in, default to attach-to-reservation mode
    if (widget.reservationId != null) {
      _mode = _TargetOption.reservation;
      _selectedReservationId = widget.reservationId;
    }

    // Load my reservations for the dropdown (pending/confirmed, future)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = context.read<AuthProvider>().userId;
      if (userId == null) return;

      await context.read<ReservationProvider>().fetchMyReservations(userId);

      // Ensure preselected reservation is actually available
      final prov = context.read<ReservationProvider>();
      final exists = prov.reservations.any(
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
    });
  }

  // Helpers

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

    // Data URI
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

    // Normal URL (fix emulator localhost)
    final url = raw
        .replaceFirst('://localhost', '://10.0.2.2')
        .replaceFirst('://127.0.0.1', '://10.0.2.2');

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

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final resProv = context.watch<ReservationProvider>();
    final now = DateTime.now();

    // Filter reservations: pending or confirmed, and in the future
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

          // Dining option / Attach to reservation
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'How would you like to proceed?',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 6),

          RadioListTile<_TargetOption>(
            dense: true,
            value: _TargetOption.delivery,
            groupValue: _mode,
            title: const Text('Delivery / Takeaway (no reservation)'),
            onChanged: (v) => setState(() {
              _mode = v!;
              _selectedReservationId = null;
            }),
          ),

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
              if (eligible.length == 1)
                _selectedReservationId = eligible.single.id;
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
                  final raw = item.imageUrls.isNotEmpty
                      ? item.imageUrls.first
                      : null;

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
          Row(
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
                          // Validate reservation selection if needed
                          int? reservationId;
                          if (_mode == _TargetOption.reservation) {
                            if (_selectedReservationId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a reservation.'),
                                ),
                              );
                              return;
                            }
                            reservationId = _selectedReservationId;
                          }

                          // Close the sheet, then push the review/checkout screen
                          final nav = Navigator.of(context);
                          nav.pop();
                          Future.microtask(() {
                            nav.push(
                              MaterialPageRoute(
                                builder: (_) => CheckoutScreen(
                                  reservationId: reservationId,
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
