import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'add_task_screen.dart';
import 'voice_input_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhispTask'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list)),
            Tab(text: 'Pending', icon: Icon(Icons.pending)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Categories')),
              const PopupMenuItem(value: 'general', child: Text('General')),
              const PopupMenuItem(value: 'work', child: Text('Work')),
              const PopupMenuItem(value: 'personal', child: Text('Personal')),
              const PopupMenuItem(value: 'health', child: Text('Health')),
              const PopupMenuItem(value: 'shopping', child: Text('Shopping')),
              const PopupMenuItem(value: 'study', child: Text('Study')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddTaskScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading && taskProvider.tasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (taskProvider.error != null && taskProvider.tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${taskProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      taskProvider.clearError();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(taskProvider, taskProvider.tasks),
              _buildTaskList(taskProvider, taskProvider.incompleteTasks),
              _buildTaskList(taskProvider, taskProvider.completedTasks),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Voice Input Button
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VoiceInputScreen(),
                ),
              );
            },
            heroTag: "voice",
            backgroundColor: Colors.red.shade400,
            child: const Icon(
              Icons.mic,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          // Regular Add Button
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTaskScreen(),
                ),
              );
            },
            heroTag: "add",
            backgroundColor: const Color(0xFF1976D2),
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(TaskProvider taskProvider, List<Task> tasks) {
    List<Task> filteredTasks = _selectedCategory == 'all' 
        ? tasks 
        : tasks.where((task) => task.category == _selectedCategory).toList();

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedCategory == 'all' ? Icons.task_alt : Icons.filter_list_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategory == 'all' 
                  ? 'No tasks yet.\nAdd your first task!' 
                  : 'No tasks in this category.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh will happen automatically via stream
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          return TaskTile(task: task);
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class TaskTile extends StatelessWidget {
  final Task task;

  const TaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showTaskDetails(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Checkbox Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) {
                      Provider.of<TaskProvider>(context, listen: false)
                          .toggleTask(task.id!, value!);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: task.isCompleted 
                                ? TextDecoration.lineThrough 
                                : TextDecoration.none,
                            color: task.isCompleted 
                                ? Colors.grey 
                                : Colors.black87,
                          ),
                        ),
                        if (task.description != null && task.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: task.isCompleted 
                                  ? Colors.grey 
                                  : Colors.black54,
                              decoration: task.isCompleted 
                                  ? TextDecoration.lineThrough 
                                  : TextDecoration.none,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddTaskScreen(taskToEdit: task),
                            ),
                          );
                          break;
                        case 'delete':
                          _showDeleteConfirmation(context, task);
                          break;
                        case 'duplicate':
                          _duplicateTask(context, task);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 18),
                            SizedBox(width: 8),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Tags Row
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildPriorityChip(task.priority),
                  _buildCategoryChip(task.category),
                  if (task.dueDate != null)
                    _buildDueDateChip(task.dueDate!),
                  if (task.isRecurring)
                    _buildRecurringChip(task.recurringPattern ?? 'recurring'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    IconData icon;
    switch (priority) {
      case 'high':
        color = Colors.red;
        icon = Icons.keyboard_arrow_up;
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.remove;
        break;
      case 'low':
        color = Colors.green;
        icon = Icons.keyboard_arrow_down;
        break;
      default:
        color = Colors.grey;
        icon = Icons.remove;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 2),
          Text(
            priority.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.blue.withOpacity(0.1),
        border: Border.all(color: Colors.blue, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getCategoryIcon(category), size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            category.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateChip(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    bool isOverdue = taskDate.isBefore(today) && !task.isCompleted;
    bool isToday = taskDate.isAtSameMomentAs(today);
    bool isTomorrow = taskDate.isAtSameMomentAs(today.add(const Duration(days: 1)));

    Color color = Colors.grey;
    String text = '${dueDate.day}/${dueDate.month}';
    IconData icon = Icons.calendar_today;

    if (isOverdue) {
      color = Colors.red;
      icon = Icons.warning;
      text = 'OVERDUE';
    } else if (isToday) {
      color = Colors.orange;
      icon = Icons.today;
      text = 'TODAY';
    } else if (isTomorrow) {
      color = Colors.blue;
      icon = Icons.calendar_today;
      text = 'TOMORROW';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringChip(String pattern) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.purple.withOpacity(0.1),
        border: Border.all(color: Colors.purple, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat, size: 12, color: Colors.purple),
          const SizedBox(width: 4),
          Text(
            pattern.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'work':
        return Icons.work;
      case 'personal':
        return Icons.person;
      case 'health':
        return Icons.health_and_safety;
      case 'shopping':
        return Icons.shopping_cart;
      case 'study':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  void _showTaskDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TaskDetailSheet(task: task),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to delete this task?'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${task.title}"',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                return TextButton(
                  onPressed: taskProvider.isDeleting ? null : () async {
                    final success = await taskProvider.deleteTask(task.id!);
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                    
                    if (success) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: taskProvider.isDeleting 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Delete'),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _duplicateTask(BuildContext context, Task originalTask) {
    final duplicatedTask = Task(
      title: '${originalTask.title} (Copy)',
      description: originalTask.description,
      createdAt: DateTime.now(),
      dueDate: originalTask.dueDate,
      priority: originalTask.priority,
      category: originalTask.category,
      color: originalTask.color,
      isRecurring: originalTask.isRecurring,
      recurringPattern: originalTask.recurringPattern,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(taskToEdit: duplicatedTask),
      ),
    );
  }
}

class TaskDetailSheet extends StatelessWidget {
  final Task task;

  const TaskDetailSheet({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          if (task.description != null && task.description!.isNotEmpty) ...[
            Text(
              task.description!,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 16),
          ],

          // Details
          _buildDetailRow('Priority', task.priority.toUpperCase()),
          _buildDetailRow('Category', task.category.toUpperCase()),
          
          if (task.dueDate != null)
            _buildDetailRow(
              'Due Date',
              '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year} at ${task.dueDate!.hour}:${task.dueDate!.minute.toString().padLeft(2, '0')}',
            ),

          if (task.isRecurring)
            _buildDetailRow(
              'Recurring',
              task.recurringPattern?.toUpperCase() ?? 'YES',
            ),

          _buildDetailRow(
            'Status',
            task.isCompleted ? 'COMPLETED' : 'PENDING',
          ),

          _buildDetailRow(
            'Created',
            '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}',
          ),

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddTaskScreen(taskToEdit: task),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Provider.of<TaskProvider>(context, listen: false)
                        .toggleTask(task.id!, !task.isCompleted);
                    Navigator.pop(context);
                  },
                  icon: Icon(task.isCompleted ? Icons.undo : Icons.check),
                  label: Text(task.isCompleted ? 'Mark Pending' : 'Mark Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: task.isCompleted ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          // Add bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          const Text(' : '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}