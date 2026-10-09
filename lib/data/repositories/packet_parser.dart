import '../models/sensor_packet.dart';

/// Abstract interface for raw byte packet parser (BLE Spec Rule 10).
abstract class PacketParser {
  /// Parse a raw byte stream from the BLE notification into a structured SensorPacket.
  SensorPacket parse(List<int> rawBytes);
}

/// Default implementation parsing multi-byte sensor values using bitwise operations.
/// Note: Packet layout will be calibrated when final ESP32 byte specification is confirmed.
class DefaultPacketParser implements PacketParser {
  @override
  SensorPacket parse(List<int> rawBytes) {
    if (rawBytes.length < 8) {
      throw FormatException(
        'Packet too short: expected at least 8 bytes, got ${rawBytes.length}',
      );
    }

    final now = DateTime.now();

    // Example Bitwise parsing pattern (BLE Spec Rule 10):
    // Bytes 0-1: Accel X (16-bit signed integer, scaled by 1/1000)
    final rawAccelX = _toInt16(rawBytes[0], rawBytes[1]);
    final accelX = rawAccelX / 1000.0;

    // Bytes 2-3: Accel Y
    final rawAccelY = _toInt16(rawBytes[2], rawBytes[3]);
    final accelY = rawAccelY / 1000.0;

    // Bytes 4-5: Accel Z
    final rawAccelZ = _toInt16(rawBytes[4], rawBytes[5]);
    final accelZ = rawAccelZ / 1000.0;

    // Byte 6: SpO2 percentage (0-100)
    final spo2 = (rawBytes[6] & 0xFF).toDouble();

    // Byte 7: Temperature integer or base (e.g. 36 + offset/10)
    final tempBase = (rawBytes[7] & 0xFF);
    final temperature = 30.0 + (tempBase / 10.0);

    // Remaining bytes: Raw PPG sample buffer
    final ppgRaw = rawBytes.length > 8 ? rawBytes.sublist(8) : <int>[];

    return SensorPacket(
      timestamp: now,
      ppgRaw: ppgRaw,
      accelX: accelX,
      accelY: accelY,
      accelZ: accelZ,
      temperature: temperature,
      spo2: spo2 > 0 ? spo2 : 98.0,
      localHeartRate: null,
    );
  }

  /// Combine two bytes into a signed 16-bit integer using bitwise operations
  int _toInt16(int byteLow, int byteHigh) {
    final combined = ((byteHigh & 0xFF) << 8) | (byteLow & 0xFF);
    // Convert to signed 16-bit
    return (combined & 0x8000) != 0 ? combined - 0x10000 : combined;
  }
}
