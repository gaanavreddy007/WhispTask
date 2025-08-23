import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/task_provider.dart';

class TaskCard extends StatelessWidget {
  final String taskId;
  final String title;
  final bool isCompleted;
  final Timestamp? createdAt;

  const TaskCard({
    super.key,
    required this.taskId,
    required this.title,
    required this.isCompleted,
    this.createdAt,
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
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: createdAt != null
            ? Text(
                'Created ${_formatDate(createdAt!.toDate())}',
                style: TextStyle(color: Colors.grey[600]),
              )
            : null,
        trailing: IconButton(
          icon: Icon(
            isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
            color: const Color(0xFFFF9800),
          ),
          onPressed: () async {
            final success = await taskProvider.toggleTask(taskId, !isCompleted);
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(taskProvider.error ?? 'Failed to update task')),
              );
            }
          },
        ),
        onLongPress: () => _showDeleteDialog(context, taskProvider),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    
    if (taskDate == today) {
      return 'today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'yesterday at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
          content: const Text('Are you sure you want to delete this task?'),
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
      final success = await taskProvider.deleteTask(taskId);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(taskProvider.error ?? 'Failed to delete task')),
        );
      }
    }
  }
}