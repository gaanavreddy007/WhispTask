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
import 'package:flutter_tts/flutter_tts.dart';
import '../services/tts_service.dart';
import '../services/voice_error_handler.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../services/user_preferences_service.dart';

// Helper class for storing task matches with scores
class TaskMatch {
  final Task task;
  final double score;

  TaskMatch({required this.task, required this.score});
}

class TaskProvider extends ChangeNotifier {
  // Private fields
  final TaskService _taskService = TaskService();
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
  
  // NEW: Voice command getters
  bool get isProcessingVoiceCommand => _isProcessingVoiceCommand;
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
        notifyListeners();
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
    if (_currentUserId == null) {
      _setError('User not authenticated');
      return false;
    }

    // Check premium limits
    if (!canAddTask()) {
      _setError('Daily task limit reached (20 tasks). Upgrade to Pro for unlimited tasks!');
      return false;
    }

    _setLoading(true);
    try {
      // Set the userId in the task
      final taskWithUserId = task.copyWith(userId: _currentUserId);
      final bool success = await _taskService.addTask(taskWithUserId, _currentUserId!);
      
      if (success) {
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
        
        notifyListeners();
        
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
      } else {
        _setError('Failed to add task');
      }
      
      return success;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('provider', 'task');
          scope.setTag('operation', 'add_task');
          scope.setExtra('task_title', task.title);
          scope.level = SentryLevel.error;
        },
      );
      _setError('Failed to add task: $e');
      return false;
    } finally {
      _setLoading(false);
    }
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
        notifyListeners();
        
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
    if (_currentUserId == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      final bool success = await _taskService.toggleTaskCompletion(taskId, _currentUserId!);
      
      if (success) {
        // Reload tasks to reflect the change immediately
        await _loadUserTasks();
        
        // Get the updated task
        final updatedTask = _tasks.firstWhere((t) => t.id == taskId);
        
        // Cancel notification if task is now completed
        if (updatedTask.isCompleted && updatedTask.notificationId != null) {
          await NotificationService().cancelNotification(updatedTask.notificationId!);
        }
        
        await _loadTaskStats();
        await loadAnalytics();
        _clearError();
        
        // Force UI update
        notifyListeners();
      } else {
        _setError('Failed to toggle task completion');
      }
      
      return success;
    } catch (e) {
      _setError('Failed to toggle task completion: $e');
      return false;
    }
  }

  void setRecurringFilter(bool showRecurringOnly) {
    _showRecurringOnly = showRecurringOnly;
    notifyListeners();
  }

  void toggleCategoryFilter(String category) {
    _selectedCategories.contains(category)
        ? _selectedCategories.remove(category)
        : _selectedCategories.add(category);
    notifyListeners();
  }

  void togglePriorityFilter(String priority) {
    _selectedPriorities.contains(priority)
        ? _selectedPriorities.remove(priority)
        : _selectedPriorities.add(priority);
    notifyListeners();
  }

  void toggleStatusFilter(String status) {
    _selectedStatuses.contains(status)
        ? _selectedStatuses.remove(status)
        : _selectedStatuses.add(status);
    notifyListeners();
  }

  void toggleColorFilter(String color) {
    _selectedColors.contains(color)
        ? _selectedColors.remove(color)
        : _selectedColors.add(color);
    notifyListeners();
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

  /// Search tasks
  Future<void> searchTasks(String query) async {
    _searchQuery = query;
    notifyListeners();
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
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
    notifyListeners();
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
      
      // Initialize voice service
      _voiceService = VoiceService();
      final voiceInitialized = await _voiceService!.initialize();
      print('Voice service initialized: $voiceInitialized');
      if (!voiceInitialized) {
        _handleVoiceError(VoiceError.notInitialized());
        return;
      }
      
      // Listen to voice command stream with enhanced error handling
      _voiceCommandSubscription = _voiceService!.voiceCommandStream?.listen(
        (command) {
          print('Voice command received: $command');
          processVoiceTaskCommandEnhanced(command);
        },
        onError: (error) {
          print('Voice command stream error: $error');
          _handleVoiceError(VoiceError.speechRecognitionError(error.toString()));
        },
      );
      
      // Provide initialization feedback
      await _ttsService!.speakListeningStarted();
      debugPrint('Enhanced voice commands initialized successfully');
      
    } catch (e) {
      _handleVoiceError(VoiceError.commandProcessingFailed('initialization', e.toString()));
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

  // Enhanced Voice Command Processing with smart task detection
  Future<void> processVoiceTaskCommandEnhanced(String command) async {
    print('TaskProvider: Processing voice input: "$command"');

    if (_isProcessingVoiceCommand) {
      print('TaskProvider: Already processing a command, skipping.');
      return;
    }

    _isProcessingVoiceCommand = true;

    try {
      // Use the enhanced parser that can detect time-based updates
      final parsedCommand = VoiceParser.parseVoiceCommand(command);
      
      // Handle validation errors
      if (parsedCommand['type'] == 'error') {
        print('TaskProvider: Invalid command - ${parsedCommand['errorType']}');
        await _ttsService?.speak(parsedCommand['suggestion'] ?? 'Please try again');
        return;
      }
      
      // Handle task updates (including time-based updates like "homework tomorrow")
      if (parsedCommand['type'] == 'task_update') {
        print('TaskProvider: Detected task update command');
        await _handleTaskUpdate(parsedCommand);
      } 
      // Handle task creation
      else if (parsedCommand['type'] == 'create_task') {
        print('TaskProvider: Detected task creation command');
        await _handleTaskCreation(parsedCommand);
      }
      
    } catch (e) {
      print('TaskProvider: Error processing voice command: $e');
      _handleVoiceError(VoiceError.commandProcessingFailed(command, e.toString()));
    } finally {
      _isProcessingVoiceCommand = false;
      notifyListeners();
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

  // Enhanced TTS feedback with error handling
  Future<void> _speakFeedback(String message) async {
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
  }

  // Test voice command reliability
  Future<double> testVoiceReliability() async {
    if (_voiceService == null) return 0.0;
    return await _voiceService!.getCommandReliabilityScore();
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
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    
    final todayTasks = _tasks.where((task) {
      return task.createdAt.isAfter(startOfDay) && 
             task.createdAt.isBefore(endOfDay);
    }).toList();
    
    if (todayTasks.isEmpty) return 0.0;
    
    final completedTasks = todayTasks.where((task) => 
      task.status == TaskStatus.completed).length;
    
    return (completedTasks / todayTasks.length) * 100;
  }

  // Add this getter for easy access
  double get dailyProductivityScore => calculateDailyProductivityScore();

  @override
  void dispose() {
    _tasksStreamSubscription?.cancel();
    _voiceCommandSubscription?.cancel();
    _voiceService?.dispose();
    _flutterTts?.stop();
    super.dispose();
  }
}