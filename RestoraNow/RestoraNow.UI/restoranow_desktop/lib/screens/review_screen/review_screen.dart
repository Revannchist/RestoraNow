import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../layouts/main_layout.dart';
import '../../providers/review_provider.dart';
import '../../widgets/pagination_controls.dart';
import '../../widgets/review_dialogs.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int? _ratingFilter;
  int? _userIdFilter;
  int? _restaurantIdFilter;

  @override
  void initState() {
    super.initState();
    Provider.of<ReviewProvider>(context, listen: false).fetchItems();
  }

  void _applyFilters() {
    Provider.of<ReviewProvider>(context, listen: false).setFilters(
      userId: _userIdFilter,
      restaurantId: _restaurantIdFilter,
      minRating: _ratingFilter,
      maxRating: _ratingFilter,
    );
  }

  void _resetFilters() {
    setState(() {
      _ratingFilter = null;
      _userIdFilter = null;
      _restaurantIdFilter = null;
    });
    Provider.of<ReviewProvider>(context, listen: false).setFilters();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Consumer<ReviewProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter UI
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _ratingFilter,
                        onChanged: (value) {
                          setState(() {
                            _ratingFilter = value;
                          });
                          _applyFilters();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Filter by rating',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('All Ratings'),
                          ),
                          ...List.generate(5, (index) {
                            final rating = index + 1;
                            return DropdownMenuItem<int>(
                              value: rating,
                              child: Text('$rating stars'),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),

              // Reviews List
              Expanded(
                child: ListView.builder(
                  itemCount: provider.items.length,
                  itemBuilder: (context, index) {
                    final review = provider.items[index];

                    return Card(
                      color: Theme.of(context).cardColor,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Info
                            Text(
                              '${review.userName ?? 'User #${review.userId}'} '
                              '(${review.userEmail ?? 'no email'})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Rating, Comment, CreatedAt
                            Text('Rating: ${review.rating}/5'),
                            if (review.comment?.isNotEmpty ?? false)
                              Text('Comment: ${review.comment}'),
                            Text(
                              'Created at: ${review.createdAt.toLocal()}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () =>
                                      showUpdateReviewDialog(context, review),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  color: Colors.red,
                                  onPressed: () =>
                                      _confirmDelete(context, review.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Pagination
              PaginationControls(
                currentPage: provider.currentPage,
                totalPages: provider.totalPages,
                pageSize: provider.pageSize,
                onPageChange: (page) => provider.setPage(page),
                onPageSizeChange: (size) => provider.setPageSize(size),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<ReviewProvider>().deleteItem(id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
