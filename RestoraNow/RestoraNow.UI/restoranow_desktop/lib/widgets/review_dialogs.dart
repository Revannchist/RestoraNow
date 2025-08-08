import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/review_model.dart';
import '../providers/review_provider.dart';

void showCreateReviewDialog(BuildContext context) {
  final _formKey = GlobalKey<FormState>();
  final ratingController = TextEditingController();
  final commentController = TextEditingController();
  final userIdController = TextEditingController();
  final restaurantIdController = TextEditingController();

  bool isTouched = false;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Create Review'),
        content: Form(
          key: _formKey,
          autovalidateMode: isTouched
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: userIdController,
                  decoration: const InputDecoration(labelText: 'User ID'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'User ID is required.';
                    if (int.tryParse(value) == null)
                      return 'User ID must be a number.';
                    return null;
                  },
                  onChanged: (_) => isTouched = true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: restaurantIdController,
                  decoration: const InputDecoration(labelText: 'Restaurant ID'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Restaurant ID is required.';
                    if (int.tryParse(value) == null)
                      return 'Restaurant ID must be a number.';
                    return null;
                  },
                  onChanged: (_) => isTouched = true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ratingController,
                  decoration: const InputDecoration(labelText: 'Rating (1–5)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final rating = int.tryParse(value ?? '');
                    if (rating == null || rating < 1 || rating > 5) {
                      return 'Rating must be between 1 and 5.';
                    }
                    return null;
                  },
                  onChanged: (_) => isTouched = true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: commentController,
                  decoration: const InputDecoration(labelText: 'Comment'),
                  maxLines: 3,
                  maxLength: 1000,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<ReviewProvider>(
            builder: (context, provider, child) {
              return ElevatedButton(
                onPressed: () {
                  isTouched = true;
                  if (_formKey.currentState!.validate()) {
                    final review = ReviewModel(
                      id: 0,
                      userId: int.parse(userIdController.text),
                      restaurantId: int.parse(restaurantIdController.text),
                      rating: int.parse(ratingController.text),
                      comment: commentController.text.trim().isEmpty
                          ? null
                          : commentController.text.trim(),
                      createdAt: DateTime.now(),
                    );
                    provider.createItem(review);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Create'),
              );
            },
          ),
        ],
      );
    },
  );
}

void showUpdateReviewDialog(BuildContext context, ReviewModel review) {
  final _formKey = GlobalKey<FormState>();
  final commentController = TextEditingController(text: review.comment ?? '');

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Update Review'),
        content: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User name
                Text(
                  'User: ${review.userName ?? 'User #${review.userId}'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Rating display (read-only)
                Text('Rating: ${review.rating}/5'),
                const SizedBox(height: 12),

                // Editable comment
                TextFormField(
                  controller: commentController,
                  decoration: const InputDecoration(labelText: 'Comment'),
                  maxLines: 3,
                  maxLength: 1000,
                ),
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
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final updatedReview = ReviewModel(
                  id: review.id,
                  userId: review.userId,
                  restaurantId: review.restaurantId,
                  rating: review.rating, // keep original rating
                  comment: commentController.text.trim().isEmpty
                      ? null
                      : commentController.text.trim(),
                  createdAt: review.createdAt,
                  userName: review.userName,
                  userEmail: review.userEmail,
                  restaurantName: review.restaurantName,
                );

                Provider.of<ReviewProvider>(
                  context,
                  listen: false,
                ).updateItem(updatedReview);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      );
    },
  );
}
