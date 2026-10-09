class Alert {
  final int id;
  final int sessionId;
  final int userId;
  final String type; // STRESS_SUSTAINED, SPO2_LOW, DIVERGENCE
  final DateTime createdAt;
  final String status; // OPEN, ACK, DISMISSED
  final int? handledBy;

  const Alert({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.type,
    required this.createdAt,
    this.status = 'OPEN',
    this.handledBy,
  });

  bool get isOpen => status == 'OPEN';
  bool get isAcknowledged => status == 'ACK';
  bool get isDismissed => status == 'DISMISSED';

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      userId: json['user_id'] as int,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String? ?? 'OPEN',
      handledBy: json['handled_by'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'handled_by': handledBy,
    };
  }

  Alert copyWith({
    int? id,
    int? sessionId,
    int? userId,
    String? type,
    DateTime? createdAt,
    String? status,
    int? handledBy,
  }) {
    return Alert(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      handledBy: handledBy ?? this.handledBy,
    );
  }
}
