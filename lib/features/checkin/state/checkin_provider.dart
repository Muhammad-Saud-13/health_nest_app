import 'package:flutter/foundation.dart';

import '../../../data/models/check_in.dart';
import '../../../data/repositories/data_repository.dart';

/// State management for the 3-question self-report check-in.
///
/// Implements FR-8.1, FR-8.2, FR-8.3, FR-8.4, and NFR-4.3.
class CheckInProvider extends ChangeNotifier {
  CheckInProvider({required DataRepository dataRepository})
      : _dataRepository = dataRepository;

  final DataRepository _dataRepository;

  // 1: Fine, 2: Tired, 3: Unwell
  int? _feeling;
  int? get feeling => _feeling;

  // 1: No, 2: Mild, 3: Severe
  int? _pain;
  int? get pain => _pain;

  // 1: Low, 2: Medium, 3: High
  int? _stressSelf;
  int? get stressSelf => _stressSelf;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool _isSubmitted = false;
  bool get isSubmitted => _isSubmitted;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Number of questions answered so far (0 to 3).
  int get answeredCount {
    int count = 0;
    if (_feeling != null) count++;
    if (_pain != null) count++;
    if (_stressSelf != null) count++;
    return count;
  }

  /// Progress fraction (0.0 to 1.0) for the 3-segment progress indicator.
  double get progressFraction => answeredCount / 3.0;

  /// True when all 3 required questions have been answered.
  bool get isComplete =>
      _feeling != null && _pain != null && _stressSelf != null;

  void setFeeling(int value) {
    if (_feeling == value) return;
    _feeling = value;
    notifyListeners();
  }

  void setPain(int value) {
    if (_pain == value) return;
    _pain = value;
    notifyListeners();
  }

  void setStress(int value) {
    if (_stressSelf == value) return;
    _stressSelf = value;
    notifyListeners();
  }

  void reset() {
    _feeling = null;
    _pain = null;
    _stressSelf = null;
    _isSubmitting = false;
    _isSubmitted = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Submit the completed check-in to [DataRepository].
  Future<bool> submit({
    required int userId,
    required int sessionId,
    String kind = 'SHIFT_START',
  }) async {
    if (!isComplete) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final checkIn = CheckIn(
        sessionId: sessionId,
        userId: userId,
        kind: kind,
        feeling: _feeling!,
        pain: _pain!,
        stressSelf: _stressSelf!,
        submittedAt: DateTime.now(),
      );

      await _dataRepository.submitCheckIn(checkIn);

      _isSubmitting = false;
      _isSubmitted = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Failed to submit self report. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
