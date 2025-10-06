// lib/services/data_sync_service.dart
// ignore_for_file: avoid_print, unnecessary_cast

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart' show UserPreferences;
import '../services/user_preferences_service.dart';
import '../services/sentry_service.dart';
import '../models/task_model.dart';

class DataSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserPreferencesService _preferencesService = UserPreferencesService();

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Helper function to convert Firestore data to JSON-serializable format
  Map<String, dynamic> _sanitizeFirestoreData(Map<String, dynamic> data) {
    Map<String, dynamic> sanitized = {};
    
    data.forEach((key, value) {
      if (value is Timestamp) {
        sanitized[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeFirestoreData(value);
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _sanitizeFirestoreData(item);
          } else if (item is Timestamp) {
            return item.toDate().toIso8601String();
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });
    
    return sanitized;
  }

  // Sync user analytics data
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
    try {
      if (_currentUserId == null) {
        throw Exception('No user logged in');
      }

      Map<String, dynamic> analyticsData = {};

      if (totalTasks != null) analyticsData['totalTasks'] = totalTasks;
      if (completedTasks != null) analyticsData['completedTasks'] = completedTasks;
      if (tasksCreatedToday != null) analyticsData['tasksCreatedToday'] = tasksCreatedToday;
      if (currentStreak != null) analyticsData['currentStreak'] = currentStreak;
      if (longestStreak != null) analyticsData['longestStreak'] = longestStreak;
      if (averageCompletionTime != null) analyticsData['averageCompletionTime'] = averageCompletionTime;
      if (completionByDay != null) analyticsData['completionByDay'] = completionByDay;
      if (lastActivityDate != null) analyticsData['lastActivityDate'] = Timestamp.fromDate(lastActivityDate);

      await _firestore.collection('users').doc(_currentUserId).update({
        'analytics': analyticsData,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('User analytics updated successfully');
    } catch (e) {
      print('Error updating user analytics: $e');
      throw Exception('Failed to update analytics: $e');
    }
  }

  // Calculate and sync analytics automatically
  Future<void> calculateAndSyncAnalytics() async {
    await SentryService.wrapWithComprehensiveTracking(
      () async {
        SentryService.logDatabaseOperation('calculate_sync_analytics_start', 'analytics', data: {
          'user_id': _currentUserId ?? 'null',
        });
        
        if (_currentUserId == null) {
          SentryService.logDatabaseOperation('calculate_sync_analytics_skipped', 'analytics', data: {
            'reason': 'no_user_logged_in',
          });
          return;
        }

        // Get all user tasks
        QuerySnapshot tasksSnapshot = await _firestore
            .collection('tasks')
            .where('userId', isEqualTo: _currentUserId)
            .get();
            
        SentryService.logDatabaseOperation('tasks_fetched_for_analytics', 'tasks', data: {
          'user_id': _currentUserId!,
          'task_count': tasksSnapshot.docs.length.toString(),
        });

      List<TaskModel> tasks = tasksSnapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Calculate analytics
      int totalTasks = tasks.length;
      int completedTasks = tasks.where((task) => task.isCompleted).length;
      
      // Tasks created today
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      int tasksCreatedToday = tasks
          .where((task) => task.createdAt.isAfter(startOfDay))
          .length;

      // Calculate streaks
      Map<String, int> streakData = _calculateStreaks(tasks);
      int currentStreak = streakData['current'] ?? 0;
      int longestStreak = streakData['longest'] ?? 0;

      // Calculate average completion time
      double averageCompletionTime = _calculateAverageCompletionTime(tasks);

      // Calculate completion by day of week
      Map<String, int> completionByDay = _calculateCompletionByDay(tasks);

      // Get last activity date
      DateTime? lastActivityDate = _getLastActivityDate(tasks);

        // Update analytics
        await updateUserAnalytics(
          totalTasks: totalTasks,
          completedTasks: completedTasks,
          tasksCreatedToday: tasksCreatedToday,
          currentStreak: currentStreak,
          longestStreak: longestStreak,
          averageCompletionTime: averageCompletionTime,
          completionByDay: completionByDay,
          lastActivityDate: lastActivityDate,
        );
        
        SentryService.logDatabaseOperation('calculate_sync_analytics_complete', 'analytics', data: {
          'user_id': _currentUserId!,
          'total_tasks': totalTasks.toString(),
          'completed_tasks': completedTasks.toString(),
          'current_streak': currentStreak.toString(),
        });
      },
      operationName: 'calculate_sync_analytics',
      description: 'Calculate and sync user analytics data',
      category: 'database',
    ).catchError((e) {
      SentryService.logDatabaseOperation('calculate_sync_analytics_failed', 'analytics', data: {
        'user_id': _currentUserId ?? 'null',
        'error': e.toString(),
      });
      print('Error calculating analytics: $e');
    });
  }

  // Export complete user data
  Future<Map<String, dynamic>> exportUserData() async {
    try {
      if (_currentUserId == null) {
        throw Exception('No user logged in');
      }

      // Get user profile data
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();

      // Get all user tasks
      QuerySnapshot tasksSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      // Get user preferences
      UserPreferences preferences = await _preferencesService.getCurrentPreferences();

      // Sanitize user profile data
      Map<String, dynamic>? sanitizedUserProfile;
      if (userDoc.exists && userDoc.data() != null) {
        sanitizedUserProfile = _sanitizeFirestoreData(userDoc.data() as Map<String, dynamic>);
      }

      // Sanitize tasks data
      List<Map<String, dynamic>> sanitizedTasks = tasksSnapshot.docs.map((doc) {
        Map<String, dynamic> taskData = {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
        return _sanitizeFirestoreData(taskData);
      }).toList();

      // Sanitize analytics data
      Map<String, dynamic>? sanitizedAnalytics;
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData['analytics'] != null) {
          sanitizedAnalytics = _sanitizeFirestoreData(userData['analytics'] as Map<String, dynamic>);
        }
      }

      // Compile export data
      Map<String, dynamic> exportData = {
        'exportInfo': {
          'exportDate': DateTime.now().toIso8601String(),
          'appVersion': '1.0.0',
          'userId': _currentUserId,
        },
        'userProfile': sanitizedUserProfile,
        'preferences': preferences.toMap(),
        'tasks': sanitizedTasks,
        'analytics': sanitizedAnalytics,
      };

      print('User data exported successfully');
      return exportData;
    } catch (e) {
      print('Error exporting user data: $e');
      throw Exception('Failed to export user data: $e');
    }
  }

  // Import user data (for account restoration)
  Future<void> importUserData(Map<String, dynamic> importData) async {
    try {
      if (_currentUserId == null) {
        throw Exception('No user logged in');
      }

      // Validate import data
      if (!_validateImportData(importData)) {
        throw Exception('Invalid import data format');
      }

      // Import user profile data
      if (importData['userProfile'] != null) {
        await _firestore.collection('users').doc(_currentUserId).update({
          ...importData['userProfile'],
          'restoredAt': FieldValue.serverTimestamp(),
          'restoredFrom': importData['exportInfo']['exportDate'],
        });
      }

      // Import preferences
      if (importData['preferences'] != null) {
        final preferences = UserPreferences.fromMap(importData['preferences']);
        await _preferencesService.updatePreferences(preferences);
      }

      // Import tasks
      if (importData['tasks'] != null) {
        WriteBatch batch = _firestore.batch();
        List<dynamic> tasks = importData['tasks'];
        
        for (Map<String, dynamic> taskData in tasks) {
          taskData.remove('id'); // Remove old ID
          taskData['userId'] = _currentUserId; // Ensure correct user ID
          taskData['restoredAt'] = FieldValue.serverTimestamp();
          
          DocumentReference taskRef = _firestore.collection('tasks').doc();
          batch.set(taskRef, taskData);
        }
        
        await batch.commit();
      }

      print('User data imported successfully');
    } catch (e) {
      print('Error importing user data: $e');
      throw Exception('Failed to import user data: $e');
    }
  }


  // Sync data across devices (force refresh)
  Future<void> forceSyncAcrossDevices() async {
    try {
      if (_currentUserId == null) return;

      // Update last sync timestamp
      await _firestore.collection('users').doc(_currentUserId).update({
        'lastSyncAt': FieldValue.serverTimestamp(),
        'syncVersion': FieldValue.increment(1),
      });

      // Recalculate analytics
      await calculateAndSyncAnalytics();

      print('Data synced across devices');
    } catch (e) {
      print('Error syncing data: $e');
    }
  }

  // Check for sync conflicts
  Future<bool> hasSyncConflicts() async {
    try {
      if (_currentUserId == null) return false;

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (!userDoc.exists) return false;

      final data = userDoc.data() as Map<String, dynamic>?;
      if (data == null) return false;

      // Check if there are multiple recent updates (indicating potential conflicts)
      Timestamp? lastUpdated = data['lastUpdated'];
      Timestamp? lastSyncAt = data['lastSyncAt'];

      if (lastUpdated != null && lastSyncAt != null) {
        Duration timeDiff = lastUpdated.toDate().difference(lastSyncAt.toDate());
        return timeDiff.inMinutes > 5; // Consider conflicts if more than 5 minutes apart
      }

      return false;
    } catch (e) {
      print('Error checking sync conflicts: $e');
      return false;
    }
  }

  // Resolve sync conflicts
  Future<void> resolveSyncConflicts({bool preferServer = true}) async {
    try {
      if (preferServer) {
        // Force refresh from server
        await forceSyncAcrossDevices();
      } else {
        // In a real app, you might prefer local changes
        // For now, we'll just recalculate analytics
        await calculateAndSyncAnalytics();
      }

      print('Sync conflicts resolved');
    } catch (e) {
      print('Error resolving sync conflicts: $e');
    }
  }

  // Private helper methods

  Map<String, int> _calculateStreaks(List<TaskModel> tasks) {
    if (tasks.isEmpty) return {'current': 0, 'longest': 0};

    // Get completed tasks sorted by completion date
    List<TaskModel> completedTasks = tasks
        .where((task) => task.isCompleted && task.completedAt != null)
        .toList();
    
    completedTasks.sort((a, b) => a.completedAt!.compareTo(b.completedAt!));

    if (completedTasks.isEmpty) return {'current': 0, 'longest': 0};

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 1;
    
    DateTime today = DateTime.now();
    DateTime yesterday = today.subtract(const Duration(days: 1));

    // Check if there's activity today or yesterday for current streak
    bool hasRecentActivity = completedTasks.any((task) {
      DateTime completionDate = task.completedAt!;
      return _isSameDay(completionDate, today) || _isSameDay(completionDate, yesterday);
    });

    if (hasRecentActivity) {
      currentStreak = 1;
      
      // Calculate current streak by going backwards from today
      for (int i = completedTasks.length - 2; i >= 0; i--) {
        DateTime current = completedTasks[i + 1].completedAt!;
        DateTime previous = completedTasks[i].completedAt!;
        
        if (current.difference(previous).inDays <= 1) {
          currentStreak++;
        } else {
          break;
        }
      }
    }

    // Calculate longest streak
    for (int i = 1; i < completedTasks.length; i++) {
      DateTime current = completedTasks[i].completedAt!;
      DateTime previous = completedTasks[i - 1].completedAt!;
      
      if (current.difference(previous).inDays <= 1) {
        tempStreak++;
      } else {
        longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
        tempStreak = 1;
      }
    }
    
    longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;

    return {'current': currentStreak, 'longest': longestStreak};
  }

  double _calculateAverageCompletionTime(List<TaskModel> tasks) {
    List<TaskModel> completedTasks = tasks
        .where((task) => task.isCompleted && task.completedAt != null)
        .toList();

    if (completedTasks.isEmpty) return 0.0;

    double totalHours = 0;
    for (TaskModel task in completedTasks) {
      Duration completionTime = task.completedAt!.difference(task.createdAt);
      totalHours += completionTime.inHours;
    }

    return totalHours / completedTasks.length;
  }

  Map<String, int> _calculateCompletionByDay(List<TaskModel> tasks) {
    List<TaskModel> completedTasks = tasks
        .where((task) => task.isCompleted && task.completedAt != null)
        .toList();

    Map<String, int> completionByDay = {
      'Monday': 0,
      'Tuesday': 0,
      'Wednesday': 0,
      'Thursday': 0,
      'Friday': 0,
      'Saturday': 0,
      'Sunday': 0,
    };

    List<String> dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    for (TaskModel task in completedTasks) {
      int weekday = task.completedAt!.weekday - 1; // Convert to 0-based index
      if (weekday >= 0 && weekday < 7) {
        completionByDay[dayNames[weekday]] = (completionByDay[dayNames[weekday]] ?? 0) + 1;
      }
    }

    return completionByDay;
  }

  DateTime? _getLastActivityDate(List<TaskModel> tasks) {
    if (tasks.isEmpty) return null;

    DateTime? lastActivity;
    
    for (TaskModel task in tasks) {
      DateTime taskDate = task.completedAt ?? task.createdAt;
      if (lastActivity == null || taskDate.isAfter(lastActivity)) {
        lastActivity = taskDate;
      }
    }

    return lastActivity;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  bool _validateImportData(Map<String, dynamic> data) {
    // Validate required fields
    if (!data.containsKey('exportInfo') || 
        !data.containsKey('userProfile') || 
        !data.containsKey('preferences')) {
      return false;
    }

    // Validate export info
    Map<String, dynamic>? exportInfo = data['exportInfo'];
    if (exportInfo == null || 
        !exportInfo.containsKey('exportDate') || 
        !exportInfo.containsKey('userId')) {
      return false;
    }

    return true;
  }

  // Create automatic backup
  Future<void> createAutomaticBackup() async {
    try {
      if (_currentUserId == null) return;

      final exportData = await _exportUserDataForBackup();
      
      // Store backup in Firestore (in a separate collection)
      await _firestore
          .collection('user_backups')
          .doc(_currentUserId)
          .collection('backups')
          .add({
        'backupData': exportData,
        'createdAt': FieldValue.serverTimestamp(),
        'isAutomatic': true,
      });

      print('Automatic backup created');
    } catch (e) {
      print('Error creating automatic backup: $e');
    }
  }

  // Get available backups
  Future<List<Map<String, dynamic>>> getAvailableBackups() async {
    try {
      if (_currentUserId == null) return [];

      QuerySnapshot backupsSnapshot = await _firestore
          .collection('user_backups')
          .doc(_currentUserId)
          .collection('backups')
          .orderBy('createdAt', descending: true)
          .limit(10) // Last 10 backups
          .get();

      return backupsSnapshot.docs.map((doc) => {
        'id': doc.id,
        'createdAt': (doc.data() as Map<String, dynamic>)['createdAt'],
        'isAutomatic': (doc.data() as Map<String, dynamic>)['isAutomatic'] ?? false,
      }).toList();
    } catch (e) {
      print('Error getting available backups: $e');
      return [];
    }
  }

  // Restore from backup
  Future<void> restoreFromBackup(String backupId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('No user logged in');
      }

      DocumentSnapshot backupDoc = await _firestore
          .collection('user_backups')
          .doc(_currentUserId)
          .collection('backups')
          .doc(backupId)
          .get();

      if (!backupDoc.exists) {
        throw Exception('Backup not found');
      }

      Map<String, dynamic> backupData = backupDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> userData = backupData['backupData'];

      await _importUserDataFromBackup(userData);
      print('Data restored from backup successfully');
    } catch (e) {
      print('Error restoring from backup: $e');
      throw Exception('Failed to restore from backup: $e');
    }
  }



  // Monitor sync status
  Stream<Map<String, dynamic>> get syncStatus {
    if (_currentUserId == null) {
      return Stream.value({'isOnline': false, 'lastSync': null});
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'isOnline': true,
          'lastSync': data['lastSyncAt'],
          'lastUpdated': data['lastUpdated'],
          'syncVersion': data['syncVersion'] ?? 1,
          'hasConflicts': false, // Would be calculated based on local vs server data
        };
      }
      return {'isOnline': false, 'lastSync': null};
    });
  }

  // Update user timezone and language
  Future<void> updateUserLocalization({
    String? timezone,
    String? language,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('No user logged in');
      }

      Map<String, dynamic> updateData = {};
      
      if (timezone != null) {
        updateData['timezone'] = timezone;
      }
      
      if (language != null) {
        updateData['language'] = language;
      }

      if (updateData.isNotEmpty) {
        updateData['lastUpdated'] = FieldValue.serverTimestamp();
        
        await _firestore.collection('users').doc(_currentUserId).update(updateData);
        
        // Also update preferences
        await _preferencesService.updateDisplaySettings(
          timezone: timezone,
          language: language,
        );
      }

      print('User localization updated');
    } catch (e) {
      print('Error updating user localization: $e');
      throw Exception('Failed to update localization settings');
    }
  }

  // Cleanup old backups (keep only last 10)
  Future<void> cleanupOldBackups() async {
    try {
      if (_currentUserId == null) return;

      QuerySnapshot backupsSnapshot = await _firestore
          .collection('user_backups')
          .doc(_currentUserId)
          .collection('backups')
          .orderBy('createdAt', descending: true)
          .get();

      if (backupsSnapshot.docs.length > 10) {
        WriteBatch batch = _firestore.batch();
        
        // Delete backups beyond the 10 most recent
        for (int i = 10; i < backupsSnapshot.docs.length; i++) {
          batch.delete(backupsSnapshot.docs[i].reference);
        }
        
        await batch.commit();
        print('Old backups cleaned up');
      }
    } catch (e) {
      print('Error cleaning up old backups: $e');
    }
  }

  // Initialize sync for new device
  Future<void> initializeSyncForNewDevice() async {
    try {
      if (_currentUserId == null) return;

      // Check if user data exists
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists) {
        // Device is syncing with existing account
        await forceSyncAcrossDevices();
        
        // Check for conflicts
        bool hasConflicts = await hasSyncConflicts();
        if (hasConflicts) {
          await resolveSyncConflicts();
        }
        
        print('Sync initialized for existing account');
      } else {
        // New account - create initial data
        await calculateAndSyncAnalytics();
        print('Sync initialized for new account');
      }
    } catch (e) {
      print('Error initializing sync: $e');
    }
  }

  // Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    try {
      if (_currentUserId == null) {
        return {'error': 'No user logged in'};
      }

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();

      QuerySnapshot tasksSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      QuerySnapshot backupsSnapshot = await _firestore
          .collection('user_backups')
          .doc(_currentUserId)
          .collection('backups')
          .get();

      final userData = userDoc.exists ? userDoc.data() as Map<String, dynamic> : {};

      return {
        'lastSyncAt': userData['lastSyncAt'],
        'lastUpdated': userData['lastUpdated'],
        'syncVersion': userData['syncVersion'] ?? 1,
        'totalTasks': tasksSnapshot.docs.length,
        'totalBackups': backupsSnapshot.docs.length,
        'accountCreated': userData['createdAt'],
        'deviceCount': 1, // Would be calculated from device tracking
      };
    } catch (e) {
      print('Error getting sync statistics: $e');
      return {'error': 'Failed to get sync statistics'};
    }
  }

  // Force sync user data
  Future<void> forceSyncUserData() async {
    try {
      if (_currentUserId == null) {
        throw Exception('No user logged in');
      }
      
      await calculateAndSyncAnalytics();
      await _firestore.collection('users').doc(_currentUserId).update({
        'lastSyncAt': FieldValue.serverTimestamp(),
        'syncVersion': FieldValue.increment(1),
      });
      
      print('User data synced successfully');
    } catch (e) {
      print('Error syncing user data: $e');
      throw Exception('Failed to sync user data: $e');
    }
  }

  // Clear user cache
  Future<void> clearUserCache() async {
    try {
      if (_currentUserId == null) return;
      
      // This would clear local cache in a real implementation
      // For now, just update the sync timestamp
      await _firestore.collection('users').doc(_currentUserId).update({
        'cacheCleared': FieldValue.serverTimestamp(),
      });
      
      print('User cache cleared');
    } catch (e) {
      print('Error clearing user cache: $e');
      throw Exception('Failed to clear user cache: $e');
    }
  }

  // Private helper methods for backup operations
  Future<Map<String, dynamic>> _exportUserDataForBackup() async {
    final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
    final tasksSnapshot = await _firestore
        .collection('tasks')
        .where('userId', isEqualTo: _currentUserId)
        .get();
    final preferences = await _preferencesService.getCurrentPreferences();

    // Sanitize user profile data
    Map<String, dynamic>? sanitizedUserProfile;
    if (userDoc.exists && userDoc.data() != null) {
      sanitizedUserProfile = _sanitizeFirestoreData(userDoc.data() as Map<String, dynamic>);
    }

    // Sanitize tasks data
    List<Map<String, dynamic>> sanitizedTasks = tasksSnapshot.docs.map((doc) {
      Map<String, dynamic> taskData = {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
      return _sanitizeFirestoreData(taskData);
    }).toList();

    // Sanitize analytics data
    Map<String, dynamic>? sanitizedAnalytics;
    if (userDoc.exists && userDoc.data() != null) {
      final userData = userDoc.data() as Map<String, dynamic>;
      if (userData['analytics'] != null) {
        sanitizedAnalytics = _sanitizeFirestoreData(userData['analytics'] as Map<String, dynamic>);
      }
    }

    return {
      'exportInfo': {
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'userId': _currentUserId,
      },
      'userProfile': sanitizedUserProfile,
      'preferences': preferences.toMap(),
      'tasks': sanitizedTasks,
      'analytics': sanitizedAnalytics,
    };
  }

  Future<void> _importUserDataFromBackup(Map<String, dynamic> importData) async {
    if (!_validateImportData(importData)) {
      throw Exception('Invalid import data format');
    }

    // Update user profile
    if (importData['userProfile'] != null) {
      await _firestore.collection('users').doc(_currentUserId).update({
        ...importData['userProfile'] as Map<String, dynamic>,
        'restoredAt': FieldValue.serverTimestamp(),
      });
    }

    // Import preferences
    if (importData['preferences'] != null) {
      final preferences = UserPreferences.fromMap(importData['preferences'] as Map<String, dynamic>);
      await _preferencesService.updatePreferences(preferences);
    }

    // Import tasks
    if (importData['tasks'] != null) {
      WriteBatch batch = _firestore.batch();
      for (Map<String, dynamic> taskData in importData['tasks'] as List) {
        taskData = Map<String, dynamic>.from(taskData);
        taskData.remove('id');
        taskData['userId'] = _currentUserId;
        taskData['restoredAt'] = FieldValue.serverTimestamp();
        
        DocumentReference taskRef = _firestore.collection('tasks').doc();
        batch.set(taskRef, taskData);
      }
      await batch.commit();
    }
  }

  // Dispose of resources
  void dispose() {
    _preferencesService.dispose();
  }
}