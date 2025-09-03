// lib/services/user_preferences_service.dart
// ignore_for_file: avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserPreferencesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Stream controller for real-time preference updates
  StreamController<UserPreferences>? _preferencesController;
  StreamSubscription<DocumentSnapshot>? _preferencesSubscription;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Stream of user preferences with real-time updates
  Stream<UserPreferences> get preferencesStream {
    if (_currentUserId == null) {
      return Stream.value(UserPreferences.defaultPreferences());
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['preferences'] != null) {
          return UserPreferences.fromMap(data['preferences']);
        }
      }
      return UserPreferences.defaultPreferences();
    });
  }

  // Get current user preferences (one-time fetch)
  Future<UserPreferences> getCurrentPreferences() async {
    try {
      if (_currentUserId == null) {
        return UserPreferences.defaultPreferences();
      }

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['preferences'] != null) {
          return UserPreferences.fromMap(data['preferences']);
        }
      }

      // If no preferences exist, create default ones
      final defaultPrefs = UserPreferences.defaultPreferences();
      await updatePreferences(defaultPrefs);
      return defaultPrefs;
    } catch (e) {
      print('Error getting user preferences: $e');
      return UserPreferences.defaultPreferences();
    }
  }

  // Update user preferences
  Future<void> updatePreferences(UserPreferences preferences) async {
    try {
      if (_currentUserId == null) {
        throw Exception('No user logged in');
      }

      await _firestore.collection('users').doc(_currentUserId).update({
        'preferences': preferences.toMap(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('User preferences updated successfully');
    } catch (e) {
      print('Error updating user preferences: $e');
      throw Exception('Failed to update preferences: $e');
    }
  }

  // Update specific preference fields
  Future<void> updateNotificationSettings({
    bool? taskReminders,
    bool? dailyDigest,
    bool? completionCelebrations,
    bool? voiceNotifications,
  }) async {
    try {
      final currentPrefs = await getCurrentPreferences();
      
      final updatedPrefs = currentPrefs.copyWith(
        taskReminders: taskReminders ?? currentPrefs.taskReminders,
        dailyDigest: dailyDigest ?? currentPrefs.dailyDigest,
        completionCelebrations: completionCelebrations ?? currentPrefs.completionCelebrations,
        voiceNotifications: voiceNotifications ?? currentPrefs.voiceNotifications,
      );

      await updatePreferences(updatedPrefs);
    } catch (e) {
      print('Error updating notification settings: $e');
      throw Exception('Failed to update notification settings');
    }
  }

  // Update theme and display settings
  Future<void> updateDisplaySettings({
    String? theme,
    String? language,
    String? timezone,
    double? fontSize,
  }) async {
    try {
      final currentPrefs = await getCurrentPreferences();
      
      final updatedPrefs = currentPrefs.copyWith(
        theme: theme ?? currentPrefs.theme,
        language: language ?? currentPrefs.language,
        timezone: timezone ?? currentPrefs.timezone,
        fontSize: fontSize ?? currentPrefs.fontSize,
      );

      await updatePreferences(updatedPrefs);
    } catch (e) {
      print('Error updating display settings: $e');
      throw Exception('Failed to update display settings');
    }
  }

  // Update voice settings
  Future<void> updateVoiceSettings({
    bool? voiceInputEnabled,
    bool? autoTranscribe,
    String? preferredVoice,
    double? speechRate,
  }) async {
    try {
      final currentPrefs = await getCurrentPreferences();
      
      final updatedPrefs = currentPrefs.copyWith(
        voiceInputEnabled: voiceInputEnabled ?? currentPrefs.voiceInputEnabled,
        autoTranscribe: autoTranscribe ?? currentPrefs.autoTranscribe,
        preferredVoice: preferredVoice ?? currentPrefs.preferredVoice,
        speechRate: speechRate ?? currentPrefs.speechRate,
      );

      await updatePreferences(updatedPrefs);
    } catch (e) {
      print('Error updating voice settings: $e');
      throw Exception('Failed to update voice settings');
    }
  }

  // Update privacy settings
  Future<void> updatePrivacySettings({
    bool? enableAnalytics,
    bool? shareUsageData,
    bool? biometricAuth,
  }) async {
    try {
      final currentPrefs = await getCurrentPreferences();
      
      final updatedPrefs = currentPrefs.copyWith(
        enableAnalytics: enableAnalytics ?? currentPrefs.enableAnalytics,
        shareUsageData: shareUsageData ?? currentPrefs.shareUsageData,
        biometricAuth: biometricAuth ?? currentPrefs.biometricAuth,
      );

      await updatePreferences(updatedPrefs);
    } catch (e) {
      print('Error updating privacy settings: $e');
      throw Exception('Failed to update privacy settings');
    }
  }

  // Reset preferences to default
  Future<void> resetToDefaults() async {
    try {
      final defaultPrefs = UserPreferences.defaultPreferences();
      await updatePreferences(defaultPrefs);
      print('Preferences reset to defaults');
    } catch (e) {
      print('Error resetting preferences: $e');
      throw Exception('Failed to reset preferences');
    }
  }

  // Check for sync conflicts and resolve them
  Future<void> resolveSyncConflicts() async {
    try {
      if (_currentUserId == null) return;

      // Get current server preferences
      final serverPrefs = await getCurrentPreferences();
      
      // In a real app, you might compare with cached local preferences
      // For now, we'll just ensure server preferences are valid
      if (serverPrefs.theme.isEmpty) {
        await updateDisplaySettings(theme: 'system');
      }
      
      if (serverPrefs.language.isEmpty) {
        await updateDisplaySettings(language: 'en');
      }

      print('Sync conflicts resolved');
    } catch (e) {
      print('Error resolving sync conflicts: $e');
    }
  }

  // Export user preferences for backup
  Future<Map<String, dynamic>> exportPreferences() async {
    try {
      final preferences = await getCurrentPreferences();
      return {
        'preferences': preferences.toMap(),
        'exportDate': DateTime.now().toIso8601String(),
        'userId': _currentUserId,
      };
    } catch (e) {
      print('Error exporting preferences: $e');
      throw Exception('Failed to export preferences');
    }
  }

  // Import user preferences from backup
  Future<void> importPreferences(Map<String, dynamic> backupData) async {
    try {
      if (backupData['preferences'] != null) {
        final preferences = UserPreferences.fromMap(backupData['preferences']);
        await updatePreferences(preferences);
        print('Preferences imported successfully');
      } else {
        throw Exception('Invalid backup data format');
      }
    } catch (e) {
      print('Error importing preferences: $e');
      throw Exception('Failed to import preferences');
    }
  }

  // Listen to real-time preference changes
  void startListeningToPreferences(Function(UserPreferences) onPreferencesChanged) {
    if (_currentUserId == null) return;

    _preferencesSubscription?.cancel();
    _preferencesSubscription = _firestore
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['preferences'] != null) {
          final preferences = UserPreferences.fromMap(data['preferences']);
          onPreferencesChanged(preferences);
        }
      }
    });
  }

  // Stop listening to preference changes
  void stopListeningToPreferences() {
    _preferencesSubscription?.cancel();
    _preferencesSubscription = null;
  }

  // Save daily productivity score
  Future<void> saveDailyProductivityScore(double score) async {
    try {
      if (_currentUserId == null) return;
      
      final today = DateTime.now().toIso8601String().split('T')[0];
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('productivity_scores')
          .doc(today)
          .set({
        'score': score,
        'date': today,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving productivity score: $e');
    }
  }

  // Get productivity history (last 7 days)
  Future<Map<String, double>> getProductivityHistory() async {
    try {
      if (_currentUserId == null) return {};
      
      final history = <String, double>{};
      final now = DateTime.now();
      
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final dateStr = date.toIso8601String().split('T')[0];
        
        final doc = await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('productivity_scores')
            .doc(dateStr)
            .get();
            
        if (doc.exists && doc.data() != null) {
          history[dateStr] = (doc.data()!['score'] as num?)?.toDouble() ?? 0.0;
        } else {
          history[dateStr] = 0.0;
        }
      }
      
      return history;
    } catch (e) {
      print('Error getting productivity history: $e');
      return {};
    }
  }

  // Clean up resources
  void dispose() {
    _preferencesController?.close();
    _preferencesSubscription?.cancel();
  }
}