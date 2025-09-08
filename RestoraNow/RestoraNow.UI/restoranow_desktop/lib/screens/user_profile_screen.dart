import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../layouts/main_layout.dart';
import '../../models/user_image_model.dart';
import '../../models/user_model.dart';
import '../../providers/base/auth_provider.dart';
import '../../providers/user_image_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/theme.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _scroll = ScrollController();

  UserModel? _me;
  bool _busy = false;
  bool _inited = false;

  // Image state
  String? _pendingImageDataUrl;
  bool _imageMarkedForDeletion = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMe());
  }

  Future<void> _loadMe() async {
    setState(() => _busy = true);

    final auth = context.read<AuthProvider>();
    final users = context.read<UserProvider>();
    final images = context.read<UserImageProvider>();

    try {
      UserModel? picked;

      // 1) Best path: resolve by JWT user id
      final uid = auth.userId;
      if (uid != null) {
        picked = await users.fetchUserById(uid);
      }

      // 2) Fallback: try to find by email within first page (if API lacks /me)
      if (picked == null) {
        await users.fetchUsers(); // first page
        final list = users.users;

        if (list.isNotEmpty) {
          final emailLc = (auth.email ?? '').toLowerCase();
          if (emailLc.isNotEmpty) {
            picked = list.firstWhere(
              (u) => u.email.toLowerCase() == emailLc,
              orElse: () => list.first,
            );
          } else {
            picked = list.first;
          }
        }
      }

      _me = picked;

      if (_me != null) {
        await images.fetchUserImage(_me!.id);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final roles = auth.roles.isNotEmpty ? auth.roles : (_me?.roles ?? const []);
    final images = context.watch<UserImageProvider>();
    final currentImg = _me == null ? null : images.getImageForUser(_me!.id);

    // Image source priority
    final dataUrlToShow = _imageMarkedForDeletion
        ? null
        : (_pendingImageDataUrl ?? currentImg?.url ?? _me?.imageUrl);

    return MainLayout(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _busy
            ? const Center(child: CircularProgressIndicator())
            : (_me == null)
            ? const Center(child: Text('No profile data available.'))
            : Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: ListView(
                  controller: _scroll,
                  children: [
                    // ===== Header card =====
                    Card(
                      color: Theme.of(context).cardColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.borderColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar + image actions
                            Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.primaryColor.withOpacity(
                                        0.3,
                                      ),
                                      width: 3,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 44,
                                    backgroundColor: AppTheme.primaryColor
                                        .withOpacity(0.15),
                                    backgroundImage: dataUrlToShow != null
                                        ? MemoryImage(
                                            _decodeBase64Image(dataUrlToShow),
                                          )
                                        : null,
                                    child: dataUrlToShow == null
                                        ? Text(
                                            _initials(
                                              _me!.firstName,
                                              _me!.lastName,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit photo'),
                                  onPressed: _openImageDialog,
                                ),
                              ],
                            ),

                            const SizedBox(width: 16),

                            // Name/email/roles
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${_me!.firstName} ${_me!.lastName}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: AppTheme.primaryColor,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    auth.email ?? _me!.email,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: -6,
                                    children: roles.isEmpty
                                        ? [AppTheme.roleChip('No role')]
                                        : roles
                                              .map((r) => AppTheme.roleChip(r))
                                              .toList(),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Actions
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _openEditDialog,
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit Profile'),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    context.read<AuthProvider>().logout();
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/login',
                                      (_) => false,
                                    );
                                  },
                                  icon: const Icon(Icons.logout),
                                  label: const Text('Logout'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                    side: const BorderSide(
                                      color: AppTheme.primaryColor,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===== Details card =====
                    _InfoCard(me: _me!, username: auth.username ?? _me!.email),
                  ],
                ),
              ),
      ),
    );
  }

  // ===== Actions =====

  Future<void> _openEditDialog() async {
    if (_me == null) return;
    final first = TextEditingController(text: _me!.firstName);
    final last = TextEditingController(text: _me!.lastName);
    final phone = TextEditingController(text: _me!.phoneNumber ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: first,
                decoration: const InputDecoration(
                  labelText: 'First name',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: last,
                decoration: const InputDecoration(
                  labelText: 'Last name',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    final provider = context.read<UserProvider>();
    final updated = _me!.copyWith(
      firstName: first.text.trim(),
      lastName: last.text.trim(),
      phoneNumber: phone.text.trim().isEmpty ? null : phone.text.trim(),
    );

    await provider.updateUser(updated);
    if (mounted) setState(() => _me = updated);
  }

  Future<void> _openImageDialog() async {
    if (_me == null) return;

    final images = context.read<UserImageProvider>();
    final users = context.read<UserProvider>();
    final existing = images.getImageForUser(_me!.id);

    String? localDataUrl = existing?.url ?? _me?.imageUrl; // current preview
    bool deleteFlag = false;
    bool saving = false;
    bool changed = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) {
          Future<void> pickImage() async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.image,
            );
            if (result != null && result.files.single.path != null) {
              final file = File(result.files.single.path!);
              final bytes = await file.readAsBytes();
              final base64Str = base64Encode(bytes);
              final mimeType = _getMimeType(file.path);
              setLocal(() {
                localDataUrl = 'data:$mimeType;base64,$base64Str';
                deleteFlag = false;
                changed = true;
              });
            }
          }

          return AlertDialog(
            title: const Text('Edit Profile Photo'),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                    backgroundImage: (deleteFlag || localDataUrl == null)
                        ? null
                        : MemoryImage(_decodeBase64Image(localDataUrl!)),
                    child: (deleteFlag || localDataUrl == null)
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: AppTheme.primaryColor,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Choose image'),
                        onPressed: pickImage,
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Remove'),
                        onPressed: (localDataUrl != null || existing != null)
                            ? () => setLocal(() {
                                deleteFlag = true;
                                localDataUrl = null;
                                changed = true;
                              })
                            : null,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: (!changed || saving)
                    ? null
                    : () async {
                        setLocal(() => saving = true);
                        try {
                          if (deleteFlag && existing != null) {
                            await images.deleteUserImage(existing.id, _me!.id);
                            users.removeUserImage(_me!.id);
                          } else if (!deleteFlag && localDataUrl != null) {
                            await images.uploadOrUpdateImage(
                              UserImageModel(
                                id: existing?.id ?? 0,
                                userId: _me!.id,
                                url: localDataUrl!,
                                description: 'Profile image',
                              ),
                            );
                            users.updateUserImageUrl(_me!.id, localDataUrl!);
                          }
                          if (context.mounted) Navigator.pop(context, true);
                        } finally {
                          setLocal(() => saving = false);
                        }
                      },
                child: saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (saved == true) {
      await context.read<UserImageProvider>().fetchUserImage(_me!.id);
      if (mounted) setState(() {});
    }
  }

  // ===== Helpers =====

  String _initials(String? f, String? l) {
    String x(String? s) => (s == null || s.isEmpty) ? '' : s[0];
    final i = (x(f) + x(l)).toUpperCase();
    return i.isEmpty ? '?' : i;
  }

  Uint8List _decodeBase64Image(String base64String) {
    final regex = RegExp(r'data:image/[^;]+;base64,');
    final cleaned = base64String.replaceAll(regex, '');
    return base64Decode(cleaned);
  }

  String _getMimeType(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return 'image/jpeg';
    if (p.endsWith('.gif')) return 'image/gif';
    if (p.endsWith('.bmp')) return 'image/bmp';
    return 'image/png';
  }
}

class _InfoCard extends StatelessWidget {
  final UserModel me;
  final String username;
  const _InfoCard({required this.me, required this.username});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          runSpacing: 12,
          children: [
            _row('Username', username),
            _row('Email', me.email),
            _row('Phone', me.phoneNumber ?? '—'),
            _row('Active', me.isActive ? 'Yes' : 'No'),
            _row('Created', _formatDateTime(me.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} $hh:$mm';
  }
}
