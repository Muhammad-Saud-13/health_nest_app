class CheckIn {
  final int? id;
  final int sessionId;
  final int userId;
  final String kind; // SHIFT_START, ON_DEMAND
  final int feeling; // 1: Fine, 2: Tired, 3: Unwell
  final int pain; // 1: No, 2: Mild, 3: Severe
  final int stressSelf; // 1: Low, 2: Medium, 3: High
  final DateTime submittedAt;

  const CheckIn({
    this.id,
    required this.sessionId,
    required this.userId,
    this.kind = 'SHIFT_START',
    required this.feeling,
    required this.pain,
    required this.stressSelf,
    required this.submittedAt,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: json['id'] as int?,
      sessionId: json['session_id'] as int,
      userId: json['user_id'] as int,
      kind: json['kind'] as String? ?? 'SHIFT_START',
      feeling: json['feeling'] as int,
      pain: json['pain'] as int,
      stressSelf: json['stress_self'] as int,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'kind': kind,
      'feeling': feeling,
      'pain': pain,
      'stress_self': stressSelf,
      'submitted_at': submittedAt.toIso8601String(),
    };
  }
}
