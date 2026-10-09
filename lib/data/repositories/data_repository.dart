import '../models/alert.dart';
import '../models/check_in.dart';
import '../models/classification.dart';
import '../models/shift_session.dart';
import '../models/spo2_reading.dart';

/// Repository interface for shift data, ML classifications, alerts, and check-ins.
abstract class DataRepository {
  /// Fetch the current active shift session for a worker, if one exists.
  Future<ShiftSession?> getActiveShiftSession({required int userId});

  /// Manually or automatically start a shift session.
  Future<ShiftSession> startShiftSession({
    required int userId,
    String startMethod = 'MANUAL',
  });

  /// End an ongoing shift session.
  Future<ShiftSession> endShiftSession({required int sessionId});

  /// Retrieve the last 24 hours of feature classifications for timeline history.
  Future<List<Classification>> getRecentClassifications({
    required int userId,
    Duration window = const Duration(hours: 24),
  });

  /// Retrieve the most recent classification window.
  Future<Classification?> getLatestClassification({required int userId});

  /// Retrieve all open alerts for the user.
  Future<List<Alert>> getActiveAlerts({required int userId});

  /// Acknowledge an alert.
  Future<void> acknowledgeAlert({required int alertId});

  /// Submit a worker self-report check-in.
  Future<void> submitCheckIn(CheckIn checkIn);

  /// Fetch recent SpO2 readings for the session.
  Future<List<Spo2Reading>> getRecentSpo2Readings({required int sessionId});
}
