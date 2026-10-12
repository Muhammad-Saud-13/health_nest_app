/// System-wide constants (BLE UUIDs, Storage Keys, Route Names)
class AppConstants {
  // BLE UUID Placeholders (TBD from vendor)
  static const String serviceUuid = 'TBD-SERVICE-UUID';
  static const String sensorCharUuid = 'TBD-SENSOR-CHAR-UUID';

  // Secure Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';

  // Named Routes
  static const String routeLogin = '/login';
  static const String routeHome = '/home';
  static const String routeCheckIn = '/checkin';
  static const String routeHistory = '/history';
  static const String routeSettings = '/settings';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeBand = '/band';
}
