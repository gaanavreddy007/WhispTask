import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
import 'notification_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Get current user's tasks collection reference
  CollectionReference get _tasksCollection {
    final userId = _auth.currentUser?.uid ?? 'anonymous';
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  // FIXED: Helper method to get notification ID from task ID
  int _getNotificationId(String taskId) {
    return taskId.hashCode;
  }

  // Create new task with notification scheduling
  Future<String> createTask(Task task) async {
    try {
      // Validate task data
      if (task.title.trim().isEmpty) {
        throw Exception('Task title cannot be empty');
      }
      
      if (task.title.length > 100) {
        throw Exception('Task title too long (max 100 characters)');
      }
      
      if (task.description != null && task.description!.length > 500) {
        throw Exception('Task description too long (max 500 characters)');
      }
      
      // Create task in Firestore WITHOUT the notification scheduling first
      DocumentReference docRef = await _tasksCollection.add(task.toMap());
      
      // NOW schedule notification if reminder is set, using the generated ID
      if (task.hasReminder && task.reminderTime != null) {
        // Create a new task object with the generated ID
        final taskWithId = task.copyWith(
          id: docRef.id,
          notificationId: _getNotificationId(docRef.id).toString(),
        );
        
        // Update the document with the notification ID
        await docRef.update({'notificationId': _getNotificationId(docRef.id).toString()});
        
        // Schedule the reminder using the task with ID
        await _notificationService.scheduleTaskReminder(taskWithId);
      }
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  // Get all tasks for a specific user
  Future<List<Task>> getUserTasks(String userId) async {
    try {
      final QuerySnapshot snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  // Get completed tasks for a specific user
  Future<List<Task>> getUserCompletedTasks(String userId) async {
    try {
      final QuerySnapshot snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to load completed tasks: $e');
    }
  }

  // Get pending tasks for a specific user
  Future<List<Task>> getUserPendingTasks(String userId) async {
    try {
      final QuerySnapshot snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to load pending tasks: $e');
    }
  }

  // Get tasks due today for a specific user
  Future<List<Task>> getUserTasksDueToday(String userId) async {
    try {
      final DateTime now = DateTime.now();
      final DateTime startOfDay = DateTime(now.year, now.month, now.day);
      final DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final QuerySnapshot snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('isCompleted', isEqualTo: false)
          .orderBy('dueDate')
          .get();

      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to load tasks due today: $e');
    }
  }

  // Get overdue tasks for a specific user
  Future<List<Task>> getUserOverdueTasks(String userId) async {
    try {
      final DateTime now = DateTime.now();
      final DateTime startOfToday = DateTime(now.year, now.month, now.day);

      final QuerySnapshot snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .where('dueDate', isLessThan: Timestamp.fromDate(startOfToday))
          .where('isCompleted', isEqualTo: false)
          .orderBy('dueDate')
          .get();

      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to load overdue tasks: $e');
    }
  }

  // Get tasks by priority for a specific user
  Future<List<Task>> getUserTasksByPriority(String userId, String priority) async {
    try {
      final QuerySnapshot snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .where('priority', isEqualTo: priority)
          .where('isCompleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to load tasks by priority: $e');
    }
  }

  // Get tasks by category for a specific user
  Future<List<Task>> getUserTasksByCategory(String userId, String category) async {
    try {
      final QuerySnapshot snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to load tasks by category: $e');
    }
  }

  // Add a new task for a specific user
  Future<bool> addTask(Task task, String userId) async {
    try {
      // Ensure task has userId
      final taskWithUser = task.copyWith(userId: userId);
      
      await _tasksCollection.add(taskWithUser.toMap());
      
      // Update user task count
      await _updateUserTaskCount(userId);
      
      return true;
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  // Update an existing task for a specific user
  Future<bool> updateTask(Task task, String userId) async {
    try {
      if (task.id == null || task.id!.isEmpty) {
        throw Exception('Task ID is required for updates');
      }

      // Verify task belongs to user
      final doc = await _tasksCollection.doc(task.id).get();
      if (!doc.exists) {
        throw Exception('Task not found');
      }
      
      final existingTask = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (existingTask.userId != userId) {
        throw Exception('Unauthorized: Task does not belong to user');
      }

      // Ensure userId is maintained
      final taskWithUser = task.copyWith(userId: userId);
      
      await _tasksCollection.doc(task.id).update(taskWithUser.toMap());
      
      // Update user task count if completion status changed
      if (task.isCompleted != existingTask.isCompleted) {
        await _updateUserTaskCount(userId);
      }
      
      return true;
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Delete a task for a specific user
  Future<bool> deleteTask(String taskId, String userId) async {
    try {
      // Verify task belongs to user
      final doc = await _tasksCollection.doc(taskId).get();
      if (!doc.exists) {
        throw Exception('Task not found');
      }
      
      final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (task.userId != userId) {
        throw Exception('Unauthorized: Task does not belong to user');
      }

      await _tasksCollection.doc(taskId).delete();
      
      // Update user task count
      await _updateUserTaskCount(userId);
      
      return true;
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // Toggle task completion status
  Future<bool> toggleTaskCompletion(String taskId, String userId) async {
    try {
      final doc = await _tasksCollection.doc(taskId).get();
      if (!doc.exists) {
        throw Exception('Task not found');
      }
      
      final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (task.userId != userId) {
        throw Exception('Unauthorized: Task does not belong to user');
      }

      final updatedTask = task.copyWith(
        isCompleted: !task.isCompleted,
        completedAt: !task.isCompleted ? DateTime.now() : null,
      );
      
      await _tasksCollection.doc(taskId).update(updatedTask.toMap());
      
      // Update user task count
      await _updateUserTaskCount(userId);
      
      return true;
    } catch (e) {
      throw Exception('Failed to toggle task completion: $e');
    }
  }

  // Get task statistics for a user
  Future<Map<String, int>> getUserTaskStats(String userId) async {
    try {
      final QuerySnapshot allTasks = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .get();

      final QuerySnapshot completedTasks = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .get();

      final QuerySnapshot pendingTasks = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: false)
          .get();

      // Get overdue tasks
      final DateTime now = DateTime.now();
      final DateTime startOfToday = DateTime(now.year, now.month, now.day);
      
      final QuerySnapshot overdueTasks = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .where('dueDate', isLessThan: Timestamp.fromDate(startOfToday))
          .where('isCompleted', isEqualTo: false)
          .get();

      return {
        'total': allTasks.docs.length,
        'completed': completedTasks.docs.length,
        'pending': pendingTasks.docs.length,
        'overdue': overdueTasks.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get task stats: $e');
    }
  }

  // Stream of user tasks (real-time updates)
  Stream<List<Task>> getUserTasksStream(String userId) {
    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Stream of pending user tasks (real-time updates)
  Stream<List<Task>> getUserPendingTasksStream(String userId) {
    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Bulk delete all tasks for a user (used when deleting account)
  Future<bool> deleteAllUserTasks(String userId) async {
    try {
      final QuerySnapshot snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .get();

      // Delete in batches to avoid hitting Firestore limits
      final WriteBatch batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Update user task counts
      await _updateUserTaskCount(userId);
      
      return true;
    } catch (e) {
      throw Exception('Failed to delete all user tasks: $e');
    }
  }

  // Search tasks by title or description for a user
  Future<List<Task>> searchUserTasks(String userId, String query) async {
    try {
      final QuerySnapshot snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .get();

      final List<Task> allTasks = snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Filter tasks by search query (case-insensitive)
      final String lowerQuery = query.toLowerCase();
      return allTasks.where((task) {
        return task.title.toLowerCase().contains(lowerQuery) ||
               (task.description?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search tasks: $e');
    }
  }

  // Get tasks with reminders for a user
  Future<List<Task>> getUserTasksWithReminders(String userId) async {
    try {
      final QuerySnapshot snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .where('hasReminder', isEqualTo: true)
          .where('isCompleted', isEqualTo: false)
          .orderBy('reminderTime')
          .get();

      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to load tasks with reminders: $e');
    }
  }

  // Update user task count in users collection
  Future<void> _updateUserTaskCount(String userId) async {
    try {
      final stats = await getUserTaskStats(userId);
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'taskCount': stats['total'],
        'completedTaskCount': stats['completed'],
      });
    } catch (e) {
      throw Exception('Failed to update user task count: $e');
    }
  }

  // Get task by ID for a specific user
  Future<Task?> getUserTask(String taskId, String userId) async {
    try {
      final doc = await _tasksCollection.doc(taskId).get();
      
      if (!doc.exists) {
        return null;
      }
      
      final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      
      // Verify task belongs to user
      if (task.userId != userId) {
        throw Exception('Unauthorized: Task does not belong to user');
      }
      
      return task;
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  // Batch update multiple tasks
  Future<bool> batchUpdateTasks(List<Task> tasks, String userId) async {
    try {
      final WriteBatch batch = _firestore.batch();
      
      for (final task in tasks) {
        if (task.id == null || task.id!.isEmpty) {
          continue; // Skip tasks without IDs
        }
        
        // Verify task belongs to user
        final doc = await _tasksCollection.doc(task.id).get();
        if (!doc.exists) continue;
        
        final existingTask = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        if (existingTask.userId != userId) continue;
        
        // Ensure userId is maintained
        final taskWithUser = task.copyWith(userId: userId);
        batch.update(doc.reference, taskWithUser.toMap());
      }
      
      await batch.commit();
      
      // Update user task count
      await _updateUserTaskCount(userId);
      
      return true;
    } catch (e) {
      throw Exception('Failed to batch update tasks: $e');
    }
  }

  // Get tasks created in a date range for a user
  Future<List<Task>> getUserTasksByDateRange(
    String userId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final QuerySnapshot snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to load tasks by date range: $e');
    }
  }

  // Get user's task categories
  Future<List<String>> getUserTaskCategories(String userId) async {
    try {
      final QuerySnapshot snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .get();

      final Set<String> categories = {};
      
      for (final doc in snapshot.docs) {
        final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        if (task.category.isNotEmpty) {
          categories.add(task.category);
        }
      }
      
      return categories.toList()..sort();
    } catch (e) {
      throw Exception('Failed to get user task categories: $e');
    }
  }

  // Check if user has any tasks
  Future<bool> userHasTasks(String userId) async {
    try {
      final QuerySnapshot snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if user has tasks: $e');
    }
  }

  // Update reminder tone for task
  Future<void> updateReminderTone(String taskId, String tone, String userId) async {
    try {
      // Verify task belongs to user
      final doc = await _tasksCollection.doc(taskId).get();
      if (!doc.exists) {
        throw Exception('Task not found');
      }
      
      final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (task.userId != userId) {
        throw Exception('Unauthorized: Task does not belong to user');
      }

      await _tasksCollection.doc(taskId).update({
        'notificationTone': tone,
      });
      
      // Reschedule notification with new tone
      if (task.hasActiveReminder) {
        await _notificationService.scheduleTaskReminder(task);
      }
      
    } catch (e) {
      throw Exception('Failed to update reminder tone: $e');
    }
  }

  // Snooze reminder (postpone by specified minutes)
  Future<void> snoozeReminder(String taskId, int minutes, String userId) async {
    try {
      // Verify task belongs to user
      final doc = await _tasksCollection.doc(taskId).get();
      if (!doc.exists) {
        throw Exception('Task not found');
      }
      
      final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (task.userId != userId) {
        throw Exception('Unauthorized: Task does not belong to user');
      }

      if (!task.hasActiveReminder) return;
      
      final newReminderTime = DateTime.now().add(Duration(minutes: minutes));
      
      await _tasksCollection.doc(taskId).update({
        'reminderTime': newReminderTime.millisecondsSinceEpoch,
      });
      
      // Reschedule notification
      final updatedTask = task.copyWith(reminderTime: newReminderTime);
      await _notificationService.scheduleTaskReminder(updatedTask);
      
    } catch (e) {
      throw Exception('Failed to snooze reminder: $e');
    }
  }

  // Schedule reminder for existing task
  Future<void> scheduleReminder(String taskId, DateTime reminderTime, String userId, 
      {String reminderType = 'once', 
       List<String> repeatDays = const [],
       String notificationTone = 'default'}) async {
    try {
      // Verify task belongs to user
      final doc = await _tasksCollection.doc(taskId).get();
      if (!doc.exists) {
        throw Exception('Task not found');
      }
      
      final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (task.userId != userId) {
        throw Exception('Unauthorized: Task does not belong to user');
      }

      final updateData = {
        'hasReminder': true,
        'reminderTime': reminderTime.millisecondsSinceEpoch,
        'reminderType': reminderType,
        'repeatDays': repeatDays,
        'notificationTone': notificationTone,
        'isReminderActive': true,
        'notificationId': _getNotificationId(taskId).toString(), // Store as string
      };
      
      await _tasksCollection.doc(taskId).update(updateData);
      
      // Schedule the notification
      final updatedTask = task.copyWith(
        hasReminder: true,
        reminderTime: reminderTime,
        reminderType: reminderType,
        repeatDays: repeatDays,
        notificationTone: notificationTone,
        isReminderActive: true,
        notificationId: _getNotificationId(taskId).toString(),
      );
      await _notificationService.scheduleTaskReminder(updatedTask);
      
    } catch (e) {
      throw Exception('Failed to schedule reminder: $e');
    }
  }

  // Cancel reminder for task
  Future<void> cancelReminder(String taskId, String userId) async {
    try {
      // Verify task belongs to user
      final doc = await _tasksCollection.doc(taskId).get();
      if (!doc.exists) {
        throw Exception('Task not found');
      }
      
      final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (task.userId != userId) {
        throw Exception('Unauthorized: Task does not belong to user');
      }

      await _tasksCollection.doc(taskId).update({
        'hasReminder': false,
        'isReminderActive': false,
      });
      
      final notificationId = _getNotificationId(taskId);
      await _notificationService.cancelNotification(notificationId);
    } catch (e) {
      throw Exception('Failed to cancel reminder: $e');
    }
  }

  // Reschedule all active reminders (useful for app startup)
  Future<void> rescheduleAllReminders(String userId) async {
    try {
      final snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .where('hasReminder', isEqualTo: true)
          .where('isReminderActive', isEqualTo: true)
          .where('isCompleted', isEqualTo: false)
          .get();
      
      for (var doc in snapshot.docs) {
        final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        if (task.reminderTime != null && task.reminderTime!.isAfter(DateTime.now())) {
          await _notificationService.scheduleTaskReminder(task);
        }
      }
      
    } catch (e) {
      throw Exception('Failed to reschedule reminders: $e');
    }
  }

  // Get upcoming reminders (next 24 hours)
  Future<List<Task>> getUpcomingReminders(String userId) async {
    try {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      
      final snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .where('hasReminder', isEqualTo: true)
          .where('isReminderActive', isEqualTo: true)
          .where('isCompleted', isEqualTo: false)
          .where('reminderTime', isGreaterThan: now.millisecondsSinceEpoch)
          .where('reminderTime', isLessThan: tomorrow.millisecondsSinceEpoch)
          .orderBy('reminderTime')
          .get();
      
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
          
    } catch (e) {
      throw Exception('Failed to get upcoming reminders: $e');
    }
  }

  // Migrate user tasks (placeholder for account migration)
  Future<bool> migrateUserTasks(String fromUserId, String toUserId) async {
    try {
      final QuerySnapshot snapshot = await _tasksCollection
          .where('userId', isEqualTo: fromUserId)
          .get();

      final WriteBatch batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        final taskData = doc.data() as Map<String, dynamic>;
        taskData['userId'] = toUserId;
        batch.update(doc.reference, taskData);
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('Failed to migrate user tasks: $e');
    }
  }
}