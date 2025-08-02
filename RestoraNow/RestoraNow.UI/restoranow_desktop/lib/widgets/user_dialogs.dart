import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user_model.dart';
import '../models/user_image_model.dart';
import '../providers/user_provider.dart';
import '../providers/user_image_provider.dart';
import '../screens/user_screen/user_list_screen.dart';
import '../widgets/password_strength_meter.dart';

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
  final phoneFocus = FocusNode();
  final passwordFocus = FocusNode();

  final fieldErrors = <String, String?>{};
  bool isActive = true;
  bool obscurePassword = true;
  bool isFormValid = false;

  void updateFormValidity(StateSetter setState) {
    final isValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      isFormValid = isValid;
    });
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          firstNameFocus.addListener(() {
            if (!firstNameFocus.hasFocus) {
              _formKey.currentState?.validate();
              updateFormValidity(setState);
            }
          });
          lastNameFocus.addListener(() {
            if (!lastNameFocus.hasFocus) {
              _formKey.currentState?.validate();
              updateFormValidity(setState);
            }
          });
          emailFocus.addListener(() {
            if (!emailFocus.hasFocus) {
              _formKey.currentState?.validate();
              updateFormValidity(setState);
            }
          });
          phoneFocus.addListener(() {
            if (!phoneFocus.hasFocus) {
              _formKey.currentState?.validate();
              updateFormValidity(setState);
            }
          });
          passwordFocus.addListener(() {
            if (!passwordFocus.hasFocus) {
              _formKey.currentState?.validate();
              updateFormValidity(setState);
            }
          });

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
                      TextFormField(
                        controller: firstNameController,
                        focusNode: firstNameFocus,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          isDense: true,
                        ),
                        onChanged: (_) => updateFormValidity(setState),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'First name is required.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: lastNameController,
                        focusNode: lastNameFocus,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          isDense: true,
                        ),
                        onChanged: (_) => updateFormValidity(setState),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Last name is required.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        focusNode: emailFocus,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          isDense: true,
                          errorText: fieldErrors['email'],
                        ),
                        onChanged: (_) => updateFormValidity(setState),
                        validator: (value) {
                          if (fieldErrors['email'] != null) {
                            return fieldErrors['email'];
                          }
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required.';
                          }
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        focusNode: passwordFocus,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          isDense: true,
                          errorMaxLines: 2,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => obscurePassword = !obscurePassword,
                            ),
                          ),
                        ),
                        onChanged: (_) => updateFormValidity(setState),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Password is required.';
                          }
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
                        PasswordStrengthMeter(
                          password: passwordController.text,
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneNumberController,
                        focusNode: phoneFocus,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          isDense: true,
                          errorText: fieldErrors['phone'],
                          errorMaxLines: 2,
                        ),
                        onChanged: (_) => updateFormValidity(setState),
                        validator: (value) {
                          if (fieldErrors['phone'] != null) {
                            return fieldErrors['phone'];
                          }
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required.';
                          }
                          final phoneRegex = RegExp(
                            r'^(?:\+?\d{7,15}|0\d{6,14})$',
                          );
                          if (!phoneRegex.hasMatch(value.trim())) {
                            return 'Enter a valid phone number.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Is Active'),
                        value: isActive,
                        onChanged: (value) {
                          setState(() => isActive = value ?? true);
                          updateFormValidity(setState);
                        },
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isFormValid
                    ? () async {
                        final user = UserModel(
                          id: 0,
                          firstName: firstNameController.text.trim(),
                          lastName: lastNameController.text.trim(),
                          email: emailController.text.trim(),
                          isActive: isActive,
                          createdAt: DateTime.now(),
                          roles: [],
                          imageUrl: null,
                          phoneNumber: phoneNumberController.text.trim(),
                        );

                        setState(() => fieldErrors.clear());

                        try {
                          await context.read<UserProvider>().createUser(
                            user,
                            passwordController.text.trim(),
                          );
                          if (context.mounted) Navigator.pop(context);
                        } on http.Response catch (response) {
                          try {
                            final errorData = jsonDecode(response.body);
                            if (errorData['errors'] is Map) {
                              final errors = Map<String, dynamic>.from(
                                errorData['errors'],
                              );
                              setState(() {
                                errors.forEach((key, value) {
                                  final field = key.toLowerCase();
                                  if (value is List && value.isNotEmpty) {
                                    if (field.contains("email")) {
                                      fieldErrors['email'] = value.first;
                                    } else if (field.contains("phone")) {
                                      fieldErrors['phone'] = value.first;
                                    } else {
                                      fieldErrors['general'] = value.first;
                                    }
                                  }
                                });
                              });
                            }
                          } catch (_) {
                            setState(() {
                              fieldErrors['general'] =
                                  'Unexpected error occurred.';
                            });
                          }
                          _formKey.currentState?.validate();
                        } catch (e) {
                          setState(() {
                            fieldErrors['general'] = e.toString();
                          });
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
    text: user.phoneNumber ?? "",
  );

  bool isActive = user.isActive;
  bool obscurePassword = true;
  String? selectedRole = user.roles.isNotEmpty ? user.roles.first : null;

  final imageProvider = Provider.of<UserImageProvider>(context, listen: false);
  final currentImage = imageProvider.getImageForUser(user.id);
  String? newImageUrl = currentImage?.url;
  bool imageMarkedForDeletion = false;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Update User'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
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
                          onPressed: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      items: UserListScreen.availableRoles
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedRole = value),
                      decoration: const InputDecoration(labelText: 'Role'),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('Is Active'),
                      value: isActive,
                      onChanged: (value) =>
                          setState(() => isActive = value ?? true),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!imageMarkedForDeletion && newImageUrl != null)
                          CircleAvatar(
                            backgroundImage: MemoryImage(
                              _decodeBase64Image(newImageUrl!),
                            ),
                            radius: 24,
                          )
                        else
                          const CircleAvatar(
                            radius: 24,
                            child: Icon(Icons.person),
                          ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton(
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
                              child: const Text('Change Image'),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  newImageUrl = null;
                                  imageMarkedForDeletion = true;
                                });
                              },
                              child: const Text('Remove Image'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final updatedUser = user.copyWith(
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    email: emailController.text.trim(),
                    phoneNumber: phoneNumberController.text.trim(),
                    isActive: isActive,
                    password: passwordController.text.isNotEmpty
                        ? passwordController.text.trim()
                        : null,
                    roles: [if (selectedRole != null) selectedRole!],
                  );

                  await context.read<UserProvider>().updateUser(updatedUser);

                  final existingImage = imageProvider.getImageForUser(user.id);

                  if (imageMarkedForDeletion && existingImage != null) {
                    await imageProvider.deleteUserImage(
                      existingImage.id,
                      user.id,
                    );
                    context.read<UserProvider>().removeUserImage(user.id);
                    onImageUpdated?.call();
                  } else if (!imageMarkedForDeletion && newImageUrl != null) {
                    await imageProvider.uploadOrUpdateImage(
                      UserImageModel(
                        id: existingImage?.id ?? 0,
                        userId: user.id,
                        url: newImageUrl!,
                        description: 'Profile image',
                      ),
                    );
                    context.read<UserProvider>().updateUserImageUrl(
                      user.id,
                      newImageUrl!,
                    );
                    onImageUpdated?.call();
                  }

                  Navigator.pop(context);
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      );
    },
  );
}

Uint8List _decodeBase64Image(String base64String) {
  final regex = RegExp(r'data:image/[^;]+;base64,');
  final cleaned = base64String.replaceAll(regex, '');
  return base64Decode(cleaned);
}

String _getMimeType(String path) {
  if (path.toLowerCase().endsWith('.jpg') ||
      path.toLowerCase().endsWith('.jpeg')) {
    return 'image/jpeg';
  } else if (path.toLowerCase().endsWith('.gif')) {
    return 'image/gif';
  } else if (path.toLowerCase().endsWith('.bmp')) {
    return 'image/bmp';
  }
  return 'image/png';
}
