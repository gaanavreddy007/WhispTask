// ignore_for_file: avoid_print, unused_field, prefer_final_fields, unused_element, unnecessary_brace_in_string_interps, prefer_const_constructors

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import '../services/notification_service.dart';
import '../utils/notification_helper.dart';
import '../providers/auth_provider.dart';
import '../services/voice_service.dart';
import '../services/voice_parser.dart';
import '../services/background_voice_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/tts_service.dart';
import '../services/voice_error_handler.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../services/user_preferences_service.dart';
import '../services/sentry_service.dart';
import '../services/performance_service.dart';

// Helper class for storing task matches with scores
class TaskMatch {
  final Task task;
  final double score;

  TaskMatch({required this.task, required this.score});
}

class TaskProvider extends ChangeNotifier {
  // Private fields
  final TaskService _taskService = TaskService();
  final PerformanceService _performanceService = PerformanceService();
  AuthProvider? _authProvider;
  String? _currentUserId;
  
  List<Task> _tasks = [];
  List<Task> _completedTasks = [];
  List<Task> _pendingTasks = [];
  List<Task> _overdueeTasks = [];
  List<Task> _todayTasks = [];
  
  bool _isLoading = false;
  String _errorMessage = '';
  // Simple Filters
  String _searchQuery = '';

  // Advanced Filters
  List<String> _selectedCategories = [];
  List<String> _selectedPriorities = [];
  List<String> _selectedStatuses = [];
  List<String> _selectedColors = [];
  DateTime? _dueDateStart;
  DateTime? _dueDateEnd;
  bool _showRemindersOnly = false;
  bool _showOverdueOnly = false;
  bool _showRecurringOnly = false;
  
  // Task statistics
  Map<String, int> _taskStats = {
    'total': 0,
    'completed': 0,
    'pending': 0,
    'overdue': 0,
  };
  
  // NEW: Analytics data
  Map<String, dynamic> _analyticsData = {};
  
  // Stream subscriptions
  StreamSubscription<List<Task>>? _tasksStreamSubscription;
  
  // NEW: Voice command fields
  VoiceService? _voiceService;
  TtsService? _ttsService;
  FlutterTts? _flutterTts;
  StreamSubscription<String>? _voiceCommandSubscription;
  bool _isProcessingVoiceCommand = false;
  String _lastVoiceCommand = '';
  List<VoiceError> _voiceErrors = [];
  
  // Getters
  List<Task> get tasks => filteredTasks;
  List<Task> get completedTasks => _completedTasks;
  List<Task> get pendingTasks => _pendingTasks;
  List<Task> get overdueTasks => _overdueeTasks;
  List<Task> get todayTasks => _todayTasks;
  List<Task> get incompleteTasks => _pendingTasks;
  List<Task> get tasksWithReminders => _tasks.where((task) => task.hasActiveReminder).toList();
  List<Task> get overdueReminders => _tasks.where((task) => 
    task.hasActiveReminder && 
    task.reminderTime != null && 
    task.reminderTime!.isBefore(DateTime.now()) && 
    !task.isCompleted
  ).toList();
  
  // NEW: Enhanced getters
  List<Task> get recurringTasks => _tasks.where((task) => task.isRecurring).toList();
  List<Task> get dueTodayTasks => _tasks.where((task) => task.isDueToday && !task.isCompleted).toList();
  List<Task> get dueTomorrowTasks => _tasks.where((task) => task.isDueTomorrow && !task.isCompleted).toList();
  List<Task> get highPriorityTasks => _tasks.where((task) => task.isHighPriority && !task.isCompleted).toList();
  List<Task> get urgentTasks => _tasks.where((task) => task.isUrgent && !task.isCompleted).toList();
  
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String? get error => _errorMessage.isEmpty ? null : _errorMessage;
  // Advanced Filter Getters
  List<String> get selectedCategories => _selectedCategories;
  List<String> get selectedPriorities => _selectedPriorities;
  List<String> get selectedStatuses => _selectedStatuses;
  List<String> get selectedColors => _selectedColors;
  DateTime? get dueDateStart => _dueDateStart;
  DateTime? get dueDateEnd => _dueDateEnd;
  bool get showRemindersOnly => _showRemindersOnly;
  bool get showOverdueOnly => _showOverdueOnly;
  bool get showRecurringOnly => _showRecurringOnly;
  String get searchQuery => _searchQuery;
  Map<String, int> get taskStats => _taskStats;
  Map<String, dynamic> get analyticsData => _analyticsData;
  bool get isProcessingVoiceCommand => _isProcessingVoiceCommand;

  // Disposal tracking to prevent rendering assertion errors
  bool _disposed = false;
  String get lastVoiceCommand => _lastVoiceCommand;
  bool get isVoiceCommandActive => _voiceService?.isWakeWordActive ?? false;
  
  bool get hasError => _errorMessage.isNotEmpty;
  bool get hasTasks => _tasks.isNotEmpty;
  bool get hasCompletedTasks => _completedTasks.isNotEmpty;
  bool get hasPendingTasks => _pendingTasks.isNotEmpty;
  bool get hasOverdueTasks => _overdueeTasks.isNotEmpty;
  bool get hasTodayTasks => _todayTasks.isNotEmpty;
  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategories.isNotEmpty ||
      _selectedPriorities.isNotEmpty ||
      _selectedStatuses.isNotEmpty ||
      _selectedColors.isNotEmpty ||
      _dueDateStart != null ||
      _dueDateEnd != null ||
      _showRemindersOnly ||
      _showOverdueOnly ||
      _showRecurringOnly;

  bool get hasDateFilter => _dueDateStart != null || _dueDateEnd != null;
  
  // Computed properties
  double get completionPercentage {
    if (_taskStats['total'] == 0) return 0.0;
    return (_taskStats['completed']! / _taskStats['total']!) * 100;
  }
  
  List<String> get availableCategories {
    final Set<String> categorySet = {};
    for (final task in _tasks) {
      if (task.category.isNotEmpty) {
        categorySet.add(task.category);
      }
    }
    return categorySet.toList()..sort();
  }

  List<String> get categories {
    final Set<String> categorySet = {'All'};
    for (final task in _tasks) {
      if (task.category.isNotEmpty) {
        categorySet.add(task.category);
      }
    }
    return categorySet.toList()..sort();
  }
  
  List<String> get priorities => ['All', 'High', 'Medium', 'Low'];
  
  // NEW: Enhanced category/tag management
  List<String> get statuses => ['All', 'pending', 'in_progress', 'completed', 'cancelled', 'overdue'];
  
  List<String> get allTags {
    final Set<String> tagSet = {};
    for (final task in _tasks) {
      tagSet.addAll(task.tags);
    }
    return tagSet.toList()..sort();
  }
  
  List<String> get colors => [
    'red', 'pink', 'purple', 'indigo', 'blue', 
    'cyan', 'teal', 'green', 'yellow', 'orange'
  ];

  List<Task> get filteredTasks {
    List<Task> filtered = List.from(_tasks);

    // Search Query Filter
    if (_searchQuery.isNotEmpty) {
      String lowerCaseQuery = _searchQuery.toLowerCase();
      filtered = filtered.where((task) {
        final titleMatch = task.title.toLowerCase().contains(lowerCaseQuery);
        final descriptionMatch = task.description?.toLowerCase().contains(lowerCaseQuery) ?? false;
        return titleMatch || descriptionMatch;
      }).toList();
    }

    // Category Filter
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((task) => _selectedCategories.contains(task.category)).toList();
    }

    // Priority Filter
    if (_selectedPriorities.isNotEmpty) {
      filtered = filtered.where((task) => _selectedPriorities.contains(task.priority)).toList();
    }

    // Status Filter
    if (_selectedStatuses.isNotEmpty) {
      filtered = filtered.where((task) {
        if (_selectedStatuses.contains('completed') && task.isCompleted) return true;
        if (_selectedStatuses.contains('pending') && !task.isCompleted) return true;
        return false;
      }).toList();
    }

    // Color Filter
    if (_selectedColors.isNotEmpty) {
      filtered = filtered.where((task) => _selectedColors.contains(task.displayColor)).toList();
    }

    // Date Range Filter
    if (_dueDateStart != null) {
      filtered = filtered.where((task) =>
          task.dueDate != null && !task.dueDate!.isBefore(_dueDateStart!)).toList();
    }
    if (_dueDateEnd != null) {
      final endOfDay = DateTime(_dueDateEnd!.year, _dueDateEnd!.month, _dueDateEnd!.day, 23, 59, 59);
      filtered = filtered.where((task) =>
          task.dueDate != null && !task.dueDate!.isAfter(endOfDay)).toList();
    }

    // Reminder Filter
    if (_showRemindersOnly) {
      filtered = filtered.where((task) => task.hasReminder).toList();
    }

    // Overdue Filter
    if (_showOverdueOnly) {
      filtered = filtered.where((task) => task.isOverdue).toList();
    }

    // Recurring Filter
    if (_showRecurringOnly) {
      filtered = filtered.where((task) => task.isRecurring).toList();
    }

    return filtered;
  }

  /// NEW: Get analytics data
  Future<void> loadAnalytics() async {
    if (_currentUserId == null) return;
    
    try {
      // _analyticsData = await _taskService.getTaskAnalytics(_currentUserId!, _tasks); // Method does not exist
      notifyListeners();
    } catch (e) {
      print('Error loading analytics: $e');
    }
  }

  /// NEW: Process recurring tasks
  Future<void> processRecurringTasks() async {
    if (_currentUserId == null) return;
    
    try {
      await _taskService.processRecurringTasks(_currentUserId!);
      // Refresh tasks to show newly created recurring tasks
      await refreshTasks();
    } catch (e) {
      print('Error processing recurring tasks: $e');
    }
  }

  /// Update auth provider and handle user changes
  void updateAuth(AuthProvider authProvider) {
    final String? newUserId = authProvider.currentUserId;
    
    // Check if user changed
    if (newUserId != _currentUserId) {
      _authProvider = authProvider;
      _currentUserId = newUserId;
      
      // Cancel existing subscription
      _tasksStreamSubscription?.cancel();
      _tasksStreamSubscription = null;
      
      // Clear existing data
      _clearData();
      
      // Load new user's data if logged in
      if (authProvider.isLoggedIn && newUserId != null) {
        _initializeUserData(newUserId);
      }
    } else {
      _authProvider = authProvider;
    }
  }

  /// Initialize data for a user
  void _initializeUserData(String userId) {
    _loadUserTasks();
    _setupTasksStream(userId);
    _loadTaskStats();
    loadAnalytics();
    // Process any pending recurring tasks
    processRecurringTasks();
  }

  /// Setup real-time task updates
  void _setupTasksStream(String userId) {
    _tasksStreamSubscription = _taskService.getUserTasksStream(userId).listen(
      (tasks) {
        _tasks = tasks;
        _updateTaskLists();
        // Auto-update analytics when tasks change
        loadAnalytics();
        // Trigger productivity score recalculation
        print('TaskProvider: Tasks updated from stream, recalculating productivity score...');
        _safeNotifyListeners();
      },
      onError: (error) {
        _setError('Failed to load tasks: $error');
      },
    );
  }

  /// Clear all data
  void _clearData() {
    _tasks.clear();
    _completedTasks.clear();
    _pendingTasks.clear();
    _overdueeTasks.clear();
    _todayTasks.clear();
    _taskStats = {
      'total': 0,
      'completed': 0,
      'pending': 0,
      'overdue': 0,
    };
    _analyticsData.clear();
    _searchQuery = '';
    _selectedCategories.clear();
    _selectedPriorities.clear();
    _selectedStatuses.clear();
    _selectedColors.clear();
    _dueDateStart = null;
    _dueDateEnd = null;
    _showRemindersOnly = false;
    _showOverdueOnly = false;
    _showRecurringOnly = false;
    _errorMessage = '';
    notifyListeners();
  }

  /// Load user tasks from Firestore
  Future<void> _loadUserTasks() async {
    if (_currentUserId == null) return;
    
    _setLoading(true);
    try {
      _tasks = await _taskService.getUserTasks(_currentUserId!);
      _updateTaskLists();
      _clearError();
    } catch (e) {
      _setError('Failed to load tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update categorized task lists
  void _updateTaskLists() {
    _completedTasks = _tasks.where((task) => task.isCompleted).toList();
    _pendingTasks = _tasks.where((task) => !task.isCompleted).toList();
    
    // Get overdue tasks
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    
    _overdueeTasks = _tasks.where((task) {
      return !task.isCompleted && 
             task.dueDate != null && 
             task.dueDate!.isBefore(today);
    }).toList();
    
    // Get today's tasks
    final DateTime endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _todayTasks = _tasks.where((task) {
      return !task.isCompleted && 
             task.dueDate != null && 
             task.dueDate!.isAfter(today) &&
             task.dueDate!.isBefore(endOfToday);
    }).toList();
  }

  /// Load task statistics
  Future<void> _loadTaskStats() async {
    if (_currentUserId == null) return;
    
    try {
      _taskStats = await _taskService.getUserTaskStats(_currentUserId!);
      notifyListeners();
    } catch (e) {
      print('Error loading task stats: $e');
    }
  }

  /// Check if user can add more tasks (premium feature)
  bool canAddTask() {
    if (_authProvider?.isPremium == true) return true;
    
    // Free users: 20 tasks per day limit
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final todayTasks = _tasks.where((task) => 
      task.createdAt.isAfter(startOfDay)).length;
    
    return todayTasks < 20;
  }

  /// Add a new task - ENHANCED with new model fields and premium limits
  Future<bool> addTask(Task task) async {
    final result = await SentryService.wrapWithErrorTracking(
      () async {
        if (_currentUserId == null) {
          SentryService.captureMessage(
            'Attempted to add task without authenticated user',
            level: 'warning',
          );
          _setError('User not authenticated');
          return false;
        }

        // Check premium limits
        if (!canAddTask()) {
          SentryService.logUserAction('task_limit_reached', data: {
            'is_premium': (_authProvider?.isPremium == true).toString(),
            'current_task_count': _tasks.length.toString(),
          });
          _setError('Daily task limit reached (20 tasks). Upgrade to Pro for unlimited tasks!');
          return false;
        }

        SentryService.logUserAction('add_task_attempt', data: {
          'task_title': task.title,
          'task_priority': task.priority.toString(),
          'has_due_date': (task.dueDate != null).toString(),
          'is_recurring': task.isRecurring.toString(),
          'recurring_pattern': task.recurringPattern ?? 'none',
          'recurring_interval': task.recurringInterval?.toString() ?? 'none',
          'has_reminder': task.hasReminder.toString(),
        });

        _setLoading(true);
        
        try {
          // Set the userId in the task
          final taskWithUserId = task.copyWith(userId: _currentUserId);
          final bool success = await _taskService.addTask(taskWithUserId, _currentUserId!);
          
          if (success) {
            SentryService.logUserAction('task_added_success', data: {
              'task_title': task.title,
              'task_id': taskWithUserId.id,
            });
            
            // Track analytics event
            FirebaseAnalytics.instance.logEvent(name: 'task_created');
            
            // Auto-save productivity score when tasks change (with error handling)
            try {
              final score = calculateDailyProductivityScore();
              await UserPreferencesService().saveDailyProductivityScore(score);
            } catch (e) {
              // Silently handle productivity score save errors to not disrupt task creation
              print('Note: Productivity score not saved (${e.toString().split(':').last.trim()})');
            }
            
            _safeNotifyListeners();
            
            // Schedule notification if reminder is set using NotificationHelper
            if (task.hasReminder && task.reminderTime != null && task.notificationId != null) {
              await NotificationService().scheduleNotification(
                id: task.notificationId!,
                title: NotificationHelper.getReminderTitle(task),
                body: NotificationHelper.getReminderBody(task),
                scheduledTime: task.reminderTime!,
                payload: task.id,
              );
            }
            
            await _loadTaskStats();
            await loadAnalytics();
            _clearError();
            return true;
          } else {
            _setError('Failed to add task');
            return false;
          }
        } finally {
          _setLoading(false);
        }
      },
      operation: 'add_task',
      description: 'Add new task to user collection',
      extra: {
        'task_title': task.title,
        'user_id': _currentUserId ?? 'unknown',
      },
    );
    
    return result ?? false;
  }

  /// Update an existing task - ENHANCED
  Future<bool> updateTask(Task task) async {
    if (_currentUserId == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    try {
      // Update the updatedAt timestamp
      final updatedTask = task.copyWith(updatedAt: DateTime.now());
      final bool success = await _taskService.updateTask(updatedTask, _currentUserId!);
      
      if (success) {
        // Update notification using NotificationHelper
        if (task.notificationId != null) {
          await NotificationService().cancelNotification(task.notificationId!);
        }
        
        if (task.hasReminder && task.reminderTime != null && !task.isCompleted && task.notificationId != null) {
          await NotificationService().scheduleNotification(
            id: task.notificationId!,
            title: NotificationHelper.getReminderTitle(task),
            body: NotificationHelper.getReminderBody(task),
            scheduledTime: task.reminderTime!,
            payload: task.id,
          );
        }
        
        await _loadTaskStats();
        await loadAnalytics();
        _clearError();
        _safeNotifyListeners(); // Ensure UI updates when task is updated
      } else {
        _setError('Failed to update task');
      }
      
      return success;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'task');
          scope.setTag('operation', 'update_task');
          scope.setExtra('task_id', task.id ?? 'unknown');
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to update task: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a task
  Future<bool> deleteTask(String taskId) async {
    if (_currentUserId == null) {
      _setError('User not authenticated');
      return false;
    }

    if (taskId.isEmpty) {
      _setError('Invalid task ID');
      return false;
    }

    _setLoading(true);
    try {
      final bool success = await _taskService.deleteTask(taskId, _currentUserId!);
      
      if (success) {
        // Cancel notification and remove task from local list
        final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
        if (taskIndex != -1) {
          final task = _tasks[taskIndex];
          if (task.notificationId != null) {
            await NotificationService().cancelNotification(task.notificationId!);
          }
          // Remove task from local list
          _tasks.removeAt(taskIndex);
        }
        _safeNotifyListeners();
        
        await _loadTaskStats();
        await loadAnalytics();
        _clearError();
      } else {
        _setError('Failed to delete task');
      }
      
      return success;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'task');
          scope.setTag('operation', 'delete_task');
          scope.setExtra('task_id', taskId);
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to delete task: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle task completion - ENHANCED with recurring task handling
  Future<bool> toggleTaskCompletion(String taskId) async {
    final result = await SentryService.wrapWithErrorTracking(
      () async {
        if (_currentUserId == null) {
          SentryService.captureMessage(
            'Attempted to toggle task completion without authenticated user',
            level: 'warning',
          );
          _setError('User not authenticated');
          return false;
        }

        SentryService.logTaskOperation('toggle_task_completion_start', taskId: taskId, data: {
          'user_id': _currentUserId!,
        });

        try {
          final bool success = await _taskService.toggleTaskCompletion(taskId, _currentUserId!);
          
          if (success) {
            // Reload tasks to reflect the change immediately
            await _loadUserTasks();
            
            // Get the updated task with safe error handling
            Task? updatedTask;
            try {
              updatedTask = _tasks.firstWhere((t) => t.id == taskId);
            } catch (e) {
              // If task not found in local list, try to get it from service
              SentryService.logTaskOperation('task_not_found_in_local_list', taskId: taskId, data: {
                'error': e.toString(),
                'local_task_count': _tasks.length.toString(),
              });
              
              updatedTask = await _taskService.getUserTask(taskId, _currentUserId!);
            }
            
            // Cancel notification if task is now completed
            if (updatedTask != null && updatedTask.isCompleted && updatedTask.notificationId != null) {
              try {
                await NotificationService().cancelNotification(updatedTask.notificationId!);
                SentryService.logTaskOperation('notification_cancelled_success', taskId: taskId);
              } catch (notificationError) {
                // Log but don't fail the operation for notification errors
                SentryService.logTaskOperation('notification_cancel_failed', taskId: taskId, data: {
                  'error': notificationError.toString(),
                });
              }
            }
            
            await _loadTaskStats();
            await loadAnalytics();
            _clearError();
            
            SentryService.logTaskOperation('toggle_task_completion_success', taskId: taskId, data: {
              'task_completed': updatedTask?.isCompleted.toString() ?? 'unknown',
            });
            
            // Force UI update
            _safeNotifyListeners();
          } else {
            SentryService.logTaskOperation('toggle_task_completion_service_failed', taskId: taskId);
            _setError('Failed to toggle task completion');
          }
          
          return success;
        } catch (e) {
          SentryService.logTaskOperation('toggle_task_completion_error', taskId: taskId, data: {
            'error': e.toString(),
            'error_type': e.runtimeType.toString(),
          });
          _setError('Failed to toggle task completion: $e');
          return false;
        }
      },
      operation: 'toggle_task_completion',
      description: 'Toggle task completion status with safe error handling',
      extra: {
        'task_id': taskId,
        'user_id': _currentUserId ?? 'unknown',
      },
    );
    
    return result ?? false;
  }

  void setRecurringFilter(bool showRecurringOnly) {
    _showRecurringOnly = showRecurringOnly;
    notifyListeners();
  }

  void toggleCategoryFilter(String category) {
    _selectedCategories.contains(category)
        ? _selectedCategories.remove(category)
        : _selectedCategories.add(category);
    _debouncedNotifyListeners();
  }

  void togglePriorityFilter(String priority) {
    _selectedPriorities.contains(priority)
        ? _selectedPriorities.remove(priority)
        : _selectedPriorities.add(priority);
    _debouncedNotifyListeners();
  }

  void toggleStatusFilter(String status) {
    _selectedStatuses.contains(status)
        ? _selectedStatuses.remove(status)
        : _selectedStatuses.add(status);
    _debouncedNotifyListeners();
  }

  void toggleColorFilter(String color) {
    _selectedColors.contains(color)
        ? _selectedColors.remove(color)
        : _selectedColors.add(color);
    _debouncedNotifyListeners();
  }

  String getDateFilterLabel() {
    if (_dueDateStart != null && _dueDateEnd != null) {
      if (_dueDateStart == _dueDateEnd) {
        return 'On: ${_dueDateStart!.toLocal().toString().split(' ')[0]}';
      }
      return 'From: ${_dueDateStart!.toLocal().toString().split(' ')[0]} To: ${_dueDateEnd!.toLocal().toString().split(' ')[0]}';
    }
    if (_dueDateStart != null) {
      return 'After: ${_dueDateStart!.toLocal().toString().split(' ')[0]}';
    }
    if (_dueDateEnd != null) {
      return 'Before: ${_dueDateEnd!.toLocal().toString().split(' ')[0]}';
    }
    return 'Not set';
  }

  void clearDateFilter() {
    _dueDateStart = null;
    _dueDateEnd = null;
    notifyListeners();
  }

  void setOverdueFilter(bool value) {
    _showOverdueOnly = value;
    notifyListeners();
  }

  void setRemindersFilter(bool value) {
    _showRemindersOnly = value;
    notifyListeners();
  }

  void setFilters({
    List<String>? categories,
    List<String>? priorities,
    List<String>? statuses,
    List<String>? colors,
    DateTime? startDate,
    DateTime? endDate,
    bool? showReminders,
    bool? showOverdue,
    bool? showRecurring,
  }) {
    _selectedCategories = categories ?? _selectedCategories;
    _selectedPriorities = priorities ?? _selectedPriorities;
    _selectedStatuses = statuses ?? _selectedStatuses;
    _selectedColors = colors ?? _selectedColors;
    _dueDateStart = startDate;
    _dueDateEnd = endDate;
    _showRemindersOnly = showReminders ?? _showRemindersOnly;
    _showOverdueOnly = showOverdue ?? _showOverdueOnly;
    _showRecurringOnly = showRecurring ?? _showRecurringOnly;
    notifyListeners();
  }

  /// Search tasks with debouncing for better performance
  Future<void> searchTasks(String query) async {
    _searchQuery = query;
    _debouncedNotifyListeners(delay: const Duration(milliseconds: 100)); // Faster response for search
  }


  /// Clear all filters - ENHANCED
  void clearAllFilters() {
    _selectedCategories.clear();
    _selectedPriorities.clear();
    _selectedStatuses.clear();
    _selectedColors.clear();
    _dueDateStart = null;
    _dueDateEnd = null;
    _showRemindersOnly = false;
    _showOverdueOnly = false;
    _showRecurringOnly = false;
    _searchQuery = '';
    notifyListeners();
  }

  /// Refresh tasks
  Future<void> refreshTasks() async {
    await _loadUserTasks();
    await _loadTaskStats();
    await loadAnalytics();
  }

  /// Get task by ID
  Task? getTaskById(String taskId) {
    try {
      return _tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }

  /// Get tasks by category
  List<Task> getTasksByCategory(String category) {
    if (category == 'All') return _tasks;
    return _tasks.where((task) => task.category == category).toList();
  }

  /// Get tasks by priority
  List<Task> getTasksByPriority(String priority) {
    if (priority == 'All') return _tasks;
    return _tasks.where((task) => task.priority == priority).toList();
  }

  /// NEW: Get tasks by color
  List<Task> getTasksByColor(String color) {
    return _tasks.where((task) => task.displayColor == color).toList();
  }

  /// NEW: Get tasks by tags
  List<Task> getTasksByTags(List<String> tags) {
    return _tasks.where((task) => 
      tags.any((tag) => task.tags.contains(tag))
    ).toList();
  }

  /// Batch update tasks
  Future<bool> batchUpdateTasks(List<Task> tasks) async {
    if (_currentUserId == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    try {
      final bool success = await _taskService.batchUpdateTasks(tasks, _currentUserId!);
      
      if (success) {
        await _loadTaskStats();
        await loadAnalytics();
        _clearError();
      } else {
        _setError('Failed to update tasks');
      }
      
      return success;
    } catch (e) {
      _setError('Failed to update tasks: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }


  /// Delete all user tasks (for account deletion)
  Future<bool> deleteAllUserTasks() async {
    if (_currentUserId == null) return false;
    
    try {
      final bool success = await _taskService.deleteAllUserTasks(_currentUserId!);
      
      if (success) {
        _clearData();
      }
      
      return success;
    } catch (e) {
      _setError('Failed to delete all tasks: $e');
      return false;
    }
  }

  /// Toggle task completion
  Future<bool> toggleTask(String taskId, bool isCompleted) async {
    return await toggleTaskCompletion(taskId);
  }

  /// Additional getters for UI state
  bool get isCreating => _isLoading;
  bool get isUpdating => _isLoading;
  bool get isDeleting => _isLoading;

  /// Clear error
  void clearError() {
    _clearError();
  }

  /// Snooze reminder - ENHANCED with NotificationHelper
  Future<bool> snoozeReminder(String taskId, int minutes) async {
    try {
      final task = getTaskById(taskId);
      if (task == null) return false;

      final newReminderTime = DateTime.now().add(Duration(minutes: minutes));
      final updatedTask = task.copyWith(reminderTime: newReminderTime);
      
      return await updateTask(updatedTask);
    } catch (e) {
      _setError('Failed to snooze reminder: $e');
      return false;
    }
  }

  /// Cancel reminder
  Future<bool> cancelReminder(String taskId) async {
    try {
      final task = getTaskById(taskId);
      if (task == null) return false;

      final updatedTask = task.copyWith(
        hasReminder: false,
        isReminderActive: false,
        reminderTime: null,
      );
      
      return await updateTask(updatedTask);
    } catch (e) {
      _setError('Failed to cancel reminder: $e');
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    _safeNotifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _safeNotifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
    _safeNotifyListeners();
  }

  // Safe notification method to prevent rendering assertion errors
  void _safeNotifyListeners() {
    try {
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      // Silently catch any rendering assertion errors
      print('Error in notifyListeners: $e');
    }
  }

  /// Debounced notify listeners to improve performance
  void _debouncedNotifyListeners({Duration delay = const Duration(milliseconds: 50)}) {
    _performanceService.debounce('task_provider_notify', () {
      _safeNotifyListeners();
    }, delay: delay);
  }

  // NEW: Voice Command Methods
  
  // Enhanced voice command initialization
  Future<void> initializeVoiceCommands() async {
    try {
      print('Initializing voice commands...');
      
      // Initialize TTS service first
      _ttsService = TtsService();
      final ttsInitialized = await _ttsService!.initialize();
      print('TTS initialized: $ttsInitialized');
      if (!ttsInitialized) {
        _handleVoiceError(VoiceError.ttsNotAvailable());
        return;
      }
      
      _voiceService = VoiceService();
      await _voiceService!.initialize(_authProvider!);
      
      // Set up direct callback as backup
      _voiceService!.setDirectCommandCallback((command) {
        print('TaskProvider: ✅ Direct callback received command: "$command"');
        processVoiceTaskCommandEnhanced(command);
      });
      
      // Add a small delay to ensure stream controllers are ready
      await Future.delayed(Duration(milliseconds: 100));
      
      // Set up voice command stream listener
      print('TaskProvider: Setting up voice command stream listener...');
      print('TaskProvider: Voice command stream available: ${_voiceService!.voiceCommandStream != null}');
      _voiceCommandSubscription = _voiceService!.voiceCommandStream?.listen(
        (command) {
          print('TaskProvider: ✅ Voice command received from stream: "$command"');
          print('TaskProvider: About to process command...');
          processVoiceTaskCommandEnhanced(command);
        },
        onError: (error) {
          print('TaskProvider: ❌ Voice command stream error: $error');
          _handleVoiceError(VoiceError.speechRecognitionError(error.toString()));
        },
      );

      // Set up live speech results stream for transcript display
      _voiceService!.speechResultsStream?.listen(
        (liveText) {
          print('TaskProvider: Live speech result: "$liveText"');
          // Update VoiceProvider with live transcript
          _updateLiveTranscript(liveText);
        },
        onError: (error) {
          print('TaskProvider: Speech results stream error: $error');
        },
      );
      
      if (_voiceCommandSubscription != null) {
        print('TaskProvider: ✅ Voice command stream subscription created successfully');
      } else {
        print('TaskProvider: ❌ Failed to create voice command stream subscription');
      }
      
      // Process any stored background commands
      await _processStoredBackgroundCommands();
      
      // Provide initialization feedback
      await _ttsService!.speakListeningStarted();
      debugPrint('Enhanced voice commands initialized successfully');
      
    } catch (e) {
      _handleVoiceError(VoiceError.commandProcessingFailed('initialization', e.toString()));
    }
  }

  // Process stored background commands when app reopens
  Future<void> _processStoredBackgroundCommands() async {
    try {
      // Import the background voice service
      final storedCommands = await BackgroundVoiceService.getStoredCommands();
      
      if (storedCommands.isNotEmpty) {
        print('TaskProvider: Processing ${storedCommands.length} stored background commands');
        
        for (final commandData in storedCommands) {
          final command = commandData['command'] as String?;
          if (command != null && command.isNotEmpty) {
            print('TaskProvider: Processing stored command: $command');
            await processVoiceTaskCommandEnhanced(command);
            await Future.delayed(const Duration(milliseconds: 500)); // Small delay between commands
          }
        }
        
        await _ttsService?.speak('Processed ${storedCommands.length} voice commands from background');
      }
    } catch (e) {
      print('TaskProvider: Error processing stored background commands: $e');
    }
  }

  // Handle voice errors with appropriate feedback
  Future<void> _handleVoiceError(VoiceError error) async {
    _voiceErrors.add(error);
    VoiceErrorHandler.logError(error);
    
    // Provide user-friendly feedback
    await _speakFeedback(error.getUserFriendlyMessage());
    
    debugPrint('Voice Error: ${error.toString()}');
    notifyListeners();
  }

  // Configure Text-to-Speech
  Future<void> _configureTTS() async {
    if (_flutterTts == null) return;
    
    await _flutterTts!.setLanguage("en-US");
    await _flutterTts!.setSpeechRate(0.8);
    await _flutterTts!.setVolume(0.8);
    await _flutterTts!.setPitch(1.0);
  }

  // Start wake word listening
  Future<void> startWakeWordListening() async {
    print('Starting wake word listening...');
    if (_voiceService == null) {
      print('Voice service null, initializing...');
      await initializeVoiceCommands();
    }
    
    if (_voiceService != null) {
      await _voiceService!.startWakeWordListening();
      print('Wake word listening started successfully');
    } else {
      print('Failed to start wake word listening - voice service still null');
    }
    notifyListeners();
  }

  // Stop wake word listening
  Future<void> stopWakeWordListening() async {
    _voiceService?.stopWakeWordListening();
    notifyListeners();
  }




  // Enhanced Voice Command Processing with automatic CRUD operations
  Future<void> processVoiceTaskCommandEnhanced(String command) async {
    print('TaskProvider: ✅ PROCESSING VOICE COMMAND: "$command"');

    if (_isProcessingVoiceCommand) {
      print('TaskProvider: Already processing a command, skipping.');
      return;
    }

    _isProcessingVoiceCommand = true;

    try {
      // Clean the command first - remove duplicates and artifacts
      String cleanedCommand = _cleanVoiceCommand(command);
      print('TaskProvider: Cleaned command: "$cleanedCommand"');
      
      final lowerCommand = cleanedCommand.toLowerCase().trim();
      
      
      // Process different command types with AUTOMATIC execution (no confirmation)
      if (_isMarkDoneCommand(lowerCommand)) {
        print('TaskProvider: ✅ AUTO-EXECUTING MARK DONE COMMAND');
        await _handleMarkDoneCommandAutomatic(cleanedCommand);
      }
      else if (_isDeleteCommand(lowerCommand)) {
        print('TaskProvider: ✅ AUTO-EXECUTING DELETE COMMAND');
        await _handleDeleteCommandAutomatic(cleanedCommand);
      }
      else if (_isUpdateCommand(lowerCommand)) {
        print('TaskProvider: ✅ AUTO-EXECUTING UPDATE COMMAND');
        await _handleUpdateCommandAutomatic(cleanedCommand);
      }
      // Fallback: automatically create task
      else {
        print('TaskProvider: ✅ AUTO-CREATING TASK FROM VOICE');
        await _handleVoiceTaskCreationAutomatic(cleanedCommand.isNotEmpty ? cleanedCommand : command);
      }
      
    } catch (e) {
      print('TaskProvider: ❌ ERROR PROCESSING VOICE COMMAND: $e');
      print('TaskProvider: Stack trace: ${StackTrace.current}');
      await _ttsService?.speak('Sorry, I had trouble processing that command.');
    } finally {
      _isProcessingVoiceCommand = false;
      print('TaskProvider: 🏁 COMMAND PROCESSING COMPLETE');
      notifyListeners();
    }
  }

  // Check if command is for marking tasks as done
  bool _isMarkDoneCommand(String command) {
    final markDonePatterns = [
      'mark', 'complete', 'finish', 'done', 'finished', 'completed'
    ];
    
    // Also check for specific phrases
    final markDonePhrases = [
      'mark as done', 'mark as complete', 'mark complete', 'mark done',
      'complete task', 'finish task', 'task done', 'task complete'
    ];
    
    // Check patterns
    bool hasPattern = markDonePatterns.any((pattern) => command.contains(pattern));
    // Check phrases
    bool hasPhrase = markDonePhrases.any((phrase) => command.contains(phrase));
    
    print('TaskProvider: Mark done check - patterns: $hasPattern, phrases: $hasPhrase');
    return hasPattern || hasPhrase;
  }

  // Check if this is an update command
  bool _isUpdateCommand(String command) {
    final updatePatterns = [
      'update', 'change', 'modify', 'edit', 'rename', 'reschedule', 'move', 'remind'
    ];
    
    // Also check for time-based update phrases
    final updatePhrases = [
      'remind tomorrow', 'remind today', 'update tomorrow', 'change to tomorrow',
      'move to tomorrow', 'reschedule to', 'set reminder', 'remind me'
    ];
    
    bool hasPattern = updatePatterns.any((pattern) => command.contains(pattern));
    bool hasPhrase = updatePhrases.any((phrase) => command.contains(phrase));
    
    print('TaskProvider: Update check - patterns: $hasPattern, phrases: $hasPhrase');
    return hasPattern || hasPhrase;
  }

  // Check if this is a delete command
  bool _isDeleteCommand(String command) {
    final deletePatterns = [
      'delete', 'remove', 'cancel', 'drop', 'erase'
    ];
    
    final deletePhrases = [
      'delete task', 'remove task', 'cancel task', 'drop task'
    ];
    
    bool hasPattern = deletePatterns.any((pattern) => command.contains(pattern));
    bool hasPhrase = deletePhrases.any((phrase) => command.contains(phrase));
    
    print('TaskProvider: Delete check - patterns: $hasPattern, phrases: $hasPhrase');
    return hasPattern || hasPhrase;
  }

  // Check if we should create a new task
  bool _shouldCreateTask(String command) {
    // Don't create if it's clearly an update/delete/complete command
    if (_isMarkDoneCommand(command) || _isUpdateCommand(command) || _isDeleteCommand(command)) {
      print('TaskProvider: Not creating task - detected as CRUD operation');
      return false;
    }
    
    // Create if it has creation keywords or meaningful content
    final creationKeywords = ['add', 'create', 'new', 'buy', 'call', 'email', 'get', 'do', 'go', 'visit', 'make', 'schedule'];
    bool hasCreationKeyword = creationKeywords.any((keyword) => command.contains(keyword));
    bool hasContent = command.split(' ').length >= 2;
    
    print('TaskProvider: Create task check - keywords: $hasCreationKeyword, content: $hasContent');
    return hasCreationKeyword || hasContent;
  }

  // Handle mark as done commands with fuzzy matching
  Future<void> _handleMarkDoneCommand(String command) async {
    print('TaskProvider: Handling mark done command: "$command"');
    
    // Extract task identifier using existing logic
    String taskIdentifier = VoiceParser.extractTaskIdentifierFromCommand(command);
    
    if (taskIdentifier.isEmpty || taskIdentifier.length < 2) {
      await _ttsService?.speak('I couldn\'t identify which task to mark as done. Please be more specific.');
      return;
    }
    
    // Find matching tasks with scores
    final matchingTasks = _findMatchingTasksWithScores(taskIdentifier, threshold: 0.3);
    
    if (matchingTasks.isEmpty) {
      await _ttsService?.speak('I couldn\'t find a task matching "$taskIdentifier".');
      return;
    }
    
    // Take the best match
    final bestMatch = matchingTasks.first;
    final task = bestMatch.task;
    
    print('TaskProvider: Found matching task: "${task.title}" (score: ${bestMatch.score})');
    
    if (task.isCompleted) {
      await _ttsService?.speak('Task "${task.title}" is already completed.');
      return;
    }
    
    // Mark as completed
    final success = await markTaskCompleteByVoice(task.id);
    
    if (success) {
      await _ttsService?.speak('Marked "${task.title}" as complete.');
      print('TaskProvider: Successfully completed task: "${task.title}"');
    } else {
      await _ttsService?.speak('Sorry, I couldn\'t mark that task as complete.');
      print('TaskProvider: Failed to complete task: "${task.title}"');
    }
  }

  // Handle update commands
  Future<void> _handleUpdateCommand(String command) async {
    print('TaskProvider: Handling update command: "$command"');
    
    // Extract task identifier and new information
    String taskIdentifier = _extractTaskIdentifierForUpdate(command);
    String newInfo = _extractUpdateInfo(command);
    
    if (taskIdentifier.isEmpty) {
      await _ttsService?.speak('I couldn\'t identify which task to update. Please specify the task name.');
      return;
    }
    
    // Find matching tasks
    final matchingTasks = _findMatchingTasksWithScores(taskIdentifier, threshold: 0.3);
    
    if (matchingTasks.isEmpty) {
      await _ttsService?.speak('I couldn\'t find a task matching "$taskIdentifier".');
      return;
    }
    
    final bestMatch = matchingTasks.first;
    final task = bestMatch.task;
    
    // Update the task based on the command
    Task updatedTask = task;
    
    if (command.contains('rename') || command.contains('change title')) {
      updatedTask = task.copyWith(title: newInfo.isNotEmpty ? newInfo : task.title);
      await _ttsService?.speak('Renamed task to "$newInfo".');
    } else if (command.contains('reschedule') || command.contains('move')) {
      // Simple date parsing for common terms
      DateTime? newDate;
      if (newInfo.contains('tomorrow')) {
        newDate = DateTime.now().add(const Duration(days: 1));
      } else if (newInfo.contains('today')) {
        newDate = DateTime.now();
      } else if (newInfo.contains('tonight')) {
        newDate = DateTime.now();
      }
      
      if (newDate != null) {
        updatedTask = task.copyWith(dueDate: newDate);
        await _ttsService?.speak('Rescheduled task to ${newDate.day}/${newDate.month}.');
      }
    } else {
      // General update
      updatedTask = task.copyWith(title: newInfo.isNotEmpty ? newInfo : task.title);
      await _ttsService?.speak('Updated task "${task.title}".');
    }
    
    final success = await updateTask(updatedTask);
    
    if (!success) {
      await _ttsService?.speak('Sorry, I couldn\'t update that task.');
    }
  }

  // Handle delete commands
  Future<void> _handleDeleteCommand(String command) async {
    print('TaskProvider: Handling delete command: "$command"');
    
    // Extract task identifier
    String taskIdentifier = VoiceParser.extractTaskIdentifierFromCommand(command);
    
    if (taskIdentifier.isEmpty || taskIdentifier.length < 2) {
      await _ttsService?.speak('I couldn\'t identify which task to delete. Please be more specific.');
      return;
    }
    
    // Find matching tasks
    final matchingTasks = _findMatchingTasksWithScores(taskIdentifier, threshold: 0.3);
    
    if (matchingTasks.isEmpty) {
      await _ttsService?.speak('I couldn\'t find a task matching "$taskIdentifier".');
      return;
    }
    
    final bestMatch = matchingTasks.first;
    final task = bestMatch.task;
    
    print('TaskProvider: Found matching task to delete: "${task.title}" (score: ${bestMatch.score})');
    
    // Delete the task
    final success = await deleteTask(task.id ?? '');
    
    if (success) {
      await _ttsService?.speak('Deleted task "${task.title}".');
      print('TaskProvider: Successfully deleted task: "${task.title}"');
    } else {
      await _ttsService?.speak('Sorry, I couldn\'t delete that task.');
      print('TaskProvider: Failed to delete task: "${task.title}"');
    }
  }

  // Extract task identifier for update commands
  String _extractTaskIdentifierForUpdate(String command) {
    // Remove update keywords to get the task identifier
    String cleaned = command
        .replaceAll(RegExp(r'\b(update|change|modify|edit|rename|reschedule|move)\b'), '')
        .trim();
    
    // Split by common separators and take the first meaningful part
    final parts = cleaned.split(RegExp(r'\b(to|with|for)\b'));
    return parts.isNotEmpty ? parts[0].trim() : '';
  }

  // Extract new information from update commands
  String _extractUpdateInfo(String command) {
    // Look for patterns like "to [new info]" or "with [new info]"
    final match = RegExp(r'\b(to|with|for)\s+(.+)').firstMatch(command);
    return match?.group(2)?.trim() ?? '';
  }

  // Handle voice task creation
  Future<void> _handleVoiceTaskCreation(String command) async {
    print('TaskProvider: 🎯 CREATING TASK FROM SPEECH: "$command"');
    
    // Use enhanced parser to create task
    final task = VoiceParser.createTaskFromSpeech(command);
    print('TaskProvider: 📝 PARSED TASK: "${task.title}" | Category: ${task.category} | Priority: ${task.priority}');
    
    // Validate task
    if (task.title.isEmpty || task.title.length < 2) {
      print('TaskProvider: ❌ INVALID TASK TITLE: "${task.title}"');
      await _ttsService?.speak('I couldn\'t understand the task. Please try again.');
      return;
    }
    
    // Check for duplicates with high confidence
    final existingMatches = _findMatchingTasksWithScores(task.title, threshold: 0.8);
    if (existingMatches.isNotEmpty) {
      final similarTask = existingMatches.first.task;
      print('TaskProvider: ⚠️ DUPLICATE DETECTED: "${similarTask.title}"');
      await _ttsService?.speak('You already have a similar task: "${similarTask.title}". Should I create it anyway?');
      return;
    }
    
    print('TaskProvider: 💾 ATTEMPTING TO ADD TASK...');
    final success = await addTask(task);
    
    if (success) {
      String response = 'Created task "${task.title}"';
      if (task.dueDate != null) {
        if (task.dueDate!.day == DateTime.now().add(Duration(days: 1)).day) {
          response += ' for tomorrow';
        } else if (task.dueDate!.day == DateTime.now().day) {
          response += ' for today';
        }
      }
      await _ttsService?.speak(response);
      print('TaskProvider: ✅ SUCCESSFULLY CREATED TASK: "${task.title}"');
      print('TaskProvider: 📊 TOTAL TASKS NOW: ${_tasks.length}');
    } else {
      await _ttsService?.speak('Sorry, I couldn\'t create that task.');
      print('TaskProvider: ❌ FAILED TO CREATE TASK FROM: "$command"');
    }
  }

  // Automatic CRUD handlers that execute without user confirmation
  
  // Handle mark as done commands automatically
  Future<void> _handleMarkDoneCommandAutomatic(String command) async {
    print('TaskProvider: Auto-handling mark done command: "$command"');
    
    // Extract task identifier using existing logic
    String taskIdentifier = VoiceParser.extractTaskIdentifierFromCommand(command);
    
    if (taskIdentifier.isEmpty || taskIdentifier.length < 2) {
      await _ttsService?.speak('I couldn\'t identify which task to mark as done.');
      return;
    }
    
    // Find matching tasks with scores
    final matchingTasks = _findMatchingTasksWithScores(taskIdentifier, threshold: 0.3);
    
    if (matchingTasks.isEmpty) {
      await _ttsService?.speak('I couldn\'t find a task matching "$taskIdentifier".');
      return;
    }
    
    // Take the best match and execute automatically
    final bestMatch = matchingTasks.first;
    final task = bestMatch.task;
    
    print('TaskProvider: Auto-completing task: "${task.title}" (score: ${bestMatch.score})');
    
    if (task.isCompleted) {
      await _ttsService?.speak('Task "${task.title}" is already completed.');
      return;
    }
    
    // Mark as completed automatically
    final success = await markTaskCompleteByVoice(task.id);
    
    if (success) {
      await _ttsService?.speak('Automatically marked "${task.title}" as complete.');
      print('TaskProvider: Auto-completed task: "${task.title}"');
    } else {
      await _ttsService?.speak('Sorry, I couldn\'t mark that task as complete.');
      print('TaskProvider: Failed to auto-complete task: "${task.title}"');
    }
  }

  // Handle delete commands automatically
  Future<void> _handleDeleteCommandAutomatic(String command) async {
    print('TaskProvider: Auto-handling delete command: "$command"');
    
    // Extract task identifier
    String taskIdentifier = VoiceParser.extractTaskIdentifierFromCommand(command);
    
    if (taskIdentifier.isEmpty || taskIdentifier.length < 2) {
      await _ttsService?.speak('I couldn\'t identify which task to delete.');
      return;
    }
    
    // Find matching tasks
    final matchingTasks = _findMatchingTasksWithScores(taskIdentifier, threshold: 0.3);
    
    if (matchingTasks.isEmpty) {
      await _ttsService?.speak('I couldn\'t find a task matching "$taskIdentifier".');
      return;
    }
    
    final bestMatch = matchingTasks.first;
    final task = bestMatch.task;
    
    print('TaskProvider: Auto-deleting task: "${task.title}" (score: ${bestMatch.score})');
    
    // Delete the task automatically
    final success = await deleteTask(task.id ?? '');
    
    if (success) {
      await _ttsService?.speak('Automatically deleted task "${task.title}".');
      print('TaskProvider: Auto-deleted task: "${task.title}"');
    } else {
      await _ttsService?.speak('Sorry, I couldn\'t delete that task.');
      print('TaskProvider: Failed to auto-delete task: "${task.title}"');
    }
  }

  // Handle update commands automatically
  Future<void> _handleUpdateCommandAutomatic(String command) async {
    print('TaskProvider: Auto-handling update command: "$command"');
    
    // Extract task identifier and new information
    String taskIdentifier = _extractTaskIdentifierForUpdate(command);
    String newInfo = _extractUpdateInfo(command);
    
    if (taskIdentifier.isEmpty) {
      await _ttsService?.speak('I couldn\'t identify which task to update.');
      return;
    }
    
    // Find matching tasks
    final matchingTasks = _findMatchingTasksWithScores(taskIdentifier, threshold: 0.3);
    
    if (matchingTasks.isEmpty) {
      await _ttsService?.speak('I couldn\'t find a task matching "$taskIdentifier".');
      return;
    }
    
    final bestMatch = matchingTasks.first;
    final task = bestMatch.task;
    
    // Update the task based on the command automatically
    Task updatedTask = task;
    String updateType = 'updated';
    
    if (command.contains('rename') || command.contains('change title')) {
      updatedTask = task.copyWith(title: newInfo.isNotEmpty ? newInfo : task.title);
      updateType = 'renamed';
      await _ttsService?.speak('Automatically renamed task to "$newInfo".');
    } else if (command.contains('reschedule') || command.contains('move')) {
      // Simple date parsing for common terms
      DateTime? newDate;
      if (newInfo.contains('tomorrow')) {
        newDate = DateTime.now().add(const Duration(days: 1));
      } else if (newInfo.contains('today')) {
        newDate = DateTime.now();
      } else if (newInfo.contains('tonight')) {
        newDate = DateTime.now();
      }
      
      if (newDate != null) {
        updatedTask = task.copyWith(dueDate: newDate);
        updateType = 'rescheduled';
        await _ttsService?.speak('Automatically rescheduled task to ${newDate.day}/${newDate.month}.');
      }
    } else {
      // General update
      updatedTask = task.copyWith(title: newInfo.isNotEmpty ? newInfo : task.title);
      await _ttsService?.speak('Automatically updated task "${task.title}".');
    }
    
    final success = await updateTask(updatedTask);
    
    if (success) {
      print('TaskProvider: Auto-$updateType task: "${task.title}"');
    } else {
      await _ttsService?.speak('Sorry, I couldn\'t update that task.');
      print('TaskProvider: Failed to auto-update task: "${task.title}"');
    }
  }

  // Handle voice task creation automatically
  Future<void> _handleVoiceTaskCreationAutomatic(String command) async {
    print('TaskProvider: 🎯 AUTO-CREATING TASK FROM SPEECH: "$command"');
    
    // Use enhanced parser to create task
    final task = VoiceParser.createTaskFromSpeech(command);
    print('TaskProvider: 📝 AUTO-PARSED TASK: "${task.title}" | Category: ${task.category} | Priority: ${task.priority}');
    
    // Validate task
    if (task.title.isEmpty || task.title.length < 2) {
      print('TaskProvider: ❌ INVALID TASK TITLE: "${task.title}"');
      await _ttsService?.speak('I couldn\'t understand the task. Please try again.');
      return;
    }
    
    // Check for duplicates with high confidence - but create anyway if voice command
    final existingMatches = _findMatchingTasksWithScores(task.title, threshold: 0.9);
    if (existingMatches.isNotEmpty) {
      final similarTask = existingMatches.first.task;
      print('TaskProvider: ⚠️ SIMILAR TASK EXISTS: "${similarTask.title}" - creating anyway');
    }
    
    print('TaskProvider: 💾 AUTO-ADDING TASK...');
    final success = await addTask(task);
    
    if (success) {
      String response = 'Automatically created task "${task.title}"';
      if (task.dueDate != null) {
        if (task.dueDate!.day == DateTime.now().add(Duration(days: 1)).day) {
          response += ' for tomorrow';
        } else if (task.dueDate!.day == DateTime.now().day) {
          response += ' for today';
        }
      }
      await _ttsService?.speak(response);
      print('TaskProvider: ✅ AUTO-CREATED TASK: "${task.title}"');
      print('TaskProvider: 📊 TOTAL TASKS NOW: ${_tasks.length}');
    } else {
      await _ttsService?.speak('Sorry, I couldn\'t create that task.');
      print('TaskProvider: ❌ FAILED TO AUTO-CREATE TASK FROM: "$command"');
    }
  }
  
  // Handle task update commands with enhanced matching
  Future<void> _handleTaskUpdate(Map<String, dynamic> parsedCommand) async {
    final action = parsedCommand['action'] as String;
    final taskIdentifier = parsedCommand['taskIdentifier'] as String;
    
    // Find matching tasks using enhanced fuzzy matching with scores
    final matchingTasks = _findMatchingTasksWithScores(taskIdentifier);
    
    if (matchingTasks.isEmpty) {
      print('TaskProvider: No matching tasks found for "$taskIdentifier"');
      await _ttsService?.speak('I couldn\'t find a task matching "$taskIdentifier"');
      return;
    }
    
    final bestMatch = matchingTasks.first;
    print('TaskProvider: Found matching task: "${bestMatch.task.title}" (score: ${bestMatch.score})');
    
    // Handle different update actions
    if (action == 'setDueDate') {
      final dueDate = parsedCommand['dueDate'] as String?;
      await _updateTaskDueDate(bestMatch.task, dueDate);
    } else {
      // Execute action directly on the matched task
      await _executeActionOnTaskByAction(bestMatch.task, action);
    }
  }
  
  // Handle task creation with duplicate prevention
  Future<void> _handleTaskCreation(Map<String, dynamic> parsedCommand) async {
    final title = parsedCommand['title'] as String;
    
    // Check for existing tasks with similar titles to prevent duplicates
    final existingMatches = _findMatchingTasksWithScores(title);
    if (existingMatches.isNotEmpty && existingMatches.first.score > 0.8) {
      print('TaskProvider: Found very similar existing task: "${existingMatches.first.task.title}"');
      await _ttsService?.speak('You already have a similar task: "${existingMatches.first.task.title}". Did you want to update it instead?');
      return;
    }
    
    // Create new task
    final voiceTask = VoiceParser.parseVoiceToTask(parsedCommand['originalCommand'] as String);
    final success = await addTask(voiceTask);
    
    if (success) {
      await _ttsService?.speakTaskCreated(voiceTask.title);
      print('TaskProvider: Task created successfully: "${voiceTask.title}"');
    } else {
      print('TaskProvider: Failed to create task from voice command.');
      await _ttsService?.speak('Sorry, I couldn\'t create the task.');
    }
  }
  
  // Update task due date from voice command
  Future<void> _updateTaskDueDate(Task task, String? dueDateString) async {
    try {
      DateTime? dueDate;
      
      if (dueDateString != null) {
        final now = DateTime.now();
        switch (dueDateString.toLowerCase()) {
          case 'today':
            dueDate = DateTime(now.year, now.month, now.day, 23, 59);
            break;
          case 'tomorrow':
            dueDate = DateTime(now.year, now.month, now.day + 1, 23, 59);
            break;
          case 'tonight':
            dueDate = DateTime(now.year, now.month, now.day, 20, 0);
            break;
          default:
            dueDate = DateTime(now.year, now.month, now.day + 1, 23, 59); // Default tomorrow
        }
      }
      
      final updatedTask = task.copyWith(dueDate: dueDate);
      final success = await updateTask(updatedTask);
      
      if (success) {
        await _ttsService?.speak('Updated "${task.title}" due date to $dueDateString');
        print('TaskProvider: Updated task due date: "${task.title}" -> $dueDateString');
      } else {
        await _ttsService?.speak('Failed to update task due date');
      }
    } catch (e) {
      print('Error updating task due date: $e');
      await _ttsService?.speak('Error updating due date');
    }
  }
  
  // Clean any speech input into a task title
  String _cleanSpeechForTaskTitle(String speech) {
    String title = speech.toLowerCase().trim();
    
    // Remove common voice artifacts
    final artifacts = ['hey', 'um', 'uh', 'so', 'well', 'ok', 'now', 'whisp', 'whisper'];
    for (String artifact in artifacts) {
      title = title.replaceAll(artifact, ' ');
    }
    
    // Clean up spacing
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Capitalize
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }
    
    return title.isEmpty ? 'Voice Task ${DateTime.now().millisecondsSinceEpoch}' : title;
  }

  // Execute smart task update with enhanced matching
  Future<void> _executeSmartTaskUpdate(Map<String, dynamic> parsedCommand) async {
    final taskIdentifier = parsedCommand['taskIdentifier'] as String;
    final action = parsedCommand['action'] as String;
    
    // Find matching tasks using enhanced algorithm
    final matchingTasks = _findMatchingTasksEnhanced(taskIdentifier);

    if (matchingTasks.isEmpty) {
      await _ttsService?.speak("I couldn't find a task matching '${taskIdentifier}'.");
      print("Voice feedback: I couldn't find a task matching '${taskIdentifier}'.");
      return;
    }

    // For now, take the best match. Future improvement: handle multiple matches.
    final task = matchingTasks.first;
    
    // Execute action on the matched task
    final success = await _executeActionOnTaskByAction(task, action);
    
    if (success) {
      await _provideFeedbackForAction(task, action);
    } else {
      _handleVoiceError(VoiceError.taskUpdateFailed(task.id ?? '', 'Action execution failed'));
    }
  }

  // ULTRA-AGGRESSIVE: Execute task creation from ANY voice input
  Future<void> _executeTaskCreation(Map<String, dynamic> parsedCommand) async {
    final title = parsedCommand['title'] as String? ?? 'Voice Task';
    final originalCommand = parsedCommand['originalCommand'] as String? ?? title;
    
    print('TaskProvider: Creating task from ANY speech: "$title"');
    
    // Create task with intelligent parsing from any speech
    final voiceTask = VoiceParser.parseVoiceToTask(originalCommand);
    
    // Always succeed - force task creation
    try {
      final success = await addTask(voiceTask);
      
      if (success) {
        await _ttsService?.speakTaskCreated(voiceTask.title);
        print('TaskProvider: Task created successfully from speech: "${voiceTask.title}"');
      } else {
        // Force create a basic task even if main creation fails
        final fallbackTask = Task(
          title: title,
          createdAt: DateTime.now(),
          category: 'general',
          priority: 'medium',
        );
        await addTask(fallbackTask);
        await _ttsService?.speakTaskCreated(fallbackTask.title);
        print('TaskProvider: Fallback task created: "${fallbackTask.title}"');
      }
    } catch (e) {
      // Ultimate fallback - create minimal task
      final emergencyTask = Task(
        title: title.isEmpty ? 'Voice Task ${DateTime.now().millisecondsSinceEpoch}' : title,
        createdAt: DateTime.now(),
        category: 'general',
        priority: 'medium',
      );
      try {
        await addTask(emergencyTask);
        print('TaskProvider: Emergency task created: "${emergencyTask.title}"');
      } catch (finalError) {
        print('TaskProvider: All task creation failed: $finalError');
      }
    }
  }

  // Execute task update commands
  Future<void> _executeTaskUpdateCommand(TaskUpdateCommand command) async {
    print('Executing voice command: ${command.toString()}');
    
    // Find matching tasks
    final matchingTasks = _findMatchingTasksEnhanced(command.taskIdentifier);

    if (matchingTasks.isEmpty) {
      await _ttsService?.speak("I couldn't find a task matching '${command.taskIdentifier}'.");
      print("Voice feedback: I couldn't find a task matching '${command.taskIdentifier}'.");
      return;
    }

    // For now, take the best match. Future improvement: handle multiple matches.
    final task = matchingTasks.first;
    
    if (matchingTasks.isEmpty) {
      _handleVoiceError(VoiceError.taskNotFound(command.taskIdentifier));
      return;
    }
    
    // Execute command on single matching task
    final success = await _executeActionOnTask(task, command);
    
    if (success) {
      final feedback = VoiceParser.generateVoiceFeedback(
        command.action, 
        task.title, 
        success: true
      );
      await _speakFeedback(feedback);
    } else {
      await _speakFeedback("Sorry, I couldn't complete that action on '${task.title}'.");
    }
  }

  // Enhanced task matching with confidence scoring
  List<Task> _findMatchingTasksEnhanced(String taskIdentifier, {double threshold = 0.3}) {
    if (taskIdentifier.isEmpty) return [];

    List<TaskMatch> matches = [];
    
    // Clean and normalize the identifier for better matching
    final cleanIdentifier = _normalizeForMatching(taskIdentifier);
    
    for (var task in _tasks) {
      final cleanTaskTitle = _normalizeForMatching(task.title);
      
      // Try multiple matching strategies
      double bestScore = 0.0;
      
      // 1. Direct fuzzy matching
      final fuzzyScore = VoiceParser.getTaskMatchingScore(taskIdentifier, task.title);
      bestScore = fuzzyScore;
      
      // 2. Normalized matching (handles speech recognition errors)
      final normalizedScore = VoiceParser.getTaskMatchingScore(cleanIdentifier, cleanTaskTitle);
      bestScore = bestScore > normalizedScore ? bestScore : normalizedScore;
      
      // 3. Keyword extraction matching (for misheard words)
      final keywordScore = _getKeywordMatchScore(cleanIdentifier, cleanTaskTitle);
      bestScore = bestScore > keywordScore ? bestScore : keywordScore;
      
      if (bestScore >= threshold) {
        matches.add(TaskMatch(task: task, score: bestScore));
      }
    }

    // Sort by score descending
    matches.sort((a, b) => b.score.compareTo(a.score));

    // Return tasks from sorted matches
    return matches.map((match) => match.task).toList();
  }
  
  // Normalize text for better matching (handles speech recognition variations)
  String _normalizeForMatching(String text) {
    return text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
  }
  
  // Extract keywords and match them (helps with misheard words)
  double _getKeywordMatchScore(String identifier, String taskTitle) {
    final identifierWords = identifier.split(' ').where((w) => w.length > 2).toList();
    final taskWords = taskTitle.split(' ').where((w) => w.length > 2).toList();
    
    if (identifierWords.isEmpty || taskWords.isEmpty) return 0.0;
    
    int matches = 0;
    for (final word in identifierWords) {
      for (final taskWord in taskWords) {
        // Check for partial matches (handles "ark" vs "buy", "milk" vs "milk")
        if (taskWord.contains(word) || word.contains(taskWord) || 
            _areSimilarWords(word, taskWord)) {
          matches++;
          break;
        }
      }
    }
    
    return matches / identifierWords.length;
  }
  
  // Check if two words are phonetically similar (common speech recognition errors)
  bool _areSimilarWords(String word1, String word2) {
    // Handle common speech recognition substitutions
    final substitutions = {
      'ark': ['buy', 'bar', 'car'],
      'buy': ['ark', 'by', 'bye'],
      'milk': ['melk', 'malk'],
      'called': ['call', 'cold'],
    };
    
    return substitutions[word1]?.contains(word2) == true ||
           substitutions[word2]?.contains(word1) == true;
  }
  
  // Find matching tasks with scores for advanced processing
  List<TaskMatch> _findMatchingTasksWithScores(String taskIdentifier, {double threshold = 0.5}) {
    if (taskIdentifier.isEmpty) return [];

    List<TaskMatch> matches = [];
    for (var task in _tasks) {
      final score = VoiceParser.getTaskMatchingScore(taskIdentifier, task.title);
      if (score >= threshold) {
        matches.add(TaskMatch(task: task, score: score));
      }
    }

    // Sort by score descending
    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches;
  }


  // Execute action on task by action string
  Future<bool> _executeActionOnTaskByAction(Task task, String action) async {
    switch (action) {
      case 'complete':
        return await markTaskCompleteByVoice(task.id);
      case 'start':
        return await updateTaskStatusByVoice(task.id, 'in_progress');
      case 'pause':
        return await updateTaskStatusByVoice(task.id, 'pending');
      case 'cancel':
        return await updateTaskStatusByVoice(task.id, 'cancelled');
      case 'delete':
        return task.id != null ? await deleteTask(task.id!) : false;
      case 'changePriority':
        return await updateTaskPriorityByVoice(task.id, 'high');
      default:
        return false;
    }
  }

  // Provide feedback for completed action
  Future<void> _provideFeedbackForAction(Task task, String action) async {
    switch (action) {
      case 'complete':
        await _ttsService?.speakTaskCompleted(task.title);
        break;
      case 'start':
        await _ttsService?.speakTaskStarted(task.title);
        break;
      case 'pause':
        await _ttsService?.speakTaskPaused(task.title);
        break;
      case 'cancel':
        await _ttsService?.speakTaskCancelled(task.title);
        break;
      case 'delete':
        await _ttsService?.speakTaskDeleted(task.title);
        break;
      case 'changePriority':
        await _ttsService?.speakPriorityChanged(task.title, 'high');
        break;
      default:
        await _speakFeedback('Action completed on ${task.title}');
    }
  }

  // Handle multiple task matches
  Future<void> _handleMultipleTaskMatches(List<Task> tasks, TaskUpdateCommand command) async {
    if (tasks.length <= 3) {
      // List the options for few matches
      final taskNames = tasks.take(3).map((t) => t.title).join(', ');
      await _speakFeedback("I found multiple tasks: $taskNames. Please be more specific.");
    } else {
      await _speakFeedback("I found ${tasks.length} matching tasks. Please be more specific.");
    }
  }

  // Execute action on specific task
  Future<bool> _executeActionOnTask(Task task, TaskUpdateCommand command) async {
    switch (command.action) {
      case TaskUpdateAction.markComplete:
        return await markTaskCompleteByVoice(task.id);
      
      case TaskUpdateAction.start:
        return await updateTaskStatusByVoice(task.id, 'in_progress');
      
      case TaskUpdateAction.pause:
        return await updateTaskStatusByVoice(task.id, 'pending');
      
      case TaskUpdateAction.cancel:
        return await updateTaskStatusByVoice(task.id, 'cancelled');
      
      case TaskUpdateAction.delete:
        return task.id != null ? await deleteTask(task.id!) : false;
      
      case TaskUpdateAction.changePriority:
        final newPriority = command.parameters['priority'] ?? 'medium';
        return await updateTaskPriorityByVoice(task.id, newPriority);
    }
  }

  // Voice-specific task update methods
  Future<bool> markTaskCompleteByVoice(String? taskId) async {
    if (taskId == null) return false;
    
    try {
      final task = getTaskById(taskId);
      if (task == null || task.isCompleted) return false;
      
      final updatedTask = task.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        status: 'completed',
      );
      
      final success = await updateTask(updatedTask);
      if (success) {
        // Track analytics event
        FirebaseAnalytics.instance.logEvent(name: 'task_completed');
        
        // Auto-save productivity score when tasks change (with error handling)
        try {
          final score = calculateDailyProductivityScore();
          await UserPreferencesService().saveDailyProductivityScore(score);
        } catch (e) {
          // Silently handle productivity score save errors to not disrupt task completion
          print('Note: Productivity score not saved (${e.toString().split(':').last.trim()})');
        }
      }
      return success;
    } catch (e) {
      print('Error completing task by voice: $e');
      return false;
    }
  }

  Future<bool> updateTaskStatusByVoice(String? taskId, String status) async {
    if (taskId == null) return false;
    
    try {
      final task = getTaskById(taskId);
      if (task == null) return false;
      
      final updatedTask = task.copyWith(status: status);
      return await updateTask(updatedTask);
    } catch (e) {
      print('Error updating task status by voice: $e');
      return false;
    }
  }

  Future<bool> updateTaskPriorityByVoice(String? taskId, String priority) async {
    if (taskId == null) return false;
    
    try {
      final task = getTaskById(taskId);
      if (task == null) return false;
      
      final updatedTask = task.copyWith(priority: priority);
      return await updateTask(updatedTask);
    } catch (e) {
      print('Error updating task priority by voice: $e');
      return false;
    }
  }

  // Find tasks by partial title for voice commands
  List<Task> findTasksByQuery(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return _tasks.where((task) {
      final titleMatch = task.title.toLowerCase().contains(lowerQuery);
      final descriptionMatch = task.description?.toLowerCase().contains(lowerQuery) ?? false;
      return titleMatch || descriptionMatch;
    }).toList();
  }

  // Enhanced TTS feedback with error handling - DISABLED FOR USER PREFERENCE
  Future<void> _speakFeedback(String message) async {
    // Voice announcements disabled - only log the message
    debugPrint('Voice feedback (disabled): $message');
    return;
    
    // Original code commented out to disable voice announcements
    /*
    try {
      if (_ttsService != null && _ttsService!.isInitialized) {
        await _ttsService!.speak(message);
      } else if (_flutterTts != null) {
        await _flutterTts!.speak(message);
      }
      debugPrint('Voice feedback: $message');
    } catch (e) {
      debugPrint('Error speaking feedback: $e');
    }
    */
  }


  // Get voice command help
  String getVoiceCommandHelp() {
    return '''
Voice Commands Available:
• "Hey Whisp, mark [task name] as done"
• "Hey Whisp, complete [task name]" 
• "Hey Whisp, start [task name]"
• "Hey Whisp, finish the first task"
• "Hey Whisp, delete [task name]"
• "Hey Whisp, set [task name] to high priority"

Examples:
• "Hey Whisp, mark grocery shopping as complete"
• "Hey Whisp, finish my meeting task"
• "Hey Whisp, complete the first task"
    ''';
  }

  // Add this method to calculate daily productivity score
  double calculateDailyProductivityScore() {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Get tasks that are due today or were completed today
      final todayTasks = _tasks.where((task) {
        // Include tasks due today
        if (task.dueDate != null) {
          final dueDate = task.dueDate!;
          final dueDateStart = DateTime(dueDate.year, dueDate.month, dueDate.day);
          if (dueDateStart.isAtSameMomentAs(startOfDay)) {
            return true;
          }
        }
        
        // Include tasks completed today
        if (task.isCompleted && task.completedAt != null) {
          return task.completedAt!.isAfter(startOfDay) && 
                 task.completedAt!.isBefore(endOfDay);
        }
        
        // Include tasks created today (for tasks without due dates)
        if (task.dueDate == null && !task.isCompleted) {
          return task.createdAt.isAfter(startOfDay) && 
                 task.createdAt.isBefore(endOfDay);
        }
        
        return false;
      }).toList();
      
      print('ProductivityScore: Found ${todayTasks.length} tasks for today');
      
      if (todayTasks.isEmpty) {
        // If no tasks for today, check if there are any completed tasks today
        final completedToday = _tasks.where((task) => 
          task.isCompleted && 
          task.completedAt != null &&
          task.completedAt!.isAfter(startOfDay) && 
          task.completedAt!.isBefore(endOfDay)
        ).length;
        
        print('ProductivityScore: No scheduled tasks, but $completedToday completed today');
        return completedToday > 0 ? 50.0 : 0.0; // Give partial score for completing any tasks
      }
      
      final completedTasks = todayTasks.where((task) => task.isCompleted).length;
      print('ProductivityScore: $completedTasks completed out of ${todayTasks.length}');
      
      // Calculate score with bonus for early completion
      double baseScore = (completedTasks / todayTasks.length) * 100;
      
      // Add bonus points for completing tasks early or on time
      int bonusPoints = 0;
      for (final task in todayTasks) {
        if (task.isCompleted && 
            task.completedAt != null && 
            task.dueDate != null) {
          if (task.completedAt!.isBefore(task.dueDate!)) {
            bonusPoints += 5; // 5% bonus for early completion
          }
        }
      }
      
      final finalScore = (baseScore + bonusPoints).clamp(0.0, 100.0);
      print('ProductivityScore: Final score = $finalScore (base: $baseScore, bonus: $bonusPoints)');
      
      return finalScore;
    } catch (e) {
      print('ProductivityScore: Error calculating score - $e');
      return 0.0;
    }
  }

  // Add this getter for easy access
  double get dailyProductivityScore => calculateDailyProductivityScore();
  
  // Method to manually refresh productivity score (for debugging)
  void refreshProductivityScore() {
    print('TaskProvider: Manually refreshing productivity score...');
    final score = calculateDailyProductivityScore();
    print('TaskProvider: Current productivity score = $score');
    _safeNotifyListeners();
  }

  // Getter for voice service (needed by VoiceIntegrationService)
  VoiceService? get voiceService => _voiceService;

  // Update live transcript in VoiceProvider for real-time display
  void _updateLiveTranscript(String liveText) {
    // Find VoiceProvider and update live transcript
    // This will be called from the speech results stream
    print('TaskProvider: Updating live transcript: "$liveText"');
    // Note: VoiceProvider will be updated via the UI context
  }

  // Clean voice command - remove duplicates and artifacts for all command types
  String _cleanVoiceCommand(String command) {
    String cleaned = command.trim();
    
    // Remove duplicate consecutive words (fix "do do do homework" -> "do homework")
    cleaned = _removeDuplicateWords(cleaned);
    
    // Remove common speech artifacts
    cleaned = _cleanSpeechArtifacts(cleaned);
    
    return cleaned;
  }

  // Remove duplicate consecutive words
  String _removeDuplicateWords(String text) {
    List<String> words = text.split(' ');
    List<String> cleanWords = [];
    
    for (int i = 0; i < words.length; i++) {
      String currentWord = words[i].toLowerCase();
      
      // Skip if this word is the same as the previous word
      if (cleanWords.isEmpty || cleanWords.last.toLowerCase() != currentWord) {
        cleanWords.add(words[i]);
      }
    }
    
    return cleanWords.join(' ');
  }

  // Clean common speech recognition artifacts
  String _cleanSpeechArtifacts(String text) {
    String cleaned = text;
    
    // Remove common speech artifacts
    final artifacts = [
      RegExp(r'\b(um|uh|er|ah)\b', caseSensitive: false),
      RegExp(r'\b(like|you know)\b', caseSensitive: false),
      RegExp(r'\b(well|so)\s+', caseSensitive: false),
      RegExp(r'\s+(please|thanks?)\s*$', caseSensitive: false),
    ];
    
    for (RegExp artifact in artifacts) {
      cleaned = cleaned.replaceAll(artifact, ' ');
    }
    
    // Remove extra punctuation and clean spaces
    cleaned = cleaned.replaceAll(RegExp(r'[.,!?]+$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned;
  }

  @override
  void dispose() {
    _disposed = true;
    _tasksStreamSubscription?.cancel();
    _voiceCommandSubscription?.cancel();
    _voiceService?.dispose();
    _flutterTts?.stop();
    super.dispose();
  }
}