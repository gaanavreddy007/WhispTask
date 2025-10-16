import '../services/achievement_service.dart';
import '../services/habit_service.dart';
import '../services/focus_service.dart';
import '../services/statistics_service.dart';
import '../services/sentry_service.dart';
import '../providers/task_provider.dart';

class AppInitializationService {
  static bool _isInitialized = false;

  /// Initialize all app services
  static Future<void> initializeServices() async {
    if (_isInitialized) return;

    try {
      // Initialize core services
      await AchievementService.initialize();
      await HabitService.initialize();
      await FocusService.initialize();

      _isInitialized = true;

      SentryService.addBreadcrumb(
        message: 'app_services_initialized',
        category: 'initialization',
        data: {
          'achievement_service': 'initialized',
          'habit_service': 'initialized',
          'focus_service': 'initialized',
        },
      );
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Update all services with current task data
  static Future<void> updateServicesWithTasks(TaskProvider taskProvider) async {
    if (!_isInitialized) {
      await initializeServices();
    }

    try {
      final tasks = taskProvider.tasks;

      // Update achievements based on task data
      final newAchievements = await AchievementService.updateAchievements(tasks);
      
      if (newAchievements.isNotEmpty) {
        SentryService.addBreadcrumb(
          message: 'achievements_unlocked',
          category: 'achievement',
          data: {
            'count': newAchievements.length,
            'achievements': newAchievements.map((a) => a.title).toList(),
          },
        );
      }

      // Create habits from recurring tasks
      for (final task in tasks) {
        if (task.recurringPattern != null && task.recurringPattern != 'once') {
          await HabitService.createHabitFromTask(task);
        }
      }

    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Check if services are initialized
  static bool get isInitialized => _isInitialized;

  /// Dispose all services
  static void dispose() {
    FocusService.dispose();
    _isInitialized = false;
  }
}
