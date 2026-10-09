class Spo2Reading {
  final int id;
  final int sessionId;
  final double value;
  final DateTime recordedAt;

  const Spo2Reading({
    required this.id,
    required this.sessionId,
    required this.value,
    required this.recordedAt,
  });

  bool get isLow => value < 95.0;

  factory Spo2Reading.fromJson(Map<String, dynamic> json) {
    return Spo2Reading(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      value: (json['value'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'value': value,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }
}
