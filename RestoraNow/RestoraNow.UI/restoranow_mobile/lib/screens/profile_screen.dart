import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_models.dart';

import '../widgets/profile_dialogs.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // fetch on first frame to ensure Provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<UserProvider>();
      await prov.fetchMe();
      _fillFromModel(prov.currentUser);
      setState(() => _initialized = true);
    });
  }

  void _fillFromModel(MeModel? m) {
    if (m == null) return;
    _firstNameCtrl.text = m.firstName;
    _lastNameCtrl.text = m.lastName;
    _phoneCtrl.text = m.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = context.read<UserProvider>();
    final ok = await prov.updateMe({
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'phoneNumber': _phoneCtrl.text.trim().isEmpty
          ? null
          : _phoneCtrl.text.trim(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Profile updated' : (prov.error ?? 'Update failed')),
      ),
    );
  }

  Future<void> _changePassword() async {
    final ok = await showChangePasswordDialog(context);
    if (!mounted || ok == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Password changed' : 'Change failed')),
    );
  }

  Future<void> _changeEmail() async {
    final ok = await showChangeEmailDialog(context);
    if (!mounted || ok == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Email updated' : 'Update failed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UserProvider>();
    final isLoading = prov.isLoading && !_initialized;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : prov.currentUser == null
          ? _ErrorView(
              error: prov.error ?? 'Failed to load profile',
              onRetry: () async {
                await prov.fetchMe();
                _fillFromModel(prov.currentUser);
              },
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Header(me: prov.currentUser!),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _firstNameCtrl,
                    decoration: const InputDecoration(labelText: 'First name'),
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _lastNameCtrl,
                    decoration: const InputDecoration(labelText: 'Last name'),
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: prov.isLoading ? null : _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save changes'),
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: prov.isLoading ? null : _changePassword,
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Change password'),
                  ),
                  const SizedBox(height: 8),

                  OutlinedButton.icon(
                    onPressed: prov.isLoading ? null : _changeEmail,
                    icon: const Icon(Icons.alternate_email),
                    label: const Text('Change email'),
                  ),

                  if (prov.isLoading && _initialized) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(minHeight: 3),
                  ],
                  if (prov.error != null && !_initialized) ...[
                    const SizedBox(height: 12),
                    Text(
                      prov.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.me});
  final MeModel me;

  @override
  Widget build(BuildContext context) {
    final fullName = '${me.firstName} ${me.lastName}'.trim();
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundImage: me.imageUrl != null && me.imageUrl!.isNotEmpty
              ? NetworkImage(me.imageUrl!)
              : null,
          child: (me.imageUrl == null || me.imageUrl!.isEmpty)
              ? Text(fullName.isEmpty ? '?' : fullName[0])
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fullName, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(me.email, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
