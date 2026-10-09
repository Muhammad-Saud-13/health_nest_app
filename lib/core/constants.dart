/// System-wide constants (BLE UUIDs, Storage Keys, Route Names)
class AppConstants {
  // BLE UUID Placeholders (TBD from vendor)
  static const String serviceUuid = '0000180d-0000-1000-8000-00805f9b34fb';
  static const String sensorCharUuid = '00002a37-0000-1000-8000-00805f9b34fb';

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
}
