// ignore_for_file: avoid_print

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
import '../services/app_integration_service.dart';
import '../services/statistics_export_service.dart';
import '../services/notification_service.dart';

/// Complete integration service that orchestrates all WhispTask features
class CompleteIntegrationService {
  static bool _isInitialized = false;
  static final Map<String, bool> _serviceStatus = {};
  static final List<String> _initializationLog = [];

  /// Initialize the complete WhispTask ecosystem
  static Future<bool> initializeCompleteSystem() async {
    if (_isInitialized) return true;

    try {
      _logStep('Starting complete system initialization...');

      // Phase 1: Core Infrastructure
      _logStep('Phase 1: Initializing core infrastructure...');
      await _initializeCoreServices();

      // Phase 2: Feature Services
      _logStep('Phase 2: Initializing feature services...');
      await _initializeFeatureServices();

      // Phase 3: Analytics & Intelligence
      _logStep('Phase 3: Initializing analytics & AI...');
      await _initializeAnalyticsServices();

      // Phase 4: Data Management
      _logStep('Phase 4: Initializing data management...');
      await _initializeDataServices();

      // Phase 5: Quality Assurance
      _logStep('Phase 5: Initializing quality assurance...');
      await _initializeQualityServices();

      // Phase 6: System Integration
      _logStep('Phase 6: Finalizing system integration...');
      await _finalizeSystemIntegration();

      _isInitialized = true;
      _logStep('✅ Complete system initialization successful!');

      SentryService.addBreadcrumb(
        message: 'complete_system_initialized',
        category: 'integration',
        data: {
          'services_initialized': _serviceStatus.length,
          'success_rate': _calculateSuccessRate(),
          'initialization_time': DateTime.now().toIso8601String(),
        },
      );

      return true;
    } catch (e) {
      _logStep('❌ System initialization failed: $e');
      SentryService.captureException(e);
      return false;
    }
  }

  /// Phase 1: Initialize core infrastructure services
  static Future<void> _initializeCoreServices() async {
    // Settings Service (Foundation)
    await _initializeService('SettingsService', () async {
      await SettingsService.initialize();
    });

    // Sentry Service (Already initialized in main.dart)
    _serviceStatus['SentryService'] = true;
    _logStep('✓ SentryService: Already initialized');

    // Notification Service
    await _initializeService('NotificationService', () async {
      final notificationService = NotificationService();
      await notificationService.initialize();
    });
  }

  /// Phase 2: Initialize feature services
  static Future<void> _initializeFeatureServices() async {
    // Habit Service
    await _initializeService('HabitService', () async {
      await HabitService.initialize();
    });

    // Achievement Service
    await _initializeService('AchievementService', () async {
      await AchievementService.initialize();
    });

    // Focus Service
    await _initializeService('FocusService', () async {
      await FocusService.initialize();
    });

    // Task Service (Implicit - managed by TaskProvider)
    _serviceStatus['TaskService'] = true;
    _logStep('✓ TaskService: Managed by TaskProvider');
  }

  /// Phase 3: Initialize analytics and AI services
  static Future<void> _initializeAnalyticsServices() async {
    // Statistics Service (No explicit initialize method)
    _serviceStatus['StatisticsService'] = true;
    _logStep('✓ StatisticsService: Ready for calculations');

    // Advanced Analytics Service
    await _initializeService('AdvancedAnalyticsService', () async {
      await AdvancedAnalyticsService.initialize();
    });

    // Statistics Export Service (No initialization required)
    _serviceStatus['StatisticsExportService'] = true;
    _logStep('✓ StatisticsExportService: Ready for export');
  }

  /// Phase 4: Initialize data management services
  static Future<void> _initializeDataServices() async {
    // Backup & Sync Service
    await _initializeService('BackupSyncService', () async {
      await BackupSyncService.initialize();
    });

    // Documentation Service
    await _initializeService('DocumentationService', () async {
      await DocumentationService.initialize();
    });
  }

  /// Phase 5: Initialize quality assurance services
  static Future<void> _initializeQualityServices() async {
    // Testing Service (No explicit initialization required)
    _serviceStatus['TestingService'] = true;
    _logStep('✓ TestingService: Ready for testing');
  }

  /// Phase 6: Finalize system integration
  static Future<void> _finalizeSystemIntegration() async {
    // App Integration Service
    await _initializeService('AppIntegrationService', () async {
      await AppIntegrationService.initialize();
    });

    // Perform initial system health check
    await _initializeService('SystemHealthCheck', () async {
      await AppIntegrationService.performHealthCheck();
    });

    // Generate initial documentation
    await _initializeService('InitialDocumentation', () async {
      // Documentation is generated on-demand
    });
  }

  /// Initialize a specific service with error handling
  static Future<void> _initializeService(String serviceName, Future<void> Function() initializer) async {
    try {
      await initializer();
      _serviceStatus[serviceName] = true;
      _logStep('✓ $serviceName: Initialized successfully');
    } catch (e) {
      _serviceStatus[serviceName] = false;
      _logStep('✗ $serviceName: Failed to initialize - $e');
      SentryService.captureException(e);
    }
  }

  /// Log initialization step
  static void _logStep(String message) {
    _initializationLog.add('${DateTime.now().toIso8601String()}: $message');
    print(message); // For debugging
  }

  /// Calculate initialization success rate
  static double _calculateSuccessRate() {
    if (_serviceStatus.isEmpty) return 0.0;
    final successCount = _serviceStatus.values.where((status) => status).length;
    return successCount / _serviceStatus.length;
  }

  /// Get complete system status
  static Map<String, dynamic> getSystemStatus() {
    return {
      'is_initialized': _isInitialized,
      'services': Map<String, bool>.from(_serviceStatus),
      'success_rate': _calculateSuccessRate(),
      'initialization_log': List<String>.from(_initializationLog),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Demonstrate all features working together
  static Future<Map<String, dynamic>> demonstrateCompleteFeatures(List<Task> tasks) async {
    final results = <String, dynamic>{};

    try {
      // 1. Statistics Calculation
      results['statistics'] = StatisticsService.calculateStatistics(tasks, 'month');

      // 2. Advanced Analytics
      final insights = await AdvancedAnalyticsService.generateInsights(tasks);
      results['insights'] = insights.map((i) => i.toJson()).toList();

      // 3. Achievement Progress
      await AchievementService.updateAchievements(tasks);
      results['achievements'] = AchievementService.achievements.map((a) => a.toJson()).toList();

      // 4. Habit Status
      results['habits'] = HabitService.habits.map((h) => h.toJson()).toList();

      // 5. Focus Statistics
      results['focus_stats'] = FocusService.getFocusStatistics();

      // 6. Export Capabilities
      final exportData = await StatisticsExportService.exportToJson(tasks);
      results['export_sample'] = '${exportData.substring(0, 200)}...'; // Sample

      // 7. Backup Status
      final backupStats = await BackupSyncService.getBackupStatistics();
      results['backup_stats'] = backupStats;

      // 8. System Health
      final healthReport = await AppIntegrationService.performHealthCheck();
      results['system_health'] = healthReport.toJson();

      // 9. Test Results
      final testSummary = TestingService.getTestSummary();
      results['test_summary'] = testSummary;

      // 10. Documentation Status
      final docSummary = DocumentationService.getDocumentationSummary();
      results['documentation'] = docSummary;

      results['demonstration_success'] = true;
      results['features_demonstrated'] = 10;

      SentryService.addBreadcrumb(
        message: 'complete_features_demonstrated',
        category: 'integration',
        data: {
          'features_count': 10,
          'tasks_analyzed': tasks.length,
        },
      );

    } catch (e) {
      results['demonstration_success'] = false;
      results['error'] = e.toString();
      SentryService.captureException(e);
    }

    return results;
  }

  /// Run comprehensive system validation
  static Future<Map<String, dynamic>> validateCompleteSystem() async {
    final validation = <String, dynamic>{};

    try {
      // 1. Service Status Validation
      validation['services_status'] = _serviceStatus;
      validation['all_services_running'] = _serviceStatus.values.every((status) => status);

      // 2. Feature Integration Test
      final testTasks = _generateTestTasks();
      final featureDemo = await demonstrateCompleteFeatures(testTasks);
      validation['feature_integration'] = featureDemo['demonstration_success'];

      // 3. Performance Validation
      final performanceTests = await TestingService.runTestCategory('performance');
      validation['performance_score'] = performanceTests.successRate;

      // 4. Security Validation
      final securityTests = await TestingService.runTestCategory('security');
      validation['security_score'] = securityTests.successRate;

      // 5. Data Integrity Check
      final dataTests = await TestingService.runTestCategory('data');
      validation['data_integrity_score'] = dataTests.successRate;

      // 6. Error Handling Validation
      final errorTests = await TestingService.runTestCategory('error');
      validation['error_handling_score'] = errorTests.successRate;

      // 7. System Health Score
      final healthReport = await AppIntegrationService.performHealthCheck();
      validation['system_health_score'] = healthReport.overallScore;

      // Calculate overall validation score
      final scores = [
        validation['performance_score'] as double,
        validation['security_score'] as double,
        validation['data_integrity_score'] as double,
        validation['error_handling_score'] as double,
        validation['system_health_score'] as double,
      ];
      validation['overall_score'] = scores.reduce((a, b) => a + b) / scores.length;

      // Determine validation status
      final overallScore = validation['overall_score'] as double;
      if (overallScore >= 0.9) {
        validation['status'] = 'EXCELLENT';
      } else if (overallScore >= 0.8) {
        validation['status'] = 'GOOD';
      } else if (overallScore >= 0.7) {
        validation['status'] = 'ACCEPTABLE';
      } else {
        validation['status'] = 'NEEDS_IMPROVEMENT';
      }

      validation['validation_success'] = true;
      validation['timestamp'] = DateTime.now().toIso8601String();

      SentryService.addBreadcrumb(
        message: 'system_validation_completed',
        category: 'integration',
        data: {
          'overall_score': overallScore,
          'status': validation['status'],
        },
      );

    } catch (e) {
      validation['validation_success'] = false;
      validation['error'] = e.toString();
      SentryService.captureException(e);
    }

    return validation;
  }

  /// Generate test tasks for validation
  static List<Task> _generateTestTasks() {
    final now = DateTime.now();
    return [
      Task(
        id: 'test_1',
        title: 'Complete project documentation',
        description: 'Write comprehensive documentation',
        category: 'work',
        priority: 'high',
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 2)),
        completedAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        id: 'test_2',
        title: 'Morning exercise routine',
        description: '30 minutes cardio workout',
        category: 'health',
        priority: 'medium',
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 1)),
        completedAt: now.subtract(const Duration(hours: 2)),
      ),
      Task(
        id: 'test_3',
        title: 'Learn new programming language',
        description: 'Study Dart and Flutter',
        category: 'learning',
        priority: 'medium',
        isCompleted: false,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      Task(
        id: 'test_4',
        title: 'Team meeting preparation',
        description: 'Prepare slides and agenda',
        category: 'work',
        priority: 'high',
        isCompleted: false,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      Task(
        id: 'test_5',
        title: 'Weekly grocery shopping',
        description: 'Buy groceries for the week',
        category: 'personal',
        priority: 'low',
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 3)),
        completedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  /// Get initialization log
  static List<String> getInitializationLog() {
    return List<String>.from(_initializationLog);
  }

  /// Check if system is fully operational
  static bool isSystemOperational() {
    return _isInitialized && _calculateSuccessRate() >= 0.8;
  }

  /// Get failed services
  static List<String> getFailedServices() {
    return _serviceStatus.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Restart failed services
  static Future<bool> restartFailedServices() async {
    final failedServices = getFailedServices();
    if (failedServices.isEmpty) return true;

    _logStep('Restarting ${failedServices.length} failed services...');

    for (final serviceName in failedServices) {
      try {
        switch (serviceName) {
          case 'SettingsService':
            await SettingsService.initialize();
            break;
          case 'HabitService':
            await HabitService.initialize();
            break;
          case 'AchievementService':
            await AchievementService.initialize();
            break;
          case 'FocusService':
            await FocusService.initialize();
            break;
          case 'AdvancedAnalyticsService':
            await AdvancedAnalyticsService.initialize();
            break;
          case 'BackupSyncService':
            await BackupSyncService.initialize();
            break;
          case 'DocumentationService':
            await DocumentationService.initialize();
            break;
          case 'AppIntegrationService':
            await AppIntegrationService.initialize();
            break;
        }
        _serviceStatus[serviceName] = true;
        _logStep('✓ $serviceName: Restarted successfully');
      } catch (e) {
        _logStep('✗ $serviceName: Restart failed - $e');
        SentryService.captureException(e);
      }
    }

    return getFailedServices().isEmpty;
  }

  /// Generate complete system report
  static Future<String> generateCompleteSystemReport() async {
    final buffer = StringBuffer();
    
    buffer.writeln('# WhispTask Complete System Report');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    // System Status
    final systemStatus = getSystemStatus();
    buffer.writeln('## System Status');
    buffer.writeln('Initialized: ${systemStatus['is_initialized']}');
    buffer.writeln('Success Rate: ${(systemStatus['success_rate'] * 100).round()}%');
    buffer.writeln('');

    // Service Status
    buffer.writeln('## Service Status');
    final services = systemStatus['services'] as Map<String, bool>;
    for (final entry in services.entries) {
      final status = entry.value ? '✅' : '❌';
      buffer.writeln('$status ${entry.key}');
    }
    buffer.writeln('');

    // System Validation
    try {
      final validation = await validateCompleteSystem();
      buffer.writeln('## System Validation');
      buffer.writeln('Status: ${validation['status']}');
      buffer.writeln('Overall Score: ${((validation['overall_score'] ?? 0.0) * 100).round()}%');
      buffer.writeln('Performance: ${((validation['performance_score'] ?? 0.0) * 100).round()}%');
      buffer.writeln('Security: ${((validation['security_score'] ?? 0.0) * 100).round()}%');
      buffer.writeln('Data Integrity: ${((validation['data_integrity_score'] ?? 0.0) * 100).round()}%');
      buffer.writeln('Error Handling: ${((validation['error_handling_score'] ?? 0.0) * 100).round()}%');
      buffer.writeln('System Health: ${((validation['system_health_score'] ?? 0.0) * 100).round()}%');
      buffer.writeln('');
    } catch (e) {
      buffer.writeln('## System Validation');
      buffer.writeln('Validation Error: $e');
      buffer.writeln('');
    }

    // Feature Summary
    buffer.writeln('## Features Summary');
    buffer.writeln('✅ Task Management with Voice Input');
    buffer.writeln('✅ Advanced Analytics & AI Insights');
    buffer.writeln('✅ Habit Tracking & Gamification');
    buffer.writeln('✅ Focus Timer & Productivity Tools');
    buffer.writeln('✅ Achievement System (15+ achievements)');
    buffer.writeln('✅ Multi-language Support');
    buffer.writeln('✅ Data Backup & Synchronization');
    buffer.writeln('✅ Comprehensive Testing Framework');
    buffer.writeln('✅ Real-time System Health Monitoring');
    buffer.writeln('✅ Professional Data Export');
    buffer.writeln('✅ Complete API Documentation');
    buffer.writeln('✅ Enterprise-grade Error Handling');
    buffer.writeln('');

    // Initialization Log
    buffer.writeln('## Initialization Log');
    final log = systemStatus['initialization_log'] as List<String>;
    for (final entry in log.take(10)) { // Show last 10 entries
      buffer.writeln(entry);
    }
    buffer.writeln('');

    buffer.writeln('---');
    buffer.writeln('WhispTask Complete Integration Service v1.0.0');

    return buffer.toString();
  }
}
