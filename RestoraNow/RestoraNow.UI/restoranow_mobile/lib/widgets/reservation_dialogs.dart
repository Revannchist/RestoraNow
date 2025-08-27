import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../providers/reservation_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../models/reservation_model.dart';
import '../../../providers/base/base_provider.dart'; // BaseProvider (fixed relative path)

class ReservationDialogResult {
  final bool saved;
  final int? openMenuForReservationId;
  const ReservationDialogResult({
    required this.saved,
    this.openMenuForReservationId,
  });
}

class ReservationFormDialog extends StatefulWidget {
  final ReservationModel? reservation;
  const ReservationFormDialog({Key? key, this.reservation}) : super(key: key);

  @override
  State<ReservationFormDialog> createState() => _ReservationFormDialogState();
}

class _ReservationFormDialogState extends State<ReservationFormDialog> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _date;
  TimeOfDay? _time;
  final _guestCountController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  int? _tableId;
  late final _TableApi _tableApi;
  Future<List<_TableOption>>? _tablesFuture;

  // ignore: unused_field
  List<_TableOption> _allTables = [];
  int? _selectedTableCapacity;

  @override
  void initState() {
    super.initState();
    _tableApi = _TableApi();

    if (widget.reservation != null) {
      final res = widget.reservation!;
      _date = DateTime(
        res.reservationDate.year,
        res.reservationDate.month,
        res.reservationDate.day,
      );
      final parts = res.reservationTime.split(":");
      _time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      _guestCountController.text = res.guestCount.toString();
      _specialRequestsController.text = res.specialRequests ?? "";
      _tableId = res.tableId;
    } else {
      _guestCountController.text = '2';
    }

    _tablesFuture = _tableApi.getTables();
  }

  @override
  void dispose() {
    _guestCountController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  List<_TableOption> _eligibleTables(List<_TableOption> items) {
    final guests = int.tryParse(_guestCountController.text) ?? 0;
    if (guests <= 0) return items;
    return items
        .where((t) => t.capacity == null || t.capacity! >= guests)
        .toList();
  }

  // NEW: resolve the reservation id for the just-created reservation (best-effort)
  Future<int?> _resolveCreatedReservationId({
    required ReservationProvider prov,
    required int userId,
    required DateTime dateOnly,
    required String hhmm,
    required int tableId,
    required int guests,
  }) async {
    // Re-fetch my reservations and try to find a matching one
    await prov.fetchMyReservations(userId);
    final candidates = prov.reservations.where((r) {
      final sameDate =
          r.reservationDate.year == dateOnly.year &&
          r.reservationDate.month == dateOnly.month &&
          r.reservationDate.day == dateOnly.day;
      final sameTime = r.reservationTime.startsWith(hhmm); // hh:mm:...
      final sameTable = r.tableId == tableId;
      final sameGuests = r.guestCount == guests;
      return sameDate && sameTime && sameTable && sameGuests;
    }).toList();

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.id.compareTo(a.id));
    return candidates.first.id;
  }

  Future<void> _submit({required bool andOpenMenu}) async {
    if (!_formKey.currentState!.validate() ||
        _date == null ||
        _time == null ||
        _tableId == null) {
      return;
    }

    final cap = _selectedTableCapacity;
    final guests = int.parse(_guestCountController.text);
    if (cap != null && guests > cap) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guest count exceeds table capacity ($cap).')),
      );
      return;
    }

    final selectedDateTime = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
    if (selectedDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a future time.')),
      );
      return;
    }

    final dateOnly = DateTime(_date!.year, _date!.month, _date!.day);
    final hhmm =
        "${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}";

    final payload = {
      "reservationDate": dateOnly.toIso8601String(),
      "reservationTime": "$hhmm:00",
      "guestCount": guests,
      "specialRequests": _specialRequestsController.text,
      "tableId": _tableId,
    };

    final prov = context.read<ReservationProvider>();
    final me = context.read<UserProvider>().currentUser;
    if (me == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You are not logged in.')));
      return;
    }

    bool success;
    int? reservationIdForMenu;

    if (widget.reservation == null) {
      success = await prov.createReservation(payload, me.id);
      if (success && andOpenMenu) {
        // Try to resolve the new reservation id
        reservationIdForMenu = await _resolveCreatedReservationId(
          prov: prov,
          userId: me.id,
          dateOnly: dateOnly,
          hhmm: hhmm,
          tableId: _tableId!,
          guests: guests,
        );
      }
    } else {
      success = await prov.updateReservation(
        widget.reservation!.id,
        payload,
        me.id,
      );
      if (success && andOpenMenu) {
        reservationIdForMenu = widget.reservation!.id;
      }
    }

    if (!mounted) return;
    if (success) {
      // Return a structured result so the caller can decide what to do
      Navigator.of(context, rootNavigator: true).pop(
        ReservationDialogResult(
          saved: true,
          openMenuForReservationId: reservationIdForMenu,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<ReservationProvider>().isLoading;

    return AlertDialog(
      title: Text(
        widget.reservation == null ? "New Reservation" : "Edit Reservation",
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<List<_TableOption>>(
                future: _tablesFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    );
                  }
                  if (snap.hasError) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Failed to load tables',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          onPressed: () => setState(() {
                            _tablesFuture = _tableApi.getTables();
                          }),
                        ),
                      ],
                    );
                  }

                  final items = snap.data ?? const <_TableOption>[];
                  _allTables = items;

                  if (items.isEmpty) {
                    _tableId = null;
                    _selectedTableCapacity = null;
                    return const Text('No tables found.');
                  }

                  final eligible = _eligibleTables(items);
                  if (eligible.isEmpty) {
                    _tableId = null;
                    _selectedTableCapacity = null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('No tables fit the current guest count.'),
                        const SizedBox(height: 6),
                        Text(
                          'Reduce the number of guests or try a different time.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  }

                  if (_tableId == null ||
                      eligible.every((t) => t.id != _tableId)) {
                    _tableId = eligible.first.id;
                  }

                  _selectedTableCapacity = eligible
                      .firstWhere(
                        (t) => t.id == _tableId,
                        orElse: () => eligible.first,
                      )
                      .capacity;

                  return DropdownButtonFormField<int>(
                    value: _tableId,
                    decoration: const InputDecoration(
                      labelText: 'Table',
                      prefixIcon: Icon(Icons.table_bar_outlined),
                    ),
                    items: eligible
                        .map(
                          (t) => DropdownMenuItem<int>(
                            value: t.id,
                            child: Text(t.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _tableId = v;
                        _selectedTableCapacity = eligible
                            .firstWhere((t) => t.id == v)
                            .capacity;

                        final n = int.tryParse(_guestCountController.text) ?? 0;
                        final cap = _selectedTableCapacity;
                        if (cap != null && n > cap) {
                          _guestCountController.text = cap.toString();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Guest count limited to $cap for this table.',
                              ),
                            ),
                          );
                          _formKey.currentState?.validate();
                        }
                      });
                    },
                    validator: (v) =>
                        v == null ? 'Please select a table' : null,
                  );
                },
              ),
              const SizedBox(height: 12),

              // Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _date == null
                      ? "Pick a date"
                      : "${_date!.year.toString().padLeft(4, '0')}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}",
                ),
                leading: const Icon(Icons.calendar_today),
                trailing: const Icon(Icons.expand_more),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 8),

              // Time
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _time == null
                      ? "Pick a time"
                      : "${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}",
                ),
                leading: const Icon(Icons.schedule),
                trailing: const Icon(Icons.expand_more),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _time ?? TimeOfDay.now(),
                  );
                  if (picked != null) setState(() => _time = picked);
                },
              ),

              // Guests
              TextFormField(
                controller: _guestCountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: "Guest count",
                  prefixIcon: const Icon(Icons.group_outlined),
                  helperText: _selectedTableCapacity == null
                      ? null
                      : "Max ${_selectedTableCapacity} for selected table",
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter number of guests";
                  final n = int.tryParse(v);
                  if (n == null || n < 1)
                    return "Guest count must be at least 1";
                  final cap = _selectedTableCapacity;
                  if (cap != null && n > cap) return "Max $cap for this table";
                  return null;
                },
                onChanged: (_) {
                  setState(() {
                    _formKey.currentState?.validate();
                  });
                },
              ),
              const SizedBox(height: 8),

              // Notes
              TextFormField(
                controller: _specialRequestsController,
                decoration: const InputDecoration(
                  labelText: "Special requests (optional)",
                  prefixIcon: Icon(Icons.comment_outlined),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(
            context,
            rootNavigator: true,
          ).maybePop(const ReservationDialogResult(saved: false)),
          child: const Text("Cancel"),
        ),
        // NEW: Save + Menu
        FilledButton.tonal(
          onPressed: saving ? null : () => _submit(andOpenMenu: true),
          child: const Text("Save + Menu"),
        ),
        FilledButton(
          onPressed: saving ? null : () => _submit(andOpenMenu: false),
          child: const Text("Save"),
        ),
      ],
    );
  }
}

// --- Minimal Table API (unchanged) ---

class _TableOption {
  final int id;
  final String label;
  final int? capacity;
  const _TableOption(this.id, this.label, {this.capacity});

  factory _TableOption.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final number =
        (json['tableNumber'] ?? json['number'] ?? json['name'] ?? '$id')
            .toString();
    final cap = (json['capacity'] ?? json['seats']) as int?;
    final seatsTxt = (cap == null) ? '' : ' • ${cap}p';
    return _TableOption(id, 'Table $number$seatsTxt', capacity: cap);
  }
}

class _TableApi extends BaseProvider<_TableOption> {
  _TableApi() : super('table');
  @override
  _TableOption fromJson(Map<String, dynamic> json) =>
      _TableOption.fromJson(json);

  Future<List<_TableOption>> getTables() async {
    final res = await get(page: 1, pageSize: 200);
    return res.items;
  }
}
