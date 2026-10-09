import '../models/user.dart';
import 'auth_repository.dart';

/// Mock implementation of AuthRepository with hardcoded test users.
class MockAuthRepository implements AuthRepository {
  User? _currentUser;

  // Pre-configured test accounts
  static const User defaultWorker = User(
    id: 1,
    employeeCode: 'EMP-1042',
    name: 'Saud Rehman',
    email: 'worker@healthnest.com',
    role: 'EMPLOYEE',
    departmentId: 101,
    plantId: 1,
    designation: 'Assembly Specialist',
    isActive: true,
  );

  static const User supervisorUser = User(
    id: 2,
    employeeCode: 'EMP-0012',
    name: 'Jane Doe',
    email: 'supervisor@healthnest.com',
    role: 'HR',
    departmentId: 101,
    plantId: 1,
    designation: 'Shift Safety Lead',
    isActive: true,
  );

  @override
  Future<User?> login({required String email, required String password}) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final normalizedEmail = email.trim().toLowerCase();

    // Check pre-configured users or standard password
    if (normalizedEmail == defaultWorker.email && password == 'password123') {
      _currentUser = defaultWorker;
      return _currentUser;
    } else if (normalizedEmail == supervisorUser.email && password == 'password123') {
      _currentUser = supervisorUser;
      return _currentUser;
    } else if (normalizedEmail.contains('@') && password == 'password123') {
      // Allow dynamic worker emails with default test password
      _currentUser = User(
        id: 99,
        employeeCode: 'EMP-9901',
        name: email.split('@').first.toUpperCase(),
        email: normalizedEmail,
        role: 'EMPLOYEE',
        departmentId: 101,
        plantId: 1,
        designation: 'Plant Operator',
        isActive: true,
      );
      return _currentUser;
    }

    return null; // Invalid credentials
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<bool> forgotPassword({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return email.contains('@') && email.contains('.');
  }

  @override
  Future<bool> isAuthenticated() async {
    return _currentUser != null;
  }
}
