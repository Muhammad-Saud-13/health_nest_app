/// Custom exception classes for HealthNest app errors.
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException: $message ${code != null ? "($code)" : ""}';
}

class AuthException extends AppException {
  const AuthException(super.message, [super.code]);
}

class BleException extends AppException {
  const BleException(super.message, [super.code]);
}

class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);
}

class LocalStoreException extends AppException {
  const LocalStoreException(super.message, [super.code]);
}
