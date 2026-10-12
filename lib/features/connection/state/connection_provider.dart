import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/sources/mock_wearable_source.dart';
import '../../../data/sources/wearable_source.dart';

/// Provider managing wristband connection state, device information,
/// and connection failure notifications (FR-3.6, FR-3.7, FR-3.9, NFR-2.1).
class ConnectionProvider extends ChangeNotifier {
  ConnectionProvider({
    required WearableSource wearableSource,
    String deviceName = 'HealthNest Band A12',
    String deviceId = 'HN-A12-8841',
  })  : _wearableSource = wearableSource,
        _deviceName = deviceName,
        _deviceId = deviceId {
    _init();
  }

  final WearableSource _wearableSource;
  StreamSubscription<WearableConnectionState>? _stateSub;

  final String _deviceName;
  final String _deviceId;
  final int _batteryLevel = 88;

  String? _failureMessage;
  bool _isAutoReconnecting = false;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  WearableConnectionState get connectionState => _wearableSource.currentState;
  String get deviceName => _deviceName;
  String get deviceId => _deviceId;
  int get batteryLevel => _batteryLevel;
  String? get failureMessage => _failureMessage;
  bool get hasFailure => _failureMessage != null && _failureMessage!.isNotEmpty;
  bool get isAutoReconnecting => _isAutoReconnecting;

  bool get isConnected =>
      connectionState == WearableConnectionState.connected;
  bool get isReconnecting =>
      connectionState == WearableConnectionState.reconnecting;
  bool get isDisconnected =>
      connectionState == WearableConnectionState.disconnected;
  bool get isConnecting =>
      connectionState == WearableConnectionState.connecting;

  /// Human-friendly state title for plain language UI (NFR-4.1).
  String get stateTitle {
    switch (connectionState) {
      case WearableConnectionState.connected:
        return 'Connected to $_deviceName';
      case WearableConnectionState.reconnecting:
        return 'Reconnecting to $_deviceName...';
      case WearableConnectionState.connecting:
        return 'Connecting to $_deviceName...';
      case WearableConnectionState.disconnected:
        return '$_deviceName Disconnected';
    }
  }

  /// Status badge label (Connected / Reconnecting / Disconnected).
  String get badgeLabel {
    switch (connectionState) {
      case WearableConnectionState.connected:
        return 'Connected';
      case WearableConnectionState.reconnecting:
        return 'Reconnecting...';
      case WearableConnectionState.connecting:
        return 'Connecting...';
      case WearableConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Connect to the wristband (FR-3.3, FR-3.9).
  Future<void> connect() async {
    _failureMessage = null;
    notifyListeners();

    try {
      await _wearableSource.connect(deviceId: _deviceId);
    } catch (e) {
      _failureMessage =
          'Unable to connect to wristband. Make sure your band is powered on and in range.';
      notifyListeners();
    }
  }

  /// Disconnect from the wristband.
  Future<void> disconnect() async {
    _failureMessage = null;
    _isAutoReconnecting = false;
    await _wearableSource.disconnect();
    notifyListeners();
  }

  /// Retry connection attempt after failure or disconnection.
  Future<void> retryConnection() async {
    await connect();
  }

  /// Dismiss or clear the active error/failure message.
  void clearFailure() {
    _failureMessage = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Scenario Simulations (Testing & Acceptance Criteria)
  // ---------------------------------------------------------------------------

  /// Simulate full auto-reconnect cycle:
  /// Disconnected -> reconnecting -> connected.
  void simulateAutoReconnect({
    Duration disconnectDuration = const Duration(seconds: 1),
    Duration reconnectDuration = const Duration(seconds: 4),
  }) {
    _failureMessage = null;
    _isAutoReconnecting = true;
    final source = _wearableSource;
    if (source is MockWearableSource) {
      source.simulateDisconnectAndReconnect(
        disconnectDuration: disconnectDuration,
        reconnectDuration: reconnectDuration,
      );
    }
    notifyListeners();
  }

  /// Simulate failure message when wearable is not found (FR-3.9).
  Future<void> simulateDeviceNotFound() async {
    await _wearableSource.disconnect();
    _failureMessage =
        'HealthNest Band not found. Make sure your wristband is charged, turned on, and nearby.';
    notifyListeners();
  }

  /// Simulate connection failure (FR-3.9).
  Future<void> simulateConnectionFailure() async {
    final source = _wearableSource;
    if (source is MockWearableSource) {
      source.setNextConnectFailure(
        reason: 'Connection handshake failed with BLE peripheral.',
      );
    }
    await connect();
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void _init() {
    _stateSub = _wearableSource.connectionStateStream.listen((state) {
      if (state == WearableConnectionState.connected) {
        _failureMessage = null;
        _isAutoReconnecting = false;
      } else if (state == WearableConnectionState.reconnecting) {
        _isAutoReconnecting = true;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    super.dispose();
  }
}
