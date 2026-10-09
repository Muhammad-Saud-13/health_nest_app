class SensorPacket {
  final DateTime timestamp;
  final List<int> ppgRaw;
  final double accelX;
  final double accelY;
  final double accelZ;
  final double temperature;
  final double spo2;
  final double? localHeartRate;

  const SensorPacket({
    required this.timestamp,
    required this.ppgRaw,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.temperature,
    required this.spo2,
    this.localHeartRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'ppg_raw': ppgRaw,
      'accel_x': accelX,
      'accel_y': accelY,
      'accel_z': accelZ,
      'temperature': temperature,
      'spo2': spo2,
      'local_heart_rate': localHeartRate,
    };
  }

  factory SensorPacket.fromJson(Map<String, dynamic> json) {
    return SensorPacket(
      timestamp: DateTime.parse(json['timestamp'] as String),
      ppgRaw: (json['ppg_raw'] as List<dynamic>?)?.map((e) => e as int).toList() ?? <int>[],
      accelX: (json['accel_x'] as num).toDouble(),
      accelY: (json['accel_y'] as num).toDouble(),
      accelZ: (json['accel_z'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      spo2: (json['spo2'] as num).toDouble(),
      localHeartRate: (json['local_heart_rate'] as num?)?.toDouble(),
    );
  }

  SensorPacket copyWith({
    DateTime? timestamp,
    List<int>? ppgRaw,
    double? accelX,
    double? accelY,
    double? accelZ,
    double? temperature,
    double? spo2,
    double? localHeartRate,
  }) {
    return SensorPacket(
      timestamp: timestamp ?? this.timestamp,
      ppgRaw: ppgRaw ?? this.ppgRaw,
      accelX: accelX ?? this.accelX,
      accelY: accelY ?? this.accelY,
      accelZ: accelZ ?? this.accelZ,
      temperature: temperature ?? this.temperature,
      spo2: spo2 ?? this.spo2,
      localHeartRate: localHeartRate ?? this.localHeartRate,
    );
  }
}
