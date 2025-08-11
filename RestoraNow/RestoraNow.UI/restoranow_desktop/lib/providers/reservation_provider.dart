import 'package:flutter/material.dart';
import '../models/reservation_model.dart';
import '../core/reservation_api_service.dart';
import '../models/search_result.dart';

class ReservationProvider with ChangeNotifier {
  final ReservationApiService _apiService = ReservationApiService();

  List<ReservationModel> _items = [];
  bool _isLoading = false;
  String? _error;

  int? _userIdFilter;
  int? _tableIdFilter;
  ReservationStatus? _statusFilter;
  DateTime? _fromDateFilter;
  DateTime? _toDateFilter;

  int _totalCount = 0;
  int _currentPage = 1;
  int _pageSize = 10;

  // Getters
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalCount / _pageSize).ceil();

  List<ReservationModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _totalCount;

  // Pagination
  void setPage(int page) {
    _currentPage = page;
    fetchItems();
  }

  void setPageSize(int size) {
    _pageSize = size;
    _currentPage = 1;
    fetchItems();
  }

  // Filtering
  void setFilters({
    int? userId,
    int? tableId,
    ReservationStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    _userIdFilter = userId;
    _tableIdFilter = tableId;
    _statusFilter = status;
    _fromDateFilter = fromDate;
    _toDateFilter = toDate;
    _currentPage = 1;
    fetchItems();
  }

  // Fetch Reservations
  Future<void> fetchItems({String? sortBy, bool ascending = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final filter = <String, String>{};

      if (_userIdFilter != null) {
        filter['UserId'] = _userIdFilter.toString();
      }
      if (_tableIdFilter != null) {
        filter['TableId'] = _tableIdFilter.toString();
      }
      if (_statusFilter != null) {
        filter['Status'] = _statusToBackendString(_statusFilter!);
      }
      if (_fromDateFilter != null) {
        filter['FromDate'] = _formatDate(_fromDateFilter!);
      }
      if (_toDateFilter != null) {
        filter['ToDate'] = _formatDate(_toDateFilter!);
      }

      final SearchResult<ReservationModel> result = await _apiService.get(
        filter: filter,
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: sortBy,
        ascending: ascending,
      );

      _items = result.items;
      _totalCount = result.totalCount;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create
  Future<ReservationModel?> createItem(ReservationModel item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final payload = _toRequestJson(item);
      final created = await _apiService.insert(payload);

      // Append to local list & count
      _items.add(created);
      _totalCount += 1;

      return created;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update
  Future<void> updateItem(ReservationModel item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final payload = _toRequestJson(item);
      final updated = await _apiService.update(item.id, payload);

      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        final prev = _items[index];
        _items[index] = ReservationModel(
          id: updated.id,
          userId: updated.userId,
          userName: updated.userName ?? prev.userName, // preserve if missing
          tableId: updated.tableId,
          tableNumber:
              updated.tableNumber ?? prev.tableNumber, // preserve if missing
          reservationDate: updated.reservationDate,
          reservationTime: updated.reservationTime,
          guestCount: updated.guestCount,
          status: updated.status,
          specialRequests: updated.specialRequests,
          confirmedAt: updated.confirmedAt,
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete
  Future<void> deleteItem(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete(id);
      _items.removeWhere((i) => i.id == id);
      _totalCount = _totalCount > 0 ? _totalCount - 1 : 0;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------- Helpers ----------
  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _statusToBackendString(ReservationStatus s) {
    // Capitalize to match C# enum names
    final name = s.name; // e.g., "pending"
    if (name.toLowerCase() == 'noshow') return 'NoShow';
    return name[0].toUpperCase() + name.substring(1);
  }

  Map<String, dynamic> _toRequestJson(ReservationModel item) {
    // Build request DTO (exclude read-only response fields)
    return {
      'userId': item.userId,
      'tableId': item.tableId,
      'reservationDate': _formatDate(item.reservationDate),
      'reservationTime': item.reservationTime, // "HH:mm:ss"
      'guestCount': item.guestCount,
      if (item.specialRequests != null &&
          item.specialRequests!.trim().isNotEmpty)
        'specialRequests': item.specialRequests,
      'status': _statusToBackendString(item.status),
    };
  }
}
