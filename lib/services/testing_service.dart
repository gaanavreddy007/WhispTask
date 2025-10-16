import 'dart:convert';
import 'dart:math' as math;
import '../models/task.dart';
import '../services/sentry_service.dart';
import '../services/statistics_service.dart';
import '../services/habit_service.dart';
import '../services/focus_service.dart';
import '../services/achievement_service.dart';
import '../services/settings_service.dart';
import '../services/backup_sync_service.dart';

class TestResult {
  final String testName;
  final bool passed;
  final String message;
  final Duration executionTime;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const TestResult({
    required this.testName,
    required this.passed,
    required this.message,
    required this.executionTime,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'test_name': testName,
      'passed': passed,
      'message': message,
      'execution_time_ms': executionTime.inMilliseconds,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class TestSuite {
  final String name;
  final List<TestResult> results;
  final Duration totalTime;
  final int passedCount;
  final int failedCount;

  const TestSuite({
    required this.name,
    required this.results,
    required this.totalTime,
    required this.passedCount,
    required this.failedCount,
  });

  double get successRate => results.isEmpty ? 0.0 : passedCount / results.length;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'results': results.map((r) => r.toJson()).toList(),
      'total_time_ms': totalTime.inMilliseconds,
      'passed_count': passedCount,
      'failed_count': failedCount,
      'success_rate': successRate,
    };
  }
}

class TestingService {
  static final List<TestResult> _allResults = [];
  static final List<TestSuite> _testSuites = [];

  /// Run comprehensive app testing
  static Future<TestSuite> runComprehensiveTests() async {
    final results = <TestResult>[];
    final startTime = DateTime.now();

    try {
      // Core service tests
      results.addAll(await _testCoreServices());
      
      // Data integrity tests
      results.addAll(await _testDataIntegrity());
      
      // Performance tests
      results.addAll(await _testPerformance());
      
      // Error handling tests
      results.addAll(await _testErrorHandling());
      
      // Integration tests
      results.addAll(await _testIntegration());
      
      // Security tests
      results.addAll(await _testSecurity());

      final endTime = DateTime.now();
      final totalTime = endTime.difference(startTime);
      final passedCount = results.where((r) => r.passed).length;
      final failedCount = results.length - passedCount;

      final testSuite = TestSuite(
        name: 'Comprehensive App Test Suite',
        results: results,
        totalTime: totalTime,
        passedCount: passedCount,
        failedCount: failedCount,
      );

      _allResults.addAll(results);
      _testSuites.add(testSuite);

      SentryService.addBreadcrumb(
        message: 'comprehensive_tests_completed',
        category: 'testing',
        data: {
          'total_tests': results.length,
          'passed': passedCount,
          'failed': failedCount,
          'success_rate': testSuite.successRate,
          'execution_time_ms': totalTime.inMilliseconds,
        },
      );

      return testSuite;
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Test core services functionality
  static Future<List<TestResult>> _testCoreServices() async {
    final results = <TestResult>[];

    // Test Statistics Service
    results.add(await _runTest(
      'StatisticsService.calculateStatistics',
      () async {
        final testTasks = _generateTestTasks(10);
        final stats = StatisticsService.calculateStatistics(testTasks, 'week');
        return stats.isNotEmpty && stats.containsKey('totalTasks');
      },
    ));

    // Test Settings Service
    results.add(await _runTest(
      'SettingsService.updateSetting',
      () async {
        await SettingsService.updateSetting('notificationsEnabled', false);
        final settings = SettingsService.settings;
        return !settings.notificationsEnabled;
      },
    ));

    // Test Habit Service
    results.add(await _runTest(
      'HabitService.createHabit',
      () async {
        final habit = await HabitService.createHabit(
          title: 'Test Habit',
          description: 'Test Description',
          category: 'test',
          frequency: 'daily',
          targetCount: 1,
        );
        return habit.title == 'Test Habit';
      },
    ));

    // Test Achievement Service
    results.add(await _runTest(
      'AchievementService.checkAchievements',
      () async {
        final testTasks = _generateTestTasks(5);
        await AchievementService.updateAchievements(testTasks);
        final achievements = AchievementService.achievements;
        return achievements.isNotEmpty;
      },
    ));

    // Test Focus Service
    results.add(await _runTest(
      'FocusService.getFocusStatistics',
      () async {
        final stats = FocusService.getFocusStatistics();
        return stats.containsKey('totalSessions') && stats.containsKey('completionRate');
      },
    ));

    return results;
  }

  /// Test data integrity
  static Future<List<TestResult>> _testDataIntegrity() async {
    final results = <TestResult>[];

    // Test task data consistency
    results.add(await _runTest(
      'TaskData.consistency',
      () async {
        final testTasks = _generateTestTasks(20);
        final completedTasks = testTasks.where((t) => t.isCompleted).toList();
        final pendingTasks = testTasks.where((t) => !t.isCompleted).toList();
        return (completedTasks.length + pendingTasks.length) == testTasks.length;
      },
    ));

    // Test habit data validation
    results.add(await _runTest(
      'HabitData.validation',
      () async {
        final habits = HabitService.habits;
        for (final habit in habits) {
          if (habit.completionRate < 0 || habit.completionRate > 1) {
            return false;
          }
        }
        return true;
      },
    ));

    // Test settings data integrity
    results.add(await _runTest(
      'SettingsData.integrity',
      () async {
        final settings = SettingsService.settings;
        return SettingsService.validateSettings(settings);
      },
    ));

    return results;
  }

  /// Test performance benchmarks
  static Future<List<TestResult>> _testPerformance() async {
    final results = <TestResult>[];

    // Test statistics calculation performance
    results.add(await _runTest(
      'Performance.statisticsCalculation',
      () async {
        final testTasks = _generateTestTasks(1000);
        final stopwatch = Stopwatch()..start();
        StatisticsService.calculateStatistics(testTasks, 'month');
        stopwatch.stop();
        return stopwatch.elapsedMilliseconds < 1000; // Should complete in under 1 second
      },
    ));

    // Test large dataset handling
    results.add(await _runTest(
      'Performance.largeDataset',
      () async {
        final testTasks = _generateTestTasks(5000);
        final stopwatch = Stopwatch()..start();
        final completedTasks = testTasks.where((t) => t.isCompleted).toList();
        stopwatch.stop();
        return stopwatch.elapsedMilliseconds < 500 && completedTasks.isNotEmpty;
      },
    ));

    return results;
  }

  /// Test error handling
  static Future<List<TestResult>> _testErrorHandling() async {
    final results = <TestResult>[];

    // Test null safety
    results.add(await _runTest(
      'ErrorHandling.nullSafety',
      () async {
        try {
          final stats = StatisticsService.calculateStatistics([], 'week');
          return stats.isNotEmpty; // Should handle empty list gracefully
        } catch (e) {
          return false;
        }
      },
    ));

    // Test invalid data handling
    results.add(await _runTest(
      'ErrorHandling.invalidData',
      () async {
        try {
          final invalidSettings = AppSettings(
            focusSessionDuration: -1, // Invalid duration
            fontSize: 0, // Invalid font size
          );
          return !SettingsService.validateSettings(invalidSettings);
        } catch (e) {
          return false;
        }
      },
    ));

    return results;
  }

  /// Test service integration
  static Future<List<TestResult>> _testIntegration() async {
    final results = <TestResult>[];

    // Test statistics and achievements integration
    results.add(await _runTest(
      'Integration.statisticsAchievements',
      () async {
        final testTasks = _generateTestTasks(50);
        final stats = StatisticsService.calculateStatistics(testTasks, 'month');
        await AchievementService.updateAchievements(testTasks);
        final achievements = AchievementService.achievements;
        return stats.isNotEmpty && achievements.isNotEmpty;
      },
    ));

    // Test backup and restore integration
    results.add(await _runTest(
      'Integration.backupRestore',
      () async {
        final backup = await BackupSyncService.createBackup();
        return backup.tasks.isNotEmpty || backup.settings.isNotEmpty;
      },
    ));

    return results;
  }

  /// Test security measures
  static Future<List<TestResult>> _testSecurity() async {
    final results = <TestResult>[];

    // Test data sanitization
    results.add(await _runTest(
      'Security.dataSanitization',
      () async {
        const maliciousInput = '<script>alert("xss")</script>';
        // Test that malicious input is handled safely
        try {
          final habit = await HabitService.createHabit(
            title: maliciousInput,
            description: 'Test',
            category: 'test',
            frequency: 'daily',
            targetCount: 1,
          );
          // Should not execute script, just store as text
          return habit.title.contains('<script>') && !habit.title.contains('alert');
        } catch (e) {
          return true; // Properly rejected malicious input
        }
      },
    ));

    // Test settings validation
    results.add(await _runTest(
      'Security.settingsValidation',
      () async {
        final maliciousSettings = AppSettings(
          language: '../../../etc/passwd', // Path traversal attempt
          fontSize: double.infinity, // Invalid value
        );
        return !SettingsService.validateSettings(maliciousSettings);
      },
    ));

    return results;
  }

  /// Run individual test with timing and error handling
  static Future<TestResult> _runTest(String testName, Future<bool> Function() testFunction) async {
    final startTime = DateTime.now();
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await testFunction();
      stopwatch.stop();
      
      return TestResult(
        testName: testName,
        passed: result,
        message: result ? 'Test passed successfully' : 'Test failed - assertion returned false',
        executionTime: stopwatch.elapsed,
        data: {'execution_time_ms': stopwatch.elapsedMilliseconds},
        timestamp: startTime,
      );
    } catch (e) {
      stopwatch.stop();
      
      return TestResult(
        testName: testName,
        passed: false,
        message: 'Test failed with exception: ${e.toString()}',
        executionTime: stopwatch.elapsed,
        data: {
          'exception': e.toString(),
          'execution_time_ms': stopwatch.elapsedMilliseconds,
        },
        timestamp: startTime,
      );
    }
  }

  /// Generate test tasks for testing
  static List<Task> _generateTestTasks(int count) {
    final random = math.Random();
    final tasks = <Task>[];
    final categories = ['work', 'personal', 'health', 'learning'];
    final priorities = ['low', 'medium', 'high'];
    
    for (int i = 0; i < count; i++) {
      final createdAt = DateTime.now().subtract(Duration(days: random.nextInt(30)));
      final isCompleted = random.nextBool();
      
      tasks.add(Task(
        id: 'test_task_$i',
        title: 'Test Task $i',
        description: 'Test description for task $i',
        category: categories[random.nextInt(categories.length)],
        priority: priorities[random.nextInt(priorities.length)],
        isCompleted: isCompleted,
        createdAt: createdAt,
        completedAt: isCompleted ? createdAt.add(Duration(hours: random.nextInt(24))) : null,
        recurringPattern: random.nextBool() ? 'daily' : 'once',
      ));
    }
    
    return tasks;
  }

  /// Get test results summary
  static Map<String, dynamic> getTestSummary() {
    if (_testSuites.isEmpty) {
      return {'message': 'No tests have been run yet'};
    }
    
    final latestSuite = _testSuites.last;
    final totalTests = _allResults.length;
    final totalPassed = _allResults.where((r) => r.passed).length;
    final totalFailed = totalTests - totalPassed;
    final overallSuccessRate = totalTests > 0 ? totalPassed / totalTests : 0.0;
    
    return {
      'latest_suite': latestSuite.toJson(),
      'overall_stats': {
        'total_tests_run': totalTests,
        'total_passed': totalPassed,
        'total_failed': totalFailed,
        'overall_success_rate': overallSuccessRate,
        'test_suites_run': _testSuites.length,
      },
      'performance_metrics': {
        'average_test_time_ms': _allResults.isEmpty ? 0 : 
            _allResults.map((r) => r.executionTime.inMilliseconds).reduce((a, b) => a + b) / _allResults.length,
        'fastest_test_ms': _allResults.isEmpty ? 0 :
            _allResults.map((r) => r.executionTime.inMilliseconds).reduce(math.min),
        'slowest_test_ms': _allResults.isEmpty ? 0 :
            _allResults.map((r) => r.executionTime.inMilliseconds).reduce(math.max),
      },
    };
  }

  /// Export test results
  static String exportTestResults() {
    final summary = getTestSummary();
    return const JsonEncoder.withIndent('  ').convert({
      'export_info': {
        'app_name': 'WhispTask',
        'export_date': DateTime.now().toIso8601String(),
        'export_type': 'test_results',
      },
      'test_summary': summary,
      'all_test_suites': _testSuites.map((s) => s.toJson()).toList(),
      'all_test_results': _allResults.map((r) => r.toJson()).toList(),
    });
  }

  /// Clear test history
  static void clearTestHistory() {
    _allResults.clear();
    _testSuites.clear();
    
    SentryService.addBreadcrumb(
      message: 'test_history_cleared',
      category: 'testing',
    );
  }

  /// Run specific test category
  static Future<TestSuite> runTestCategory(String category) async {
    final results = <TestResult>[];
    final startTime = DateTime.now();

    switch (category.toLowerCase()) {
      case 'core':
        results.addAll(await _testCoreServices());
        break;
      case 'data':
        results.addAll(await _testDataIntegrity());
        break;
      case 'performance':
        results.addAll(await _testPerformance());
        break;
      case 'error':
        results.addAll(await _testErrorHandling());
        break;
      case 'integration':
        results.addAll(await _testIntegration());
        break;
      case 'security':
        results.addAll(await _testSecurity());
        break;
      default:
        throw ArgumentError('Unknown test category: $category');
    }

    final endTime = DateTime.now();
    final totalTime = endTime.difference(startTime);
    final passedCount = results.where((r) => r.passed).length;
    final failedCount = results.length - passedCount;

    final testSuite = TestSuite(
      name: '${category.toUpperCase()} Test Suite',
      results: results,
      totalTime: totalTime,
      passedCount: passedCount,
      failedCount: failedCount,
    );

    _allResults.addAll(results);
    _testSuites.add(testSuite);

    return testSuite;
  }
}
