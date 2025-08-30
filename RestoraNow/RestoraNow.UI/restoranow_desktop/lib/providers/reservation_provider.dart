// lib/providers/reservation_provider.dart
import 'package:flutter/material.dart';
import '../models/reservation_model.dart';
import '../core/reservation_api_service.dart';
import '../models/search_result.dart';

class ReservationProvider with ChangeNotifier {
  final ReservationApiService _apiService = ReservationApiService();

  // Data
  List<ReservationModel> _items = [];
  bool _isLoading = false;
  String? _error;

  // Filters
  int? _userIdFilter;
  int? _tableIdFilter;
  ReservationStatus? _statusFilter;
  DateTime? _fromDateFilter;
  DateTime? _toDateFilter;

  // Paging
  int _totalCount = 0;
  int _currentPage = 1;
  int _pageSize = 10;

  // Public getters
  List<ReservationModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _totalCount;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalCount / _pageSize).ceil();

  // ---------- Paging ----------
  void setPage(int page) {
    _currentPage = page;
    fetchItems();
  }

  void setPageSize(int size) {
    _pageSize = size;
    _currentPage = 1;
    fetchItems();
  }

  // ---------- Filters ----------
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

  // ---------- Queries ----------
  Future<void> fetchItems({String? sortBy, bool ascending = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final filter = <String, String>{};

      if (_userIdFilter != null) filter['UserId'] = _userIdFilter.toString();
      if (_tableIdFilter != null) filter['TableId'] = _tableIdFilter.toString();
      if (_statusFilter != null)
        filter['Status'] = _statusToBackendString(_statusFilter!);
      if (_fromDateFilter != null)
        filter['FromDate'] = _formatDate(_fromDateFilter!);
      if (_toDateFilter != null) filter['ToDate'] = _formatDate(_toDateFilter!);

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

  // ---------- CRUD ----------
  Future<ReservationModel?> createItem(ReservationModel item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final payload = _toRequestJson(
        item,
      ); // always includes specialRequests ("" if null)
      final created = await _apiService.insert(payload);

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

  Future<void> updateItem(ReservationModel item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final payload = _toRequestJson(
        item,
      ); // always includes specialRequests ("" if null)
      final updated = await _apiService.update(item.id, payload);
      _mergeIntoList(updated);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  // ---------- Quick status change (used by screen) ----------
  Future<bool> setStatus(int id, ReservationStatus newStatus) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch current to build a full, backend-friendly body
      final current = await _apiService.getById(id);

      final payload = {
        'userId': current.userId,
        'tableId': current.tableId,
        'reservationDate': _formatDate(current.reservationDate), // yyyy-MM-dd
        'reservationTime': _ensureHms(current.reservationTime), // HH:mm:ss
        'guestCount': current.guestCount,
        // IMPORTANT: Always send this, even if empty string
        'specialRequests': (current.specialRequests ?? ''),
        'status': _statusToBackendString(newStatus),
      };

      final updated = await _apiService.update(id, payload);
      _mergeIntoList(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------- Helpers ----------
  void _mergeIntoList(ReservationModel updated) {
    final idx = _items.indexWhere((i) => i.id == updated.id);
    if (idx != -1) {
      final prev = _items[idx];
      _items[idx] = ReservationModel(
        id: updated.id,
        userId: updated.userId,
        userName: updated.userName ?? prev.userName,
        tableId: updated.tableId,
        tableNumber: updated.tableNumber ?? prev.tableNumber,
        reservationDate: updated.reservationDate,
        reservationTime: updated.reservationTime,
        guestCount: updated.guestCount,
        status: updated.status,
        specialRequests: updated.specialRequests,
        confirmedAt: updated.confirmedAt,
      );
    } else {
      _items.insert(0, updated);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _ensureHms(String s) {
    // normalize "HH:mm" -> "HH:mm:00"
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(s)) return '$s:00';
    return s; // assume already HH:mm:ss
  }

  String _statusToBackendString(ReservationStatus s) {
    final name = s.name;
    if (name.toLowerCase() == 'noshow') return 'NoShow';
    return name[0].toUpperCase() + name.substring(1);
  }

  Map<String, dynamic> _toRequestJson(ReservationModel item) {
    return {
      'userId': item.userId,
      'tableId': item.tableId,
      'reservationDate': _formatDate(item.reservationDate),
      'reservationTime': _ensureHms(item.reservationTime),
      'guestCount': item.guestCount,
      // IMPORTANT: Always include (empty string if null) to avoid DB NOT NULL errors
      'specialRequests': (item.specialRequests ?? ''),
      'status': _statusToBackendString(item.status),
    };
  }
}
