// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/task.dart';

class HomeWidgetService {
  static const String _androidWidgetName = 'WhispTaskWidgetProvider';
  static const String _iOSWidgetName = 'WhispTaskWidget';
  
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await HomeWidget.setAppGroupId('group.com.whisptask.app');
      _isInitialized = true;
      debugPrint('🏠 Home Widget Service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize Home Widget Service: $e');
    }
  }

  static Future<void> updateWidget({
    required List<Task> tasks,
    required int completedToday,
    required int totalToday,
    required double productivityScore,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Prepare data for widget
      final pendingTasks = tasks.where((task) => !task.isCompleted).take(5).toList();
      final urgentTasks = tasks.where((task) => 
        !task.isCompleted && 
        task.priority == 'high' &&
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now().add(const Duration(days: 1)))
      ).length;

      // Save data to widget
      await HomeWidget.saveWidgetData<String>('app_name', 'WhispTask');
      await HomeWidget.saveWidgetData<int>('completed_today', completedToday);
      await HomeWidget.saveWidgetData<int>('total_today', totalToday);
      await HomeWidget.saveWidgetData<double>('productivity_score', productivityScore);
      await HomeWidget.saveWidgetData<int>('urgent_tasks', urgentTasks);
      await HomeWidget.saveWidgetData<int>('pending_count', pendingTasks.length);
      
      // Save top 3 pending tasks
      for (int i = 0; i < 3; i++) {
        if (i < pendingTasks.length) {
          await HomeWidget.saveWidgetData<String>('task_${i}_title', pendingTasks[i].title);
          await HomeWidget.saveWidgetData<String>('task_${i}_priority', pendingTasks[i].priority);
          await HomeWidget.saveWidgetData<String>('task_${i}_category', pendingTasks[i].category);
        } else {
          await HomeWidget.saveWidgetData<String>('task_${i}_title', '');
          await HomeWidget.saveWidgetData<String>('task_${i}_priority', '');
          await HomeWidget.saveWidgetData<String>('task_${i}_category', '');
        }
      }

      // Update last sync time
      await HomeWidget.saveWidgetData<String>('last_update', DateTime.now().toIso8601String());

      // Update the widget
      await HomeWidget.updateWidget(
        name: defaultTargetPlatform == TargetPlatform.android 
            ? _androidWidgetName 
            : _iOSWidgetName,
        androidName: _androidWidgetName,
        iOSName: _iOSWidgetName,
      );

      debugPrint('🏠 Widget updated successfully');
    } catch (e) {
      debugPrint('❌ Failed to update widget: $e');
    }
  }

  static Future<void> updateTaskCompletion(String taskId, bool isCompleted) async {
    try {
      await HomeWidget.saveWidgetData<String>('last_action', 'task_toggle');
      await HomeWidget.saveWidgetData<String>('last_task_id', taskId);
      await HomeWidget.saveWidgetData<bool>('last_task_completed', isCompleted);
      
      await HomeWidget.updateWidget(
        name: defaultTargetPlatform == TargetPlatform.android 
            ? _androidWidgetName 
            : _iOSWidgetName,
        androidName: _androidWidgetName,
        iOSName: _iOSWidgetName,
      );
      
      debugPrint('🏠 Widget updated for task completion');
    } catch (e) {
      debugPrint('❌ Failed to update widget for task completion: $e');
    }
  }

  static Future<void> registerInteractivityCallback() async {
    try {
      HomeWidget.widgetClicked.listen((uri) {
        debugPrint('🏠 Widget clicked: $uri');
        
        // Handle widget interactions
        if (uri != null) {
          final action = uri.queryParameters['action'];
          final taskId = uri.queryParameters['taskId'];
          
          switch (action) {
            case 'open_app':
              // App will open automatically
              break;
            case 'toggle_task':
              if (taskId != null) {
                _handleTaskToggle(taskId);
              }
              break;
            case 'add_task':
              _handleAddTask();
              break;
          }
        }
      });
      
      debugPrint('🏠 Widget interactivity callback registered');
    } catch (e) {
      debugPrint('❌ Failed to register widget callback: $e');
    }
  }

  static void _handleTaskToggle(String taskId) {
    debugPrint('🏠 Widget task toggle requested: $taskId');
    // This would be handled by the main app when it receives the callback
  }

  static void _handleAddTask() {
    debugPrint('🏠 Widget add task requested');
    // This would be handled by the main app when it receives the callback
  }

  static Future<Map<String, dynamic>?> getWidgetData() async {
    try {
      final data = <String, dynamic>{};
      
      data['app_name'] = await HomeWidget.getWidgetData<String>('app_name');
      data['completed_today'] = await HomeWidget.getWidgetData<int>('completed_today');
      data['total_today'] = await HomeWidget.getWidgetData<int>('total_today');
      data['productivity_score'] = await HomeWidget.getWidgetData<double>('productivity_score');
      data['urgent_tasks'] = await HomeWidget.getWidgetData<int>('urgent_tasks');
      data['pending_count'] = await HomeWidget.getWidgetData<int>('pending_count');
      data['last_update'] = await HomeWidget.getWidgetData<String>('last_update');
      
      return data;
    } catch (e) {
      debugPrint('❌ Failed to get widget data: $e');
      return null;
    }
  }

  static Future<void> clearWidgetData() async {
    try {
      // Clear all widget data
      final keys = [
        'app_name', 'completed_today', 'total_today', 'productivity_score',
        'urgent_tasks', 'pending_count', 'last_update', 'last_action',
        'last_task_id', 'last_task_completed'
      ];
      
      for (final key in keys) {
        await HomeWidget.saveWidgetData<String>(key, '');
      }
      
      // Clear task data
      for (int i = 0; i < 3; i++) {
        await HomeWidget.saveWidgetData<String>('task_${i}_title', '');
        await HomeWidget.saveWidgetData<String>('task_${i}_priority', '');
        await HomeWidget.saveWidgetData<String>('task_${i}_category', '');
      }
      
      debugPrint('🏠 Widget data cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear widget data: $e');
    }
  }
}
