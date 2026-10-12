import 'dart:async';
import 'dart:math';
import '../models/sensor_packet.dart';
import 'wearable_source.dart';

/// Available scripted scenarios for MockWearableSource.
enum MockScenario {
  calm,
  stressSpike,
  lowSpo2,
  disconnected,
}

/// Mock implementation of WearableSource emitting realistic physiological data
/// and scripted scenarios (calm, stress spikes, low SpO2, disconnect/reconnect).
class MockWearableSource implements WearableSource {
  final StreamController<SensorPacket> _sensorController =
      StreamController<SensorPacket>.broadcast();
  final StreamController<WearableConnectionState> _connectionController =
      StreamController<WearableConnectionState>.broadcast();

  WearableConnectionState _currentState = WearableConnectionState.disconnected;
  MockScenario _currentScenario = MockScenario.calm;
  Timer? _ticker;
  final Random _random = Random();

  MockWearableSource({bool autoConnect = false}) {
    if (autoConnect) {
      connect();
    }
  }

  @override
  Stream<SensorPacket> get sensorStream => _sensorController.stream;

  @override
  Stream<WearableConnectionState> get connectionStateStream =>
      _connectionController.stream;

  @override
  WearableConnectionState get currentState => _currentState;

  MockScenario get currentScenario => _currentScenario;

  bool _shouldFailConnect = false;
  String? _connectFailureReason;
  Timer? _reconnectTimer;
  Timer? _reconnectCompleteTimer;

  @override
  Future<void> connect({String? deviceId}) async {
    if (_currentState == WearableConnectionState.connected) return;

    _updateState(WearableConnectionState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (_shouldFailConnect) {
      _shouldFailConnect = false;
      final reason = _connectFailureReason ?? 'Band not found';
      _connectFailureReason = null;
      _updateState(WearableConnectionState.disconnected);
      throw Exception(reason);
    }

    _updateState(WearableConnectionState.connected);
    _startTicker();
  }

  @override
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectCompleteTimer?.cancel();
    _ticker?.cancel();
    _ticker = null;
    _updateState(WearableConnectionState.disconnected);
  }

  /// Configure the next connection attempt to simulate a failure (FR-3.9).
  void setNextConnectFailure({String? reason}) {
    _shouldFailConnect = true;
    _connectFailureReason = reason;
  }

  /// Manually switch scenario for testing or UI demonstrations.
  void setScenario(MockScenario scenario) {
    _currentScenario = scenario;
    if (scenario == MockScenario.disconnected) {
      simulateDisconnectAndReconnect();
    }
  }

  /// Convenience triggers
  void triggerCalmScenario() => setScenario(MockScenario.calm);
  void triggerStressSpikeScenario() => setScenario(MockScenario.stressSpike);
  void triggerLowSpo2Scenario() => setScenario(MockScenario.lowSpo2);

  /// Simulate temporary disconnection with auto-reconnect cycle:
  /// disconnect -> reconnecting -> connected (BLE Spec §4.2 / NFR-2.1 / T-05)
  void simulateDisconnectAndReconnect({
    Duration disconnectDuration = const Duration(seconds: 1),
    Duration reconnectDuration = const Duration(seconds: 4),
  }) {
    _ticker?.cancel();
    _ticker = null;
    _updateState(WearableConnectionState.disconnected);

    _reconnectTimer?.cancel();
    _reconnectCompleteTimer?.cancel();

    _reconnectTimer = Timer(disconnectDuration, () {
      if (_currentState == WearableConnectionState.disconnected) {
        _updateState(WearableConnectionState.reconnecting);

        _reconnectCompleteTimer = Timer(reconnectDuration, () {
          if (_currentState == WearableConnectionState.reconnecting) {
            _updateState(WearableConnectionState.connected);
            _currentScenario = MockScenario.calm;
            _startTicker();
          }
        });
      }
    });
  }

  void _updateState(WearableConnectionState state) {
    _currentState = state;
    if (!_connectionController.isClosed) {
      _connectionController.add(state);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    // Emits a new sensor packet every 1 second
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentState != WearableConnectionState.connected) return;

      final packet = _generatePacket();
      if (!_sensorController.isClosed) {
        _sensorController.add(packet);
      }
    });
  }

  SensorPacket _generatePacket() {
    final now = DateTime.now();

    double hr;
    double spo2;
    double temp;
    double accelX;
    double accelY;
    double accelZ;

    switch (_currentScenario) {
      case MockScenario.stressSpike:
        // Stress spike: HR > 100 bpm, slight temperature rise, higher movement
        hr = 104.0 + (_random.nextDouble() * 8.0); // 104 - 112 bpm
        spo2 = 96.5 + (_random.nextDouble() * 2.0); // 96.5 - 98.5 %
        temp = 36.8 + (_random.nextDouble() * 0.4);
        accelX = 0.2 + (_random.nextDouble() * 0.4);
        accelY = 0.8 + (_random.nextDouble() * 0.4);
        accelZ = 0.1 + (_random.nextDouble() * 0.3);
        break;

      case MockScenario.lowSpo2:
        // Low SpO2: SpO2 < 95% (e.g. 91% - 93.5%)
        hr = 78.0 + (_random.nextDouble() * 6.0);
        spo2 = 91.0 + (_random.nextDouble() * 2.5); // 91.0 - 93.5 %
        temp = 36.5 + (_random.nextDouble() * 0.2);
        accelX = 0.05;
        accelY = 0.95;
        accelZ = 0.02;
        break;

      case MockScenario.disconnected:
      case MockScenario.calm:
        // Normal calm baseline: HR 68-76 bpm, SpO2 97-99%
        hr = 70.0 + (_random.nextDouble() * 6.0); // 70 - 76 bpm
        spo2 = 97.5 + (_random.nextDouble() * 1.5); // 97.5 - 99.0 %
        temp = 36.4 + (_random.nextDouble() * 0.3);
        accelX = 0.02 + (_random.nextDouble() * 0.05);
        accelY = 0.98 + (_random.nextDouble() * 0.04);
        accelZ = 0.01 + (_random.nextDouble() * 0.05);
        break;
    }

    // Generate simulated raw PPG sample buffer (20 dummy bytes for transmission)
    final ppgBytes = List<int>.generate(20, (i) => (_random.nextInt(256)));

    return SensorPacket(
      timestamp: now,
      ppgRaw: ppgBytes,
      accelX: accelX,
      accelY: accelY,
      accelZ: accelZ,
      temperature: temp,
      spo2: double.parse(spo2.toStringAsFixed(1)),
      localHeartRate: double.parse(hr.toStringAsFixed(0)),
    );
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _reconnectCompleteTimer?.cancel();
    _ticker?.cancel();
    _sensorController.close();
    _connectionController.close();
  }
}
