// ignore_for_file: unused_import, unnecessary_overrides

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isInitialized = false;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;
  bool get isLoggedIn => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? false;
  bool get isInitialized => _isInitialized;
  String? get currentUserId => _user?.uid;

  AuthProvider() {
    initializeAuth();
  }

  // Initialize auth state listener
  Future<void> initializeAuth() async {
    try {
      _authService.user.listen((UserModel? user) {
        _user = user;
        _isInitialized = true;
        notifyListeners();
      });
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Sign in anonymously
  Future<bool> signInAnonymously() async {
    try {
      _setLoading(true);
      clearError();
      
      UserModel? user = await _authService.signInAnonymously();
      _user = user;
      
      _setLoading(false);
      return user != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Register with email and password
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _setLoading(true);
      clearError();

      // Validate inputs
      if (!_validateEmail(email)) {
        throw Exception('Please enter a valid email address');
      }
      if (!_validatePassword(password)) {
        throw Exception('Password must be at least 6 characters long');
      }
      if (displayName.trim().isEmpty) {
        throw Exception('Please enter your name');
      }

      UserModel? user = await _authService.registerWithEmailPassword(
        email, 
        password, 
        displayName.trim()
      );
      _user = user;

      _setLoading(false);
      return user != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      clearError();

      // Validate inputs
      if (!_validateEmail(email)) {
        throw Exception('Please enter a valid email address');
      }
      if (password.trim().isEmpty) {
        throw Exception('Please enter your password');
      }

      UserModel? user = await _authService.signInWithEmailPassword(email, password);
      _user = user;

      _setLoading(false);
      return user != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Convert anonymous account to permanent account
  Future<bool> linkAnonymousAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _setLoading(true);
      clearError();

      if (!isAnonymous) {
        throw Exception('Current user is not anonymous');
      }

      // Validate inputs
      if (!_validateEmail(email)) {
        throw Exception('Please enter a valid email address');
      }
      if (!_validatePassword(password)) {
        throw Exception('Password must be at least 6 characters long');
      }
      if (displayName.trim().isEmpty) {
        throw Exception('Please enter your name');
      }

      UserModel? user = await _authService.linkAnonymousWithEmail(
        email, 
        password, 
        displayName.trim()
      );
      _user = user;

      _setLoading(false);
      return user != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      clearError();

      if (!_validateEmail(email)) {
        throw Exception('Please enter a valid email address');
      }

      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? email,
  }) async {
    try {
      _setLoading(true);
      clearError();

      // Validate email if provided
      if (email != null && !_validateEmail(email)) {
        throw Exception('Please enter a valid email address');
      }

      // Validate display name if provided
      if (displayName != null && displayName.trim().isEmpty) {
        throw Exception('Name cannot be empty');
      }

      UserModel? user = await _authService.updateProfile(
        displayName: displayName?.trim(),
        email: email,
      );
      _user = user;

      _setLoading(false);
      return user != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _setLoading(true);
      clearError();

      if (isAnonymous) {
        throw Exception('Anonymous users cannot change password');
      }

      if (currentPassword.isEmpty) {
        throw Exception('Please enter your current password');
      }

      if (!_validatePassword(newPassword)) {
        throw Exception('New password must be at least 6 characters long');
      }

      if (currentPassword == newPassword) {
        throw Exception('New password must be different from current password');
      }

      await _authService.changePassword(currentPassword, newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount({String? password}) async {
    try {
      _setLoading(true);
      clearError();

      // Require password for non-anonymous users
      if (!isAnonymous && (password == null || password.isEmpty)) {
        throw Exception('Please enter your password to delete account');
      }

      await _authService.deleteAccount(password);
      _user = null;
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<bool> signOut() async {
    try {
      _setLoading(true);
      clearError();

      await _authService.signOut();
      _user = null;

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Get user statistics
  Future<Map<String, int>> getUserStats() async {
    try {
      return await _authService.getUserStats();
    } catch (e) {
      return {'taskCount': 0, 'completedTaskCount': 0};
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    try {
      if (_authService.currentUser != null) {
        await _authService.currentUser!.reload();
        // The auth state listener will automatically update _user
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error refreshing user: $e');
    }
  }

  // Validate email format
  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email.trim());
  }

  // Validate password strength
  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  // Check if password meets strong requirements
  bool isStrongPassword(String password) {
    // At least 8 characters, contains uppercase, lowercase, number, and special character
    final strongPasswordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return strongPasswordRegex.hasMatch(password);
  }

  // Get password strength score (0-4)
  int getPasswordStrength(String password) {
    int score = 0;
    
    if (password.length >= 8) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[@$!%*?&]').hasMatch(password)) score++;
    
    return score;
  }

  // Get password strength description
  String getPasswordStrengthText(String password) {
    int strength = getPasswordStrength(password);
    switch (strength) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      case 5:
        return 'Very Strong';
      default:
        return 'Unknown';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}