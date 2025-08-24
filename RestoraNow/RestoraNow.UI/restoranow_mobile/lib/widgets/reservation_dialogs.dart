import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/reservation_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../models/reservation_model.dart';
import '../providers/base/base_provider.dart'; // we’ll reuse BaseProvider

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

    // kick off table load
    _tablesFuture = _tableApi.getTables();
  }

  @override
  void dispose() {
    _guestCountController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _date == null ||
        _time == null ||
        _tableId == null) {
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

    final payload = {
      "reservationDate": DateTime(
        _date!.year,
        _date!.month,
        _date!.day,
      ).toIso8601String(),
      "reservationTime":
          "${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}:00",
      "guestCount": int.parse(_guestCountController.text),
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
    if (widget.reservation == null) {
      success = await prov.createReservation(payload, me.id);
    } else {
      success = await prov.updateReservation(
        widget.reservation!.id,
        payload,
        me.id,
      );
    }

    if (!mounted) return;
    if (success) Navigator.of(context, rootNavigator: true).pop(true);
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
              // Table dropdown
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
                  if (items.isEmpty) {
                    return const Text('No tables found.');
                  }
                  // ensure initial selection
                  _tableId ??= items.first.id;

                  return DropdownButtonFormField<int>(
                    value: _tableId,
                    decoration: const InputDecoration(
                      labelText: 'Table',
                      prefixIcon: Icon(Icons.table_bar_outlined),
                    ),
                    items: items
                        .map(
                          (t) => DropdownMenuItem<int>(
                            value: t.id,
                            child: Text(t.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _tableId = v),
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

              TextFormField(
                controller: _guestCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Guest count",
                  prefixIcon: Icon(Icons.group_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter number of guests";
                  final n = int.tryParse(v);
                  if (n == null || n < 1)
                    return "Guest count must be at least 1";
                  return null;
                },
              ),
              const SizedBox(height: 8),

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
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).maybePop(false),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: saving ? null : _submit,
          child: const Text("Save"),
        ),
      ],
    );
  }
}

/// --- Minimal table API using your BaseProvider pattern ---

class _TableOption {
  final int id;
  final String label;
  const _TableOption(this.id, this.label);

  factory _TableOption.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    // try common properties for display
    final number =
        (json['tableNumber'] ?? json['number'] ?? json['name'] ?? '$id')
            .toString();
    final seats = json['seats'] ?? json['capacity'];
    final seatsTxt = (seats == null) ? '' : ' • ${seats}p';
    return _TableOption(id, 'Table $number$seatsTxt');
  }
}

class _TableApi extends BaseProvider<_TableOption> {
  _TableApi() : super('table'); // -> GET /api/table
  @override
  _TableOption fromJson(Map<String, dynamic> json) =>
      _TableOption.fromJson(json);

  Future<List<_TableOption>> getTables() async {
    final res = await get(page: 1, pageSize: 200);
    return res.items;
  }
}
