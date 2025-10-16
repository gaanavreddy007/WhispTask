// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';
import '../services/sentry_service.dart';
import '../services/statistics_service.dart';
import '../services/achievement_service.dart';
import '../services/habit_service.dart';
import '../services/focus_service.dart';
import '../services/settings_service.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  conflict,
}

class BackupData {
  final DateTime timestamp;
  final String version;
  final Map<String, dynamic> tasks;
  final Map<String, dynamic> habits;
  final Map<String, dynamic> achievements;
  final Map<String, dynamic> focusSessions;
  final Map<String, dynamic> statistics;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> metadata;

  const BackupData({
    required this.timestamp,
    required this.version,
    required this.tasks,
    required this.habits,
    required this.achievements,
    required this.focusSessions,
    required this.statistics,
    required this.settings,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'version': version,
      'tasks': tasks,
      'habits': habits,
      'achievements': achievements,
      'focus_sessions': focusSessions,
      'statistics': statistics,
      'settings': settings,
      'metadata': metadata,
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      timestamp: DateTime.parse(json['timestamp']),
      version: json['version'],
      tasks: json['tasks'] ?? {},
      habits: json['habits'] ?? {},
      achievements: json['achievements'] ?? {},
      focusSessions: json['focus_sessions'] ?? {},
      statistics: json['statistics'] ?? {},
      settings: json['settings'] ?? {},
      metadata: json['metadata'] ?? {},
    );
  }
}

class BackupSyncService {
  static const String _lastBackupKey = 'last_backup_timestamp';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _syncStatusKey = 'sync_status';
  static const String _currentVersion = '1.0.0';

  static SyncStatus _syncStatus = SyncStatus.idle;
  static DateTime? _lastBackupTime;
  static DateTime? _lastSyncTime;
  static final List<Function(SyncStatus)> _statusListeners = [];

  /// Get current sync status
  static SyncStatus get syncStatus => _syncStatus;
  static DateTime? get lastBackupTime => _lastBackupTime;
  static DateTime? get lastSyncTime => _lastSyncTime;

  /// Add sync status listener
  static void addStatusListener(Function(SyncStatus) listener) {
    _statusListeners.add(listener);
  }

  /// Remove sync status listener
  static void removeStatusListener(Function(SyncStatus) listener) {
    _statusListeners.remove(listener);
  }

  /// Notify status listeners
  static void _notifyStatusListeners(SyncStatus status) {
    _syncStatus = status;
    for (final listener in _statusListeners) {
      try {
        listener(status);
      } catch (e) {
        SentryService.captureException(e);
      }
    }
  }

  /// Initialize backup sync service
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load last backup time
      final lastBackupString = prefs.getString(_lastBackupKey);
      if (lastBackupString != null) {
        _lastBackupTime = DateTime.parse(lastBackupString);
      }
      
      // Load last sync time
      final lastSyncString = prefs.getString(_lastSyncKey);
      if (lastSyncString != null) {
        _lastSyncTime = DateTime.parse(lastSyncString);
      }
      
      // Load sync status
      final statusString = prefs.getString(_syncStatusKey);
      if (statusString != null) {
        _syncStatus = SyncStatus.values.firstWhere(
          (status) => status.name == statusString,
          orElse: () => SyncStatus.idle,
        );
      }

      SentryService.addBreadcrumb(
        message: 'backup_sync_service_initialized',
        category: 'backup',
        data: {
          'last_backup': _lastBackupTime?.toIso8601String(),
          'last_sync': _lastSyncTime?.toIso8601String(),
          'status': _syncStatus.name,
        },
      );
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Create complete backup of all app data
  static Future<BackupData> createBackup() async {
    try {
      _notifyStatusListeners(SyncStatus.syncing);

      // Collect all app data
      final tasks = await _collectTasksData();
      final habits = await _collectHabitsData();
      final achievements = await _collectAchievementsData();
      final focusSessions = await _collectFocusSessionsData();
      final statistics = await _collectStatisticsData();
      final settings = await _collectSettingsData();
      final metadata = await _collectMetadata();

      final backup = BackupData(
        timestamp: DateTime.now(),
        version: _currentVersion,
        tasks: tasks,
        habits: habits,
        achievements: achievements,
        focusSessions: focusSessions,
        statistics: statistics,
        settings: settings,
        metadata: metadata,
      );

      // Update last backup time
      _lastBackupTime = backup.timestamp;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupKey, backup.timestamp.toIso8601String());

      _notifyStatusListeners(SyncStatus.success);

      SentryService.addBreadcrumb(
        message: 'backup_created',
        category: 'backup',
        data: {
          'timestamp': backup.timestamp.toIso8601String(),
          'version': backup.version,
          'tasks_count': (tasks['items'] as List?)?.length ?? 0,
          'habits_count': (habits['items'] as List?)?.length ?? 0,
        },
      );

      return backup;
    } catch (e) {
      _notifyStatusListeners(SyncStatus.error);
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Restore data from backup
  static Future<void> restoreFromBackup(BackupData backup) async {
    try {
      _notifyStatusListeners(SyncStatus.syncing);

      // Validate backup version compatibility
      if (!_isVersionCompatible(backup.version)) {
        throw Exception('Backup version ${backup.version} is not compatible with current version $_currentVersion');
      }

      // Restore each data type
      await _restoreTasksData(backup.tasks);
      await _restoreHabitsData(backup.habits);
      await _restoreAchievementsData(backup.achievements);
      await _restoreFocusSessionsData(backup.focusSessions);
      await _restoreSettingsData(backup.settings);

      // Update sync time
      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, _lastSyncTime!.toIso8601String());

      _notifyStatusListeners(SyncStatus.success);

      SentryService.addBreadcrumb(
        message: 'backup_restored',
        category: 'backup',
        data: {
          'backup_timestamp': backup.timestamp.toIso8601String(),
          'backup_version': backup.version,
        },
      );
    } catch (e) {
      _notifyStatusListeners(SyncStatus.error);
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Export backup to file
  static Future<String> exportBackupToFile() async {
    try {
      final backup = await createBackup();
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'whisptask_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(backup.toJson());
      await file.writeAsString(jsonString);

      SentryService.addBreadcrumb(
        message: 'backup_exported',
        category: 'backup',
        data: {
          'file_path': file.path,
          'file_size': jsonString.length,
        },
      );

      return file.path;
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Import backup from file
  static Future<void> importBackupFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found: $filePath');
      }

      final jsonString = await file.readAsString();
      final backupJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final backup = BackupData.fromJson(backupJson);

      await restoreFromBackup(backup);

      SentryService.addBreadcrumb(
        message: 'backup_imported',
        category: 'backup',
        data: {
          'file_path': filePath,
          'backup_timestamp': backup.timestamp.toIso8601String(),
        },
      );
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Copy backup to clipboard
  static Future<void> copyBackupToClipboard() async {
    try {
      final backup = await createBackup();
      final jsonString = jsonEncode(backup.toJson());
      await Clipboard.setData(ClipboardData(text: jsonString));

      SentryService.addBreadcrumb(
        message: 'backup_copied_to_clipboard',
        category: 'backup',
        data: {'backup_size': jsonString.length},
      );
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Restore backup from clipboard
  static Future<void> restoreBackupFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData?.text == null) {
        throw Exception('No backup data found in clipboard');
      }

      final backupJson = jsonDecode(clipboardData!.text!) as Map<String, dynamic>;
      final backup = BackupData.fromJson(backupJson);

      await restoreFromBackup(backup);

      SentryService.addBreadcrumb(
        message: 'backup_restored_from_clipboard',
        category: 'backup',
      );
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Auto backup if needed
  static Future<void> autoBackupIfNeeded() async {
    try {
      final settings = SettingsService.settings;
      if (!settings.enableDataSync) return;

      final now = DateTime.now();
      final lastBackup = _lastBackupTime;
      
      // Auto backup every 24 hours
      if (lastBackup == null || now.difference(lastBackup).inHours >= 24) {
        await createBackup();
        
        SentryService.addBreadcrumb(
          message: 'auto_backup_performed',
          category: 'backup',
          data: {'hours_since_last': lastBackup != null ? now.difference(lastBackup).inHours : null},
        );
      }
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Get backup statistics
  static Future<Map<String, dynamic>> getBackupStatistics() async {
    try {
      final backup = await createBackup();
      final jsonString = jsonEncode(backup.toJson());
      
      return {
        'backup_size_bytes': jsonString.length,
        'backup_size_kb': (jsonString.length / 1024).round(),
        'last_backup': _lastBackupTime?.toIso8601String(),
        'last_sync': _lastSyncTime?.toIso8601String(),
        'tasks_count': (backup.tasks['items'] as List?)?.length ?? 0,
        'habits_count': (backup.habits['items'] as List?)?.length ?? 0,
        'achievements_count': (backup.achievements['items'] as List?)?.length ?? 0,
        'focus_sessions_count': (backup.focusSessions['items'] as List?)?.length ?? 0,
        'version': backup.version,
        'timestamp': backup.timestamp.toIso8601String(),
      };
    } catch (e) {
      SentryService.captureException(e);
      return {};
    }
  }

  // Private helper methods

  static Future<Map<String, dynamic>> _collectTasksData() async {
    // This would integrate with your TaskProvider
    return {
      'items': [], // TaskProvider.tasks.map((t) => t.toJson()).toList(),
      'metadata': {
        'total_count': 0,
        'completed_count': 0,
        'last_updated': DateTime.now().toIso8601String(),
      },
    };
  }

  static Future<Map<String, dynamic>> _collectHabitsData() async {
    final habits = HabitService.habits;
    return {
      'items': habits.map((h) => h.toJson()).toList(),
      'metadata': {
        'total_count': habits.length,
        'active_count': habits.where((h) => h.isActive).length,
        'last_updated': DateTime.now().toIso8601String(),
      },
    };
  }

  static Future<Map<String, dynamic>> _collectAchievementsData() async {
    final achievements = AchievementService.achievements;
    return {
      'items': achievements.map((a) => a.toJson()).toList(),
      'metadata': {
        'total_count': achievements.length,
        'unlocked_count': achievements.where((a) => a.isUnlocked).length,
        'last_updated': DateTime.now().toIso8601String(),
      },
    };
  }

  static Future<Map<String, dynamic>> _collectFocusSessionsData() async {
    final sessions = FocusService.sessions;
    return {
      'items': sessions.map((s) => s.toJson()).toList(),
      'statistics': FocusService.getFocusStatistics(),
      'metadata': {
        'total_count': sessions.length,
        'last_updated': DateTime.now().toIso8601String(),
      },
    };
  }

  static Future<Map<String, dynamic>> _collectStatisticsData() async {
    return {
      'cached_data': {}, // StatisticsService cached data if any
      'metadata': {
        'last_calculated': DateTime.now().toIso8601String(),
      },
    };
  }

  static Future<Map<String, dynamic>> _collectSettingsData() async {
    return {
      'settings': SettingsService.settings.toJson(),
      'metadata': {
        'last_updated': DateTime.now().toIso8601String(),
      },
    };
  }

  static Future<Map<String, dynamic>> _collectMetadata() async {
    return {
      'app_version': _currentVersion,
      'platform': Platform.operatingSystem,
      'backup_created': DateTime.now().toIso8601String(),
      'device_info': {
        'os': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
      },
    };
  }

  static Future<void> _restoreTasksData(Map<String, dynamic> data) async {
    // This would integrate with your TaskProvider
    // final items = data['items'] as List<dynamic>;
    // await TaskProvider.restoreFromBackup(items);
  }

  static Future<void> _restoreHabitsData(Map<String, dynamic> data) async {
    // final items = data['items'] as List<dynamic>;
    // await HabitService.restoreFromBackup(items);
  }

  static Future<void> _restoreAchievementsData(Map<String, dynamic> data) async {
    // final items = data['items'] as List<dynamic>;
    // await AchievementService.restoreFromBackup(items);
  }

  static Future<void> _restoreFocusSessionsData(Map<String, dynamic> data) async {
    // final items = data['items'] as List<dynamic>;
    // await FocusService.restoreFromBackup(items);
  }

  static Future<void> _restoreSettingsData(Map<String, dynamic> data) async {
    final settingsData = data['settings'] as Map<String, dynamic>;
    final settings = AppSettings.fromJson(settingsData);
    await SettingsService.updateSettings(settings);
  }

  static bool _isVersionCompatible(String backupVersion) {
    // Simple version compatibility check
    final backupMajor = int.parse(backupVersion.split('.')[0]);
    final currentMajor = int.parse(_currentVersion.split('.')[0]);
    return backupMajor == currentMajor;
  }
}
