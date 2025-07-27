// lib/widgets/pagination_controls.dart
import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final List<int> pageSizeOptions;
  final void Function(int page) onPageChange;
  final void Function(int pageSize) onPageSizeChange;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.onPageChange,
    required this.onPageSizeChange,
    this.pageSizeOptions = const [5, 10, 25, 50],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Items per page:'),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: pageSize,
              onChanged: (value) {
                if (value != null) onPageSizeChange(value);
              },
              items: pageSizeOptions
                  .map((size) => DropdownMenuItem<int>(
                        value: size,
                        child: Text('$size'),
                      ))
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: currentPage > 1
                  ? () => onPageChange(currentPage - 1)
                  : null,
            ),
            ...List.generate(
              totalPages,
              (index) {
                final page = index + 1;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentPage == page
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300],
                    foregroundColor: currentPage == page
                        ? Colors.white
                        : Colors.black,
                  ),
                  onPressed: () => onPageChange(page),
                  child: Text('$page'),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: currentPage < totalPages
                  ? () => onPageChange(currentPage + 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
