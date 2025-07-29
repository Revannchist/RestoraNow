import 'package:flutter/foundation.dart';

abstract class PaginatedProvider<T> extends ChangeNotifier {
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalCount = 0;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalCount / _pageSize).ceil();
  int get totalCount => _totalCount;

  late List<T> items;
  bool isLoading = false;
  String? error;

  void setPage(int page) {
    _currentPage = page;
    fetchData();
  }

  void setPageSize(int newSize) {
    _pageSize = newSize;
    _currentPage = 1;
    fetchData();
  }

  @protected
  Future<void> fetchData();

  @protected
  void setTotalCount(int count) => _totalCount = count;
}
