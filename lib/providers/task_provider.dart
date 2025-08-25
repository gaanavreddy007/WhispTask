import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  final NotificationService _notificationService = NotificationService();
  
  List<Task> _tasks = [];
  List<Task> _upcomingReminders = [];
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  bool _isSchedulingReminder = false;
  String? _error;
  StreamSubscription<List<Task>>? _tasksSubscription;
  StreamSubscription<List<Task>>? _remindersSubscription;

  // Getters
  List<Task> get tasks => _tasks;
  List<Task> get upcomingReminders => _upcomingReminders;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  bool get isSchedulingReminder => _isSchedulingReminder;
  String? get error => _error;

  // Get tasks by status
  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();
  List<Task> get incompleteTasks => _tasks.where((task) => !task.isCompleted).toList();

  // Get tasks by priority
  List<Task> get highPriorityTasks => _tasks.where((task) => task.priority == 'high').toList();
  List<Task> get mediumPriorityTasks => _tasks.where((task) => task.priority == 'medium').toList();
  List<Task> get lowPriorityTasks => _tasks.where((task) => task.priority == 'low').toList();

  // Get overdue tasks
  List<Task> get overdueTasks {
    final now = DateTime.now();
    return _tasks.where((task) => 
      !task.isCompleted && 
      task.dueDate != null && 
      task.dueDate!.isBefore(now)
    ).toList();
  }

  // Get today's tasks
  List<Task> get todaysTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return _tasks.where((task) => 
      task.dueDate != null && 
      task.dueDate!.isAfter(today) && 
      task.dueDate!.isBefore(tomorrow)
    ).toList();
  }

  // Get tasks with reminders
  List<Task> get tasksWithReminders => _tasks.where((task) => task.hasActiveReminder).toList();

  // Get overdue reminders
  List<Task> get overdueReminders {
    final now = DateTime.now();
    return _tasks.where((task) => 
      task.hasActiveReminder && 
      task.reminderTime != null && 
      task.reminderTime!.isBefore(now) &&
      !task.isCompleted
    ).toList();
  }

  TaskProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    await _notificationService.initialize();
    _loadTasks();
    _loadUpcomingReminders();
    
    // Reschedule all existing reminders on app start
    await _rescheduleAllReminders();
  }

  void _loadTasks() {
    _isLoading = true;
    notifyListeners();

    _tasksSubscription = _taskService.getTasks().listen(
      (tasks) {
        _tasks = tasks;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _loadUpcomingReminders() {
    _remindersSubscription = _taskService.getTasksWithReminders().listen(
      (reminders) {
        _upcomingReminders = reminders;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error loading reminders: $error');
      },
    );
  }

  // FIXED: Get notification ID from task ID consistently
  int _getNotificationId(String taskId) {
    return taskId.hashCode;
  }

// UPDATED: Add task with direct notification scheduling
Future<bool> addTask(Task task) async {
  try {
    _isCreating = true;
    _error = null;
    notifyListeners();
    
    // Create task in Firestore - the notification scheduling is now handled inside createTask
    await _taskService.createTask(task);
    
    _isCreating = false;
    notifyListeners();
    return true;
  } catch (e) {
    _error = e.toString();
    _isCreating = false;
    notifyListeners();
    return false;
  }
}

  // FIXED: Update task with notification management
  Future<bool> updateTask(Task task) async {
    try {
      _isUpdating = true;
      _error = null;
      notifyListeners();
      
      // Get the old task to compare reminders
      final oldTask = _tasks.firstWhere((t) => t.id == task.id);
      
      // FIXED: Cancel old notification using task ID hash
      if (oldTask.id != null) {
        final notificationId = _getNotificationId(oldTask.id!);
        await _notificationService.cancelNotification(notificationId);
      }
      
      // Update task in Firestore
      await _taskService.updateTask(task);
      
      // Schedule new notification if reminder is set and task isn't completed
      if (task.hasReminder && task.reminderTime != null && !task.isCompleted) {
        await _scheduleTaskReminder(task);
      }
      
      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  // FIXED: Delete task with notification cleanup
  Future<bool> deleteTask(String taskId) async {
    try {
      _isDeleting = true;
      _error = null;
      notifyListeners();
      
      // FIXED: Cancel notification using task ID hash
      final notificationId = _getNotificationId(taskId);
      await _notificationService.cancelNotification(notificationId);
      
      await _taskService.deleteTask(taskId);
      _isDeleting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isDeleting = false;
      notifyListeners();
      return false;
    }
  }

  // FIXED: Toggle task with notification management
  Future<bool> toggleTask(String taskId, bool isCompleted) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      
      // FIXED: Cancel notification when task is completed
      if (isCompleted) {
        final notificationId = _getNotificationId(taskId);
        await _notificationService.cancelNotification(notificationId);
      }
      
      // Reschedule notification when task is uncompleted
      if (!isCompleted && task.hasReminder && task.reminderTime != null) {
        await _scheduleTaskReminder(task);
      }
      
      await _taskService.toggleTaskCompletion(taskId, isCompleted);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // UPDATED: Helper method to schedule task reminder
  Future<void> _scheduleTaskReminder(Task task) async {
    try {
      if (task.id == null) {
        throw Exception('Task ID cannot be null');
      }

      // Use the correct method from NotificationService
      await _notificationService.scheduleTaskReminder(task);
      
      // FIXED: Update task with notification ID for tracking (as string)
      final notificationId = _getNotificationId(task.id!);
      final updatedTask = task.copyWith(notificationId: notificationId.toString());
      await _taskService.updateTask(updatedTask);
      
    } catch (e) {
      debugPrint('Error scheduling reminder: $e');
      rethrow;
    }
  }

  // Reminder-specific methods
  Future<bool> scheduleReminder(
    String taskId,
    DateTime reminderTime, {
    String reminderType = 'once',
    List<String> repeatDays = const [],
    String notificationTone = 'default',
  }) async {
    try {
      _isSchedulingReminder = true;
      _error = null;
      notifyListeners();

      final task = _tasks.firstWhere((t) => t.id == taskId);
      final updatedTask = task.copyWith(
        hasReminder: true,
        reminderTime: reminderTime,
        reminderType: reminderType,
        repeatDays: repeatDays,
        notificationTone: notificationTone,
        isReminderActive: true,
      );

      await updateTask(updatedTask);

      _isSchedulingReminder = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSchedulingReminder = false;
      notifyListeners();
      return false;
    }
  }

  // FIXED: Cancel reminder
  Future<bool> cancelReminder(String taskId) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      
      // FIXED: Cancel the notification using task ID hash
      final notificationId = _getNotificationId(taskId);
      await _notificationService.cancelNotification(notificationId);
      
      // Update task to remove reminder
      final updatedTask = task.copyWith(
        hasReminder: false,
        reminderTime: null,
        isReminderActive: false,
        notificationId: null,
      );
      
      await updateTask(updatedTask);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> snoozeReminder(String taskId, int minutes) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final newReminderTime = DateTime.now().add(Duration(minutes: minutes));
      
      final updatedTask = task.copyWith(reminderTime: newReminderTime);
      await updateTask(updatedTask);
      
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReminderTone(String taskId, String tone) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final updatedTask = task.copyWith(notificationTone: tone);
      
      await updateTask(updatedTask);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // UPDATED: Reschedule all reminders (useful on app start)
  Future<void> _rescheduleAllReminders() async {
    try {
      for (final task in tasksWithReminders) {
        if (task.reminderTime != null && task.reminderTime!.isAfter(DateTime.now())) {
          await _scheduleTaskReminder(task);
        }
      }
    } catch (e) {
      debugPrint('Error rescheduling reminders: $e');
    }
  }

  // Send test notification
  Future<bool> sendTestNotification() async {
    try {
      await _notificationService.sendTestNotification();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get notification statistics
  Future<Map<String, int>> getNotificationStats() async {
    try {
      final pendingNotifications = await _notificationService.getPendingNotifications();
      
      return {
        'total_tasks': _tasks.length,
        'tasks_with_reminders': tasksWithReminders.length,
        'pending_notifications': pendingNotifications.length,
        'overdue_reminders': overdueReminders.length,
        'upcoming_reminders': _upcomingReminders.length,
      };
    } catch (e) {
      return {};
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<Task> getTasksByCategory(String category) {
    return _tasks.where((task) => task.category == category).toList();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    _remindersSubscription?.cancel();
    super.dispose();
  }

  // FOR TESTING ONLY
  @visibleForTesting
  void setTasksForTesting(List<Task> tasks) {
    _tasks = tasks;
  }
}