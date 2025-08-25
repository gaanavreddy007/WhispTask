import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task; // CHANGED: Pass full Task object instead of individual fields
  
  const TaskCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
        // NEW: Add colored border for high priority or overdue reminders
        border: _getBorderColor(),
      ),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            // NEW: Reminder indicator
            if (task.hasActiveReminder) ...[
              const SizedBox(width: 8),
              _buildReminderIndicator(),
            ],
            // NEW: Priority indicator
            if (task.priority == 'high') ...[
              const SizedBox(width: 8),
              Icon(
                Icons.priority_high,
                color: Colors.red[600],
                size: 20,
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Created date
            Text(
              'Created ${_formatDate(task.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            // NEW: Due date if exists
            if (task.dueDate != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: _getDueDateColor(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due ${_formatDate(task.dueDate!)}',
                    style: TextStyle(
                      color: _getDueDateColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            // NEW: Reminder time if exists
            if (task.hasActiveReminder && task.reminderTime != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    size: 14,
                    color: _getReminderColor(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reminder ${_formatReminderTime()}',
                    style: TextStyle(
                      color: _getReminderColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            // NEW: Category tag
            if (task.category != 'general') ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: _getCategoryColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  // ignore: deprecated_member_use
                  border: Border.all(color: _getCategoryColor().withOpacity(0.3)),
                ),
                child: Text(
                  task.category.toUpperCase(),
                  style: TextStyle(
                    color: _getCategoryColor(),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NEW: Reminder actions
            if (task.hasActiveReminder && !task.isCompleted)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey[600],
                  size: 20,
                ),
                onSelected: (value) => _handleReminderAction(context, taskProvider, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'snooze_5',
                    child: Row(
                      children: [
                        Icon(Icons.snooze, size: 16),
                        SizedBox(width: 8),
                        Text('Snooze 5 min'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'snooze_15',
                    child: Row(
                      children: [
                        Icon(Icons.snooze, size: 16),
                        SizedBox(width: 8),
                        Text('Snooze 15 min'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancel_reminder',
                    child: Row(
                      children: [
                        Icon(Icons.notifications_off, size: 16),
                        SizedBox(width: 8),
                        Text('Cancel Reminder'),
                      ],
                    ),
                  ),
                ],
              ),
            // Completion toggle
            IconButton(
              icon: Icon(
                task.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                color: const Color(0xFFFF9800),
              ),
              onPressed: () async {
                // Add null check for task ID
                if (task.id == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: Task ID is missing'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final success = await taskProvider.toggleTask(task.id!, !task.isCompleted);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(taskProvider.error ?? 'Failed to update task')),
                  );
                }
              },
            ),
          ],
        ),
        onLongPress: () => _showDeleteDialog(context, taskProvider),
      ),
    );
  }

  // NEW: Build reminder indicator
  Widget _buildReminderIndicator() {
    final isOverdue = task.reminderTime != null && 
                     task.reminderTime!.isBefore(DateTime.now()) && 
                     !task.isCompleted;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red[100] : Colors.blue[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverdue ? Colors.red[300]! : Colors.blue[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning : Icons.notifications_active,
            size: 12,
            color: isOverdue ? Colors.red[700] : Colors.blue[700],
          ),
          const SizedBox(width: 2),
          Text(
            isOverdue ? 'OVERDUE' : task.reminderType.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isOverdue ? Colors.red[700] : Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Get border color based on task status
  Border? _getBorderColor() {
    // Red border for overdue reminders
    if (task.hasActiveReminder && 
        task.reminderTime != null && 
        task.reminderTime!.isBefore(DateTime.now()) && 
        !task.isCompleted) {
      return Border.all(color: Colors.red[300]!, width: 2);
    }
    
    // Orange border for high priority
    if (task.priority == 'high' && !task.isCompleted) {
      return Border.all(color: Colors.orange[300]!, width: 1);
    }
    
    return null;
  }

  // NEW: Get due date color
  Color _getDueDateColor() {
    if (task.dueDate == null || task.isCompleted) return Colors.grey[600]!;
    
    final now = DateTime.now();
    final dueDate = task.dueDate!;
    
    if (dueDate.isBefore(now)) {
      return Colors.red[600]!; // Overdue
    } else if (dueDate.difference(now).inHours <= 24) {
      return Colors.orange[600]!; // Due soon
    } else {
      return Colors.grey[600]!; // Normal
    }
  }

  // NEW: Get reminder color
  Color _getReminderColor() {
    if (!task.hasActiveReminder || task.reminderTime == null) {
      return Colors.grey[600]!;
    }
    
    final now = DateTime.now();
    final reminderTime = task.reminderTime!;
    
    if (reminderTime.isBefore(now) && !task.isCompleted) {
      return Colors.red[600]!; // Overdue reminder
    } else if (reminderTime.difference(now).inHours <= 1) {
      return Colors.orange[600]!; // Reminder soon
    } else {
      return Colors.blue[600]!; // Normal reminder
    }
  }

  // NEW: Get category color
  Color _getCategoryColor() {
    switch (task.category.toLowerCase()) {
      case 'work':
        return Colors.blue[600]!;
      case 'personal':
        return Colors.green[600]!;
      case 'shopping':
        return Colors.purple[600]!;
      case 'health':
        return Colors.red[600]!;
      case 'education':
        return Colors.indigo[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  // NEW: Format reminder time
  String _formatReminderTime() {
    if (task.reminderTime == null) return '';
    
    final now = DateTime.now();
    final reminder = task.reminderTime!;
    
    if (reminder.isBefore(now)) {
      final diff = now.difference(reminder);
      if (diff.inDays > 0) {
        return '${diff.inDays}d overdue';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h overdue';
      } else {
        return '${diff.inMinutes}m overdue';
      }
    } else {
      return _formatDate(reminder);
    }
  }

  // NEW: Handle reminder actions
  Future<void> _handleReminderAction(
    BuildContext context, 
    TaskProvider taskProvider, 
    String action
  ) async {
    switch (action) {
      case 'snooze_5':
        await taskProvider.snoozeReminder(task.id!, 5);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder snoozed for 5 minutes')),
          );
        }
        break;
      case 'snooze_15':
        await taskProvider.snoozeReminder(task.id!, 15);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder snoozed for 15 minutes')),
          );
        }
        break;
      case 'cancel_reminder':
        await taskProvider.cancelReminder(task.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder cancelled')),
          );
        }
        break;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    
    if (taskDate == today) {
      return 'today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'yesterday at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'tomorrow at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, TaskProvider taskProvider) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text(
            task.hasActiveReminder 
              ? 'This task has an active reminder. Deleting it will also cancel the reminder. Continue?'
              : 'Are you sure you want to delete this task?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      final success = await taskProvider.deleteTask(task.id!);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(taskProvider.error ?? 'Failed to delete task')),
        );
      } else if (context.mounted && task.hasActiveReminder) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task and reminder deleted successfully')),
        );
      }
    }
  }
}