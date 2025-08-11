import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/restaurant_model.dart';
import '../providers/restaurant_provider.dart';

void showEditRestaurantDialog(BuildContext context) {
  final provider = Provider.of<RestaurantProvider>(context, listen: false);
  final restaurant = provider.restaurant;

  if (restaurant == null) return;

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController(text: restaurant.name);
  final addressController = TextEditingController(text: restaurant.address);
  final phoneController = TextEditingController(text: restaurant.phoneNumber);
  final emailController = TextEditingController(text: restaurant.email);
  final descriptionController = TextEditingController(
    text: restaurant.description,
  );

  bool isActive = restaurant.isActive;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Restaurant Info'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              /*
              SwitchListTile(
                title: const Text('Is Active'),
                value: isActive,
                onChanged: (value) {
                  isActive = value;
                  (context as Element).markNeedsBuild();
                },
              ),
              */
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final updated = RestaurantModel(
                id: restaurant.id,
                name: nameController.text,
                address: addressController.text,
                phoneNumber: phoneController.text,
                email: emailController.text,
                description: descriptionController.text,
                isActive: isActive,
                createdAt: restaurant.createdAt,
              );
              await provider.updateRestaurant(updated);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
