import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';

import '../../layouts/main_layout.dart';
import '../../models/reservation_model.dart';
import '../../providers/reservation_provider.dart';
import '../../widgets/pagination_controls.dart';
import '../../widgets/reservation_dialogs/reservation_dialogs.dart';

import '../../models/user_model.dart';
import '../../widgets/order_dialogs/order_dialog_helpers.dart' as helpers;

// overlays
import '../../widgets/helpers/error_dialog_helper.dart' as msg;
import '../../core/api_exception.dart';

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({Key? key}) : super(key: key);

  @override
  State<ReservationListScreen> createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen> {
  // User (TypeAhead → selects UserId)
  final TextEditingController _userCtrl = TextEditingController();
  int? _selectedUserId;
  String? _userError;

  // Table
  final TextEditingController _tableIdController = TextEditingController();
  final FocusNode _tableIdFocus = FocusNode();

  // Status + Dates
  DateTime? _fromDate;
  DateTime? _toDate;
  ReservationStatus? _selectedStatus;

  // overlay guard
  String? _lastErrorShown;

  // inline busy flags for status changes
  final Set<int> _busyReservations = <int>{};

  @override
  void initState() {
    super.initState();
    Provider.of<ReservationProvider>(context, listen: false).fetchItems();

    _tableIdFocus.addListener(() {
      if (!_tableIdFocus.hasFocus) _applyFilters();
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _tableIdFocus.dispose();
    _tableIdController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final provider = Provider.of<ReservationProvider>(context, listen: false);
    final tableId = _tableIdController.text.trim().isEmpty
        ? null
        : int.tryParse(_tableIdController.text.trim());

    provider.setFilters(
      userId: _selectedUserId,
      tableId: tableId,
      status: _selectedStatus,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      useRootNavigator: true,
    );
    if (picked != null) {
      setState(() => _fromDate = picked);
      _applyFilters();
    }
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      useRootNavigator: true,
    );
    if (picked != null) {
      setState(() => _toDate = picked);
      _applyFilters();
    }
  }

  void _resetFilters() {
    _userCtrl.clear();
    _selectedUserId = null;
    _userError = null;

    _tableIdController.clear();
    setState(() {
      _selectedStatus = null;
      _fromDate = null;
      _toDate = null;
    });
    Provider.of<ReservationProvider>(context, listen: false).setFilters();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ---------- inline status change ----------
  List<_ResAction> _actionsFor(ReservationStatus current) {
    // Mirror sensible transitions.
    // Adjust if your API enforces stricter rules.
    switch (current) {
      case ReservationStatus.pending:
        return const [
          _ResAction(ReservationStatus.confirmed, 'Confirm', Icons.check_circle_outline),
          _ResAction(ReservationStatus.cancelled, 'Cancel', Icons.cancel_outlined),
        ];
      case ReservationStatus.confirmed:
        return const [
          _ResAction(ReservationStatus.completed, 'Complete', Icons.flag_circle_outlined),
          _ResAction(ReservationStatus.noShow, 'No-show', Icons.report_outlined),
          _ResAction(ReservationStatus.cancelled, 'Cancel', Icons.cancel_outlined),
        ];
      case ReservationStatus.completed:
        // Often terminal; include Cancel if your backend allows it. Remove if not.
        return const [
          _ResAction(ReservationStatus.cancelled, 'Cancel', Icons.cancel_outlined),
        ];
      case ReservationStatus.cancelled:
      case ReservationStatus.noShow:
        return const [];
    }
  }

  Future<void> _changeStatusInline(ReservationModel r, ReservationStatus target) async {
    if (_busyReservations.contains(r.id)) return;
    setState(() => _busyReservations.add(r.id));
    try {
      final updated = ReservationModel(
        id: r.id,
        userId: r.userId,
        tableId: r.tableId,
        reservationDate: r.reservationDate,
        reservationTime: r.reservationTime,
        guestCount: r.guestCount,
        status: target,
        specialRequests: r.specialRequests,
        userName: r.userName,
        tableNumber: r.tableNumber,
        confirmedAt: r.confirmedAt,
      );

      await context.read<ReservationProvider>().updateItem(updated);

      if (!mounted) return;
      msg.showOverlayMessage(
        context,
        'Reservation set to ${_statusText(target)}',
        type: msg.AppMessageType.success,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      msg.showAnyErrorOnTop(context, e);
    } catch (_) {
      if (!mounted) return;
      msg.showOverlayMessage(context, 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busyReservations.remove(r.id));
    }
  }

  String _statusText(ReservationStatus s) {
    switch (s) {
      case ReservationStatus.pending:
        return 'Pending';
      case ReservationStatus.confirmed:
        return 'Confirmed';
      case ReservationStatus.cancelled:
        return 'Cancelled';
      case ReservationStatus.completed:
        return 'Completed';
      case ReservationStatus.noShow:
        return 'NoShow';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Consumer<ReservationProvider>(
        builder: (context, provider, child) {
          // overlay error once
          if (provider.error != null &&
              provider.error!.isNotEmpty &&
              provider.error != _lastErrorShown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              msg.showOverlayMessage(context, provider.error!);
              _lastErrorShown = provider.error;
            });
          }

          final isFirst = provider.isLoading && provider.items.isEmpty;

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Add button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => showCreateReservationDialog(context),
                        child: const Text('Add Reservation'),
                      ),
                    ),
                  ),

                  // Filters
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // User TypeAhead
                        SizedBox(
                          width: 260,
                          child: TypeAheadField<UserModel>(
                            suggestionsCallback: helpers.searchUsers,
                            itemBuilder: (context, u) => ListTile(
                              dense: true,
                              title: Text(helpers.displayUser(u)),
                              subtitle: u.email.isNotEmpty ? Text(u.email) : null,
                              trailing: Text('ID: ${u.id}'),
                            ),
                            onSelected: (u) {
                              _selectedUserId = u.id;
                              _userError = null;
                              _userCtrl.text = helpers.displayUser(u);
                              _applyFilters();
                            },
                            builder: (context, controller, focusNode) {
                              controller.text = _userCtrl.text;
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Filter by User (email/name)',
                                  isDense: true,
                                  errorText: _userError,
                                  suffixIcon: _userCtrl.text.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'Clear',
                                          onPressed: () {
                                            _userCtrl.clear();
                                            _selectedUserId = null;
                                            _applyFilters();
                                          },
                                          icon: const Icon(Icons.close),
                                        ),
                                ),
                                onChanged: (_) {
                                  _selectedUserId = null;
                                  if (_userError != null) setState(() => _userError = null);
                                },
                                onSubmitted: (_) {
                                  _selectedUserId = int.tryParse(_userCtrl.text.trim());
                                  _applyFilters();
                                },
                              );
                            },
                            debounceDuration: const Duration(milliseconds: 300),
                          ),
                        ),

                        // Table
                        SizedBox(
                          width: 160,
                          child: TextField(
                            controller: _tableIdController,
                            focusNode: _tableIdFocus,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Table number'),
                            onSubmitted: (_) => _applyFilters(),
                          ),
                        ),

                        // Status
                        DropdownButton<ReservationStatus?>(
                          value: _selectedStatus,
                          hint: const Text('Status'),
                          onChanged: (val) {
                            setState(() => _selectedStatus = val);
                            _applyFilters();
                          },
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All')),
                            DropdownMenuItem(value: ReservationStatus.pending, child: Text('Pending')),
                            DropdownMenuItem(value: ReservationStatus.confirmed, child: Text('Confirmed')),
                            DropdownMenuItem(value: ReservationStatus.cancelled, child: Text('Cancelled')),
                            DropdownMenuItem(value: ReservationStatus.completed, child: Text('Completed')),
                            DropdownMenuItem(value: ReservationStatus.noShow, child: Text('NoShow')),
                          ],
                        ),

                        // Dates
                        OutlinedButton.icon(
                          onPressed: _pickFromDate,
                          icon: const Icon(Icons.date_range),
                          label: Text(_fromDate == null ? 'From date' : _fmtDate(_fromDate!)),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickToDate,
                          icon: const Icon(Icons.date_range),
                          label: Text(_toDate == null ? 'To date' : _fmtDate(_toDate!)),
                        ),

                        TextButton(onPressed: _resetFilters, child: const Text('Reset')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // List
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: isFirst
                          ? const Center(child: CircularProgressIndicator())
                          : (provider.items.isEmpty
                              ? const Center(child: Text('No reservations found'))
                              : ListView.builder(
                                  key: ValueKey(provider.items.length),
                                  itemCount: provider.items.length,
                                  itemBuilder: (context, index) {
                                    final r = provider.items[index];
                                    final actions = _actionsFor(r.status);
                                    final busy = _busyReservations.contains(r.id);

                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Theme.of(context).dividerColor),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // User / Table
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  r.userName ?? 'User #${r.userId}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  r.tableNumber != null ? 'Table ${r.tableNumber}' : 'Table #${r.tableId}',
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Date / Time
                                          Expanded(
                                            child: Row(
                                              children: [
                                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    '${_fmtDate(r.reservationDate)} ${r.reservationTime}',
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Guests
                                          Expanded(
                                            child: Row(
                                              children: [
                                                const Icon(Icons.group, size: 16, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text('${r.guestCount}'),
                                              ],
                                            ),
                                          ),
                                          // Status
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: _statusChip(r.status),
                                            ),
                                          ),
                                          // Actions: Change status (left), Edit (middle), Delete (rightmost)
                                          SizedBox(
                                            width: 160,
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // 1) Change status
                                                  if (busy)
                                                    const SizedBox(
                                                      width: 22,
                                                      height: 22,
                                                      child: Padding(
                                                        padding: EdgeInsets.all(2),
                                                        child: CircularProgressIndicator(strokeWidth: 2),
                                                      ),
                                                    )
                                                  else if (actions.isNotEmpty)
                                                    PopupMenuButton<_ResAction>(
                                                      tooltip: 'Change status',
                                                      icon: const Icon(Icons.sync_alt, size: 18),
                                                      itemBuilder: (ctx) => actions
                                                          .map(
                                                            (a) => PopupMenuItem<_ResAction>(
                                                              value: a,
                                                              child: Row(
                                                                children: [
                                                                  Icon(a.icon, size: 18),
                                                                  const SizedBox(width: 8),
                                                                  Text(a.label),
                                                                ],
                                                              ),
                                                            ),
                                                          )
                                                          .toList(),
                                                      onSelected: (a) => _changeStatusInline(r, a.target),
                                                    ),

                                                  const SizedBox(width: 4),

                                                  // 2) Edit
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, size: 18),
                                                    onPressed: () => showUpdateReservationDialog(context, r),
                                                  ),

                                                  const SizedBox(width: 4),

                                                  // 3) Delete
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, size: 18),
                                                    color: Colors.red,
                                                    onPressed: () => _confirmDelete(context, r.id),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )),
                    ),
                  ),

                  // Pagination
                  PaginationControls(
                    currentPage: provider.currentPage,
                    totalPages: provider.totalPages,
                    pageSize: provider.pageSize,
                    onPageChange: (page) => provider.setPage(page),
                    onPageSizeChange: (newSize) => provider.setPageSize(newSize),
                  ),
                  const SizedBox(height: 8),
                ],
              ),

              if (provider.isLoading && provider.items.isNotEmpty)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusChip(ReservationStatus status) {
    final text = _statusText(status);

    final bg = () {
      switch (status) {
        case ReservationStatus.pending:
          return Colors.amber.withOpacity(0.2);
        case ReservationStatus.confirmed:
          return Colors.green.withOpacity(0.2);
        case ReservationStatus.cancelled:
          return Colors.red.withOpacity(0.2);
        case ReservationStatus.completed:
          return Colors.blueGrey.withOpacity(0.2);
        case ReservationStatus.noShow:
          return Colors.orange.withOpacity(0.2);
      }
    }();

    final fg = () {
      switch (status) {
        case ReservationStatus.pending:
          return Colors.amber[800];
        case ReservationStatus.confirmed:
          return Colors.green[800];
        case ReservationStatus.cancelled:
          return Colors.red[800];
        case ReservationStatus.completed:
          return Colors.blueGrey[800];
        case ReservationStatus.noShow:
          return Colors.orange[800];
      }
    }();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this reservation?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await context.read<ReservationProvider>().deleteItem(id);
                if (!mounted) return;
                Navigator.pop(context);
                msg.showOverlayMessage(context, 'Reservation deleted', type: msg.AppMessageType.success);
              } on ApiException catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                msg.showAnyErrorOnTop(context, e);
              } catch (_) {
                if (!mounted) return;
                Navigator.pop(context);
                msg.showOverlayMessage(context, 'Something went wrong. Please try again.');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Small helper to describe menu options
class _ResAction {
  final ReservationStatus target;
  final String label;
  final IconData icon;
  const _ResAction(this.target, this.label, this.icon);
}
