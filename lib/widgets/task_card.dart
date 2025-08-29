// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_field

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../utils/notification_helper.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final bool showAnalytics;
  final VoidCallback? onTap;
  
  const TaskCard({
    super.key,
    required this.task,
    this.showAnalytics = false,
    this.onTap,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              _animationController.forward();
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _animationController.reverse();
              widget.onTap?.call();
            },
            onTapCancel: () {
              setState(() => _isPressed = false);
              _animationController.reverse();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: _getCardGradient(),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getAccentColor().withOpacity(0.1),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: _getBorderDecoration(),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Color accent bar
                    if (widget.task.color != null)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: _parseColor(widget.task.color!),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    
                    // Main content
                    Padding(
                      padding: EdgeInsets.only(
                        left: widget.task.color != null ? 20 : 16,
                        right: 16,
                        top: 16,
                        bottom: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row with title and status indicators
                          Row(
                            children: [
                              // Completion checkbox
                              GestureDetector(
                                onTap: () => _toggleTaskCompletion(taskProvider),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: widget.task.isCompleted 
                                        ? _getAccentColor()
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: widget.task.isCompleted 
                                          ? _getAccentColor()
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: widget.task.isCompleted
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Title
                              Expanded(
                                child: Text(
                                  widget.task.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: widget.task.isCompleted 
                                        ? Colors.grey[500]
                                        : theme.colorScheme.onSurface,
                                    decoration: widget.task.isCompleted 
                                        ? TextDecoration.lineThrough 
                                        : null,
                                    decorationColor: Colors.grey[400],
                                  ),
                                ),
                              ),
                              
                              // Status indicators row
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Recurring indicator
                                  if (widget.task.isRecurring)
                                    _buildStatusChip(
                                      icon: Icons.repeat,
                                      label: 'RECURRING',
                                      color: Colors.purple,
                                    ),
                                  
                                  // Priority indicator
                                  if (widget.task.priority == 'high')
                                    _buildStatusChip(
                                      icon: Icons.priority_high,
                                      label: 'HIGH',
                                      color: Colors.red,
                                    ),
                                  
                                  // Reminder indicator
                                  if (widget.task.hasActiveReminder)
                                    _buildReminderChip(),
                                  
                                  // Options menu
                                  _buildOptionsMenu(taskProvider),
                                ],
                              ),
                            ],
                          ),
                          
                          // Description if exists
                          if (widget.task.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.task.description!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: widget.task.isCompleted 
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          
                          const SizedBox(height: 12),
                          
                          // Tags section
                          if (widget.task.tags.isNotEmpty) ...[
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: widget.task.tags.take(4).map((tag) => 
                                _buildTag(tag)
                              ).toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                          
                          // Bottom row with dates and category
                          Row(
                            children: [
                              // Voice notes indicator
                              _buildVoiceNotesIndicator(widget.task),
                              
                              // Category chip  
                              if (widget.task.category != 'general') ...[
                                if (widget.task.voiceNotes.isNotEmpty) const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8, 
                                    vertical: 4
                                  ),
                                  decoration: BoxDecoration(
                                    color: NotificationHelper.getCategoryColor(widget.task.category).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: NotificationHelper.getCategoryColor(widget.task.category).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        NotificationHelper.getCategoryIcon(widget.task.category),
                                        size: 12,
                                        color: NotificationHelper.getCategoryColor(widget.task.category),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.task.category.toUpperCase(),
                                        style: TextStyle(
                                          color: NotificationHelper.getCategoryColor(widget.task.category),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              
                              const Spacer(),
                              
                              // Date info
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Due date
                                  if (widget.task.dueDate != null)
                                    _buildDateChip(
                                      icon: Icons.schedule,
                                      label: 'Due ${_formatDate(widget.task.dueDate!)}',
                                      color: _getDueDateColor(),
                                    ),
                                  
                                  // Reminder time
                                  if (widget.task.hasActiveReminder && 
                                      widget.task.reminderTime != null) ...[
                                    const SizedBox(height: 4),
                                    _buildDateChip(
                                      icon: Icons.notifications,
                                      label: _formatReminderTime(),
                                      color: _getReminderColor(),
                                    ),
                                  ],
                                  
                                  // Created/Updated info
                                  if (widget.showAnalytics) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.task.updatedAt != null 
                                          ? 'Updated ${_formatRelativeDate(widget.task.updatedAt!)}'
                                          : 'Created ${_formatRelativeDate(widget.task.createdAt)}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[500],
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Completion overlay
                    if (widget.task.isCompleted)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.check_circle,
                              size: 48,
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Build status chip widget
  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Build enhanced reminder chip
  Widget _buildReminderChip() {
    final isOverdue = widget.task.reminderTime != null && 
                     widget.task.reminderTime!.isBefore(DateTime.now()) && 
                     !widget.task.isCompleted;
    
    final isSoon = widget.task.reminderTime != null &&
                   widget.task.reminderTime!.difference(DateTime.now()).inHours <= 1 &&
                   widget.task.reminderTime!.isAfter(DateTime.now());

    Color color;
    String label;
    IconData icon;

    if (isOverdue) {
      color = Colors.red;
      label = 'OVERDUE';
      icon = Icons.warning;
    } else if (isSoon) {
      color = Colors.orange;
      label = 'SOON';
      icon = Icons.notifications_active;
    } else {
      color = Colors.blue;
      label = widget.task.reminderType.toUpperCase();
      icon = Icons.notifications;
    }

    return _buildStatusChip(
      icon: icon,
      label: label,
      color: color,
    );
  }

  // Build tag widget
  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  // Build date chip widget
  Widget _buildDateChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  // Build options menu
  Widget _buildOptionsMenu(TaskProvider taskProvider) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Colors.grey[600],
        size: 20,
      ),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) => _handleMenuAction(context, taskProvider, value),
      itemBuilder: (context) => [
        // Edit option
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16, color: Colors.blue),
              SizedBox(width: 12),
              Text('Edit Task'),
            ],
          ),
        ),
        
        // Duplicate option
        const PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy, size: 16, color: Colors.green),
              SizedBox(width: 12),
              Text('Duplicate'),
            ],
          ),
        ),
        
        // Reminder actions (if has active reminder)
        if (widget.task.hasActiveReminder && !widget.task.isCompleted) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'snooze_5',
            child: Row(
              children: [
                Icon(Icons.snooze, size: 16, color: Colors.orange),
                SizedBox(width: 12),
                Text('Snooze 5 min'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'snooze_30',
            child: Row(
              children: [
                Icon(Icons.snooze, size: 16, color: Colors.orange),
                SizedBox(width: 12),
                Text('Snooze 30 min'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'snooze_1h',
            child: Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.orange),
                SizedBox(width: 12),
                Text('Snooze 1 hour'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'cancel_reminder',
            child: Row(
              children: [
                Icon(Icons.notifications_off, size: 16, color: Colors.grey),
                SizedBox(width: 12),
                Text('Cancel Reminder'),
              ],
            ),
          ),
        ],
        
        // Add reminder (if no active reminder)
        if (!widget.task.hasActiveReminder) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'add_reminder',
            child: Row(
              children: [
                Icon(Icons.add_alert, size: 16, color: Colors.blue),
                SizedBox(width: 12),
                Text('Add Reminder'),
              ],
            ),
          ),
        ],
        
        // Delete option
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: Colors.red),
              SizedBox(width: 12),
              Text('Delete'),
            ],
          ),
        ),
      ],
    );
  }

  // Get card gradient based on task properties
  LinearGradient _getCardGradient() {
    if (widget.task.isCompleted) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey[50]!,
          Colors.grey[100]!,
        ],
      );
    }

    final baseColor = widget.task.color != null 
        ? _parseColor(widget.task.color!)
        : _getAccentColor();

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(0.15),
        baseColor.withOpacity(0.05),
      ],
    );
  }

  // Get border decoration
  Border? _getBorderDecoration() {
    // Red border for overdue reminders
    if (widget.task.hasActiveReminder && 
        widget.task.reminderTime != null && 
        widget.task.reminderTime!.isBefore(DateTime.now()) && 
        !widget.task.isCompleted) {
      return Border.all(color: Colors.red[400]!, width: 2);
    }
    
    // Orange border for high priority
    if (widget.task.priority == 'high' && !widget.task.isCompleted) {
      return Border.all(color: Colors.orange[300]!, width: 1.5);
    }
    
    // Subtle border for completed tasks
    if (widget.task.isCompleted) {
      return Border.all(color: Colors.grey[200]!, width: 1);
    }
    
    return Border.all(color: Colors.grey[100]!, width: 1);
  }

  // Get accent color based on task properties
  Color _getAccentColor() {
    if (widget.task.color != null) {
      return _parseColor(widget.task.color!);
    }
    
    // Default accent based on priority and category
    if (widget.task.priority == 'high') return Colors.red[600]!;
    return NotificationHelper.getCategoryColor(widget.task.category);
  }

  // Parse color from string
  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      } else if (colorString.startsWith('0x')) {
        return Color(int.parse(colorString));
      } else {
        // Named colors
        switch (colorString.toLowerCase()) {
          case 'red': return Colors.red[600]!;
          case 'blue': return Colors.blue[600]!;
          case 'green': return Colors.green[600]!;
          case 'orange': return Colors.orange[600]!;
          case 'purple': return Colors.purple[600]!;
          case 'teal': return Colors.teal[600]!;
          case 'pink': return Colors.pink[600]!;
          case 'yellow': return Colors.yellow[700]!;
          case 'indigo': return Colors.indigo[600]!;
          case 'cyan': return Colors.cyan[600]!;
          default: return Colors.blue[600]!;
        }
      }
    } catch (e) {
      return Colors.blue[600]!;
    }
  }


  // Get due date color with urgency levels
  Color _getDueDateColor() {
    if (widget.task.dueDate == null || widget.task.isCompleted) {
      return Colors.grey[500]!;
    }
    
    final now = DateTime.now();
    final dueDate = widget.task.dueDate!;
    final hoursUntilDue = dueDate.difference(now).inHours;
    
    if (hoursUntilDue < 0) {
      return Colors.red[600]!; // Overdue
    } else if (hoursUntilDue <= 2) {
      return Colors.red[500]!; // Very urgent
    } else if (hoursUntilDue <= 24) {
      return Colors.orange[600]!; // Due soon
    } else if (hoursUntilDue <= 72) {
      return Colors.amber[600]!; // Due this week
    } else {
      return Colors.grey[600]!; // Normal
    }
  }

  // Get reminder color with urgency levels
  Color _getReminderColor() {
    if (!widget.task.hasActiveReminder || widget.task.reminderTime == null) {
      return Colors.grey[500]!;
    }
    
    final now = DateTime.now();
    final reminderTime = widget.task.reminderTime!;
    final minutesUntilReminder = reminderTime.difference(now).inMinutes;
    
    if (minutesUntilReminder < 0) {
      return Colors.red[600]!; // Overdue reminder
    } else if (minutesUntilReminder <= 15) {
      return Colors.orange[600]!; // Very soon
    } else if (minutesUntilReminder <= 60) {
      return Colors.amber[600]!; // Soon
    } else {
      return Colors.blue[600]!; // Normal
    }
  }

  // Format reminder time with relative info
  String _formatReminderTime() {
    if (widget.task.reminderTime == null) return '';
    
    final now = DateTime.now();
    final reminder = widget.task.reminderTime!;
    
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
      final diff = reminder.difference(now);
      if (diff.inDays > 0) {
        return 'in ${diff.inDays}d';
      } else if (diff.inHours > 0) {
        return 'in ${diff.inHours}h';
      } else {
        return 'in ${diff.inMinutes}m';
      }
    }
  }

  // Format date with smart relative formatting
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    
    final dayDiff = taskDate.difference(today).inDays;
    
    if (dayDiff == 0) {
      return 'today ${_formatTime(date)}';
    } else if (dayDiff == -1) {
      return 'yesterday ${_formatTime(date)}';
    } else if (dayDiff == 1) {
      return 'tomorrow ${_formatTime(date)}';
    } else if (dayDiff > 1 && dayDiff <= 7) {
      return 'in ${dayDiff}d ${_formatTime(date)}';
    } else if (dayDiff < -1 && dayDiff >= -7) {
      return '${dayDiff.abs()}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Format relative date for analytics
  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  // Format time
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Toggle task completion
  Future<void> _toggleTaskCompletion(TaskProvider taskProvider) async {
    if (widget.task.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Task ID is missing'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    final success = await taskProvider.toggleTask(
      widget.task.id!, 
      !widget.task.isCompleted
    );
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taskProvider.error ?? 'Failed to update task'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (success && mounted) {
      // Show appropriate feedback
      final message = widget.task.isCompleted 
          ? 'Task marked as incomplete'
          : widget.task.isRecurring 
              ? 'Task completed! Next occurrence created'
              : 'Task completed!';
              
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Handle menu actions
  Future<void> _handleMenuAction(
    BuildContext context, 
    TaskProvider taskProvider, 
    String action
  ) async {
    switch (action) {
      case 'edit':
        // Navigate to edit screen (implement based on your navigation)
        // Navigator.pushNamed(context, '/edit_task', arguments: widget.task);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit feature coming soon!')),
        );
        break;
        
      case 'duplicate':
        final duplicatedTask = Task(
          title: '${widget.task.title} (Copy)',
          description: widget.task.description,
          createdAt: DateTime.now(),
          category: widget.task.category,
          priority: widget.task.priority,
          dueDate: widget.task.dueDate,
          tags: List.from(widget.task.tags),
          color: widget.task.color,
          isRecurring: false, // Don't duplicate recurring settings
        );
        
        final success = await taskProvider.addTask(duplicatedTask);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success 
                  ? 'Task duplicated successfully!'
                  : 'Failed to duplicate task'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
        break;
        
      case 'snooze_5':
        await _snoozeReminder(taskProvider, 5);
        break;
      case 'snooze_30':
        await _snoozeReminder(taskProvider, 30);
        break;
      case 'snooze_1h':
        await _snoozeReminder(taskProvider, 60);
        break;
        
      case 'cancel_reminder':
        await taskProvider.cancelReminder(widget.task.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder cancelled')),
          );
        }
        break;
        
      case 'add_reminder':
        // Navigate to add reminder screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add reminder feature coming soon!')),
        );
        break;
        
      case 'delete':
        await _showDeleteDialog(context, taskProvider);
        break;
    }
  }

  // Snooze reminder helper
  Future<void> _snoozeReminder(TaskProvider taskProvider, int minutes) async {
    final success = await taskProvider.snoozeReminder(widget.task.id!, minutes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Reminder snoozed for $minutes minutes'
              : 'Failed to snooze reminder'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  // Show delete confirmation dialog
  Future<void> _showDeleteDialog(BuildContext context, TaskProvider taskProvider) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red[600]),
              const SizedBox(width: 8),
              const Text('Delete Task'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete "${widget.task.title}"?'),
              if (widget.task.hasActiveReminder) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'This will also cancel the active reminder.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.task.isRecurring) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.repeat, size: 16, color: Colors.purple[700]),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'This will stop all future recurring instances.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      // Show loading indicator
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Deleting task...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final success = await taskProvider.deleteTask(widget.task.id!);
      
      // Clear the loading snackbar
      messenger.clearSnackBars();
      
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(success 
                    ? 'Task deleted successfully!'
                    : taskProvider.error ?? 'Failed to delete task'),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Widget _buildVoiceNotesIndicator(Task task) {
    if (task.voiceNotes.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.purple[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic, size: 12, color: Colors.purple[700]),
          const SizedBox(width: 4),
          Text(
            '${task.voiceNotes.length}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.purple[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}