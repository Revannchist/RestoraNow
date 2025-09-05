import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'dart:convert';

import '../../layouts/main_layout.dart';
import '../../providers/user_provider.dart';
import '../../providers/user_image_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/pagination_controls.dart';
import '../../widgets/user_dialogs.dart';

// overlay helper + ApiException
import '../../widgets/helpers/error_dialog_helper.dart' as msg;
import '../../core/api_exception.dart';

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

  String? _lastErrorShown;

  @override
  void initState() {
    super.initState();

    final userProvider = context.read<UserProvider>();
    final imageProvider = context.read<UserImageProvider>();

    userProvider.fetchUsers().then((_) {
      for (var user in userProvider.users) {
        imageProvider.fetchUserImage(user.id);
      }
    });

    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) _applyFilters();
    });
    _usernameFocus.addListener(() {
      if (!_usernameFocus.hasFocus) _applyFilters();
    });
  }

  void _applyFilters() {
    context.read<UserProvider>().setFilters(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Add button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => showCreateUserDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
              ),
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    decoration: const InputDecoration(labelText: 'Name'),
                    onSubmitted: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _usernameController,
                    focusNode: _usernameFocus,
                    decoration: const InputDecoration(labelText: 'Email'),
                    onSubmitted: (_) => _applyFilters(),
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
                    setState(
                      () => _selectedStatus = [null, true, false][index],
                    );
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
                Consumer<UserProvider>(
                  builder: (_, up, __) => TextButton(
                    onPressed: () {
                      _nameController.clear();
                      _usernameController.clear();
                      setState(() => _selectedStatus = null);
                      up.setFilters(); // clears all backend filters
                    },
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // List + loading overlay + error
          Expanded(
            child: Consumer<UserProvider>(
              builder: (context, provider, _) {
                // show overlay error (once) — prettify JSON payloads too
                final err = provider.error;
                if (err != null && err.isNotEmpty && err != _lastErrorShown) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    // turns {"message":...} or {"errors":{...}} into a nice message
                    final pretty = msg.extractServerMessage(err);
                    msg.showOverlayMessage(
                      context,
                      pretty,
                      type: msg.AppMessageType.error,
                    );
                    _lastErrorShown = err; // dedupe
                  });
                }

                final isFirstLoad =
                    provider.isLoading && provider.users.isEmpty;

                return Stack(
                  children: [
                    // Fade list updates
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: isFirstLoad
                          ? const Center(child: CircularProgressIndicator())
                          : (provider.users.isEmpty
                                ? const Center(child: Text('No users found'))
                                : ListView.builder(
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Theme.of(
                                              context,
                                            ).dividerColor,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // Avatar + name/email/role
                                            Expanded(
                                              flex: 2,
                                              child: Row(
                                                children: [
                                                  ClipOval(
                                                    child: user.imageUrl != null
                                                        ? Image.memory(
                                                            _decodeBase64Image(
                                                              user.imageUrl!,
                                                            ),
                                                            width: 40,
                                                            height: 40,
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) => const Icon(
                                                                  Icons
                                                                      .broken_image,
                                                                  size: 40,
                                                                ),
                                                          )
                                                        : const CircleAvatar(
                                                            radius: 20,
                                                            backgroundColor: Colors
                                                                .deepPurpleAccent,
                                                            child: Icon(
                                                              Icons.person,
                                                              color:
                                                                  Colors.white,
                                                              size: 20,
                                                            ),
                                                          ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '${user.firstName} ${user.lastName}',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        Text(
                                                          user.email,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                        ),
                                                        if (user
                                                            .roles
                                                            .isNotEmpty)
                                                          AppTheme.roleChip(
                                                            user.roles.first,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Phone
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
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // CreatedAt
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.calendar_today,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _formatDateTime(
                                                      user.createdAt,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Status
                                            Expanded(
                                              child: AppTheme.statusChip(
                                                isActive: user.isActive,
                                              ),
                                            ),

                                            // Actions
                                            SizedBox(
                                              width: 80,
                                              child: Center(
                                                child: Wrap(
                                                  spacing: 4,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size: 18,
                                                      ),
                                                      onPressed: () =>
                                                          showUpdateUserDialog(
                                                            context,
                                                            user,
                                                            onImageUpdated:
                                                                () => setState(
                                                                  () {},
                                                                ),
                                                          ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        size: 18,
                                                      ),
                                                      color: Colors.red,
                                                      onPressed: () =>
                                                          _confirmDelete(
                                                            context,
                                                            user.id,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )),
                    ),

                    // Slim loading bar overlay when updating filters/pages
                    if (provider.isLoading && provider.users.isNotEmpty)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                  ],
                );
              },
            ),
          ),

          // Pagination
          Consumer<UserProvider>(
            builder: (context, provider, _) => PaginationControls(
              currentPage: provider.currentPage,
              totalPages: provider.totalPages,
              pageSize: provider.pageSize,
              onPageChange: (page) => provider.setPage(page),
              onPageSizeChange: (newSize) => provider.setPageSize(newSize),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Uint8List _decodeBase64Image(String base64String) {
    final regex = RegExp(r'data:image/[^;]+;base64,');
    final cleaned = base64String.replaceAll(regex, '');
    return base64Decode(cleaned);
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<UserProvider>().deleteUser(id);
                if (!mounted) return;
                Navigator.pop(context);
                msg.showOverlayMessage(
                  context,
                  'User deleted',
                  type: msg.AppMessageType.success,
                );
              } on ApiException catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                msg.showAnyErrorOnTop(context, e);
              } catch (_) {
                if (!mounted) return;
                Navigator.pop(context);
                msg.showOverlayMessage(
                  context,
                  'Something went wrong. Please try again.',
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
