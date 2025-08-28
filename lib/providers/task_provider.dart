// ignore_for_file: avoid_print, unused_field

import 'package:flutter/material.dart';
import 'dart:async';

import '../models/task.dart';
import '../services/task_service.dart';
import '../services/notification_service.dart';
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
  String _selectedCategory = 'All';
  String _selectedPriority = 'All';
  String _searchQuery = '';
  
  // Task statistics
  Map<String, int> _taskStats = {
    'total': 0,
    'completed': 0,
    'pending': 0,
    'overdue': 0,
  };
  
  // Stream subscriptions
  StreamSubscription<List<Task>>? _tasksStreamSubscription;
  
  // Getters
  List<Task> get tasks => _filteredTasks;
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
  
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String? get error => _errorMessage.isEmpty ? null : _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get selectedPriority => _selectedPriority;
  String get searchQuery => _searchQuery;
  Map<String, int> get taskStats => _taskStats;
  
  bool get hasError => _errorMessage.isNotEmpty;
  bool get hasTasks => _tasks.isNotEmpty;
  bool get hasCompletedTasks => _completedTasks.isNotEmpty;
  bool get hasPendingTasks => _pendingTasks.isNotEmpty;
  bool get hasOverdueTasks => _overdueeTasks.isNotEmpty;
  bool get hasTodayTasks => _todayTasks.isNotEmpty;
  
  // Computed properties
  double get completionPercentage {
    if (_taskStats['total'] == 0) return 0.0;
    return (_taskStats['completed']! / _taskStats['total']!) * 100;
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
  
  /// Get filtered tasks based on current filters
  List<Task> get _filteredTasks {
    List<Task> filtered = List.from(_tasks);
    
    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((task) => task.category == _selectedCategory).toList();
    }
    
    // Apply priority filter
    if (_selectedPriority != 'All') {
      filtered = filtered.where((task) => task.priority == _selectedPriority).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((task) {
        return task.title.toLowerCase().contains(query) ||
               (task.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    return filtered;
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
  }

  /// Setup real-time task updates
  void _setupTasksStream(String userId) {
    _tasksStreamSubscription = _taskService.getUserTasksStream(userId).listen(
      (tasks) {
        _tasks = tasks;
        _updateTaskLists();
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
    _selectedCategory = 'All';
    _selectedPriority = 'All';
    _searchQuery = '';
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

  /// Add a new task
  Future<bool> addTask(Task task) async {
    if (_currentUserId == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    try {
      final bool success = await _taskService.addTask(task, _currentUserId!);
      
      if (success) {
        // Schedule notification if reminder is set
        if (task.hasReminder && task.reminderTime != null) {
          await NotificationService().scheduleNotification(
            id: task.hashCode,
            title: 'Task Reminder',
            body: task.title,
            scheduledTime: task.reminderTime!,
            payload: task.id,
          );
        }
        
        await _loadTaskStats();
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

  /// Update an existing task
  Future<bool> updateTask(Task task) async {
    if (_currentUserId == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    try {
      final bool success = await _taskService.updateTask(task, _currentUserId!);
      
      if (success) {
        // Update notification
        await NotificationService().cancelNotification(task.hashCode);
        
        if (task.hasReminder && task.reminderTime != null && !task.isCompleted) {
          await NotificationService().scheduleNotification(
            id: task.hashCode,
            title: 'Task Reminder',
            body: task.title,
            scheduledTime: task.reminderTime!,
            payload: task.id,
          );
        }
        
        await _loadTaskStats();
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
        await NotificationService().cancelNotification(task.hashCode);
        
        await _loadTaskStats();
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

  /// Toggle task completion
  Future<bool> toggleTaskCompletion(String taskId) async {
    if (_currentUserId == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      final bool success = await _taskService.toggleTaskCompletion(taskId, _currentUserId!);
      
      if (success) {
        final task = _tasks.firstWhere((t) => t.id == taskId);
        
        // Cancel notification if task is completed
        if (!task.isCompleted) {
          await NotificationService().cancelNotification(task.hashCode);
        }
        
        await _loadTaskStats();
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

  /// Search tasks
  Future<void> searchTasks(String query) async {
    _searchQuery = query;
    notifyListeners();
  }

  /// Set category filter
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Set priority filter
  void setPriority(String priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedCategory = 'All';
    _selectedPriority = 'All';
    _searchQuery = '';
    notifyListeners();
  }

  /// Refresh tasks
  Future<void> refreshTasks() async {
    await _loadUserTasks();
    await _loadTaskStats();
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

  /// Migrate tasks from anonymous to registered user
  Future<bool> migrateUserTasks(String fromUserId, String toUserId) async {
    try {
      final bool success = await _taskService.migrateUserTasks(fromUserId, toUserId);
      
      if (success) {
        // Update current user ID and reload data
        _currentUserId = toUserId;
        await refreshTasks();
      }
      
      return success;
    } catch (e) {
      _setError('Failed to migrate tasks: $e');
      return false;
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

  /// Snooze reminder
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