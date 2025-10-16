import 'dart:async';
import '../models/task.dart';
import '../services/sentry_service.dart';
import '../services/statistics_service.dart';
import '../services/achievement_service.dart';
import '../services/habit_service.dart';
import '../services/focus_service.dart';
import '../services/settings_service.dart';
import '../services/backup_sync_service.dart';
import '../services/advanced_analytics_service.dart';
import '../services/testing_service.dart';
import '../services/documentation_service.dart';
import '../services/notification_service.dart';

enum AppHealthStatus {
  excellent,
  good,
  warning,
  critical,
}

class AppHealthReport {
  final AppHealthStatus status;
  final double overallScore;
  final Map<String, double> serviceScores;
  final List<String> recommendations;
  final Map<String, dynamic> metrics;
  final DateTime timestamp;

  const AppHealthReport({
    required this.status,
    required this.overallScore,
    required this.serviceScores,
    required this.recommendations,
    required this.metrics,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'overall_score': overallScore,
      'service_scores': serviceScores,
      'recommendations': recommendations,
      'metrics': metrics,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class AppIntegrationService {
  static Timer? _healthCheckTimer;
  static AppHealthReport? _lastHealthReport;
  static final List<Function(AppHealthReport)> _healthListeners = [];

  /// Initialize complete app integration
  static Future<void> initialize() async {
    try {
      // Initialize all services in proper order
      await _initializeServices();
      
      // Start health monitoring
      _startHealthMonitoring();
      
      // Perform initial health check
      await performHealthCheck();

      SentryService.addBreadcrumb(
        message: 'app_integration_initialized',
        category: 'integration',
        data: {
          'services_initialized': 10,
          'health_monitoring': true,
        },
      );
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Initialize all services in dependency order
  static Future<void> _initializeServices() async {
    // Core services first
    await SettingsService.initialize();
    
    // Analytics services
    await AdvancedAnalyticsService.initialize();
    
    // Feature services
    await HabitService.initialize();
    await AchievementService.initialize();
    await FocusService.initialize();
    
    // Infrastructure services
    await BackupSyncService.initialize();
    await DocumentationService.initialize();
    
    // Notification service (depends on settings)
    final notificationService = NotificationService();
    await notificationService.initialize();
  }

  /// Start continuous health monitoring
  static void _startHealthMonitoring() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => performHealthCheck(),
    );
  }

  /// Perform comprehensive app health check
  static Future<AppHealthReport> performHealthCheck() async {
    try {
      final serviceScores = <String, double>{};
      final recommendations = <String>[];
      final metrics = <String, dynamic>{};

      // Check Settings Service
      final settingsScore = _checkSettingsHealth();
      serviceScores['settings'] = settingsScore;
      if (settingsScore < 0.8) {
        recommendations.add('Review and optimize app settings');
      }

      // Check Statistics Service
      final statsScore = _checkStatisticsHealth();
      serviceScores['statistics'] = statsScore;
      if (statsScore < 0.8) {
        recommendations.add('Update statistics calculations');
      }

      // Check Habit Service
      final habitScore = _checkHabitHealth();
      serviceScores['habits'] = habitScore;
      if (habitScore < 0.8) {
        recommendations.add('Review habit tracking consistency');
      }

      // Check Achievement Service
      final achievementScore = _checkAchievementHealth();
      serviceScores['achievements'] = achievementScore;
      if (achievementScore < 0.8) {
        recommendations.add('Update achievement progress');
      }

      // Check Focus Service
      final focusScore = _checkFocusHealth();
      serviceScores['focus'] = focusScore;
      if (focusScore < 0.8) {
        recommendations.add('Optimize focus session management');
      }

      // Check Backup Service
      final backupScore = _checkBackupHealth();
      serviceScores['backup'] = backupScore;
      if (backupScore < 0.8) {
        recommendations.add('Perform data backup');
      }

      // Calculate overall score
      final overallScore = serviceScores.values.isEmpty 
          ? 1.0 
          : serviceScores.values.reduce((a, b) => a + b) / serviceScores.length;

      // Determine health status
      AppHealthStatus status;
      if (overallScore >= 0.9) {
        status = AppHealthStatus.excellent;
      } else if (overallScore >= 0.8) {
        status = AppHealthStatus.good;
      } else if (overallScore >= 0.6) {
        status = AppHealthStatus.warning;
      } else {
        status = AppHealthStatus.critical;
      }

      // Collect metrics
      metrics['memory_usage'] = await _getMemoryUsage();
      metrics['storage_usage'] = await _getStorageUsage();
      metrics['last_backup'] = BackupSyncService.lastBackupTime?.toIso8601String();
      metrics['active_habits'] = HabitService.habits.where((h) => h.isActive).length;
      metrics['unlocked_achievements'] = AchievementService.achievements.where((a) => a.isUnlocked).length;

      final report = AppHealthReport(
        status: status,
        overallScore: overallScore,
        serviceScores: serviceScores,
        recommendations: recommendations,
        metrics: metrics,
        timestamp: DateTime.now(),
      );

      _lastHealthReport = report;
      _notifyHealthListeners(report);

      SentryService.addBreadcrumb(
        message: 'health_check_completed',
        category: 'integration',
        data: {
          'status': status.name,
          'overall_score': overallScore,
          'recommendations_count': recommendations.length,
        },
      );

      return report;
    } catch (e) {
      SentryService.captureException(e);
      
      // Return critical status on error
      final errorReport = AppHealthReport(
        status: AppHealthStatus.critical,
        overallScore: 0.0,
        serviceScores: {},
        recommendations: ['System error detected - check logs'],
        metrics: {'error': e.toString()},
        timestamp: DateTime.now(),
      );
      
      _lastHealthReport = errorReport;
      return errorReport;
    }
  }

  /// Check individual service health scores
  static double _checkSettingsHealth() {
    try {
      final settings = SettingsService.settings;
      return SettingsService.validateSettings(settings) ? 1.0 : 0.5;
    } catch (e) {
      return 0.0;
    }
  }

  static double _checkStatisticsHealth() {
    try {
      // Check if statistics can be calculated
      final testTasks = [
        Task(
          id: 'test',
          title: 'Test',
          isCompleted: true,
          createdAt: DateTime.now(),
        ),
      ];
      final stats = StatisticsService.calculateStatistics(testTasks, 'week');
      return stats.isNotEmpty ? 1.0 : 0.5;
    } catch (e) {
      return 0.0;
    }
  }

  static double _checkHabitHealth() {
    try {
      final habits = HabitService.habits;
      final activeHabits = habits.where((h) => h.isActive).length;
      return habits.isEmpty ? 1.0 : (activeHabits / habits.length);
    } catch (e) {
      return 0.0;
    }
  }

  static double _checkAchievementHealth() {
    try {
      final achievements = AchievementService.achievements;
      return achievements.isNotEmpty ? 1.0 : 0.8;
    } catch (e) {
      return 0.0;
    }
  }

  static double _checkFocusHealth() {
    try {
      final stats = FocusService.getFocusStatistics();
      return stats.isNotEmpty ? 1.0 : 0.8;
    } catch (e) {
      return 0.0;
    }
  }

  static double _checkBackupHealth() {
    try {
      final lastBackup = BackupSyncService.lastBackupTime;
      if (lastBackup == null) return 0.6;
      
      final daysSinceBackup = DateTime.now().difference(lastBackup).inDays;
      if (daysSinceBackup <= 1) return 1.0;
      if (daysSinceBackup <= 7) return 0.8;
      if (daysSinceBackup <= 30) return 0.6;
      return 0.4;
    } catch (e) {
      return 0.0;
    }
  }

  /// Optimize app performance
  static Future<void> optimizePerformance() async {
    try {
      // Auto backup if needed
      await BackupSyncService.autoBackupIfNeeded();
      
      // Clear old insights
      final insights = AdvancedAnalyticsService.insights;
      if (insights.length > 50) {
        await AdvancedAnalyticsService.clearInsights();
      }
      
      // Optimize settings
      final settings = SettingsService.settings;
      if (!SettingsService.validateSettings(settings)) {
        await SettingsService.resetSettings();
      }

      SentryService.addBreadcrumb(
        message: 'performance_optimized',
        category: 'integration',
      );
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Run comprehensive system diagnostics
  static Future<Map<String, dynamic>> runDiagnostics() async {
    try {
      final diagnostics = <String, dynamic>{};

      // Run health check
      final healthReport = await performHealthCheck();
      diagnostics['health_report'] = healthReport.toJson();

      // Run tests
      final testResults = await TestingService.runComprehensiveTests();
      diagnostics['test_results'] = testResults.toJson();

      // Get system metrics
      diagnostics['system_metrics'] = {
        'memory_usage': await _getMemoryUsage(),
        'storage_usage': await _getStorageUsage(),
        'app_version': '1.0.0',
        'platform': 'Flutter',
      };

      // Get service status
      diagnostics['service_status'] = {
        'settings_valid': SettingsService.validateSettings(SettingsService.settings),
        'habits_count': HabitService.habits.length,
        'achievements_unlocked': AchievementService.achievements.where((a) => a.isUnlocked).length,
        'last_backup': BackupSyncService.lastBackupTime?.toIso8601String(),
        'insights_count': AdvancedAnalyticsService.insights.length,
      };

      SentryService.addBreadcrumb(
        message: 'diagnostics_completed',
        category: 'integration',
        data: {
          'health_status': healthReport.status.name,
          'test_success_rate': testResults.successRate,
        },
      );

      return diagnostics;
    } catch (e) {
      SentryService.captureException(e);
      return {'error': e.toString()};
    }
  }

  /// Generate comprehensive system report
  static Future<String> generateSystemReport() async {
    try {
      final diagnostics = await runDiagnostics();
      final healthReport = _lastHealthReport;
      final docSummary = DocumentationService.getDocumentationSummary();

      final buffer = StringBuffer();
      buffer.writeln('# WhispTask System Report');
      buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
      buffer.writeln();

      // Health Status
      if (healthReport != null) {
        buffer.writeln('## System Health');
        buffer.writeln('Status: ${healthReport.status.name.toUpperCase()}');
        buffer.writeln('Overall Score: ${(healthReport.overallScore * 100).round()}%');
        buffer.writeln();

        buffer.writeln('### Service Scores');
        for (final entry in healthReport.serviceScores.entries) {
          buffer.writeln('- ${entry.key}: ${(entry.value * 100).round()}%');
        }
        buffer.writeln();

        if (healthReport.recommendations.isNotEmpty) {
          buffer.writeln('### Recommendations');
          for (final rec in healthReport.recommendations) {
            buffer.writeln('- $rec');
          }
          buffer.writeln();
        }
      }

      // Test Results
      final testResults = diagnostics['test_results'] as Map<String, dynamic>?;
      if (testResults != null) {
        buffer.writeln('## Test Results');
        buffer.writeln('Success Rate: ${((testResults['success_rate'] ?? 0.0) * 100).round()}%');
        buffer.writeln('Tests Passed: ${testResults['passed_count'] ?? 0}');
        buffer.writeln('Tests Failed: ${testResults['failed_count'] ?? 0}');
        buffer.writeln();
      }

      // System Metrics
      final metrics = diagnostics['system_metrics'] as Map<String, dynamic>?;
      if (metrics != null) {
        buffer.writeln('## System Metrics');
        buffer.writeln('Memory Usage: ${metrics['memory_usage'] ?? 'Unknown'}');
        buffer.writeln('Storage Usage: ${metrics['storage_usage'] ?? 'Unknown'}');
        buffer.writeln('App Version: ${metrics['app_version'] ?? 'Unknown'}');
        buffer.writeln();
      }

      // Service Status
      final serviceStatus = diagnostics['service_status'] as Map<String, dynamic>?;
      if (serviceStatus != null) {
        buffer.writeln('## Service Status');
        for (final entry in serviceStatus.entries) {
          buffer.writeln('- ${entry.key}: ${entry.value}');
        }
        buffer.writeln();
      }

      // Documentation Summary
      buffer.writeln('## Documentation');
      buffer.writeln('Services Documented: ${docSummary['services_documented']}');
      buffer.writeln('Total Methods: ${docSummary['total_methods']}');
      buffer.writeln('Last Updated: ${docSummary['last_updated']}');
      buffer.writeln();

      buffer.writeln('---');
      buffer.writeln('Report generated by WhispTask Integration Service');

      return buffer.toString();
    } catch (e) {
      SentryService.captureException(e);
      return 'Error generating system report: $e';
    }
  }

  /// Add health status listener
  static void addHealthListener(Function(AppHealthReport) listener) {
    _healthListeners.add(listener);
  }

  /// Remove health status listener
  static void removeHealthListener(Function(AppHealthReport) listener) {
    _healthListeners.remove(listener);
  }

  /// Notify health listeners
  static void _notifyHealthListeners(AppHealthReport report) {
    for (final listener in _healthListeners) {
      try {
        listener(report);
      } catch (e) {
        SentryService.captureException(e);
      }
    }
  }

  /// Get current health report
  static AppHealthReport? get currentHealthReport => _lastHealthReport;

  /// Emergency system recovery
  static Future<void> emergencyRecovery() async {
    try {
      SentryService.addBreadcrumb(
        message: 'emergency_recovery_initiated',
        category: 'integration',
      );

      // Reset settings to defaults
      await SettingsService.resetSettings();
      
      // Clear problematic data
      await AdvancedAnalyticsService.clearInsights();
      
      // Reinitialize services
      await _initializeServices();
      
      // Perform health check
      await performHealthCheck();

      SentryService.addBreadcrumb(
        message: 'emergency_recovery_completed',
        category: 'integration',
      );
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Cleanup resources
  static void dispose() {
    _healthCheckTimer?.cancel();
    _healthListeners.clear();
    
    SentryService.addBreadcrumb(
      message: 'app_integration_disposed',
      category: 'integration',
    );
  }

  // Helper methods for system metrics
  static Future<String> _getMemoryUsage() async {
    // Platform-specific memory usage would be implemented here
    return 'N/A';
  }

  static Future<String> _getStorageUsage() async {
    // Platform-specific storage usage would be implemented here
    return 'N/A';
  }
}
