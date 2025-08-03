import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/table_model.dart';
import '../providers/table_provider.dart';

void showCreateTableDialog(BuildContext context) {
  final _formKey = GlobalKey<FormState>();
  final tableNumberController = TextEditingController();
  final capacityController = TextEditingController();
  final locationController = TextEditingController();
  final notesController = TextEditingController();

  final tableNumberFocus = FocusNode();
  final capacityFocus = FocusNode();

  bool isAvailable = true;
  bool isTouched = false;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Create Table'),
        content: Form(
          key: _formKey,
          autovalidateMode: isTouched ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: tableNumberController,
                  focusNode: tableNumberFocus,
                  decoration: const InputDecoration(labelText: 'Table Number'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Table number is required.';
                    final number = int.tryParse(value);
                    if (number == null || number <= 0) return 'Table number must be a positive number.';
                    return null;
                  },
                  onChanged: (_) => isTouched = true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: capacityController,
                  focusNode: capacityFocus,
                  decoration: const InputDecoration(labelText: 'Capacity'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Capacity is required.';
                    final number = int.tryParse(value);
                    if (number == null || number <= 0) return 'Capacity must be at least 1.';
                    return null;
                  },
                  onChanged: (_) => isTouched = true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  maxLength: 20,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                  maxLength: 100,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text("Is Available"),
                  value: isAvailable,
                  onChanged: (value) {
                    isAvailable = value;
                    (context as Element).markNeedsBuild();
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          Consumer<TableProvider>(
            builder: (context, provider, child) {
              return ElevatedButton(
                onPressed: () {
                  isTouched = true;
                  if (_formKey.currentState!.validate()) {
                    final table = TableModel(
                      id: 0,
                      tableNumber: int.parse(tableNumberController.text),
                      capacity: int.parse(capacityController.text),
                      location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                      isAvailable: isAvailable,
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      restaurantId: 1,
                    );
                    provider.createItem(table);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Create'),
              );
            },
          ),
        ],
      );
    },
  );
}

void showUpdateTableDialog(BuildContext context, TableModel table) {
  final _formKey = GlobalKey<FormState>();
  final tableNumberController = TextEditingController(text: table.tableNumber.toString());
  final capacityController = TextEditingController(text: table.capacity.toString());
  final locationController = TextEditingController(text: table.location ?? '');
  final notesController = TextEditingController(text: table.notes ?? '');
  bool isAvailable = table.isAvailable;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Update Table'),
        content: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: tableNumberController,
                  decoration: const InputDecoration(labelText: 'Table Number'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Table number is required.';
                    final number = int.tryParse(value);
                    if (number == null || number <= 0) return 'Table number must be a positive number.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: capacityController,
                  decoration: const InputDecoration(labelText: 'Capacity'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Capacity is required.';
                    final number = int.tryParse(value);
                    if (number == null || number <= 0) return 'Capacity must be at least 1.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  maxLength: 20,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                  maxLength: 100,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text("Is Available"),
                  value: isAvailable,
                  onChanged: (value) {
                    isAvailable = value;
                    (context as Element).markNeedsBuild();
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final updatedTable = TableModel(
                  id: table.id,
                  tableNumber: int.parse(tableNumberController.text),
                  capacity: int.parse(capacityController.text),
                  location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                  isAvailable: isAvailable,
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  restaurantId: table.restaurantId,
                );
                Provider.of<TableProvider>(context, listen: false).updateItem(updatedTable);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      );
    },
  );
}
