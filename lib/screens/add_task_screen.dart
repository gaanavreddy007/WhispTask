// ignore_for_file: deprecated_member_use, unused_import, use_build_context_synchronously, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/notification_helper.dart'; 
import '../widgets/voice_notes_widget.dart';
import '../widgets/file_attachments_widget.dart';
import '../services/transcription_service.dart';
import '../l10n/app_localizations.dart';

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
  int _recurringInterval = 1;

  // NEW: Reminder fields
  bool _hasReminder = false;
  DateTime? _reminderTime;
  String _reminderType = 'once';
  String _notificationTone = 'default';
  List<String> _repeatDays = [];
  List<VoiceNote> _voiceNotes = [];
  List<TaskAttachment> _attachments = [];
  String _taskColor = 'blue';
  int _reminderMinutesBefore = 0;

  final List<String> _availableColors = [
    'red', 'pink', 'purple', 'indigo', 'blue', 
    'cyan', 'teal', 'green', 'yellow', 'orange'
  ];
  
  // TranscriptionService initialization
  final TranscriptionService _transcriptionService = TranscriptionService();
  bool _isInitialized = false;

  final List<String> _priorities = ['high', 'medium', 'low'];
  final List<String> _categories = ['general', 'work', 'personal', 'health', 'shopping', 'study'];
  final List<String> _recurringPatterns = ['daily', 'weekly', 'monthly', 'yearly'];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    if (widget.taskToEdit != null) {
      _populateFields(widget.taskToEdit!);
      _voiceNotes = List.from(widget.taskToEdit!.voiceNotes);
      _attachments = List.from(widget.taskToEdit!.attachments);
    }
  }

  Future<void> _initializeServices() async {
    await _transcriptionService.initialize();
    setState(() {
      _isInitialized = true;
    });
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
    _recurringInterval = task.recurringInterval ?? 1;

    // NEW: Populate reminder fields
    _hasReminder = task.hasReminder;
    _reminderTime = task.reminderTime;
    _reminderType = task.reminderType;
    _notificationTone = task.notificationTone;
    _repeatDays = List.from(task.repeatDays);
    _taskColor = task.color ?? 'blue';
    _reminderMinutesBefore = task.reminderMinutesBefore;
  }

  // NEW: Select reminder method
  Future<void> _selectReminder() async {
    final result = await NotificationHelper.showReminderOptionsSheet(
      context,
      initialTime: _reminderTime ?? DateTime.now().add(const Duration(hours: 1)),
      initialType: _reminderType,
      initialTone: _notificationTone,
      initialRepeatDays: _repeatDays,
    );

    if (result != null) {
      setState(() {
        _reminderTime = result['time'];
        _reminderType = result['type'];
        _notificationTone = result['tone'];
        _repeatDays = List<String>.from(result['repeatDays']);
        _hasReminder = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskToEdit == null ? AppLocalizations.of(context).addTask : AppLocalizations.of(context).editTask),
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
                        color: Colors.grey[_taskColor == 'blue' ? 100 : 200],
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
                    decoration: InputDecoration(
                      labelText: '${AppLocalizations.of(context).taskTitle} *',
                      hintText: AppLocalizations.of(context).taskTitleHint,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.task),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppLocalizations.of(context).pleaseEnterTaskTitle;
                      }
                      if (value.length > 100) {
                        return AppLocalizations.of(context).titleTooLong;
                      }
                      return null;
                    },
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).descriptionOptional,
                      hintText: AppLocalizations.of(context).addMoreDetails,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    maxLength: 500,
                    validator: (value) {
                      if (value != null && value.length > 500) {
                        return AppLocalizations.of(context).descriptionTooLong;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Voice Notes Section
                  if (_isInitialized)
                    EnhancedVoiceNotesWidget(
                      taskId: widget.taskToEdit?.id ?? '',
                      voiceNotes: _voiceNotes,
                      onVoiceNoteAdded: (voiceNote) {
                        setState(() {
                          _voiceNotes.add(voiceNote);
                        });
                      },
                      onVoiceNoteDeleted: (voiceNoteId) {
                        setState(() {
                          _voiceNotes.removeWhere((note) => note.id == voiceNoteId);
                        });
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(AppLocalizations.of(context).initializingVoiceServices),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // File Attachments Section
                  FileAttachmentsWidget(
                    taskId: widget.taskToEdit?.id ?? '',
                    attachments: _attachments,
                    onAttachmentAdded: (attachment) {
                      setState(() {
                        _attachments.add(attachment);
                      });
                    },
                    onAttachmentDeleted: (attachmentId) {
                      setState(() {
                        _attachments.removeWhere((att) => att.id == attachmentId);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Priority, Category, and Color Row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).taskProperties,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Priority and Category Row
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _priority,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context).priority,
                                  prefixIcon: Icon(_getPriorityIcon(_priority), 
                                                 color: _getPriorityColor(_priority)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: _priorities.map((priority) {
                                  return DropdownMenuItem(
                                    value: priority,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_getPriorityIcon(priority), 
                                             size: 14, color: _getPriorityColor(priority)),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            priority.toUpperCase(),
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _category,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context).category,
                                  prefixIcon: Icon(_getCategoryIcon(_category)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: _categories.map((category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_getCategoryIcon(category), size: 13),
                                        const SizedBox(width: 3),
                                        Flexible(
                                          child: Text(
                                            category.toUpperCase(),
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ),
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
                        
                        // Color Selection Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.palette, size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'Task Color',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            Container(
                              height: 60,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: _availableColors.map((colorName) {
                                          final color = _parseTaskColor(colorName);
                                          final isSelected = _taskColor == colorName;
                                          
                                          return Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _taskColor = colorName;
                                                });
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isSelected ? Colors.black : Colors.grey.shade400,
                                                    width: isSelected ? 3 : 1,
                                                  ),
                                                  boxShadow: isSelected ? [
                                                    BoxShadow(
                                                      color: color.withOpacity(0.4),
                                                      blurRadius: 8,
                                                      spreadRadius: 2,
                                                    ),
                                                  ] : null,
                                                ),
                                                child: isSelected
                                                    ? Icon(
                                                        Icons.check,
                                                        color: _getContrastColor(color),
                                                        size: 20,
                                                      )
                                                    : null,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Selected color indicator
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _parseTaskColor(_taskColor),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade400),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Selected: ${_taskColor.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
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

                  // NEW: Reminder Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.notifications),
                              const SizedBox(width: 8),
                              const Text(
                                'Reminder',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Spacer(),
                              Switch(
                                value: _hasReminder,
                                onChanged: (value) {
                                  setState(() {
                                    _hasReminder = value;
                                    if (!value) {
                                      _reminderTime = null;
                                      _reminderType = 'once';
                                      _notificationTone = 'default';
                                      _repeatDays = [];
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          
                          if (_hasReminder) ...[
                            const SizedBox(height: 12),
                            ListTile(
                              leading: const Icon(Icons.schedule),
                              title: const Text('Set Reminder Time'),
                              subtitle: Text(_reminderTime == null 
                                  ? 'Tap to set reminder' 
                                  : NotificationHelper.formatReminderTime(_reminderTime)),
                              trailing: _reminderTime != null 
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _reminderTime = null;
                                        });
                                      },
                                    )
                                  : const Icon(Icons.arrow_forward_ios),
                              onTap: _selectReminder,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            
                            if (_reminderTime != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(NotificationHelper.getReminderIcon(_reminderType), 
                                             size: 16, color: Colors.blue),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Type: ${NotificationHelper.reminderTypes[_reminderType]}',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(NotificationHelper.getNotificationToneIcon(_notificationTone), 
                                             size: 16, color: Colors.blue),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Tone: ${NotificationHelper.notificationTones[_notificationTone]}',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    if (_reminderType == 'weekly' && _repeatDays.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.date_range, size: 16, color: Colors.blue),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Days: ${_repeatDays.map((d) => d.toUpperCase()).join(', ')}',
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                            
                            // Validation message for reminder
                            if (_hasReminder && _reminderTime != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  NotificationHelper.getTimeUntilReminder(_reminderTime) == 'Overdue'
                                      ? '⚠️ Reminder time is in the past'
                                      : '✅ Reminder in ${NotificationHelper.getTimeUntilReminder(_reminderTime)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: NotificationHelper.getTimeUntilReminder(_reminderTime) == 'Overdue'
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: _recurringInterval.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Repeat Every (number)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.numbers),
                                helperText: 'e.g., 2 for every 2 days/weeks/months',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  _recurringInterval = int.tryParse(value) ?? 1;
                                });
                              },
                              validator: (value) {
                                if (_isRecurring) {
                                  final interval = int.tryParse(value ?? '');
                                  if (interval == null || interval < 1) {
                                    return 'Please enter a valid interval (1 or greater)';
                                  }
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

      // NEW: Validate reminder time
      if (_hasReminder && _reminderTime != null && _reminderTime!.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder time cannot be in the past'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final task = Task(
        id: widget.taskToEdit?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        createdAt: widget.taskToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: combinedDateTime,
        priority: _priority,
        category: _category,
        color: _taskColor,
        isRecurring: _isRecurring,
        recurringPattern: _isRecurring ? _recurringPattern : null,
        recurringInterval: _isRecurring ? _recurringInterval : null,
        hasReminder: _hasReminder,
        reminderTime: _hasReminder ? _reminderTime : null,
        reminderType: _hasReminder ? _reminderType : 'once',
        notificationTone: _hasReminder ? _notificationTone : 'default',
        repeatDays: _hasReminder && _reminderType == 'weekly' ? _repeatDays : [],
        reminderMinutesBefore: _reminderMinutesBefore,
        voiceNotes: _voiceNotes,
        attachments: _attachments,
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
                ? '✅ ${AppLocalizations.of(context).taskAddedSuccessfully} ${_hasReminder ? AppLocalizations.of(context).withReminder : ""}' 
                : '✅ ${AppLocalizations.of(context).taskUpdatedSuccessfully} ${_hasReminder ? AppLocalizations.of(context).withReminder : ""}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _parseTaskColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red': return Colors.red.shade600;
      case 'blue': return Colors.blue.shade600;
      case 'green': return Colors.green.shade600;
      case 'orange': return Colors.orange.shade600;
      case 'purple': return Colors.purple.shade600;
      case 'teal': return Colors.teal.shade600;
      case 'pink': return Colors.pink.shade600;
      case 'yellow': return Colors.yellow.shade700;
      case 'indigo': return Colors.indigo.shade600;
      case 'cyan': return Colors.cyan.shade600;
      default: return Colors.blue.shade600;
    }
  }

  Color _getContrastColor(Color color) {
    double luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Icons.priority_high;
      case 'medium': return Icons.remove;
      case 'low': return Icons.expand_more;
      default: return Icons.flag;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _transcriptionService.dispose();
    super.dispose();
  }
}