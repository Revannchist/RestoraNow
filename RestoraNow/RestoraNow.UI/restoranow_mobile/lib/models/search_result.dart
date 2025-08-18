class SearchResult<T> {
  final List<T> items;
  final int totalCount;

  SearchResult({
    required this.items,
    required this.totalCount,
  });

  factory SearchResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final List<T> items = (json['items'] as List)
        .map((item) => fromJsonT(item as Map<String, dynamic>))
        .toList();

    return SearchResult(
      items: items,
      totalCount: json['totalCount'] ?? 0,
    );
  }
}
