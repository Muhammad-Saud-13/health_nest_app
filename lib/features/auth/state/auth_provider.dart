import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/auth_repository.dart';

/// Authentication states for the auth flow.
enum AuthStatus {
  /// Initial state — checking for existing session.
  unknown,

  /// User is authenticated.
  authenticated,

  /// User is not authenticated.
  unauthenticated,
}

/// Manages authentication session state.
///
/// Wraps [AuthRepository] and persists JWT token via [FlutterSecureStorage].
/// Exposes login / logout / forgot-password and session-check actions.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthRepository authRepository,
    FlutterSecureStorage? secureStorage,
  })  : _authRepo = authRepository,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final AuthRepository _authRepo;
  final FlutterSecureStorage _secureStorage;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// True after a successful forgot-password request.
  bool _forgotPasswordSent = false;
  bool get forgotPasswordSent => _forgotPasswordSent;

  // ---------------------------------------------------------------------------
  // Bootstrap — call once at app start to restore session
  // ---------------------------------------------------------------------------

  /// Check for a persisted token and restore the session if valid.
  Future<void> tryRestoreSession() async {
    _setLoading(true);

    final storedToken = await _secureStorage.read(key: AppConstants.authTokenKey);

    if (storedToken != null) {
      final user = await _authRepo.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
      } else {
        // Token exists but user is null — stale token; clear it.
        await _secureStorage.delete(key: AppConstants.authTokenKey);
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }

    _setLoading(false);
  }

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  /// Authenticate with [email] and [password].
  ///
  /// On success: stores a mock JWT, updates [status] to authenticated.
  /// On failure: sets [errorMessage].
  Future<bool> login({required String email, required String password}) async {
    _clearError();
    _setLoading(true);

    // Basic client-side validation
    if (email.trim().isEmpty || password.isEmpty) {
      _errorMessage = 'Please enter your email and password.';
      _setLoading(false);
      return false;
    }

    final user = await _authRepo.login(email: email, password: password);

    if (user != null) {
      _currentUser = user;
      _status = AuthStatus.authenticated;

      // Persist a mock JWT token (real token comes from backend in T-11).
      await _secureStorage.write(
        key: AppConstants.authTokenKey,
        value: 'mock_jwt_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
      );

      _setLoading(false);
      return true;
    }

    _errorMessage = 'Invalid email or password. Please try again.';
    _setLoading(false);
    return false;
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  /// Log out the current user, clear persisted token, reset state.
  Future<void> logout() async {
    _setLoading(true);
    await _authRepo.logout();
    await _secureStorage.delete(key: AppConstants.authTokenKey);
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _setLoading(false);
  }

  // ---------------------------------------------------------------------------
  // Forgot Password
  // ---------------------------------------------------------------------------

  /// Request a password-reset for [email].
  Future<bool> forgotPassword({required String email}) async {
    _clearError();
    _forgotPasswordSent = false;
    _setLoading(true);

    if (email.trim().isEmpty) {
      _errorMessage = 'Please enter your email address.';
      _setLoading(false);
      return false;
    }

    final success = await _authRepo.forgotPassword(email: email);

    if (success) {
      _forgotPasswordSent = true;
      _setLoading(false);
      return true;
    }

    _errorMessage = 'Could not send reset link. Check your email and try again.';
    _setLoading(false);
    return false;
  }

  /// Reset the forgot-password sent flag (e.g. when navigating away).
  void resetForgotPasswordState() {
    _forgotPasswordSent = false;
    _clearError();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
