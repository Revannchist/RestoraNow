import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/menu_item_review_provider.dart';
import '../models/menu_item_review_model.dart';

Future<void> showMenuItemReviewsDialog(
  BuildContext context, {
  required int menuItemId,
  required String menuItemName,
}) async {
  // Prepare provider with filter
  final prov = context.read<MenuItemReviewProvider>();
  prov.setFilters(menuItemId: menuItemId); // triggers fetch

  await showDialog(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 720,
        height: 520,
        child: ChangeNotifierProvider.value(
          value: prov,
          child: const _ReviewsBody(),
        ),
      ),
    ),
  );
}

class _ReviewsBody extends StatelessWidget {
  const _ReviewsBody();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MenuItemReviewProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Menu Item Reviews',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => prov.refresh(),
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        if (prov.isLoading && prov.items.isEmpty)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (prov.error != null)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: ${prov.error}', textAlign: TextAlign.center),
              ),
            ),
          )
        else if (prov.items.isEmpty)
          const Expanded(
            child: Center(child: Text('No reviews yet')),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: prov.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _ReviewTile(review: prov.items[i]),
            ),
          ),

        // Pagination
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Text('Page ${prov.currentPage} of ${prov.totalPages == 0 ? 1 : prov.totalPages}'),
              const Spacer(),
              IconButton(
                tooltip: 'Prev',
                onPressed: prov.currentPage > 1 ? () => prov.setPage(prov.currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: 'Next',
                onPressed: (prov.currentPage < prov.totalPages)
                    ? () => prov.setPage(prov.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final MenuItemReviewModel review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if ((review.userName ?? '').trim().isNotEmpty) review.userName!.trim(),
      if ((review.userEmail ?? '').trim().isNotEmpty) review.userEmail!.trim(),
    ].where((e) => e.isNotEmpty).join(' • ');

    return ListTile(
      leading: _Stars(average: review.rating.toDouble()),
      title: Text(
        subtitle.isEmpty ? 'User #${review.userId}' : subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((review.comment ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(review.comment!.trim()),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _fmt(review.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
      // Admin is read-only: no trailing actions
    );
  }
}

class _Stars extends StatelessWidget {
  final double average;
  const _Stars({required this.average});

  @override
  Widget build(BuildContext context) {
    final full = average.floor();
    final hasHalf = (average - full) >= 0.25 && (average - full) < 0.75;
    final totalFull = hasHalf ? full : (average - full >= 0.75 ? full + 1 : full);
    final totalHalf = hasHalf ? 1 : 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < totalFull) return const Icon(Icons.star, size: 18, color: Colors.amber);
        if (i < totalFull + totalHalf) return const Icon(Icons.star_half, size: 18, color: Colors.amber);
        return const Icon(Icons.star_border, size: 18, color: Colors.amber);
      }),
    );
  }
}

String _fmt(DateTime dt) {
  final d = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}
