import 'dart:math';
import '../services/habit_service.dart';
import '../services/sentry_service.dart';

class HabitAnalytics {
  final String habitId;
  final String habitTitle;
  final String category;
  final String frequency;
  final double completionRate;
  final int currentStreak;
  final int longestStreak;
  final List<DateTime> completedDates;
  final DateTime createdAt;
  final Map<String, dynamic> weeklyData;
  final Map<String, dynamic> monthlyData;
  final List<String> insights;

  HabitAnalytics({
    required this.habitId,
    required this.habitTitle,
    required this.category,
    required this.frequency,
    required this.completionRate,
    required this.currentStreak,
    required this.longestStreak,
    required this.completedDates,
    required this.createdAt,
    required this.weeklyData,
    required this.monthlyData,
    required this.insights,
  });
}

class WeeklyOverviewData {
  final List<double> dailyCompletionRates;
  final List<String> dayLabels;
  final double weeklyAverage;
  final int totalCompletions;
  final int totalHabits;
  final String bestDay;
  final String worstDay;
  final List<String> insights;

  WeeklyOverviewData({
    required this.dailyCompletionRates,
    required this.dayLabels,
    required this.weeklyAverage,
    required this.totalCompletions,
    required this.totalHabits,
    required this.bestDay,
    required this.worstDay,
    required this.insights,
  });
}

class BestPerformingHabitsData {
  final List<HabitPerformance> topHabits;
  final List<HabitPerformance> strugglingHabits;
  final double overallAverage;
  final List<String> insights;

  BestPerformingHabitsData({
    required this.topHabits,
    required this.strugglingHabits,
    required this.overallAverage,
    required this.insights,
  });
}

class HabitPerformance {
  final String habitId;
  final String title;
  final String category;
  final double completionRate;
  final int currentStreak;
  final int longestStreak;
  final String frequency;
  final DateTime lastCompleted;
  final List<String> strengths;
  final List<String> improvements;

  HabitPerformance({
    required this.habitId,
    required this.title,
    required this.category,
    required this.completionRate,
    required this.currentStreak,
    required this.longestStreak,
    required this.frequency,
    required this.lastCompleted,
    required this.strengths,
    required this.improvements,
  });
}

class ImprovementAreasData {
  final List<ImprovementArea> areas;
  final List<String> generalRecommendations;
  final Map<String, List<String>> categoryRecommendations;
  final List<String> quickWins;

  ImprovementAreasData({
    required this.areas,
    required this.generalRecommendations,
    required this.categoryRecommendations,
    required this.quickWins,
  });
}

class ImprovementArea {
  final String title;
  final String description;
  final String severity; // 'low', 'medium', 'high'
  final List<String> affectedHabits;
  final List<String> recommendations;
  final String category;

  ImprovementArea({
    required this.title,
    required this.description,
    required this.severity,
    required this.affectedHabits,
    required this.recommendations,
    required this.category,
  });
}

class StreakAnalysisData {
  final List<StreakInfo> currentStreaks;
  final List<StreakInfo> longestStreaks;
  final Map<String, List<int>> streakHistory;
  final double averageStreakLength;
  final List<String> streakTips;
  final Map<String, dynamic> streakPatterns;

  StreakAnalysisData({
    required this.currentStreaks,
    required this.longestStreaks,
    required this.streakHistory,
    required this.averageStreakLength,
    required this.streakTips,
    required this.streakPatterns,
  });
}

class StreakInfo {
  final String habitId;
  final String habitTitle;
  final String category;
  final int streakLength;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;

  StreakInfo({
    required this.habitId,
    required this.habitTitle,
    required this.category,
    required this.streakLength,
    required this.startDate,
    this.endDate,
    required this.isActive,
  });
}

class HabitAnalyticsService {
  /// Generate comprehensive weekly overview
  static WeeklyOverviewData generateWeeklyOverview() {
    try {
      final habits = HabitService.activeHabits;
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      
      final dailyCompletionRates = <double>[];
      final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      
      var totalCompletions = 0;
      var bestDayRate = 0.0;
      var worstDayRate = 1.0;
      var bestDay = 'Monday';
      var worstDay = 'Monday';
      
      // Calculate daily completion rates for the week
      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        var dayCompletions = 0;
        var dayHabits = 0;
        
        for (final habit in habits) {
          if (habit.createdAt.isBefore(day.add(const Duration(days: 1)))) {
            dayHabits++;
            if (habit.completedDates.any((date) => _isSameDay(date, day))) {
              dayCompletions++;
              totalCompletions++;
            }
          }
        }
        
        final rate = dayHabits > 0 ? dayCompletions / dayHabits : 0.0;
        dailyCompletionRates.add(rate);
        
        if (rate > bestDayRate) {
          bestDayRate = rate;
          bestDay = dayLabels[i];
        }
        if (rate < worstDayRate) {
          worstDayRate = rate;
          worstDay = dayLabels[i];
        }
      }
      
      final weeklyAverage = dailyCompletionRates.isNotEmpty 
          ? dailyCompletionRates.reduce((a, b) => a + b) / dailyCompletionRates.length
          : 0.0;
      
      final insights = _generateWeeklyInsights(
        dailyCompletionRates, 
        weeklyAverage, 
        bestDay, 
        worstDay,
        totalCompletions,
      );
      
      SentryService.addBreadcrumb(
        message: 'weekly_overview_generated',
        category: 'habit_analytics',
        data: {
          'weekly_average': weeklyAverage,
          'total_completions': totalCompletions,
          'best_day': bestDay,
        },
      );
      
      return WeeklyOverviewData(
        dailyCompletionRates: dailyCompletionRates,
        dayLabels: dayLabels,
        weeklyAverage: weeklyAverage,
        totalCompletions: totalCompletions,
        totalHabits: habits.length,
        bestDay: bestDay,
        worstDay: worstDay,
        insights: insights,
      );
    } catch (e) {
      SentryService.captureException(e);
      return WeeklyOverviewData(
        dailyCompletionRates: List.filled(7, 0.0),
        dayLabels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        weeklyAverage: 0.0,
        totalCompletions: 0,
        totalHabits: 0,
        bestDay: 'Monday',
        worstDay: 'Monday',
        insights: ['No data available'],
      );
    }
  }
  
  /// Analyze best and worst performing habits
  static BestPerformingHabitsData analyzeBestPerformingHabits() {
    try {
      final habits = HabitService.activeHabits;
      final habitPerformances = <HabitPerformance>[];
      
      for (final habit in habits) {
        final performance = _analyzeHabitPerformance(habit);
        habitPerformances.add(performance);
      }
      
      // Sort by completion rate
      habitPerformances.sort((a, b) => b.completionRate.compareTo(a.completionRate));
      
      final topHabits = habitPerformances.take(3).toList();
      final strugglingHabits = habitPerformances.reversed.take(3).toList().reversed.toList();
      
      final overallAverage = habitPerformances.isNotEmpty
          ? habitPerformances.map((h) => h.completionRate).reduce((a, b) => a + b) / habitPerformances.length
          : 0.0;
      
      final insights = _generatePerformanceInsights(topHabits, strugglingHabits, overallAverage);
      
      SentryService.addBreadcrumb(
        message: 'habit_performance_analyzed',
        category: 'habit_analytics',
        data: {
          'total_habits': habits.length,
          'overall_average': overallAverage,
          'top_habits_count': topHabits.length,
        },
      );
      
      return BestPerformingHabitsData(
        topHabits: topHabits,
        strugglingHabits: strugglingHabits,
        overallAverage: overallAverage,
        insights: insights,
      );
    } catch (e) {
      SentryService.captureException(e);
      return BestPerformingHabitsData(
        topHabits: [],
        strugglingHabits: [],
        overallAverage: 0.0,
        insights: ['No data available'],
      );
    }
  }
  
  /// Identify improvement areas and recommendations
  static ImprovementAreasData identifyImprovementAreas() {
    try {
      final habits = HabitService.activeHabits;
      final areas = <ImprovementArea>[];
      final categoryRecommendations = <String, List<String>>{};
      final quickWins = <String>[];
      
      // Analyze consistency issues
      final inconsistentHabits = habits.where((h) => h.completionRate < 0.5).toList();
      if (inconsistentHabits.isNotEmpty) {
        areas.add(ImprovementArea(
          title: 'Consistency Challenge',
          description: 'Some habits have low completion rates',
          severity: 'high',
          affectedHabits: inconsistentHabits.map((h) => h.title).toList(),
          recommendations: [
            'Start with smaller, easier versions of these habits',
            'Set up environmental cues and reminders',
            'Track your progress visually',
            'Celebrate small wins',
          ],
          category: 'consistency',
        ));
      }
      
      // Analyze streak breaks
      final streakBreakers = habits.where((h) => h.currentStreak == 0 && h.completedDates.isNotEmpty).toList();
      if (streakBreakers.isNotEmpty) {
        areas.add(ImprovementArea(
          title: 'Streak Maintenance',
          description: 'Recent streak breaks detected',
          severity: 'medium',
          affectedHabits: streakBreakers.map((h) => h.title).toList(),
          recommendations: [
            'Identify what caused the streak break',
            'Create backup plans for difficult days',
            'Lower the bar to maintain momentum',
            'Focus on getting back on track quickly',
          ],
          category: 'streaks',
        ));
      }
      
      // Analyze category performance
      final categoryStats = <String, List<double>>{};
      for (final habit in habits) {
        categoryStats.putIfAbsent(habit.category, () => []).add(habit.completionRate);
      }
      
      categoryStats.forEach((category, rates) {
        final avgRate = rates.reduce((a, b) => a + b) / rates.length;
        if (avgRate < 0.6) {
          categoryRecommendations[category] = [
            'Consider reducing the number of $category habits',
            'Focus on one $category habit at a time',
            'Review if $category habits fit your lifestyle',
            'Adjust timing or frequency for $category habits',
          ];
        }
      });
      
      // Identify quick wins
      final easyWins = habits.where((h) => h.completionRate > 0.7 && h.completionRate < 0.9).toList();
      for (final habit in easyWins) {
        quickWins.add('Boost "${habit.title}" from ${(habit.completionRate * 100).round()}% to 90%+');
      }
      
      final generalRecommendations = _generateGeneralRecommendations(habits);
      
      SentryService.addBreadcrumb(
        message: 'improvement_areas_identified',
        category: 'habit_analytics',
        data: {
          'areas_count': areas.length,
          'quick_wins_count': quickWins.length,
          'categories_analyzed': categoryStats.length,
        },
      );
      
      return ImprovementAreasData(
        areas: areas,
        generalRecommendations: generalRecommendations,
        categoryRecommendations: categoryRecommendations,
        quickWins: quickWins,
      );
    } catch (e) {
      SentryService.captureException(e);
      return ImprovementAreasData(
        areas: [],
        generalRecommendations: ['No data available'],
        categoryRecommendations: {},
        quickWins: [],
      );
    }
  }
  
  /// Analyze streak patterns and history
  static StreakAnalysisData analyzeStreaks() {
    try {
      final habits = HabitService.activeHabits;
      final currentStreaks = <StreakInfo>[];
      final longestStreaks = <StreakInfo>[];
      final streakHistory = <String, List<int>>{};
      
      var totalStreakLength = 0;
      var streakCount = 0;
      
      for (final habit in habits) {
        // Current streak
        if (habit.currentStreak > 0) {
          final streakStart = DateTime.now().subtract(Duration(days: habit.currentStreak - 1));
          currentStreaks.add(StreakInfo(
            habitId: habit.id,
            habitTitle: habit.title,
            category: habit.category,
            streakLength: habit.currentStreak,
            startDate: streakStart,
            isActive: true,
          ));
          totalStreakLength += habit.currentStreak;
          streakCount++;
        }
        
        // Calculate longest streak
        final longestStreak = _calculateLongestStreak(habit.completedDates);
        if (longestStreak > 0) {
          longestStreaks.add(StreakInfo(
            habitId: habit.id,
            habitTitle: habit.title,
            category: habit.category,
            streakLength: longestStreak,
            startDate: habit.createdAt, // Approximation
            isActive: habit.currentStreak == longestStreak,
          ));
        }
        
        // Streak history
        streakHistory[habit.id] = _calculateStreakHistory(habit.completedDates);
      }
      
      // Sort by streak length
      currentStreaks.sort((a, b) => b.streakLength.compareTo(a.streakLength));
      longestStreaks.sort((a, b) => b.streakLength.compareTo(a.streakLength));
      
      final averageStreakLength = streakCount > 0 ? totalStreakLength / streakCount : 0.0;
      
      final streakTips = _generateStreakTips(currentStreaks, averageStreakLength);
      final streakPatterns = _analyzeStreakPatterns(habits);
      
      SentryService.addBreadcrumb(
        message: 'streak_analysis_completed',
        category: 'habit_analytics',
        data: {
          'current_streaks': currentStreaks.length,
          'average_streak_length': averageStreakLength,
          'longest_streak': longestStreaks.isNotEmpty ? longestStreaks.first.streakLength : 0,
        },
      );
      
      return StreakAnalysisData(
        currentStreaks: currentStreaks,
        longestStreaks: longestStreaks,
        streakHistory: streakHistory,
        averageStreakLength: averageStreakLength,
        streakTips: streakTips,
        streakPatterns: streakPatterns,
      );
    } catch (e) {
      SentryService.captureException(e);
      return StreakAnalysisData(
        currentStreaks: [],
        longestStreaks: [],
        streakHistory: {},
        averageStreakLength: 0.0,
        streakTips: ['No data available'],
        streakPatterns: {},
      );
    }
  }
  
  // Helper methods
  
  static HabitPerformance _analyzeHabitPerformance(Habit habit) {
    final strengths = <String>[];
    final improvements = <String>[];
    
    if (habit.completionRate > 0.8) {
      strengths.add('Excellent consistency');
    }
    if (habit.currentStreak > 7) {
      strengths.add('Strong current streak');
    }
    if (habit.completedDates.length > 30) {
      strengths.add('Long-term commitment');
    }
    
    if (habit.completionRate < 0.5) {
      improvements.add('Focus on consistency');
    }
    if (habit.currentStreak == 0) {
      improvements.add('Rebuild momentum');
    }
    if (habit.completedDates.isEmpty) {
      improvements.add('Get started');
    }
    
    final lastCompleted = habit.completedDates.isNotEmpty
        ? habit.completedDates.reduce((a, b) => a.isAfter(b) ? a : b)
        : habit.createdAt;
    
    return HabitPerformance(
      habitId: habit.id,
      title: habit.title,
      category: habit.category,
      completionRate: habit.completionRate,
      currentStreak: habit.currentStreak,
      longestStreak: _calculateLongestStreak(habit.completedDates),
      frequency: habit.frequency,
      lastCompleted: lastCompleted,
      strengths: strengths,
      improvements: improvements,
    );
  }
  
  static List<String> _generateWeeklyInsights(
    List<double> dailyRates,
    double weeklyAverage,
    String bestDay,
    String worstDay,
    int totalCompletions,
  ) {
    final insights = <String>[];
    
    if (weeklyAverage > 0.8) {
      insights.add('🎉 Outstanding week! You maintained excellent consistency.');
    } else if (weeklyAverage > 0.6) {
      insights.add('👍 Good week overall with room for improvement.');
    } else {
      insights.add('💪 Challenging week - focus on getting back on track.');
    }
    
    insights.add('📈 Your best day was $bestDay with ${(dailyRates[['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexOf(bestDay)] * 100).round()}% completion.');
    
    if (bestDay != worstDay) {
      insights.add('📉 Consider what made $bestDay successful and apply it to $worstDay.');
    }
    
    if (totalCompletions > 0) {
      insights.add('✅ You completed $totalCompletions habits this week.');
    }
    
    return insights;
  }
  
  static List<String> _generatePerformanceInsights(
    List<HabitPerformance> topHabits,
    List<HabitPerformance> strugglingHabits,
    double overallAverage,
  ) {
    final insights = <String>[];
    
    if (topHabits.isNotEmpty) {
      final topHabit = topHabits.first;
      insights.add('🏆 "${topHabit.title}" is your star performer with ${(topHabit.completionRate * 100).round()}% completion rate.');
    }
    
    if (overallAverage > 0.7) {
      insights.add('🌟 Your overall habit performance is excellent at ${(overallAverage * 100).round()}%.');
    } else if (overallAverage > 0.5) {
      insights.add('📊 Your overall performance is solid at ${(overallAverage * 100).round()}% - aim for 70%+.');
    } else {
      insights.add('🎯 Focus on consistency - your current average is ${(overallAverage * 100).round()}%.');
    }
    
    if (strugglingHabits.isNotEmpty) {
      final strugglingHabit = strugglingHabits.first;
      insights.add('🔧 "${strugglingHabit.title}" needs attention - consider simplifying or adjusting timing.');
    }
    
    return insights;
  }
  
  static List<String> _generateGeneralRecommendations(List<Habit> habits) {
    final recommendations = <String>[];
    
    if (habits.length > 5) {
      recommendations.add('Consider focusing on fewer habits for better consistency');
    }
    
    final dailyHabits = habits.where((h) => h.frequency == 'daily').length;
    if (dailyHabits > 3) {
      recommendations.add('Too many daily habits can be overwhelming - try habit stacking');
    }
    
    final newHabits = habits.where((h) => DateTime.now().difference(h.createdAt).inDays < 30).length;
    if (newHabits > 2) {
      recommendations.add('Focus on establishing current habits before adding new ones');
    }
    
    recommendations.addAll([
      'Start with 2-minute versions of difficult habits',
      'Use habit stacking to link new habits to established routines',
      'Track your habits visually for motivation',
      'Celebrate small wins to build momentum',
    ]);
    
    return recommendations;
  }
  
  static List<String> _generateStreakTips(List<StreakInfo> currentStreaks, double averageLength) {
    final tips = <String>[];
    
    if (currentStreaks.isNotEmpty) {
      final longestCurrent = currentStreaks.first;
      tips.add('🔥 Protect your ${longestCurrent.streakLength}-day streak in "${longestCurrent.habitTitle}"');
    }
    
    if (averageLength > 7) {
      tips.add('💪 Your average streak of ${averageLength.round()} days shows great consistency');
    } else {
      tips.add('🎯 Aim to build streaks of 7+ days for habit formation');
    }
    
    tips.addAll([
      'Never miss twice - get back on track immediately after a slip',
      'Lower the bar on difficult days to maintain momentum',
      'Use visual streak tracking for motivation',
      'Plan for obstacles and have backup strategies',
    ]);
    
    return tips;
  }
  
  static Map<String, dynamic> _analyzeStreakPatterns(List<Habit> habits) {
    final patterns = <String, dynamic>{};
    
    final streakLengths = habits.map((h) => h.currentStreak).where((s) => s > 0).toList();
    if (streakLengths.isNotEmpty) {
      patterns['average_active_streak'] = streakLengths.reduce((a, b) => a + b) / streakLengths.length;
      patterns['longest_active_streak'] = streakLengths.reduce(max);
    }
    
    patterns['habits_with_streaks'] = streakLengths.length;
    patterns['habits_without_streaks'] = habits.length - streakLengths.length;
    
    return patterns;
  }
  
  static int _calculateLongestStreak(List<DateTime> completedDates) {
    if (completedDates.isEmpty) return 0;
    
    final sortedDates = List<DateTime>.from(completedDates)
      ..sort();
    
    int longestStreak = 1;
    int currentStreak = 1;
    
    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
        longestStreak = max(longestStreak, currentStreak);
      } else {
        currentStreak = 1;
      }
    }
    
    return longestStreak;
  }
  
  static List<int> _calculateStreakHistory(List<DateTime> completedDates) {
    if (completedDates.isEmpty) return [];
    
    final sortedDates = List<DateTime>.from(completedDates)..sort();
    final streaks = <int>[];
    int currentStreak = 1;
    
    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
      } else {
        streaks.add(currentStreak);
        currentStreak = 1;
      }
    }
    streaks.add(currentStreak);
    
    return streaks;
  }
  
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}
