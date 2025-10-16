import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/sentry_service.dart';

class StatisticsService {
  static const int _daysInWeek = 7;
  static const int _daysInMonth = 30;
  static const int _daysInYear = 365;

  /// Calculate comprehensive statistics for a given period
  static Map<String, dynamic> calculateStatistics(
    List<Task> tasks, 
    String period
  ) {
    try {
      final now = DateTime.now();
      final filteredTasks = _filterTasksByPeriod(tasks, period, now);
      
      return {
        'totalTasks': filteredTasks.length,
        'completedTasks': filteredTasks.where((t) => t.isCompleted).length,
        'pendingTasks': filteredTasks.where((t) => !t.isCompleted).length,
        'completionRate': _calculateCompletionRate(filteredTasks),
        'averagePerDay': _calculateAveragePerDay(filteredTasks, period),
        'productivityTrend': _calculateProductivityTrend(filteredTasks, period),
        'categoryBreakdown': _calculateCategoryBreakdown(filteredTasks),
        'timeAnalysis': _calculateTimeAnalysis(filteredTasks),
        'streakAnalysis': _calculateStreakAnalysis(tasks),
        'priorityDistribution': _calculatePriorityDistribution(filteredTasks),
        'weeklyPattern': _calculateWeeklyPattern(filteredTasks),
        'monthlyPattern': _calculateMonthlyPattern(filteredTasks),
      };
    } catch (e) {
      SentryService.captureException(e);
      return _getDefaultStatistics();
    }
  }

  /// Filter tasks by time period
  static List<Task> _filterTasksByPeriod(List<Task> tasks, String period, DateTime now) {
    DateTime startDate;
    
    switch (period) {
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }
    
    return tasks.where((task) {
      final taskDate = task.createdAt;
      return taskDate.isAfter(startDate) && taskDate.isBefore(now.add(const Duration(days: 1)));
    }).toList();
  }

  /// Calculate completion rate percentage
  static int _calculateCompletionRate(List<Task> tasks) {
    if (tasks.isEmpty) return 0;
    final completed = tasks.where((t) => t.isCompleted).length;
    return ((completed / tasks.length) * 100).round();
  }

  /// Calculate average tasks per day
  static double _calculateAveragePerDay(List<Task> tasks, String period) {
    if (tasks.isEmpty) return 0.0;
    
    int days;
    switch (period) {
      case 'week':
        days = _daysInWeek;
        break;
      case 'month':
        days = _daysInMonth;
        break;
      case 'year':
        days = _daysInYear;
        break;
      default:
        days = _daysInWeek;
    }
    
    return tasks.length / days;
  }

  /// Calculate productivity trend data for charts
  static List<Map<String, dynamic>> _calculateProductivityTrend(List<Task> tasks, String period) {
    final now = DateTime.now();
    final trendData = <Map<String, dynamic>>[];
    
    if (period == 'week') {
      // Last 7 days
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayTasks = tasks.where((task) {
          final taskDate = task.createdAt;
          return _isSameDay(taskDate, date);
        }).toList();
        
        trendData.add({
          'label': _getDayLabel(date),
          'value': dayTasks.where((t) => t.isCompleted).length,
          'total': dayTasks.length,
          'date': date,
        });
      }
    } else if (period == 'month') {
      // Last 4 weeks
      for (int i = 3; i >= 0; i--) {
        final weekStart = now.subtract(Duration(days: (i * 7) + now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        final weekTasks = tasks.where((task) {
          final taskDate = task.createdAt;
          return taskDate.isAfter(weekStart.subtract(const Duration(days: 1))) && 
                 taskDate.isBefore(weekEnd.add(const Duration(days: 1)));
        }).toList();
        
        trendData.add({
          'label': 'Week ${4 - i}',
          'value': weekTasks.where((t) => t.isCompleted).length,
          'total': weekTasks.length,
          'date': weekStart,
        });
      }
    } else {
      // Last 12 months
      for (int i = 11; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthTasks = tasks.where((task) {
          final taskDate = task.createdAt;
          return taskDate.year == monthDate.year && taskDate.month == monthDate.month;
        }).toList();
        
        trendData.add({
          'label': _getMonthLabel(monthDate),
          'value': monthTasks.where((t) => t.isCompleted).length,
          'total': monthTasks.length,
          'date': monthDate,
        });
      }
    }
    
    return trendData;
  }

  /// Calculate category breakdown
  static List<Map<String, dynamic>> _calculateCategoryBreakdown(List<Task> tasks) {
    if (tasks.isEmpty) return [];
    
    final categoryMap = <String, int>{};
    for (final task in tasks) {
      final category = task.category;
      categoryMap[category] = (categoryMap[category] ?? 0) + 1;
    }
    
    final totalTasks = tasks.length;
    final categories = <Map<String, dynamic>>[];
    final colors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFF44336), // Red
      const Color(0xFF00BCD4), // Cyan
    ];
    
    int colorIndex = 0;
    for (var entry in categoryMap.entries) {
      final percentage = ((entry.value / totalTasks) * 100).round();
      categories.add({
        'name': _formatCategoryName(entry.key),
        'count': entry.value,
        'percentage': percentage,
        'color': colors[colorIndex % colors.length],
      });
      colorIndex++;
    }
    
    // Sort by count descending
    categories.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return categories;
  }

  /// Calculate time analysis
  static Map<String, dynamic> _calculateTimeAnalysis(List<Task> tasks) {
    final completedTasks = tasks.where((t) => t.isCompleted).toList();
    
    if (completedTasks.isEmpty) {
      return {
        'mostProductiveHour': '12:00 PM',
        'averageCompletionTime': '0h',
        'peakProductivityDay': 'Monday',
        'totalTimeSpent': '0h',
      };
    }
    
    // Calculate most productive hour
    final hourMap = <int, int>{};
    for (final task in completedTasks) {
      final completedAt = task.completedAt ?? task.createdAt;
      final hour = completedAt.hour;
      hourMap[hour] = (hourMap[hour] ?? 0) + 1;
    }
    
    int mostProductiveHour = 12;
    int maxTasks = 0;
    for (var entry in hourMap.entries) {
      if (entry.value > maxTasks) {
        maxTasks = entry.value;
        mostProductiveHour = entry.key;
      }
    }
    
    // Calculate average completion time (mock calculation)
    final averageHours = completedTasks.isNotEmpty ? 
        (completedTasks.length * 1.5) / completedTasks.length : 0.0;
    
    return {
      'mostProductiveHour': _formatHour(mostProductiveHour),
      'averageCompletionTime': '${averageHours.toStringAsFixed(1)}h',
      'peakProductivityDay': _calculatePeakDay(completedTasks),
      'totalTimeSpent': '${(completedTasks.length * 1.5).toStringAsFixed(1)}h',
    };
  }

  /// Calculate streak analysis
  static Map<String, dynamic> _calculateStreakAnalysis(List<Task> tasks) {
    final completedTasks = tasks.where((t) => t.isCompleted).toList();
    
    if (completedTasks.isEmpty) {
      return {
        'currentStreak': 0,
        'longestStreak': 0,
        'streakStartDate': null,
        'daysWithTasks': 0,
      };
    }
    
    // Sort tasks by completion date
    completedTasks.sort((a, b) {
      final dateA = a.completedAt ?? a.createdAt;
      final dateB = b.completedAt ?? b.createdAt;
      return dateA.compareTo(dateB);
    });
    
    // Calculate streaks
    final now = DateTime.now();
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;
    
    // Group tasks by date
    final tasksByDate = <String, List<Task>>{};
    for (final task in completedTasks) {
      final date = task.completedAt ?? task.createdAt;
      final dateKey = '${date.year}-${date.month}-${date.day}';
      tasksByDate[dateKey] = tasksByDate[dateKey] ?? [];
      tasksByDate[dateKey]!.add(task);
    }
    
    final sortedDates = tasksByDate.keys.toList()..sort();
    
    for (int i = 0; i < sortedDates.length; i++) {
      final dateKey = sortedDates[i];
      final dateParts = dateKey.split('-');
      final date = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );
      
      if (lastDate == null || date.difference(lastDate).inDays == 1) {
        tempStreak++;
      } else if (date.difference(lastDate).inDays > 1) {
        tempStreak = 1;
      }
      
      longestStreak = math.max(longestStreak, tempStreak);
      
      // Check if streak continues to today
      if (_isSameDay(date, now) || date.difference(now).inDays == -1) {
        currentStreak = tempStreak;
      }
      
      lastDate = date;
    }
    
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'streakStartDate': lastDate,
      'daysWithTasks': tasksByDate.length,
    };
  }

  /// Calculate priority distribution
  static Map<String, int> _calculatePriorityDistribution(List<Task> tasks) {
    final priorityMap = <String, int>{
      'high': 0,
      'medium': 0,
      'low': 0,
    };
    
    for (final task in tasks) {
      final priority = task.priority.toLowerCase();
      priorityMap[priority] = (priorityMap[priority] ?? 0) + 1;
    }
    
    return priorityMap;
  }

  /// Calculate weekly pattern
  static List<Map<String, dynamic>> _calculateWeeklyPattern(List<Task> tasks) {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weeklyData = <Map<String, dynamic>>[];
    
    for (int i = 0; i < 7; i++) {
      final dayTasks = tasks.where((task) {
        final taskDate = task.createdAt;
        return taskDate.weekday == i + 1;
      }).toList();
      
      weeklyData.add({
        'day': weekDays[i],
        'tasks': dayTasks.length,
        'completed': dayTasks.where((t) => t.isCompleted).length,
      });
    }
    
    return weeklyData;
  }

  /// Calculate monthly pattern
  static List<Map<String, dynamic>> _calculateMonthlyPattern(List<Task> tasks) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthlyData = <Map<String, dynamic>>[];
    
    for (int i = 1; i <= 12; i++) {
      final monthTasks = tasks.where((task) {
        final taskDate = task.createdAt;
        return taskDate.month == i;
      }).toList();
      
      monthlyData.add({
        'month': months[i - 1],
        'tasks': monthTasks.length,
        'completed': monthTasks.where((t) => t.isCompleted).length,
      });
    }
    
    return monthlyData;
  }

  // Helper methods
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  static String _getDayLabel(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  static String _getMonthLabel(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  static String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour < 12) return '$hour:00 AM';
    if (hour == 12) return '12:00 PM';
    return '${hour - 12}:00 PM';
  }

  static String _formatCategoryName(String category) {
    return category.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }

  static String _calculatePeakDay(List<Task> tasks) {
    final dayMap = <int, int>{};
    for (final task in tasks) {
      final date = task.completedAt ?? task.createdAt;
      final weekday = date.weekday;
      dayMap[weekday] = (dayMap[weekday] ?? 0) + 1;
    }
    
    int peakDay = 1;
    int maxTasks = 0;
    for (var entry in dayMap.entries) {
      if (entry.value > maxTasks) {
        maxTasks = entry.value;
        peakDay = entry.key;
      }
    }
    
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[peakDay - 1];
  }

  static Map<String, dynamic> _getDefaultStatistics() {
    return {
      'totalTasks': 0,
      'completedTasks': 0,
      'pendingTasks': 0,
      'completionRate': 0,
      'averagePerDay': 0.0,
      'productivityTrend': [],
      'categoryBreakdown': [],
      'timeAnalysis': {
        'mostProductiveHour': '12:00 PM',
        'averageCompletionTime': '0h',
        'peakProductivityDay': 'Monday',
        'totalTimeSpent': '0h',
      },
      'streakAnalysis': {
        'currentStreak': 0,
        'longestStreak': 0,
        'streakStartDate': null,
        'daysWithTasks': 0,
      },
      'priorityDistribution': {'high': 0, 'medium': 0, 'low': 0},
      'weeklyPattern': [],
      'monthlyPattern': [],
    };
  }
}
