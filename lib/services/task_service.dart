// ignore_for_file: unused_field, unused_local_variable, unnecessary_null_comparison, unnecessary_cast, avoid_print, prefer_const_constructors, avoid_types_as_parameter_names

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../models/task.dart';
import '../services/notification_service.dart';
import '../services/sentry_service.dart';
import '../utils/notification_helper.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // FIXED: Get tasks collection for specific user (removes current user dependency)
  CollectionReference _getTasksCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  // FIXED: Helper method to get notification ID from task ID (ensures positive integer)
  int _getNotificationId(String taskId) {
    return taskId.hashCode.abs();
  }

  // ENHANCED: Create new task with comprehensive validation and error handling
  Future<String> createTask(Task task, String userId) async {
    final result = await SentryService.wrapWithComprehensiveTracking(
      () async {
        SentryService.logTaskOperation('create_task_start', data: {
          'user_id': userId,
          'task_title': task.title,
          'task_priority': task.priority.toString(),
          'has_reminder': task.hasReminder.toString(),
          'is_recurring': task.isRecurring.toString(),
        });

        // Enhanced validation using NotificationHelper
        if (task.title.trim().isEmpty) {
          SentryService.logTaskOperation('create_task_validation_failed', data: {'reason': 'empty_title'});
          throw Exception('Task title cannot be empty');
        }
        
        if (task.title.length > 100) {
          SentryService.logTaskOperation('create_task_validation_failed', data: {'reason': 'title_too_long'});
          throw Exception('Task title too long (max 100 characters)');
        }
        
        if (task.description != null && task.description!.length > 500) {
          SentryService.logTaskOperation('create_task_validation_failed', data: {'reason': 'description_too_long'});
          throw Exception('Task description too long (max 500 characters)');
        }

        // CRITICAL: Validate and normalize priority
        final validPriorities = ['high', 'medium', 'low'];
        if (!validPriorities.contains(task.priority.toLowerCase())) {
          SentryService.logTaskOperation('create_task_validation_failed', data: {
            'reason': 'invalid_priority',
            'provided_priority': task.priority,
            'valid_priorities': validPriorities.join(', ')
          });
          // Auto-fix invalid priority to medium
          task.priority = 'medium';
        } else {
          // Normalize priority to lowercase
          task.priority = task.priority.toLowerCase();
        }

        // CRITICAL: Validate category
        final validCategories = ['general', 'work', 'personal', 'shopping', 'health', 'study', 'finance'];
        if (!validCategories.contains(task.category.toLowerCase())) {
          SentryService.logTaskOperation('create_task_validation_failed', data: {
            'reason': 'invalid_category',
            'provided_category': task.category,
            'valid_categories': validCategories.join(', ')
          });
          // Auto-fix invalid category to general
          task.category = 'general';
        } else {
          // Normalize category to lowercase
          task.category = task.category.toLowerCase();
        }

      // CRITICAL: Validate reminder settings
      if (task.hasReminder) {
        // Ensure reminder time is set if hasReminder is true
        if (task.reminderTime == null) {
          SentryService.logTaskOperation('reminder_validation_failed', data: {'reason': 'missing_reminder_time'});
          // Auto-fix: set reminder time to due date or 1 hour from now
          task.reminderTime = task.dueDate ?? DateTime.now().add(Duration(hours: 1));
        }
        
        // Validate reminder time
        final validation = NotificationHelper.validateReminderTime(task.reminderTime!);
        if (validation != null) {
          SentryService.logTaskOperation('reminder_validation_failed', data: {'reason': validation});
          throw Exception(validation);
        }

        // Validate reminder type
        final validReminderTypes = ['once', 'daily', 'weekly', 'monthly'];
        if (!validReminderTypes.contains(task.reminderType.toLowerCase())) {
          SentryService.logTaskOperation('reminder_validation_failed', data: {
            'reason': 'invalid_reminder_type',
            'provided_type': task.reminderType
          });
          // Auto-fix invalid reminder type
          task.reminderType = 'once';
        }

        // Validate repeat days for weekly reminders
        final daysValidation = NotificationHelper.validateRepeatDays(
          task.reminderType, 
          task.repeatDays
        );
        if (daysValidation != null) {
          SentryService.logTaskOperation('reminder_validation_failed', data: {'reason': daysValidation});
          throw Exception(daysValidation);
        }

        // Ensure notification ID is set
        task.notificationId ??= _getNotificationId(task.id ?? DateTime.now().millisecondsSinceEpoch.toString());

        // Ensure isReminderActive is properly set
        task.isReminderActive = true;
      } else {
        // If hasReminder is false, clear all reminder fields
        task.reminderTime = null;
        task.isReminderActive = false;
        task.notificationId = null;
      }

      // ENHANCED: Validate and normalize recurring task parameters
      Task validatedTask = task;
      if (task.isRecurring) {
        SentryService.logTaskOperation('validate_recurring_task', data: {
          'pattern': task.recurringPattern,
          'interval': task.recurringInterval?.toString(),
        });
        
        if (task.recurringPattern == null || task.recurringPattern!.isEmpty) {
          SentryService.logTaskOperation('recurring_validation_failed', data: {'reason': 'missing_pattern'});
          throw Exception('Recurring tasks must have a pattern (daily, weekly, monthly, or yearly)');
        }
        
        if (task.recurringInterval == null || task.recurringInterval! <= 0) {
          SentryService.logTaskOperation('recurring_validation_failed', data: {'reason': 'invalid_interval'});
          throw Exception('Recurring interval must be a positive number (e.g., every 1 day, every 2 weeks)');
        }
        
        final validPatterns = ['daily', 'weekly', 'monthly', 'yearly'];
        if (!validPatterns.contains(task.recurringPattern!.toLowerCase())) {
          SentryService.logTaskOperation('recurring_validation_failed', data: {
            'reason': 'invalid_pattern',
            'provided_pattern': task.recurringPattern,
            'valid_patterns': validPatterns.join(', ')
          });
          throw Exception('Invalid recurring pattern: ${task.recurringPattern}. Must be one of: ${validPatterns.join(', ')}');
        }
        
        // Normalize the pattern to lowercase for consistency
        validatedTask = task.copyWith(
          recurringPattern: task.recurringPattern!.toLowerCase(),
        );
        
        SentryService.logTaskOperation('recurring_validation_success', data: {
          'pattern': validatedTask.recurringPattern,
          'interval': validatedTask.recurringInterval?.toString(),
        });
      }
      
      // Ensure task has userId and proper timestamps
      final taskWithUser = validatedTask.copyWith(
        userId: userId,
        createdAt: validatedTask.createdAt,
      );
      
      // Create task in Firestore
      DocumentReference docRef = await _getTasksCollection(userId).add(taskWithUser.toMap());
      
      // Schedule notification if reminder is set
      if (taskWithUser.hasReminder && taskWithUser.reminderTime != null) {
        final taskWithId = taskWithUser.copyWith(id: docRef.id);
        await _notificationService.scheduleTaskReminder(taskWithId);
      }
      
        // Update user task count
        await _updateUserTaskCount(userId);
        
        SentryService.logTaskOperation('create_task_complete', taskId: docRef.id, data: {
          'user_id': userId,
          'task_title': task.title,
        });
        
        return docRef.id;
      },
      operationName: 'create_task',
      description: 'Create new task with validation and notifications',
      category: 'task',
      extra: {
        'user_id': userId,
        'task_title': task.title,
        'has_reminder': task.hasReminder.toString(),
      },
    ).catchError((e) {
      SentryService.logTaskOperation('create_task_failed', data: {
        'user_id': userId,
        'error': e.toString(),
      });
      
      if (e is FirebaseException) {
        throw Exception('Database error: ${e.message}');
      }
      throw e;
    });
    
    return result ?? '';
  }

  // ENHANCED: Get tasks with advanced filtering and better error handling
  Future<List<Task>> getUserTasks(
    String userId, {
    String? priority,
    String? category,
    bool? isCompleted,
    DateTime? dueBefore,
    DateTime? dueAfter,
    bool? hasReminder,
    String? searchQuery,
    String orderBy = 'createdAt',
    bool descending = true,
    int? limit,
  }) async {
    try {
      Query query = _getTasksCollection(userId);

      // FIXED: Better handling of compound queries
      List<String> appliedFilters = [];
      
      if (isCompleted != null) {
        query = query.where('isCompleted', isEqualTo: isCompleted);
        appliedFilters.add('isCompleted');
      }
      
      if (hasReminder != null && !appliedFilters.contains('isCompleted')) {
        query = query.where('hasReminder', isEqualTo: hasReminder);
        appliedFilters.add('hasReminder');
      }
      
      if (priority != null && appliedFilters.isEmpty) {
        query = query.where('priority', isEqualTo: priority);
        appliedFilters.add('priority');
      }
      
      if (category != null && appliedFilters.isEmpty) {
        query = query.where('category', isEqualTo: category);
        appliedFilters.add('category');
      }
      
      // Apply date filters (only if no other filters are applied)
      if (dueBefore != null && appliedFilters.isEmpty) {
        query = query.where('dueDate', isLessThan: Timestamp.fromDate(dueBefore));
        appliedFilters.add('dueDate');
      } else if (dueAfter != null && appliedFilters.isEmpty) {
        query = query.where('dueDate', isGreaterThan: Timestamp.fromDate(dueAfter));
        appliedFilters.add('dueDate');
      }

      // Apply ordering with fallback
      try {
        // Check if we can order by the requested field
        if (appliedFilters.isEmpty || !appliedFilters.contains(orderBy)) {
          query = query.orderBy(orderBy, descending: descending);
        } else {
          // Use createdAt as fallback if orderBy field conflicts
          query = query.orderBy('createdAt', descending: descending);
        }
      } catch (e) {
        // Final fallback to createdAt
        query = query.orderBy('createdAt', descending: true);
      }

      // Apply limit if specified
      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }

      final QuerySnapshot snapshot = await query.get();
      List<Task> tasks = snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Apply client-side filters for complex filtering that Firestore can't handle
      tasks = _applyClientSideFilters(tasks, priority, category, hasReminder, 
                                     dueBefore, dueAfter, searchQuery, appliedFilters);

      return tasks;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('service', 'task');
          scope.setTag('operation', 'get_user_tasks');
          scope.setExtra('user_id', userId);
          scope.setExtra('filters_applied', 'user_tasks_query');
          scope.level = SentryLevel.error;
        },
      );
      if (e is FirebaseException) {
        throw Exception('Failed to load tasks: ${e.message}');
      }
      throw Exception('Failed to load tasks: $e');
    }
  }

  // FIXED: Helper method for client-side filtering
  List<Task> _applyClientSideFilters(
    List<Task> tasks,
    String? priority,
    String? category, 
    bool? hasReminder,
    DateTime? dueBefore,
    DateTime? dueAfter,
    String? searchQuery,
    List<String> appliedFilters,
  ) {
    List<Task> filteredTasks = tasks;

    // Apply filters that weren't applied server-side
    if (priority != null && !appliedFilters.contains('priority')) {
      filteredTasks = filteredTasks.where((task) => task.priority == priority).toList();
    }
    
    if (category != null && !appliedFilters.contains('category')) {
      filteredTasks = filteredTasks.where((task) => task.category == category).toList();
    }
    
    if (hasReminder != null && !appliedFilters.contains('hasReminder')) {
      filteredTasks = filteredTasks.where((task) => task.hasReminder == hasReminder).toList();
    }

    // Apply date filters if not applied server-side
    if (dueBefore != null && !appliedFilters.contains('dueDate')) {
      filteredTasks = filteredTasks.where((task) => 
        task.dueDate != null && task.dueDate!.isBefore(dueBefore)
      ).toList();
    }
    
    if (dueAfter != null && !appliedFilters.contains('dueDate')) {
      filteredTasks = filteredTasks.where((task) => 
        task.dueDate != null && task.dueDate!.isAfter(dueAfter)
      ).toList();
    }

    // Apply search filter
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final String lowerQuery = searchQuery.toLowerCase().trim();
      filteredTasks = filteredTasks.where((task) {
        return task.title.toLowerCase().contains(lowerQuery) ||
               (task.description?.toLowerCase().contains(lowerQuery) ?? false) ||
               task.category.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    return filteredTasks;
  }

  // Get all tasks for a specific user (backward compatibility)
  Future<List<Task>> getAllUserTasks(String userId) async {
    return getUserTasks(userId);
  }

  // Get completed tasks for a specific user
  Future<List<Task>> getUserCompletedTasks(String userId) async {
    return getUserTasks(userId, isCompleted: true);
  }

  // Get pending tasks for a specific user
  Future<List<Task>> getUserPendingTasks(String userId) async {
    return getUserTasks(userId, isCompleted: false);
  }

  // FIXED: Get tasks due today with proper timezone handling
  Future<List<Task>> getUserTasksDueToday(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    
    return getUserTasks(
      userId,
      isCompleted: false,
      dueAfter: startOfDay,
      dueBefore: endOfDay,
      orderBy: 'dueDate',
    );
  }

  // FIXED: Get overdue tasks with proper date comparison
  Future<List<Task>> getUserOverdueTasks(String userId) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    
    return getUserTasks(
      userId,
      isCompleted: false,
      dueBefore: startOfToday,
      orderBy: 'dueDate',
      descending: false, // Oldest overdue tasks first
    );
  }

  // Get tasks by priority for a specific user
  Future<List<Task>> getUserTasksByPriority(String userId, String priority) async {
    return getUserTasks(userId, priority: priority, isCompleted: false);
  }

  // Get tasks by category for a specific user
  Future<List<Task>> getUserTasksByCategory(String userId, String category) async {
    return getUserTasks(userId, category: category);
  }

  // ENHANCED: Add task with proper user ID handling
  Future<bool> addTask(Task task, String userId) async {
    try {
      await createTask(task, userId);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // ENHANCED: Update task with comprehensive reminder and recurring task handling
  Future<bool> updateTask(Task updatedTask, String userId) async {
    try {
      if (updatedTask.id == null || updatedTask.id!.isEmpty) {
        throw Exception('Task ID is required for updates');
      }

      // Verify task belongs to user and get existing task
      final doc = await _getTasksCollection(userId).doc(updatedTask.id).get();
      if (!doc.exists) {
        throw Exception('Task not found');
      }
      
      final existingTask = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (existingTask.userId != userId) {
        throw Exception('Unauthorized: Task does not belong to user');
      }

      // FIXED: Validate updated task data
      if (updatedTask.title.trim().isEmpty) {
        throw Exception('Task title cannot be empty');
      }

      if (updatedTask.isRecurring) {
        if (updatedTask.recurringPattern == null || updatedTask.recurringInterval == null) {
          throw Exception('Recurring tasks must have pattern and interval');
        }
      }

      // Handle reminder changes
      await _handleReminderUpdates(existingTask, updatedTask, userId);
      
      // Handle completion status changes
      final wasCompleted = existingTask.isCompleted;
      final nowCompleted = updatedTask.isCompleted;
      
      if (!wasCompleted && nowCompleted) {
        // Task just completed
        final taskWithCompletion = updatedTask.copyWith(
          userId: userId,
          completedAt: DateTime.now(),
        );
        
        await _getTasksCollection(userId).doc(updatedTask.id).update(taskWithCompletion.toMap());
        
        // Process recurring task if applicable
        if (taskWithCompletion.isRecurring) {
          await _processCompletedRecurringTask(taskWithCompletion, userId);
        }
      } else if (wasCompleted && !nowCompleted) {
        // Task marked as incomplete
        final taskWithUser = updatedTask.copyWith(
          userId: userId,
          completedAt: null,
        );
        await _getTasksCollection(userId).doc(updatedTask.id).update(taskWithUser.toMap());
      } else {
        // Regular update
        final taskWithUser = updatedTask.copyWith(userId: userId);
        await _getTasksCollection(userId).doc(updatedTask.id).update(taskWithUser.toMap());
      }
      
      // Update user task count if completion status changed
      if (wasCompleted != nowCompleted) {
        await _updateUserTaskCount(userId);
      }
      
      return true;
    } catch (e) {
      if (e is FirebaseException) {
        throw Exception('Database error: ${e.message}');
      }
      rethrow;
    }
  }

  // FIXED: Helper method to handle reminder updates
  Future<void> _handleReminderUpdates(Task existingTask, Task updatedTask, String userId) async {
    final hasReminderChanged = updatedTask.hasReminder != existingTask.hasReminder;
    final reminderTimeChanged = updatedTask.reminderTime != existingTask.reminderTime;
    final reminderTypeChanged = updatedTask.reminderType != existingTask.reminderType;
    final repeatDaysChanged = !_listsEqual(updatedTask.repeatDays, existingTask.repeatDays);
    
    if (hasReminderChanged || reminderTimeChanged || reminderTypeChanged || repeatDaysChanged) {
      // Cancel existing notification
      if (existingTask.hasReminder && existingTask.notificationId != null) {
        final oldNotificationId = existingTask.notificationId ?? _getNotificationId(updatedTask.id!);
        await _notificationService.cancelNotification(oldNotificationId);
      }
      
      // Schedule new notification if needed
      if (updatedTask.hasReminder && updatedTask.reminderTime != null) {
        // Validate new reminder
        final validation = NotificationHelper.validateReminderTime(updatedTask.reminderTime!);
        if (validation != null) {
          throw Exception(validation);
        }

        final notificationId = _getNotificationId(updatedTask.id!);
        final taskWithNotification = updatedTask.copyWith(
          userId: userId,
          notificationId: notificationId,
          isReminderActive: true,
        );
        
        await _notificationService.scheduleTaskReminder(taskWithNotification);
      }
    }
  }

  // FIXED: Helper to compare lists for equality
  bool _listsEqual<T>(List<T>? list1, List<T>? list2) {
    if (list1 == null && list2 == null) return true;
    if (list1 == null || list2 == null) return false;
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  // ENHANCED: Delete task with comprehensive cleanup
  Future<bool> deleteTask(String taskId, String userId) async {
    try {
      // Validate inputs
      if (taskId.isEmpty || userId.isEmpty) {
        throw Exception('Invalid task ID or user ID');
      }

      // Verify task belongs to user
      final doc = await _getTasksCollection(userId).doc(taskId).get();
      if (!doc.exists) {
        throw Exception('Task not found');
      }
      
      final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (task.userId != userId) {
        throw Exception('Unauthorized: Task does not belong to user');
      }

      // Cancel notification if exists
      if (task.hasReminder && task.notificationId != null) {
        final notificationId = task.notificationId ?? _getNotificationId(taskId);
        await _notificationService.cancelNotification(notificationId);
      }

      await _getTasksCollection(userId).doc(taskId).delete();
      
      // Update user task count
      await _updateUserTaskCount(userId);
      
      return true;
    } catch (e) {
      if (e is FirebaseException) {
        throw Exception('Database error: ${e.message}');
      }
      rethrow;
    }
  }

  // FIXED: Toggle task completion with better state management
  Future<bool> toggleTaskCompletion(String taskId, String userId) async {
    try {
      final result = await SentryService.wrapWithComprehensiveTracking(
        () async {
          SentryService.logTaskOperation('toggle_completion_start', taskId: taskId, data: {
            'user_id': userId,
          });

          final doc = await _getTasksCollection(userId).doc(taskId).get();
          if (!doc.exists) {
            SentryService.logTaskOperation('toggle_completion_task_not_found', taskId: taskId);
            throw Exception('Task not found');
          }
          
          final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          if (task.userId != userId) {
            SentryService.logTaskOperation('toggle_completion_unauthorized', taskId: taskId, data: {
              'task_user_id': task.userId,
              'requesting_user_id': userId,
            });
            throw Exception('Unauthorized: Task does not belong to user');
          }

          final wasCompleted = task.isCompleted;
          final nowCompleted = !task.isCompleted;
          
          SentryService.logTaskOperation('toggle_completion_state_change', taskId: taskId, data: {
            'was_completed': wasCompleted.toString(),
            'now_completed': nowCompleted.toString(),
            'is_recurring': task.isRecurring.toString(),
          });
          
          final updatedTask = task.copyWith(
            isCompleted: nowCompleted,
            completedAt: nowCompleted ? DateTime.now() : null,
          );
          
          await _getTasksCollection(userId).doc(taskId).update(updatedTask.toMap());
          
          // Process recurring task if just completed (with error handling)
          if (nowCompleted && updatedTask.isRecurring) {
            try {
              await _processCompletedRecurringTask(updatedTask, userId);
              SentryService.logTaskOperation('recurring_task_processed_success', taskId: taskId);
            } catch (recurringError) {
              // Log but don't fail the main operation
              SentryService.logTaskOperation('recurring_task_processing_failed', taskId: taskId, data: {
                'error': recurringError.toString(),
              });
              print('Warning: Failed to process recurring task: $recurringError');
            }
          }
          
          // Handle reminder when task is completed (with error handling)
          if (nowCompleted && task.hasReminder && task.isReminderActive) {
            try {
              await _getTasksCollection(userId).doc(taskId).update({
                'isReminderActive': false
              });
              
              if (task.notificationId != null) {
                final notificationId = task.notificationId ?? _getNotificationId(taskId);
                await _notificationService.cancelNotification(notificationId);
              }
              SentryService.logTaskOperation('reminder_deactivated_success', taskId: taskId);
            } catch (reminderError) {
              // Log but don't fail the main operation
              SentryService.logTaskOperation('reminder_deactivation_failed', taskId: taskId, data: {
                'error': reminderError.toString(),
              });
              print('Warning: Failed to deactivate reminder: $reminderError');
            }
          }
          
          // Update user task count (with error handling)
          try {
            await _updateUserTaskCount(userId);
          } catch (countError) {
            // Log but don't fail the main operation
            SentryService.logTaskOperation('task_count_update_failed', taskId: taskId, data: {
              'error': countError.toString(),
            });
            print('Warning: Failed to update task count: $countError');
          }
          
          SentryService.logTaskOperation('toggle_completion_success', taskId: taskId, data: {
            'final_state': nowCompleted.toString(),
          });
          
          return true;
        },
        operationName: 'toggle_task_completion',
        description: 'Toggle task completion status with comprehensive error handling',
        category: 'task',
        extra: {
          'task_id': taskId,
          'user_id': userId,
        },
      );
      
      return result ?? false;
    } catch (e) {
      SentryService.logTaskOperation('toggle_completion_failed', taskId: taskId, data: {
        'error': e.toString(),
        'error_type': e.runtimeType.toString(),
      });
      
      if (e is FirebaseException) {
        throw Exception('Database error: ${e.message}');
      }
      rethrow;
    }
  }

  // ENHANCED: Get task statistics with comprehensive metrics
  Future<Map<String, int>> getUserTaskStats(String userId) async {
    try {
      final allTasks = await getUserTasks(userId);
      final completedTasks = allTasks.where((task) => task.isCompleted).toList();
      final pendingTasks = allTasks.where((task) => !task.isCompleted).toList();
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final overdueTasks = pendingTasks.where((task) => 
        task.dueDate != null && task.dueDate!.isBefore(today)
      ).toList();
      
      final todayTasks = pendingTasks.where((task) {
        if (task.dueDate == null) return false;
        return task.dueDate!.isAfter(today) && task.dueDate!.isBefore(endOfToday);
      }).toList();
      
      final withReminders = allTasks.where((task) => task.hasReminder).toList();
      final recurringTasks = allTasks.where((task) => task.isRecurring).toList();
      
      // FIXED: Calculate priority-based metrics more accurately
      final highPriorityTasks = pendingTasks.where((task) => task.priority == 'high').toList();
      final mediumPriorityTasks = pendingTasks.where((task) => task.priority == 'medium').toList();
      final lowPriorityTasks = pendingTasks.where((task) => task.priority == 'low').toList();

      return {
        'total': allTasks.length,
        'completed': completedTasks.length,
        'pending': pendingTasks.length,
        'overdue': overdueTasks.length,
        'dueToday': todayTasks.length,
        'withReminders': withReminders.length,
        'recurring': recurringTasks.length,
        'highPriority': highPriorityTasks.length,
        'mediumPriority': mediumPriorityTasks.length,
        'lowPriority': lowPriorityTasks.length,
      };
    } catch (e) {
      throw Exception('Failed to get task stats: $e');
    }
  }

  // FIXED: Stream of user tasks with error handling
  Stream<List<Task>> getUserTasksStream(String userId) {
    return _getTasksCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          throw Exception('Failed to stream tasks: $error');
        })
        .map((snapshot) => 
            snapshot.docs.map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // FIXED: Stream of pending user tasks with error handling
  Stream<List<Task>> getUserPendingTasksStream(String userId) {
    return _getTasksCollection(userId)
        .where('isCompleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          throw Exception('Failed to stream pending tasks: $error');
        })
        .map((snapshot) => 
            snapshot.docs.map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // ENHANCED: Bulk delete with better batch handling
  Future<bool> deleteAllUserTasks(String userId) async {
    try {
      const int batchSize = 500; // Firestore batch limit
      bool hasMoreTasks = true;
      
      while (hasMoreTasks) {
        final QuerySnapshot snapshot = await _getTasksCollection(userId)
            .limit(batchSize)
            .get();
        
        if (snapshot.docs.isEmpty) {
          hasMoreTasks = false;
          break;
        }

        // Cancel notifications for this batch
        for (final doc in snapshot.docs) {
          final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          if (task.hasReminder && task.notificationId != null) {
            final notificationId = task.notificationId ?? _getNotificationId(doc.id);
            await _notificationService.cancelNotification(notificationId);
          }
        }

        // Delete batch
        final WriteBatch batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        
        // Check if there are more tasks
        hasMoreTasks = snapshot.docs.length == batchSize;
      }
      
      // Update user task counts
      await _updateUserTaskCount(userId);
      
      return true;
    } catch (e) {
      if (e is FirebaseException) {
        throw Exception('Database error: ${e.message}');
      }
      rethrow;
    }
  }

  // Search tasks by title or description for a user
  Future<List<Task>> searchUserTasks(String userId, String query) async {
    return getUserTasks(userId, searchQuery: query);
  }

  // FIXED: Get tasks with reminders with proper filtering
  Future<List<Task>> getUserTasksWithReminders(String userId) async {
    return getUserTasks(
      userId, 
      hasReminder: true, 
      isCompleted: false,
      orderBy: 'reminderTime',
      descending: false, // Earliest reminders first
    );
  }

  // ENHANCED: Update user task count with retry logic
  Future<void> _updateUserTaskCount(String userId) async {
    try {
      final stats = await getUserTaskStats(userId);
      
      await _firestore.collection('users').doc(userId).update({
        'taskCount': stats['total'],
        'completedTaskCount': stats['completed'],
        'pendingTaskCount': stats['pending'],
        'overdueTaskCount': stats['overdue'],
        'highPriorityTaskCount': stats['highPriority'],
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Retry once after a short delay
      await Future.delayed(const Duration(seconds: 1));
      try {
        final stats = await getUserTaskStats(userId);
        await _firestore.collection('users').doc(userId).update({
          'taskCount': stats['total'],
          'completedTaskCount': stats['completed'],
          'pendingTaskCount': stats['pending'],
          'overdueTaskCount': stats['overdue'],
          'highPriorityTaskCount': stats['highPriority'],
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } catch (retryError) {
        // Log error but don't throw to avoid breaking main operations
        print('Failed to update user task count: $retryError');
      }
    }
  }

  // FIXED: Get task by ID with proper error handling
  Future<Task?> getUserTask(String taskId, String userId) async {
    try {
      final doc = await _getTasksCollection(userId).doc(taskId).get();
      
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
      if (e is FirebaseException) {
        throw Exception('Database error: ${e.message}');
      }
      rethrow;
    }
  }

  // ENHANCED: Batch update with transaction support
  Future<bool> batchUpdateTasks(List<Task> tasks, String userId) async {
    try {
      // Process in smaller batches to avoid Firestore limits
      const int batchSize = 100;
      
      for (int i = 0; i < tasks.length; i += batchSize) {
        final batchTasks = tasks.skip(i).take(batchSize).toList();
        await _processBatch(batchTasks, userId);
      }
      
      // Update user task count once after all batches
      await _updateUserTaskCount(userId);
      
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Helper for processing batch updates
  Future<void> _processBatch(List<Task> tasks, String userId) async {
    final WriteBatch batch = _firestore.batch();
    
    for (final task in tasks) {
      if (task.id == null || task.id!.isEmpty) {
        continue; // Skip tasks without IDs
      }
      
      // Verify task belongs to user
      final doc = await _getTasksCollection(userId).doc(task.id).get();
      if (!doc.exists) continue;
      
      final existingTask = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (existingTask.userId != userId) continue;
      
      // Ensure userId is maintained
      final taskWithUser = task.copyWith(userId: userId);
      batch.update(doc.reference, taskWithUser.toMap());
    }
    
    await batch.commit();
  }


  // FIXED: Get tasks by date range with proper timestamp handling
  Future<List<Task>> getUserTasksByDateRange(
    String userId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      // Ensure startDate is beginning of day, endDate is end of day
      final adjustedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
      final adjustedEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
      
      final QuerySnapshot snapshot = await _getTasksCollection(userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(adjustedStartDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(adjustedEndDate))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      if (e is FirebaseException) {
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to load tasks by date range: $e');
    }
  }

  // ENHANCED: Get user's task categories with frequency count
  Future<Map<String, int>> getUserTaskCategoriesWithCount(String userId) async {
    try {
      final QuerySnapshot snapshot = await _getTasksCollection(userId).get();
      final Map<String, int> categories = {};
      
      for (final doc in snapshot.docs) {
        final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        if (task.category.isNotEmpty) {
          categories[task.category] = (categories[task.category] ?? 0) + 1;
        }
      }
      
      return categories;
    } catch (e) {
      throw Exception('Failed to get user task categories: $e');
    }
  }

  // Get user's task categories (simple list)
  Future<List<String>> getUserTaskCategories(String userId) async {
    try {
      final categoriesMap = await getUserTaskCategoriesWithCount(userId);
      return categoriesMap.keys.toList()..sort();
    } catch (e) {
      throw Exception('Failed to get user task categories: $e');
    }
  }

  // Check if user has any tasks
  Future<bool> userHasTasks(String userId) async {
    try {
      final QuerySnapshot snapshot = await _getTasksCollection(userId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (e is FirebaseException) {
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to check if user has tasks: $e');
    }
  }

  // FIXED: Update reminder tone with proper validation
  Future<void> updateReminderTone(String taskId, String tone, String userId) async {
    try {
      // Validate tone
      final validTones = NotificationHelper.getValidNotificationTones();
      if (!validTones.contains(tone)) {
        throw Exception('Invalid notification tone: $tone');
      }

      // Verify task exists and belongs to user
      final doc = await _getTasksCollection(userId).doc(taskId).get();
      if (!doc.exists) {
        throw Exception('Task not found');
      }
      
      final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (task.userId != userId) {
        throw Exception('Unauthorized: Task does not belong to user');
      }

      await _getTasksCollection(userId).doc(taskId).update({
        'notificationTone': tone,
      });
      
      // Reschedule notification with new tone if reminder is active
      if (task.hasReminder && task.isReminderActive && task.reminderTime != null) {
        final updatedTask = task.copyWith(notificationTone: tone);
        
        // Cancel existing notification
        if (task.notificationId != null) {
          final notificationId = task.notificationId ?? _getNotificationId(taskId);
          await _notificationService.cancelNotification(notificationId);
        }
        
        // Schedule with new tone
        await _notificationService.scheduleTaskReminder(updatedTask);
      }
      
    } catch (e) {
      if (e is FirebaseException) {
        throw Exception('Database error: ${e.message}');
      }
      rethrow;
    }
  }

  // ENHANCED: Snooze reminder with comprehensive validation
  Future<void> snoozeReminder(String taskId, int minutes, String userId) async {
    try {
      if (minutes <= 0 || minutes > 1440) { // Max 24 hours
        throw Exception('Snooze time must be between 1 and 1440 minutes (24 hours)');
      }

      final doc = await _getTasksCollection(userId).doc(taskId).get();
      if (!doc.exists) {
        throw Exception('Task not found');
      }
      
      final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (task.userId != userId) {
        throw Exception('Unauthorized: Task does not belong to user');
      }

      if (!task.hasReminder || !task.isReminderActive) {
        throw Exception('Task has no active reminder to snooze');
      }
      
      final newReminderTime = DateTime.now().add(Duration(minutes: minutes));
      
      // Validate new time
      final validation = NotificationHelper.validateReminderTime(newReminderTime);
      if (validation != null) {
        throw Exception(validation);
      }
      
      await _getTasksCollection(userId).doc(taskId).update({
        'reminderTime': newReminderTime.millisecondsSinceEpoch,
        'snoozeCount': (task.snoozeCount ?? 0) + 1,
        'lastSnoozedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Reschedule notification
      final snoozedTask = task.copyWith(reminderTime: newReminderTime);
      await _notificationService.scheduleTaskReminder(snoozedTask);
      
    } catch (e) {
      if (e is FirebaseException) {
        throw Exception('Database error: ${e.message}');
      }
      rethrow;
    }
  }

  // ENHANCED: Process completed recurring task with robust logic
  Future<void> _processCompletedRecurringTask(Task task, String userId) async {
    if (!task.isRecurring || task.recurringPattern == null) return;

    final nextOccurrence = _getNextOccurrence(task);

    if (nextOccurrence != null) {
      // Create a new task for the next occurrence
      final newTask = task.copyWith(
        id: null, // Let Firestore generate a new ID
        dueDate: nextOccurrence,
        isCompleted: false,
        completedAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // Reset reminder if it's not a sticky reminder
        reminderTime: task.hasReminder ? nextOccurrence : null,
        isReminderActive: task.hasReminder,
        snoozeCount: 0,
        lastSnoozedAt: null,
      );

      await createTask(newTask, userId);
    }
  }

  // FIXED: Calculate next occurrence of a recurring task
  DateTime? _getNextOccurrence(Task task) {
    if (task.dueDate == null || task.recurringPattern == null || task.recurringInterval == null) {
      return null;
    }

    DateTime nextDate = task.dueDate!;
    final interval = task.recurringInterval!;

    switch (task.recurringPattern) {
      case 'daily':
        nextDate = nextDate.add(Duration(days: interval));
        break;
      case 'weekly':
        nextDate = nextDate.add(Duration(days: 7 * interval));
        break;
      case 'monthly':
        nextDate = DateTime(
          nextDate.year,
          nextDate.month + interval,
          nextDate.day,
          nextDate.hour,
          nextDate.minute,
        );
        // Handle month overflow
        while (nextDate.month > 12) {
          nextDate = DateTime(
            nextDate.year + 1,
            nextDate.month - 12,
            nextDate.day,
            nextDate.hour,
            nextDate.minute,
          );
        }
        break;
      case 'yearly':
        nextDate = DateTime(
          nextDate.year + interval,
          nextDate.month,
          nextDate.day,
          nextDate.hour,
          nextDate.minute,
        );
        break;
      default:
        return null;
    }

    // If the next occurrence is in the past, keep adding intervals until it's in the future
    final now = DateTime.now();
    while (nextDate.isBefore(now)) {
      switch (task.recurringPattern) {
        case 'daily':
          nextDate = nextDate.add(Duration(days: interval));
          break;
        case 'weekly':
          nextDate = nextDate.add(Duration(days: 7 * interval));
          break;
        case 'monthly':
          nextDate = DateTime(
            nextDate.year,
            nextDate.month + interval,
            nextDate.day,
            nextDate.hour,
            nextDate.minute,
          );
          break;
        case 'yearly':
          nextDate = DateTime(
            nextDate.year + interval,
            nextDate.month,
            nextDate.day,
            nextDate.hour,
            nextDate.minute,
          );
          break;
      }
    }

    return nextDate;
  }

  // ENHANCED: Schedule reminder with comprehensive validation and error handling
  Future<void> scheduleReminder(
    String taskId, 
    DateTime reminderTime, 
    String userId, {
    String reminderType = 'once', 
    List<String> repeatDays = const [],
    String notificationTone = 'default'
  }) async {
    try {
      // Validate inputs
      final timeValidation = NotificationHelper.validateReminderTime(reminderTime);
      if (timeValidation != null) {
        throw Exception(timeValidation);
      }

      final daysValidation = NotificationHelper.validateRepeatDays(reminderType, repeatDays);
      if (daysValidation != null) {
        throw Exception(daysValidation);
      }

      final validTones = NotificationHelper.getValidNotificationTones();
      if (!validTones.contains(notificationTone)) {
        throw Exception('Invalid notification tone');
      }

      // Verify task exists and belongs to user
      final doc = await _getTasksCollection(userId).doc(taskId).get();
      if (!doc.exists) {
        throw Exception('Task not found');
      }
      
      final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (task.userId != userId) {
        throw Exception('Unauthorized: Task does not belong to user');
      }

      final notificationId = _getNotificationId(taskId);

      // Calculate next occurrence for recurring reminders
      DateTime scheduleTime = reminderTime;
      if (reminderType != 'once') {
        final nextOccurrence = NotificationHelper.getNextOccurrence(
          reminderType, 1, reminderTime
        );
        if (nextOccurrence != null) {
          scheduleTime = nextOccurrence;
        }
      }

      final updateData = {
        'hasReminder': true,
        'reminderTime': scheduleTime.millisecondsSinceEpoch,
        'reminderType': reminderType,
        'repeatDays': repeatDays,
        'notificationTone': notificationTone,
        'isReminderActive': true,
        'notificationId': notificationId,
      };
      
      await _getTasksCollection(userId).doc(taskId).update(updateData);
      
      // Schedule the notification
      final updatedTask = task.copyWith(
        hasReminder: true,
        reminderTime: scheduleTime,
        reminderType: reminderType,
        repeatDays: repeatDays,
        notificationTone: notificationTone,
        isReminderActive: true,
        notificationId: notificationId,
      );
      
      await _notificationService.scheduleTaskReminder(updatedTask);
      
    } catch (e) {
      if (e is FirebaseException) {
        throw Exception('Database error: ${e.message}');
      }
      rethrow;
    }
  }

  // ENHANCED: Cancel reminder with proper cleanup
  Future<void> cancelReminder(String taskId, String userId) async {
    try {
      // Verify task belongs to user
      final doc = await _getTasksCollection(userId).doc(taskId).get();
      if (!doc.exists) {
        throw Exception('Task not found');
      }
      
      final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (task.userId != userId) {
        throw Exception('Unauthorized: Task does not belong to user');
      }

      await _getTasksCollection(userId).doc(taskId).update({
        'hasReminder': false,
        'isReminderActive': false,
        'reminderCancelledAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Cancel the notification
      if (task.notificationId != null) {
        final notificationId = task.notificationId ?? _getNotificationId(taskId);
        await _notificationService.cancelNotification(notificationId);
      }
    } catch (e) {
      if (e is FirebaseException) {
        throw Exception('Database error: ${e.message}');
      }
      rethrow;
    }
  }

  // FIXED: Reschedule all reminders with better error handling
  Future<void> rescheduleAllReminders(String userId) async {
    try {
      final snapshot = await _getTasksCollection(userId)
          .where('hasReminder', isEqualTo: true)
          .where('isReminderActive', isEqualTo: true)
          .where('isCompleted', isEqualTo: false)
          .get();
      
      int successCount = 0;
      int failureCount = 0;
      
      for (var doc in snapshot.docs) {
        try {
          final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          
          // Only reschedule future reminders
          if (task.reminderTime != null && task.reminderTime!.isAfter(DateTime.now())) {
            await _notificationService.scheduleTaskReminder(task);
            successCount++;
          } else {
            // Deactivate past reminders
            await doc.reference.update({'isReminderActive': false});
          }
        } catch (taskError) {
          failureCount++;
          print('Failed to reschedule reminder for task ${doc.id}: $taskError');
        }
      }
      
      if (failureCount > 0) {
        print('Rescheduled $successCount reminders, $failureCount failed');
      }
      
    } catch (e) {
      throw Exception('Failed to reschedule reminders: $e');
    }
  }

  // ENHANCED: Get upcoming reminders with proper date handling
  Future<List<Task>> getUpcomingReminders(String userId, {int hoursAhead = 24}) async {
    try {
      final now = DateTime.now();
      final futureTime = now.add(Duration(hours: hoursAhead));
      
      final snapshot = await _getTasksCollection(userId)
          .where('hasReminder', isEqualTo: true)
          .where('isReminderActive', isEqualTo: true)
          .where('isCompleted', isEqualTo: false)
          .orderBy('reminderTime')
          .get();
      
      // Filter by time range client-side due to Firestore query limitations
      final tasks = snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((task) => 
            task.reminderTime != null &&
            task.reminderTime!.isAfter(now) && 
            task.reminderTime!.isBefore(futureTime)
          )
          .toList();

      return tasks;
          
    } catch (e) {
      if (e is FirebaseException) {
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to get upcoming reminders: $e');
    }
  }

  // ENHANCED: Process recurring tasks with comprehensive handling
  Future<void> processRecurringTasks(String userId) async {
    try {
      final now = DateTime.now();
      
      // Get all recurring tasks that are completed and need processing
      final snapshot = await _getTasksCollection(userId)
          .where('isRecurring', isEqualTo: true)
          .where('isCompleted', isEqualTo: true)
          .get();
      
      int processedCount = 0;
      
      for (var doc in snapshot.docs) {
        try {
          final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          
          // Check if we need to create next occurrence
          final lastProcessed = task.lastProcessedAt;
          final timeSinceProcessed = lastProcessed == null 
              ? Duration(hours: 25) // Force processing if never processed
              : now.difference(lastProcessed);
          
          if (timeSinceProcessed.inHours >= 1) {
            await _processCompletedRecurringTask(task, userId);
            processedCount++;
          }
        } catch (taskError) {
          print('Failed to process recurring task ${doc.id}: $taskError');
        }
      }
      
      if (processedCount > 0) {
        print('Processed $processedCount recurring tasks');
      }
    } catch (e) {
      throw Exception('Failed to process recurring tasks: $e');
    }
  }


  // FIXED: Migrate user tasks with proper transaction handling
  Future<bool> migrateUserTasks(String fromUserId, String toUserId) async {
    try {
      if (fromUserId == toUserId) {
        throw Exception('Cannot migrate tasks to the same user');
      }

      final QuerySnapshot snapshot = await _getTasksCollection(fromUserId).get();
      
      if (snapshot.docs.isEmpty) {
        return true; // Nothing to migrate
      }

      // Process in batches to avoid Firestore transaction limits
      const int batchSize = 100;
      final docs = snapshot.docs;
      
      for (int i = 0; i < docs.length; i += batchSize) {
        final batch = _firestore.batch();
        final batchDocs = docs.skip(i).take(batchSize);
        
        for (final doc in batchDocs) {
          final taskData = doc.data() as Map<String, dynamic>;
          taskData['userId'] = toUserId;
          taskData['migratedAt'] = DateTime.now().millisecondsSinceEpoch;
          
          // Create new document in target user's collection
          final newDocRef = _getTasksCollection(toUserId).doc();
          batch.set(newDocRef, taskData);
          
          // Delete from source user's collection
          batch.delete(doc.reference);
        }
        
        await batch.commit();
      }
      
      // Update task counts for both users
      await _updateUserTaskCount(fromUserId);
      await _updateUserTaskCount(toUserId);
      
      return true;
    } catch (e) {
      if (e is FirebaseException) {
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to migrate user tasks: $e');
    }
  }

  // NEW: Advanced filtering method
  Future<List<Task>> getFilteredTasks(
    String userId, {
    List<String>? priorities,
    List<String>? categories,
    bool? isCompleted,
    bool? hasReminder,
    bool? isOverdue,
    bool? isDueToday,
    bool? isRecurring,
    String? searchQuery,
    String sortBy = 'createdAt',
    bool sortDescending = true,
    int? limit,
  }) async {
    try {
      // Start with all tasks for user
      List<Task> tasks = await getUserTasks(userId, orderBy: sortBy, descending: sortDescending, limit: limit);

      // Apply filters
      if (isCompleted != null) {
        tasks = tasks.where((task) => task.isCompleted == isCompleted).toList();
      }
      
      if (priorities != null && priorities.isNotEmpty) {
        tasks = tasks.where((task) => priorities.contains(task.priority)).toList();
      }
      
      if (categories != null && categories.isNotEmpty) {
        tasks = tasks.where((task) => categories.contains(task.category)).toList();
      }
      
      if (hasReminder != null) {
        tasks = tasks.where((task) => task.hasReminder == hasReminder).toList();
      }
      
      if (isRecurring != null) {
        tasks = tasks.where((task) => task.isRecurring == isRecurring).toList();
      }
      
      if (isOverdue == true) {
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        tasks = tasks.where((task) => 
          task.dueDate != null && 
          task.dueDate!.isBefore(startOfToday) && 
          !task.isCompleted
        ).toList();
      }
      
      if (isDueToday == true) {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        
        tasks = tasks.where((task) => 
          task.dueDate != null && 
          task.dueDate!.isAfter(startOfDay) &&
          task.dueDate!.isBefore(endOfDay) &&
          !task.isCompleted
        ).toList();
      }

      // Apply search filter
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final String lowerQuery = searchQuery.toLowerCase().trim();
        tasks = tasks.where((task) {
          return task.title.toLowerCase().contains(lowerQuery) ||
                 (task.description?.toLowerCase().contains(lowerQuery) ?? false) ||
                 task.category.toLowerCase().contains(lowerQuery) ||
                 task.priority.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      return tasks;
    } catch (e) {
      throw Exception('Failed to load filtered tasks: $e');
    }
  }

  // NEW: Get comprehensive task analytics
  Future<Map<String, dynamic>> getTaskAnalytics(String userId) async {
    try {
      final allTasks = await getUserTasks(userId);
      final now = DateTime.now();
      
      // Group tasks by category and priority
      Map<String, int> categoryCount = {};
      Map<String, int> priorityCount = {};
      Map<String, int> monthlyCompletion = {};
      Map<String, int> weeklyCompletion = {};
      
      for (final task in allTasks) {
        // Category stats
        if (task.category.isNotEmpty) {
          categoryCount[task.category] = (categoryCount[task.category] ?? 0) + 1;
        }
        
        // Priority stats
        priorityCount[task.priority] = (priorityCount[task.priority] ?? 0) + 1;
        
        // Completion stats
        if (task.isCompleted && task.completedAt != null) {
          // Monthly completion
          final monthKey = '${task.completedAt!.year}-${task.completedAt!.month.toString().padLeft(2, '0')}';
          monthlyCompletion[monthKey] = (monthlyCompletion[monthKey] ?? 0) + 1;
          
          // Weekly completion (week number of year)
          final weekNumber = _getWeekNumber(task.completedAt!);
          final weekKey = '${task.completedAt!.year}-W$weekNumber';
          weeklyCompletion[weekKey] = (weeklyCompletion[weekKey] ?? 0) + 1;
        }
      }
      
      // Calculate productivity metrics
      final completedTasks = allTasks.where((task) => task.isCompleted).length;
      final totalTasks = allTasks.length;
      final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100).round() : 0;
      
      // Calculate various streaks and metrics
      final currentStreak = await _calculateCompletionStreak(userId);
      final longestStreak = await _calculateLongestStreak(userId);
      final averageTasksPerDay = await _calculateAverageTasksPerDay(userId);
      
      return {
        'categoryStats': categoryCount,
        'priorityStats': priorityCount,
        'monthlyCompletion': monthlyCompletion,
        'weeklyCompletion': weeklyCompletion,
        'completionRate': completionRate,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'averageTasksPerDay': averageTasksPerDay,
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'pendingTasks': allTasks.length - completedTasks,
        'overdueCount': allTasks.where((task) => 
          !task.isCompleted && 
          task.dueDate != null && 
          task.dueDate!.isBefore(DateTime(now.year, now.month, now.day))
        ).length,
      };
    } catch (e) {
      throw Exception('Failed to get task analytics: $e');
    }
  }

  // Helper to get week number
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  // FIXED: Calculate completion streak with proper date handling
  Future<int> _calculateCompletionStreak(String userId) async {
    try {
      final now = DateTime.now();
      int streak = 0;
      
      // Check each day going backwards
      for (int i = 0; i < 365; i++) { // Max 1 year streak
        final checkDate = now.subtract(Duration(days: i));
        final startOfDay = DateTime(checkDate.year, checkDate.month, checkDate.day);
        final endOfDay = DateTime(checkDate.year, checkDate.month, checkDate.day, 23, 59, 59, 999);
        
        final snapshot = await _getTasksCollection(userId)
            .where('isCompleted', isEqualTo: true)
            .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('completedAt', isLessThan: Timestamp.fromDate(endOfDay))
            .limit(1)
            .get();
        
        if (snapshot.docs.isNotEmpty) {
          streak++;
        } else if (i > 0) { // Don't break on today if no tasks completed yet
          break;
        }
      }
      
      return streak;
    } catch (e) {
      return 0; // Return 0 on error instead of throwing
    }
  }

  // NEW: Calculate longest completion streak
  Future<int> _calculateLongestStreak(String userId) async {
    try {
      // Get all completed tasks ordered by completion date
      final snapshot = await _getTasksCollection(userId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('completedAt')
          .get();
      
      if (snapshot.docs.isEmpty) return 0;
      
      int longestStreak = 0;
      int currentStreak = 0;
      DateTime? lastDate;
      
      for (final doc in snapshot.docs) {
        final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        if (task.completedAt == null) continue;
        
        final completionDate = DateTime(
          task.completedAt!.year,
          task.completedAt!.month,
          task.completedAt!.day,
        );
        
        if (lastDate == null || completionDate.difference(lastDate).inDays <= 1) {
          if (lastDate == null || completionDate.difference(lastDate).inDays == 1) {
            currentStreak++;
          }
        } else {
          longestStreak = math.max(longestStreak, currentStreak);
          currentStreak = 1;
        }
        
        lastDate = completionDate;
      }
      
      return math.max(longestStreak, currentStreak);
    } catch (e) {
      return 0;
    }
  }

  // NEW: Calculate average tasks completed per day
  Future<double> _calculateAverageTasksPerDay(String userId) async {
    try {
      final snapshot = await _getTasksCollection(userId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('completedAt')
          .get();
      
      if (snapshot.docs.isEmpty) return 0.0;
      
      final tasks = snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((task) => task.completedAt != null)
          .toList();
      
      if (tasks.isEmpty) return 0.0;
      
      final firstCompletion = tasks.first.completedAt!;
      final lastCompletion = tasks.last.completedAt!;
      final daysDifference = lastCompletion.difference(firstCompletion).inDays + 1;
      
      return tasks.length / daysDifference;
    } catch (e) {
      return 0.0;
    }
  }

  // NEW: Get tasks with priority weights for smart sorting
  Future<List<Task>> getSmartSortedTasks(String userId) async {
    try {
      final tasks = await getUserTasks(userId, isCompleted: false);
      
      // Sort by urgency score (combination of priority, due date, and other factors)
      tasks.sort((a, b) {
        final aScore = _calculateUrgencyScore(a);
        final bScore = _calculateUrgencyScore(b);
        return bScore.compareTo(aScore); // Higher score first
      });
      
      return tasks;
    } catch (e) {
      throw Exception('Failed to get smart sorted tasks: $e');
    }
  }

  // Helper to calculate urgency score
  double _calculateUrgencyScore(Task task) {
    double score = 0;
    
    // Priority weight
    switch (task.priority) {
      case 'high':
        score += 100;
        break;
      case 'medium':
        score += 50;
        break;
      case 'low':
        score += 25;
        break;
    }
    
    // Due date urgency
    if (task.dueDate != null) {
      final now = DateTime.now();
      final daysUntilDue = task.dueDate!.difference(now).inDays;
      
      if (daysUntilDue < 0) {
        // Overdue - very high urgency
        score += 200 + (-daysUntilDue * 10); // More overdue = higher score
      } else if (daysUntilDue == 0) {
        // Due today
        score += 150;
      } else if (daysUntilDue == 1) {
        // Due tomorrow
        score += 75;
      } else if (daysUntilDue <= 7) {
        // Due this week
        score += 40 - (daysUntilDue * 5);
      } else {
        // Due later
        score += math.max(0, 20 - daysUntilDue);
      }
    }
    
    // Reminder urgency
    if (task.hasReminder && task.reminderTime != null && task.isReminderActive) {
      score += 30;
    }
    
    // Recurring task bonus
    if (task.isRecurring) {
      score += 20;
    }
    
    return score;
  }

  // NEW: Bulk operations for multiple tasks
  Future<Map<String, dynamic>> bulkUpdateTasks(
    List<String> taskIds, 
    Map<String, dynamic> updates, 
    String userId
  ) async {
    try {
      int successCount = 0;
      int failureCount = 0;
      List<String> failedIds = [];
      
      // Process in batches
      const int batchSize = 100;
      
      for (int i = 0; i < taskIds.length; i += batchSize) {
        final batchIds = taskIds.skip(i).take(batchSize).toList();
        final batch = _firestore.batch();
        
        for (final taskId in batchIds) {
          try {
            // Verify task exists and belongs to user
            final doc = await _getTasksCollection(userId).doc(taskId).get();
            if (!doc.exists) {
              failureCount++;
              failedIds.add(taskId);
              continue;
            }
            
            final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            if (task.userId != userId) {
              failureCount++;
              failedIds.add(taskId);
              continue;
            }
            
            // Add userId to updates to ensure it's maintained
            final updatesWithUser = Map<String, dynamic>.from(updates);
            updatesWithUser['userId'] = userId;
            
            batch.update(doc.reference, updatesWithUser);
            successCount++;
          } catch (e) {
            failureCount++;
            failedIds.add(taskId);
          }
        }
        
        if (successCount > 0) {
          await batch.commit();
        }
      }
      
      // Update user task count if any tasks were modified
      if (successCount > 0) {
        await _updateUserTaskCount(userId);
      }
      
      return {
        'success': successCount,
        'failure': failureCount,
        'failedIds': failedIds,
        'total': taskIds.length,
      };
    } catch (e) {
      throw Exception('Failed to bulk update tasks: $e');
    }
  }

  // NEW: Bulk delete multiple tasks
  Future<Map<String, dynamic>> bulkDeleteTasks(List<String> taskIds, String userId) async {
    try {
      int successCount = 0;
      int failureCount = 0;
      List<String> failedIds = [];
      
      // First, cancel all notifications
      for (final taskId in taskIds) {
        try {
          final doc = await _getTasksCollection(userId).doc(taskId).get();
          if (doc.exists) {
            final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            if (task.userId == userId && task.hasReminder && task.notificationId != null) {
              await _notificationService.cancelNotification(task.notificationId!);
            }
          }
        } catch (e) {
          // Continue with deletion even if notification cancellation fails
          print('Failed to cancel notification for task $taskId: $e');
        }
      }
      
      // Process deletions in batches
      const int batchSize = 100;
      
      for (int i = 0; i < taskIds.length; i += batchSize) {
        final batchIds = taskIds.skip(i).take(batchSize).toList();
        final batch = _firestore.batch();
        
        for (final taskId in batchIds) {
          try {
            // Verify task exists and belongs to user
            final doc = await _getTasksCollection(userId).doc(taskId).get();
            if (!doc.exists) {
              failureCount++;
              failedIds.add(taskId);
              continue;
            }
            
            final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            if (task.userId != userId) {
              failureCount++;
              failedIds.add(taskId);
              continue;
            }
            
            batch.delete(doc.reference);
            successCount++;
          } catch (e) {
            failureCount++;
            failedIds.add(taskId);
          }
        }
        
        if (successCount > 0) {
          await batch.commit();
        }
      }
      
      // Update user task count
      if (successCount > 0) {
        await _updateUserTaskCount(userId);
      }
      
      return {
        'success': successCount,
        'failure': failureCount,
        'failedIds': failedIds,
        'total': taskIds.length,
      };
    } catch (e) {
      throw Exception('Failed to bulk delete tasks: $e');
    }
  }

  // NEW: Get tasks due this week
  Future<List<Task>> getUserTasksDueThisWeek(String userId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    
    return getUserTasks(
      userId,
      isCompleted: false,
      dueAfter: startOfWeek,
      dueBefore: endOfWeek,
      orderBy: 'dueDate',
      descending: false,
    );
  }

  // NEW: Get tasks due next week
  Future<List<Task>> getUserTasksDueNextWeek(String userId) async {
    final now = DateTime.now();
    final daysUntilNextWeek = 8 - now.weekday;
    final startOfNextWeek = now.add(Duration(days: daysUntilNextWeek));
    final endOfNextWeek = startOfNextWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    
    return getUserTasks(
      userId,
      isCompleted: false,
      dueAfter: startOfNextWeek,
      dueBefore: endOfNextWeek,
      orderBy: 'dueDate',
      descending: false,
    );
  }

  // NEW: Get recently completed tasks
  Future<List<Task>> getRecentlyCompletedTasks(String userId, {int days = 7}) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    
    return getUserTasks(
      userId,
      isCompleted: true,
      orderBy: 'completedAt',
      descending: true,
    ).then((tasks) {
      return tasks.where((task) => 
        task.completedAt != null && task.completedAt!.isAfter(startDate)
      ).toList();
    });
  }

  // NEW: Get task productivity insights
  Future<Map<String, dynamic>> getProductivityInsights(String userId) async {
    try {
      final analytics = await getTaskAnalytics(userId);
      final now = DateTime.now();
      
      // Get tasks from last 30 days
      final last30Days = now.subtract(const Duration(days: 30));
      final recentTasks = await getUserTasksByDateRange(userId, last30Days, now);
      
      // Calculate productivity trends
      final recentCompleted = recentTasks.where((task) => task.isCompleted).length;
      final recentTotal = recentTasks.length;
      final recentCompletionRate = recentTotal > 0 ? (recentCompleted / recentTotal * 100).round() : 0;
      
      // Find most productive day of week
      Map<int, int> dayOfWeekCompletions = {};
      for (final task in recentTasks) {
        if (task.isCompleted && task.completedAt != null) {
          final dayOfWeek = task.completedAt!.weekday;
          dayOfWeekCompletions[dayOfWeek] = (dayOfWeekCompletions[dayOfWeek] ?? 0) + 1;
        }
      }
      
      final mostProductiveDay = dayOfWeekCompletions.entries
          .fold<int>(0, (prev, entry) => (dayOfWeekCompletions[prev] ?? 0) > entry.value ? prev : entry.key);
      
      return {
        'overall': analytics,
        'recent30Days': {
          'completed': recentCompleted,
          'total': recentTotal,
          'completionRate': recentCompletionRate,
        },
        'trends': {
          'mostProductiveDay': mostProductiveDay,
          'dayOfWeekStats': dayOfWeekCompletions,
        }
      };
    } catch (e) {
      throw Exception('Failed to get productivity insights: $e');
    }
  }

  // NEW: Duplicate a task
  Future<String> duplicateTask(String taskId, String userId, {String? newTitle}) async {
    try {
      final originalTask = await getUserTask(taskId, userId);
      if (originalTask == null) {
        throw Exception('Original task not found');
      }
      
      final duplicatedTask = originalTask.copyWith(
        id: null, // New task gets new ID
        title: newTitle ?? '${originalTask.title} (Copy)',
        isCompleted: false,
        completedAt: null,
        createdAt: DateTime.now(),
        notificationId: null,
        lastProcessedAt: null,
        snoozeCount: 0,
        lastSnoozedAt: null,
        // Keep reminder settings but reset state
        isReminderActive: originalTask.hasReminder,
      );
      
      return await createTask(duplicatedTask, userId);
    } catch (e) {
      throw Exception('Failed to duplicate task: $e');
    }
  }

  // NEW: Export user tasks to map (for backup/export)
  Future<Map<String, dynamic>> exportUserTasks(String userId) async {
    try {
      final allTasks = await getUserTasks(userId);
      final analytics = await getTaskAnalytics(userId);
      
      return {
        'exportedAt': DateTime.now().toIso8601String(),
        'userId': userId,
        'taskCount': allTasks.length,
        'tasks': allTasks.map((task) => task.toMap()).toList(),
        'analytics': analytics,
      };
    } catch (e) {
      throw Exception('Failed to export user tasks: $e');
    }
  }

  // NEW: Import tasks from exported data
  Future<Map<String, int>> importUserTasks(String userId, Map<String, dynamic> exportData) async {
    try {
      if (!exportData.containsKey('tasks')) {
        throw Exception('Invalid export data: missing tasks');
      }
      
      final List<dynamic> tasksList = exportData['tasks'] as List<dynamic>;
      int successCount = 0;
      int failureCount = 0;
      
      for (final taskData in tasksList) {
        try {
          final taskMap = taskData as Map<String, dynamic>;
          
          // Remove original ID and user-specific data
          taskMap.remove('id');
          taskMap['userId'] = userId;
          taskMap['createdAt'] = DateTime.now().millisecondsSinceEpoch;
          taskMap['importedAt'] = DateTime.now().millisecondsSinceEpoch;
          
          // Reset notification state
          taskMap['notificationId'] = null;
          taskMap['isReminderActive'] = false;
          
          final task = Task.fromMap(taskMap, '');
          await createTask(task, userId);
          successCount++;
        } catch (e) {
          failureCount++;
          print('Failed to import task: $e');
        }
      }
      
      return {
        'success': successCount,
        'failure': failureCount,
        'total': tasksList.length,
      };
    } catch (e) {
      throw Exception('Failed to import tasks: $e');
    }
  }

  // NEW: Clean up orphaned notifications
  Future<void> cleanupOrphanedNotifications(String userId) async {
    try {
      final tasks = await getUserTasksWithReminders(userId);
      
      // Get all notification IDs that should exist
      final validNotificationIds = <int>{};
      for (final task in tasks) {
        if (task.notificationId != null) {
          final id = task.notificationId ?? _getNotificationId(task.id!);
          validNotificationIds.add(id);
        }
      }
      
      // This would require platform-specific implementation to get all scheduled notifications
      // and cancel ones not in validNotificationIds set
      // await _notificationService.cancelNotifications(validNotificationIds); // Method does not exist
      
    } catch (e) {
      print('Failed to cleanup orphaned notifications: $e');
      // Don't throw - this is a cleanup operation
    }
  }

  // NEW: Get task completion trends
  Future<Map<String, List<Map<String, dynamic>>>> getTaskCompletionTrends(String userId, {int days = 30}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      
      final tasks = await getUserTasksByDateRange(userId, startDate, now);
      final completedTasks = tasks.where((task) => task.isCompleted && task.completedAt != null).toList();
      
      // Group by day
      Map<String, int> dailyCompletions = {};
      Map<String, int> dailyCreations = {};
      
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        
        dailyCompletions[dateKey] = 0;
        dailyCreations[dateKey] = 0;
      }
      
      // Count completions
      for (final task in completedTasks) {
        final date = task.completedAt!;
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyCompletions[dateKey] = (dailyCompletions[dateKey] ?? 0) + 1;
      }
      
      // Count creations
      for (final task in tasks) {
        if (task.createdAt != null) {
          final date = task.createdAt;
          final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          dailyCreations[dateKey] = (dailyCreations[dateKey] ?? 0) + 1;
        }
      }
      
      return {
        'completions': dailyCompletions.entries.map((e) => {
          'date': e.key,
          'count': e.value,
        }).toList(),
        'creations': dailyCreations.entries.map((e) => {
          'date': e.key,
          'count': e.value,
        }).toList(),
      };
    } catch (e) {
      throw Exception('Failed to get completion trends: $e');
    }
  }

  // NEW: Archive completed tasks older than specified days
  Future<int> archiveOldCompletedTasks(String userId, {int daysOld = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final snapshot = await _getTasksCollection(userId)
          .where('isCompleted', isEqualTo: true)
          .where('completedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();
      
      if (snapshot.docs.isEmpty) return 0;
      
      // Move to archived collection
      final archivedCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('archived_tasks');
      
      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        final taskData = doc.data() as Map<String, dynamic>;
        taskData['archivedAt'] = DateTime.now().millisecondsSinceEpoch;
        
        // Add to archive
        batch.set(archivedCollection.doc(doc.id), taskData);
        
        // Remove from active tasks
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      await _updateUserTaskCount(userId);
      
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to archive old tasks: $e');
    }
  }

  // NEW: Restore archived task
  Future<bool> restoreArchivedTask(String taskId, String userId) async {
    try {
      final archivedDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('archived_tasks')
          .doc(taskId)
          .get();
      
      if (!archivedDoc.exists) {
        throw Exception('Archived task not found');
      }
      
      final taskData = archivedDoc.data() as Map<String, dynamic>;
      taskData.remove('archivedAt');
      taskData['restoredAt'] = DateTime.now().millisecondsSinceEpoch;
      
      // Restore to active tasks
      await _getTasksCollection(userId).doc(taskId).set(taskData);
      
      // Remove from archive
      await archivedDoc.reference.delete();
      
      await _updateUserTaskCount(userId);
      
      return true;
    } catch (e) {
      throw Exception('Failed to restore archived task: $e');
    }
  }

  // NEW: Get archived tasks
  Future<List<Task>> getArchivedTasks(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('archived_tasks')
          .orderBy('archivedAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get archived tasks: $e');
    }
  }

  // NEW: Validate task data before operations
  String? validateTaskData(Task task) {
    if (task.title.trim().isEmpty) {
      return 'Task title cannot be empty';
    }
    
    if (task.title.length > 100) {
      return 'Task title too long (max 100 characters)';
    }
    
    if (task.description != null && task.description!.length > 500) {
      return 'Task description too long (max 500 characters)';
    }
    
    if (task.isRecurring) {
      if (task.recurringPattern == null || task.recurringInterval == null) {
        return 'Recurring tasks must have pattern and interval';
      }
      
      if (task.recurringInterval! <= 0) {
        return 'Recurring interval must be positive';
      }
      
      final validPatterns = ['daily', 'weekly', 'monthly', 'yearly'];
      if (!validPatterns.contains(task.recurringPattern)) {
        return 'Invalid recurring pattern';
      }
    }
    
    if (task.hasReminder && task.reminderTime != null) {
      final validation = NotificationHelper.validateReminderTime(task.reminderTime!);
      if (validation != null) {
        return validation;
      }
    }
    
    return null; // Valid
  }

  // NEW: Get task dependencies (if tasks reference each other)
  Future<List<Task>> getTaskDependencies(String taskId, String userId) async {
    try {
      // This would require a dependency system in your Task model
      // For now, return empty list
      return [];
    } catch (e) {
      throw Exception('Failed to get task dependencies: $e');
    }
  }

  // NEW: Batch schedule reminders for multiple tasks
  Future<Map<String, dynamic>> batchScheduleReminders(
    List<String> taskIds,
    DateTime reminderTime,
    String userId, {
    String reminderType = 'once',
    List<String> repeatDays = const [],
    String notificationTone = 'default',
  }) async {
    try {
      int successCount = 0;
      int failureCount = 0;
      List<String> failedIds = [];
      
      for (final taskId in taskIds) {
        try {
          await scheduleReminder(
            taskId,
            reminderTime,
            userId,
            reminderType: reminderType,
            repeatDays: repeatDays,
            notificationTone: notificationTone,
          );
          successCount++;
        } catch (e) {
          failureCount++;
          failedIds.add(taskId);
        }
      }
      
      return {
        'success': successCount,
        'failure': failureCount,
        'failedIds': failedIds,
        'total': taskIds.length,
      };
    } catch (e) {
      throw Exception('Failed to batch schedule reminders: $e');
    }
  }

  // NEW: Get task performance metrics
  Future<Map<String, dynamic>> getTaskPerformanceMetrics(String userId) async {
    try {
      final allTasks = await getUserTasks(userId);
      
      // Calculate average time to completion
      final completedTasks = allTasks.where((task) => 
        task.isCompleted && task.completedAt != null && task.createdAt != null
      ).toList();
      
      double averageCompletionTime = 0;
      if (completedTasks.isNotEmpty) {
        final totalTime = completedTasks.fold<int>(0, (sum, task) => 
          sum + task.completedAt!.difference(task.createdAt).inHours
        );
        averageCompletionTime = totalTime / completedTasks.length;
      }
      
      // Calculate completion rate by priority
      Map<String, double> priorityCompletionRates = {};
      for (final priority in ['high', 'medium', 'low']) {
        final priorityTasks = allTasks.where((task) => task.priority == priority).toList();
        final completedPriorityTasks = priorityTasks.where((task) => task.isCompleted).length;
        priorityCompletionRates[priority] = priorityTasks.isNotEmpty 
            ? (completedPriorityTasks / priorityTasks.length * 100)
            : 0.0;
      }
      
      // Calculate snooze statistics
      final tasksWithSnoozes = allTasks.where((task) => (task.snoozeCount ?? 0) > 0).toList();
      final averageSnoozeCount = tasksWithSnoozes.isNotEmpty
          ? tasksWithSnoozes.fold<int>(0, (sum, task) => sum + (task.snoozeCount ?? 0)) / tasksWithSnoozes.length
          : 0.0;
      
      return {
        'averageCompletionTimeHours': averageCompletionTime.round(),
        'priorityCompletionRates': priorityCompletionRates,
        'tasksWithSnoozes': tasksWithSnoozes.length,
        'averageSnoozeCount': averageSnoozeCount.round(),
        'totalTasks': allTasks.length,
        'completionRate': allTasks.isNotEmpty 
            ? (completedTasks.length / allTasks.length * 100).round()
            : 0,
      };
    } catch (e) {
      throw Exception('Failed to get performance metrics: $e');
    }
  }
}