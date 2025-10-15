// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../services/sentry_service.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  
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
    _tabController = TabController(length: 3, vsync: this);
    
    _fadeController.forward();
    
    SentryService.addBreadcrumb(
      message: 'habits_screen_opened',
      category: 'navigation',
      data: {'screen': 'habits'},
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
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
        child: Column(
          children: [
            _buildTabBar(theme),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveHabitsTab(),
                  _buildHabitInsightsTab(),
                  _buildHabitTemplatesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHabitDialog(),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(AppLocalizations.of(context).addHabit),
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
              Icons.track_changes_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).habits,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1976D2),
            Color(0xFF1565C0),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: [
          _buildEnhancedTab(AppLocalizations.of(context).active, Icons.trending_up_rounded),
          _buildEnhancedTab(AppLocalizations.of(context).insights, Icons.analytics_rounded),
          _buildEnhancedTab(AppLocalizations.of(context).templates, Icons.library_books_rounded),
        ],
      ),
    );
  }

  Widget _buildEnhancedTab(String text, IconData icon) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveHabitsTab() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final habitTasks = taskProvider.tasks.where((task) => 
          task.recurringPattern != null && task.recurringPattern!.isNotEmpty).toList();
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHabitStats(habitTasks),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).yourHabits,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: habitTasks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: habitTasks.length,
                        itemBuilder: (context, index) {
                          return _buildHabitCard(habitTasks[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHabitStats(List<dynamic> habitTasks) {
    final activeHabits = habitTasks.length;
    final completedToday = habitTasks.where((task) => task.isCompleted).length;
    const streakDays = 7; // Mock streak calculation
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withOpacity(0.8),
            const Color(0xFF388E3C).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              AppLocalizations.of(context).activeHabits,
              activeHabits.toString(),
              Icons.track_changes_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              AppLocalizations.of(context).completedToday,
              completedToday.toString(),
              Icons.check_circle_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              AppLocalizations.of(context).currentStreak,
              '$streakDays ${AppLocalizations.of(context).days}',
              Icons.local_fire_department_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHabitCard(dynamic task) {
    final theme = Theme.of(context);
    final isCompleted = task.isCompleted;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted 
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted 
                ? const Color(0xFF4CAF50).withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCompleted 
                ? const Color(0xFF4CAF50).withOpacity(0.1)
                : const Color(0xFF1976D2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isCompleted ? const Color(0xFF4CAF50) : const Color(0xFF1976D2),
            size: 24,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${AppLocalizations.of(context).frequency}: ${_getFrequencyText(task.recurringPattern)}',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            _buildHabitProgress(0.7), // Mock progress
          ],
        ),
        trailing: IconButton(
          onPressed: () => _toggleHabitCompletion(task),
          icon: Icon(
            isCompleted ? Icons.undo_rounded : Icons.check_rounded,
            color: isCompleted ? Colors.orange : const Color(0xFF4CAF50),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitProgress(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).weeklyProgress,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).noHabitsYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).createFirstHabit,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddHabitDialog(),
            icon: const Icon(Icons.add_rounded),
            label: Text(AppLocalizations.of(context).addHabit),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitInsightsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).habitInsights,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildInsightCard(
                  AppLocalizations.of(context).weeklyOverview,
                  AppLocalizations.of(context).weeklyOverviewDesc,
                  Icons.calendar_view_week_rounded,
                  const Color(0xFF2196F3),
                ),
                _buildInsightCard(
                  AppLocalizations.of(context).bestPerformingHabits,
                  AppLocalizations.of(context).bestPerformingHabitsDesc,
                  Icons.trending_up_rounded,
                  const Color(0xFF4CAF50),
                ),
                _buildInsightCard(
                  AppLocalizations.of(context).improvementAreas,
                  AppLocalizations.of(context).improvementAreasDesc,
                  Icons.lightbulb_outline_rounded,
                  const Color(0xFFFF9800),
                ),
                _buildInsightCard(
                  AppLocalizations.of(context).streakAnalysis,
                  AppLocalizations.of(context).streakAnalysisDesc,
                  Icons.local_fire_department_rounded,
                  const Color(0xFFFF5722),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String description, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildHabitTemplatesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).habitTemplates,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildTemplateCard(
                  AppLocalizations.of(context).healthFitness,
                  Icons.fitness_center_rounded,
                  const Color(0xFF4CAF50),
                  ['Exercise', 'Drink Water', 'Take Vitamins'],
                ),
                _buildTemplateCard(
                  AppLocalizations.of(context).productivity,
                  Icons.work_outline_rounded,
                  const Color(0xFF2196F3),
                  ['Read Books', 'Learn Skills', 'Plan Day'],
                ),
                _buildTemplateCard(
                  AppLocalizations.of(context).mindfulness,
                  Icons.self_improvement_rounded,
                  const Color(0xFF9C27B0),
                  ['Meditate', 'Journal', 'Gratitude'],
                ),
                _buildTemplateCard(
                  AppLocalizations.of(context).socialLife,
                  Icons.people_outline_rounded,
                  const Color(0xFFFF5722),
                  ['Call Family', 'Meet Friends', 'Network'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(String title, IconData icon, Color color, List<String> habits) {
    final theme = Theme.of(context);
    
    return Container(
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
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...habits.take(2).map((habit) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $habit',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          )),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _useTemplate(title, habits),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                AppLocalizations.of(context).useTemplate,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFrequencyText(String? pattern) {
    if (pattern == null) return AppLocalizations.of(context).daily;
    switch (pattern.toLowerCase()) {
      case 'daily':
        return AppLocalizations.of(context).daily;
      case 'weekly':
        return AppLocalizations.of(context).weekly;
      case 'monthly':
        return AppLocalizations.of(context).monthly;
      default:
        return AppLocalizations.of(context).daily;
    }
  }

  void _toggleHabitCompletion(dynamic task) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.toggleTaskCompletion(task.id);
    
    SentryService.addBreadcrumb(
      message: 'habit_toggled',
      category: 'habit',
      data: {'taskId': task.id, 'completed': !task.isCompleted},
    );
  }

  void _showAddHabitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).addNewHabit),
        content: Text(AppLocalizations.of(context).addHabitDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/add-task');
            },
            child: Text(AppLocalizations.of(context).createHabit),
          ),
        ],
      ),
    );
  }

  void _useTemplate(String templateName, List<String> habits) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${AppLocalizations.of(context).useTemplate}: $templateName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).templateWillCreate),
            const SizedBox(height: 12),
            ...habits.map((habit) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $habit'),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, this would create multiple recurring tasks
              Navigator.pushNamed(context, '/add-task');
            },
            child: Text(AppLocalizations.of(context).createHabits),
          ),
        ],
      ),
    );
  }
}
