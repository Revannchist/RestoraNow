import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/user_image_model.dart';
import '../models/user_model.dart';
import '../providers/user_image_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/password_strength_meter.dart';

// overlay toasts + ApiException
import '../widgets/helpers/error_dialog_helper.dart' as msg;
import '../core/api_exception.dart';

/// Keep roles local to avoid referencing the screen class (prevents circular deps)
const kAvailableUserRoles = <String>['Admin', 'Manager', 'Staff', 'Customer'];

/// ----------------------------- CREATE USER -----------------------------
void showCreateUserDialog(BuildContext context) {
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneNumberController = TextEditingController();

  final firstNameFocus = FocusNode();
  final lastNameFocus = FocusNode();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  final phoneFocus = FocusNode();

  // validation state
  final fieldErrors = <String, String?>{};
  final touched = <String, bool>{};

  bool isActive = true;
  bool obscurePassword = true;
  bool isFormValid = false;
  bool isSubmitting = false;

  // root context for overlays (keeps toast above dialogs)
  final rootCtx = context;

  void markTouched(String name, StateSetter setState) {
    touched[name] = true;
    setState(() => isFormValid = _formKey.currentState?.validate() ?? false);
  }

  void forceRevalidate(StateSetter setState) {
    setState(() {
      isFormValid = _formKey.currentState?.validate() ?? false;
    });
  }

  showDialog(
    context: context,
    useRootNavigator: true,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setState) {
        return AlertDialog(
          title: const Text('Create User'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // First Name
                    TextFormField(
                      controller: firstNameController,
                      focusNode: firstNameFocus,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        isDense: true,
                      ),
                      onChanged: (_) => forceRevalidate(setState),
                      onFieldSubmitted: (_) => markTouched('first', setState),
                      onTapOutside: (_) => markTouched('first', setState),
                      validator: (v) {
                        if (!(touched['first'] ?? false)) return null;
                        if ((v ?? '').trim().isEmpty) {
                          return 'First name is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Last Name
                    TextFormField(
                      controller: lastNameController,
                      focusNode: lastNameFocus,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        isDense: true,
                      ),
                      onChanged: (_) => forceRevalidate(setState),
                      onFieldSubmitted: (_) => markTouched('last', setState),
                      onTapOutside: (_) => markTouched('last', setState),
                      validator: (v) {
                        if (!(touched['last'] ?? false)) return null;
                        if ((v ?? '').trim().isEmpty) {
                          return 'Last name is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Email
                    TextFormField(
                      controller: emailController,
                      focusNode: emailFocus,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        isDense: true,
                        errorText: fieldErrors['email'],
                      ),
                      onChanged: (_) => forceRevalidate(setState),
                      onFieldSubmitted: (_) => markTouched('email', setState),
                      onTapOutside: (_) => markTouched('email', setState),
                      validator: (v) {
                        if (fieldErrors['email'] != null) {
                          return fieldErrors['email'];
                        }
                        if (!(touched['email'] ?? false)) return null;
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return 'Email is required.';
                        final emailRe = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRe.hasMatch(value)) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Password
                    TextFormField(
                      controller: passwordController,
                      focusNode: passwordFocus,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        isDense: true,
                        errorMaxLines: 2,
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      onChanged: (_) => forceRevalidate(setState),
                      onFieldSubmitted: (_) =>
                          markTouched('password', setState),
                      onTapOutside: (_) => markTouched('password', setState),
                      validator: (v) {
                        if (!(touched['password'] ?? false)) return null;
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return 'Password is required.';
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }
                        if (!RegExp(r'\d').hasMatch(value)) {
                          return 'Password must contain at least one number.';
                        }
                        return null;
                      },
                    ),
                    if (passwordController.text.isNotEmpty)
                      PasswordStrengthMeter(password: passwordController.text),
                    const SizedBox(height: 12),

                    // Phone (OPTIONAL)
                    TextFormField(
                      controller: phoneNumberController,
                      focusNode: phoneFocus,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Phone Number (optional)',
                        isDense: true,
                        errorText: fieldErrors['phone'],
                        errorMaxLines: 2,
                      ),
                      onChanged: (_) => forceRevalidate(setState),
                      onFieldSubmitted: (_) => markTouched('phone', setState),
                      onTapOutside: (_) => markTouched('phone', setState),
                      validator: (v) {
                        if (fieldErrors['phone'] != null) {
                          return fieldErrors['phone'];
                        }
                        if (!(touched['phone'] ?? false)) return null;
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return null; // <-- optional now
                        final re = RegExp(r'^(?:\+?\d{7,15}|0\d{6,14})$');
                        if (!re.hasMatch(value)) {
                          return 'Enter a valid phone number.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    CheckboxListTile(
                      title: const Text('Is Active'),
                      value: isActive,
                      onChanged: (v) {
                        setState(() => isActive = v ?? true);
                        forceRevalidate(setState);
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    if (fieldErrors['general'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          fieldErrors['general']!,
                          style: const TextStyle(color: Colors.red),
                        ),
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
                      setState(() {
                        isSubmitting = true;
                        fieldErrors.clear();
                      });

                      final phone = phoneNumberController.text.trim();
                      final user = UserModel(
                        id: 0,
                        firstName: firstNameController.text.trim(),
                        lastName: lastNameController.text.trim(),
                        email: emailController.text.trim(),
                        isActive: isActive,
                        createdAt: DateTime.now(),
                        roles: const [],
                        imageUrl: null,
                        phoneNumber: phone.isEmpty
                            ? null
                            : phone, // <-- null if empty
                      );

                      try {
                        await rootCtx.read<UserProvider>().createUser(
                          user,
                          passwordController.text.trim(),
                        );

                        // If provider captured an error (e.g., duplicate email), surface nicely
                        final provErr = rootCtx.read<UserProvider>().error;
                        if (provErr != null && provErr.isNotEmpty) {
                          final pretty = msg.extractServerMessage(provErr);
                          msg.showOverlayMessage(rootCtx, pretty);
                          setState(() => isSubmitting = false);
                          return;
                        }

                        if (!dialogCtx.mounted) return;
                        Navigator.pop(dialogCtx);
                        msg.showOverlayMessage(
                          rootCtx,
                          'User created',
                          type: msg.AppMessageType.success,
                        );
                      } on ApiException catch (e) {
                        msg.showAnyErrorOnTop(rootCtx, e);
                        setState(() => isSubmitting = false);
                      } on http.Response catch (response) {
                        // If your BaseProvider throws raw http.Response
                        final pretty = msg.extractServerMessage(response.body);
                        msg.showOverlayMessage(rootCtx, pretty);
                        setState(() => isSubmitting = false);
                      } catch (_) {
                        msg.showOverlayMessage(
                          rootCtx,
                          'Something went wrong. Please try again.',
                        );
                        setState(() => isSubmitting = false);
                      }
                    }
                  : null,
              child: isSubmitting
                  ? const Text('Creating...')
                  : const Text('Create'),
            ),
          ],
        );
      },
    ),
  );
}

/// ----------------------------- UPDATE USER -----------------------------
void showUpdateUserDialog(
  BuildContext context,
  UserModel user, {
  VoidCallback? onImageUpdated,
}) {
  final firstNameController = TextEditingController(text: user.firstName);
  final lastNameController = TextEditingController(text: user.lastName);
  final emailController = TextEditingController(text: user.email);
  final passwordController = TextEditingController();
  final phoneNumberController = TextEditingController(
    text: user.phoneNumber ?? '',
  );

  bool isActive = user.isActive;
  bool obscurePassword = true;
  String? selectedRole = user.roles.isNotEmpty ? user.roles.first : null;

  final imageProvider = Provider.of<UserImageProvider>(context, listen: false);
  final currentImage = imageProvider.getImageForUser(user.id);
  String? newImageUrl = currentImage?.url;
  bool imageMarkedForDeletion = false;

  bool isSubmitting = false;

  // root context for overlays (keeps toast above dialogs)
  final rootCtx = context;

  showDialog(
    context: context,
    useRootNavigator: true,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setState) {
        return AlertDialog(
          title: const Text('Update User'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'New Password (optional)',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: kAvailableUserRoles
                        .map(
                          (role) => DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => selectedRole = value),
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Is Active'),
                    value: isActive,
                    onChanged: (value) =>
                        setState(() => isActive = value ?? true),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 12),

                  // -------- Avatar preview & actions --------
                  if (!imageMarkedForDeletion && newImageUrl != null)
                    Column(
                      children: [
                        CircleAvatar(
                          backgroundImage: MemoryImage(
                            _decodeBase64Image(newImageUrl!),
                          ),
                          radius: 36,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.image),
                              label: const Text('Change Image'),
                              onPressed: () async {
                                final result = await FilePicker.platform
                                    .pickFiles(type: FileType.image);
                                if (result != null &&
                                    result.files.single.path != null) {
                                  final file = File(result.files.single.path!);
                                  final bytes = await file.readAsBytes();
                                  final base64 = base64Encode(bytes);
                                  final mimeType = _getMimeType(file.path);
                                  final dataUrl =
                                      'data:$mimeType;base64,$base64';
                                  setState(() {
                                    newImageUrl = dataUrl;
                                    imageMarkedForDeletion = false;
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Remove Image'),
                              onPressed: () {
                                setState(() {
                                  newImageUrl = null;
                                  imageMarkedForDeletion = true;
                                });
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        const CircleAvatar(
                          radius: 36,
                          child: Icon(Icons.person),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Add Image'),
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
                              setState(() {
                                newImageUrl = dataUrl;
                                imageMarkedForDeletion = false;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setState(() => isSubmitting = true);

                      final phone = phoneNumberController.text.trim();
                      final updatedUser = user.copyWith(
                        firstName: firstNameController.text.trim(),
                        lastName: lastNameController.text.trim(),
                        email: emailController.text.trim(),
                        phoneNumber: phone.isEmpty
                            ? null
                            : phone, // <-- null if empty
                        isActive: isActive,
                        password: passwordController.text.isNotEmpty
                            ? passwordController.text.trim()
                            : null,
                        roles: [if (selectedRole != null) selectedRole!],
                      );

                      try {
                        await rootCtx.read<UserProvider>().updateUser(
                          updatedUser,
                        );

                        // If provider captured an error (e.g., duplicate email), surface nicely
                        final provErr = rootCtx.read<UserProvider>().error;
                        if (provErr != null && provErr.isNotEmpty) {
                          final pretty = msg.extractServerMessage(provErr);
                          msg.showOverlayMessage(rootCtx, pretty);
                          setState(() => isSubmitting = false);
                          return;
                        }

                        // Handle image updates/deletes after a successful user update
                        final existingImage = imageProvider.getImageForUser(
                          user.id,
                        );

                        if (imageMarkedForDeletion && existingImage != null) {
                          await imageProvider.deleteUserImage(
                            existingImage.id,
                            user.id,
                          );
                          await rootCtx.read<UserProvider>().fetchUsers();
                          rootCtx.read<UserProvider>().removeUserImage(user.id);
                          onImageUpdated?.call();
                        } else if (!imageMarkedForDeletion &&
                            newImageUrl != null) {
                          await imageProvider.uploadOrUpdateImage(
                            UserImageModel(
                              id: existingImage?.id ?? 0,
                              userId: user.id,
                              url: newImageUrl!,
                              description: 'Profile image',
                            ),
                          );
                          rootCtx.read<UserProvider>().updateUserImageUrl(
                            user.id,
                            newImageUrl!,
                          );
                          onImageUpdated?.call();
                        }

                        if (!dialogCtx.mounted) return;
                        Navigator.pop(dialogCtx);
                        msg.showOverlayMessage(
                          rootCtx,
                          'User updated',
                          type: msg.AppMessageType.success,
                        );
                      } on ApiException catch (e) {
                        msg.showAnyErrorOnTop(rootCtx, e);
                        setState(() => isSubmitting = false);
                      } on http.Response catch (response) {
                        final pretty = msg.extractServerMessage(response.body);
                        msg.showOverlayMessage(rootCtx, pretty);
                        setState(() => isSubmitting = false);
                      } catch (_) {
                        msg.showOverlayMessage(
                          rootCtx,
                          'Something went wrong. Please try again.',
                        );
                        setState(() => isSubmitting = false);
                      }
                    },
              child: isSubmitting
                  ? const Text('Updating...')
                  : const Text('Update'),
            ),
          ],
        );
      },
    ),
  );
}

/// ----------------------------- Helpers -----------------------------
Uint8List _decodeBase64Image(String base64String) {
  final regex = RegExp(r'data:image/[^;]+;base64,');
  final cleaned = base64String.replaceAll(regex, '');
  return base64Decode(cleaned);
}

String _getMimeType(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.bmp')) return 'image/bmp';
  return 'image/png';
}
