import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../layouts/main_layout.dart';
import '../../providers/review_provider.dart';
import '../../widgets/pagination_controls.dart';
import '../../widgets/review_dialogs.dart';

// errors/snacks
import '../../core/api_exception.dart';
import '../../widgets/helpers/error_dialog_helper.dart' as msg;

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  // Filters
  int? _ratingFilter;        // 1..5 or null (All)
  final _userIdCtrl = TextEditingController();
  final _restIdCtrl = TextEditingController();
  final _userIdFocus = FocusNode();
  final _restIdFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<ReviewProvider>().fetchItems();

    // Apply when leaving the field
    _userIdFocus.addListener(() {
      if (!_userIdFocus.hasFocus) _applyFilters();
    });
    _restIdFocus.addListener(() {
      if (!_restIdFocus.hasFocus) _applyFilters();
    });
  }

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _restIdCtrl.dispose();
    _userIdFocus.dispose();
    _restIdFocus.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final userId = int.tryParse(_userIdCtrl.text.trim());
    final restaurantId = int.tryParse(_restIdCtrl.text.trim());

    context.read<ReviewProvider>().setFilters(
          userId: userId,
          restaurantId: restaurantId,
          minRating: _ratingFilter,
          maxRating: _ratingFilter,
        );
  }

  void _resetFilters() {
    setState(() {
      _ratingFilter = null;
    });
    _userIdCtrl.clear();
    _restIdCtrl.clear();
    context.read<ReviewProvider>().setFilters();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Consumer<ReviewProvider>(
        builder: (context, provider, child) {
          final isFirstLoad = provider.isLoading && provider.items.isEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Rating
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<int?>(
                        value: _ratingFilter,
                        onChanged: (value) {
                          setState(() => _ratingFilter = value);
                          _applyFilters();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Filter by rating',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: const [
                          DropdownMenuItem<int?>(value: null, child: Text('All Ratings')),
                          DropdownMenuItem<int?>(value: 1, child: Text('1 star')),
                          DropdownMenuItem<int?>(value: 2, child: Text('2 stars')),
                          DropdownMenuItem<int?>(value: 3, child: Text('3 stars')),
                          DropdownMenuItem<int?>(value: 4, child: Text('4 stars')),
                          DropdownMenuItem<int?>(value: 5, child: Text('5 stars')),
                        ],
                      ),
                    ),

                    // User Id
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: _userIdCtrl,
                        focusNode: _userIdFocus,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'User ID',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),

                    // Restaurant Id
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: _restIdCtrl,
                        focusNode: _restIdFocus,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Restaurant ID',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),

                    TextButton(onPressed: _resetFilters, child: const Text('Reset')),
                  ],
                ),
              ),

              // List + overlay progress
              Expanded(
                child: Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: isFirstLoad
                          ? const Center(child: CircularProgressIndicator())
                          : _buildListOrState(provider),
                    ),

                    if (provider.isLoading && provider.items.isNotEmpty)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                  ],
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

  Widget _buildListOrState(ReviewProvider provider) {
    if (provider.error != null && provider.items.isEmpty) {
      return Center(child: Text('Error: ${provider.error}'));
    }
    if (provider.items.isEmpty) {
      return const Center(child: Text('No reviews found'));
    }

    return ListView.builder(
      key: ValueKey(provider.items.length),
      itemCount: provider.items.length,
      itemBuilder: (context, index) {
        final review = provider.items[index];
        return Card(
          color: Theme.of(context).cardColor,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User
                Text(
                  '${review.userName ?? 'User #${review.userId}'} '
                  '(${review.userEmail ?? 'no email'})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),

                // Rating / Comment / Created
                Text('Rating: ${review.rating}/5'),
                if (review.comment?.isNotEmpty ?? false)
                  Text('Comment: ${review.comment}'),
                Text(
                  'Created at: ${_formatDate(review.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => showUpdateReviewDialog(context, review),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      color: Colors.red,
                      onPressed: () => _confirmDelete(context, review.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _pad2(int n) => n.toString().padLeft(2, '0');
  String _formatDate(DateTime dt) =>
      '${_pad2(dt.day)}/${_pad2(dt.month)}/${dt.year} ${_pad2(dt.hour)}:${_pad2(dt.minute)}';

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await context.read<ReviewProvider>().deleteItem(id);
                if (!context.mounted) return;
                Navigator.pop(context);
                msg.showSnackMessage(context, 'Review deleted', type: msg.AppMessageType.success);
              } on ApiException catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context);
                msg.showApiErrorSnack(context, e);
              } catch (_) {
                if (!context.mounted) return;
                Navigator.pop(context);
                msg.showSnackMessage(context, 'Something went wrong. Please try again.');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
