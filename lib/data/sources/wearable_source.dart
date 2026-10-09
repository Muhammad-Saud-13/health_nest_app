import '../models/sensor_packet.dart';

/// Connection states matching BLE Specification §4.1 / FR-3.6.
enum WearableConnectionState {
  disconnected,
  connecting,
  reconnecting,
  connected,
}

/// Abstract interface for wristband data source (BLE / Mock).
abstract class WearableSource {
  /// Stream of incoming sensor packets.
  Stream<SensorPacket> get sensorStream;

  /// Stream of connection state updates.
  Stream<WearableConnectionState> get connectionStateStream;

  /// Current connection state.
  WearableConnectionState get currentState;

  /// Connect to the wristband.
  Future<void> connect({String? deviceId});

  /// Disconnect from the wristband.
  Future<void> disconnect();

  /// Clean up streams and resources.
  void dispose();
}
