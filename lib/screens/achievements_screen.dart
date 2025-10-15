// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../services/sentry_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
    
    SentryService.addBreadcrumb(
      message: 'achievements_screen_opened',
      category: 'navigation',
      data: {'screen': 'achievements'},
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
                  _buildStatsOverview(taskProvider, theme),
                  const SizedBox(height: 24),
                  _buildAchievementCategories(taskProvider, theme),
                  const SizedBox(height: 24),
                  _buildRecentAchievements(taskProvider, theme),
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
              Icons.emoji_events_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).achievements,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(TaskProvider taskProvider, ThemeData theme) {
    final completedTasks = taskProvider.tasks.where((task) => task.isCompleted).length;
    final totalTasks = taskProvider.tasks.length;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100).round() : 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1976D2).withOpacity(0.8),
            const Color(0xFF1565C0).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.3),
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
                Icons.trending_up_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).yourProgress,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  AppLocalizations.of(context).totalTasks,
                  totalTasks.toString(),
                  Icons.task_alt_rounded,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  AppLocalizations.of(context).completed,
                  completedTasks.toString(),
                  Icons.check_circle_rounded,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  AppLocalizations.of(context).completionRate,
                  '$completionRate%',
                  Icons.percent_rounded,
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
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
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCategories(TaskProvider taskProvider, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).achievementCategories,
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
          childAspectRatio: 1.2,
          children: [
            _buildAchievementCategory(
              AppLocalizations.of(context).taskMaster,
              AppLocalizations.of(context).taskMasterDesc,
              Icons.task_alt_rounded,
              const Color(0xFF4CAF50),
              _getTaskMasterProgress(taskProvider),
              theme,
            ),
            _buildAchievementCategory(
              AppLocalizations.of(context).streakWarrior,
              AppLocalizations.of(context).streakWarriorDesc,
              Icons.local_fire_department_rounded,
              const Color(0xFFFF5722),
              _getStreakProgress(taskProvider),
              theme,
            ),
            _buildAchievementCategory(
              AppLocalizations.of(context).earlyBird,
              AppLocalizations.of(context).earlyBirdDesc,
              Icons.wb_sunny_rounded,
              const Color(0xFFFFB300),
              _getEarlyBirdProgress(taskProvider),
              theme,
            ),
            _buildAchievementCategory(
              AppLocalizations.of(context).voiceChampion,
              AppLocalizations.of(context).voiceChampionDesc,
              Icons.mic_rounded,
              const Color(0xFF9C27B0),
              _getVoiceProgress(taskProvider),
              theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementCategory(
    String title,
    String description,
    IconData icon,
    Color color,
    double progress,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
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
          Row(
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
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAchievements(TaskProvider taskProvider, ThemeData theme) {
    final recentAchievements = _getRecentAchievements(taskProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).recentAchievements,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        if (recentAchievements.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).noAchievementsYet,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).completeTasksToEarn,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...recentAchievements.map((achievement) => _buildAchievementItem(achievement, theme)),
      ],
    );
  }

  Widget _buildAchievementItem(Map<String, dynamic> achievement, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement['color'].withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: achievement['color'].withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: achievement['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              achievement['icon'],
              color: achievement['color'],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: achievement['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppLocalizations.of(context).unlocked,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: achievement['color'],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getTaskMasterProgress(TaskProvider taskProvider) {
    final completedTasks = taskProvider.tasks.where((task) => task.isCompleted).length;
    return (completedTasks / 100).clamp(0.0, 1.0); // Progress towards 100 tasks
  }

  double _getStreakProgress(TaskProvider taskProvider) {
    // Simple streak calculation - in a real app, this would track daily completion streaks
    final completedTasks = taskProvider.tasks.where((task) => task.isCompleted).length;
    return (completedTasks / 30).clamp(0.0, 1.0); // Progress towards 30-day streak
  }

  double _getEarlyBirdProgress(TaskProvider taskProvider) {
    // Simple early completion calculation
    final completedTasks = taskProvider.tasks.where((task) => task.isCompleted).length;
    return (completedTasks / 50).clamp(0.0, 1.0); // Progress towards 50 early completions
  }

  double _getVoiceProgress(TaskProvider taskProvider) {
    // Simple voice task calculation
    final totalTasks = taskProvider.tasks.length;
    return (totalTasks / 25).clamp(0.0, 1.0); // Progress towards 25 voice-created tasks
  }

  List<Map<String, dynamic>> _getRecentAchievements(TaskProvider taskProvider) {
    final completedTasks = taskProvider.tasks.where((task) => task.isCompleted).length;
    final achievements = <Map<String, dynamic>>[];

    if (completedTasks >= 1) {
      achievements.add({
        'title': AppLocalizations.of(context).firstTaskComplete,
        'description': AppLocalizations.of(context).firstTaskCompleteDesc,
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF4CAF50),
      });
    }

    if (completedTasks >= 5) {
      achievements.add({
        'title': AppLocalizations.of(context).taskNovice,
        'description': AppLocalizations.of(context).taskNoviceDesc,
        'icon': Icons.star_rounded,
        'color': const Color(0xFFFFB300),
      });
    }

    if (completedTasks >= 10) {
      achievements.add({
        'title': AppLocalizations.of(context).taskExplorer,
        'description': AppLocalizations.of(context).taskExplorerDesc,
        'icon': Icons.explore_rounded,
        'color': const Color(0xFF2196F3),
      });
    }

    return achievements.take(3).toList(); // Show only recent 3 achievements
  }
}
