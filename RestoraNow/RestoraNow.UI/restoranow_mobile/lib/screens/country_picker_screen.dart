import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';

import '../providers/address_provider.dart';
import '../providers/user_provider.dart';
import '../models/address_model.dart';

String? _opt(String s) => s.trim().isEmpty ? null : s.trim();

Future<void> showCreateAddressDialog(BuildContext context) async {
  final me = context.read<UserProvider>().currentUser;
  if (me == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('You must be logged in.')));
    return;
  }

  final formKey = GlobalKey<FormState>();
  final streetCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final zipCtrl = TextEditingController();
  final countryCtrl = TextEditingController();

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Add address'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: streetCtrl,
                decoration: const InputDecoration(labelText: 'Street *'),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: cityCtrl,
                decoration: const InputDecoration(labelText: 'City'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: zipCtrl,
                decoration: const InputDecoration(labelText: 'ZIP'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: countryCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                onTap: () {
                  showCountryPicker(
                    context: context,
                    favorite: const ['BA', 'HR', 'RS', 'DE', 'AT', 'CH'],
                    showPhoneCode: false,
                    countryListTheme: const CountryListThemeData(
                      bottomSheetHeight: 500,
                      inputDecoration: InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    onSelect: (c) => countryCtrl.text = c.name,
                  );
                },
              ),
              const SizedBox(height: 8),
              // NOTE: no "is default" checkbox here
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final model = AddressModel(
              id: 0,
              userId: me.id,
              street: streetCtrl.text.trim(),
              city: _opt(cityCtrl.text),
              zipCode: _opt(zipCtrl.text),
              country: _opt(countryCtrl.text),
              isDefault: false, // always false on create
            );
            final ok = await context.read<AddressProvider>().add(model);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Address added' : 'Failed to add address'),
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<void> showUpdateAddressDialog(
  BuildContext context,
  AddressModel a,
) async {
  final formKey = GlobalKey<FormState>();
  final streetCtrl = TextEditingController(text: a.street);
  final cityCtrl = TextEditingController(text: a.city ?? '');
  final zipCtrl = TextEditingController(text: a.zipCode ?? '');
  final countryCtrl = TextEditingController(text: a.country ?? '');

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Edit address'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: streetCtrl,
                decoration: const InputDecoration(labelText: 'Street *'),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: cityCtrl,
                decoration: const InputDecoration(labelText: 'City'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: zipCtrl,
                decoration: const InputDecoration(labelText: 'ZIP'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: countryCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                onTap: () {
                  showCountryPicker(
                    context: context,
                    favorite: const ['BA', 'HR', 'RS', 'DE', 'AT', 'CH'],
                    showPhoneCode: false,
                    countryListTheme: const CountryListThemeData(
                      bottomSheetHeight: 500,
                      inputDecoration: InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    onSelect: (c) => countryCtrl.text = c.name,
                  );
                },
              ),
              const SizedBox(height: 8),
              // NOTE: no "is default" checkbox here
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final model = AddressModel(
              id: a.id,
              userId: a.userId,
              street: streetCtrl.text.trim(),
              city: _opt(cityCtrl.text),
              zipCode: _opt(zipCtrl.text),
              country: _opt(countryCtrl.text),
              isDefault: a.isDefault, // preserve current default status
            );
            final ok = await context.read<AddressProvider>().edit(model);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Address updated' : 'Failed to update'),
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
