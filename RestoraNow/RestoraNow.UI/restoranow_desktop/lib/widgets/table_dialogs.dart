import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/table_model.dart';
import '../providers/table_provider.dart';

/// CREATE TABLE
void showCreateTableDialog(BuildContext context) {
  final _formKey = GlobalKey<FormState>();

  final tableNumberController = TextEditingController();
  final capacityController    = TextEditingController();
  final locationController    = TextEditingController();
  final notesController       = TextEditingController();

  final tableNumberFocus = FocusNode();
  final capacityFocus    = FocusNode();
  final locationFocus    = FocusNode();

  bool isAvailable = true;

  // touch + validity state (blur-to-validate like your menu create)
  bool tableNumberTouched = false;
  bool capacityTouched    = false;
  bool locationTouched    = false;
  bool isFormValid        = false;

  void updateFormValidity(StateSetter setState) {
    final tn = int.tryParse(tableNumberController.text.trim());
    final cp = int.tryParse(capacityController.text.trim());
    final loc = locationController.text.trim();

    final tnValid  = tn != null && tn > 0;
    final cpValid  = cp != null && cp > 0;
    final locValid = loc.isNotEmpty && loc.length <= 20;

    setState(() => isFormValid = tnValid && cpValid && locValid);
  }

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        // blur listeners (same pattern as your menu dialog)
        tableNumberFocus.addListener(() {
          if (!tableNumberFocus.hasFocus) {
            tableNumberTouched = true;
            updateFormValidity(setState);
            _formKey.currentState?.validate();
          }
        });
        capacityFocus.addListener(() {
          if (!capacityFocus.hasFocus) {
            capacityTouched = true;
            updateFormValidity(setState);
            _formKey.currentState?.validate();
          }
        });
        locationFocus.addListener(() {
          if (!locationFocus.hasFocus) {
            locationTouched = true;
            updateFormValidity(setState);
            _formKey.currentState?.validate();
          }
        });

        return AlertDialog(
          title: const Text('Create Table'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Table Number (required, positive int)
                    TextFormField(
                      controller: tableNumberController,
                      focusNode: tableNumberFocus,
                      decoration: const InputDecoration(labelText: 'Table Number'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => updateFormValidity(setState),
                      validator: (value) {
                        if (!tableNumberTouched) return null;
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Table number is required.';
                        final n = int.tryParse(v);
                        if (n == null || n <= 0) return 'Table number must be a positive number.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Capacity (required, >= 1)
                    TextFormField(
                      controller: capacityController,
                      focusNode: capacityFocus,
                      decoration: const InputDecoration(labelText: 'Capacity'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => updateFormValidity(setState),
                      validator: (value) {
                        if (!capacityTouched) return null;
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Capacity is required.';
                        final n = int.tryParse(v);
                        if (n == null || n <= 0) return 'Capacity must be at least 1.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Location (required, max 20)
                    TextFormField(
                      controller: locationController,
                      focusNode: locationFocus,
                      decoration: const InputDecoration(labelText: 'Location'),
                      maxLength: 20,
                      onChanged: (_) => updateFormValidity(setState),
                      validator: (value) {
                        if (!locationTouched) return null;
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Location is required.';
                        if (v.length > 20) return 'Location cannot exceed 20 characters.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Notes (optional, max 100)
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 2,
                      maxLength: 100,
                      onChanged: (_) => updateFormValidity(setState),
                    ),
                    const SizedBox(height: 12),

                    CheckboxListTile(
                      title: const Text('Is Available'),
                      value: isAvailable,
                      onChanged: (val) => setState(() => isAvailable = val ?? true),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            // Match menu dialog's Create button style (TextButton)
            TextButton(
              onPressed: isFormValid
                  ? () async {
                      if (!_formKey.currentState!.validate()) return;

                      final model = TableModel(
                        id: 0,
                        tableNumber: int.parse(tableNumberController.text.trim()),
                        capacity: int.parse(capacityController.text.trim()),
                        location: locationController.text.trim(),
                        isAvailable: isAvailable,
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                        restaurantId: 1, // adjust if this comes from context
                      );

                      await context.read<TableProvider>().createItem(model);
                      if (context.mounted) Navigator.pop(context);
                    }
                  : null,
              child: const Text('Create'),
            ),
          ],
        );
      },
    ),
  );
}

/// UPDATE TABLE
void showUpdateTableDialog(BuildContext context, TableModel table) {
  final _formKey = GlobalKey<FormState>();

  final tableNumberController = TextEditingController(text: table.tableNumber.toString());
  final capacityController    = TextEditingController(text: table.capacity.toString());
  final locationController    = TextEditingController(text: table.location ?? '');
  final notesController       = TextEditingController(text: table.notes ?? '');

  bool isAvailable = table.isAvailable;
  bool isFormValid = true; // prefilled

  void updateFormValidity(StateSetter setState) {
    final tn = int.tryParse(tableNumberController.text.trim());
    final cp = int.tryParse(capacityController.text.trim());
    final loc = locationController.text.trim();

    final tnValid  = tn != null && tn > 0;
    final cpValid  = cp != null && cp > 0;
    final locValid = loc.isNotEmpty && loc.length <= 20;

    setState(() => isFormValid = tnValid && cpValid && locValid);
  }

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Update Table'),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction, // like your menu Update
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: tableNumberController,
                    decoration: const InputDecoration(labelText: 'Table Number'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => updateFormValidity(setState),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Table number is required.';
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) return 'Table number must be a positive number.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: capacityController,
                    decoration: const InputDecoration(labelText: 'Capacity'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => updateFormValidity(setState),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Capacity is required.';
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) return 'Capacity must be at least 1.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                    maxLength: 20,
                    onChanged: (_) => updateFormValidity(setState),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Location is required.';
                      if (v.length > 20) return 'Location cannot exceed 20 characters.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 2,
                    maxLength: 100,
                    onChanged: (_) => updateFormValidity(setState),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Is Available'),
                    value: isAvailable,
                    onChanged: (val) => setState(() => isAvailable = val ?? true),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          // Match menu dialog's Update button style (TextButton)
          TextButton(
            onPressed: isFormValid
                ? () async {
                    if (!_formKey.currentState!.validate()) return;

                    final updated = TableModel(
                      id: table.id,
                      tableNumber: int.parse(tableNumberController.text.trim()),
                      capacity: int.parse(capacityController.text.trim()),
                      location: locationController.text.trim(),
                      isAvailable: isAvailable,
                      notes: notesController.text.trim().isNotEmpty
                          ? notesController.text.trim()
                          : null,
                      restaurantId: table.restaurantId,
                    );

                    await context.read<TableProvider>().updateItem(updated);
                    if (context.mounted) Navigator.pop(context);
                  }
                : null,
            child: const Text('Update'),
          ),
        ],
      ),
    ),
  );
}