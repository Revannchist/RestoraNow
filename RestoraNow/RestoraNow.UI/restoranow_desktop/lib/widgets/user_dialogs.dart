import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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

  final emailFocusNode = FocusNode();
  final phoneFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  bool isActive = true;
  bool obscurePassword = true;
  bool isFormValid = false;
  bool phoneTouched = false;
  bool passwordTouched = false;

  final fieldErrors = <String, String?>{};

  void updateFormValidity(StateSetter setState) {
    setState(() {
      isFormValid = _formKey.currentState?.validate() ?? false;
    });
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          phoneFocusNode.addListener(() {
            if (!phoneFocusNode.hasFocus) {
              setState(() => phoneTouched = true);
              _formKey.currentState?.validate();
            }
          });
          passwordFocusNode.addListener(() {
            if (!passwordFocusNode.hasFocus) {
              setState(() => passwordTouched = true);
              _formKey.currentState?.validate();
            }
          });

          return AlertDialog(
            title: const Text('Create User'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'First name is required.'
                          : null,
                      onChanged: (_) => updateFormValidity(setState),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Last name is required.'
                          : null,
                      onChanged: (_) => updateFormValidity(setState),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      focusNode: emailFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        errorText: fieldErrors['email'],
                      ),
                      validator: (value) {
                        if (fieldErrors['email'] != null)
                          return fieldErrors['email'];
                        if (value == null || value.trim().isEmpty)
                          return 'Email is required.';
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(value))
                          return 'Enter a valid email address.';
                        return null;
                      },
                      onChanged: (_) => updateFormValidity(setState),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      focusNode: passwordFocusNode,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
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
                      validator: (value) {
                        if (!passwordTouched) return null;
                        if (value == null || value.trim().isEmpty)
                          return 'Password is required.';
                        if (value.length < 6)
                          return 'Password must be at least 6 characters.';
                        if (!RegExp(r'\d').hasMatch(value))
                          return 'Password must contain at least one number.';
                        return null;
                      },
                      onChanged: (_) => updateFormValidity(setState),
                    ),
                    if (passwordController.text.isNotEmpty)
                      PasswordStrengthMeter(password: passwordController.text),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneNumberController,
                      focusNode: phoneFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        errorText: fieldErrors['phone'],
                      ),
                      validator: (value) {
                        if (!phoneTouched) return null;
                        if (fieldErrors['phone'] != null)
                          return fieldErrors['phone'];
                        if (value == null || value.trim().isEmpty)
                          return 'Phone number is required.';
                        final phoneRegex = RegExp(
                          r'^(?:\+?\d{7,15}|0\d{6,14})$',
                        );
                        if (!phoneRegex.hasMatch(value.trim()))
                          return 'Enter a valid phone number (7–15 digits).';
                        return null;
                      },
                      onChanged: (_) => updateFormValidity(setState),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('Is Active'),
                      value: isActive,
                      onChanged: (value) {
                        setState(() {
                          isActive = value ?? true;
                        });
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
                          imageUrls: [],
                          phoneNumber: phoneNumberController.text.trim(),
                        );

                        setState(() => fieldErrors.clear());

                        try {
                          await context.read<UserProvider>().createUser(
                            user,
                            passwordController.text.trim(),
                          );
                          Navigator.pop(context);
                        } on http.Response catch (response) {
                          try {
                            final errorData = jsonDecode(response.body);
                            if (errorData['errors'] is Map) {
                              final Map<String, dynamic> errors =
                                  errorData['errors'];
                              setState(() {
                                fieldErrors.clear();
                                errors.forEach((key, value) {
                                  if (value is List && value.isNotEmpty) {
                                    final lowerKey = key.toLowerCase();
                                    if (lowerKey.contains("email")) {
                                      fieldErrors['email'] = value.first;
                                    } else if (lowerKey.contains("phone")) {
                                      fieldErrors['phone'] = value.first;
                                    } else {
                                      fieldErrors['general'] = value.first;
                                    }
                                  }
                                });
                              });
                              _formKey.currentState!.validate();
                            }
                          } catch (_) {
                            setState(() {
                              fieldErrors['general'] =
                                  'Unexpected error occurred.';
                            });
                            _formKey.currentState!.validate();
                          }
                        } catch (e) {
                          setState(() {
                            fieldErrors['general'] = e.toString();
                          });
                          _formKey.currentState!.validate();
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
  String? newImageUrl;
  bool imageMarkedForDeletion = false;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Load image after first frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (newImageUrl == null && !imageMarkedForDeletion) {
              final currentImage = imageProvider.getImageForUser(user.id);
              if (currentImage?.url != null) {
                setState(() {
                  newImageUrl = currentImage!.url;
                });
              }
            }
          });

          return AlertDialog(
            title: const Text('Update User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
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
                        onPressed: () =>
                            setState(() => obscurePassword = !obscurePassword),
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
                          (role) =>
                              DropdownMenuItem(value: role, child: Text(role)),
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
                  ),
                  const SizedBox(height: 12),
                  Row(
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
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final result = await FilePicker.platform
                                  .pickFiles(type: FileType.image);
                              if (result != null &&
                                  result.files.single.path != null) {
                                final file = File(result.files.single.path!);
                                final bytes = await file.readAsBytes();
                                String mimeType = 'image/png';

                                if (file.path.toLowerCase().endsWith('.jpg') ||
                                    file.path.toLowerCase().endsWith('.jpeg')) {
                                  mimeType = 'image/jpeg';
                                } else if (file.path.toLowerCase().endsWith(
                                  '.gif',
                                )) {
                                  mimeType = 'image/gif';
                                } else if (file.path.toLowerCase().endsWith(
                                  '.bmp',
                                )) {
                                  mimeType = 'image/bmp';
                                }

                                final base64Image = base64Encode(bytes);
                                final dataUrl =
                                    'data:$mimeType;base64,$base64Image';

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
                    // Image not included in user update
                  );

                  await context.read<UserProvider>().updateUser(updatedUser);

                  // Handle image updates separately
                  final currentImage = imageProvider.getImageForUser(user.id);

                  if (imageMarkedForDeletion && currentImage != null) {
                    await imageProvider.deleteUserImage(
                      currentImage.id,
                      user.id,
                    );

                    // ✅ Update the user image state in UserProvider
                    context.read<UserProvider>().removeUserImage(user.id);

                    onImageUpdated?.call();
                  } else if (newImageUrl != null &&
                      newImageUrl != currentImage?.url) {
                    await imageProvider.uploadOrUpdateImage(
                      UserImageModel(
                        id: currentImage?.id ?? 0,
                        url: newImageUrl!,
                        userId: user.id,
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
