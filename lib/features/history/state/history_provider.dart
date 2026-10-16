import 'package:flutter/foundation.dart';

import '../../../data/models/classification.dart';
import '../../../data/models/shift_session.dart';
import '../../../data/repositories/data_repository.dart';

/// State management for the 24-Hour State History screen.
///
/// Implements FR-7.6: Displays own state history for the last 24 hours
/// using timeline data from [DataRepository].
class HistoryProvider extends ChangeNotifier {
  HistoryProvider({
    required DataRepository dataRepository,
    required int userId,
  })  : _dataRepository = dataRepository,
        _userId = userId;

  final DataRepository _dataRepository;
  final int _userId;

  List<Classification> _classifications = [];
  List<Classification> get classifications => List.unmodifiable(_classifications);

  ShiftSession? _activeSession;
  ShiftSession? get activeSession => _activeSession;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Total number of classification records logged in the last 24h.
  int get totalRecords => _classifications.length;

  /// Number of calm classifications.
  int get calmCount => _classifications.where((c) => c.isCalm).length;

  /// Number of stressed classifications.
  int get stressedCount => _classifications.where((c) => c.isStressed).length;

  /// Percentage of records classified as Calm (0–100%).
  int get calmPercentage {
    if (_classifications.isEmpty) return 100;
    return ((calmCount / _classifications.length) * 100).round();
  }

  /// Whether an active shift session is currently underway.
  bool get hasActiveShift => _activeSession != null && _activeSession!.isActive;

  /// Formatted shift label (e.g. "Active Shift • Station 101" or "Active Shift").
  String get shiftBadgeLabel {
    if (_activeSession != null && _activeSession!.departmentId != null) {
      return 'Active Shift • Line ${_activeSession!.departmentId}';
    }
    return 'Active Shift';
  }

  /// Load classification history and session data.
  Future<void> loadHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _dataRepository.getRecentClassifications(
        userId: _userId,
        window: const Duration(hours: 24),
      );
      _classifications = results;

      _activeSession = await _dataRepository.getActiveShiftSession(
        userId: _userId,
      );
    } catch (e) {
      _errorMessage = 'Failed to load state history: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pull-to-refresh handler.
  Future<void> refresh() => loadHistory();
}
