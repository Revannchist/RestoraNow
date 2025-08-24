import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'avatar_view.dart';
import '../../providers/user_provider.dart';
import '../../models/user_models.dart';

void showEditProfileDialog(BuildContext context, MeModel me) {
  final firstNameController = TextEditingController(text: me.firstName);
  final lastNameController  = TextEditingController(text: me.lastName);

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        final prov        = context.watch<UserProvider>();
        final avatarUrl   = prov.avatarUrl ?? me.imageUrl;
        final avatarBytes = prov.avatarBytes;

        final fullName = '${me.firstName} ${me.lastName}'.trim();
        final initials = (fullName.isNotEmpty ? fullName[0] : '?').toUpperCase();

        Future<void> _pickAndUpload() async {
          final picked = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            maxWidth: 1024,
            imageQuality: 85,
          );
          if (picked == null) return;

          final bytes  = await picked.readAsBytes();
          final mime   = picked.mimeType ?? _guessMimeFromPath(picked.path);
          final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';

          final ok = await prov.upsertMyImageUrl(dataUri);
          if (!context.mounted) return;
          setState(() {}); // refresh preview
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ok ? 'Photo uploaded' : (prov.error ?? 'Upload failed'))),
          );
        }

        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar + actions (only device upload + remove)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AvatarView(
                      initials: initials,
                      imageUrl: avatarUrl,
                      imageBytes: avatarBytes,
                      size: 64,
                      isBusy: prov.imageBusy,
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
                          onPressed: (prov.imageBusy ||
                                  ((avatarBytes == null || avatarBytes.isEmpty) &&
                                   (avatarUrl == null || avatarUrl.isEmpty)))
                              ? null
                              : () async {
                                  final ok = await prov.deleteMyImage();
                                  if (!context.mounted) return;
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok ? 'Photo removed' : (prov.error ?? 'Failed to remove')),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove'),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Name fields
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lastNameController,
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
                        "firstName": firstNameController.text.trim(),
                        "lastName" : lastNameController.text.trim(),
                      });
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ok ? 'Profile updated' : (prov.error ?? 'Update failed'))),
                      );
                    },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}

Future<bool?> showChangePasswordDialog(BuildContext context) {
  final currentPwd = TextEditingController();
  final newPwd     = TextEditingController();

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
          const SizedBox(height: 12), // spacing requested
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
            final ok   = await prov.changePassword(currentPwd.text, newPwd.text);
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
  final newEmail   = TextEditingController();

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
          const SizedBox(height: 12), // spacing requested
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
            final ok   = await prov.changeEmail(currentPwd.text, newEmail.text);
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
