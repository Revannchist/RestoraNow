import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../widgets/avatar_view.dart';
import '../widgets/profile_dialogs.dart';
import '../providers/user_provider.dart';
import '../providers/address_provider.dart';
import '../models/user_model.dart';
import '../screens/addresses_screen.dart';

// local helpers
String _guessMimeFromPath(String path) {
  final p = path.toLowerCase();
  if (p.endsWith('.png')) return 'image/png';
  if (p.endsWith('.webp')) return 'image/webp';
  if (p.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}

Future<String> _dataUriFromXFile(XFile x) async {
  final bytes = await x.readAsBytes();
  final mime = x.mimeType ?? _guessMimeFromPath(x.path);
  return 'data:$mime;base64,${base64Encode(bytes)}';
}

void _snack(BuildContext ctx, String msg) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
}

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProv = context.read<UserProvider>();
      final addrProv = context.read<AddressProvider>();

      await userProv.fetchMe();
      final me = userProv.currentUser;
      if (me != null) {
        await addrProv.fetchByUser(me.id);
      }

      if (!mounted) return;
      _fillFromModel(userProv.currentUser);
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
    _snack(context, ok ? 'Profile updated' : (prov.error ?? 'Update failed'));
  }

  Future<void> _reloadAddresses() async {
    final me = context.read<UserProvider>().currentUser;
    if (me != null) {
      await context.read<AddressProvider>().fetchByUser(me.id);
    }
  }

  Future<void> _changePassword() async {
    final ok = await showChangePasswordDialog(context);
    if (!mounted || ok == null) return;
    _snack(context, ok ? 'Password changed' : 'Change failed');
  }

  Future<void> _changeEmail() async {
    final ok = await showChangeEmailDialog(context);
    if (!mounted || ok == null) return;
    _snack(context, ok ? 'Email updated' : 'Update failed');
  }

  /// Bottom sheet for avatar actions (device upload only + remove)
  Future<void> _onAvatarTap(UserProvider prov) async {
    if (prov.currentUser == null) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final me = prov.currentUser!;
        final fullName = '${me.firstName.trim()} ${me.lastName.trim()}'.trim();
        final initials = (fullName.isNotEmpty ? fullName[0] : '?')
            .toUpperCase();

        final String? url = prov.avatarUrl;
        final Uint8List? bs = prov.avatarBytes;

        Widget preview;
        if (bs != null && bs.isNotEmpty) {
          preview = Image.memory(bs, fit: BoxFit.cover);
        } else if (url != null &&
            url.isNotEmpty &&
            !url.startsWith('data:image/')) {
          preview = Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _InitialAvatar(initials: initials),
          );
        } else {
          preview = _InitialAvatar(initials: initials);
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    children: [
                      ClipOval(child: preview),
                      if (prov.imageBusy)
                        const Positioned.fill(
                          child: ColoredBox(color: Color(0x66000000)),
                        ),
                      if (prov.imageBusy)
                        const Positioned.fill(
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(fullName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Pick from device'),
                  enabled: !prov.imageBusy,
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 512,
                      imageQuality: 70,
                    );
                    if (picked == null) return;

                    final bytes = await picked.readAsBytes();
                    final dataUri = await _dataUriFromXFile(picked);

                    Navigator.of(context).pop();

                    final ok = await prov.upsertMyImageUrl(
                      dataUri,
                      previewBytes: bytes, // instant preview
                    );

                    if (!mounted) return;
                    _snack(
                      context,
                      ok ? 'Photo uploaded' : (prov.error ?? 'Upload failed'),
                    );

                    final newUrl = prov.avatarUrl;
                    if (ok &&
                        newUrl != null &&
                        !newUrl.startsWith('data:image/')) {
                      // warm the cache for the new URL to avoid flicker
                      precacheImage(NetworkImage(newUrl), context);
                    }
                    if (mounted)
                      setState(() {}); // 🔧 force a rebuild of the screen
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove photo'),
                  enabled:
                      !prov.imageBusy &&
                      ((bs != null && bs.isNotEmpty) ||
                          (url != null && url.isNotEmpty)),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final ok = await prov.deleteMyImage();
                    if (!mounted) return;
                    _snack(
                      context,
                      ok ? 'Photo removed' : (prov.error ?? 'Failed to remove'),
                    );
                    if (mounted)
                      setState(() {}); // 🔧 force a rebuild of the screen
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDefaultAddressSummary(AddressProvider addrProv) {
    if (addrProv.isLoading) return 'Loading addresses…';
    final a = addrProv.defaultAddress;
    if (a == null) return 'Add a delivery address';
    final parts = <String>[
      a.street,
      if ((a.city ?? '').isNotEmpty) a.city!,
      if ((a.zipCode ?? '').isNotEmpty) a.zipCode!,
      if ((a.country ?? '').isNotEmpty) a.country!,
    ];
    return parts.where((e) => e.trim().isNotEmpty).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();
    final addrProv = context.watch<AddressProvider>();
    final isLoading = userProv.isLoading && !_initialized;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userProv.currentUser == null
          ? _ErrorView(
              error: userProv.error ?? 'Failed to load profile',
              onRetry: () async {
                await userProv.fetchMe();
                _fillFromModel(userProv.currentUser);
                await _reloadAddresses();
              },
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Header(
                    me: userProv.currentUser!,
                    isBusy: userProv.imageBusy,
                    onTap: () => _onAvatarTap(userProv),
                  ),
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

                  const SizedBox(height: 8),

                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('Delivery addresses'),
                    subtitle: Text(
                      _formatDefaultAddressSummary(addrProv),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddressesScreen(),
                        ),
                      );
                      if (mounted) await _reloadAddresses();
                    },
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: userProv.isLoading ? null : _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save changes'),
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: userProv.isLoading ? null : _changePassword,
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Change password'),
                  ),
                  const SizedBox(height: 8),

                  OutlinedButton.icon(
                    onPressed: userProv.isLoading ? null : _changeEmail,
                    icon: const Icon(Icons.alternate_email),
                    label: const Text('Change email'),
                  ),

                  if (userProv.isLoading && _initialized) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(minHeight: 3),
                  ],
                  if (userProv.error != null && !_initialized) ...[
                    const SizedBox(height: 12),
                    Text(
                      userProv.error!,
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
  const _Header({required this.me, required this.onTap, required this.isBusy});
  final MeModel me;
  final VoidCallback onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final fullName = '${me.firstName.trim()} ${me.lastName.trim()}'.trim();
    final initials = (fullName.isNotEmpty ? fullName[0] : '?').toUpperCase();

    final avatarUrl = context.select<UserProvider, String?>((p) => p.avatarUrl);
    final avatarBytes = context.select<UserProvider, Uint8List?>(
      (p) => p.avatarBytes,
    );
    final version = context.select<UserProvider, int>((p) => p.avatarVersion);

    // Force rebuilds of the avatar subtree when identity changes (URL/bytes/version).
    final identityKey = ValueKey(
      '${avatarUrl ?? 'mem'}:${avatarBytes?.length ?? 0}:$version:$isBusy',
    );

    return Row(
      children: [
        KeyedSubtree(
          key: identityKey,
          child: AvatarView(
            initials: initials,
            imageUrl: avatarUrl,
            imageBytes: avatarBytes,
            isBusy: isBusy,
            onTap: onTap,
          ),
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

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          initials,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
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
