import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/sentry_service.dart';
import '../services/notification_service.dart';

class Habit {
  final String id;
  final String title;
  final String description;
  final String category;
  final String frequency; // daily, weekly, monthly
  final int targetCount;
  final DateTime createdAt;
  final bool isActive;
  final List<DateTime> completedDates;
  final Map<String, dynamic> settings;

  Habit({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.frequency,
    required this.targetCount,
    required this.createdAt,
    this.isActive = true,
    this.completedDates = const [],
    this.settings = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'frequency': frequency,
      'targetCount': targetCount,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
      'settings': settings,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      frequency: json['frequency'],
      targetCount: json['targetCount'],
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'] ?? true,
      completedDates: (json['completedDates'] as List<dynamic>?)
          ?.map((d) => DateTime.parse(d))
          .toList() ?? [],
      settings: json['settings'] ?? {},
    );
  }

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? frequency,
    int? targetCount,
    DateTime? createdAt,
    bool? isActive,
    List<DateTime>? completedDates,
    Map<String, dynamic>? settings,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      targetCount: targetCount ?? this.targetCount,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      completedDates: completedDates ?? this.completedDates,
      settings: settings ?? this.settings,
    );
  }

  // Calculate current streak
  int get currentStreak {
    if (completedDates.isEmpty) return 0;
    
    final sortedDates = List<DateTime>.from(completedDates)
      ..sort((a, b) => b.compareTo(a));
    
    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    for (final date in sortedDates) {
      if (_isSameDay(date, currentDate) || 
          _isSameDay(date, currentDate.subtract(Duration(days: streak)))) {
        streak++;
        currentDate = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  // Calculate completion rate for current period
  double get completionRate {
    final now = DateTime.now();
    DateTime periodStart;
    
    switch (frequency) {
      case 'daily':
        periodStart = DateTime(now.year, now.month, now.day - 7);
        break;
      case 'weekly':
        periodStart = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'monthly':
        periodStart = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        periodStart = DateTime(now.year, now.month, now.day - 7);
    }
    
    final periodCompletions = completedDates
        .where((date) => date.isAfter(periodStart))
        .length;
    
    final expectedCompletions = _calculateExpectedCompletions(periodStart, now);
    
    if (expectedCompletions == 0) return 0.0;
    return (periodCompletions / expectedCompletions).clamp(0.0, 1.0);
  }

  int _calculateExpectedCompletions(DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    
    switch (frequency) {
      case 'daily':
        return days;
      case 'weekly':
        return (days / 7).ceil();
      case 'monthly':
        return (days / 30).ceil();
      default:
        return days;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // Check if habit is due today
  bool get isDueToday {
    final today = DateTime.now();
    final lastCompletion = completedDates.isNotEmpty
        ? completedDates.reduce((a, b) => a.isAfter(b) ? a : b)
        : null;
    
    if (lastCompletion == null) return true;
    
    switch (frequency) {
      case 'daily':
        return !_isSameDay(lastCompletion, today);
      case 'weekly':
        return today.difference(lastCompletion).inDays >= 7;
      case 'monthly':
        return today.difference(lastCompletion).inDays >= 30;
      default:
        return true;
    }
  }
}

class HabitService {
  static const String _habitsKey = 'user_habits';
  static List<Habit> _habits = [];

  /// Initialize habit service
  static Future<void> initialize() async {
    try {
      await _loadHabits();
    } catch (e) {
      SentryService.captureException(e);
      _habits = [];
    }
  }

  /// Get all habits
  static List<Habit> get habits => List.unmodifiable(_habits);

  /// Get active habits
  static List<Habit> get activeHabits => 
      _habits.where((h) => h.isActive).toList();

  /// Get habits by category
  static List<Habit> getHabitsByCategory(String category) =>
      _habits.where((h) => h.category == category).toList();

  /// Create a new habit
  static Future<Habit> createHabit({
    required String title,
    required String description,
    required String category,
    required String frequency,
    required int targetCount,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final habit = Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        category: category,
        frequency: frequency,
        targetCount: targetCount,
        createdAt: DateTime.now(),
        settings: settings ?? {},
      );

      _habits.add(habit);
      await _saveHabits();

      SentryService.addBreadcrumb(
        message: 'habit_created',
        category: 'habit',
        data: {
          'habit_id': habit.id,
          'category': category,
          'frequency': frequency,
        },
      );

      // Schedule habit reminders
      await _scheduleHabitReminders(habit);

      return habit;
    } catch (e) {
      SentryService.captureException(e);
      rethrow;
    }
  }

  /// Update a habit
  static Future<void> updateHabit(Habit updatedHabit) async {
    try {
      final index = _habits.indexWhere((h) => h.id == updatedHabit.id);
      if (index != -1) {
        _habits[index] = updatedHabit;
        await _saveHabits();

        SentryService.addBreadcrumb(
          message: 'habit_updated',
          category: 'habit',
          data: {'habit_id': updatedHabit.id},
        );
      }
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Mark habit as completed for today
  static Future<void> completeHabit(String habitId) async {
    try {
      final habitIndex = _habits.indexWhere((h) => h.id == habitId);
      if (habitIndex == -1) return;

      final habit = _habits[habitIndex];
      final today = DateTime.now();
      
      // Check if already completed today
      if (habit.completedDates.any((date) => 
          date.year == today.year && 
          date.month == today.month && 
          date.day == today.day)) {
        return; // Already completed today
      }

      final updatedCompletedDates = List<DateTime>.from(habit.completedDates)
        ..add(today);

      _habits[habitIndex] = habit.copyWith(
        completedDates: updatedCompletedDates,
      );

      await _saveHabits();

      // Send completion celebration notification
      await _sendCompletionNotification(_habits[habitIndex]);

      SentryService.addBreadcrumb(
        message: 'habit_completed',
        category: 'habit',
        data: {
          'habit_id': habitId,
          'completion_date': today.toIso8601String(),
          'streak': _habits[habitIndex].currentStreak,
        },
      );
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Delete a habit
  static Future<void> deleteHabit(String habitId) async {
    try {
      // Cancel reminders before deleting
      await _cancelHabitReminders(habitId);
      
      _habits.removeWhere((h) => h.id == habitId);
      await _saveHabits();

      SentryService.addBreadcrumb(
        message: 'habit_deleted',
        category: 'habit',
        data: {'habit_id': habitId},
      );
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Get habit statistics
  static Map<String, dynamic> getHabitStatistics() {
    final activeHabits = _habits.where((h) => h.isActive).toList();
    
    if (activeHabits.isEmpty) {
      return {
        'totalHabits': 0,
        'activeHabits': 0,
        'completedToday': 0,
        'averageStreak': 0.0,
        'completionRate': 0.0,
        'categoryBreakdown': <String, int>{},
      };
    }

    final today = DateTime.now();
    final completedToday = activeHabits.where((habit) =>
        habit.completedDates.any((date) =>
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day)).length;

    final totalStreak = activeHabits.fold<int>(0, (sum, habit) => sum + habit.currentStreak);
    final averageStreak = totalStreak / activeHabits.length;

    final totalCompletionRate = activeHabits.fold<double>(0.0, (sum, habit) => sum + habit.completionRate);
    final averageCompletionRate = totalCompletionRate / activeHabits.length;

    final categoryBreakdown = <String, int>{};
    for (final habit in activeHabits) {
      categoryBreakdown[habit.category] = (categoryBreakdown[habit.category] ?? 0) + 1;
    }

    return {
      'totalHabits': _habits.length,
      'activeHabits': activeHabits.length,
      'completedToday': completedToday,
      'averageStreak': averageStreak,
      'completionRate': averageCompletionRate,
      'categoryBreakdown': categoryBreakdown,
    };
  }

  /// Get habits due today
  static List<Habit> getHabitsDueToday() {
    return activeHabits.where((habit) => habit.isDueToday).toList();
  }

  /// Create habit from recurring task
  static Future<Habit?> createHabitFromTask(Task task) async {
    if (task.recurringPattern == null || task.recurringPattern == 'once') {
      return null;
    }

    try {
      final frequency = _mapRecurringPatternToFrequency(task.recurringPattern!);
      
      return await createHabit(
        title: task.title,
        description: task.description ?? '',
        category: task.category,
        frequency: frequency,
        targetCount: 1,
        settings: {
          'source': 'task',
          'taskId': task.id,
          'priority': task.priority,
        },
      );
    } catch (e) {
      SentryService.captureException(e);
      return null;
    }
  }

  /// Map recurring pattern to habit frequency
  static String _mapRecurringPatternToFrequency(String recurringPattern) {
    switch (recurringPattern.toLowerCase()) {
      case 'daily':
        return 'daily';
      case 'weekly':
        return 'weekly';
      case 'monthly':
        return 'monthly';
      default:
        return 'daily';
    }
  }

  /// Get habit templates
  static List<Map<String, dynamic>> getHabitTemplates() {
    return [
      {
        'title': 'Drink Water',
        'description': 'Stay hydrated throughout the day',
        'category': 'health',
        'frequency': 'daily',
        'targetCount': 8,
        'icon': '💧',
      },
      {
        'title': 'Exercise',
        'description': 'Get your body moving',
        'category': 'health',
        'frequency': 'daily',
        'targetCount': 1,
        'icon': '🏃',
      },
      {
        'title': 'Read',
        'description': 'Read for personal growth',
        'category': 'learning',
        'frequency': 'daily',
        'targetCount': 1,
        'icon': '📚',
      },
      {
        'title': 'Meditate',
        'description': 'Practice mindfulness',
        'category': 'wellness',
        'frequency': 'daily',
        'targetCount': 1,
        'icon': '🧘',
      },
      {
        'title': 'Journal',
        'description': 'Reflect on your day',
        'category': 'wellness',
        'frequency': 'daily',
        'targetCount': 1,
        'icon': '📝',
      },
      {
        'title': 'Call Family',
        'description': 'Stay connected with loved ones',
        'category': 'social',
        'frequency': 'weekly',
        'targetCount': 1,
        'icon': '📞',
      },
    ];
  }

  /// Load habits from storage
  static Future<void> _loadHabits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final habitsJson = prefs.getString(_habitsKey);
      
      if (habitsJson != null) {
        final List<dynamic> habitsList = jsonDecode(habitsJson);
        _habits = habitsList.map((json) => Habit.fromJson(json)).toList();
      }
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Save habits to storage
  static Future<void> _saveHabits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final habitsJson = jsonEncode(_habits.map((h) => h.toJson()).toList());
      await prefs.setString(_habitsKey, habitsJson);
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Schedule habit reminders based on frequency
  static Future<void> _scheduleHabitReminders(Habit habit) async {
    try {
      final notificationService = NotificationService();
      final now = DateTime.now();
      
      switch (habit.frequency) {
        case 'daily':
          // Schedule daily reminder at 9 AM
          final reminderTime = DateTime(now.year, now.month, now.day, 9, 0);
          final nextReminder = reminderTime.isBefore(now) 
              ? reminderTime.add(const Duration(days: 1))
              : reminderTime;
          
          await notificationService.scheduleNotification(
            id: habit.id.hashCode,
            title: 'Daily Habit Reminder',
            body: 'Time to work on: ${habit.title}',
            scheduledTime: nextReminder,
          );
          break;
          
        case 'weekly':
          // Schedule weekly reminder on Mondays at 9 AM
          final daysUntilMonday = (DateTime.monday - now.weekday) % 7;
          final nextMonday = now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
          final reminderTime = DateTime(nextMonday.year, nextMonday.month, nextMonday.day, 9, 0);
          
          await notificationService.scheduleNotification(
            id: habit.id.hashCode,
            title: 'Weekly Habit Reminder',
            body: 'Time to work on: ${habit.title}',
            scheduledTime: reminderTime,
          );
          break;
          
        case 'monthly':
          // Schedule monthly reminder on the 1st at 9 AM
          final nextMonth = DateTime(now.year, now.month + 1, 1, 9, 0);
          
          await notificationService.scheduleNotification(
            id: habit.id.hashCode,
            title: 'Monthly Habit Reminder',
            body: 'Time to work on: ${habit.title}',
            scheduledTime: nextMonth,
          );
          break;
      }

      SentryService.addBreadcrumb(
        message: 'habit_reminders_scheduled',
        category: 'habit',
        data: {
          'habit_id': habit.id,
          'frequency': habit.frequency,
        },
      );
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Cancel habit reminders
  static Future<void> _cancelHabitReminders(String habitId) async {
    try {
      final notificationService = NotificationService();
      await notificationService.cancelNotification(habitId.hashCode);
      
      SentryService.addBreadcrumb(
        message: 'habit_reminders_cancelled',
        category: 'habit',
        data: {'habit_id': habitId},
      );
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Send habit completion celebration notification
  static Future<void> _sendCompletionNotification(Habit habit) async {
    try {
      final notificationService = NotificationService();
      
      String celebrationMessage;
      switch (habit.frequency) {
        case 'daily':
          celebrationMessage = 'Great job! You completed your daily habit: ${habit.title} 🎉';
          break;
        case 'weekly':
          celebrationMessage = 'Awesome! You completed your weekly habit: ${habit.title} 🌟';
          break;
        case 'monthly':
          celebrationMessage = 'Amazing! You completed your monthly habit: ${habit.title} 👑';
          break;
        default:
          celebrationMessage = 'Well done! You completed: ${habit.title} ✅';
      }
      
      await notificationService.showNotification(
        id: habit.id.hashCode + 1000, // Different ID for completion notifications
        title: 'Habit Completed!',
        body: celebrationMessage,
      );

      SentryService.addBreadcrumb(
        message: 'habit_completion_notification_sent',
        category: 'habit',
        data: {'habit_id': habit.id},
      );
    } catch (e) {
      SentryService.captureException(e);
    }
  }
}
