import '../models/user.dart';

/// Authentication repository interface for login, logout, and credential validation.
abstract class AuthRepository {
  /// Authenticate worker with email and password.
  Future<User?> login({required String email, required String password});

  /// Log out current worker and clear session tokens.
  Future<void> logout();

  /// Retrieve currently logged-in user profile if session is active.
  Future<User?> getCurrentUser();

  /// Request password reset link or instructions.
  Future<bool> forgotPassword({required String email});

  /// Check whether an active authenticated session exists.
  Future<bool> isAuthenticated();
}
