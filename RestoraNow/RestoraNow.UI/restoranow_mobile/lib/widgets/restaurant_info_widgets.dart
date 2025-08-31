import 'package:flutter/material.dart';

/// ===== Public helpers (re-usable) =====
String orDash(String? s) => (s == null || s.trim().isEmpty) ? '—' : s.trim();

String formatDateTime(DateTime dt) {
  final d = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

/// ===== Header (name + open/closed chip) =====
class RestaurantHeader extends StatelessWidget {
  const RestaurantHeader({
    super.key,
    required this.name,
    required this.isActive,
  });
  final String name;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.red;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.restaurant_menu, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Chip(
                label: Text(isActive ? 'Open' : 'Inactive'),
                labelStyle: TextStyle(
                  color: color.shade700,
                  fontWeight: FontWeight.w600,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                backgroundColor: color.withOpacity(0.12),
                side: BorderSide(color: color.withOpacity(0.3)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ===== Simple info tile (icon + label + value) =====
class RestaurantInfoTile extends StatelessWidget {
  const RestaurantInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(value),
      ),
    );
  }
}

/// ===== Section card with title =====
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

/// ===== Average rating summary =====
class RatingSummaryTile extends StatelessWidget {
  const RatingSummaryTile({super.key, required this.avg, required this.count});
  final double avg;
  final int count;

  @override
  Widget build(BuildContext context) {
    final avgText = avg == 0 ? '—' : avg.toStringAsFixed(1);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        leading: const Icon(Icons.star_rate_rounded, color: Colors.amber),
        title: Text('Average rating: $avgText'),
        subtitle: Text('$count review${count == 1 ? '' : 's'}'),
      ),
    );
  }
}

/// ===== 5-star picker =====
class StarPicker extends StatelessWidget {
  const StarPicker({super.key, required this.value, required this.onChanged});
  final int value; // 0..5
  final void Function(int)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final idx = i + 1;
        final filled = value >= idx;
        return IconButton(
          tooltip: '$idx',
          iconSize: 28,
          onPressed: onChanged == null ? null : () => onChanged!(idx),
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: Colors.amber,
          ),
        );
      }),
    );
  }
}

/// ===== "Your review" editor card =====
class YourReviewCard extends StatelessWidget {
  const YourReviewCard({
    super.key,
    required this.submitting,
    required this.rating,
    required this.commentController,
    required this.onSetRating,
    required this.onSave,
    required this.onClear,
    required this.hasExisting,
  });

  final bool submitting;
  final int rating;
  final TextEditingController commentController;
  final void Function(int) onSetRating;
  final VoidCallback onSave;
  final VoidCallback onClear;
  final bool hasExisting;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Your review',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarPicker(value: rating, onChanged: submitting ? null : onSetRating),
          const SizedBox(height: 8),
          TextField(
            controller: commentController,
            enabled: !submitting,
            minLines: 2,
            maxLines: 5,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'Comment (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: submitting ? null : onSave,
                icon: const Icon(Icons.save_outlined),
                label: Text(hasExisting ? 'Update' : 'Submit'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: submitting ? null : onClear,
                child: const Text('Clear'),
              ),
              if (submitting) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// ===== One review row =====
class ReviewRow extends StatelessWidget {
  const ReviewRow({
    super.key,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String userName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.account_circle, size: 28, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // name + date
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatDateTime(createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                // stars
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                  ),
                ),
                if ((comment ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(comment!.trim()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ===== Error view =====
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
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
              message,
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
