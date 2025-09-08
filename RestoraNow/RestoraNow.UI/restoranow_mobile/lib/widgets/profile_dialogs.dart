import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'avatar_view.dart';
import '../../providers/user_provider.dart';
import '../models/user_model.dart';

void showEditProfileDialog(BuildContext context, MeModel meFallback) {
  final prov = context.read<UserProvider>();
  if (prov.currentUser == null && !prov.isLoading) {
    prov.fetchMe();
  }

  showDialog(
    context: context,
    builder: (_) => _EditProfileDialog(meFallback: meFallback),
  );
}

class _EditProfileDialog extends StatefulWidget {
  final MeModel meFallback;
  const _EditProfileDialog({required this.meFallback});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _picking = false; // guard for image_picker re-entry

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UserProvider>();
    final me = prov.currentUser ?? widget.meFallback;

    if (_firstNameController.text.isEmpty && _lastNameController.text.isEmpty) {
      _firstNameController.text = me.firstName;
      _lastNameController.text = me.lastName;
    }

    final avatarUrl = prov.avatarUrl; // provider-driven (with cache-bust)
    final avatarBytes = prov.avatarBytes; // preview or data URI bytes
    final version = prov.avatarVersion;

    final fullName = '${me.firstName} ${me.lastName}'.trim();
    final initials = (fullName.isNotEmpty ? fullName[0] : '?').toUpperCase();

    Future<void> _pickAndUpload() async {
      if (_picking || prov.imageBusy) return;
      _picking = true;
      try {
        final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          imageQuality: 85,
        );
        if (picked == null) return;

        final bytes = await picked.readAsBytes();
        final mime = picked.mimeType ?? _guessMimeFromPath(picked.path);
        final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';

        // Optimistic preview (shown via provider.avatarBytes immediately)
        final ok = await prov.upsertMyImageUrl(dataUri, previewBytes: bytes);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'Photo uploaded' : (prov.error ?? 'Upload failed'),
            ),
          ),
        );

        // Warm the new URL (if any) to avoid flicker on swap
        final newUrl = prov.avatarUrl;
        if (ok && newUrl != null && !newUrl.startsWith('data:image/')) {
          precacheImage(NetworkImage(newUrl), context);
        }
      } finally {
        _picking = false;
      }
    }

    Future<void> _deleteAvatar() async {
      if (prov.imageBusy) return;
      final ok = await prov.deleteMyImage();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Photo removed' : (prov.error ?? 'Failed to remove'),
          ),
        ),
      );
    }

    // Force rebuilds of the avatar subtree when identity changes (URL/bytes/version/busy)
    final identityKey = ValueKey(
      'dlg:${avatarUrl ?? 'mem'}:${avatarBytes?.length ?? 0}:$version:${prov.imageBusy}',
    );

    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar + actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                KeyedSubtree(
                  key: identityKey,
                  child: AvatarView(
                    initials: initials,
                    imageUrl: avatarUrl,
                    imageBytes: avatarBytes,
                    size: 64,
                    isBusy: prov.imageBusy,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton.icon(
                      onPressed: prov.imageBusy ? null : _pickAndUpload,
                      icon: const Icon(Icons.photo_library),
                      label: prov.imageBusy
                          ? const Text('Uploading...')
                          : const Text('Pick from device'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed:
                          (prov.imageBusy ||
                              (avatarBytes == null &&
                                  (avatarUrl == null || avatarUrl.isEmpty)))
                          ? null
                          : _deleteAvatar,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
              textInputAction: TextInputAction.done,
            ),

            if (prov.error != null) ...[
              const SizedBox(height: 8),
              Text(prov.error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: prov.isLoading
              ? null
              : () async {
                  final ok = await prov.updateMe({
                    "firstName": _firstNameController.text.trim(),
                    "lastName": _lastNameController.text.trim(),
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Profile updated'
                            : (prov.error ?? 'Update failed'),
                      ),
                    ),
                  );
                },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

Future<bool?> showChangePasswordDialog(BuildContext context) {
  final currentPwd = TextEditingController();
  final newPwd = TextEditingController();

  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Change Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: currentPwd,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current Password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newPwd,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final prov = context.read<UserProvider>();
            final ok = await prov.changePassword(currentPwd.text, newPwd.text);
            if (!context.mounted) return;
            Navigator.pop(context, ok);
          },
          child: const Text('Update'),
        ),
      ],
    ),
  );
}

Future<bool?> showChangeEmailDialog(BuildContext context) {
  final currentPwd = TextEditingController();
  final newEmail = TextEditingController();

  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Change Email'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: currentPwd,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current Password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newEmail,
            decoration: const InputDecoration(labelText: 'New Email'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final prov = context.read<UserProvider>();
            final ok = await prov.changeEmail(currentPwd.text, newEmail.text);
            if (!context.mounted) return;
            Navigator.pop(context, ok);
          },
          child: const Text('Update'),
        ),
      ],
    ),
  );
}

// tiny helper (kept local)
String _guessMimeFromPath(String path) {
  final p = path.toLowerCase();
  if (p.endsWith('.png')) return 'image/png';
  if (p.endsWith('.webp')) return 'image/webp';
  if (p.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}
