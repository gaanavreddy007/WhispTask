import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/sentry_service.dart';
import '../services/statistics_service.dart';
import '../services/notification_service.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int targetValue;
  final String category;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int currentProgress;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.targetValue,
    required this.category,
    this.isUnlocked = false,
    this.unlockedAt,
    this.currentProgress = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'targetValue': targetValue,
      'category': category,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'currentProgress': currentProgress,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      targetValue: json['targetValue'],
      category: json['category'],
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt']) 
          : null,
      currentProgress: json['currentProgress'] ?? 0,
    );
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    int? targetValue,
    String? category,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? currentProgress,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      targetValue: targetValue ?? this.targetValue,
      category: category ?? this.category,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      currentProgress: currentProgress ?? this.currentProgress,
    );
  }

  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }
}

class AchievementService {
  static const String _achievementsKey = 'user_achievements';
  static List<Achievement> _achievements = [];
  static final List<Achievement> _recentlyUnlocked = [];

  /// Initialize achievement system with default achievements
  static Future<void> initialize() async {
    try {
      await _loadAchievements();
      if (_achievements.isEmpty) {
        _achievements = _getDefaultAchievements();
        await _saveAchievements();
      }
    } catch (e) {
      SentryService.captureException(e);
      _achievements = _getDefaultAchievements();
    }
  }

  /// Get all achievements
  static List<Achievement> get achievements => List.unmodifiable(_achievements);

  /// Get recently unlocked achievements
  static List<Achievement> get recentlyUnlocked => List.unmodifiable(_recentlyUnlocked);

  /// Update achievements based on current task data
  static Future<List<Achievement>> updateAchievements(List<Task> tasks) async {
    try {
      final stats = StatisticsService.calculateStatistics(tasks, 'year');
      final newlyUnlocked = <Achievement>[];

      for (int i = 0; i < _achievements.length; i++) {
        final achievement = _achievements[i];
        if (achievement.isUnlocked) continue;

        final newProgress = _calculateProgress(achievement, stats, tasks);
        final updatedAchievement = achievement.copyWith(currentProgress: newProgress);

        if (newProgress >= achievement.targetValue) {
          final unlockedAchievement = updatedAchievement.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          );
          _achievements[i] = unlockedAchievement;
          newlyUnlocked.add(unlockedAchievement);
          _recentlyUnlocked.add(unlockedAchievement);
        } else {
          _achievements[i] = updatedAchievement;
        }
      }

      if (newlyUnlocked.isNotEmpty) {
        await _saveAchievements();
        
        // Track achievement unlocks and send notifications
        for (final achievement in newlyUnlocked) {
          await _sendAchievementUnlockedNotification(achievement);
          
          SentryService.addBreadcrumb(
            message: 'achievement_unlocked',
            category: 'achievement',
            data: {
              'achievement_id': achievement.id,
              'achievement_title': achievement.title,
              'category': achievement.category,
            },
          );
        }
      }

      return newlyUnlocked;
    } catch (e) {
      SentryService.captureException(e);
      return [];
    }
  }

  /// Calculate progress for a specific achievement
  static int _calculateProgress(Achievement achievement, Map<String, dynamic> stats, List<Task> tasks) {
    switch (achievement.id) {
      case 'first_task':
        return stats['totalTasks'] as int? ?? 0;
      
      case 'task_master_10':
        return stats['completedTasks'] as int? ?? 0;
      
      case 'task_master_50':
        return stats['completedTasks'] as int? ?? 0;
      
      case 'task_master_100':
        return stats['completedTasks'] as int? ?? 0;
      
      case 'streak_warrior_3':
        final streakAnalysis = stats['streakAnalysis'] as Map<String, dynamic>? ?? {};
        return streakAnalysis['longestStreak'] as int? ?? 0;
      
      case 'streak_warrior_7':
        final streakAnalysis = stats['streakAnalysis'] as Map<String, dynamic>? ?? {};
        return streakAnalysis['longestStreak'] as int? ?? 0;
      
      case 'streak_warrior_30':
        final streakAnalysis = stats['streakAnalysis'] as Map<String, dynamic>? ?? {};
        return streakAnalysis['longestStreak'] as int? ?? 0;
      
      case 'early_bird':
        return _countEarlyTasks(tasks);
      
      case 'night_owl':
        return _countLateTasks(tasks);
      
      case 'perfectionist':
        final completionRate = stats['completionRate'] as int? ?? 0;
        return completionRate >= 100 ? 1 : 0;
      
      case 'category_explorer':
        final categoryBreakdown = stats['categoryBreakdown'] as List<Map<String, dynamic>>? ?? [];
        return categoryBreakdown.length;
      
      case 'voice_champion_10':
        return _countVoiceTasks(tasks);
      
      case 'voice_champion_50':
        return _countVoiceTasks(tasks);
      
      case 'productivity_guru':
        final averagePerDay = (stats['averagePerDay'] as double? ?? 0.0);
        return averagePerDay >= 5.0 ? 1 : 0;
      
      default:
        return 0;
    }
  }

  /// Count tasks created before 9 AM
  static int _countEarlyTasks(List<Task> tasks) {
    return tasks.where((task) {
      final createdAt = task.createdAt;
      return createdAt.hour < 9;
    }).length;
  }

  /// Count tasks created after 9 PM
  static int _countLateTasks(List<Task> tasks) {
    return tasks.where((task) {
      final createdAt = task.createdAt;
      return createdAt.hour >= 21;
    }).length;
  }

  /// Count tasks created via voice (mock implementation)
  static int _countVoiceTasks(List<Task> tasks) {
    // In a real implementation, you'd track which tasks were created via voice
    // For now, we'll estimate based on task titles containing voice-like patterns
    return tasks.where((task) {
      final title = task.title.toLowerCase();
      return title.contains('remind') || 
             title.contains('call') || 
             title.contains('meeting') ||
             title.length < 20; // Short titles might indicate voice input
    }).length;
  }

  /// Get achievements by category
  static List<Achievement> getAchievementsByCategory(String category) {
    return _achievements.where((a) => a.category == category).toList();
  }

  /// Get unlocked achievements
  static List<Achievement> getUnlockedAchievements() {
    return _achievements.where((a) => a.isUnlocked).toList();
  }

  /// Get locked achievements
  static List<Achievement> getLockedAchievements() {
    return _achievements.where((a) => !a.isUnlocked).toList();
  }

  /// Clear recently unlocked achievements
  static void clearRecentlyUnlocked() {
    _recentlyUnlocked.clear();
  }

  /// Load achievements from storage
  static Future<void> _loadAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString(_achievementsKey);
      
      if (achievementsJson != null) {
        final List<dynamic> achievementsList = jsonDecode(achievementsJson);
        _achievements = achievementsList
            .map((json) => Achievement.fromJson(json))
            .toList();
      }
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Save achievements to storage
  static Future<void> _saveAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = jsonEncode(
        _achievements.map((a) => a.toJson()).toList()
      );
      await prefs.setString(_achievementsKey, achievementsJson);
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Get default achievements
  static List<Achievement> _getDefaultAchievements() {
    return [
      // Task Master Category
      Achievement(
        id: 'first_task',
        title: 'First Step',
        description: 'Create your first task',
        icon: '🎯',
        targetValue: 1,
        category: 'task_master',
      ),
      Achievement(
        id: 'task_master_10',
        title: 'Getting Started',
        description: 'Complete 10 tasks',
        icon: '✅',
        targetValue: 10,
        category: 'task_master',
      ),
      Achievement(
        id: 'task_master_50',
        title: 'Task Warrior',
        description: 'Complete 50 tasks',
        icon: '⚔️',
        targetValue: 50,
        category: 'task_master',
      ),
      Achievement(
        id: 'task_master_100',
        title: 'Century Club',
        description: 'Complete 100 tasks',
        icon: '💯',
        targetValue: 100,
        category: 'task_master',
      ),

      // Streak Warrior Category
      Achievement(
        id: 'streak_warrior_3',
        title: 'Three in a Row',
        description: 'Maintain a 3-day streak',
        icon: '🔥',
        targetValue: 3,
        category: 'streak_warrior',
      ),
      Achievement(
        id: 'streak_warrior_7',
        title: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        icon: '🌟',
        targetValue: 7,
        category: 'streak_warrior',
      ),
      Achievement(
        id: 'streak_warrior_30',
        title: 'Monthly Master',
        description: 'Maintain a 30-day streak',
        icon: '👑',
        targetValue: 30,
        category: 'streak_warrior',
      ),

      // Early Bird Category
      Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Create 10 tasks before 9 AM',
        icon: '🌅',
        targetValue: 10,
        category: 'early_bird',
      ),
      Achievement(
        id: 'night_owl',
        title: 'Night Owl',
        description: 'Create 10 tasks after 9 PM',
        icon: '🦉',
        targetValue: 10,
        category: 'early_bird',
      ),

      // Voice Champion Category
      Achievement(
        id: 'voice_champion_10',
        title: 'Voice Novice',
        description: 'Create 10 tasks using voice',
        icon: '🎤',
        targetValue: 10,
        category: 'voice_champion',
      ),
      Achievement(
        id: 'voice_champion_50',
        title: 'Voice Master',
        description: 'Create 50 tasks using voice',
        icon: '🎙️',
        targetValue: 50,
        category: 'voice_champion',
      ),

      // Special Achievements
      Achievement(
        id: 'perfectionist',
        title: 'Perfectionist',
        description: 'Achieve 100% completion rate',
        icon: '💎',
        targetValue: 1,
        category: 'special',
      ),
      Achievement(
        id: 'category_explorer',
        title: 'Category Explorer',
        description: 'Use 5 different categories',
        icon: '🗂️',
        targetValue: 5,
        category: 'special',
      ),
      Achievement(
        id: 'productivity_guru',
        title: 'Productivity Guru',
        description: 'Average 5+ tasks per day',
        icon: '🚀',
        targetValue: 1,
        category: 'special',
      ),
    ];
  }

  /// Send achievement unlocked notification
  static Future<void> _sendAchievementUnlockedNotification(Achievement achievement) async {
    try {
      final notificationService = NotificationService();
      
      String celebrationMessage;
      switch (achievement.category) {
        case 'task_master':
          celebrationMessage = 'You\'ve mastered task management! ${achievement.icon}';
          break;
        case 'streak_warrior':
          celebrationMessage = 'Your consistency is on fire! ${achievement.icon}';
          break;
        case 'early_bird':
          celebrationMessage = 'Early bird catches the worm! ${achievement.icon}';
          break;
        case 'voice_champion':
          celebrationMessage = 'Voice command master! ${achievement.icon}';
          break;
        case 'special':
          celebrationMessage = 'Special achievement unlocked! ${achievement.icon}';
          break;
        default:
          celebrationMessage = 'New achievement unlocked! ${achievement.icon}';
      }
      
      await notificationService.showNotification(
        id: achievement.id.hashCode,
        title: '🎉 Achievement Unlocked: ${achievement.title}',
        body: celebrationMessage,
      );

      SentryService.addBreadcrumb(
        message: 'achievement_notification_sent',
        category: 'achievement',
        data: {
          'achievement_id': achievement.id,
          'achievement_title': achievement.title,
        },
      );
    } catch (e) {
      SentryService.captureException(e);
    }
  }
}
