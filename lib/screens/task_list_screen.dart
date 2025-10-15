// ignore_for_file: avoid_print, prefer_final_fields, deprecated_member_use, use_build_context_synchronously, prefer_const_constructors, unused_import, unnecessary_import

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/filter_dialog.dart';
import '../utils/notification_helper.dart';
import 'add_task_screen.dart';
import '../screens/account_settings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/premium_purchase_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/habits_screen.dart';
import '../screens/focus_screen.dart';
import '../screens/statistics_screen.dart';
import '../widgets/task_calendar.dart';
import '../providers/auth_provider.dart';
import '../services/ad_service.dart';
import '../services/voice_integration_service.dart';
import '../services/sentry_service.dart';
import '../providers/voice_provider.dart';
import '../l10n/app_localizations.dart';

// Performance optimization class to reduce rebuilds
class TaskProviderState {
  final bool isLoading;
  final String? error;
  final List<Task> tasks;
  final bool hasData;

  TaskProviderState({
    required this.isLoading,
    required this.error,
    required this.tasks,
    required this.hasData,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskProviderState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          error == other.error &&
          tasks.length == other.tasks.length &&
          hasData == other.hasData;

  @override
  int get hashCode =>
      isLoading.hashCode ^
      error.hashCode ^
      tasks.length.hashCode ^
      hasData.hashCode;
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  String _selectedCategory = 'all';
  TaskProvider? _taskProvider; // Store reference to avoid context access in dispose
  bool _listenerAdded = false; // Track if listener was added

  @override
  void initState() {
    super.initState();
    
    // Reduced Sentry logging for performance - only log critical errors
    try {
      _tabController = TabController(length: 4, vsync: this);
      _fabAnimationController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
      );
      _fabAnimationController.forward();
      
      // Initialize voice service asynchronously with delay to not block UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Delay voice service initialization to allow UI to render first
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _initializeVoiceService();
            }
          });
        }
      });
    } catch (e, stackTrace) {
      // Only log critical errors to reduce overhead
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error in TaskListScreen initState',
        extra: {'screen': 'TaskListScreen'},
      );
      print('Error in initState: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildEnhancedAppBar(theme),
      body: Selector<TaskProvider, TaskProviderState>(
        selector: (context, taskProvider) => TaskProviderState(
          isLoading: taskProvider.isLoading,
          error: taskProvider.error,
          tasks: taskProvider.tasks,
          hasData: taskProvider.tasks.isNotEmpty,
        ),
        builder: (context, state, child) {
          final taskProvider = Provider.of<TaskProvider>(context, listen: false);
          if (state.isLoading && state.tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context).loading,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state.error != null && state.tasks.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 32,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).somethingWentWrong,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${AppLocalizations.of(context).error}: ${taskProvider.error}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        taskProvider.clearError();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context).retry),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Only essential non-scrollable widgets at top
              _buildVoiceStatusIndicator(),
              _buildEnhancedLiveVoiceTranscript(),
              _buildEnhancedActiveFilters(),
              
              // Main content - scrollable with header widgets integrated
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskListWithHeaders(taskProvider, taskProvider.filteredTasks),
                    _buildTaskListWithHeaders(taskProvider, taskProvider.filteredTasks.where((t) => !t.isCompleted).toList()),
                    _buildTaskListWithHeaders(taskProvider, taskProvider.filteredTasks.where((t) => t.isCompleted).toList()),
                    _buildRemindersListWithHeaders(taskProvider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const AddTaskScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 8.0,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
          icon: const Icon(Icons.add_rounded, size: 24),
          label: Text(
            AppLocalizations.of(context).addTask,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskListWithHeaders(TaskProvider taskProvider, List<Task> tasks) {
    List<Task> filteredTasks = taskProvider.hasActiveFilters 
        ? tasks
        : (_selectedCategory == 'all' 
            ? tasks 
            : tasks.where((task) => task.category == _selectedCategory).toList());

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          // Header widgets as slivers
          SliverToBoxAdapter(child: _buildEnhancedProductivityScore()),
          SliverToBoxAdapter(child: _buildEnhancedPremiumSection()),
          SliverToBoxAdapter(child: _buildEnhancedAdBanner()),
          SliverToBoxAdapter(child: _buildEnhancedReminderStats()),
          
          // Task list content
          filteredTasks.isEmpty
              ? SliverFillRemaining(
                  child: _buildEmptyTaskState(taskProvider),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return RepaintBoundary(
                        key: ValueKey('task_${task.id}'),
                        child: TaskCard(
                          key: ValueKey('taskcard_${task.id}'),
                          task: task,
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildRemindersListWithHeaders(TaskProvider taskProvider) {
    final tasksWithReminders = taskProvider.tasksWithReminders;
    final overdueReminders = taskProvider.overdueReminders;
    
    if (tasksWithReminders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: CustomScrollView(
          slivers: [
            // Header widgets as slivers
            SliverToBoxAdapter(child: _buildEnhancedProductivityScore()),
            SliverToBoxAdapter(child: _buildEnhancedPremiumSection()),
            SliverToBoxAdapter(child: _buildEnhancedAdBanner()),
            SliverToBoxAdapter(child: _buildEnhancedReminderStats()),
            
            // Empty state
            SliverFillRemaining(
              child: _buildEmptyReminderState(),
            ),
          ],
        ),
      );
    }

    final sortedReminders = [...tasksWithReminders]
      ..sort((a, b) {
        if (a.reminderTime == null) return 1;
        if (b.reminderTime == null) return -1;
        return a.reminderTime!.compareTo(b.reminderTime!);
      });

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          // Header widgets as slivers
          SliverToBoxAdapter(child: _buildEnhancedProductivityScore()),
          SliverToBoxAdapter(child: _buildEnhancedPremiumSection()),
          SliverToBoxAdapter(child: _buildEnhancedAdBanner()),
          SliverToBoxAdapter(child: _buildEnhancedReminderStats()),
          
          // Overdue reminders warning
          if (overdueReminders.isNotEmpty)
            SliverToBoxAdapter(child: _buildOverdueRemindersWarning(overdueReminders)),
          
          // Reminders list
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList.builder(
              itemCount: sortedReminders.length,
              itemBuilder: (context, index) {
                final task = sortedReminders[index];
                return RepaintBoundary(
                  key: ValueKey('reminder_${task.id}'),
                  child: TaskCard(
                    key: ValueKey('remindercard_${task.id}'),
                    task: task,
                    showAnalytics: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTaskState(TaskProvider taskProvider) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                taskProvider.hasActiveFilters 
                    ? Icons.filter_list_off_rounded
                    : (_selectedCategory == 'all' 
                        ? Icons.task_alt_rounded 
                        : Icons.category_rounded),
                size: 30,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              taskProvider.hasActiveFilters 
                  ? AppLocalizations.of(context).noTasksFound
                  : (_selectedCategory == 'all' 
                      ? AppLocalizations.of(context).noTasksFound 
                      : AppLocalizations.of(context).noTasksFound),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              taskProvider.hasActiveFilters 
                  ? AppLocalizations.of(context).noTasksFound
                  : (_selectedCategory == 'all' 
                      ? AppLocalizations.of(context).noTasksFound 
                      : AppLocalizations.of(context).noTasksFound),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (taskProvider.hasActiveFilters) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  taskProvider.clearAllFilters();
                  setState(() {});
                },
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: Text(AppLocalizations.of(context).clearAll),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyReminderState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.notifications_off_rounded,
                size: 30,
                color: Colors.blue.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noTasksFound,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).noTasksFound,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueRemindersWarning(List<Task> overdueReminders) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.1),
            Colors.red.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.warning_rounded,
              color: Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).overdueReminders,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${overdueReminders.length} reminder${overdueReminders.length > 1 ? 's' : ''} ${AppLocalizations.of(context).reminderNeedAttention}',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${overdueReminders.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }


  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'work': return Icons.work_rounded;
      case 'personal': return Icons.person_rounded;
      case 'health': return Icons.health_and_safety_rounded;
      case 'shopping': return Icons.shopping_cart_rounded;
      case 'study': return Icons.school_rounded;
      default: return Icons.category_rounded;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high': return Icons.keyboard_arrow_up_rounded;
      case 'medium': return Icons.remove_rounded;
      case 'low': return Icons.keyboard_arrow_down_rounded;
      default: return Icons.remove_rounded;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _showFilterDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const FilterDialog(),
    );
    
    if (result == true) {
      setState(() {});
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 'calendar': 
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const TaskCalendar(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 'settings':
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AccountSettingsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 'achievements':
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AchievementsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 'habits':
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HabitsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 'focus':
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const FocusScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 'statistics':
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const StatisticsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 'logout':
        _showLogoutConfirmation();
        break;
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Colors.red,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).signOut,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.of(context).signOutConfirm,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context).cancel,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthProvider>().signOut();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: Text(
                AppLocalizations.of(context).signOut,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _initializeVoiceService() async {
    if (!mounted) return;
    
    // Run voice service initialization in background without blocking UI
    try {
      SentryService.logVoiceOperation('voice_service_initialization_start');
      print('TaskListScreen: Starting voice service initialization...');
      
      // Initialize components in parallel for better performance
      final futures = <Future>[];
      
      // Initialize voice integration service
      futures.add(VoiceIntegrationService.initializeVoiceIntegration(context).catchError((e) {
        print('Voice integration service failed: $e');
        return null;
      }));
      
      if (!mounted) return;
      
      // Initialize TaskProvider voice commands
      _taskProvider = context.read<TaskProvider>();
      futures.add(_taskProvider!.initializeVoiceCommands().catchError((e) {
        print('Task provider voice commands failed: $e');
        return null;
      }));
      
      // Wait for all initializations to complete
      await Future.wait(futures, eagerError: false);
      
      if (!mounted) return;
      
      // Set voice status (non-blocking)
      final voiceProvider = context.read<VoiceProvider>();
      try {
        voiceProvider.setVoiceStatus(AppLocalizations.of(context).voiceCommandsReady);
        SentryService.logVoiceOperation('voice_status_set_localized');
      } catch (e) {
        voiceProvider.setVoiceStatus('Voice commands ready');
        SentryService.logVoiceOperation('voice_status_set_fallback');
      }
      
      // Listen to TaskProvider voice command state changes
      if (mounted && !_listenerAdded) {
        _taskProvider!.addListener(_updateVoiceStatus);
        _listenerAdded = true;
        SentryService.logVoiceOperation('voice_status_listener_added');
        print('Voice status listener added successfully');
      }
      
      SentryService.logVoiceOperation('voice_service_initialization_complete');
      print('Voice service initialized successfully');
    } catch (e) {
      print('Voice service initialization error: $e');
      SentryService.logVoiceOperation('voice_service_initialization_error');
      
      if (mounted) {
        try {
          final voiceProvider = context.read<VoiceProvider>();
          try {
            voiceProvider.setVoiceStatus(AppLocalizations.of(context).voiceServiceUnavailable);
            SentryService.logVoiceOperation('voice_status_set_error_localized');
          } catch (e) {
            voiceProvider.setVoiceStatus('Voice service unavailable');
            SentryService.logVoiceOperation('voice_status_set_error_fallback');
          }
        } catch (e) {
          SentryService.logVoiceOperation('voice_status_set_failed_context_invalid');
          print('Could not set voice status - context invalid');
        }
      }
    }
  }
  
  void _updateVoiceStatus() {
    if (!mounted) return;
    
    try {
      final taskProvider = _taskProvider ?? context.read<TaskProvider>();
      final voiceProvider = context.read<VoiceProvider>();
      
      voiceProvider.setProcessingVoiceCommand(taskProvider.isProcessingVoiceCommand);
      voiceProvider.setVoiceListening(taskProvider.isVoiceCommandActive);
      
      // Use fallback strings if context is invalid
      String statusMessage;
      if (taskProvider.isProcessingVoiceCommand) {
        try {
          statusMessage = '${AppLocalizations.of(context).processing} voice command: "${taskProvider.lastVoiceCommand}"';
        } catch (e) {
          statusMessage = 'Processing voice command: "${taskProvider.lastVoiceCommand}"';
        }
      } else if (taskProvider.isVoiceCommandActive) {
        try {
          statusMessage = AppLocalizations.of(context).listeningForHeyWhisp;
        } catch (e) {
          statusMessage = 'Listening for Hey Whisp...';
        }
      } else {
        try {
          statusMessage = AppLocalizations.of(context).voiceCommandsReady;
        } catch (e) {
          statusMessage = 'Voice commands ready';
        }
      }
      
      voiceProvider.setVoiceStatus(statusMessage);
    } catch (e) {
      print('Voice status update skipped - widget disposed or context invalid: $e');
    }
  }

  Widget _buildVoiceStatusIndicator() {
    return Consumer<VoiceProvider>(
      builder: (context, voiceProvider, child) {
        if (!voiceProvider.isVoiceListening && !voiceProvider.isProcessingVoiceCommand) {
          return const SizedBox.shrink();
        }
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: voiceProvider.isProcessingVoiceCommand 
                  ? [
                      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
                      Theme.of(context).colorScheme.primaryContainer,
                    ]
                  : [
                      Colors.green.withOpacity(0.1),
                      Colors.green.withOpacity(0.2),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: voiceProvider.isProcessingVoiceCommand 
                  ? Theme.of(context).colorScheme.primary 
                  : Colors.green,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (voiceProvider.isProcessingVoiceCommand 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.green).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: voiceProvider.isProcessingVoiceCommand 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: voiceProvider.isProcessingVoiceCommand
                    ? Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.mic,
                        color: Colors.green,
                        size: 16,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voiceProvider.isProcessingVoiceCommand 
                          ? AppLocalizations.of(context).processing 
                          : AppLocalizations.of(context).listening,
                      style: TextStyle(
                        color: voiceProvider.isProcessingVoiceCommand 
                            ? Theme.of(context).colorScheme.primary 
                            : Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      voiceProvider.voiceStatus,
                      style: TextStyle(
                        color: voiceProvider.isProcessingVoiceCommand 
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                            : Colors.green.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (voiceProvider.isVoiceListening || voiceProvider.isProcessingVoiceCommand)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        try {
                          final taskProvider = _taskProvider ?? context.read<TaskProvider>();
                          taskProvider.stopWakeWordListening();
                          voiceProvider.setVoiceListening(false);
                          try {
                            voiceProvider.setVoiceStatus(AppLocalizations.of(context).voiceInputHint);
                          } catch (e) {
                            voiceProvider.setVoiceStatus('Voice input hint');
                          }
                        } catch (e) {
                          print('Error stopping voice listening: $e');
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedLiveVoiceTranscript() {
    return Consumer<VoiceProvider>(
      builder: (context, voiceProvider, child) {
        if (voiceProvider.liveRecognizedText.isEmpty || !voiceProvider.isVoiceListening) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '"${voiceProvider.liveRecognizedText}"',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedProductivityScore() {
    return Selector<TaskProvider, double>(
      selector: (context, taskProvider) => taskProvider.dailyProductivityScore,
      builder: (context, score, child) {
        final theme = Theme.of(context);
        final Color scoreColor = score > 70 ? Colors.green : 
                                 score > 40 ? Colors.orange : theme.colorScheme.error;
        
        return RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scoreColor.withOpacity(0.1),
                  scoreColor.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scoreColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: scoreColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      color: scoreColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).todaysProductivity,
                          style: TextStyle(
                            color: scoreColor.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${score.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: scoreColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: scoreColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: scoreColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      score > 70 ? AppLocalizations.of(context).great : 
                      score > 40 ? AppLocalizations.of(context).good : 
                      AppLocalizations.of(context).keepGoing,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedPremiumSection() {
    return Selector<AuthProvider, bool>(
      selector: (context, authProvider) => authProvider.isPremium,
      builder: (context, isPremium, child) {
        if (isPremium) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context).premiumFeaturesList,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(AppLocalizations.of(context).customVoicePacks, Icons.record_voice_over_rounded),
                _buildFeatureItem(AppLocalizations.of(context).offlineMode, Icons.offline_bolt_rounded),
                _buildFeatureItem(AppLocalizations.of(context).smartTags, Icons.auto_awesome_rounded),
                _buildFeatureItem(AppLocalizations.of(context).customThemes, Icons.palette_rounded),
                _buildFeatureItem(AppLocalizations.of(context).advancedAnalytics, Icons.analytics_rounded),
                _buildFeatureItem(AppLocalizations.of(context).noAds, Icons.block_rounded),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const PremiumPurchaseScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              )),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    },
                    icon: const Icon(Icons.upgrade_rounded, size: 20),
                    label: Text(
                      AppLocalizations.of(context).upgradeToPro,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAdBanner() {
    return Selector<AuthProvider, bool>(
      selector: (context, authProvider) => authProvider.isPremium,
      builder: (context, isPremium, child) {
        if (isPremium) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                Theme.of(context).colorScheme.surfaceVariant,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.ads_click_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).advertisementSpace,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context).supportTheAppWithPremium,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppLocalizations.of(context).removeWithPro,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedActiveFilters() {
    return Selector<TaskProvider, bool>(
      selector: (context, taskProvider) => taskProvider.hasActiveFilters,
      builder: (context, hasActiveFilters, child) {
        if (!hasActiveFilters) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.filter_alt_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).activeFilters,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      context.read<TaskProvider>().clearAllFilters();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: Text(
                      AppLocalizations.of(context).clearAll,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildActiveFilterChips(context.read<TaskProvider>()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedReminderStats() {
    return Selector<TaskProvider, ({int reminders, int overdue})>(
      selector: (context, taskProvider) => (
        reminders: taskProvider.tasksWithReminders.length,
        overdue: taskProvider.overdueReminders.length
      ),
      builder: (context, counts, child) {
        if (counts.reminders == 0) return const SizedBox.shrink();
        
        final isOverdue = counts.overdue > 0;
        final color = isOverdue ? Colors.red : Colors.blue;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isOverdue ? Icons.warning_rounded : Icons.notifications_active_rounded,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOverdue ? AppLocalizations.of(context).overdueReminders : AppLocalizations.of(context).activeReminders,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOverdue
                          ? '${counts.overdue} reminder${counts.overdue > 1 ? 's' : ''} ${AppLocalizations.of(context).reminderNeedsAttention}'
                          : '${counts.reminders} reminder${counts.reminders > 1 ? 's' : ''} ${AppLocalizations.of(context).reminderSet}',
                      style: TextStyle(
                        color: color.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${counts.overdue}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildActiveFilterChips(TaskProvider taskProvider) {
    List<Widget> chips = [];

    // Category filters
    for (String category in taskProvider.selectedCategories) {
      chips.add(_buildEnhancedFilterChip(
        label: category.toUpperCase(),
        icon: _getCategoryIcon(category),
        onRemove: () {
          taskProvider.toggleCategoryFilter(category);
          setState(() {});
        },
      ));
    }

    // Priority filters
    for (String priority in taskProvider.selectedPriorities) {
      chips.add(_buildEnhancedFilterChip(
        label: priority.toUpperCase(),
        icon: _getPriorityIcon(priority),
        color: _getPriorityColor(priority),
        onRemove: () {
          taskProvider.togglePriorityFilter(priority);
          setState(() {});
        },
      ));
    }

    // Status filters
    for (String status in taskProvider.selectedStatuses) {
      chips.add(_buildEnhancedFilterChip(
        label: status.toUpperCase(),
        icon: status == 'completed' ? Icons.check_circle_rounded : Icons.pending_outlined,
        color: status == 'completed' ? Colors.green : Colors.orange,
        onRemove: () {
          taskProvider.toggleStatusFilter(status);
          setState(() {});
        },
      ));
    }

    // Date range filter
    if (taskProvider.hasDateFilter) {
      chips.add(_buildEnhancedFilterChip(
        label: taskProvider.getDateFilterLabel(),
        icon: Icons.date_range_rounded,
        color: Colors.purple,
        onRemove: () {
          taskProvider.clearDateFilter();
          setState(() {});
        },
      ));
    }

    // Special filters
    if (taskProvider.showOverdueOnly) {
      chips.add(_buildEnhancedFilterChip(
        label: AppLocalizations.of(context).overdue.toUpperCase(),
        icon: Icons.warning_rounded,
        color: Colors.red,
        onRemove: () {
          taskProvider.setOverdueFilter(false);
          setState(() {});
        },
      ));
    }

    if (taskProvider.showRecurringOnly) {
      chips.add(_buildEnhancedFilterChip(
        label: AppLocalizations.of(context).recurring.toUpperCase(),
        icon: Icons.repeat_rounded,
        color: Colors.purple,
        onRemove: () {
          taskProvider.setRecurringFilter(false);
          setState(() {});
        },
      ));
    }

    if (taskProvider.showRemindersOnly) {
      chips.add(_buildEnhancedFilterChip(
        label: AppLocalizations.of(context).reminders.toUpperCase(),
        icon: Icons.notifications_active_rounded,
        color: Colors.blue,
        onRemove: () {
          taskProvider.setRemindersFilter(false);
          setState(() {});
        },
      ));
    }

    return chips;
  }

  Widget _buildEnhancedFilterChip({
    required String label,
    required IconData icon,
    Color? color,
    required VoidCallback onRemove,
  }) {
    final chipColor = color ?? Colors.blue;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            chipColor.withOpacity(0.1),
            chipColor.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: chipColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: chipColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: chipColor,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: chipColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onRemove,
                child: Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: chipColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildEnhancedAppBar(ThemeData theme) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.onPrimary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Container(
                color: Colors.white,
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.white,
                      child: Icon(
                        Icons.task_alt_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).whispTask,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      elevation: 0,
      centerTitle: false,
      
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
            indicatorColor: theme.colorScheme.onPrimary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            isScrollable: true,
            dividerColor: Colors.transparent,
            tabAlignment: TabAlignment.start,
            tabs: [
              _buildEnhancedTab(AppLocalizations.of(context).all, Icons.list_rounded),
              _buildEnhancedTab(AppLocalizations.of(context).pending, Icons.pending_outlined),
              _buildEnhancedTab(AppLocalizations.of(context).completed, Icons.check_circle_outline_rounded),
              _buildEnhancedTab(AppLocalizations.of(context).reminders, Icons.notifications_outlined),
            ],
          ),
        ),
      ),
      
      actions: [
        // Voice command button
        Consumer<VoiceProvider>(
          builder: (context, voiceProvider, child) {
            return Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: voiceProvider.isVoiceListening 
                    ? theme.colorScheme.onPrimary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    voiceProvider.isVoiceListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    key: ValueKey(voiceProvider.isVoiceListening),
                    color: voiceProvider.isVoiceListening 
                        ? theme.colorScheme.error 
                        : theme.colorScheme.onPrimary,
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/voice-input');
                },
                tooltip: voiceProvider.isVoiceListening 
                    ? AppLocalizations.of(context).stopVoiceCommands 
                    : AppLocalizations.of(context).startVoiceCommands,
              ),
            );
          },
        ),
        
        // Filter button with indicator
        Container(
          margin: const EdgeInsets.only(right: 4),
          child: Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => _showFilterDialog(),
              ),
              Selector<TaskProvider, bool>(
                selector: (context, taskProvider) => taskProvider.hasActiveFilters,
                builder: (context, hasActiveFilters, child) {
                  if (!hasActiveFilters) return const SizedBox.shrink();
                  
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.error.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        
        // Main menu
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              _buildPopupMenuItem('profile', Icons.person_outline_rounded, AppLocalizations.of(context).profile),
              _buildPopupMenuItem('calendar', Icons.calendar_today_rounded, AppLocalizations.of(context).calendarView),
              const PopupMenuDivider(),
              _buildPopupMenuItem('achievements', Icons.emoji_events_outlined, AppLocalizations.of(context).achievements),
              _buildPopupMenuItem('habits', Icons.track_changes_rounded, AppLocalizations.of(context).habits),
              _buildPopupMenuItem('focus', Icons.center_focus_strong_rounded, AppLocalizations.of(context).focus),
              _buildPopupMenuItem('statistics', Icons.analytics_rounded, AppLocalizations.of(context).statistics),
              const PopupMenuDivider(),
              _buildPopupMenuItem('settings', Icons.settings_outlined, AppLocalizations.of(context).settings),
              _buildPopupMenuItem('logout', Icons.logout_rounded, AppLocalizations.of(context).logout, isDestructive: true),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, IconData icon, String label, {bool isDestructive = false}) {
    return PopupMenuItem(
      value: value,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          
          return Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDestructive 
                      ? Colors.red.withOpacity(0.1)
                      : theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isDestructive 
                      ? Colors.red 
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isDestructive 
                      ? Colors.red 
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEnhancedTab(String text, IconData icon) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void deactivate() {
    SentryService.logWidgetLifecycle('TaskListScreen', 'deactivate');
    // Clean up listener when widget is deactivated
    _cleanupListener();
    super.deactivate();
  }

  @override
  void dispose() {
    SentryService.logWidgetLifecycle('TaskListScreen', 'dispose');
    
    // Ensure listener is cleaned up
    _cleanupListener();
    
    // Dispose controllers
    try {
      _tabController.dispose();
      SentryService.logWidgetLifecycle('TaskListScreen', 'tab_controller_disposed');
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error disposing tab controller',
        extra: {'screen': 'TaskListScreen'},
      );
      print('Error disposing tab controller: $e');
    }
    
    try {
      _fabAnimationController.dispose();
      SentryService.logWidgetLifecycle('TaskListScreen', 'fab_controller_disposed');
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error disposing fab animation controller',
        extra: {'screen': 'TaskListScreen'},
      );
      print('Error disposing fab animation controller: $e');
    }
    
    super.dispose();
  }

  void _cleanupListener() {
    if (_listenerAdded && _taskProvider != null) {
      try {
        _taskProvider!.removeListener(_updateVoiceStatus);
        _listenerAdded = false;
        SentryService.logWidgetLifecycle('TaskListScreen', 'listener_cleaned_up');
        print('Successfully removed voice status listener');
      } catch (e, stackTrace) {
        SentryService.captureException(
          e,
          stackTrace: stackTrace,
          hint: 'Error removing voice status listener',
          extra: {'screen': 'TaskListScreen'},
        );
        print('Error removing listener: $e');
      }
    }
  }
}

// Enhanced TaskTile class with improved UI
class TaskTile extends StatelessWidget {
  final Task task;

  const TaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showTaskDetails(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: task.isCompleted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withOpacity(0.5),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            Provider.of<TaskProvider>(context, listen: false)
                                .toggleTask(task.id!, !task.isCompleted);
                          },
                          child: task.isCompleted
                              ? Icon(
                                  Icons.check_rounded,
                                  color: theme.colorScheme.onPrimary,
                                  size: 16,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted 
                                  ? TextDecoration.lineThrough 
                                  : TextDecoration.none,
                              color: task.isCompleted 
                                  ? theme.colorScheme.onSurface.withOpacity(0.6)
                                  : theme.colorScheme.onSurface,
                              decorationColor: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                          if (task.description != null && task.description!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              task.description!,
                              style: TextStyle(
                                fontSize: 14,
                                color: task.isCompleted 
                                    ? theme.colorScheme.onSurface.withOpacity(0.4)
                                    : theme.colorScheme.onSurface.withOpacity(0.7),
                                decoration: task.isCompleted 
                                    ? TextDecoration.lineThrough 
                                    : TextDecoration.none,
                                decorationColor: theme.colorScheme.onSurface.withOpacity(0.3),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => AddTaskScreen(taskToEdit: task),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.0, 1.0),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      )),
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(milliseconds: 300),
                                ),
                              );
                              break;
                            case 'delete':
                              _showDeleteConfirmation(context, task);
                              break;
                            case 'duplicate':
                              _duplicateTask(context, task);
                              break;
                            case 'snooze_5':
                              Provider.of<TaskProvider>(context, listen: false)
                                  .snoozeReminder(task.id!, 5);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context).reminderSnoozedFor5Minutes),
                                  backgroundColor: theme.colorScheme.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              break;
                            case 'cancel_reminder':
                              Provider.of<TaskProvider>(context, listen: false)
                                  .cancelReminder(task.id!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context).reminderCancelled),
                                  backgroundColor: theme.colorScheme.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              break;
                          }
                        },
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (context) => [
                          _buildPopupMenuItem('edit', Icons.edit_rounded, AppLocalizations.of(context).edit),
                          _buildPopupMenuItem('duplicate', Icons.copy_rounded, AppLocalizations.of(context).duplicate),
                          if (task.hasActiveReminder && !task.isCompleted) ...[
                            const PopupMenuDivider(),
                            _buildPopupMenuItem('snooze_5', Icons.snooze_rounded, AppLocalizations.of(context).snooze5Min),
                            _buildPopupMenuItem('cancel_reminder', Icons.notifications_off_rounded, AppLocalizations.of(context).cancelReminder),
                          ],
                          const PopupMenuDivider(),
                          _buildPopupMenuItem('delete', Icons.delete_rounded, AppLocalizations.of(context).delete, isDestructive: true),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildEnhancedPriorityChip(task.priority),
                    _buildEnhancedCategoryChip(task.category),
                    if (task.dueDate != null)
                      _buildEnhancedDueDateChip(task.dueDate!, context),
                    Text(task.isRecurring ? AppLocalizations.of(context).yes : AppLocalizations.of(context).no),
                    _buildEnhancedRecurringChip(task.recurringPattern ?? 'recurring'),
                    if (task.hasActiveReminder && !task.isCompleted)
                      _buildEnhancedReminderChip(task, context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, IconData icon, String label, {bool isDestructive = false}) {
    return PopupMenuItem(
      value: value,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          
          return Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDestructive 
                      ? Colors.red.withOpacity(0.1)
                      : theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isDestructive 
                      ? Colors.red 
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDestructive 
                        ? Colors.red 
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEnhancedReminderChip(Task task, BuildContext context) {
    final isOverdue = task.reminderTime != null && 
                     task.reminderTime!.isBefore(DateTime.now()) && 
                     !task.isCompleted;
    
    final Color color = isOverdue ? Colors.red : Colors.blue;
    final IconData icon = isOverdue ? Icons.warning_rounded : Icons.notifications_active_rounded;
    final String text = isOverdue ? AppLocalizations.of(context).overdue.toUpperCase() : AppLocalizations.of(context).reminder.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPriorityChip(String priority) {
    Color color;
    IconData icon;
    switch (priority) {
      case 'high':
        color = Colors.red;
        icon = Icons.keyboard_arrow_up_rounded;
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.remove_rounded;
        break;
      case 'low':
        color = Colors.green;
        icon = Icons.keyboard_arrow_down_rounded;
        break;
      default:
        color = Colors.grey;
        icon = Icons.remove_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            priority.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.blue.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.blue.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(NotificationHelper.getCategoryIcon(category), size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            category.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDueDateChip(DateTime dueDate, BuildContext context) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    bool isOverdue = taskDate.isBefore(today);
    bool isToday = taskDate.isAtSameMomentAs(today);
    bool isTomorrow = taskDate.isAtSameMomentAs(today.add(const Duration(days: 1)));

    Color color = Colors.grey;
    String text = '${dueDate.day}/${dueDate.month}';
    IconData icon = Icons.calendar_today_rounded;

    if (isOverdue) {
      color = Colors.red;
      icon = Icons.warning_rounded;
      text = AppLocalizations.of(context).overdue.toUpperCase();
    } else if (isToday) {
      color = Colors.orange;
      icon = Icons.today_rounded;
      text = AppLocalizations.of(context).today.toUpperCase();
    } else if (isTomorrow) {
      color = Colors.blue;
      icon = Icons.calendar_today_rounded;
      text = AppLocalizations.of(context).tomorrow.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRecurringChip(String pattern) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.purple.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.purple.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat_rounded, size: 12, color: Colors.purple),
          const SizedBox(width: 4),
          Text(
            pattern.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailSheet(task: task),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: theme.colorScheme.surface,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.red,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).deleteTask,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.hasActiveReminder 
                  ? AppLocalizations.of(context).taskHasActiveReminderDeleteWarning
                  : AppLocalizations.of(context).areYouSureDeleteTask,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  '"${task.title}"',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context).cancel,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                return FilledButton(
                  onPressed: taskProvider.isDeleting ? null : () async {
                    final success = await taskProvider.deleteTask(task.id!);
                    Navigator.of(context).pop();
                    
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            task.hasActiveReminder 
                              ? AppLocalizations.of(context).taskAndReminderDeletedSuccessfully
                              : AppLocalizations.of(context).taskDeletedSuccessfully
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: taskProvider.isDeleting 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context).delete,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _duplicateTask(BuildContext context, Task originalTask) {
    final duplicatedTask = Task(
      title: '${originalTask.title} (${AppLocalizations.of(context).copy})',
      description: originalTask.description,
      createdAt: DateTime.now(),
      dueDate: originalTask.dueDate,
      priority: originalTask.priority,
      category: originalTask.category,
      color: originalTask.color,
      isRecurring: originalTask.isRecurring,
      recurringPattern: originalTask.recurringPattern,
      hasReminder: false,
      reminderTime: null,
    );

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AddTaskScreen(taskToEdit: duplicatedTask),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

// Enhanced TaskDetailSheet class
class TaskDetailSheet extends StatelessWidget {
  final Task task;

  const TaskDetailSheet({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 16),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.1),
                              theme.colorScheme.primary.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.task_alt_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).taskDetails,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task.isCompleted ? AppLocalizations.of(context).completed : AppLocalizations.of(context).pending,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: task.isCompleted 
                                    ? Colors.green 
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (task.hasActiveReminder)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.1),
                                Colors.blue.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_active_rounded, size: 14, color: Colors.blue[700]),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context).reminder.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Task Title
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      task.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),

                  if (task.description != null && task.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        task.description!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Details Grid
                  _buildDetailItem(
                    context,
                    AppLocalizations.of(context).priority,
                    task.priority.toUpperCase(),
                    Icons.flag_rounded,
                    _getPriorityColor(task.priority),
                  ),
                  
                  _buildDetailItem(
                    context,
                    AppLocalizations.of(context).category, 
                    task.category.toUpperCase(),
                    _getCategoryIcon(task.category),
                    Colors.blue,
                  ),
                  
                  if (task.dueDate != null)
                    _buildDetailItem(
                      context,
                      AppLocalizations.of(context).dueDate,
                      '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year} at ${task.dueDate!.hour}:${task.dueDate!.minute.toString().padLeft(2, '0')}',
                      Icons.calendar_today_rounded,
                      Colors.purple,
                    ),

                  if (task.hasReminder) ...[
                    if (task.reminderTime != null)
                      _buildDetailItem(
                        context,
                        AppLocalizations.of(context).reminderTime,
                        '${task.reminderTime!.day}/${task.reminderTime!.month}/${task.reminderTime!.year} at ${task.reminderTime!.hour}:${task.reminderTime!.minute.toString().padLeft(2, '0')}',
                        Icons.notifications_rounded,
                        Colors.blue,
                      ),
                  ],

                  _buildDetailItem(
                    context,
                    AppLocalizations.of(context).recurring,
                    task.isRecurring ? AppLocalizations.of(context).yes : AppLocalizations.of(context).no,
                    Icons.repeat_rounded,
                    Colors.purple,
                  ),

                  _buildDetailItem(
                    context,
                    AppLocalizations.of(context).status,
                    task.isCompleted ? AppLocalizations.of(context).completed : AppLocalizations.of(context).pending,
                    task.isCompleted ? Icons.check_circle_rounded : Icons.pending_outlined,
                    task.isCompleted ? Colors.green : Colors.orange,
                  ),

                  _buildDetailItem(
                    context,
                    AppLocalizations.of(context).created,
                    '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}',
                    Icons.today_rounded,
                    Colors.grey,
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => AddTaskScreen(taskToEdit: task),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, 1.0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    )),
                                    child: child,
                                  );
                                },
                                transitionDuration: const Duration(milliseconds: 300),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text(
                            'Edit',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Provider.of<TaskProvider>(context, listen: false)
                                .toggleTask(task.id!, !task.isCompleted);
                            Navigator.pop(context);
                          },
                          icon: Icon(task.isCompleted ? Icons.undo_rounded : Icons.check_rounded),
                          label: Text(
                            task.isCompleted ? AppLocalizations.of(context).markPending : AppLocalizations.of(context).markDone,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: task.isCompleted ? Colors.orange : Colors.green,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (task.hasActiveReminder && !task.isCompleted) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Provider.of<TaskProvider>(context, listen: false)
                                  .snoozeReminder(task.id!, 15);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context).reminderSnoozedFor15Minutes),
                                  backgroundColor: theme.colorScheme.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.snooze_rounded),
                            label: Text(
                              AppLocalizations.of(context).snooze15m,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Provider.of<TaskProvider>(context, listen: false)
                                  .cancelReminder(task.id!);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context).reminderCancelled),
                                  backgroundColor: theme.colorScheme.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.notifications_off_rounded),
                            label: Text(
                              AppLocalizations.of(context).cancelReminderButton,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.05),
            color.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'work': return Icons.work_rounded;
      case 'personal': return Icons.person_rounded;
      case 'health': return Icons.health_and_safety_rounded;
      case 'shopping': return Icons.shopping_cart_rounded;
      case 'study': return Icons.school_rounded;
      default: return Icons.category_rounded;
    }
  }
}

// Extension for better task management
extension TaskExtensions on Task {
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return taskDate.isBefore(today);
  }
  
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return taskDate.isAtSameMomentAs(today);
  }
  
  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return taskDate.isAtSameMomentAs(tomorrow);
  }
  
  String get dueDateLabel {
    if (dueDate == null) return '';
    if (isOverdue && !isCompleted) return 'OVERDUE';
    if (isDueToday) return 'TODAY';
    if (isDueTomorrow) return 'TOMORROW';
    return '${dueDate!.day}/${dueDate!.month}';
  }
  
  Color get dueDateColor {
    if (dueDate == null) return Colors.grey;
    if (isOverdue && !isCompleted) return Colors.red;
    if (isDueToday) return Colors.orange;
    if (isDueTomorrow) return Colors.blue;
    return Colors.grey;
  }
  
  IconData get dueDateIcon {
    if (dueDate == null) return Icons.calendar_today_rounded;
    if (isOverdue && !isCompleted) return Icons.warning_rounded;
    if (isDueToday) return Icons.today_rounded;
    return Icons.calendar_today_rounded;
  }
}