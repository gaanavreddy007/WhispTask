// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

enum CalendarViewType { month, week, day }

class TaskCalendar extends StatefulWidget {
  const TaskCalendar({super.key});

  @override
  State<TaskCalendar> createState() => _TaskCalendarState();
}

class _TaskCalendarState extends State<TaskCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarViewType _viewType = CalendarViewType.month;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Calendar'),
        actions: [
          PopupMenuButton<CalendarViewType>(
            icon: const Icon(Icons.view_module),
            onSelected: (CalendarViewType type) {
              setState(() {
                _viewType = type;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: CalendarViewType.month, child: Text('Month View')),
              const PopupMenuItem(value: CalendarViewType.week, child: Text('Week View')),
              const PopupMenuItem(value: CalendarViewType.day, child: Text('Day View')),
            ],
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return Column(
            children: [
              if (_viewType != CalendarViewType.day) ...[
                TableCalendar<Task>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _viewType == CalendarViewType.week 
                      ? CalendarFormat.week 
                      : CalendarFormat.month,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: (day) => _getTasksForDay(taskProvider.tasks, day),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
              
              // Day view or selected day tasks
              Expanded(
                child: _buildTaskList(taskProvider),
              ),
            ],
          );
        },
      ),
    );
  }
  
  List<Task> _getTasksForDay(List<Task> tasks, DateTime day) {
    return tasks.where((task) {
      if (task.dueDate == null) return false;
      return isSameDay(task.dueDate!, day);
    }).toList();
  }
  
  Widget _buildTaskList(TaskProvider taskProvider) {
    DateTime targetDay = _selectedDay ?? DateTime.now();
    List<Task> dayTasks = _getTasksForDay(taskProvider.tasks, targetDay);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            _viewType == CalendarViewType.day 
                ? "Today's Tasks"
                : 'Tasks for ${targetDay.day}/${targetDay.month}/${targetDay.year}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: dayTasks.isEmpty
              ? const Center(child: Text('No tasks for this day'))
              : ListView.builder(
                  itemCount: dayTasks.length,
                  itemBuilder: (context, index) {
                    return _buildTaskCard(dayTasks[index]);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: task.isCompleted ? Colors.green : Colors.grey,
        ),
        title: Text(task.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty) Text(task.description!),
            Row(
              children: [
                if (task.hasVoiceNotes) 
                  const Icon(Icons.mic, size: 16, color: Colors.blue),
                if (task.hasAttachments) 
                  const Icon(Icons.attach_file, size: 16, color: Colors.orange),
                Text('Priority: ${task.priority}'),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Edit'),
              onTap: () => _editTask(task),
            ),
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: () => _deleteTask(task),
            ),
          ],
        ),
      ),
    );
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
}