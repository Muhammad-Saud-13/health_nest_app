import 'dart:async';

/// Network connectivity states for the offline queue system.
enum ConnectivityStatus {
  /// Device has network connectivity.
  online,

  /// Device has no network connectivity.
  offline,
}

/// Abstract interface for detecting network connectivity changes (NFR-2.2).
abstract class ConnectivityService {
  /// Stream of connectivity status changes.
  Stream<ConnectivityStatus> get statusStream;

  /// Current connectivity status.
  ConnectivityStatus get currentStatus;

  /// Check connectivity once (one-shot check).
  Future<ConnectivityStatus> checkConnectivity();

  /// Clean up resources.
  void dispose();
}

/// Mock implementation of [ConnectivityService] for testing offline queue
/// behaviour without requiring real network hardware.
///
/// Starts online, and can be toggled programmatically for demo/test scenarios.
class MockConnectivityService implements ConnectivityService {
  MockConnectivityService({
    ConnectivityStatus initialStatus = ConnectivityStatus.online,
  }) : _currentStatus = initialStatus {
    _controller = StreamController<ConnectivityStatus>.broadcast();
  }

  late final StreamController<ConnectivityStatus> _controller;
  ConnectivityStatus _currentStatus;

  @override
  Stream<ConnectivityStatus> get statusStream => _controller.stream;

  @override
  ConnectivityStatus get currentStatus => _currentStatus;

  @override
  Future<ConnectivityStatus> checkConnectivity() async {
    return _currentStatus;
  }

  /// Simulate going offline.
  void goOffline() {
    if (_currentStatus != ConnectivityStatus.offline) {
      _currentStatus = ConnectivityStatus.offline;
      _controller.add(_currentStatus);
    }
  }

  /// Simulate coming back online.
  void goOnline() {
    if (_currentStatus != ConnectivityStatus.online) {
      _currentStatus = ConnectivityStatus.online;
      _controller.add(_currentStatus);
    }
  }

  /// Simulate a disconnect → reconnect cycle after [offlineDuration].
  Future<void> simulateNetworkBlip({
    Duration offlineDuration = const Duration(seconds: 10),
  }) async {
    goOffline();
    await Future<void>.delayed(offlineDuration);
    goOnline();
  }

  @override
  void dispose() {
    _controller.close();
  }
}
