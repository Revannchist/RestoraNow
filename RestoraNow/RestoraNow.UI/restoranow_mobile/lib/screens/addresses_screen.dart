import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/address_dialogs.dart';
import '../../models/address_model.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final me = context.read<UserProvider>().currentUser;
      if (me != null) {
        await context.read<AddressProvider>().fetchByUser(me.id);
      }
    });
  }

  Future<void> _refresh() async {
    final me = context.read<UserProvider>().currentUser;
    if (me != null) await context.read<AddressProvider>().fetchByUser(me.id);
  }

  int? _defaultIdOf(List<AddressModel> items) {
    for (final a in items) {
      if (a.isDefault) return a.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AddressProvider>();
    final defaultId = _defaultIdOf(prov.items);

    return Scaffold(
      appBar: AppBar(title: const Text('My Addresses')),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : prov.error != null
          ? Center(child: Text(prov.error!))
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: prov.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final a = prov.items[i];
                  final subtitle = [
                    if ((a.city ?? '').isNotEmpty) a.city,
                    if ((a.zipCode ?? '').isNotEmpty) a.zipCode,
                    if ((a.country ?? '').isNotEmpty) a.country,
                  ].whereType<String>().join(', ');

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        a.isDefault
                            ? Icons.location_on
                            : Icons.location_on_outlined,
                        color: a.isDefault
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(a.street),
                      subtitle: subtitle.isEmpty ? null : Text(subtitle),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<int>(
                            value: a.id,
                            groupValue: defaultId,
                            onChanged: prov.isSubmitting
                                ? null
                                : (_) async {
                                    final ok = await context
                                        .read<AddressProvider>()
                                        .setDefault(a);
                                    if (!ok && mounted) {
                                      final err =
                                          context
                                              .read<AddressProvider>()
                                              .submitError ??
                                          'Failed to set default';
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(err)),
                                      );
                                    }
                                  },
                          ),
                          PopupMenuButton<String>(
                            onSelected: (key) async {
                              if (key == 'edit') {
                                await showUpdateAddressDialog(context, a);
                              } else if (key == 'delete') {
                                final ok = await context
                                    .read<AddressProvider>()
                                    .remove(a.id, a.userId);
                                if (!ok && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Delete failed'),
                                    ),
                                  );
                                }
                              }
                            },
                            itemBuilder: (ctx) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => showUpdateAddressDialog(context, a),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: prov.isSubmitting
            ? null
            : () => showCreateAddressDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}
