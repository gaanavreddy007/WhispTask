// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../l10n/app_localizations.dart';

enum CalendarViewType { month, week, day }

class TaskCalendar extends StatefulWidget {
  const TaskCalendar({super.key});

  @override
  State<TaskCalendar> createState() => _TaskCalendarState();
}

class _TaskCalendarState extends State<TaskCalendar> with TickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarViewType _viewType = CalendarViewType.month;
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fabAnimation;
  
  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );
    
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _fabAnimationController.forward();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildModernAppBar(context, theme),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  return CustomScrollView(
                    slivers: [
                      // Header spacing
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),
                      
                      // Calendar section
                      if (_viewType != CalendarViewType.day) ...[
                        SliverToBoxAdapter(
                          child: _buildModernCalendar(taskProvider, theme),
                        ),
                      ],
                      
                      // Tasks section header
                      SliverToBoxAdapter(
                        child: _buildTasksHeader(context, theme),
                      ),
                      
                      // Tasks list
                      _buildModernTasksList(taskProvider, theme),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: _buildModernFAB(context, theme),
      ),
    );
  }
  
  List<Task> _getTasksForDay(List<Task> tasks, DateTime day) {
    return tasks.where((task) {
      if (task.dueDate == null) return false;
      return _isSameDay(task.dueDate!, day);
    }).toList();
  }
  
  PreferredSizeWidget _buildModernAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF1976D2), // Blue header
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
        ),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      title: Text(
        AppLocalizations.of(context).taskCalendar,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: PopupMenuButton<CalendarViewType>(
            icon: const Icon(
              Icons.view_module,
              color: Colors.white,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (CalendarViewType type) {
              HapticFeedback.lightImpact();
              setState(() {
                _viewType = type;
              });
            },
            itemBuilder: (context) => [
              _buildPopupMenuItem(CalendarViewType.month, Icons.calendar_view_month, AppLocalizations.of(context).monthView),
              _buildPopupMenuItem(CalendarViewType.week, Icons.calendar_view_week, AppLocalizations.of(context).weekView),
              _buildPopupMenuItem(CalendarViewType.day, Icons.calendar_today, AppLocalizations.of(context).dayView),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<CalendarViewType> _buildPopupMenuItem(CalendarViewType value, IconData icon, String text) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildModernCalendar(TaskProvider taskProvider, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: TableCalendar<Task>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _viewType == CalendarViewType.week 
              ? CalendarFormat.week 
              : CalendarFormat.month,
          selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
          eventLoader: (day) => _getTasksForDay(taskProvider.tasks, day),
          startingDayOfWeek: StartingDayOfWeek.monday,
          onDaySelected: (selectedDay, focusedDay) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            weekendTextStyle: TextStyle(
              color: Colors.red.shade600,
              fontWeight: FontWeight.w600,
            ),
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            markerDecoration: BoxDecoration(
              color: Colors.blue.shade400,
              borderRadius: BorderRadius.circular(50),
            ),
            markersMaxCount: 3,
            canMarkersOverflow: true,
            defaultTextStyle: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            cellMargin: const EdgeInsets.all(4),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            leftChevronIcon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_left,
                color: theme.colorScheme.onSurface,
              ),
            ),
            rightChevronIcon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            weekendStyle: TextStyle(
              color: Colors.red.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTasksHeader(BuildContext context, ThemeData theme) {
    DateTime targetDay = _selectedDay ?? DateTime.now();
    List<Task> dayTasks = _getTasksForDay(
      Provider.of<TaskProvider>(context, listen: false).tasks, 
      targetDay
    );
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _viewType == CalendarViewType.day 
                      ? AppLocalizations.of(context).todaysTasks
                      : '${AppLocalizations.of(context).tasksFor} ${_formatDate(targetDay)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dayTasks.length} ${dayTasks.length == 1 ? 'task' : 'tasks'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (dayTasks.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${dayTasks.where((t) => t.isCompleted).length}/${dayTasks.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernTasksList(TaskProvider taskProvider, ThemeData theme) {
    DateTime targetDay = _selectedDay ?? DateTime.now();
    List<Task> dayTasks = _getTasksForDay(taskProvider.tasks, targetDay);
    
    if (dayTasks.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(theme),
      );
    }
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return RepaintBoundary(
            key: ValueKey('calendar_task_${dayTasks[index].id}'),
            child: _buildModernTaskCard(dayTasks[index], theme, index),
          );
        },
        childCount: dayTasks.length,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).noTasksForThisDay,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a new task',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTaskCard(Task task, ThemeData theme, int index) {
    final priorityColors = {
      'high': Colors.red,
      'medium': Colors.orange,
      'low': Colors.green,
    };
    
    final priorityColor = priorityColors[task.priority] ?? Colors.grey;
    
    return Container(
      margin: EdgeInsets.fromLTRB(16, index == 0 ? 8 : 4, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggleTaskCompletion(task),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Completion checkbox
                GestureDetector(
                  onTap: () => _toggleTaskCompletion(task),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? Colors.green
                          : null,
                      border: task.isCompleted
                          ? null
                          : Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.5),
                              width: 2,
                            ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: task.isCompleted
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Priority indicator
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Task content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          decoration: task.isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                      ),
                      if (task.description != null && task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                            decoration: task.isCompleted 
                                ? TextDecoration.lineThrough 
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (task.hasVoiceNotes) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.mic,
                                    size: 12,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Voice',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (task.hasAttachments) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.attach_file,
                                    size: 12,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Files',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              task.priority.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: priorityColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Actions menu
                PopupMenuButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20),
                          const SizedBox(width: 12),
                          Text(AppLocalizations.of(context).edit),
                        ],
                      ),
                      onTap: () => _editTask(task),
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 20, color: Colors.red),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context).delete,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                      onTap: () => _deleteTask(task),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFAB(BuildContext context, ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        Navigator.pushNamed(context, '/add-task');
      },
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      elevation: 8.0,
      icon: const Icon(Icons.add, size: 24),
      label: const Text(
        'Add Task',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _toggleTaskCompletion(Task task) {
    HapticFeedback.lightImpact();
    if (task.id != null) {
      Provider.of<TaskProvider>(context, listen: false).toggleTaskCompletion(task.id!);
    }
  }
  
  void _editTask(Task task) {
    // Navigate to edit screen
    Navigator.pushNamed(context, '/add-task', arguments: task);
  }
  
  void _deleteTask(Task task) {
    if (task.id != null) {
      Provider.of<TaskProvider>(context, listen: false).deleteTask(task.id!);
    }
  }
  
  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}