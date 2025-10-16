import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/sentry_service.dart';
import '../services/statistics_service.dart';
import '../services/habit_service.dart';
import '../services/focus_service.dart';

class ProductivityInsight {
  final String id;
  final String title;
  final String description;
  final String category;
  final double score;
  final String recommendation;
  final Map<String, dynamic> data;
  final DateTime generatedAt;

  const ProductivityInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.score,
    required this.recommendation,
    required this.data,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'score': score,
      'recommendation': recommendation,
      'data': data,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  factory ProductivityInsight.fromJson(Map<String, dynamic> json) {
    return ProductivityInsight(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      score: (json['score'] ?? 0.0).toDouble(),
      recommendation: json['recommendation'],
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      generatedAt: DateTime.parse(json['generated_at']),
    );
  }
}

class AdvancedAnalyticsService {
  static const String _insightsKey = 'productivity_insights';
  static const String _lastAnalysisKey = 'last_analysis_timestamp';
  
  static List<ProductivityInsight> _insights = [];
  static DateTime? _lastAnalysisTime;

  /// Get current insights
  static List<ProductivityInsight> get insights => List.unmodifiable(_insights);
  static DateTime? get lastAnalysisTime => _lastAnalysisTime;

  /// Initialize analytics service
  static Future<void> initialize() async {
    try {
      await _loadInsights();
      
      SentryService.addBreadcrumb(
        message: 'advanced_analytics_initialized',
        category: 'analytics',
        data: {
          'insights_count': _insights.length,
          'last_analysis': _lastAnalysisTime?.toIso8601String(),
        },
      );
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Generate comprehensive productivity insights
  static Future<List<ProductivityInsight>> generateInsights(List<Task> tasks) async {
    try {
      final insights = <ProductivityInsight>[];
      final now = DateTime.now();

      // Task completion insights
      insights.addAll(await _generateTaskInsights(tasks));
      
      // Time management insights
      insights.addAll(await _generateTimeInsights(tasks));
      
      // Habit correlation insights
      insights.addAll(await _generateHabitInsights(tasks));
      
      // Focus session insights
      insights.addAll(await _generateFocusInsights());
      
      // Productivity pattern insights
      insights.addAll(await _generatePatternInsights(tasks));
      
      // Goal achievement insights
      insights.addAll(await _generateGoalInsights(tasks));

      _insights = insights;
      _lastAnalysisTime = now;
      await _saveInsights();

      SentryService.addBreadcrumb(
        message: 'insights_generated',
        category: 'analytics',
        data: {
          'insights_count': insights.length,
          'tasks_analyzed': tasks.length,
        },
      );

      return insights;
    } catch (e) {
      SentryService.captureException(e);
      return [];
    }
  }

  /// Generate task completion insights
  static Future<List<ProductivityInsight>> _generateTaskInsights(List<Task> tasks) async {
    final insights = <ProductivityInsight>[];
    
    try {
      final completedTasks = tasks.where((t) => t.isCompleted).toList();
      final completionRate = tasks.isEmpty ? 0.0 : completedTasks.length / tasks.length;
      
      // Completion rate insight
      if (completionRate >= 0.8) {
        insights.add(ProductivityInsight(
          id: 'high_completion_rate',
          title: 'Excellent Task Completion',
          description: 'You\'re completing ${(completionRate * 100).round()}% of your tasks!',
          category: 'completion',
          score: completionRate,
          recommendation: 'Keep up the great work! Consider setting more challenging goals.',
          data: {'completion_rate': completionRate, 'total_tasks': tasks.length},
          generatedAt: DateTime.now(),
        ));
      } else if (completionRate < 0.5) {
        insights.add(ProductivityInsight(
          id: 'low_completion_rate',
          title: 'Room for Improvement',
          description: 'Your task completion rate is ${(completionRate * 100).round()}%',
          category: 'completion',
          score: completionRate,
          recommendation: 'Try breaking large tasks into smaller, manageable pieces.',
          data: {'completion_rate': completionRate, 'total_tasks': tasks.length},
          generatedAt: DateTime.now(),
        ));
      }

      // Category performance insight
      final categoryPerformance = _analyzeCategoryPerformance(tasks);
      final bestCategory = categoryPerformance.entries
          .where((e) => e.value > 0.7)
          .reduce((a, b) => a.value > b.value ? a : b);
      
      if (categoryPerformance.isNotEmpty) {
        insights.add(ProductivityInsight(
          id: 'best_category_performance',
          title: 'Category Strength',
          description: 'You excel at ${bestCategory.key} tasks',
          category: 'performance',
          score: bestCategory.value,
          recommendation: 'Consider taking on more ${bestCategory.key} responsibilities.',
          data: categoryPerformance,
          generatedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      SentryService.captureException(e);
    }

    return insights;
  }

  /// Generate time management insights
  static Future<List<ProductivityInsight>> _generateTimeInsights(List<Task> tasks) async {
    final insights = <ProductivityInsight>[];
    
    try {
      final completedTasks = tasks.where((t) => t.isCompleted && t.completedAt != null).toList();
      
      if (completedTasks.isNotEmpty) {
        // Peak productivity hours
        final hourlyCompletion = <int, int>{};
        for (final task in completedTasks) {
          final completedAt = task.completedAt;
          if (completedAt != null) {
            final hour = completedAt.hour;
            hourlyCompletion[hour] = (hourlyCompletion[hour] ?? 0) + 1;
          }
        }
        
        final peakHour = hourlyCompletion.entries
            .reduce((a, b) => a.value > b.value ? a : b);
        
        insights.add(ProductivityInsight(
          id: 'peak_productivity_hour',
          title: 'Peak Productivity Time',
          description: 'You\'re most productive at ${peakHour.key}:00',
          category: 'timing',
          score: peakHour.value / completedTasks.length,
          recommendation: 'Schedule important tasks around ${peakHour.key}:00 for best results.',
          data: {'peak_hour': peakHour.key, 'tasks_completed': peakHour.value},
          generatedAt: DateTime.now(),
        ));

        // Weekly patterns
        final weeklyCompletion = <int, int>{};
        for (final task in completedTasks) {
          final completedAt = task.completedAt;
          if (completedAt != null) {
            final weekday = completedAt.weekday;
            weeklyCompletion[weekday] = (weeklyCompletion[weekday] ?? 0) + 1;
          }
        }
        
        final bestDay = weeklyCompletion.entries
            .reduce((a, b) => a.value > b.value ? a : b);
        
        final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        
        insights.add(ProductivityInsight(
          id: 'best_productivity_day',
          title: 'Most Productive Day',
          description: '${dayNames[bestDay.key]} is your most productive day',
          category: 'timing',
          score: bestDay.value / completedTasks.length,
          recommendation: 'Plan challenging tasks for ${dayNames[bestDay.key]}s.',
          data: {'best_day': bestDay.key, 'day_name': dayNames[bestDay.key]},
          generatedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      SentryService.captureException(e);
    }

    return insights;
  }

  /// Generate habit correlation insights
  static Future<List<ProductivityInsight>> _generateHabitInsights(List<Task> tasks) async {
    final insights = <ProductivityInsight>[];
    
    try {
      final habits = HabitService.habits;
      final activeHabits = habits.where((h) => h.isActive).toList();
      
      if (activeHabits.isNotEmpty) {
        final avgCompletionRate = activeHabits
            .map((h) => h.completionRate)
            .reduce((a, b) => a + b) / activeHabits.length;
        
        if (avgCompletionRate > 0.7) {
          insights.add(ProductivityInsight(
            id: 'strong_habit_correlation',
            title: 'Habit-Task Synergy',
            description: 'Your strong habits boost task completion by ${((avgCompletionRate - 0.5) * 100).round()}%',
            category: 'habits',
            score: avgCompletionRate,
            recommendation: 'Your consistent habits are driving productivity. Keep it up!',
            data: {'habit_completion_rate': avgCompletionRate, 'active_habits': activeHabits.length},
            generatedAt: DateTime.now(),
          ));
        }

        // Best performing habit
        final bestHabit = activeHabits.reduce((a, b) => a.completionRate > b.completionRate ? a : b);
        
        insights.add(ProductivityInsight(
          id: 'best_habit_performance',
          title: 'Habit Champion',
          description: '${bestHabit.title} is your strongest habit',
          category: 'habits',
          score: bestHabit.completionRate,
          recommendation: 'Use the success pattern from this habit for other areas.',
          data: {'habit_title': bestHabit.title, 'completion_rate': bestHabit.completionRate},
          generatedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      SentryService.captureException(e);
    }

    return insights;
  }

  /// Generate focus session insights
  static Future<List<ProductivityInsight>> _generateFocusInsights() async {
    final insights = <ProductivityInsight>[];
    
    try {
      final focusStats = FocusService.getFocusStatistics();
      final completionRate = focusStats['completionRate'] as double;
      final totalSessions = focusStats['totalSessions'] as int;
      
      if (totalSessions > 0) {
        if (completionRate > 0.8) {
          insights.add(ProductivityInsight(
            id: 'excellent_focus',
            title: 'Focus Master',
            description: 'You complete ${(completionRate * 100).round()}% of focus sessions',
            category: 'focus',
            score: completionRate,
            recommendation: 'Your focus discipline is excellent. Consider longer sessions.',
            data: focusStats,
            generatedAt: DateTime.now(),
          ));
        } else if (completionRate < 0.5) {
          insights.add(ProductivityInsight(
            id: 'focus_improvement_needed',
            title: 'Focus Challenge',
            description: 'Focus session completion could be improved',
            category: 'focus',
            score: completionRate,
            recommendation: 'Try shorter sessions or eliminate distractions.',
            data: focusStats,
            generatedAt: DateTime.now(),
          ));
        }

        // Focus time analysis
        final totalFocusTime = focusStats['totalFocusTime'] as Duration;
        final avgSessionTime = totalFocusTime.inMinutes / totalSessions;
        
        insights.add(ProductivityInsight(
          id: 'focus_time_analysis',
          title: 'Focus Time Insights',
          description: 'Average focus session: ${avgSessionTime.round()} minutes',
          category: 'focus',
          score: math.min(avgSessionTime / 25, 1.0), // Normalized to 25min standard
          recommendation: avgSessionTime < 20 
              ? 'Try extending sessions for deeper focus.'
              : 'Great session length for sustained concentration.',
          data: {'avg_session_minutes': avgSessionTime, 'total_minutes': totalFocusTime.inMinutes},
          generatedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      SentryService.captureException(e);
    }

    return insights;
  }

  /// Generate productivity pattern insights
  static Future<List<ProductivityInsight>> _generatePatternInsights(List<Task> tasks) async {
    final insights = <ProductivityInsight>[];
    
    try {
      final now = DateTime.now();
      final last30Days = tasks.where((t) => 
          now.difference(t.createdAt).inDays <= 30
      ).toList();
      
      if (last30Days.length >= 10) {
        // Trend analysis
        final weeklyTasks = <int, int>{};
        for (final task in last30Days) {
          final createdAt = task.createdAt;
          final weekNumber = ((now.difference(createdAt).inDays) / 7).floor();
          weeklyTasks[weekNumber] = (weeklyTasks[weekNumber] ?? 0) + 1;
                }
        
        final weeks = weeklyTasks.keys.toList()..sort();
        if (weeks.length >= 3) {
          final recentWeek = weeklyTasks[weeks[0]] ?? 0;
          final olderWeek = weeklyTasks[weeks[2]] ?? 0;
          
          if (recentWeek > olderWeek * 1.2) {
            insights.add(ProductivityInsight(
              id: 'increasing_productivity',
              title: 'Upward Trend',
              description: 'Your productivity is increasing over time',
              category: 'trends',
              score: recentWeek / math.max(olderWeek, 1),
              recommendation: 'You\'re on the right track! Keep building momentum.',
              data: {'recent_tasks': recentWeek, 'older_tasks': olderWeek},
              generatedAt: DateTime.now(),
            ));
          } else if (recentWeek < olderWeek * 0.8) {
            insights.add(ProductivityInsight(
              id: 'declining_productivity',
              title: 'Attention Needed',
              description: 'Recent productivity has declined',
              category: 'trends',
              score: recentWeek / math.max(olderWeek, 1),
              recommendation: 'Consider reviewing your goals and removing obstacles.',
              data: {'recent_tasks': recentWeek, 'older_tasks': olderWeek},
              generatedAt: DateTime.now(),
            ));
          }
        }
      }
    } catch (e) {
      SentryService.captureException(e);
    }

    return insights;
  }

  /// Generate goal achievement insights
  static Future<List<ProductivityInsight>> _generateGoalInsights(List<Task> tasks) async {
    final insights = <ProductivityInsight>[];
    
    try {
      final recurringTasks = tasks.where((t) => t.recurringPattern != null && t.recurringPattern != 'once').toList();
      
      if (recurringTasks.isNotEmpty) {
        final completedRecurring = recurringTasks.where((t) => t.isCompleted).length;
        final recurringRate = completedRecurring / recurringTasks.length;
        
        if (recurringRate > 0.8) {
          insights.add(ProductivityInsight(
            id: 'consistent_goal_achievement',
            title: 'Goal Consistency',
            description: 'You\'re ${(recurringRate * 100).round()}% consistent with recurring goals',
            category: 'goals',
            score: recurringRate,
            recommendation: 'Your consistency is excellent. Consider adding new challenges.',
            data: {'recurring_completion_rate': recurringRate, 'recurring_tasks': recurringTasks.length},
            generatedAt: DateTime.now(),
          ));
        }
      }

      // Priority completion analysis
      final highPriorityTasks = tasks.where((t) => t.priority == 'high').toList();
      if (highPriorityTasks.isNotEmpty) {
        final completedHighPriority = highPriorityTasks.where((t) => t.isCompleted).length;
        final highPriorityRate = completedHighPriority / highPriorityTasks.length;
        
        insights.add(ProductivityInsight(
          id: 'priority_focus',
          title: 'Priority Management',
          description: '${(highPriorityRate * 100).round()}% of high-priority tasks completed',
          category: 'priorities',
          score: highPriorityRate,
          recommendation: highPriorityRate > 0.7 
              ? 'Excellent priority management!'
              : 'Focus more on high-priority tasks first.',
          data: {'high_priority_rate': highPriorityRate, 'high_priority_tasks': highPriorityTasks.length},
          generatedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      SentryService.captureException(e);
    }

    return insights;
  }

  /// Analyze category performance
  static Map<String, double> _analyzeCategoryPerformance(List<Task> tasks) {
    final categoryStats = <String, Map<String, int>>{};
    
    for (final task in tasks) {
      final category = task.category;
      categoryStats[category] ??= {'total': 0, 'completed': 0};
      categoryStats[category]!['total'] = categoryStats[category]!['total']! + 1;
      if (task.isCompleted) {
        categoryStats[category]!['completed'] = categoryStats[category]!['completed']! + 1;
      }
    }
    
    final performance = <String, double>{};
    for (final entry in categoryStats.entries) {
      final total = entry.value['total']!;
      final completed = entry.value['completed']!;
      performance[entry.key] = total > 0 ? completed / total : 0.0;
    }
    
    return performance;
  }

  /// Get insights by category
  static List<ProductivityInsight> getInsightsByCategory(String category) {
    return _insights.where((insight) => insight.category == category).toList();
  }

  /// Get top insights by score
  static List<ProductivityInsight> getTopInsights({int limit = 5}) {
    final sortedInsights = List<ProductivityInsight>.from(_insights);
    sortedInsights.sort((a, b) => b.score.compareTo(a.score));
    return sortedInsights.take(limit).toList();
  }

  /// Save insights to storage
  static Future<void> _saveInsights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final insightsJson = jsonEncode(_insights.map((i) => i.toJson()).toList());
      await prefs.setString(_insightsKey, insightsJson);
      
      if (_lastAnalysisTime != null) {
        await prefs.setString(_lastAnalysisKey, _lastAnalysisTime!.toIso8601String());
      }
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  /// Load insights from storage
  static Future<void> _loadInsights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final insightsJson = prefs.getString(_insightsKey);
      
      if (insightsJson != null) {
        final insightsList = jsonDecode(insightsJson) as List<dynamic>;
        _insights = insightsList.map((json) => ProductivityInsight.fromJson(json)).toList();
      }
      
      final lastAnalysisString = prefs.getString(_lastAnalysisKey);
      if (lastAnalysisString != null) {
        _lastAnalysisTime = DateTime.parse(lastAnalysisString);
      }
    } catch (e) {
      SentryService.captureException(e);
      _insights = [];
    }
  }

  /// Clear all insights
  static Future<void> clearInsights() async {
    try {
      _insights.clear();
      _lastAnalysisTime = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_insightsKey);
      await prefs.remove(_lastAnalysisKey);
      
      SentryService.addBreadcrumb(
        message: 'insights_cleared',
        category: 'analytics',
      );
    } catch (e) {
      SentryService.captureException(e);
    }
  }
}
