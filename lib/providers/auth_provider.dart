// providers/auth_provider.dart - Enhanced with preference sync
// ignore_for_file: unused_import, unnecessary_overrides, avoid_print

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_preferences_service.dart';
import '../services/data_sync_service.dart';
import '../services/revenue_cat_service.dart';
import '../models/sync_status.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserPreferencesService _preferencesService = UserPreferencesService();
  final DataSyncService _dataSyncService = DataSyncService();
  
  UserModel? _user;
  UserPreferences? _userPreferences;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  bool _isSyncing = false;
  bool _isPremium = false;
  
  // Stream subscriptions for proper disposal
  StreamSubscription<UserPreferences>? _preferencesSubscription;

  // Getters
  UserModel? get user => _user;
  UserPreferences? get userPreferences => _userPreferences;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;
  bool get isLoggedIn => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? false;
  bool get isInitialized => _isInitialized;
  bool get isPremium => _isPremium;
  String? get currentUserId => _user?.uid;
  DataSyncService get dataSyncService => _dataSyncService;
  
  // Sync status stream
  Stream<SyncStatus> get syncStatusStream {
    return _dataSyncService.syncStatus.map((statusMap) {
      final isOnline = statusMap['isOnline'] as bool? ?? false;
      final lastSync = statusMap['lastSync'];
      
      if (!isOnline) return SyncStatus.offline;
      if (_isSyncing) return SyncStatus.syncing;
      if (lastSync != null) return SyncStatus.success;
      return SyncStatus.idle;
    });
  }

  AuthProvider() {
    initializeAuth();
  }

  // Initialize auth state listener
  Future<void> initializeAuth() async {
    try {
      // Listen to auth state changes
      _authService.user.listen((UserModel? user) {
        _user = user;
        _isInitialized = true;
        
        // Initialize preferences listener when user changes
        if (user != null) {
          _initializePreferencesListener();
          checkPremiumStatus();
        } else {
          _userPreferences = null;
          _isPremium = false;
        }
        
        notifyListeners();
      });
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'initialize_auth');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to initialize authentication: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Initialize preferences listener
  void _initializePreferencesListener() {
    _preferencesSubscription?.cancel();
    _preferencesSubscription = _preferencesService.preferencesStream.listen((UserPreferences preferences) {
      if (!mounted) return;
      _userPreferences = preferences;
      notifyListeners();
    });
  }
  
  // Check if provider is still mounted
  bool get mounted => !_isDisposed;
  bool _isDisposed = false;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set syncing state
  void _setSyncing(bool syncing) {
    _isSyncing = syncing;
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

  // Premium status management
  Future<void> checkPremiumStatus() async {
    try {
      _isPremium = await RevenueCatService.isPremiumUser();
      notifyListeners();
    } catch (e) {
      print('Failed to check premium status: $e');
      _isPremium = false;
    }
  }

  Future<bool> upgradeToPremium() async {
    try {
      _setLoading(true);
      clearError();
      
      bool success = await RevenueCatService.purchaseMonthlyPremium();
      if (success) {
        await checkPremiumStatus();
      }
      
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Purchase failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> upgradeToYearlyPremium() async {
    try {
      _setLoading(true);
      clearError();
      
      bool success = await RevenueCatService.purchaseYearlyPremium();
      if (success) {
        await checkPremiumStatus();
      }
      
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Purchase failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      _setLoading(true);
      clearError();
      
      await RevenueCatService.restorePurchases();
      await checkPremiumStatus();
      
      _setLoading(false);
    } catch (e) {
      _setError('Restore failed: ${e.toString()}');
      _setLoading(false);
    }
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
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'register');
          scope.setExtra('email', email);
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to register: $e');
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
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'sign_in_with_email_password');
          scope.setExtra('email', email);
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to sign in: $e');
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
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'link_anonymous_account');
          scope.setExtra('email', email);
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to link anonymous account: $e');
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
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'reset_password');
          scope.setExtra('email', email);
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to reset password: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? email,
    String? timezone,
    String? language,
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
        timezone: timezone,
        language: language,
      );
      _user = user;

      _setLoading(false);
      return user != null;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'update_profile');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to update profile: $e');
      _setLoading(false);
      return false;
    }
  }

  // NEW: Update user preferences
  Future<bool> updateUserPreferences(UserPreferences preferences) async {
    try {
      _setSyncing(true);
      clearError();

      await _authService.updateUserPreferences(preferences);
      _userPreferences = preferences;

      _setSyncing(false);
      return true;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'update_user_preferences');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to update preferences: $e');
      _setSyncing(false);
      return false;
    }
  }

  // NEW: Update notification settings
  Future<bool> updateNotificationSettings({
    bool? taskReminders,
    bool? dailyDigest,
    bool? completionCelebrations,
    bool? voiceNotifications,
  }) async {
    try {
      _setSyncing(true);
      clearError();

      await _preferencesService.updateNotificationSettings(
        taskReminders: taskReminders,
        dailyDigest: dailyDigest,
        completionCelebrations: completionCelebrations,
        voiceNotifications: voiceNotifications,
      );

      _setSyncing(false);
      return true;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'update_notification_settings');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to update notification settings: $e');
      _setSyncing(false);
      return false;
    }
  }

  // NEW: Update display settings
  Future<bool> updateDisplaySettings({
    String? theme,
    String? language,
    String? timezone,
    double? fontSize,
  }) async {
    try {
      _setSyncing(true);
      clearError();

      await _preferencesService.updateDisplaySettings(
        theme: theme,
        language: language,
        timezone: timezone,
        fontSize: fontSize,
      );

      // Also update user profile if timezone/language changed
      if (timezone != null || language != null) {
        await updateProfile(timezone: timezone, language: language);
      }

      _setSyncing(false);
      return true;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'update_display_settings');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to update display settings: $e');
      _setSyncing(false);
      return false;
    }
  }

  // NEW: Update voice settings
  Future<bool> updateVoiceSettings({
    bool? voiceInputEnabled,
    bool? autoTranscribe,
    String? preferredVoice,
    double? speechRate,
  }) async {
    try {
      _setSyncing(true);
      clearError();

      await _preferencesService.updateVoiceSettings(
        voiceInputEnabled: voiceInputEnabled,
        autoTranscribe: autoTranscribe,
        preferredVoice: preferredVoice,
        speechRate: speechRate,
      );

      _setSyncing(false);
      return true;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'update_voice_settings');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to update voice settings: $e');
      _setSyncing(false);
      return false;
    }
  }

  // NEW: Update privacy settings
  Future<bool> updatePrivacySettings({
    bool? enableAnalytics,
    bool? shareUsageData,
    bool? biometricAuth,
  }) async {
    try {
      _setSyncing(true);
      clearError();

      await _preferencesService.updatePrivacySettings(
        enableAnalytics: enableAnalytics,
        shareUsageData: shareUsageData,
        biometricAuth: biometricAuth,
      );

      _setSyncing(false);
      return true;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'update_privacy_settings');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to update privacy settings: $e');
      _setSyncing(false);
      return false;
    }
  }

  // NEW: Reset preferences to defaults
  Future<bool> resetPreferencesToDefaults() async {
    try {
      _setSyncing(true);
      clearError();

      await _preferencesService.resetToDefaults();

      _setSyncing(false);
      return true;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'reset_preferences_to_defaults');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to reset preferences: $e');
      _setSyncing(false);
      return false;
    }
  }

  // NEW: Sync preferences across devices
  Future<bool> syncPreferencesAcrossDevices() async {
    try {
      _setSyncing(true);
      clearError();

      await _authService.syncPreferencesAcrossDevices();

      _setSyncing(false);
      return true;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'sync_preferences_across_devices');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to sync preferences: $e');
      _setSyncing(false);
      return false;
    }
  }

  // NEW: Get user analytics
  Future<UserAnalytics?> getUserAnalytics() async {
    try {
      if (_user?.analytics != null) {
        return _user!.analytics;
      }

      // If not available in user model, try to fetch from Firestore
      final userData = await _authService.getCurrentUserData();
      return userData?.analytics;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'get_user_analytics');
          scope.level = SentryLevel.error;
        },
      );
      print('Error getting user analytics: $e');
      return null;
    }
  }

  // NEW: Export user data
  Future<Map<String, dynamic>?> exportUserData() async {
    try {
      _setLoading(true);
      clearError();

      final exportData = await _dataSyncService.exportUserData();

      _setLoading(false);
      return exportData;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'export_user_data');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to export user data: $e');
      _setLoading(false);
      return null;
    }
  }

  // NEW: Import user data
  Future<bool> importUserData(Map<String, dynamic> importData) async {
    try {
      _setLoading(true);
      clearError();

      await _dataSyncService.importUserData(importData);
      
      // Refresh user data after import
      await refreshUser();

      _setLoading(false);
      return true;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'import_user_data');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to import user data: $e');
      _setLoading(false);
      return false;
    }
  }

  // NEW: Clear user cache
  Future<bool> clearUserCache() async {
    try {
      _setLoading(true);
      clearError();

      await _dataSyncService.clearUserCache();
      
      // Refresh user data after cache clear
      await refreshUser();

      _setLoading(false);
      return true;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'clear_user_cache');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to clear cache: $e');
      _setLoading(false);
      return false;
    }
  }

  // NEW: Create backup
  Future<bool> createBackup() async {
    try {
      _setSyncing(true);
      clearError();

      await _dataSyncService.createAutomaticBackup();

      _setSyncing(false);
      return true;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'create_backup');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to create backup: $e');
      _setSyncing(false);
      return false;
    }
  }

  // NEW: Get available backups
  Future<List<Map<String, dynamic>>> getAvailableBackups() async {
    try {
      return await _dataSyncService.getAvailableBackups();
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'get_available_backups');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to get backups: $e');
      return [];
    }
  }

  // NEW: Restore from backup
  Future<bool> restoreFromBackup(String backupId) async {
    try {
      _setLoading(true);
      clearError();

      await _dataSyncService.restoreFromBackup(backupId);
      
      // Refresh user data after restore
      await refreshUser();

      _setLoading(false);
      return true;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'restore_from_backup');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to restore from backup: $e');
      _setLoading(false);
      return false;
    }
  }

  // NEW: Get sync status
  Stream<Map<String, dynamic>> get syncStatus => _dataSyncService.syncStatus;
  
  // NEW: Get user stream for real-time updates
  Stream<UserModel?> get userStream => _authService.user;
  
  // NEW: Force sync user data
  Future<bool> forceSyncUserData() async {
    try {
      _setSyncing(true);
      clearError();
      
      await _dataSyncService.forceSyncUserData();
      
      // Refresh user data after sync
      await refreshUser();
      
      _setSyncing(false);
      return true;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'force_sync_user_data');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to sync user data: $e');
      _setSyncing(false);
      return false;
    }
  }

  // NEW: Force sync across devices
  Future<bool> forceSyncAcrossDevices() async {
    try {
      _setSyncing(true);
      clearError();

      await _dataSyncService.forceSyncAcrossDevices();

      _setSyncing(false);
      return true;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'force_sync_across_devices');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to sync across devices: $e');
      _setSyncing(false);
      return false;
    }
  }

  // NEW: Check and resolve sync conflicts
  Future<bool> resolveSyncConflicts({bool preferServer = true}) async {
    try {
      _setSyncing(true);
      clearError();

      bool hasConflicts = await _dataSyncService.hasSyncConflicts();
      if (hasConflicts) {
        await _dataSyncService.resolveSyncConflicts(preferServer: preferServer);
      }

      _setSyncing(false);
      return true;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'resolve_sync_conflicts');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to resolve sync conflicts: $e');
      _setSyncing(false);
      return false;
    }
  }

  // NEW: Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    try {
      return await _dataSyncService.getSyncStatistics();
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'get_sync_statistics');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to get sync statistics: $e');
      return {'error': 'Failed to get sync statistics'};
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
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'change_password');
          scope.level = SentryLevel.error;
        },
      );
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
      _userPreferences = null;
      
      _setLoading(false);
      return true;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'delete_account');
          scope.level = SentryLevel.error;
        },
      );
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
      _userPreferences = null;

      _setLoading(false);
      return true;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'sign_out');
          scope.level = SentryLevel.error;
        },
      );
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
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'get_user_stats');
          scope.level = SentryLevel.error;
        },
      );
      return {'taskCount': 0, 'completedTaskCount': 0};
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    try {
      if (_authService.currentUser != null) {
        await _authService.currentUser!.reload();
        
        // Refresh user data from Firestore
        final userData = await _authService.getCurrentUserData();
        if (userData != null) {
          _user = userData;
          notifyListeners();
        }
      }
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'auth');
          scope.setTag('operation', 'refresh_user');
          scope.level = SentryLevel.error;
        },
      );
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
    _isDisposed = true;
    _preferencesSubscription?.cancel();
    _preferencesService.dispose();
    _dataSyncService.dispose();
    super.dispose();
  }
}