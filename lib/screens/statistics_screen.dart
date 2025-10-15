// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../services/sentry_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _chartController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _chartAnimation;
  
  String _selectedPeriod = 'week';
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartController, curve: Curves.easeOutCubic),
    );
    
    _fadeController.forward();
    _chartController.forward();
    
    SentryService.addBreadcrumb(
      message: 'statistics_screen_opened',
      category: 'navigation',
      data: {'screen': 'statistics'},
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer2<TaskProvider, AuthProvider>(
          builder: (context, taskProvider, authProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(theme),
                  const SizedBox(height: 24),
                  _buildOverviewCards(taskProvider, theme),
                  const SizedBox(height: 24),
                  _buildProductivityChart(taskProvider, theme),
                  const SizedBox(height: 24),
                  _buildCategoryBreakdown(taskProvider, theme),
                  const SizedBox(height: 24),
                  _buildTimeAnalysis(taskProvider, theme),
                  const SizedBox(height: 24),
                  _buildStreakAnalysis(taskProvider, theme),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: const Color(0xFF1976D2),
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
        ),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.analytics_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).statistics,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showExportOptions(),
          icon: const Icon(Icons.file_download_outlined, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPeriodButton('week', AppLocalizations.of(context).thisWeek, theme),
          _buildPeriodButton('month', AppLocalizations.of(context).thisMonth, theme),
          _buildPeriodButton('year', AppLocalizations.of(context).thisYear, theme),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label, ThemeData theme) {
    final isSelected = _selectedPeriod == period;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectPeriod(period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1976D2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(TaskProvider taskProvider, ThemeData theme) {
    final stats = _calculateStats(taskProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).overview,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildStatCard(
              AppLocalizations.of(context).totalTasks,
              stats['totalTasks'].toString(),
              Icons.task_alt_rounded,
              const Color(0xFF2196F3),
              theme,
            ),
            _buildStatCard(
              AppLocalizations.of(context).completed,
              stats['completedTasks'].toString(),
              Icons.check_circle_rounded,
              const Color(0xFF4CAF50),
              theme,
            ),
            _buildStatCard(
              AppLocalizations.of(context).completionRate,
              '${stats['completionRate']}%',
              Icons.trending_up_rounded,
              const Color(0xFFFF9800),
              theme,
            ),
            _buildStatCard(
              AppLocalizations.of(context).averagePerDay,
              stats['averagePerDay'].toString(),
              Icons.calendar_today_rounded,
              const Color(0xFF9C27B0),
              theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, ThemeData theme) {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _chartAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductivityChart(TaskProvider taskProvider, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                color: const Color(0xFF1976D2),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).productivityTrend,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSimpleChart(taskProvider, theme),
        ],
      ),
    );
  }

  Widget _buildSimpleChart(TaskProvider taskProvider, ThemeData theme) {
    final chartData = _getChartData(taskProvider);
    
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chartData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final maxValue = chartData.map((e) => e['value'] as int).reduce(math.max);
              final height = maxValue > 0 ? (data['value'] as int) / maxValue * 160 : 0.0;
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 800 + (index * 100)),
                        height: height * _chartAnimation.value,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              const Color(0xFF1976D2),
                              const Color(0xFF1976D2).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCategoryBreakdown(TaskProvider taskProvider, ThemeData theme) {
    final categories = _getCategoryStats(taskProvider);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart_rounded,
                color: const Color(0xFF1976D2),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).categoryBreakdown,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...categories.map((category) => _buildCategoryItem(category, theme)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category, ThemeData theme) {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: category['color'],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category['name'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '${category['count']}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: LinearProgressIndicator(
                  value: (category['percentage'] / 100) * _chartAnimation.value,
                  backgroundColor: category['color'].withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(category['color']),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${category['percentage']}%',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeAnalysis(TaskProvider taskProvider, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                color: const Color(0xFF1976D2),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).timeAnalysis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTimeMetric(
                  AppLocalizations.of(context).mostProductiveHour,
                  '2:00 PM',
                  Icons.wb_sunny_rounded,
                  const Color(0xFFFFB300),
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeMetric(
                  AppLocalizations.of(context).averageCompletionTime,
                  '1.5h',
                  Icons.timer_rounded,
                  const Color(0xFF4CAF50),
                  theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeMetric(String title, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakAnalysis(TaskProvider taskProvider, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE53935).withOpacity(0.8),
            const Color(0xFFD32F2F).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).streakAnalysis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStreakMetric(
                  AppLocalizations.of(context).currentStreak,
                  '7',
                  AppLocalizations.of(context).days,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStreakMetric(
                  AppLocalizations.of(context).longestStreak,
                  '15',
                  AppLocalizations.of(context).days,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakMetric(String title, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Map<String, int> _calculateStats(TaskProvider taskProvider) {
    final tasks = taskProvider.tasks;
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final totalTasks = tasks.length;
    final completionRate = totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;
    final averagePerDay = totalTasks > 0 ? (totalTasks / 7).round() : 0; // Mock calculation
    
    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'completionRate': completionRate,
      'averagePerDay': averagePerDay,
    };
  }

  List<Map<String, dynamic>> _getChartData(TaskProvider taskProvider) {
    // Mock data for demonstration - in a real app, this would be calculated from actual task data
    return [
      {'label': 'Mon', 'value': 5},
      {'label': 'Tue', 'value': 8},
      {'label': 'Wed', 'value': 3},
      {'label': 'Thu', 'value': 12},
      {'label': 'Fri', 'value': 7},
      {'label': 'Sat', 'value': 4},
      {'label': 'Sun', 'value': 6},
    ];
  }

  List<Map<String, dynamic>> _getCategoryStats(TaskProvider taskProvider) {
    // Mock data for demonstration - in a real app, this would be calculated from actual task data
    final totalTasks = taskProvider.tasks.length;
    
    return [
      {
        'name': 'Work',
        'count': (totalTasks * 0.4).round(),
        'percentage': 40,
        'color': const Color(0xFF2196F3),
      },
      {
        'name': 'Personal',
        'count': (totalTasks * 0.3).round(),
        'percentage': 30,
        'color': const Color(0xFF4CAF50),
      },
      {
        'name': 'Health',
        'count': (totalTasks * 0.2).round(),
        'percentage': 20,
        'color': const Color(0xFFFF9800),
      },
      {
        'name': 'Other',
        'count': (totalTasks * 0.1).round(),
        'percentage': 10,
        'color': const Color(0xFF9C27B0),
      },
    ];
  }

  void _selectPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    
    SentryService.addBreadcrumb(
      message: 'statistics_period_changed',
      category: 'statistics',
      data: {'period': period},
    );
  }

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).exportStatistics),
        content: Text(AppLocalizations.of(context).exportStatisticsDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, this would export the statistics
            },
            child: Text(AppLocalizations.of(context).export),
          ),
        ],
      ),
    );
  }
}
