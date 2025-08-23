import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  String? _error;
  StreamSubscription<List<Task>>? _tasksSubscription;

  // Getters
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
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

  TaskProvider() {
    _loadTasks();
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

  Future<bool> addTask(Task task) async {
    try {
      _isCreating = true;
      _error = null;
      notifyListeners();
      
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

  Future<bool> updateTask(Task task) async {
    try {
      _isUpdating = true;
      _error = null;
      notifyListeners();
      
      await _taskService.updateTask(task);
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

  Future<bool> deleteTask(String taskId) async {
    try {
      _isDeleting = true;
      _error = null;
      notifyListeners();
      
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

  Future<bool> toggleTask(String taskId, bool isCompleted) async {
    try {
      await _taskService.toggleTaskCompletion(taskId, isCompleted);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
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
    super.dispose();
  }

  // FOR TESTING ONLY - This method should only be used in tests
  @visibleForTesting
  void setTasksForTesting(List<Task> tasks) {
    _tasks = tasks;
  }
}
