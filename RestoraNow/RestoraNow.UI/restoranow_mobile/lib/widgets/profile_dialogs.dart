import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_models.dart';

void showEditProfileDialog(BuildContext context, MeModel me) {
  final firstNameController = TextEditingController(text: me.firstName);
  final lastNameController = TextEditingController(text: me.lastName);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Edit Profile'),
      content: SingleChildScrollView(
        // avoids overflow on small screens
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final prov = context.read<UserProvider>();
            final ok = await prov.updateMe({
              "firstName": firstNameController.text.trim(),
              "lastName": lastNameController.text.trim(),
            });
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ok ? 'Profile updated' : (prov.error ?? 'Update failed'),
                ),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
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
            Navigator.pop(context, ok); // return true/false
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
            Navigator.pop(context, ok); // return true/false
          },
          child: const Text('Update'),
        ),
      ],
    ),
  );
}
