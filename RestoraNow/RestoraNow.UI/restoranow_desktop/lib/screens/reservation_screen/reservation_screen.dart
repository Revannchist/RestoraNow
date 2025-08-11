import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../layouts/main_layout.dart';
import '../../models/reservation_model.dart';
import '../../providers/reservation_provider.dart';
import '../../widgets/pagination_controls.dart';
import '../../widgets/reservation_dialogs/reservation_dialogs.dart'; // implement create/update dialogs

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({Key? key}) : super(key: key);

  @override
  State<ReservationListScreen> createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _tableIdController = TextEditingController();
  final FocusNode _userIdFocus = FocusNode();
  final FocusNode _tableIdFocus = FocusNode();

  DateTime? _fromDate;
  DateTime? _toDate;
  ReservationStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ReservationProvider>(context, listen: false);
    provider.fetchItems();

    _userIdFocus.addListener(() {
      if (!_userIdFocus.hasFocus) _applyFilters();
    });
    _tableIdFocus.addListener(() {
      if (!_tableIdFocus.hasFocus) _applyFilters();
    });
  }

  @override
  void dispose() {
    _userIdFocus.dispose();
    _tableIdFocus.dispose();
    _userIdController.dispose();
    _tableIdController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final provider = Provider.of<ReservationProvider>(context, listen: false);
    final userId = _userIdController.text.trim().isEmpty
        ? null
        : int.tryParse(_userIdController.text.trim());
    final tableId = _tableIdController.text.trim().isEmpty
        ? null
        : int.tryParse(_tableIdController.text.trim());

    provider.setFilters(
      userId: userId,
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
    );
    if (picked != null) {
      setState(() => _toDate = picked);
      _applyFilters();
    }
  }

  void _resetFilters() {
    _userIdController.clear();
    _tableIdController.clear();
    setState(() {
      _selectedStatus = null;
      _fromDate = null;
      _toDate = null;
    });
    Provider.of<ReservationProvider>(context, listen: false).setFilters();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Consumer<ReservationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          return Column(
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
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: _userIdController,
                        focusNode: _userIdFocus,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'User ID'),
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: _tableIdController,
                        focusNode: _tableIdFocus,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Table ID'),
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                    DropdownButton<ReservationStatus?>(
                      value: _selectedStatus,
                      hint: const Text('Status'),
                      onChanged: (val) {
                        setState(() => _selectedStatus = val);
                        _applyFilters();
                      },
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('All'),
                        ),
                        DropdownMenuItem(
                          value: ReservationStatus.pending,
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: ReservationStatus.confirmed,
                          child: Text('Confirmed'),
                        ),
                        DropdownMenuItem(
                          value: ReservationStatus.cancelled,
                          child: Text('Cancelled'),
                        ),
                        DropdownMenuItem(
                          value: ReservationStatus.completed,
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: ReservationStatus.noShow,
                          child: Text('NoShow'),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickFromDate,
                      icon: const Icon(Icons.date_range),
                      label: Text(_fromDate == null
                          ? 'From date'
                          : _formatDate(_fromDate!)),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickToDate,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                          _toDate == null ? 'To date' : _formatDate(_toDate!)),
                    ),
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // List
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: ListView.builder(
                    key: ValueKey(provider.items.length),
                    itemCount: provider.items.length,
                    itemBuilder: (context, index) {
                      final r = provider.items[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    r.tableNumber != null
                                        ? 'Table ${r.tableNumber}'
                                        : 'Table #${r.tableId}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            // Date / Time
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${_formatDate(r.reservationDate)} ${r.reservationTime}',
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
                                  const Icon(Icons.group,
                                      size: 16, color: Colors.grey),
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
                            // Actions
                            SizedBox(
                              width: 96,
                              child: Center(
                                child: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () => showUpdateReservationDialog(
                                        context,
                                        r,
                                      ),
                                    ),
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
                  ),
                ),
              ),
              const SizedBox(height: 8),

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
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _statusChip(ReservationStatus status) {
    final text = () {
      switch (status) {
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
    }();

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
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content:
              const Text('Are you sure you want to delete this reservation?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await context.read<ReservationProvider>().deleteItem(id);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
