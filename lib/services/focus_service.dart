import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../services/sentry_service.dart';
import '../services/notification_service.dart';

enum FocusMode {
  pomodoro,
  deepWork,
  breakTime,
  custom,
}

enum FocusSessionStatus {
  idle,
  running,
  paused,
  completed,
  cancelled,
}

class FocusSession {
  final String id;
  final FocusMode mode;
  final Duration duration;
  final DateTime startTime;
  final DateTime? endTime;
  final FocusSessionStatus status;
  final Duration? pausedDuration;
  final Map<String, dynamic> metadata;

  FocusSession({
    required this.id,
    required this.mode,
    required this.duration,
    required this.startTime,
    this.endTime,
    required this.status,
    this.pausedDuration,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mode': mode.name,
      'duration': duration.inSeconds,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status.name,
      'pausedDuration': pausedDuration?.inSeconds,
      'metadata': metadata,
    };
  }

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'],
      mode: FocusMode.values.firstWhere((e) => e.name == json['mode']),
      duration: Duration(seconds: json['duration']),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      status: FocusSessionStatus.values.firstWhere((e) => e.name == json['status']),
      pausedDuration: json['pausedDuration'] != null 
          ? Duration(seconds: json['pausedDuration']) 
          : null,
      metadata: json['metadata'] ?? {},
    );
  }

  FocusSession copyWith({
    String? id,
    FocusMode? mode,
    Duration? duration,
    DateTime? startTime,
    DateTime? endTime,
    FocusSessionStatus? status,
    Duration? pausedDuration,
    Map<String, dynamic>? metadata,
  }) {
    return FocusSession(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      pausedDuration: pausedDuration ?? this.pausedDuration,
      metadata: metadata ?? this.metadata,
    );
  }

  Duration get actualDuration {
    if (endTime == null) return Duration.zero;
    final totalDuration = endTime!.difference(startTime);
    return totalDuration - (pausedDuration ?? Duration.zero);
  }

  double get completionPercentage {
    if (status == FocusSessionStatus.completed) return 1.0;
    if (status == FocusSessionStatus.idle) return 0.0;
    
    final elapsed = DateTime.now().difference(startTime) - (pausedDuration ?? Duration.zero);
    return (elapsed.inSeconds / duration.inSeconds).clamp(0.0, 1.0);
  }
}

class FocusService {
  static const String _sessionsKey = 'focus_sessions';
  static const String _settingsKey = 'focus_settings';
  
  static List<FocusSession> _sessions = [];
  static FocusSession? _currentSession;
  static Timer? _focusTimer;
  static DateTime? _pauseStartTime;
  static Duration _totalPausedDuration = Duration.zero;
  
  static final StreamController<FocusSession?> _sessionController = 
      StreamController<FocusSession?>.broadcast();
  static final StreamController<Duration> _timerController = 
      StreamController<Duration>.broadcast();

  // Default durations for different focus modes
  static const Map<FocusMode, Duration> _defaultDurations = {
    FocusMode.pomodoro: Duration(minutes: 25),
    FocusMode.deepWork: Duration(minutes: 90),
    FocusMode.breakTime: Duration(minutes: 5),
    FocusMode.custom: Duration(minutes: 30),
  };

  /// Initialize focus service
  static Future<void> initialize() async {
    try {
      await _loadSessions();
      await _loadSettings();
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Get current session stream
  static Stream<FocusSession?> get sessionStream => _sessionController.stream;

  /// Get timer stream
  static Stream<Duration> get timerStream => _timerController.stream;

  /// Get current session
  static FocusSession? get currentSession => _currentSession;

  /// Get all sessions
  static List<FocusSession> get sessions => List.unmodifiable(_sessions);

  /// Get sessions for today
  static List<FocusSession> get todaySessions {
    final today = DateTime.now();
    return _sessions.where((session) =>
        session.startTime.year == today.year &&
        session.startTime.month == today.month &&
        session.startTime.day == today.day).toList();
  }

  /// Start a focus session
  static Future<FocusSession> startSession({
    required FocusMode mode,
    Duration? customDuration,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Stop any existing session
      if (_currentSession != null) {
        await stopSession();
      }

      final duration = customDuration ?? _defaultDurations[mode]!;
      final session = FocusSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mode: mode,
        duration: duration,
        startTime: DateTime.now(),
        status: FocusSessionStatus.running,
        metadata: metadata ?? {},
      );

      _currentSession = session;
      _totalPausedDuration = Duration.zero;
      _startTimer(duration);

      _sessionController.add(_currentSession);

      // Schedule notification for session completion
      final notificationService = NotificationService();
      await notificationService.scheduleNotification(
        id: session.id.hashCode,
        title: 'Focus Session Complete!',
        body: 'Your ${_getModeDisplayName(mode)} session is finished.',
        scheduledTime: DateTime.now().add(duration),
      );

      SentryService.addBreadcrumb(
        message: 'focus_session_started',
        category: 'focus',
        data: {
          'session_id': session.id,
          'mode': mode.name,
          'duration_minutes': duration.inMinutes,
        },
      );

      return session;
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Pause current session
  static Future<void> pauseSession() async {
    if (_currentSession?.status != FocusSessionStatus.running) return;

    try {
      _focusTimer?.cancel();
      _pauseStartTime = DateTime.now();
      
      _currentSession = _currentSession!.copyWith(
        status: FocusSessionStatus.paused,
      );

      _sessionController.add(_currentSession);

      // Cancel scheduled notification
      final notificationService = NotificationService();
      await notificationService.cancelNotification(_currentSession!.id.hashCode);

      SentryService.addBreadcrumb(
        message: 'focus_session_paused',
        category: 'focus',
        data: {'session_id': _currentSession!.id},
      );
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Resume current session
  static Future<void> resumeSession() async {
    if (_currentSession?.status != FocusSessionStatus.paused) return;

    try {
      if (_pauseStartTime != null) {
        _totalPausedDuration += DateTime.now().difference(_pauseStartTime!);
        _pauseStartTime = null;
      }

      final elapsed = DateTime.now().difference(_currentSession!.startTime) - _totalPausedDuration;
      final remaining = _currentSession!.duration - elapsed;

      if (remaining.inSeconds > 0) {
        _currentSession = _currentSession!.copyWith(
          status: FocusSessionStatus.running,
          pausedDuration: _totalPausedDuration,
        );

        _startTimer(remaining);

        // Reschedule notification
        final notificationService = NotificationService();
        await notificationService.scheduleNotification(
          id: _currentSession!.id.hashCode,
          title: 'Focus Session Complete!',
          body: 'Your ${_getModeDisplayName(_currentSession!.mode)} session is finished.',
          scheduledTime: DateTime.now().add(remaining),
        );

        _sessionController.add(_currentSession);

        SentryService.addBreadcrumb(
          message: 'focus_session_resumed',
          category: 'focus',
          data: {'session_id': _currentSession!.id},
        );
      } else {
        await completeSession();
      }
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Stop current session
  static Future<void> stopSession() async {
    if (_currentSession == null) return;

    try {
      _focusTimer?.cancel();
      
      _currentSession = _currentSession!.copyWith(
        status: FocusSessionStatus.cancelled,
        endTime: DateTime.now(),
        pausedDuration: _totalPausedDuration,
      );

      _sessions.add(_currentSession!);
      await _saveSessions();

      // Cancel scheduled notification
      final notificationService = NotificationService();
      await notificationService.cancelNotification(_currentSession!.id.hashCode);

      SentryService.addBreadcrumb(
        message: 'focus_session_stopped',
        category: 'focus',
        data: {
          'session_id': _currentSession!.id,
          'duration_completed': _currentSession!.actualDuration.inMinutes,
        },
      );

      _currentSession = null;
      _totalPausedDuration = Duration.zero;
      _sessionController.add(null);
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Complete current session
  static Future<void> completeSession() async {
    if (_currentSession == null) return;

    try {
      _focusTimer?.cancel();
      
      _currentSession = _currentSession!.copyWith(
        status: FocusSessionStatus.completed,
        endTime: DateTime.now(),
        pausedDuration: _totalPausedDuration,
      );

      _sessions.add(_currentSession!);
      await _saveSessions();

      // Trigger completion haptic feedback
      HapticFeedback.heavyImpact();

      // Show completion notification
      final notificationService = NotificationService();
      await notificationService.showNotification(
        id: _currentSession!.id.hashCode + 1,
        title: 'Focus Session Complete! 🎉',
        body: 'Great job! You completed your ${_getModeDisplayName(_currentSession!.mode)} session.',
      );

      SentryService.addBreadcrumb(
        message: 'focus_session_completed',
        category: 'focus',
        data: {
          'session_id': _currentSession!.id,
          'mode': _currentSession!.mode.name,
          'duration_minutes': _currentSession!.duration.inMinutes,
        },
      );

      _currentSession = null;
      _totalPausedDuration = Duration.zero;
      _sessionController.add(null);
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Get focus statistics
  static Map<String, dynamic> getFocusStatistics({DateTime? startDate, DateTime? endDate}) {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, now.day - 7);
    final end = endDate ?? now;

    final periodSessions = _sessions.where((session) =>
        session.startTime.isAfter(start) && session.startTime.isBefore(end)).toList();

    if (periodSessions.isEmpty) {
      return {
        'totalSessions': 0,
        'completedSessions': 0,
        'totalFocusTime': Duration.zero,
        'averageSessionLength': Duration.zero,
        'completionRate': 0.0,
        'longestSession': Duration.zero,
        'modeBreakdown': <String, int>{},
        'dailyPattern': <String, int>{},
      };
    }

    final completedSessions = periodSessions.where((s) => s.status == FocusSessionStatus.completed).toList();
    final totalFocusTime = periodSessions.fold<Duration>(
      Duration.zero,
      (sum, session) => sum + session.actualDuration,
    );

    final averageSessionLength = Duration(
      seconds: totalFocusTime.inSeconds ~/ periodSessions.length,
    );

    final completionRate = completedSessions.length / periodSessions.length;

    final longestSession = periodSessions.fold<Duration>(
      Duration.zero,
      (longest, session) => session.actualDuration > longest ? session.actualDuration : longest,
    );

    final modeBreakdown = <String, int>{};
    final dailyPattern = <String, int>{};

    for (final session in periodSessions) {
      // Mode breakdown
      final modeName = _getModeDisplayName(session.mode);
      modeBreakdown[modeName] = (modeBreakdown[modeName] ?? 0) + 1;

      // Daily pattern
      final dayKey = '${session.startTime.year}-${session.startTime.month}-${session.startTime.day}';
      dailyPattern[dayKey] = (dailyPattern[dayKey] ?? 0) + 1;
    }

    return {
      'totalSessions': periodSessions.length,
      'completedSessions': completedSessions.length,
      'totalFocusTime': totalFocusTime,
      'averageSessionLength': averageSessionLength,
      'completionRate': completionRate,
      'longestSession': longestSession,
      'modeBreakdown': modeBreakdown,
      'dailyPattern': dailyPattern,
    };
  }

  /// Get remaining time for current session
  static Duration get remainingTime {
    if (_currentSession == null || _currentSession!.status != FocusSessionStatus.running) {
      return Duration.zero;
    }

    final elapsed = DateTime.now().difference(_currentSession!.startTime) - _totalPausedDuration;
    final remaining = _currentSession!.duration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Start internal timer
  static void _startTimer(Duration duration) {
    _focusTimer?.cancel();
    
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = remainingTime;
      _timerController.add(remaining);
      
      if (remaining.inSeconds <= 0) {
        timer.cancel();
        completeSession();
      }
    });
  }

  /// Get display name for focus mode
  static String _getModeDisplayName(FocusMode mode) {
    switch (mode) {
      case FocusMode.pomodoro:
        return 'Pomodoro';
      case FocusMode.deepWork:
        return 'Deep Work';
      case FocusMode.breakTime:
        return 'Break Time';
      case FocusMode.custom:
        return 'Custom';
    }
  }

  /// Load sessions from storage
  static Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString(_sessionsKey);
      
      if (sessionsJson != null) {
        final List<dynamic> sessionsList = jsonDecode(sessionsJson);
        _sessions = sessionsList.map((json) => FocusSession.fromJson(json)).toList();
      }
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Save sessions to storage
  static Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = jsonEncode(_sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_sessionsKey, sessionsJson);
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Load settings from storage
  static Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        // Load custom settings if needed
        jsonDecode(settingsJson);
        // Apply settings...
      }
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Dispose focus service
  static void dispose() {
    _focusTimer?.cancel();
    _sessionController.close();
    _timerController.close();
  }
}
