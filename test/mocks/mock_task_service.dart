import 'dart:async';
import 'package:whisptask/models/task.dart';

class MockTaskService {
  final List<Task> _tasks = [];
  final StreamController<List<Task>> _tasksController = StreamController<List<Task>>.broadcast();
  final StreamController<List<Task>> _incompleteTasksController = StreamController<List<Task>>.broadcast();
  final Map<String, StreamController<List<Task>>> _categoryControllers = {};

  // Simulate current user ID
  String currentUserId = 'test_user_123';

  MockTaskService() {
    _updateAllStreams();
  }

  void _updateAllStreams() {
    _tasksController.add(List.from(_tasks));
    _incompleteTasksController.add(_tasks.where((task) => !task.isCompleted).toList());
    
    // Update category streams
    for (final controller in _categoryControllers.values) {
      final category = _categoryControllers.keys.firstWhere((key) => _categoryControllers[key] == controller);
      controller.add(_tasks.where((task) => task.category == category).toList());
    }
  }

  // Create new task (matching your service interface)
  Future<String> createTask(Task task) async {
    // Validate task data (same as your service)
    if (task.title.trim().isEmpty) {
      throw Exception('Task title cannot be empty');
    }
    
    if (task.title.length > 100) {
      throw Exception('Task title too long (max 100 characters)');
    }
    
    if (task.description != null && task.description!.length > 500) {
      throw Exception('Task description too long (max 500 characters)');
    }

    // Create task with generated ID
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final newTask = task.copyWith(id: taskId);
    
    _tasks.add(newTask);
    _updateAllStreams();
    
    return taskId;
  }

  // Get all tasks
  Stream<List<Task>> getTasks() {
    return _tasksController.stream;
  }

  // Get tasks by category
  Stream<List<Task>> getTasksByCategory(String category) {
    if (!_categoryControllers.containsKey(category)) {
      _categoryControllers[category] = StreamController<List<Task>>.broadcast();
    }
    
    // Send initial data
    final categoryTasks = _tasks.where((task) => task.category == category).toList();
    _categoryControllers[category]!.add(categoryTasks);
    
    return _categoryControllers[category]!.stream;
  }

  // Get incomplete tasks
  Stream<List<Task>> getIncompleteTasks() {
    return _incompleteTasksController.stream;
  }

  // Update task
  Future<void> updateTask(Task task) async {
    if (task.id == null) throw Exception('Task ID cannot be null');
    
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _updateAllStreams();
    } else {
      throw Exception('Task not found');
    }
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      _tasks.removeAt(index);
      _updateAllStreams();
    } else {
      throw Exception('Task not found');
    }
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final updatedTask = task.copyWith(isCompleted: isCompleted);
      _tasks[index] = updatedTask;
      _updateAllStreams();
    } else {
      throw Exception('Task not found');
    }
  }

  // Get task by ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      return _tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }

  // Additional helper methods for testing
  List<Task> get allTasks => List.unmodifiable(_tasks);

  void clearAllTasks() {
    _tasks.clear();
    _updateAllStreams();
  }

  void setTasksForTesting(List<Task> tasks) {
    _tasks.clear();
    _tasks.addAll(tasks);
    _updateAllStreams();
  }

  // Get completed tasks (helper for testing)
  List<Task> getCompletedTasks() {
    return _tasks.where((task) => task.isCompleted).toList();
  }

  // Get tasks by priority (helper for testing)
  List<Task> getTasksByPriority(String priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }

  // Get overdue tasks (helper for testing)
  List<Task> getOverdueTasks() {
    final now = DateTime.now();
    return _tasks.where((task) => 
      !task.isCompleted && 
      task.dueDate != null && 
      task.dueDate!.isBefore(now)
    ).toList();
  }

  // Get today's tasks (helper for testing)
  List<Task> getTodaysTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return _tasks.where((task) => 
      task.dueDate != null &&
      task.dueDate!.isAfter(today) &&
      task.dueDate!.isBefore(tomorrow)
    ).toList();
  }

  // Search tasks (helper for testing)
  List<Task> searchTasks(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _tasks.where((task) {
      final titleMatch = task.title.toLowerCase().contains(lowercaseQuery);
      final descriptionMatch = task.description?.toLowerCase().contains(lowercaseQuery) ?? false;
      return titleMatch || descriptionMatch;
    }).toList();
  }

  void dispose() {
    _tasksController.close();
    _incompleteTasksController.close();
    for (final controller in _categoryControllers.values) {
      controller.close();
    }
    _categoryControllers.clear();
  }
}