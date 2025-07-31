import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../layouts/main_layout.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../theme/theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../widgets/password_strength_meter.dart';
import '../../widgets/pagination_controls.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({Key? key}) : super(key: key);

  static const List<String> availableRoles = [
    'Admin',
    'Manager',
    'Staff',
    'Customer',
  ];

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  bool? _selectedStatus;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<UserProvider>(context, listen: false);
    provider.fetchUsers();

    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) _applyFilters();
    });
    _usernameFocus.addListener(() {
      if (!_usernameFocus.hasFocus) _applyFilters();
    });
  }

  void _applyFilters() {
    Provider.of<UserProvider>(context, listen: false).setFilters(
      name: _nameController.text,
      username: _usernameController.text,
      isActive: _selectedStatus,
    );
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _usernameFocus.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Consumer<UserProvider>(
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _showCreateUserDialog(context),
                    child: const Text('Add User'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _usernameController,
                        focusNode: _usernameFocus,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ToggleButtons(
                      isSelected: [
                        _selectedStatus == null,
                        _selectedStatus == true,
                        _selectedStatus == false,
                      ],
                      onPressed: (index) {
                        setState(() {
                          _selectedStatus = [null, true, false][index];
                        });
                        _applyFilters();
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('All'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Active'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Inactive'),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        _nameController.clear();
                        _usernameController.clear();
                        setState(() {
                          _selectedStatus = null;
                        });
                        Provider.of<UserProvider>(
                          context,
                          listen: false,
                        ).setFilters();
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: ListView.builder(
                    key: ValueKey(provider.users.length),
                    itemCount: provider.users.length,
                    itemBuilder: (context, index) {
                      final user = provider.users[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.deepPurpleAccent,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${user.firstName} ${user.lastName}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          user.email,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color.fromARGB(255, 0, 0, 0),
                                          ),
                                        ),
                                        if (user.roles.isNotEmpty)
                                          AppTheme.roleChip(user.roles.first),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      user.phoneNumber ?? '-',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(_formatDateTime(user.createdAt)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: AppTheme.statusChip(
                                isActive: user.isActive,
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Center(
                                child: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () =>
                                          _showUpdateUserDialog(context, user),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 18),
                                      color: Colors.red,
                                      onPressed: () =>
                                          _confirmDelete(context, user.id),
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
              PaginationControls(
                currentPage: provider.currentPage,
                totalPages: provider.totalPages,
                pageSize: provider.pageSize,
                onPageChange: (page) {
                  provider.setPage(page);
                },
                onPageSizeChange: (newSize) {
                  provider.setPageSize(newSize);
                },
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showCreateUserDialog(BuildContext context) {
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
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                        ),
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
                        PasswordStrengthMeter(
                          password: passwordController.text,
                        ),
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

  void _showUpdateUserDialog(BuildContext context, UserModel user) {
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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update User'),
              content: SingleChildScrollView(
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
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
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
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Role'),
                    ),
                    const SizedBox(height: 12),

                    CheckboxListTile(
                      title: const Text('Is Active'),
                      value: isActive,
                      onChanged: (value) {
                        setState(() {
                          isActive = value ?? true;
                        });
                      },
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
                      firstName: firstNameController.text,
                      lastName: lastNameController.text,
                      email: emailController.text,
                      phoneNumber: phoneNumberController.text,
                      isActive: isActive,
                      password: passwordController.text.isEmpty
                          ? null
                          : passwordController.text,
                      roles: [if (selectedRole != null) selectedRole!],
                    );

                    await context.read<UserProvider>().updateUser(updatedUser);
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

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await context.read<UserProvider>().deleteUser(id);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
