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

class _AddTaskScreenState extends State<AddTaskScreen> with TickerProviderStateMixin {
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

  late AnimationController _colorAnimationController;
  late Animation<double> _colorScaleAnimation;

  static const List<String> _availableColors = [
    'red', 'pink', 'purple', 'indigo', 'blue', 
    'cyan', 'teal', 'green', 'yellow', 'orange'
  ];
  
  // TranscriptionService initialization
  final TranscriptionService _transcriptionService = TranscriptionService();
  bool _isInitialized = false;

  static const List<String> _priorities = ['high', 'medium', 'low'];
  static const List<String> _categories = ['general', 'work', 'personal', 'health', 'shopping', 'study'];
  static const List<String> _recurringPatterns = ['daily', 'weekly', 'monthly', 'yearly'];

  @override
  void initState() {
    super.initState();
    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200), // Faster animation
      vsync: this,
    );
    _colorScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate( // Reduced scale
      CurvedAnimation(parent: _colorAnimationController, curve: Curves.easeOut) // Simpler curve
    );
    
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.taskToEdit == null ? AppLocalizations.of(context).addTask : AppLocalizations.of(context).editTask,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: taskProvider.isCreating || taskProvider.isUpdating
                        ? colorScheme.surfaceVariant.withOpacity(0.8)
                        : colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: taskProvider.isCreating || taskProvider.isUpdating
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onSurfaceVariant),
                            ),
                          )
                        : Icon(Icons.check_rounded, color: colorScheme.onPrimary),
                    onPressed: taskProvider.isCreating || taskProvider.isUpdating
                        ? null
                        : _saveTask,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                // App Bar Space
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).padding.top + 80),
                ),
                
                // Error Message
                if (taskProvider.error != null)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.error_rounded, 
                                     color: colorScheme.error, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              taskProvider.error!,
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, size: 20),
                            onPressed: taskProvider.clearError,
                            style: IconButton.styleFrom(
                              foregroundColor: colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Main Content
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Title and Description Section
                      _buildTitleDescriptionSection(),
                      const SizedBox(height: 24),

                      // Voice Notes Section
                      if (_isInitialized)
                        _buildVoiceNotesSection()
                      else
                        _buildLoadingSection(),
                      const SizedBox(height: 24),

                      // File Attachments Section
                      _buildFileAttachmentsSection(),
                      const SizedBox(height: 24),

                      // Task Properties Section
                      _buildTaskPropertiesSection(),
                      const SizedBox(height: 24),

                      // Due Date and Time Section
                      _buildDueDateSection(),
                      const SizedBox(height: 24),

                      // Reminder Section
                      _buildReminderSection(),
                      const SizedBox(height: 24),

                      // Recurring Task Section
                      _buildRecurringSection(),
                      const SizedBox(height: 32),

                      // Save Button
                      _buildSaveButton(taskProvider),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleDescriptionSection() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Title Field
          Container(
            padding: const EdgeInsets.all(24),
            child: TextFormField(
              controller: _titleController,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
              decoration: InputDecoration(
                labelText: '${AppLocalizations.of(context).taskTitle} *',
                labelStyle: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
                hintText: AppLocalizations.of(context).taskTitleHint,
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surface,
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.task_alt_rounded, 
                             color: colorScheme.primary, size: 20),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
          ),

          // Description Field
          Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: TextFormField(
              controller: _descriptionController,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).descriptionOptional,
                labelStyle: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
                hintText: AppLocalizations.of(context).addMoreDetails,
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surface,
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.description_rounded, 
                             color: colorScheme.secondary, size: 20),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              minLines: 3,
              maxLength: 500,
              validator: (value) {
                if (value != null && value.length > 500) {
                  return AppLocalizations.of(context).descriptionTooLong;
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceNotesSection() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.mic_rounded, 
                             color: colorScheme.tertiary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).voiceCommands,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context).voiceInputHint,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: EnhancedVoiceNotesWidget(
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            AppLocalizations.of(context).initializingVoiceServices,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileAttachmentsSection() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.attach_file_rounded, 
                             color: Theme.of(context).colorScheme.secondary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).add,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context).taskDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: FileAttachmentsWidget(
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
          ),
        ],
      ),
    );
  }

  Widget _buildTaskPropertiesSection() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.tune_rounded, 
                             color: colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  AppLocalizations.of(context).taskProperties,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Priority and Category Row
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    value: _priority,
                    items: _priorities,
                    label: AppLocalizations.of(context).priority,
                    icon: _getPriorityIcon(_priority),
                    iconColor: _getPriorityColor(_priority),
                    onChanged: (value) => setState(() => _priority = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdownField(
                    value: _category,
                    items: _categories,
                    label: AppLocalizations.of(context).category,
                    icon: _getCategoryIcon(_category),
                    iconColor: colorScheme.secondary,
                    onChanged: (value) => setState(() => _category = value!),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Color Selection Section
            _buildColorSelection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Color iconColor,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildColorSelection() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.palette_rounded, 
                 size: 20, 
                 color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).taskColor,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableColors.length,
                  itemBuilder: (context, index) {
                    final colorName = _availableColors[index];
                    final color = _parseTaskColor(colorName);
                    final isSelected = _taskColor == colorName;
                    
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          _colorAnimationController.forward().then((_) {
                            _colorAnimationController.reverse();
                          });
                          setState(() {
                            _taskColor = colorName;
                          });
                        },
                        child: AnimatedBuilder(
                          animation: _colorAnimationController,
                          builder: (context, child) {
                            final scale = isSelected ? _colorScaleAnimation.value : 1.0;
                            return Transform.scale(
                              scale: scale,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
                                    width: isSelected ? 3 : 2,
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ] : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check_rounded,
                                        color: _getContrastColor(color),
                                        size: 24,
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Selected color indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _parseTaskColor(_taskColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _parseTaskColor(_taskColor).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _parseTaskColor(_taskColor),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context).selectedColon} ${_taskColor.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 14,
                        color: _parseTaskColor(_taskColor),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDueDateSection() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.schedule_rounded, 
                             color: Theme.of(context).colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  AppLocalizations.of(context).dueDate,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Date Picker
            _buildDateTimeCard(
              icon: Icons.calendar_today_rounded,
              title: _dueDate == null 
                  ? AppLocalizations.of(context).dueDate 
                  : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
              subtitle: _dueDate == null ? AppLocalizations.of(context).dueDate : AppLocalizations.of(context).dueDate,
              onTap: _selectDueDate,
              hasValue: _dueDate != null,
              onClear: _dueDate != null ? () {
                setState(() {
                  _dueDate = null;
                  _dueTime = null;
                });
              } : null,
            ),
            
            if (_dueDate != null) ...[
              const SizedBox(height: 12),
              // Time Picker
              _buildDateTimeCard(
                icon: Icons.access_time_rounded,
                title: _dueTime == null 
                    ? AppLocalizations.of(context).dueDate 
                    : _dueTime!.format(context),
                subtitle: AppLocalizations.of(context).dueDate,
                onTap: _selectDueTime,
                hasValue: _dueTime != null,
                onClear: _dueTime != null ? () {
                  setState(() {
                    _dueTime = null;
                  });
                } : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool hasValue,
    VoidCallback? onClear,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasValue 
              ? colorScheme.primary.withOpacity(0.3) 
              : colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: hasValue 
                ? colorScheme.primary.withOpacity(0.1) 
                : colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: hasValue ? colorScheme.primary : colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: hasValue ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: onClear != null 
            ? IconButton(
                icon: Icon(Icons.clear_rounded, size: 20),
                onPressed: onClear,
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  backgroundColor: colorScheme.error.withOpacity(0.1),
                ),
              )
            : Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildReminderSection() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.notifications_rounded, 
                             color: Colors.purple, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).reminder,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: _hasReminder 
                        ? Colors.purple.withOpacity(0.1) 
                        : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Switch(
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
                    activeColor: Colors.purple,
                    activeTrackColor: Colors.purple.withOpacity(0.3),
                  ),
                ),
              ],
            ),
            
            if (_hasReminder) ...[
              const SizedBox(height: 20),
              _buildReminderCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _reminderTime != null 
                  ? Colors.purple.withOpacity(0.3) 
                  : colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _reminderTime != null 
                    ? Colors.purple.withOpacity(0.1) 
                    : colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.schedule_rounded,
                color: _reminderTime != null ? Colors.purple : colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            title: Text(
              AppLocalizations.of(context).reminder,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              _reminderTime == null 
                  ? AppLocalizations.of(context).reminder 
                  : NotificationHelper.formatReminderTime(_reminderTime),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: _reminderTime != null 
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, size: 20),
                    onPressed: () {
                      setState(() {
                        _reminderTime = null;
                      });
                    },
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      backgroundColor: colorScheme.error.withOpacity(0.1),
                    ),
                  )
                : Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
            onTap: _selectReminder,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        
        if (_reminderTime != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.1),
                  Colors.purple.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                _buildReminderDetailRow(
                  icon: NotificationHelper.getReminderIcon(_reminderType),
                  label: AppLocalizations.of(context).category,
                  value: NotificationHelper.reminderTypes[_reminderType] ?? _reminderType,
                ),
                const SizedBox(height: 12),
                _buildReminderDetailRow(
                  icon: NotificationHelper.getNotificationToneIcon(_notificationTone),
                  label: AppLocalizations.of(context).notifications,
                  value: NotificationHelper.notificationTones[_notificationTone] ?? _notificationTone,
                ),
                if (_reminderType == 'weekly' && _repeatDays.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildReminderDetailRow(
                    icon: Icons.date_range_rounded,
                    label: AppLocalizations.of(context).today,
                    value: _repeatDays.map((d) => d.toUpperCase()).join(', '),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Validation message for reminder
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NotificationHelper.getTimeUntilReminder(_reminderTime) == AppLocalizations.of(context).overdue
                  ? colorScheme.errorContainer
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: NotificationHelper.getTimeUntilReminder(_reminderTime) == AppLocalizations.of(context).overdue
                    ? colorScheme.error.withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  NotificationHelper.getTimeUntilReminder(_reminderTime) == AppLocalizations.of(context).overdue
                      ? Icons.warning_rounded
                      : Icons.check_circle_rounded,
                  color: NotificationHelper.getTimeUntilReminder(_reminderTime) == AppLocalizations.of(context).overdue
                      ? colorScheme.error
                      : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    NotificationHelper.getTimeUntilReminder(_reminderTime) == AppLocalizations.of(context).overdue
                        ? AppLocalizations.of(context).reminderTimeInPast
                        : '${AppLocalizations.of(context).reminderIn} ${NotificationHelper.getTimeUntilReminder(_reminderTime)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: NotificationHelper.getTimeUntilReminder(_reminderTime) == AppLocalizations.of(context).overdue
                          ? colorScheme.onErrorContainer
                          : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReminderDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.purple),
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.purple.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecurringSection() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.repeat_rounded, 
                             color: Colors.teal, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).tasks,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context).taskDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: _isRecurring 
                        ? Colors.teal.withOpacity(0.1) 
                        : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Switch(
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() {
                        _isRecurring = value;
                        if (!_isRecurring) _recurringPattern = null;
                      });
                    },
                    activeColor: Colors.teal,
                    activeTrackColor: Colors.teal.withOpacity(0.3),
                  ),
                ),
              ],
            ),

            if (_isRecurring) ...[
              const SizedBox(height: 20),
              
              DropdownButtonFormField<String>(
                value: _recurringPattern,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).category,
                  labelStyle: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.w500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.repeat_rounded, color: Colors.teal, size: 18),
                  ),
                ),
                hint: Text(AppLocalizations.of(context).category),
                items: _recurringPatterns.map((pattern) {
                  return DropdownMenuItem(
                    value: pattern,
                    child: Text(
                      pattern.toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _recurringPattern = value;
                  });
                },
                validator: (value) {
                  if (_isRecurring && (value == null || value.isEmpty)) {
                    return 'Please select a recurring pattern (daily, weekly, monthly, or yearly)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                initialValue: _recurringInterval.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).repeatEveryNumber,
                  labelStyle: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.w500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.numbers_rounded, color: Colors.teal, size: 18),
                  ),
                  helperText: AppLocalizations.of(context).repeatEveryHelper,
                  helperStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
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
                    if (interval > 365) {
                      return 'Interval cannot be more than 365';
                    }
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(TaskProvider taskProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: taskProvider.isCreating || taskProvider.isUpdating
              ? [
                  colorScheme.surfaceVariant,
                  colorScheme.surfaceVariant.withOpacity(0.8),
                ]
              : [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: taskProvider.isCreating || taskProvider.isUpdating
            ? null
            : [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: taskProvider.isCreating || taskProvider.isUpdating
            ? null
            : _saveTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: taskProvider.isCreating || taskProvider.isUpdating
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    AppLocalizations.of(context).saving,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              )
            : Text(
                widget.taskToEdit == null ? AppLocalizations.of(context).addTask : AppLocalizations.of(context).editTask,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                  letterSpacing: -0.5,
                ),
              ),
      ),
    );
  }


  // Helper Methods - Enhanced versions
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red.shade600;
      case 'medium':
        return Colors.orange.shade600;
      case 'low':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Icons.priority_high_rounded;
      case 'medium': return Icons.remove_rounded;
      case 'low': return Icons.expand_more_rounded;
      default: return Icons.flag_rounded;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Icons.work_rounded;
      case 'personal':
        return Icons.person_rounded;
      case 'health':
        return Icons.health_and_safety_rounded;
      case 'shopping':
        return Icons.shopping_cart_rounded;
      case 'study':
        return Icons.school_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
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
        SnackBar(
          content: Text(AppLocalizations.of(context).error),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
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
    if (_dueTime == null) return _dueDate;
    
    // Safe null check before using !
    final dueDate = _dueDate;
    final dueTime = _dueTime;
    if (dueDate == null || dueTime == null) return _dueDate;
    
    return DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      dueTime.hour,
      dueTime.minute,
    );
  }

  Future<void> _saveTask() async {
    final formState = _formKey.currentState;
    if (formState != null && formState.validate()) {
      final combinedDateTime = _combineDateAndTime();
      
      // Validate due date is not in the past
      if (combinedDateTime != null && combinedDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).error),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // NEW: Validate reminder time
      if (_hasReminder && _reminderTime != null && _reminderTime!.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).error),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
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
        // Ensure recurring tasks have proper validation
        status: 'pending',
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
                ? '${AppLocalizations.of(context).taskAddedSuccessfully} ${_hasReminder ? AppLocalizations.of(context).withReminder : ""}' 
                : '${AppLocalizations.of(context).taskUpdatedSuccessfully} ${_hasReminder ? AppLocalizations.of(context).withReminder : ""}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: AppLocalizations.of(context).edit,
              textColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () {
                // Optional: Navigate to task details or home
              },
            ),
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _colorAnimationController.dispose();
    _transcriptionService.dispose();
    super.dispose();
  }
}