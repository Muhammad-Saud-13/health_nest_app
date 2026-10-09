class Classification {
  final int id;
  final int sessionId;
  final int userId;
  final DateTime windowStart;
  final DateTime windowEnd;
  final double hrMean;
  final double rmssd;
  final double sma;
  final double tempMean;
  final double tempDelta;
  final String label; // CALM or STRESSED
  final double stressProb;
  final bool isCalibrating;

  const Classification({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.windowStart,
    required this.windowEnd,
    required this.hrMean,
    required this.rmssd,
    required this.sma,
    required this.tempMean,
    required this.tempDelta,
    required this.label,
    required this.stressProb,
    this.isCalibrating = false,
  });

  bool get isStressed => label.toUpperCase() == 'STRESSED';
  bool get isCalm => label.toUpperCase() == 'CALM';

  factory Classification.fromJson(Map<String, dynamic> json) {
    return Classification(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      userId: json['user_id'] as int,
      windowStart: DateTime.parse(json['window_start'] as String),
      windowEnd: DateTime.parse(json['window_end'] as String),
      hrMean: (json['hr_mean'] as num).toDouble(),
      rmssd: (json['rmssd'] as num).toDouble(),
      sma: (json['sma'] as num).toDouble(),
      tempMean: (json['temp_mean'] as num).toDouble(),
      tempDelta: (json['temp_delta'] as num).toDouble(),
      label: json['label'] as String,
      stressProb: (json['stress_prob'] as num).toDouble(),
      isCalibrating: json['is_calibrating'] == 1 || json['is_calibrating'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'window_start': windowStart.toIso8601String(),
      'window_end': windowEnd.toIso8601String(),
      'hr_mean': hrMean,
      'rmssd': rmssd,
      'sma': sma,
      'temp_mean': tempMean,
      'temp_delta': tempDelta,
      'label': label,
      'stress_prob': stressProb,
      'is_calibrating': isCalibrating ? 1 : 0,
    };
  }
}
