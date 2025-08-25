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

  // Get all tasks
  Stream<List<Task>> getTasks() {
    return _tasksCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Get tasks by category
  Stream<List<Task>> getTasksByCategory(String category) {
    return _tasksCollection
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Get incomplete tasks
  Stream<List<Task>> getIncompleteTasks() {
    return _tasksCollection
        .where('isCompleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Get tasks with active reminders
  Stream<List<Task>> getTasksWithReminders() {
    return _tasksCollection
        .where('hasReminder', isEqualTo: true)
        .where('isReminderActive', isEqualTo: true)
        .where('isCompleted', isEqualTo: false)
        .orderBy('reminderTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Update task with notification management
  Future<void> updateTask(Task task) async {
    if (task.id == null) throw Exception('Task ID cannot be null');
    
    try {
      // Get the original task to compare reminder settings
      Task? originalTask = await getTaskById(task.id!);
      
      // Update task in Firestore
      await _tasksCollection.doc(task.id).update(task.toMap());
      
      // FIXED: Handle notification updates
      if (originalTask != null) {
        // If reminder was removed or deactivated, cancel notification
        if ((originalTask.hasReminder && !task.hasReminder) ||
            (originalTask.isReminderActive && !task.isReminderActive)) {
          final notificationId = _getNotificationId(task.id!);
          await _notificationService.cancelNotification(notificationId);
        }
        
        // If reminder was added or changed, schedule new notification
        if (task.hasActiveReminder && task.reminderTime != null) {
          await _notificationService.scheduleTaskReminder(task);
        }
      }
      
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // FIXED: Delete task with notification cleanup
  Future<void> deleteTask(String taskId) async {
    try {
      // FIXED: Cancel any associated notifications using task ID hash
      final notificationId = _getNotificationId(taskId);
      await _notificationService.cancelNotification(notificationId);
      
      // Delete task from Firestore
      await _tasksCollection.doc(taskId).delete();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // FIXED: Toggle task completion with notification management
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      await _tasksCollection.doc(taskId).update({
        'isCompleted': isCompleted,
        'completedAt': isCompleted ? DateTime.now().millisecondsSinceEpoch : null,
      });
      
      // FIXED: Cancel notification if task is completed
      if (isCompleted) {
        final notificationId = _getNotificationId(taskId);
        await _notificationService.cancelNotification(notificationId);
      } else {
        // If uncompleted, reschedule notification if it has reminder
        Task? task = await getTaskById(taskId);
        if (task != null && task.hasActiveReminder) {
          await _notificationService.scheduleTaskReminder(task);
        }
      }
      
    } catch (e) {
      throw Exception('Failed to toggle task completion: $e');
    }
  }

  // Get task by ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      DocumentSnapshot doc = await _tasksCollection.doc(taskId).get();
      if (doc.exists) {
        return Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  // Schedule reminder for existing task
  Future<void> scheduleReminder(String taskId, DateTime reminderTime, 
      {String reminderType = 'once', 
       List<String> repeatDays = const [],
       String notificationTone = 'default'}) async {
    try {
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
      Task? task = await getTaskById(taskId);
      if (task != null) {
        await _notificationService.scheduleTaskReminder(task);
      }
      
    } catch (e) {
      throw Exception('Failed to schedule reminder: $e');
    }
  }

  // FIXED: Cancel reminder for task
  Future<void> cancelReminder(String taskId) async {
    try {
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
  Future<void> rescheduleAllReminders() async {
    try {
      final snapshot = await _tasksCollection
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
  Future<List<Task>> getUpcomingReminders() async {
    try {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      
      final snapshot = await _tasksCollection
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

  // Update reminder tone for task
  Future<void> updateReminderTone(String taskId, String tone) async {
    try {
      await _tasksCollection.doc(taskId).update({
        'notificationTone': tone,
      });
      
      // Reschedule notification with new tone
      Task? task = await getTaskById(taskId);
      if (task != null && task.hasActiveReminder) {
        await _notificationService.scheduleTaskReminder(task);
      }
      
    } catch (e) {
      throw Exception('Failed to update reminder tone: $e');
    }
  }

  // Snooze reminder (postpone by specified minutes)
  Future<void> snoozeReminder(String taskId, int minutes) async {
    try {
      Task? task = await getTaskById(taskId);
      if (task == null || !task.hasActiveReminder) return;
      
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
}