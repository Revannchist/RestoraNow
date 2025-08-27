import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restoranow_mobile/screens/menu_screen.dart';

import '../providers/reservation_provider.dart';
import '../providers/user_provider.dart';
import '../models/reservation_model.dart';
import '../widgets/reservation_dialogs.dart';
import '../widgets/reservation_widgets.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});
  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  bool _initialized = false;
  bool _showPast = false; // filter state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<ReservationProvider>();
      final me = context.read<UserProvider>().currentUser;
      if (me == null) return;
      await prov.fetchMyReservations(me.id);
      if (!mounted) return;
      setState(() => _initialized = true);
    });
  }

  Future<void> _refresh() async {
    final me = context.read<UserProvider>().currentUser;
    if (me == null) return;
    await context.read<ReservationProvider>().fetchMyReservations(me.id);
  }

  Future<void> _openReservationDialog({ReservationModel? reservation}) async {
    final result = await showDialog<ReservationDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ReservationFormDialog(reservation: reservation),
    );

    if (!mounted || result == null) return;

    if (result.saved) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reservation saved')));

      // If user chose "Save + Menu", open menu for that reservation
      final rid = result.openMenuForReservationId;
      if (rid != null) {
        // Navigate to your Menu screen, passing reservationId
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MenuScreen(reservationId: rid)),
        );
      } else {
        // Normal flow: maybe refresh list
        await _refresh();
      }
    }
  }

  Future<void> _confirmCancel(ReservationModel res) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel reservation?'),
        content: Text(
          'Table ${res.tableNumber ?? res.tableId}\n'
          '${fmtDate(res.reservationDate)} at ${fmtTime(res.reservationTime)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (yes == true) {
      final ok = await context.read<ReservationProvider>().cancelReservation(
        res.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Reservation canceled' : 'Failed to cancel'),
        ),
      );
    }
  }

  void _openFilterSheet() async {
    final choice = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              value: false,
              groupValue: _showPast,
              title: const Text('Upcoming'),
              subtitle: const Text(
                'Only future reservations (excluding cancelled)',
              ),
              onChanged: (v) => Navigator.pop(ctx, v),
            ),
            RadioListTile<bool>(
              value: true,
              groupValue: _showPast,
              title: const Text('Past / History'),
              subtitle: const Text('Past, cancelled, completed, no-show'),
              onChanged: (v) => Navigator.pop(ctx, v),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
    if (choice != null && mounted) {
      setState(() => _showPast = choice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ReservationProvider>();
    final me = context.watch<UserProvider>().currentUser;
    final isLoading = prov.isLoading && !_initialized;

    // filter list
    final now = DateTime.now();
    List<ReservationModel> filtered = prov.reservations.where((r) {
      final dt = combineDateAndTime(r.reservationDate, r.reservationTime);
      final isPast =
          dt.isBefore(now) ||
          r.status == ReservationStatus.cancelled ||
          r.status == ReservationStatus.completed ||
          r.status == ReservationStatus.noShow;

      return _showPast ? isPast : !isPast;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // fallback if opened as a top-level destination
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
        title: const Text('My Reservations'),
        actions: [
          TextButton.icon(
            onPressed: _openFilterSheet,
            icon: const Icon(Icons.filter_list),
            label: Text(_showPast ? 'History' : 'Upcoming'),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : prov.error != null
          ? ReservationsErrorView(
              error: prov.error!,
              onRetry: () async {
                if (me != null) await prov.fetchMyReservations(me.id);
              },
            )
          : filtered.isEmpty
          ? EmptyReservationsView(
              onCreate: () => _openReservationDialog(),
              label: _showPast
                  ? 'No past reservations'
                  : 'No upcoming reservations',
              hint: _showPast
                  ? 'Switch to Upcoming to see future reservations.'
                  : 'Tap New to create one.',
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final res = filtered[i];
                  final canCancel =
                      res.status != ReservationStatus.cancelled &&
                      combineDateAndTime(
                        res.reservationDate,
                        res.reservationTime,
                      ).isAfter(DateTime.now());

                  return ReservationCard(
                    res: res,
                    onEdit: () => _openReservationDialog(reservation: res),
                    onCancel: canCancel ? () => _confirmCancel(res) : null,
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openReservationDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
    );
  }
}
