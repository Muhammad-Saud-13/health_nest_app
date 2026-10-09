/// Date and sensor data formatters.
class Formatters {
  /// Format Heart Rate value with unit.
  static String formatBpm(double? bpm) {
    if (bpm == null) return '-- BPM';
    return '${bpm.round()} BPM';
  }

  /// Format SpO2 percentage value.
  static String formatSpo2(double? spo2) {
    if (spo2 == null) return '--%';
    return '${spo2.toStringAsFixed(1)}%';
  }

  /// Format timestamp to HH:mm readable format.
  static String formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
