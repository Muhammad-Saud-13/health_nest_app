import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config.dart';
import '../../../data/models/alert.dart';
import '../../../data/models/classification.dart';
import '../../../data/models/sensor_packet.dart';
import '../../../data/repositories/data_repository.dart';
import '../../../data/repositories/mock_data_repository.dart';
import '../../../data/sources/mock_wearable_source.dart';
import '../../../data/sources/wearable_source.dart';

/// Provider managing live sensor data, classification state, and connection
/// status for the Home Screen.
///
/// Subscribes to [WearableSource.sensorStream] for live HR / SpO2 and
/// [WearableSource.connectionStateStream] for BLE banner. Periodically
/// polls [DataRepository.getLatestClassification] for ML state.
class HomeProvider extends ChangeNotifier {
  HomeProvider({
    required WearableSource wearableSource,
    required DataRepository dataRepository,
    int userId = 1,
  })  : _wearableSource = wearableSource,
        _dataRepo = dataRepository,
        _userId = userId {
    _init();
  }

  final WearableSource _wearableSource;
  final DataRepository _dataRepo;
  final int _userId;

  StreamSubscription<SensorPacket>? _sensorSub;
  StreamSubscription<WearableConnectionState>? _connectionSub;
  Timer? _classificationPollTimer;

  // ---------------------------------------------------------------------------
  // Live Vitals
  // ---------------------------------------------------------------------------

  double _heartRate = 0;
  double get heartRate => _heartRate;

  double _spo2 = 0;
  double get spo2 => _spo2;

  /// HR status label based on value.
  String get hrStatusLabel {
    if (_heartRate <= 0) return '--';
    if (_heartRate > 100) return 'Elevated';
    if (_heartRate >= 60) return 'Normal';
    return 'Low';
  }

  /// SpO2 status label based on threshold (D-04: < 95% is critical).
  String get spo2StatusLabel {
    if (_spo2 <= 0) return '--';
    if (_spo2 < AppConfig.lowSpo2Threshold) return 'Low';
    return 'Good';
  }

  bool get isSpo2Low => _spo2 > 0 && _spo2 < AppConfig.lowSpo2Threshold;

  // ---------------------------------------------------------------------------
  // Connection State
  // ---------------------------------------------------------------------------

  WearableConnectionState _connectionState =
      WearableConnectionState.disconnected;
  WearableConnectionState get connectionState => _connectionState;

  bool get isConnected =>
      _connectionState == WearableConnectionState.connected;
  bool get isConnecting =>
      _connectionState == WearableConnectionState.connecting;
  bool get isReconnecting =>
      _connectionState == WearableConnectionState.reconnecting;
  bool get isDisconnected =>
      _connectionState == WearableConnectionState.disconnected;

  Future<void> retryConnection() async {
    await _wearableSource.connect();
  }

  // ---------------------------------------------------------------------------
  // Classification / ML State
  // ---------------------------------------------------------------------------

  Classification? _latestClassification;
  Classification? get latestClassification => _latestClassification;

  /// Current display label: 'Calm', 'Stressed', or 'Getting Ready'.
  String get stateLabel {
    if (_latestClassification == null) return 'Getting Ready';
    return _latestClassification!.isStressed ? 'Stressed' : 'Calm';
  }

  bool get isStressed => _latestClassification?.isStressed ?? false;
  bool get isCalm => _latestClassification?.isCalm ?? false;

  // ---------------------------------------------------------------------------
  // Shift Info
  // ---------------------------------------------------------------------------

  DateTime? _shiftStartTime;
  DateTime? get shiftStartTime => _shiftStartTime;

  String get shiftStartTimeFormatted {
    if (_shiftStartTime == null) return 'Shift active';
    final hour = _shiftStartTime!.hour;
    final minute = _shiftStartTime!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return 'Shift active since $displayHour:$minute $period';
  }

  // ---------------------------------------------------------------------------
  // Passive Tip Card (D-24)
  // ---------------------------------------------------------------------------

  bool _tipDismissed = false;
  bool get tipDismissed => _tipDismissed;

  void dismissTip() {
    _tipDismissed = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Backend Alerts (FR-6.2, FR-9.1 — Sustained Stress & SpO2 Low)
  // ---------------------------------------------------------------------------

  List<Alert> _activeAlerts = [];
  List<Alert> get activeAlerts => List.unmodifiable(_activeAlerts);

  /// True when backend has generated a sustained-stress alert (STRESS_SUSTAINED)
  /// and the worker is currently in a Stressed state (FR-6.2, FR-9.1, D-24).
  bool get hasSustainedStressAlert =>
      isStressed &&
      _activeAlerts.any((a) => a.type == 'STRESS_SUSTAINED' && a.isOpen);

  /// The most recent open sustained-stress alert, or null.
  Alert? get sustainedStressAlert {
    final matches = _activeAlerts
        .where((a) => a.type == 'STRESS_SUSTAINED' && a.isOpen)
        .toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches.first;
  }

  /// True when backend has generated a low-SpO2 alert.
  bool get hasLowSpo2Alert =>
      _activeAlerts.any((a) => a.type == 'SPO2_LOW' && a.isOpen);

  /// The most recent open SpO2-low alert, or null.
  Alert? get lowSpo2Alert {
    final matches = _activeAlerts
        .where((a) => a.type == 'SPO2_LOW' && a.isOpen)
        .toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches.first;
  }

  bool _spo2AlertDismissed = false;
  bool get spo2AlertDismissed => _spo2AlertDismissed;

  /// Acknowledge an alert (FR-9.3). Updates local state and calls repository.
  Future<void> acknowledgeAlert(int alertId) async {
    // Dismiss fallback tip cards as well so a second redundant card never appears.
    _tipDismissed = true;
    _spo2AlertDismissed = true;
    await _dataRepo.acknowledgeAlert(alertId: alertId);
    // Refresh alerts after acknowledging
    await _loadAlerts();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Scenario Simulation (For testing & interactive preview)
  // ---------------------------------------------------------------------------

  void simulateScenario(MockScenario scenario) {
    final source = _wearableSource;
    if (source is MockWearableSource) {
      source.setScenario(scenario);

      final now = DateTime.now();
      final repo = _dataRepo;

      if (scenario == MockScenario.stressSpike) {
        final stressed = Classification(
          id: DateTime.now().millisecondsSinceEpoch,
          sessionId: 101,
          userId: _userId,
          windowStart: now.subtract(const Duration(minutes: 5)),
          windowEnd: now,
          hrMean: 106.0,
          rmssd: 20.0,
          sma: 1.5,
          tempMean: 36.8,
          tempDelta: 0.3,
          label: 'STRESSED',
          stressProb: 0.89,
          isCalibrating: false,
        );
        _latestClassification = stressed;
        if (repo is MockDataRepository) {
          repo.addClassification(stressed);
          // Simulate backend generating a sustained stress alert (FR-6.2)
          repo.generateSustainedStressAlert(
            userId: _userId,
            sessionId: 101,
          );
        }
        _tipDismissed = false;
      } else if (scenario == MockScenario.lowSpo2) {
        _spo2AlertDismissed = false;
        // Also generate a low SpO2 backend alert
        if (repo is MockDataRepository) {
          repo.generateLowSpo2Alert(userId: _userId, sessionId: 101);
        }
      } else if (scenario == MockScenario.calm) {
        final calm = Classification(
          id: DateTime.now().millisecondsSinceEpoch,
          sessionId: 101,
          userId: _userId,
          windowStart: now.subtract(const Duration(minutes: 5)),
          windowEnd: now,
          hrMean: 72.0,
          rmssd: 55.0,
          sma: 0.8,
          tempMean: 36.5,
          tempDelta: 0.0,
          label: 'CALM',
          stressProb: 0.12,
          isCalibrating: false,
        );
        _latestClassification = calm;
        if (repo is MockDataRepository) {
          repo.addClassification(calm);
        }
      }

      // Refresh alerts to reflect scenario changes
      _loadAlerts();
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // ---------------------------------------------------------------------------
  // Init / Teardown
  // ---------------------------------------------------------------------------

  Future<void> _init() async {
    // Listen to connection state changes.
    _connectionSub = _wearableSource.connectionStateStream.listen((state) {
      _connectionState = state;
      notifyListeners();
    });

    // Listen to sensor packets for live vitals.
    _sensorSub = _wearableSource.sensorStream.listen((packet) {
      _heartRate = packet.localHeartRate ?? 0;
      _spo2 = packet.spo2;
      notifyListeners();
    });

    // Auto-connect the wearable source.
    await _wearableSource.connect();

    // Load initial classification, alerts, and shift info.
    await _loadClassification();
    await _loadAlerts();
    await _loadShiftInfo();

    _isLoading = false;
    notifyListeners();

    // Poll for updated classification and alerts every 5 seconds (simulates backend push).
    _classificationPollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) {
      _loadClassification();
      _loadAlerts();
    });
  }

  Future<void> _loadClassification() async {
    final source = _wearableSource;
    if (source is MockWearableSource &&
        source.currentScenario == MockScenario.stressSpike) {
      // In Stress Spike scenario, preserve the stressed state
      return;
    }

    final classification =
        await _dataRepo.getLatestClassification(userId: _userId);
    if (classification != null) {
      final wasStressed = _latestClassification?.isStressed ?? false;
      _latestClassification = classification;
      // If transitioned to stressed, reset dismissal so tip is shown
      if (!wasStressed && classification.isStressed) {
        _tipDismissed = false;
      }
      notifyListeners();
    }
  }

  Future<void> _loadShiftInfo() async {
    final session = await _dataRepo.getActiveShiftSession(userId: _userId);
    _shiftStartTime = session?.startedAt;
    notifyListeners();
  }

  /// Fetch active alerts from backend (FR-6.2, FR-9.1).
  Future<void> _loadAlerts() async {
    final alerts = await _dataRepo.getActiveAlerts(userId: _userId);
    _activeAlerts = alerts;
    notifyListeners();
  }

  bool _isDisposed = false;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sensorSub?.cancel();
    _connectionSub?.cancel();
    _classificationPollTimer?.cancel();
    super.dispose();
  }
}
