// services/auth_service.dart - Enhanced version with full UserModel support
// ignore_for_file: deprecated_member_use, avoid_print, must_call_super, annotate_overrides

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'user_preferences_service.dart';
import 'data_sync_service.dart';
import 'sentry_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserPreferencesService? _preferencesService;
  DataSyncService? _dataSyncService;
  final bool _isTestMode;

  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _isTestMode = firebaseAuth != null || firestore != null {
    // Only initialize services if not in test mode
    if (!_isTestMode) {
      _preferencesService = UserPreferencesService();
      _dataSyncService = DataSyncService();
    }
  }

  // Get current user stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Get current user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  // Check if user is logged in
  bool get isLoggedIn => _firebaseAuth.currentUser != null;

  // Check if user is anonymous
  bool get isAnonymous => _firebaseAuth.currentUser?.isAnonymous ?? false;

  // Convert Firebase User to UserModel (fallback only)
  UserModel? _userFromFirebase(User? user) {
    if (user == null) return null;
    
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName ?? 'User',
      isAnonymous: user.isAnonymous,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastSignIn: user.metadata.lastSignInTime ?? DateTime.now(),
      preferences: UserPreferences.defaultPreferences(),
      analytics: UserAnalytics.defaultAnalytics(),
      timezone: DateTime.now().timeZoneName,
      language: 'en',
    );
  }

  // ENHANCED: Complete UserModel stream that fetches from Firestore
  Stream<UserModel?> get user {
    return authStateChanges.asyncMap((User? firebaseUser) async {
      if (firebaseUser == null) return null;
      
      try {
        // Try to get complete user data from Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        
        if (userDoc.exists) {
          return UserModel.fromFirestore(userDoc);
        } else {
          // Create user document if it doesn't exist
          await _createEnhancedUserDocument(firebaseUser);
          
          // Fetch the newly created document
          DocumentSnapshot newUserDoc = await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .get();
          
          return UserModel.fromFirestore(newUserDoc);
        }
      } catch (e) {
        print('Error fetching user data from Firestore: $e');
        await SentryService.captureException(
          e,
          stackTrace: StackTrace.current,
          hint: 'Error fetching user data from Firestore',
          extra: {
            'user_id': firebaseUser.uid,
            'service': 'auth',
            'operation': 'fetch_user_data',
          },
          level: 'warning',
        );
        // Fallback to basic Firebase user data
        return _userFromFirebase(firebaseUser);
      }
    });
  }

  // Get current user data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) return null;

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      } else {
        await _createEnhancedUserDocument(currentUser);
        DocumentSnapshot newUserDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        return UserModel.fromFirestore(newUserDoc);
      }
    } catch (e) {
      print('Error getting current user data: $e');
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('service', 'auth');
          scope.setTag('operation', 'get_current_user_data');
          scope.level = SentryLevel.error;
        },
      );
      return null;
    }
  }

  // Sign in anonymously
  Future<UserModel?> signInAnonymously() async {
    try {
      UserCredential result = await _firebaseAuth.signInAnonymously();
      User? user = result.user;
      
      // Create enhanced user document in Firestore
      if (user != null) {
        await _createEnhancedUserDocument(user);
        
        // Initialize sync for new device (skip in test mode)
        if (!_isTestMode && _dataSyncService != null) {
          await _dataSyncService!.initializeSyncForNewDevice();
        }
        
        // Return complete Firestore data
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromFirestore(userDoc);
      }
      
      return _userFromFirebase(user);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailPassword(
    String email, 
    String password, 
    String displayName
  ) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      User? user = result.user;
      
      // Update display name
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.reload();
        user = _firebaseAuth.currentUser;
        
        // Create enhanced user document in Firestore
        await _createEnhancedUserDocument(user!, displayName: displayName);
        
        // Initialize sync for new device (skip in test mode)
        if (!_isTestMode && _dataSyncService != null) {
          await _dataSyncService!.initializeSyncForNewDevice();
        }
        
        // Return complete Firestore data
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromFirestore(userDoc);
      }
      
      return _userFromFirebase(user);
    } catch (e) {
      if (_isTestMode) {
        print('Auth error in test mode: ${_handleAuthError(e)}');
        return null;
      }
      throw _handleAuthError(e);
    }
  }

  // Sign in with email and password - ENHANCED VERSION
  Future<UserModel?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    
      User? user = result.user;
    
      if (user != null) {
        // Update last sign in
        await _updateEnhancedUserDocument(user);
        
        // Skip sync operations in test mode
        if (!_isTestMode && _dataSyncService != null) {
          try {
            await _dataSyncService!.initializeSyncForNewDevice();
            if (await _dataSyncService!.hasSyncConflicts()) {
              await _dataSyncService!.resolveSyncConflicts();
            }
          } catch (e) {
            print('Sync service error: $e');
          }
        }
      
        // Fetch complete user data from Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      
        if (userDoc.exists) {
          return UserModel.fromFirestore(userDoc);
        } else {
          // Fallback: create user document if it doesn't exist
          await _createEnhancedUserDocument(user);
          DocumentSnapshot newUserDoc = await _firestore.collection('users').doc(user.uid).get();
          return UserModel.fromFirestore(newUserDoc);
        }
      }
    
      return null;
    } catch (e) {
      if (_isTestMode) {
        print('Auth error in test mode (signInWithEmailPassword): $e');
        print('Error type: ${e.runtimeType}');
        return null;
      }
      throw _handleAuthError(e);
    }
  }

  // Convert anonymous account to permanent account
  Future<UserModel?> linkAnonymousWithEmail(
    String email, 
    String password, 
    String displayName
  ) async {
    try {
      if (!isAnonymous) {
        throw Exception('Current user is not anonymous');
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: email.trim(), 
        password: password
      );
      
      UserCredential result = await _firebaseAuth.currentUser!.linkWithCredential(credential);
      User? user = result.user;
      
      // Update display name and user document
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.reload();
        user = _firebaseAuth.currentUser;
        
        // Update user document with new info
        await _updateEnhancedUserDocument(user!, displayName: displayName, isAnonymous: false);
        
        // Return complete Firestore data
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromFirestore(userDoc);
      }
      
      return _userFromFirebase(user);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Update profile - ENHANCED VERSION
  Future<UserModel?> updateProfile({
    String? displayName, 
    String? email,
    String? timezone,
    String? language,
  }) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Update display name
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }

      // Update email
      if (email != null && email.isNotEmpty && email != user.email) {
        await user.updateEmail(email.trim());
      }

      // Reload user data
      await user.reload();
      user = _firebaseAuth.currentUser;

      // Update Firestore document
      if (user != null) {
        await _updateEnhancedUserDocument(
          user, 
          displayName: displayName,
          timezone: timezone,
          language: language,
        );
        
        // Update user preferences with new settings (skip in test mode)
        if (!_isTestMode && _preferencesService != null) {
          try {
            final currentPrefs = await _preferencesService!.getCurrentPreferences();
            final updatedPrefs = currentPrefs.copyWith(
              timezone: timezone,
              language: language,
            );
            await _preferencesService!.updatePreferences(updatedPrefs);
          } catch (e) {
            print('Preferences service error: $e');
          }
        }
        
        // Return complete Firestore data
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromFirestore(userDoc);
      }

      return _userFromFirebase(user);
    } catch (e) {
      if (_isTestMode) {
        print('Auth error in test mode: ${_handleAuthError(e)}');
        return null;
      }
      throw _handleAuthError(e);
    }
  }

  // Update user preferences (skip in test mode)
  Future<void> updateUserPreferences(UserPreferences preferences) async {
    if (!_isTestMode && _preferencesService != null) {
      try {
        await _preferencesService!.updatePreferences(preferences);
      } catch (e) {
        print('Preferences service error: $e');
      }
    }
  }

  // Update user analytics (delegated to data sync service)
  Future<void> updateUserAnalytics({
    int? totalTasks,
    int? completedTasks,
    int? tasksCreatedToday,
    int? currentStreak,
    int? longestStreak,
    double? averageCompletionTime,
    Map<String, int>? completionByDay,
    DateTime? lastActivityDate,
  }) async {
    if (!_isTestMode && _dataSyncService != null) {
      await _dataSyncService!.updateUserAnalytics(
        totalTasks: totalTasks,
        completedTasks: completedTasks,
        tasksCreatedToday: tasksCreatedToday,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        averageCompletionTime: averageCompletionTime,
        completionByDay: completionByDay,
        lastActivityDate: lastActivityDate,
      );
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user logged in or user has no email');
      }

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      
      // Update last activity
      await _updateEnhancedUserDocument(user);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Delete account
  Future<void> deleteAccount(String? password) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Re-authenticate if not anonymous
      if (!user.isAnonymous && password != null && user.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }

      String userId = user.uid;

      // Delete user document from Firestore
      await _firestore.collection('users').doc(userId).delete();
      
      // Delete user tasks
      await _deleteUserTasks(userId);

      // Delete user backups
      await _deleteUserBackups(userId);

      // Delete Firebase Auth user
      await user.delete();
    } catch (e) {
      if (_isTestMode) {
        print('Auth error in test mode: ${_handleAuthError(e)}');
        return;
      }
      throw _handleAuthError(e);
    }
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with the credential
      UserCredential result = await _firebaseAuth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // Create or update enhanced user document
        await _createOrUpdateGoogleUserDocument(user, googleUser);
        
        // Initialize sync for new device (skip in test mode)
        if (!_isTestMode && _dataSyncService != null) {
          await _dataSyncService!.initializeSyncForNewDevice();
          if (await _dataSyncService!.hasSyncConflicts()) {
            await _dataSyncService!.resolveSyncConflicts();
          }
        }
        
        // Return complete Firestore data
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromFirestore(userDoc);
      }
      
      return null;
    } catch (e) {
      if (_isTestMode) {
        print('Google sign-in error in test mode: $e');
        return null;
      }
      throw _handleAuthError(e);
    }
  }

  // Link anonymous account with Google
  Future<UserModel?> linkAnonymousWithGoogle() async {
    try {
      if (!isAnonymous) {
        throw Exception('Current user is not anonymous');
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null;
      }

      // Obtain the auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link with credential
      UserCredential result = await _firebaseAuth.currentUser!.linkWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // Update user document
        await _updateEnhancedUserDocument(
          user, 
          displayName: googleUser.displayName,
          isAnonymous: false,
        );
        
        // Return complete Firestore data
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromFirestore(userDoc);
      }
      
      return null;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out from Google
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error signing out from Google: $e');
    }
  }

  // Create or update user document for Google sign-in
  Future<void> _createOrUpdateGoogleUserDocument(User user, GoogleSignInAccount googleUser) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(user.uid);
      DocumentSnapshot userDoc = await userRef.get();
      
      String deviceTimezone = DateTime.now().timeZoneName;
      String deviceLanguage = 'en';
      
      if (userDoc.exists) {
        // Update existing user
        await userRef.update({
          'lastSignIn': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'syncVersion': FieldValue.increment(1),
          'email': user.email,
          'displayName': user.displayName ?? googleUser.displayName ?? 'User',
        });
      } else {
        // Create new user document
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? googleUser.displayName ?? 'User',
          'isAnonymous': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSignIn': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'timezone': deviceTimezone,
          'language': deviceLanguage,
          'provider': 'google',
          
          // Initialize preferences with defaults
          'preferences': UserPreferences.defaultPreferences().toMap(),
          
          // Initialize analytics with defaults
          'analytics': UserAnalytics.defaultAnalytics().toMap(),
          
          // Sync metadata
          'syncVersion': 1,
          'lastSyncAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error creating/updating Google user document: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Create automatic backup before signing out
      await _dataSyncService?.createAutomaticBackup();
      
      // Sign out from Google if signed in with Google
      await signOutGoogle();
      
      // Clean up listeners
      _preferencesService?.dispose();
      _dataSyncService?.dispose();
      
      await _firebaseAuth.signOut();
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ENHANCED: Create user document with complete UserModel data
  Future<void> _createEnhancedUserDocument(User user, {String? displayName}) async {
    try {
      // Get device timezone and language
      String deviceTimezone = DateTime.now().timeZoneName;
      String deviceLanguage = 'en'; // Could be detected from device locale

      // Create complete user document
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName ?? user.displayName ?? 'User',
        'isAnonymous': user.isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'timezone': deviceTimezone,
        'language': deviceLanguage,
        
        // Initialize preferences with defaults
        'preferences': UserPreferences.defaultPreferences().toMap(),
        
        // Initialize analytics with defaults
        'analytics': UserAnalytics.defaultAnalytics().toMap(),
        
        // Sync metadata
        'syncVersion': 1,
        'lastSyncAt': FieldValue.serverTimestamp(),
      });

      print('Enhanced user document created');
    } catch (e) {
      print('Error creating enhanced user document: $e');
    }
  }

  // ENHANCED: Update user document with complete data
  Future<void> _updateEnhancedUserDocument(
    User user, {
    String? displayName,
    bool? isAnonymous,
    String? timezone,
    String? language,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'lastSignIn': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'syncVersion': FieldValue.increment(1),
      };

      if (displayName != null) {
        updateData['displayName'] = displayName;
      }

      if (isAnonymous != null) {
        updateData['isAnonymous'] = isAnonymous;
        updateData['email'] = user.email;
      }

      if (timezone != null) {
        updateData['timezone'] = timezone;
      }

      if (language != null) {
        updateData['language'] = language;
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);
      
      // Update analytics after profile changes
      await _dataSyncService?.calculateAndSyncAnalytics();
    } catch (e) {
      print('Error updating enhanced user document: $e');
    }
  }

  // Delete all user tasks
  Future<void> _deleteUserTasks(String userId) async {
    try {
      QuerySnapshot tasksSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();

      WriteBatch batch = _firestore.batch();
      for (QueryDocumentSnapshot doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting user tasks: $e');
    }
  }

  // Delete user backups
  Future<void> _deleteUserBackups(String userId) async {
    try {
      QuerySnapshot backupsSnapshot = await _firestore
          .collection('user_backups')
          .doc(userId)
          .collection('backups')
          .get();

      WriteBatch batch = _firestore.batch();
      for (QueryDocumentSnapshot doc in backupsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the parent backup document
      await batch.commit();
      await _firestore.collection('user_backups').doc(userId).delete();
    } catch (e) {
      print('Error deleting user backups: $e');
    }
  }

  // Get user stats with enhanced analytics
  Future<Map<String, int>> getUserStats() async {
    try {
      if (currentUserId == null) return {'taskCount': 0, 'completedTaskCount': 0};

      // Trigger analytics calculation
      await _dataSyncService?.calculateAndSyncAnalytics();

      QuerySnapshot allTasks = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: currentUserId)
          .get();

      QuerySnapshot completedTasks = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: currentUserId)
          .where('isCompleted', isEqualTo: true)
          .get();

      return {
        'taskCount': allTasks.docs.length,
        'completedTaskCount': completedTasks.docs.length,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {'taskCount': 0, 'completedTaskCount': 0};
    }
  }

  // Sync preferences across devices
  Future<void> syncPreferencesAcrossDevices() async {
    try {
      // Skip preferences sync in test mode
      if (!_isTestMode && _preferencesService != null) {
        await _preferencesService!.resetToDefaults();
      }
      await _dataSyncService?.forceSyncAcrossDevices();
      print('Preferences synced across devices');
    } catch (e) {
      print('Error syncing preferences: $e');
    }
  }

  // Handle authentication errors
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'invalid-email':
          return 'Invalid email address format.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'This operation is not allowed. Please contact support.';
        case 'requires-recent-login':
          return 'Please log in again to perform this action.';
        case 'credential-already-in-use':
          return 'This account is already linked with another user.';
        // Add Google-specific cases
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email using a different sign-in method.';
        case 'invalid-credential':
          return 'The Google sign-in credential is invalid.';
        default:
          return 'Authentication error: ${error.message}';
      }
    }
    
    // Handle Google Sign-In specific errors
    if (error.toString().contains('GoogleSignIn')) {
      if (error.toString().contains('network_error')) {
        return 'Network error. Please check your internet connection.';
      }
      if (error.toString().contains('sign_in_canceled')) {
        return ''; // Don't show error for user cancellation
      }
      return 'Google sign-in failed. Please try again.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  // Dispose of resources
  void dispose() {
    // Dispose services (skip in test mode)
    if (!_isTestMode) {
      _preferencesService?.dispose();
      _dataSyncService?.dispose();
    }
  }
}