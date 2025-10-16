import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../services/sentry_service.dart';

class AppSettings {
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool darkModeEnabled;
  final String language;
  final int focusSessionDuration; // in minutes
  final int shortBreakDuration; // in minutes
  final int longBreakDuration; // in minutes
  final int sessionsBeforeLongBreak;
  final bool autoStartBreaks;
  final bool autoStartSessions;
  final String dateFormat;
  final String timeFormat;
  final bool showCompletionAnimations;
  final bool enableHapticFeedback;
  final double fontSize;
  final String defaultTaskCategory;
  final String defaultTaskPriority;
  final bool enableVoiceInput;
  final bool enableOfflineMode;
  final bool enableDataSync;
  final int dataRetentionDays;
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final Map<String, dynamic> customSettings;

  const AppSettings({
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.darkModeEnabled = false,
    this.language = 'en',
    this.focusSessionDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
    this.sessionsBeforeLongBreak = 4,
    this.autoStartBreaks = false,
    this.autoStartSessions = false,
    this.dateFormat = 'dd/MM/yyyy',
    this.timeFormat = '24h',
    this.showCompletionAnimations = true,
    this.enableHapticFeedback = true,
    this.fontSize = 16.0,
    this.defaultTaskCategory = 'general',
    this.defaultTaskPriority = 'medium',
    this.enableVoiceInput = true,
    this.enableOfflineMode = true,
    this.enableDataSync = true,
    this.dataRetentionDays = 365,
    this.enableAnalytics = true,
    this.enableCrashReporting = true,
    this.customSettings = const {},
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? darkModeEnabled,
    String? language,
    int? focusSessionDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? sessionsBeforeLongBreak,
    bool? autoStartBreaks,
    bool? autoStartSessions,
    String? dateFormat,
    String? timeFormat,
    bool? showCompletionAnimations,
    bool? enableHapticFeedback,
    double? fontSize,
    String? defaultTaskCategory,
    String? defaultTaskPriority,
    bool? enableVoiceInput,
    bool? enableOfflineMode,
    bool? enableDataSync,
    int? dataRetentionDays,
    bool? enableAnalytics,
    bool? enableCrashReporting,
    Map<String, dynamic>? customSettings,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      language: language ?? this.language,
      focusSessionDuration: focusSessionDuration ?? this.focusSessionDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      sessionsBeforeLongBreak: sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartSessions: autoStartSessions ?? this.autoStartSessions,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      showCompletionAnimations: showCompletionAnimations ?? this.showCompletionAnimations,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      fontSize: fontSize ?? this.fontSize,
      defaultTaskCategory: defaultTaskCategory ?? this.defaultTaskCategory,
      defaultTaskPriority: defaultTaskPriority ?? this.defaultTaskPriority,
      enableVoiceInput: enableVoiceInput ?? this.enableVoiceInput,
      enableOfflineMode: enableOfflineMode ?? this.enableOfflineMode,
      enableDataSync: enableDataSync ?? this.enableDataSync,
      dataRetentionDays: dataRetentionDays ?? this.dataRetentionDays,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      enableCrashReporting: enableCrashReporting ?? this.enableCrashReporting,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'darkModeEnabled': darkModeEnabled,
      'language': language,
      'focusSessionDuration': focusSessionDuration,
      'shortBreakDuration': shortBreakDuration,
      'longBreakDuration': longBreakDuration,
      'sessionsBeforeLongBreak': sessionsBeforeLongBreak,
      'autoStartBreaks': autoStartBreaks,
      'autoStartSessions': autoStartSessions,
      'dateFormat': dateFormat,
      'timeFormat': timeFormat,
      'showCompletionAnimations': showCompletionAnimations,
      'enableHapticFeedback': enableHapticFeedback,
      'fontSize': fontSize,
      'defaultTaskCategory': defaultTaskCategory,
      'defaultTaskPriority': defaultTaskPriority,
      'enableVoiceInput': enableVoiceInput,
      'enableOfflineMode': enableOfflineMode,
      'enableDataSync': enableDataSync,
      'dataRetentionDays': dataRetentionDays,
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
      'customSettings': customSettings,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      darkModeEnabled: json['darkModeEnabled'] ?? false,
      language: json['language'] ?? 'en',
      focusSessionDuration: json['focusSessionDuration'] ?? 25,
      shortBreakDuration: json['shortBreakDuration'] ?? 5,
      longBreakDuration: json['longBreakDuration'] ?? 15,
      sessionsBeforeLongBreak: json['sessionsBeforeLongBreak'] ?? 4,
      autoStartBreaks: json['autoStartBreaks'] ?? false,
      autoStartSessions: json['autoStartSessions'] ?? false,
      dateFormat: json['dateFormat'] ?? 'dd/MM/yyyy',
      timeFormat: json['timeFormat'] ?? '24h',
      showCompletionAnimations: json['showCompletionAnimations'] ?? true,
      enableHapticFeedback: json['enableHapticFeedback'] ?? true,
      fontSize: (json['fontSize'] ?? 16.0).toDouble(),
      defaultTaskCategory: json['defaultTaskCategory'] ?? 'general',
      defaultTaskPriority: json['defaultTaskPriority'] ?? 'medium',
      enableVoiceInput: json['enableVoiceInput'] ?? true,
      enableOfflineMode: json['enableOfflineMode'] ?? true,
      enableDataSync: json['enableDataSync'] ?? true,
      dataRetentionDays: json['dataRetentionDays'] ?? 365,
      enableAnalytics: json['enableAnalytics'] ?? true,
      enableCrashReporting: json['enableCrashReporting'] ?? true,
      customSettings: Map<String, dynamic>.from(json['customSettings'] ?? {}),
    );
  }
}

class SettingsService {
  static const String _settingsKey = 'app_settings';
  static AppSettings _settings = const AppSettings();
  static final List<VoidCallback> _listeners = [];

  /// Get current settings
  static AppSettings get settings => _settings;

  /// Add listener for settings changes
  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove listener
  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners of settings changes
  static void _notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener();
      } catch (e) {
        SentryService.captureException(e);
      }
    }
  }

  /// Initialize settings service
  static Future<void> initialize() async {
    try {
      await loadSettings();
      
      SentryService.addBreadcrumb(
        message: 'settings_service_initialized',
        category: 'settings',
        data: {
          'language': _settings.language,
          'notifications_enabled': _settings.notificationsEnabled,
          'dark_mode': _settings.darkModeEnabled,
        },
      );
    } catch (e) {
      SentryService.captureException(e);
      // Use default settings if loading fails
      _settings = const AppSettings();
    }
  }

  /// Load settings from storage
  static Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _settings = AppSettings.fromJson(settingsMap);
      } else {
        _settings = const AppSettings();
        await saveSettings(); // Save default settings
      }
    } catch (e) {
      SentryService.captureException(e);
      _settings = const AppSettings();
    }
  }

  /// Save settings to storage
  static Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(_settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
      
      SentryService.addBreadcrumb(
        message: 'settings_saved',
        category: 'settings',
        data: {
          'language': _settings.language,
          'notifications_enabled': _settings.notificationsEnabled,
        },
      );
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Update settings
  static Future<void> updateSettings(AppSettings newSettings) async {
    final oldSettings = _settings;
    try {
      _settings = newSettings;
      await saveSettings();
      _notifyListeners();

      // Log significant changes
      if (oldSettings.language != newSettings.language) {
        SentryService.addBreadcrumb(
          message: 'language_changed',
          category: 'settings',
          data: {
            'from': oldSettings.language,
            'to': newSettings.language,
          },
        );
      }

      if (oldSettings.notificationsEnabled != newSettings.notificationsEnabled) {
        SentryService.addBreadcrumb(
          message: 'notifications_toggled',
          category: 'settings',
          data: {'enabled': newSettings.notificationsEnabled},
        );
      }
    } catch (e) {
      // Revert on error
      _settings = oldSettings;
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Update specific setting
  static Future<void> updateSetting<T>(String key, T value) async {
    try {
      AppSettings newSettings;
      
      switch (key) {
        case 'notificationsEnabled':
          newSettings = _settings.copyWith(notificationsEnabled: value as bool);
          break;
        case 'soundEnabled':
          newSettings = _settings.copyWith(soundEnabled: value as bool);
          break;
        case 'vibrationEnabled':
          newSettings = _settings.copyWith(vibrationEnabled: value as bool);
          break;
        case 'darkModeEnabled':
          newSettings = _settings.copyWith(darkModeEnabled: value as bool);
          break;
        case 'language':
          newSettings = _settings.copyWith(language: value as String);
          break;
        case 'focusSessionDuration':
          newSettings = _settings.copyWith(focusSessionDuration: value as int);
          break;
        case 'shortBreakDuration':
          newSettings = _settings.copyWith(shortBreakDuration: value as int);
          break;
        case 'longBreakDuration':
          newSettings = _settings.copyWith(longBreakDuration: value as int);
          break;
        case 'fontSize':
          newSettings = _settings.copyWith(fontSize: value as double);
          break;
        case 'defaultTaskCategory':
          newSettings = _settings.copyWith(defaultTaskCategory: value as String);
          break;
        case 'defaultTaskPriority':
          newSettings = _settings.copyWith(defaultTaskPriority: value as String);
          break;
        default:
          // Handle custom settings
          final customSettings = Map<String, dynamic>.from(_settings.customSettings);
          customSettings[key] = value;
          newSettings = _settings.copyWith(customSettings: customSettings);
      }
      
      await updateSettings(newSettings);
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Get theme data based on settings
  static ThemeData getThemeData() {
    return _settings.darkModeEnabled
        ? ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
            textTheme: ThemeData.dark().textTheme.apply(
              fontSizeFactor: _settings.fontSize / 16.0,
            ),
          )
        : ThemeData.light().copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
            textTheme: ThemeData.light().textTheme.apply(
              fontSizeFactor: _settings.fontSize / 16.0,
            ),
          );
  }

  /// Get locale based on settings
  static Locale getLocale() {
    switch (_settings.language) {
      case 'hi':
        return const Locale('hi', 'IN');
      case 'kn':
        return const Locale('kn', 'IN');
      default:
        return const Locale('en', 'US');
    }
  }

  /// Reset settings to defaults
  static Future<void> resetSettings() async {
    try {
      await updateSettings(const AppSettings());
      
      SentryService.addBreadcrumb(
        message: 'settings_reset',
        category: 'settings',
      );
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Export settings as JSON string
  static String exportSettings() {
    try {
      final exportData = {
        'app_name': 'WhispTask',
        'export_date': DateTime.now().toIso8601String(),
        'settings': _settings.toJson(),
      };
      
      return const JsonEncoder.withIndent('  ').convert(exportData);
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Import settings from JSON string
  static Future<void> importSettings(String jsonString) async {
    try {
      final importData = jsonDecode(jsonString) as Map<String, dynamic>;
      final settingsData = importData['settings'] as Map<String, dynamic>;
      final newSettings = AppSettings.fromJson(settingsData);
      
      await updateSettings(newSettings);
      
      SentryService.addBreadcrumb(
        message: 'settings_imported',
        category: 'settings',
      );
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Validate settings
  static bool validateSettings(AppSettings settings) {
    try {
      // Validate focus session duration
      if (settings.focusSessionDuration < 1 || settings.focusSessionDuration > 120) {
        return false;
      }
      
      // Validate break durations
      if (settings.shortBreakDuration < 1 || settings.shortBreakDuration > 30) {
        return false;
      }
      
      if (settings.longBreakDuration < 1 || settings.longBreakDuration > 60) {
        return false;
      }
      
      // Validate font size
      if (settings.fontSize < 10.0 || settings.fontSize > 24.0) {
        return false;
      }
      
      // Validate language
      if (!['en', 'hi', 'kn'].contains(settings.language)) {
        return false;
      }
      
      return true;
    } catch (e) {
      SentryService.captureException(e);
      return false;
    }
  }
}
