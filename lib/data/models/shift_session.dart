class ShiftSession {
  final int id;
  final int userId;
  final int? shiftTypeId;
  final int? departmentId;
  final String shiftDate; // YYYY-MM-DD
  final DateTime startedAt;
  final DateTime? endedAt;
  final String status; // ACTIVE, CLOSED, AUTO_CLOSED
  final String startMethod; // MANUAL, AUTO
  final double? baselineTemp;
  final String baselineStatus; // PENDING, DONE, FALLBACK
  final int baselineWindowCount;

  const ShiftSession({
    required this.id,
    required this.userId,
    this.shiftTypeId,
    this.departmentId,
    required this.shiftDate,
    required this.startedAt,
    this.endedAt,
    this.status = 'ACTIVE',
    this.startMethod = 'MANUAL',
    this.baselineTemp,
    this.baselineStatus = 'PENDING',
    this.baselineWindowCount = 0,
  });

  bool get isActive => status == 'ACTIVE';

  factory ShiftSession.fromJson(Map<String, dynamic> json) {
    return ShiftSession(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      shiftTypeId: json['shift_type_id'] as int?,
      departmentId: json['department_id'] as int?,
      shiftDate: json['shift_date'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String) : null,
      status: json['status'] as String? ?? 'ACTIVE',
      startMethod: json['start_method'] as String? ?? 'MANUAL',
      baselineTemp: (json['baseline_temp'] as num?)?.toDouble(),
      baselineStatus: json['baseline_status'] as String? ?? 'PENDING',
      baselineWindowCount: json['baseline_window_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'shift_type_id': shiftTypeId,
      'department_id': departmentId,
      'shift_date': shiftDate,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'status': status,
      'start_method': startMethod,
      'baseline_temp': baselineTemp,
      'baseline_status': baselineStatus,
      'baseline_window_count': baselineWindowCount,
    };
  }

  ShiftSession copyWith({
    int? id,
    int? userId,
    int? shiftTypeId,
    int? departmentId,
    String? shiftDate,
    DateTime? startedAt,
    DateTime? endedAt,
    String? status,
    String? startMethod,
    double? baselineTemp,
    String? baselineStatus,
    int? baselineWindowCount,
  }) {
    return ShiftSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      shiftTypeId: shiftTypeId ?? this.shiftTypeId,
      departmentId: departmentId ?? this.departmentId,
      shiftDate: shiftDate ?? this.shiftDate,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      startMethod: startMethod ?? this.startMethod,
      baselineTemp: baselineTemp ?? this.baselineTemp,
      baselineStatus: baselineStatus ?? this.baselineStatus,
      baselineWindowCount: baselineWindowCount ?? this.baselineWindowCount,
    );
  }
}
