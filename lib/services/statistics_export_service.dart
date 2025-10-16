import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';
import '../services/statistics_service.dart';
import '../services/achievement_service.dart';
import '../services/habit_service.dart';
import '../services/focus_service.dart';
import '../services/sentry_service.dart';

class StatisticsExportService {
  /// Export comprehensive statistics to JSON
  static Future<String> exportToJson(List<Task> tasks) async {
    try {
      final weekStats = StatisticsService.calculateStatistics(tasks, 'week');
      final monthStats = StatisticsService.calculateStatistics(tasks, 'month');
      final yearStats = StatisticsService.calculateStatistics(tasks, 'year');
      
      final achievements = AchievementService.achievements;
      final habits = HabitService.habits;
      final focusStats = FocusService.getFocusStatistics();

      final exportData = {
        'export_info': {
          'app_name': 'WhispTask',
          'export_date': DateTime.now().toIso8601String(),
          'version': '1.0.0',
          'total_tasks': tasks.length,
        },
        'task_statistics': {
          'week': weekStats,
          'month': monthStats,
          'year': yearStats,
        },
        'achievements': {
          'total': achievements.length,
          'unlocked': achievements.where((a) => a.isUnlocked).length,
          'achievements': achievements.map((a) => {
            'id': a.id,
            'title': a.title,
            'description': a.description,
            'category': a.category,
            'is_unlocked': a.isUnlocked,
            'unlocked_at': a.unlockedAt?.toIso8601String(),
            'progress': a.progressPercentage,
          }).toList(),
        },
        'habits': {
          'total': habits.length,
          'active': habits.where((h) => h.isActive).length,
          'habits': habits.map((h) => {
            'id': h.id,
            'title': h.title,
            'category': h.category,
            'frequency': h.frequency,
            'current_streak': h.currentStreak,
            'completion_rate': h.completionRate,
            'is_active': h.isActive,
            'created_at': h.createdAt.toIso8601String(),
          }).toList(),
        },
        'focus_sessions': focusStats,
        'tasks': tasks.map((task) => {
          'id': task.id,
          'title': task.title,
          'description': task.description,
          'category': task.category,
          'priority': task.priority,
          'is_completed': task.isCompleted,
          'created_at': task.createdAt.toIso8601String(),
          'completed_at': task.completedAt?.toIso8601String(),
          'recurring_pattern': task.recurringPattern,
        }).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      SentryService.addBreadcrumb(
        message: 'statistics_exported_json',
        category: 'export',
        data: {
          'tasks_count': tasks.length,
          'achievements_count': achievements.length,
          'habits_count': habits.length,
        },
      );

      return jsonString;
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Export statistics to CSV format
  static Future<String> exportToCsv(List<Task> tasks) async {
    try {
      final buffer = StringBuffer();
      
      // CSV Header
      buffer.writeln('Task ID,Title,Description,Category,Priority,Status,Created Date,Completed Date,Recurring Pattern');
      
      // Task data
      for (final task in tasks) {
        final row = [
          _escapeCsvField(task.id ?? ''),
          _escapeCsvField(task.title),
          _escapeCsvField(task.description ?? ''),
          _escapeCsvField(task.category),
          _escapeCsvField(task.priority),
          task.isCompleted ? 'Completed' : 'Pending',
          task.createdAt.toIso8601String(),
          task.completedAt?.toIso8601String() ?? '',
          _escapeCsvField(task.recurringPattern ?? ''),
        ];
        buffer.writeln(row.join(','));
      }

      // Add summary statistics
      buffer.writeln('\n--- SUMMARY STATISTICS ---');
      final stats = StatisticsService.calculateStatistics(tasks, 'year');
      buffer.writeln('Total Tasks,${stats['totalTasks']}');
      buffer.writeln('Completed Tasks,${stats['completedTasks']}');
      buffer.writeln('Completion Rate,${stats['completionRate']}%');
      buffer.writeln('Average Per Day,${stats['averagePerDay'].toStringAsFixed(2)}');

      SentryService.addBreadcrumb(
        message: 'statistics_exported_csv',
        category: 'export',
        data: {'tasks_count': tasks.length},
      );

      return buffer.toString();
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Export statistics to readable text format
  static Future<String> exportToText(List<Task> tasks) async {
    try {
      final buffer = StringBuffer();
      final now = DateTime.now();
      
      buffer.writeln('=== WHISPTASK STATISTICS REPORT ===');
      buffer.writeln('Generated on: ${now.toLocal().toString()}');
      buffer.writeln('');
      
      // Overall Statistics
      final yearStats = StatisticsService.calculateStatistics(tasks, 'year');
      buffer.writeln('📊 OVERALL STATISTICS');
      buffer.writeln('Total Tasks: ${yearStats['totalTasks']}');
      buffer.writeln('Completed Tasks: ${yearStats['completedTasks']}');
      buffer.writeln('Pending Tasks: ${yearStats['pendingTasks']}');
      buffer.writeln('Completion Rate: ${yearStats['completionRate']}%');
      buffer.writeln('Average Tasks Per Day: ${yearStats['averagePerDay'].toStringAsFixed(2)}');
      buffer.writeln('');

      // Time Analysis
      final timeAnalysis = yearStats['timeAnalysis'] as Map<String, dynamic>;
      buffer.writeln('⏰ TIME ANALYSIS');
      buffer.writeln('Most Productive Hour: ${timeAnalysis['mostProductiveHour']}');
      buffer.writeln('Peak Productivity Day: ${timeAnalysis['peakProductivityDay']}');
      buffer.writeln('Average Completion Time: ${timeAnalysis['averageCompletionTime']}');
      buffer.writeln('Total Time Spent: ${timeAnalysis['totalTimeSpent']}');
      buffer.writeln('');

      // Streak Analysis
      final streakAnalysis = yearStats['streakAnalysis'] as Map<String, dynamic>;
      buffer.writeln('🔥 STREAK ANALYSIS');
      buffer.writeln('Current Streak: ${streakAnalysis['currentStreak']} days');
      buffer.writeln('Longest Streak: ${streakAnalysis['longestStreak']} days');
      buffer.writeln('Days with Tasks: ${streakAnalysis['daysWithTasks']}');
      buffer.writeln('');

      // Category Breakdown
      final categoryBreakdown = yearStats['categoryBreakdown'] as List<Map<String, dynamic>>;
      if (categoryBreakdown.isNotEmpty) {
        buffer.writeln('📂 CATEGORY BREAKDOWN');
        for (final category in categoryBreakdown) {
          buffer.writeln('${category['name']}: ${category['count']} tasks (${category['percentage']}%)');
        }
        buffer.writeln('');
      }

      // Achievements
      final achievements = AchievementService.achievements;
      final unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();
      buffer.writeln('🏆 ACHIEVEMENTS');
      buffer.writeln('Total Achievements: ${achievements.length}');
      buffer.writeln('Unlocked: ${unlockedAchievements.length}');
      buffer.writeln('Progress: ${((unlockedAchievements.length / achievements.length) * 100).round()}%');
      buffer.writeln('');

      if (unlockedAchievements.isNotEmpty) {
        buffer.writeln('Unlocked Achievements:');
        for (final achievement in unlockedAchievements) {
          buffer.writeln('• ${achievement.icon} ${achievement.title} - ${achievement.description}');
        }
        buffer.writeln('');
      }

      // Habits
      final habits = HabitService.habits;
      final activeHabits = habits.where((h) => h.isActive).toList();
      if (habits.isNotEmpty) {
        buffer.writeln('📈 HABITS');
        buffer.writeln('Total Habits: ${habits.length}');
        buffer.writeln('Active Habits: ${activeHabits.length}');
        buffer.writeln('');

        if (activeHabits.isNotEmpty) {
          buffer.writeln('Active Habits:');
          for (final habit in activeHabits) {
            buffer.writeln('• ${habit.title} (${habit.frequency}) - Streak: ${habit.currentStreak} days');
          }
          buffer.writeln('');
        }
      }

      // Focus Sessions
      final focusStats = FocusService.getFocusStatistics();
      buffer.writeln('🎯 FOCUS SESSIONS');
      buffer.writeln('Total Sessions: ${focusStats['totalSessions']}');
      buffer.writeln('Completed Sessions: ${focusStats['completedSessions']}');
      buffer.writeln('Completion Rate: ${(focusStats['completionRate'] * 100).round()}%');
      final totalFocusTime = focusStats['totalFocusTime'] as Duration;
      buffer.writeln('Total Focus Time: ${totalFocusTime.inHours}h ${totalFocusTime.inMinutes % 60}m');
      buffer.writeln('');

      buffer.writeln('=== END OF REPORT ===');

      SentryService.addBreadcrumb(
        message: 'statistics_exported_text',
        category: 'export',
        data: {'tasks_count': tasks.length},
      );

      return buffer.toString();
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Save statistics file to device
  static Future<String> saveStatistics(String content, String format) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'whisptask_statistics_$timestamp.$format';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(content);

      SentryService.addBreadcrumb(
        message: 'statistics_saved',
        category: 'export',
        data: {
          'format': format,
          'file_size': content.length,
          'file_path': file.path,
        },
      );

      return file.path;
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Copy statistics to clipboard
  static Future<void> copyToClipboard(String content) async {
    try {
      await Clipboard.setData(ClipboardData(text: content));
      
      SentryService.addBreadcrumb(
        message: 'statistics_copied_to_clipboard',
        category: 'export',
        data: {'content_length': content.length},
      );
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Helper method to escape CSV fields
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
