// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_field, avoid_print, unused_element

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../utils/notification_helper.dart';
import '../services/sentry_service.dart';
import '../l10n/app_localizations.dart';
import '../screens/add_task_screen.dart';

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

  // Cached values for performance - with safe fallbacks to prevent LateInitializationError
  Color _accentColor = const Color(0xFF1976D2);
  Color _dueDateColor = const Color(0xFFFF9800);
  Color _reminderColor = const Color(0xFF4CAF50);
  LinearGradient _cardGradient = const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)]);
  Border? _border;
  ThemeData _theme = ThemeData.light(); // Safe default theme
  
  // Cached formatted strings - initialized as nullable to prevent LateInitializationError
  String? _cachedDueDateString;
  String? _cachedReminderString;
  String? _cachedRelativeDateString;

  @override
  void initState() {
    super.initState();
    
    // Reduced Sentry logging for performance - only log errors
    try {
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
    } catch (e, stackTrace) {
      // Only log critical errors to reduce overhead
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error initializing TaskCard animation controller',
        extra: {
          'task_id': widget.task.id,
          'widget': 'TaskCard',
        },
      );
    }
  }

  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize theme and colors here as it depends on context
    if (!_isInitialized) {
      try {
        _theme = Theme.of(context);
        _calculateColors();
        _initializeCachedStrings();
        _isInitialized = true;
      } catch (e) {
        // Fallback initialization to prevent crashes
        _theme = ThemeData.light();
        _isInitialized = true;
      }
    }
  }

  void _calculateColors() {
    _accentColor = _getAccentColor();
    _dueDateColor = _getDueDateColor();
    _reminderColor = _getReminderColor();
    _cardGradient = _getCardGradient();
    _border = _getBorderDecoration();
  }

  void _initializeCachedStrings() {
    try {
      // Initialize cached due date string
      if (widget.task.dueDate != null) {
        _cachedDueDateString = DateFormat('MMM dd, yyyy').format(widget.task.dueDate!);
      }
      
      // Initialize cached reminder string
      if (widget.task.hasActiveReminder && widget.task.reminderTime != null) {
        _cachedReminderString = '${AppLocalizations.of(context).reminder} ${DateFormat('MMM dd, HH:mm').format(widget.task.reminderTime!)}';
      }
      
      // Initialize cached relative date string
      final referenceDate = widget.task.updatedAt ?? widget.task.createdAt;
      final now = DateTime.now();
      final difference = now.difference(referenceDate);
      
      if (difference.inDays > 0) {
        _cachedRelativeDateString = '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        _cachedRelativeDateString = '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        _cachedRelativeDateString = '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        _cachedRelativeDateString = 'Just now';
      }
    } catch (e) {
      // Fallback to prevent crashes - set to null if initialization fails
      _cachedDueDateString = null;
      _cachedReminderString = null;
      _cachedRelativeDateString = null;
    }
  }

  @override
  void dispose() {
    SentryService.logWidgetLifecycle('TaskCard', 'dispose', data: {
      'task_id': widget.task.id,
    });
    
    try {
      _animationController.dispose();
      SentryService.logWidgetLifecycle('TaskCard', 'animation_controller_disposed');
      super.dispose();
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error disposing TaskCard',
        extra: {
          'task_id': widget.task.id,
          'widget': 'TaskCard',
        },
      );
      super.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) {
          SentryService.logUIEvent('task_card_tap_down', data: {
            'task_id': widget.task.id,
            'task_title': widget.task.title,
            'task_completed': widget.task.isCompleted.toString(),
          });
          setState(() => _isPressed = true);
          _animationController.forward();
        },
        onTapUp: (_) {
          SentryService.logUIEvent('task_card_tap_up', data: {
            'task_id': widget.task.id,
            'task_title': widget.task.title,
            'has_callback': (widget.onTap != null).toString(),
          });
          setState(() => _isPressed = false);
          _animationController.reverse();
          
          try {
            widget.onTap?.call();
            SentryService.logUIEvent('task_card_callback_executed', data: {
              'task_id': widget.task.id,
            });
          } catch (e, stackTrace) {
            SentryService.captureException(
              e,
              stackTrace: stackTrace,
              hint: 'Error executing TaskCard onTap callback',
              extra: {
                'task_id': widget.task.id,
                'widget': 'TaskCard',
              },
            );
          }
        },
        onTapCancel: () {
          SentryService.logUIEvent('task_card_tap_cancel', data: {
            'task_id': widget.task.id,
          });
          setState(() => _isPressed = false);
          _animationController.reverse();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: _cardGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: _theme.colorScheme.shadow.withOpacity(0.12),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
            border: _border,
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
                    left: widget.task.color != null ? 24 : 20,
                    right: 20,
                    top: 20,
                    bottom: 20,
                  ),
                  child: _buildCardContent(taskProvider),
                ),
                
                // Completion overlay
                if (widget.task.isCompleted)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 48,
                                color: _theme.colorScheme.primary,
                              ),
                              Text(
                                AppLocalizations.of(context).completed,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
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
  }

  // --- Refactored Build Methods for Clarity and Performance ---

  Widget _buildCardContent(TaskProvider taskProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderRow(taskProvider),
        if (widget.task.description?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _buildDescription(),
        ],
        const SizedBox(height: 16),
        if (widget.task.tags.isNotEmpty) ...[
          _buildTags(),
          const SizedBox(height: 12),
        ],
        _buildFooterRow(),
      ],
    );
  }

  Widget _buildHeaderRow(TaskProvider taskProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompletionCheckbox(taskProvider),
        const SizedBox(width: 16),
        Expanded(child: _buildTitle()),
        const SizedBox(width: 12),
        _buildStatusIndicators(taskProvider),
      ],
    );
  }

  Widget _buildCompletionCheckbox(TaskProvider taskProvider) {
    return GestureDetector(
      onTap: () => _toggleTaskCompletion(taskProvider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: widget.task.isCompleted ? _accentColor : Colors.transparent,
          border: Border.all(
            color: widget.task.isCompleted ? _accentColor : _theme.colorScheme.outline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: widget.task.isCompleted
            ? Icon(Icons.check, size: 16, color: _theme.colorScheme.onPrimary)
            : null,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.task.title,
      style: _theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: widget.task.isCompleted ? _theme.colorScheme.onSurface.withOpacity(0.6) : _theme.colorScheme.onSurface,
        decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
        decorationColor: _theme.colorScheme.outline,
      ),
    );
  }

  Widget _buildStatusIndicators(TaskProvider taskProvider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.task.isRecurring)
          _buildStatusChip(
            icon: Icons.repeat,
            label: AppLocalizations.of(context).recurringLabel,
            color: _theme.colorScheme.tertiary,
          ),
        if (widget.task.priority == 'high')
          _buildStatusChip(
            icon: Icons.priority_high,
            label: AppLocalizations.of(context).high,
            color: _theme.colorScheme.error,
          ),
        if (widget.task.hasActiveReminder) _buildReminderChip(),
        _buildOptionsMenu(taskProvider),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.task.description!,
      style: _theme.textTheme.bodyMedium?.copyWith(
        color: widget.task.isCompleted ? _theme.colorScheme.onSurface.withOpacity(0.4) : _theme.colorScheme.onSurfaceVariant,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.task.tags.take(4).map((tag) => _buildTag(tag)).toList(),
    );
  }

  Widget _buildFooterRow() {
    return Row(
      children: [
        _buildVoiceNotesIndicator(widget.task),
        if (widget.task.category != 'general') ...[
          if (widget.task.voiceNotes.isNotEmpty) const SizedBox(width: 8),
          _buildCategoryChip(),
        ],
        const Spacer(),
        _buildDateInfo(),
      ],
    );
  }

  Widget _buildCategoryChip() {
    final categoryColor = NotificationHelper.getCategoryColor(widget.task.category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: categoryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            NotificationHelper.getCategoryIcon(widget.task.category),
            size: 12,
            color: categoryColor,
          ),
          const SizedBox(width: 4),
          Text(
            widget.task.category.toUpperCase(),
            style: TextStyle(
              color: categoryColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.task.dueDate != null && _cachedDueDateString != null)
          _buildDateChip(
            icon: Icons.schedule,
            label: '${AppLocalizations.of(context).due} $_cachedDueDateString',
            color: _dueDateColor,
          ),
        if (widget.task.hasActiveReminder && widget.task.reminderTime != null && _cachedReminderString != null) ...[
          const SizedBox(height: 4),
          _buildDateChip(
            icon: Icons.notifications,
            label: _cachedReminderString!,
            color: _reminderColor,
          ),
        ],
        if (widget.showAnalytics && _cachedRelativeDateString != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.task.updatedAt != null
                ? '${AppLocalizations.of(context).updated} $_cachedRelativeDateString'
                : '${AppLocalizations.of(context).created} $_cachedRelativeDateString',
            style: _theme.textTheme.bodySmall?.copyWith(
              color: _theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
        ],
      ],
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
      color = _theme.colorScheme.error;
      label = AppLocalizations.of(context).overdue;
      icon = Icons.warning;
    } else if (isSoon) {
      color = _theme.colorScheme.errorContainer;
      label = AppLocalizations.of(context).soon;
      icon = Icons.notifications_active;
    } else {
      color = _theme.colorScheme.primary;
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
        color: _theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _theme.colorScheme.outline),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: _theme.colorScheme.onSurfaceVariant,
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
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: _theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) => _handleMenuAction(context, taskProvider, value),
        splashRadius: 20,
        itemBuilder: (context) => [
        // Edit option
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16, color: _theme.colorScheme.primary),
              SizedBox(width: 12),
              Text(AppLocalizations.of(context).edit),
            ],
          ),
        ),
        
        // Duplicate option
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy, size: 16, color: _theme.colorScheme.secondary),
              SizedBox(width: 12),
              Text(AppLocalizations.of(context).duplicate),
            ],
          ),
        ),
        
        // Reminder actions (if has active reminder)
        if (widget.task.hasActiveReminder && !widget.task.isCompleted) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'snooze_5',
            child: Row(
              children: [
                Icon(Icons.snooze, size: 16, color: _theme.colorScheme.tertiary),
                SizedBox(width: 12),
                Text(AppLocalizations.of(context).snooze5min),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'snooze_30',
            child: Row(
              children: [
                Icon(Icons.snooze, size: 16, color: _theme.colorScheme.tertiary),
                SizedBox(width: 12),
                Text(AppLocalizations.of(context).snooze30min),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'snooze_1h',
            child: Row(
              children: [
                Icon(Icons.access_time, size: 16, color: _theme.colorScheme.tertiary),
                SizedBox(width: 12),
                Text(AppLocalizations.of(context).snooze1hour),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'cancel_reminder',
            child: Row(
              children: [
                Icon(Icons.notifications_off, size: 16, color: _theme.colorScheme.outline),
                SizedBox(width: 12),
                Text(AppLocalizations.of(context).cancel),
              ],
            ),
          ),
        ],
        
        // Add reminder (if no active reminder)
        if (!widget.task.hasActiveReminder) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'add_reminder',
            child: Row(
              children: [
                Icon(Icons.add_alert, size: 16, color: _theme.colorScheme.primary),
                SizedBox(width: 12),
                Text(AppLocalizations.of(context).setReminder),
              ],
            ),
          ),
        ],
        
        // Delete option
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: _theme.colorScheme.error),
              SizedBox(width: 12),
              Text(AppLocalizations.of(context).delete),
            ],
          ),
        ),
      ],
      ),
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
      return '${AppLocalizations.of(context).today} ${_formatTime(date)}';
    } else if (dayDiff == -1) {
      return '${AppLocalizations.of(context).yesterday} ${_formatTime(date)}';
    } else if (dayDiff == 1) {
      return '${AppLocalizations.of(context).tomorrow} ${_formatTime(date)}';
    } else if (dayDiff > 1 && dayDiff <= 7) {
      return '${AppLocalizations.of(context).inTime} ${dayDiff}d ${_formatTime(date)}';
    } else if (dayDiff < -1 && dayDiff >= -7) {
      return '${dayDiff.abs()}d ${AppLocalizations.of(context).ago}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Format relative date for analytics
  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ${AppLocalizations.of(context).ago}';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ${AppLocalizations.of(context).ago}';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ${AppLocalizations.of(context).ago}';
    } else {
      return AppLocalizations.of(context).justNow;
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
          SnackBar(
            content: Text(AppLocalizations.of(context).errorTaskIdMissing),
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
    
    // Use post frame callback to ensure UI updates happen after current frame
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            if (!success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(taskProvider.error ?? AppLocalizations.of(context).failedToUpdateTask),
                  backgroundColor: Colors.red,
                ),
              );
            } else {
              // Show appropriate feedback based on the NEW state (opposite of current state)
              final message = widget.task.isRecurring 
                      ? AppLocalizations.of(context).taskCompletedNextOccurrence
                      : AppLocalizations.of(context).taskCompleted;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            // Silently handle any remaining context errors
            print('TaskCard: Task completion post-frame callback error: $e');
          }
        }
      });
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTaskScreen(taskToEdit: widget.task),
          ),
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                        ? AppLocalizations.of(context).taskDuplicatedSuccess
                        : AppLocalizations.of(context).failedToDuplicateTask),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              } catch (e) {
                print('TaskCard: Duplicate task post-frame callback error: $e');
              }
            }
          });
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).reminderCancelled)),
                );
              } catch (e) {
                print('TaskCard: Cancel reminder post-frame callback error: $e');
              }
            }
          });
        }
        break;
        
      case 'add_reminder':
        await _showAddReminderDialog(context, taskProvider);
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success 
                    ? '${AppLocalizations.of(context).reminderSnoozedMinutes} $minutes ${AppLocalizations.of(context).minutes}'
                    : AppLocalizations.of(context).failedToSnoozeReminder),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          } catch (e) {
            print('TaskCard: Snooze reminder post-frame callback error: $e');
          }
        }
      });
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
              Text(AppLocalizations.of(context).deleteTask),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${AppLocalizations.of(context).confirmDeleteTask} "${widget.task.title}"?'),
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
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).willCancelActiveReminder,
                          style: const TextStyle(fontSize: 12),
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
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).willStopFutureRecurring,
                          style: const TextStyle(fontSize: 12),
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
                AppLocalizations.of(context).cancel,
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
              child: Text(AppLocalizations.of(context).delete),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      // Check if task ID is valid
      if (widget.task.id == null || widget.task.id!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text(AppLocalizations.of(context).failedToDeleteTask),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
        return;
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(AppLocalizations.of(context).deletingTask),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      bool success = false;
      try {
        success = await taskProvider.deleteTask(widget.task.id!);
      } catch (e) {
        success = false;
        // Log the error for debugging
        print('Delete task error: $e');
      }
      
      // Clear the loading snackbar and show result - only if still mounted
      // Use post frame callback to ensure UI updates happen after current frame
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
              final messenger = ScaffoldMessenger.of(context);
              messenger.clearSnackBars();
              
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
                          ? AppLocalizations.of(context).taskDeletedSuccess
                          : taskProvider.error ?? AppLocalizations.of(context).failedToDeleteTask),
                    ],
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            } catch (e) {
              // Silently handle any remaining context errors
              print('TaskCard: Post-frame callback error: $e');
            }
          }
        });
      }
    }
  }

  // Show add reminder dialog
  Future<void> _showAddReminderDialog(BuildContext context, TaskProvider taskProvider) async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.add_alert, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(AppLocalizations.of(context).setReminder),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${AppLocalizations.of(context).setReminderFor} "${widget.task.title}"'),
                  const SizedBox(height: 16),
                  
                  // Date picker
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(selectedDate != null 
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : AppLocalizations.of(context).selectDate),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                  ),
                  
                  // Time picker
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(selectedTime != null 
                        ? selectedTime!.format(context)
                        : AppLocalizations.of(context).selectTime),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() => selectedTime = time);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(AppLocalizations.of(context).cancel),
                ),
                ElevatedButton(
                  onPressed: selectedDate != null && selectedTime != null
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  child: Text(AppLocalizations.of(context).setReminder),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && selectedDate != null && selectedTime != null && mounted) {
      final reminderDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      final updatedTask = widget.task.copyWith(
        hasReminder: true,
        isReminderActive: true,
        reminderTime: reminderDateTime,
        reminderType: 'once',
        notificationId: widget.task.id?.hashCode.abs(),
      );

      final success = await taskProvider.updateTask(updatedTask);
      
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success 
                      ? '${AppLocalizations.of(context).reminderSetFor} ${selectedTime!.format(context)} on ${selectedDate!.day}/${selectedDate!.month}'
                      : AppLocalizations.of(context).failedToSetReminder),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            } catch (e) {
              print('TaskCard: Add reminder post-frame callback error: $e');
            }
          }
        });
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