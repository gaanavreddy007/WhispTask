import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? taskToEdit;

  const AddTaskScreen({super.key, this.taskToEdit});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _priority = 'medium';
  String _category = 'general';
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _isRecurring = false;
  String? _recurringPattern;

  final List<String> _priorities = ['high', 'medium', 'low'];
  final List<String> _categories = ['general', 'work', 'personal', 'health', 'shopping', 'study'];
  final List<String> _recurringPatterns = ['daily', 'weekly', 'monthly'];

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      _populateFields(widget.taskToEdit!);
    }
  }

  void _populateFields(Task task) {
    _titleController.text = task.title;
    _descriptionController.text = task.description ?? '';
    _priority = task.priority;
    _category = task.category;
    _dueDate = task.dueDate;
    if (task.dueDate != null) {
      _dueTime = TimeOfDay.fromDateTime(task.dueDate!);
    }
    _isRecurring = task.isRecurring;
    _recurringPattern = task.recurringPattern;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskToEdit == null ? 'Add Task' : 'Edit Task'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              return IconButton(
                icon: taskProvider.isCreating || taskProvider.isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check),
                onPressed: taskProvider.isCreating || taskProvider.isUpdating
                    ? null
                    : _saveTask,
              );
            },
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Error message
                  if (taskProvider.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              taskProvider.error!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: taskProvider.clearError,
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ),

                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title *',
                      hintText: 'Enter your task...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.task),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a task title';
                      }
                      if (value.length > 100) {
                        return 'Title must be less than 100 characters';
                      }
                      return null;
                    },
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Add more details...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    maxLength: 500,
                    validator: (value) {
                      if (value != null && value.length > 500) {
                        return 'Description must be less than 500 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Priority and Category Row
                  Row(
                    children: [
                      // Priority Dropdown
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _priority,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.flag),
                          ),
                          items: _priorities.map((priority) {
                            return DropdownMenuItem(
                              value: priority,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(priority),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(priority.toUpperCase()),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _priority = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Category Dropdown
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(_getCategoryIcon(category), size: 16),
                                  const SizedBox(width: 8),
                                  Text(category.toUpperCase()),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _category = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Due Date and Time
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Due Date & Time',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          
                          // Date Picker
                          ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: Text(_dueDate == null 
                                ? 'No due date set' 
                                : 'Date: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
                            trailing: _dueDate != null 
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _dueDate = null;
                                        _dueTime = null;
                                      });
                                    },
                                  )
                                : null,
                            onTap: _selectDueDate,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          
                          if (_dueDate != null) ...[
                            const SizedBox(height: 8),
                            // Time Picker
                            ListTile(
                              leading: const Icon(Icons.access_time),
                              title: Text(_dueTime == null 
                                  ? 'No time set' 
                                  : 'Time: ${_dueTime!.format(context)}'),
                              trailing: _dueTime != null 
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _dueTime = null;
                                        });
                                      },
                                    )
                                  : null,
                              onTap: _selectDueTime,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recurring Task Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            title: const Text('Recurring Task'),
                            subtitle: const Text('Repeat this task automatically'),
                            value: _isRecurring,
                            onChanged: (value) {
                              setState(() {
                                _isRecurring = value!;
                                if (!_isRecurring) _recurringPattern = null;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          ),

                          if (_isRecurring) ...[
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _recurringPattern,
                              decoration: const InputDecoration(
                                labelText: 'Repeat Pattern',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.repeat),
                              ),
                              hint: const Text('Select repeat pattern'),
                              items: _recurringPatterns.map((pattern) {
                                return DropdownMenuItem(
                                  value: pattern,
                                  child: Text(pattern.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _recurringPattern = value;
                                });
                              },
                              validator: (value) {
                                if (_isRecurring && value == null) {
                                  return 'Please select a repeat pattern';
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: taskProvider.isCreating || taskProvider.isUpdating
                        ? null
                        : _saveTask,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: taskProvider.isCreating || taskProvider.isUpdating
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Saving...'),
                            ],
                          )
                        : Text(
                            widget.taskToEdit == null ? 'Add Task' : 'Update Task',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
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

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
        // If time was not set and date is today, suggest current time + 1 hour
        if (_dueTime == null && _isToday(picked)) {
          final now = TimeOfDay.now();
          _dueTime = TimeOfDay(
            hour: now.hour + 1 > 23 ? 23 : now.hour + 1,
            minute: now.minute,
          );
        }
      });
    }
  }

  Future<void> _selectDueTime() async {
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date first')),
      );
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    
    if (picked != null && picked != _dueTime) {
      setState(() {
        _dueTime = picked;
      });
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  DateTime? _combineDateAndTime() {
    if (_dueDate == null) return null;
    
    if (_dueTime == null) {
      return _dueDate;
    }
    
    return DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      _dueTime!.hour,
      _dueTime!.minute,
    );
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final combinedDateTime = _combineDateAndTime();
      
      // Validate due date is not in the past
      if (combinedDateTime != null && combinedDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Due date and time cannot be in the past'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final task = Task(
        id: widget.taskToEdit?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        createdAt: widget.taskToEdit?.createdAt ?? DateTime.now(),
        dueDate: combinedDateTime,
        priority: _priority,
        category: _category,
        isRecurring: _isRecurring,
        recurringPattern: _recurringPattern,
        isCompleted: widget.taskToEdit?.isCompleted ?? false,
      );

      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      bool success;
      if (widget.taskToEdit == null) {
        success = await taskProvider.addTask(task);
      } else {
        success = await taskProvider.updateTask(task);
      }

      if (success) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.taskToEdit == null 
                ? 'Task added successfully' 
                : 'Task updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
