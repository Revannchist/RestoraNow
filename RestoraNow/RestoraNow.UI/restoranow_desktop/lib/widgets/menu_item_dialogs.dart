import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/menu_item_model.dart';
import '../providers/menu_item_provider.dart';
import '../providers/menu_item_image_provider.dart';
import '../providers/menu_category_provider.dart';

void showCreateMenuItemDialog(BuildContext context) {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();

  final nameFocus = FocusNode();
  final priceFocus = FocusNode();

  bool isAvailable = true;
  bool isSpecial = false;
  String? selectedCategory;

  bool nameTouched = false;
  bool priceTouched = false;
  bool categoryTouched = false;
  bool isFormValid = false;

  final categoryProvider = Provider.of<MenuCategoryProvider>(
    context,
    listen: false,
  );

  if (categoryProvider.categories.isEmpty) {
    categoryProvider.fetchCategories();
  }

  void updateFormValidity(StateSetter setState) {
    final nameValid =
        nameController.text.trim().isNotEmpty &&
        nameController.text.trim().length <= 20;
    final priceValid =
        double.tryParse(priceController.text.trim()) != null &&
        double.parse(priceController.text.trim()) > 0;
    final categoryValid = selectedCategory != null;

    setState(() {
      isFormValid = nameValid && priceValid && categoryValid;
    });
  }

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        nameFocus.addListener(() {
          if (!nameFocus.hasFocus) {
            setState(() => nameTouched = true);
            updateFormValidity(setState);
            _formKey.currentState?.validate();
          }
        });
        priceFocus.addListener(() {
          if (!priceFocus.hasFocus) {
            setState(() => priceTouched = true);
            updateFormValidity(setState);
            _formKey.currentState?.validate();
          }
        });

        return AlertDialog(
          title: const Text('Create Menu Item'),
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
                      controller: nameController,
                      focusNode: nameFocus,
                      decoration: const InputDecoration(labelText: 'Name'),
                      maxLength: 20,
                      onChanged: (_) => updateFormValidity(setState),
                      validator: (value) => !nameTouched
                          ? null
                          : (value == null || value.trim().isEmpty
                                ? 'Name is required'
                                : value.trim().length > 20
                                ? 'Name must be 20 characters or fewer'
                                : null),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      focusNode: priceFocus,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      decoration: const InputDecoration(labelText: 'Price'),
                      onChanged: (_) => updateFormValidity(setState),
                      validator: (value) {
                        if (!priceTouched) return null;
                        final price = double.tryParse(value ?? '');
                        if (price == null || price <= 0) {
                          return 'Price must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categoryProvider.categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id.toString(),
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                          categoryTouched = true;
                        });
                        updateFormValidity(setState);
                      },
                      onTap: () {
                        setState(() => categoryTouched = true);
                        updateFormValidity(setState);
                        _formKey.currentState?.validate();
                      },
                      validator: (value) => !categoryTouched
                          ? null
                          : (value == null ? 'Please select a category' : null),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('Is Available'),
                      value: isAvailable,
                      onChanged: (val) =>
                          setState(() => isAvailable = val ?? true),
                    ),
                    CheckboxListTile(
                      title: const Text('Special of the Day'),
                      value: isSpecial,
                      onChanged: (val) =>
                          setState(() => isSpecial = val ?? false),
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
            TextButton(
              onPressed: isFormValid
                  ? () async {
                      if (!_formKey.currentState!.validate()) return;

                      final created = MenuItemModel(
                        id: 0,
                        name: nameController.text.trim(),
                        description: descController.text.trim(),
                        price:
                            double.tryParse(priceController.text.trim()) ?? 0,
                        isAvailable: isAvailable,
                        isSpecialOfTheDay: isSpecial,
                        categoryId: int.tryParse(selectedCategory ?? '') ?? 0,
                        categoryName: categoryProvider
                            .getById(int.tryParse(selectedCategory ?? '') ?? 0)
                            ?.name,
                      );

                      await context.read<MenuItemProvider>().createItem(
                        created,
                      );
                      await context.read<MenuItemProvider>().fetchItems();

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

void showUpdateMenuItemDialog(BuildContext context, MenuItemModel item) {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: item.name);
  final descController = TextEditingController(text: item.description ?? '');
  final priceController = TextEditingController(text: item.price.toString());
  final categoryProvider = Provider.of<MenuCategoryProvider>(
    context,
    listen: false,
  );
  final imageProvider = Provider.of<MenuItemImageProvider>(
    context,
    listen: false,
  );

  bool isAvailable = item.isAvailable;
  bool isSpecial = item.isSpecialOfTheDay;
  String? selectedCategory = item.categoryId.toString();
  bool isFormValid = true;

  // Current first image (if any)
  final existingImages = imageProvider.getImagesForMenuItem(item.id);
  final hasExisting = existingImages.isNotEmpty;
  bool removeExistingImage = false;
  String? newImageDataUrl; // picked replacement

  void updateFormValidity(StateSetter setState) {
    final nameValid =
        nameController.text.trim().isNotEmpty &&
        nameController.text.trim().length <= 20;
    final priceValid =
        double.tryParse(priceController.text.trim()) != null &&
        double.parse(priceController.text.trim()) > 0;
    final categoryValid = selectedCategory != null;

    setState(() {
      isFormValid = nameValid && priceValid && categoryValid;
    });
  }

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Update Menu Item'),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    maxLength: 20,
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: (_) => updateFormValidity(setState),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (value.trim().length > 20) {
                        return 'Name must be 20 characters or fewer';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => updateFormValidity(setState),
                    validator: (value) {
                      final price = double.tryParse(value ?? '');
                      if (price == null || price <= 0) {
                        return 'Price must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categoryProvider.categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id.toString(),
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                      updateFormValidity(setState);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Is Available'),
                    value: isAvailable,
                    onChanged: (val) =>
                        setState(() => isAvailable = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Special of the Day'),
                    value: isSpecial,
                    onChanged: (val) =>
                        setState(() => isSpecial = val ?? false),
                  ),
                  const SizedBox(height: 12),

                  /// IMAGE HANDLING (single image per item)
                  if (hasExisting && !removeExistingImage)
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Builder(
                            builder: (_) {
                              final bytes = imageProvider.getFirstImageBytes(
                                item.id,
                              );
                              if (bytes == null) return const SizedBox.shrink();
                              return Image.memory(
                                bytes,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              removeExistingImage = true;
                              newImageDataUrl = null;
                            });
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Remove Image'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  if (removeExistingImage || !hasExisting)
                    Column(
                      children: [
                        if (newImageDataUrl != null)
                          Image.memory(
                            _decodeBase64Image(newImageDataUrl!),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                            );
                            if (result != null &&
                                result.files.single.path != null) {
                              final file = File(result.files.single.path!);
                              final bytes = await file.readAsBytes();
                              final base64 = base64Encode(bytes);
                              final mimeType = _getMimeType(file.path);
                              final dataUrl = 'data:$mimeType;base64,$base64';
                              setState(() => newImageDataUrl = dataUrl);
                            }
                          },
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Add Image'),
                        ),
                      ],
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
          TextButton(
            onPressed: isFormValid
                ? () async {
                    if (!_formKey.currentState!.validate()) return;

                    final updated = MenuItemModel(
                      id: item.id,
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      price: double.tryParse(priceController.text.trim()) ?? 0,
                      isAvailable: isAvailable,
                      isSpecialOfTheDay: isSpecial,
                      categoryId: int.tryParse(selectedCategory ?? '') ?? 0,
                      categoryName:
                          categoryProvider
                              .getById(
                                int.tryParse(selectedCategory ?? '') ?? 0,
                              )
                              ?.name ??
                          item.categoryName,
                    );

                    await context.read<MenuItemProvider>().updateItem(updated);

                    // Image changes
                    if (removeExistingImage) {
                      await imageProvider.deleteAllForMenuItem(item.id);
                    }
                    if (newImageDataUrl != null) {
                      await imageProvider.replaceWithDataUrl(
                        menuItemId: item.id,
                        dataUrl: newImageDataUrl!,
                        description: 'Updated image',
                      );
                    }

                    // Refresh list after image ops (to update projections if any)
                    await context.read<MenuItemProvider>().fetchItems();

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

Uint8List _decodeBase64Image(String base64DataUrl) {
  final cleaned = base64DataUrl
      .replaceAll(RegExp(r'^data:image/[^;]+;base64,'), '')
      .replaceAll(RegExp(r'\s'), '');
  return base64Decode(cleaned);
}

String _getMimeType(String filePath) {
  final ext = filePath.toLowerCase();
  if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) return 'image/jpeg';
  if (ext.endsWith('.png')) return 'image/png';
  if (ext.endsWith('.gif')) return 'image/gif';
  if (ext.endsWith('.bmp')) return 'image/bmp';
  return 'image/*';
}
