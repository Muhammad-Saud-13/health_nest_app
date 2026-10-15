import 'dart:math';
import '../models/alert.dart';
import '../models/check_in.dart';
import '../models/classification.dart';
import '../models/shift_session.dart';
import '../models/spo2_reading.dart';
import 'data_repository.dart';

/// Mock implementation of DataRepository providing canned shift data,
/// 24h classifications (Calm & Stressed), alerts, and check-in storage.
class MockDataRepository implements DataRepository {
  ShiftSession? _activeSession;
  final List<CheckIn> _checkIns = [];
  final List<Alert> _alerts = [];
  final List<Classification> _classifications = [];
  final List<Spo2Reading> _spo2Readings = [];

  MockDataRepository() {
    _initializeCannedData();
  }

  void _initializeCannedData() {
    final now = DateTime.now();

    // Default active shift starting 2 hours ago
    _activeSession = ShiftSession(
      id: 101,
      userId: 1,
      shiftTypeId: 1,
      departmentId: 101,
      shiftDate: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      startedAt: now.subtract(const Duration(hours: 2)),
      status: 'ACTIVE',
      startMethod: 'MANUAL',
      baselineTemp: 36.4,
      baselineStatus: 'DONE',
      baselineWindowCount: 12,
    );

    // Generate 24 hours of classification history
    // Standard schedule: mostly Calm, with a couple of Stressed episodes
    final random = Random(42);
    for (int i = 24; i >= 0; i--) {
      final windowStart = now.subtract(Duration(hours: i));
      final windowEnd = windowStart.add(const Duration(minutes: 5));

      // Simulate a stress episode around 3 hours ago and 14 hours ago
      final isStressWindow = (i == 3 || i == 4 || i == 14);

      final double hr = isStressWindow
          ? 104.0 + random.nextDouble() * 8.0
          : 70.0 + random.nextDouble() * 8.0;

      final double rmssd = isStressWindow
          ? 22.0 + random.nextDouble() * 6.0
          : 54.0 + random.nextDouble() * 12.0;

      final double stressProb = isStressWindow
          ? 0.88 + random.nextDouble() * 0.08
          : 0.15 + random.nextDouble() * 0.20;

      final classification = Classification(
        id: 1000 + i,
        sessionId: 101,
        userId: 1,
        windowStart: windowStart,
        windowEnd: windowEnd,
        hrMean: double.parse(hr.toStringAsFixed(1)),
        rmssd: double.parse(rmssd.toStringAsFixed(1)),
        sma: isStressWindow ? 1.4 : 0.8,
        tempMean: 36.5,
        tempDelta: isStressWindow ? 0.3 : 0.0,
        label: isStressWindow ? 'STRESSED' : 'CALM',
        stressProb: double.parse(stressProb.toStringAsFixed(2)),
        isCalibrating: false,
      );

      _classifications.add(classification);

      // Add SpO2 readings
      final spo2Val = (i == 3) ? 94.0 : 97.0 + (random.nextDouble() * 2.0);
      _spo2Readings.add(
        Spo2Reading(
          id: 500 + i,
          sessionId: 101,
          value: double.parse(spo2Val.toStringAsFixed(1)),
          recordedAt: windowStart,
        ),
      );
    }

    // Add a canned open alert for sustained stress from earlier
    _alerts.add(
      Alert(
        id: 1,
        sessionId: 101,
        userId: 1,
        type: 'STRESS_SUSTAINED',
        createdAt: now.subtract(const Duration(minutes: 45)),
        status: 'OPEN',
      ),
    );

    // Add a canned SpO2 low alert (linked to the i==3 window where spo2 was 94%)
    _alerts.add(
      Alert(
        id: 2,
        sessionId: 101,
        userId: 1,
        type: 'SPO2_LOW',
        createdAt: now.subtract(const Duration(hours: 3)),
        status: 'ACK', // Already acknowledged (historical)
      ),
    );
  }

  @override
  Future<ShiftSession?> getActiveShiftSession({required int userId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _activeSession;
  }

  @override
  Future<ShiftSession> startShiftSession({
    required int userId,
    String startMethod = 'MANUAL',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    _activeSession = ShiftSession(
      id: Random().nextInt(10000) + 200,
      userId: userId,
      shiftDate: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      startedAt: now,
      status: 'ACTIVE',
      startMethod: startMethod,
      baselineStatus: 'PENDING',
      baselineWindowCount: 0,
    );
    return _activeSession!;
  }

  @override
  Future<ShiftSession> endShiftSession({required int sessionId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (_activeSession != null && _activeSession!.id == sessionId) {
      _activeSession = _activeSession!.copyWith(
        status: 'CLOSED',
        endedAt: DateTime.now(),
      );
      final closed = _activeSession!;
      _activeSession = null;
      return closed;
    }

    return ShiftSession(
      id: sessionId,
      userId: 1,
      shiftDate: '2026-10-09',
      startedAt: DateTime.now().subtract(const Duration(hours: 8)),
      endedAt: DateTime.now(),
      status: 'CLOSED',
    );
  }

  @override
  Future<List<Classification>> getRecentClassifications({
    required int userId,
    Duration window = const Duration(hours: 24),
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final cutoff = DateTime.now().subtract(window);
    return _classifications
        .where((c) => c.userId == userId && c.windowStart.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.windowStart.compareTo(a.windowStart)); // Latest first
  }

  @override
  Future<Classification?> getLatestClassification({required int userId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final userItems = _classifications.where((c) => c.userId == userId).toList();
    if (userItems.isEmpty) return null;
    userItems.sort((a, b) => b.windowStart.compareTo(a.windowStart));
    return userItems.first;
  }

  @override
  Future<List<Alert>> getActiveAlerts({required int userId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _alerts.where((a) => a.userId == userId && a.isOpen).toList();
  }

  @override
  Future<void> acknowledgeAlert({required int alertId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(status: 'ACK');
    }
  }

  @override
  Future<void> submitCheckIn(CheckIn checkIn) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _checkIns.add(checkIn);
  }

  @override
  Future<List<Spo2Reading>> getRecentSpo2Readings({required int sessionId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _spo2Readings
        .where((r) => r.sessionId == sessionId)
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }

  /// Helper to insert a classification for dynamic mock scenarios.
  void addClassification(Classification classification) {
    _classifications.add(classification);
  }

  /// Helper to insert an alert for dynamic mock scenarios.
  void addAlert(Alert alert) {
    _alerts.add(alert);
  }

  /// Generate a sustained stress alert (simulates backend D-24 behaviour).
  void generateSustainedStressAlert({required int userId, required int sessionId}) {
    final existingOpen = _alerts.any(
      (a) => a.type == 'STRESS_SUSTAINED' && a.userId == userId && a.isOpen,
    );
    if (!existingOpen) {
      _alerts.add(
        Alert(
          id: DateTime.now().millisecondsSinceEpoch,
          sessionId: sessionId,
          userId: userId,
          type: 'STRESS_SUSTAINED',
          createdAt: DateTime.now(),
          status: 'OPEN',
        ),
      );
    }
  }

  /// Generate a low SpO2 alert (simulates backend SPO2_LOW detection).
  void generateLowSpo2Alert({required int userId, required int sessionId}) {
    final existingOpen = _alerts.any(
      (a) => a.type == 'SPO2_LOW' && a.userId == userId && a.isOpen,
    );
    if (!existingOpen) {
      _alerts.add(
        Alert(
          id: DateTime.now().millisecondsSinceEpoch + 1,
          sessionId: sessionId,
          userId: userId,
          type: 'SPO2_LOW',
          createdAt: DateTime.now(),
          status: 'OPEN',
        ),
      );
    }
  }
}
