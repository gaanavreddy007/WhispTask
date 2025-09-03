// Test-specific authentication service for integration tests
// ignore_for_file: avoid_relative_lib_imports

import '../lib/models/user_model.dart';

class TestAuthService {
  static UserModel? _testUser;
  
  static UserModel createTestUser() {
    _testUser = UserModel(
      uid: 'test_user_123',
      email: 'test@integration.com',
      displayName: 'Test User',
      isAnonymous: true,
      createdAt: DateTime.now(),
      lastSignIn: DateTime.now(),
      preferences: const UserPreferences(),
    );
    return _testUser!;
  }
  
  static UserModel? getCurrentUser() {
    return _testUser;
  }
  
  static void clearUser() {
    _testUser = null;
  }
  
  static bool isLoggedIn() {
    return _testUser != null;
  }
}
