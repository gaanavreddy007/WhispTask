// ignore_for_file: avoid_print, unused_field, prefer_final_fields

import 'package:flutter/material.dart';
import 'dart:async';

import '../models/task.dart';
import '../services/task_service.dart';
import '../services/notification_service.dart';
import '../utils/notification_helper.dart';
import '../providers/auth_provider.dart';

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

  /// Add a new task - ENHANCED with new model fields
  Future<bool> addTask(Task task) async {
    if (_currentUserId == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    try {
      // Set the userId in the task
      final taskWithUserId = task.copyWith(userId: _currentUserId);
      final bool success = await _taskService.addTask(taskWithUserId, _currentUserId!);
      
      if (success) {
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
        // Cancel notification
        final task = _tasks.firstWhere((t) => t.id == taskId);
        if (task.notificationId != null) {
          await NotificationService().cancelNotification(task.notificationId!);
        }
        
        // Remove task from local list
        _tasks.removeWhere((t) => t.id == taskId);
        notifyListeners();
        
        await _loadTaskStats();
        await loadAnalytics();
        _clearError();
      } else {
        _setError('Failed to delete task');
      }
      
      return success;
    } catch (e) {
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
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final bool success = await _taskService.toggleTaskCompletion(taskId, _currentUserId!);
      
      if (success) {
        // Handle recurring tasks
        // if (task.isRecurring && !task.isCompleted) {
        //   await _taskService.processRecurringTask(task, _currentUserId!); // Method does not exist
        // }
        
        // Cancel notification if task is completed
        if (!task.isCompleted && task.notificationId != null) {
          await NotificationService().cancelNotification(task.notificationId!);
        }
        
        await _loadTaskStats();
        await loadAnalytics();
        _clearError();
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

  @override
  void dispose() {
    _tasksStreamSubscription?.cancel();
    super.dispose();
  }
}