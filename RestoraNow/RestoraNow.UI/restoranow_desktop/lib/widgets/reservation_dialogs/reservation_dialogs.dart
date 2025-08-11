import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../models/reservation_model.dart';
import '../../models/user_model.dart';

import '../../providers/reservation_provider.dart';
import 'reservation_dialog_helpers.dart' as helpers;

void showCreateReservationDialog(BuildContext context) {
  final _formKey = GlobalKey<FormState>();

  // User typeahead state
  int? selectedUserId;
  String? userFieldError;
  TextEditingController? _userCtrl;

  // Other fields
  final tableIdController = TextEditingController();
  final dateController = TextEditingController(); // yyyy-MM-dd
  final timeController = TextEditingController(); // HH:mm:ss
  final guestCountController = TextEditingController();
  final specialReqController = TextEditingController();

  // Focus nodes
  final tableIdFocus = FocusNode();
  final dateFocus = FocusNode();
  final timeFocus = FocusNode();
  final guestCountFocus = FocusNode();
  final specialReqFocus = FocusNode();

  // Backend defaults
  ReservationStatus status = ReservationStatus.pending;

  // Client-side validation helpers
  final fieldErrors = <String, String?>{};
  final touched = <String, bool>{};
  bool isFormValid = false;

  void updateFormValidity(StateSetter setState) {
    final ok = _formKey.currentState?.validate() ?? false;
    setState(() => isFormValid = ok);
  }

  void markTouched(String name, StateSetter setState) {
    touched[name] = true;
    updateFormValidity(setState);
  }

  Future<void> pickDate(StateSetter setState) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      dateController.text = helpers.formatDate(picked);
      markTouched('date', setState);
    }
  }

  Future<void> pickTime(StateSetter setState) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      timeController.text = helpers.formatTimeOfDay(picked);
      markTouched('time', setState);
    }
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create Reservation'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ---------- USER PICKER ----------
                      TypeAheadField<UserModel>(
                        suggestionsCallback: helpers.searchUsers,
                        itemBuilder: (context, u) {
                          final email = u.email;
                          return ListTile(
                            title: Text(helpers.displayUser(u)),
                            subtitle: (email.isNotEmpty) ? Text(email) : null,
                            trailing: Text('ID: ${u.id}'),
                          );
                        },
                        onSelected: (u) {
                          selectedUserId = u.id;
                          userFieldError = null;
                          if (_userCtrl != null) {
                            _userCtrl!.text = helpers.displayUser(u);
                          }
                          updateFormValidity(setState);
                        },
                        builder: (context, controller, focusNode) {
                          _userCtrl ??= controller;
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Search user (email/name)',
                              isDense: true,
                              errorText: userFieldError,
                            ),
                            validator: (_) =>
                                selectedUserId == null ? 'Please select a user' : null,
                            onChanged: (_) {
                              if (selectedUserId != null) selectedUserId = null;
                              if (userFieldError != null) userFieldError = null;
                            },
                          );
                        },
                        debounceDuration: const Duration(milliseconds: 300),
                      ),
                      const SizedBox(height: 12),

                      // TableId
                      TextFormField(
                        controller: tableIdController,
                        focusNode: tableIdFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Table number',
                          isDense: true,
                          errorText: fieldErrors['tableId'],
                        ),
                        onChanged: (_) => updateFormValidity(setState),
                        onFieldSubmitted: (_) => markTouched('tableId', setState),
                        onTapOutside: (_) => markTouched('tableId', setState),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (fieldErrors['tableId'] != null) return fieldErrors['tableId'];
                          if (!(touched['tableId'] ?? false)) return null;
                          if (value.isEmpty) return 'Table is required.';
                          final val = int.tryParse(value);
                          if (val == null || val <= 0) return 'Table must be a positive number.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // ReservationDate
                      TextFormField(
                        controller: dateController,
                        focusNode: dateFocus,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Reservation Date',
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.date_range),
                            onPressed: () => pickDate(setState),
                          ),
                          errorText: fieldErrors['reservationDate'],
                        ),
                        onTap: () => pickDate(setState),
                        onChanged: (_) => updateFormValidity(setState),
                        onTapOutside: (_) => markTouched('date', setState),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (fieldErrors['reservationDate'] != null) {
                            return fieldErrors['reservationDate'];
                          }
                          if (!(touched['date'] ?? false)) return null;
                          if (value.isEmpty) return 'Reservation date is required.';
                          if (!helpers.isValidDate(value)) return 'Invalid date format. Use yyyy-MM-dd.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // ReservationTime
                      TextFormField(
                        controller: timeController,
                        focusNode: timeFocus,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Reservation Time',
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () => pickTime(setState),
                          ),
                          errorText: fieldErrors['reservationTime'],
                        ),
                        onTap: () => pickTime(setState),
                        onChanged: (_) => updateFormValidity(setState),
                        onTapOutside: (_) => markTouched('time', setState),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (fieldErrors['reservationTime'] != null) {
                            return fieldErrors['reservationTime'];
                          }
                          if (!(touched['time'] ?? false)) return null;
                          if (value.isEmpty) return 'Reservation time is required.';
                          if (!helpers.isValidTime(value)) return 'Invalid time format. Use HH:mm:ss.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // GuestCount
                      TextFormField(
                        controller: guestCountController,
                        focusNode: guestCountFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Guest Count (1–20)',
                          isDense: true,
                          errorText: fieldErrors['guestCount'],
                        ),
                        onChanged: (_) => updateFormValidity(setState),
                        onFieldSubmitted: (_) => markTouched('guestCount', setState),
                        onTapOutside: (_) => markTouched('guestCount', setState),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (fieldErrors['guestCount'] != null) return fieldErrors['guestCount'];
                          if (!(touched['guestCount'] ?? false)) return null;
                          if (value.isEmpty) return 'Guest count is required.';
                          final val = int.tryParse(value);
                          if (val == null || val < 1 || val > 20) {
                            return 'Guest count must be between 1 and 20.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Special Requests
                      TextFormField(
                        controller: specialReqController,
                        focusNode: specialReqFocus,
                        maxLines: 3,
                        maxLength: 500,
                        decoration: InputDecoration(
                          labelText: 'Special Requests (optional)',
                          isDense: true,
                          errorText: fieldErrors['specialRequests'],
                        ),
                        onChanged: (_) => updateFormValidity(setState),
                        onTapOutside: (_) => markTouched('specialRequests', setState),
                      ),
                      const SizedBox(height: 12),

                      // Status
                      DropdownButtonFormField<ReservationStatus>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: ReservationStatus.pending, child: Text('Pending')),
                          DropdownMenuItem(value: ReservationStatus.confirmed, child: Text('Confirmed')),
                          DropdownMenuItem(value: ReservationStatus.cancelled, child: Text('Cancelled')),
                          DropdownMenuItem(value: ReservationStatus.completed, child: Text('Completed')),
                          DropdownMenuItem(value: ReservationStatus.noShow, child: Text('NoShow')),
                        ],
                        onChanged: (v) {
                          if (v != null) status = v;
                          updateFormValidity(setState);
                        },
                      ),

                      if (fieldErrors['general'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(fieldErrors['general']!, style: const TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: isFormValid
                    ? () async {
                        final uid = selectedUserId;
                        if (uid == null) {
                          setState(() => userFieldError = 'Please select a user');
                          _formKey.currentState?.validate();
                          return;
                        }

                        setState(() => fieldErrors.clear());

                        final tableId    = int.parse(tableIdController.text.trim());
                        final date       = DateTime.parse(dateController.text.trim());
                        final time       = timeController.text.trim();
                        final guestCount = int.parse(guestCountController.text.trim());

                        final model = ReservationModel(
                          id: 0,
                          userId: uid,
                          tableId: tableId,
                          reservationDate: date,
                          reservationTime: time,
                          guestCount: guestCount,
                          status: status,
                          specialRequests: specialReqController.text.trim().isEmpty
                              ? null
                              : specialReqController.text.trim(),
                          userName: null,
                          tableNumber: null,
                          confirmedAt: null,
                        );

                        try {
                          final created = await context.read<ReservationProvider>().createItem(model);
                          if (created != null && context.mounted) Navigator.pop(context);
                        } on http.Response catch (response) {
                          setState(() {
                            helpers.mapServerErrors(response, fieldErrors);
                            userFieldError = fieldErrors['userId'];
                          });
                          _formKey.currentState?.validate();
                        } catch (e) {
                          setState(() => fieldErrors['general'] = e.toString());
                          _formKey.currentState?.validate();
                        }
                      }
                    : null,
                child: const Text('Create'),
              ),
            ],
          );
        },
      );
    },
  );
}

void showUpdateReservationDialog(BuildContext context, ReservationModel item) {
  final _formKey = GlobalKey<FormState>();

  // Prefill typeahead state
  int? selectedUserId = item.userId;
  String? userFieldError;
  TextEditingController? _userCtrl;
  final String _initialUserText = item.userName ?? 'User #${item.userId}';

  // Other fields
  final tableIdController = TextEditingController(text: item.tableId.toString());
  final dateController    = TextEditingController(text: helpers.formatDate(item.reservationDate));
  final timeController    = TextEditingController(text: item.reservationTime);
  final guestCountController = TextEditingController(text: item.guestCount.toString());
  final specialReqController = TextEditingController(text: item.specialRequests ?? '');

  // Focus nodes
  final tableIdFocus = FocusNode();
  final dateFocus = FocusNode();
  final timeFocus = FocusNode();
  final guestCountFocus = FocusNode();
  final specialReqFocus = FocusNode();

  ReservationStatus status = item.status;

  final fieldErrors = <String, String?>{};
  final touched = <String, bool>{};
  bool isFormValid = true;

  void updateFormValidity(StateSetter setState) {
    setState(() => isFormValid = _formKey.currentState?.validate() ?? false);
  }

  void markTouched(String name, StateSetter setState) {
    touched[name] = true;
    updateFormValidity(setState);
  }

  Future<void> pickDate(StateSetter setState) async {
    final now = DateTime.now();
    final init = helpers.tryParseDate(dateController.text) ?? item.reservationDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      dateController.text = helpers.formatDate(picked);
      markTouched('date', setState);
    }
  }

  Future<void> pickTime(StateSetter setState) async {
    final current = helpers.parseTimeOfDay(timeController.text) ??
        const TimeOfDay(hour: 12, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) {
      timeController.text = helpers.formatTimeOfDay(picked);
      markTouched('time', setState);
    }
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Update Reservation'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ---------- USER PICKER ----------
                      TypeAheadField<UserModel>(
                        suggestionsCallback: helpers.searchUsers,
                        itemBuilder: (context, u) {
                          final email = u.email;
                          return ListTile(
                            title: Text(helpers.displayUser(u)),
                            subtitle: (email.isNotEmpty) ? Text(email) : null,
                            trailing: Text('ID: ${u.id}'),
                          );
                        },
                        onSelected: (u) {
                          selectedUserId = u.id;
                          userFieldError = null;
                          if (_userCtrl != null) {
                            _userCtrl!.text = helpers.displayUser(u);
                          }
                          updateFormValidity(setState);
                        },
                        builder: (context, controller, focusNode) {
                          _userCtrl ??= controller;
                          if (controller.text.isEmpty) controller.text = _initialUserText;
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Search user (email/name)',
                              isDense: true,
                              errorText: userFieldError,
                            ),
                            validator: (_) =>
                                selectedUserId == null ? 'Please select a user' : null,
                            onChanged: (_) {
                              if (selectedUserId != null) selectedUserId = null;
                              if (userFieldError != null) userFieldError = null;
                            },
                          );
                        },
                        debounceDuration: const Duration(milliseconds: 300),
                      ),
                      const SizedBox(height: 12),

                      // TableId
                      TextFormField(
                        controller: tableIdController,
                        focusNode: tableIdFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Table number',
                          isDense: true,
                          errorText: fieldErrors['tableId'],
                        ),
                        onChanged: (_) => updateFormValidity(setState),
                        onFieldSubmitted: (_) => markTouched('tableId', setState),
                        onTapOutside: (_) => markTouched('tableId', setState),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (fieldErrors['tableId'] != null) return fieldErrors['tableId'];
                          if (!(touched['tableId'] ?? false)) return null;
                          if (value.isEmpty) return 'TableId is required.';
                          final val = int.tryParse(value);
                          if (val == null || val <= 0) return 'TableId must be a positive number.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Date
                      TextFormField(
                        controller: dateController,
                        focusNode: dateFocus,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Reservation Date (yyyy-MM-dd)',
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.date_range),
                            onPressed: () => pickDate(setState),
                          ),
                          errorText: fieldErrors['reservationDate'],
                        ),
                        onTap: () => pickDate(setState),
                        onChanged: (_) => updateFormValidity(setState),
                        onTapOutside: (_) => markTouched('date', setState),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (fieldErrors['reservationDate'] != null) return fieldErrors['reservationDate'];
                          if (!(touched['date'] ?? false)) return null;
                          if (value.isEmpty) return 'Reservation date is required.';
                          if (!helpers.isValidDate(value)) return 'Invalid date format. Use yyyy-MM-dd.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Time
                      TextFormField(
                        controller: timeController,
                        focusNode: timeFocus,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Reservation Time (HH:mm:ss)',
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () => pickTime(setState),
                          ),
                          errorText: fieldErrors['reservationTime'],
                        ),
                        onTap: () => pickTime(setState),
                        onChanged: (_) => updateFormValidity(setState),
                        onTapOutside: (_) => markTouched('time', setState),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (fieldErrors['reservationTime'] != null) return fieldErrors['reservationTime'];
                          if (!(touched['time'] ?? false)) return null;
                          if (value.isEmpty) return 'Reservation time is required.';
                          if (!helpers.isValidTime(value)) return 'Invalid time format. Use HH:mm:ss.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // GuestCount
                      TextFormField(
                        controller: guestCountController,
                        focusNode: guestCountFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Guest Count (1–20)',
                          isDense: true,
                          errorText: fieldErrors['guestCount'],
                        ),
                        onChanged: (_) => updateFormValidity(setState),
                        onFieldSubmitted: (_) => markTouched('guestCount', setState),
                        onTapOutside: (_) => markTouched('guestCount', setState),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (fieldErrors['guestCount'] != null) return fieldErrors['guestCount'];
                          if (!(touched['guestCount'] ?? false)) return null;
                          if (value.isEmpty) return 'Guest count is required.';
                          final val = int.tryParse(value);
                          if (val == null || val < 1 || val > 20) {
                            return 'Guest count must be between 1 and 20.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Special Requests
                      TextFormField(
                        controller: specialReqController,
                        focusNode: specialReqFocus,
                        maxLines: 3,
                        maxLength: 500,
                        decoration: InputDecoration(
                          labelText: 'Special Requests (optional)',
                          isDense: true,
                          errorText: fieldErrors['specialRequests'],
                        ),
                        onChanged: (_) => updateFormValidity(setState),
                        onTapOutside: (_) => markTouched('specialRequests', setState),
                      ),
                      const SizedBox(height: 12),

                      // Status
                      DropdownButtonFormField<ReservationStatus>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: ReservationStatus.pending, child: Text('Pending')),
                          DropdownMenuItem(value: ReservationStatus.confirmed, child: Text('Confirmed')),
                          DropdownMenuItem(value: ReservationStatus.cancelled, child: Text('Cancelled')),
                          DropdownMenuItem(value: ReservationStatus.completed, child: Text('Completed')),
                          DropdownMenuItem(value: ReservationStatus.noShow, child: Text('NoShow')),
                        ],
                        onChanged: (v) {
                          if (v != null) status = v;
                          updateFormValidity(setState);
                        },
                      ),

                      if (fieldErrors['general'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(fieldErrors['general']!, style: const TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: isFormValid
                    ? () async {
                        final uid = selectedUserId;
                        if (uid == null) {
                          setState(() => userFieldError = 'Please select a user');
                          _formKey.currentState?.validate();
                          return;
                        }

                        setState(() => fieldErrors.clear());

                        final updated = ReservationModel(
                          id: item.id,
                          userId: uid,
                          tableId: int.parse(tableIdController.text.trim()),
                          reservationDate: DateTime.parse(dateController.text.trim()),
                          reservationTime: timeController.text.trim(),
                          guestCount: int.parse(guestCountController.text.trim()),
                          status: status,
                          specialRequests: specialReqController.text.trim().isEmpty
                              ? null
                              : specialReqController.text.trim(),
                          userName: item.userName,
                          tableNumber: item.tableNumber,
                          confirmedAt: item.confirmedAt,
                        );

                        try {
                          await context.read<ReservationProvider>().updateItem(updated);
                          if (context.mounted) Navigator.pop(context);
                        } on http.Response catch (response) {
                          setState(() {
                            helpers.mapServerErrors(response, fieldErrors);
                            userFieldError = fieldErrors['userId'];
                          });
                          _formKey.currentState?.validate();
                        } catch (e) {
                          setState(() => fieldErrors['general'] = e.toString());
                          _formKey.currentState?.validate();
                        }
                      }
                    : null,
                child: const Text('Update'),
              ),
            ],
          );
        },
      );
    },
  );
}