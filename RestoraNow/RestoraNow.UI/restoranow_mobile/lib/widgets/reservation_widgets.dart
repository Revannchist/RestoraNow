import 'package:flutter/material.dart';
import '../models/reservation_model.dart';

/// ---- Utilities ----

String fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String fmtTime(String hhmmss) {
  final p = hhmmss.split(':');
  if (p.length >= 2) return '${p[0].padLeft(2, '0')}:${p[1].padLeft(2, '0')}';
  return hhmmss;
}

DateTime combineDateAndTime(DateTime date, String hhmmss) {
  final p = hhmmss.split(':');
  final h = int.tryParse(p.elementAt(0)) ?? 0;
  final m = int.tryParse(p.elementAt(1)) ?? 0;
  final s = int.tryParse(p.elementAt(2)) ?? 0;
  return DateTime(date.year, date.month, date.day, h, m, s);
}

String statusText(ReservationStatus s) => switch (s) {
      ReservationStatus.pending => 'Pending',
      ReservationStatus.confirmed => 'Confirmed',
      ReservationStatus.cancelled => 'Cancelled',
      ReservationStatus.completed => 'Completed',
      ReservationStatus.noShow => 'No-show',
    };

Color statusColor(ReservationStatus s) => switch (s) {
      ReservationStatus.pending => Colors.orange,
      ReservationStatus.confirmed => Colors.green,
      ReservationStatus.cancelled => Colors.red,
      ReservationStatus.completed => Colors.blueGrey,
      ReservationStatus.noShow => Colors.deepOrange,
    };

/// ---- Widgets ----

class ReservationCard extends StatelessWidget {
  const ReservationCard({
    super.key,
    required this.res,
    required this.onEdit,
    this.onCancel,
  });

  final ReservationModel res;
  final VoidCallback onEdit;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(res.status);
    final subtle = Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                const Icon(Icons.event_seat_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Table ${res.tableNumber ?? res.tableId}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    statusText(res.status),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date / Time / Guests
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 6),
                Text(fmtDate(res.reservationDate)),
                const SizedBox(width: 12),
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 6),
                Text(fmtTime(res.reservationTime)),
                const Spacer(),
                const Icon(Icons.group_outlined, size: 18),
                const SizedBox(width: 6),
                Text('${res.guestCount}'),
              ],
            ),
            const SizedBox(height: 8),

            if ((res.specialRequests ?? '').trim().isNotEmpty) ...[
              Text('Notes', style: subtle),
              const SizedBox(height: 4),
              Text(res.specialRequests!.trim()),
              const SizedBox(height: 8),
            ],

            Row(
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                if (onCancel != null)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel'),
                  ),
                const Spacer(),
                if (res.confirmedAt != null)
                  Text('Confirmed ${fmtDate(res.confirmedAt!)}', style: subtle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyReservationsView extends StatelessWidget {
  const EmptyReservationsView({
    super.key,
    this.onCreate,
    this.label = 'No reservations yet',
    this.hint = 'Tap New to create your first reservation.',
  });

  final VoidCallback? onCreate;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_seat_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(hint, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            if (onCreate != null)
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('New reservation'),
              ),
          ],
        ),
      ),
    );
  }
}

class ReservationsErrorView extends StatelessWidget {
  const ReservationsErrorView({super.key, required this.error, required this.onRetry});
  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
