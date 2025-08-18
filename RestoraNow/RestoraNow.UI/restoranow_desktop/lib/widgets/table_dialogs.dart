// lib/widgets/table_dialogs.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/table_model.dart';
import '../providers/table_provider.dart';
import '../providers/restaurant_provider.dart';
import '../../core/api_exception.dart';

// SnackBar helpers (bottom toast-like messages)
import 'package:restoranow_desktop/widgets/helpers/error_dialog_helper.dart';

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

  // Use the *page* context for SnackBars (not the dialog context)
  final rootCtx = context;

  bool isAvailable   = true;
  bool isSubmitting  = false;
  bool isFormValid   = false;
  bool tnTouched     = false;
  bool capTouched    = false;
  bool locTouched    = false;
  bool listenersBound = false;

  void updateFormValidity(StateSetter setState) {
    final tn  = int.tryParse(tableNumberController.text.trim());
    final cp  = int.tryParse(capacityController.text.trim());
    final loc = locationController.text.trim();

    final tnValid  = tn != null && tn > 0;
    final cpValid  = cp != null && cp > 0;
    final locValid = loc.isNotEmpty && loc.length <= 20;

    setState(() => isFormValid = tnValid && cpValid && locValid);
  }

  showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setState) {
        if (!listenersBound) {
          tableNumberFocus.addListener(() {
            if (!tableNumberFocus.hasFocus) {
              tnTouched = true;
              updateFormValidity(setState);
              _formKey.currentState?.validate();
            }
          });
          capacityFocus.addListener(() {
            if (!capacityFocus.hasFocus) {
              capTouched = true;
              updateFormValidity(setState);
              _formKey.currentState?.validate();
            }
          });
          locationFocus.addListener(() {
            if (!locationFocus.hasFocus) {
              locTouched = true;
              updateFormValidity(setState);
              _formKey.currentState?.validate();
            }
          });
          listenersBound = true;
        }

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
                    TextFormField(
                      controller: tableNumberController,
                      focusNode: tableNumberFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => FocusScope.of(dialogCtx).requestFocus(capacityFocus),
                      decoration: const InputDecoration(labelText: 'Table Number'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => updateFormValidity(setState),
                      validator: (value) {
                        if (!tnTouched) return null;
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
                      focusNode: capacityFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => FocusScope.of(dialogCtx).requestFocus(locationFocus),
                      decoration: const InputDecoration(labelText: 'Capacity'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => updateFormValidity(setState),
                      validator: (value) {
                        if (!capTouched) return null;
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
                      focusNode: locationFocus,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(labelText: 'Location'),
                      maxLength: 20,
                      onChanged: (_) => updateFormValidity(setState),
                      validator: (value) {
                        if (!locTouched) return null;
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
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: (isFormValid && !isSubmitting)
                  ? () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => isSubmitting = true);

                      // Prefer real restaurant id from provider if available
                      final restaurant   = rootCtx.read<RestaurantProvider>().restaurant;
                      final restaurantId = restaurant?.id ?? 1;

                      final model = TableModel(
                        id: 0,
                        tableNumber: int.parse(tableNumberController.text.trim()),
                        capacity: int.parse(capacityController.text.trim()),
                        location: locationController.text.trim(),
                        isAvailable: isAvailable,
                        // If your DB column is nullable, you can send null instead of ""
                        notes: notesController.text.trim().isEmpty ? "" : notesController.text.trim(),
                        restaurantId: restaurantId,
                      );

                      try {
                        await rootCtx.read<TableProvider>().createItem(model);
                        if (!dialogCtx.mounted) return;
                        Navigator.pop(dialogCtx);
                      } on ApiException catch (e) {
                        // Bottom SnackBar like login screen
                        showApiErrorSnack(rootCtx, e);
                        setState(() => isSubmitting = false);
                      } catch (_) {
                        showSnackMessage(rootCtx, 'Something went wrong. Please try again.');
                        setState(() => isSubmitting = false);
                      }
                    }
                  : null,
              child: isSubmitting ? const Text('Creating...') : const Text('Create'),
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

  // Use the *page* context for SnackBars (not the dialog context)
  final rootCtx = context;

  bool isAvailable  = table.isAvailable;
  bool isFormValid  = true;
  bool isSubmitting = false;

  void updateFormValidity(StateSetter setState) {
    final tn  = int.tryParse(tableNumberController.text.trim());
    final cp  = int.tryParse(capacityController.text.trim());
    final loc = locationController.text.trim();

    final tnValid  = tn != null && tn > 0;
    final cpValid  = cp != null && cp > 0;
    final locValid = loc.isNotEmpty && loc.length <= 20;

    setState(() => isFormValid = tnValid && cpValid && locValid);
  }

  showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setState) => AlertDialog(
        title: const Text('Update Table'),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
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
            onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: (isFormValid && !isSubmitting)
                ? () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => isSubmitting = true);

                    final updated = TableModel(
                      id: table.id,
                      tableNumber: int.parse(tableNumberController.text.trim()),
                      capacity: int.parse(capacityController.text.trim()),
                      location: locationController.text.trim(),
                      isAvailable: isAvailable,
                      notes: notesController.text.trim().isEmpty ? "" : notesController.text.trim(),
                      restaurantId: table.restaurantId,
                    );

                    try {
                      await rootCtx.read<TableProvider>().updateItem(updated);
                      if (!dialogCtx.mounted) return;
                      Navigator.pop(dialogCtx);
                    } on ApiException catch (e) {
                      showApiErrorSnack(rootCtx, e);
                      setState(() => isSubmitting = false);
                    } catch (_) {
                      showSnackMessage(rootCtx, 'Something went wrong. Please try again.');
                      setState(() => isSubmitting = false);
                    }
                  }
                : null,
            child: isSubmitting ? const Text('Updating...') : const Text('Update'),
          ),
        ],
      ),
    ),
  );
}
