// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/task_provider.dart';
import '../services/sentry_service.dart';
import '../models/task.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedFrequency = 'daily';
  int _targetCount = 1;
  TimeOfDay? _reminderTime;
  String _selectedCategory = 'health';
  String _selectedPriority = 'medium';
  bool _enableReminder = true;
  
  final List<String> _frequencies = ['daily', 'weekly', 'monthly'];
  final List<String> _categories = ['health', 'productivity', 'mindfulness', 'social'];
  final List<String> _priorities = ['low', 'medium', 'high'];
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
    
    SentryService.addBreadcrumb(
      message: 'add_habit_screen_opened',
      category: 'navigation',
      data: {'screen': 'add_habit'},
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTemplateSection(theme),
                const SizedBox(height: 24),
                _buildHabitBasics(theme),
                const SizedBox(height: 24),
                _buildHabitSettings(theme),
                const SizedBox(height: 24),
                _buildReminderSettings(theme),
                const SizedBox(height: 32),
                _buildActionButtons(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: const Color(0xFF1976D2),
      elevation: 0,
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
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.add_task_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).addNewHabit,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Quick Start with Templates',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Choose from pre-made habit templates to get started quickly',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openTemplateScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1976D2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.explore_rounded),
              label: const Text(
                'Browse Habit Templates',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitBasics(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Habit Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).taskTitle,
              hintText: AppLocalizations.of(context).taskTitleHint,
              prefixIcon: const Icon(Icons.track_changes_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppLocalizations.of(context).pleaseEnterTaskTitle;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).taskDescription,
              hintText: 'Enter task description',
              prefixIcon: const Icon(Icons.description_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildHabitSettings(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Habit Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            AppLocalizations.of(context).frequency,
            _selectedFrequency,
            _frequencies,
            (value) => setState(() => _selectedFrequency = value!),
            Icons.repeat_rounded,
            theme,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            AppLocalizations.of(context).category,
            _selectedCategory,
            _categories,
            (value) => setState(() => _selectedCategory = value!),
            Icons.category_rounded,
            theme,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            AppLocalizations.of(context).priority,
            _selectedPriority,
            _priorities,
            (value) => setState(() => _selectedPriority = value!),
            Icons.flag_rounded,
            theme,
          ),
          const SizedBox(height: 16),
          _buildTargetCountField(theme),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
    IconData icon,
    ThemeData theme,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(_getLocalizedValue(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTargetCountField(ThemeData theme) {
    return TextFormField(
      initialValue: _targetCount.toString(),
      decoration: InputDecoration(
        labelText: 'Daily Target',
        hintText: 'Enter daily target',
        prefixIcon: const Icon(Icons.numbers_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final count = int.tryParse(value);
        if (count != null && count > 0) {
          setState(() => _targetCount = count);
        }
      },
      validator: (value) {
        final count = int.tryParse(value ?? '');
        if (count == null || count <= 0) {
          return 'Please enter a valid target';
        }
        return null;
      },
    );
  }

  Widget _buildReminderSettings(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reminder Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text('Enable Reminders'),
            subtitle: Text('Get notified daily'),
            value: _enableReminder,
            onChanged: (value) => setState(() => _enableReminder = value),
            activeColor: const Color(0xFF1976D2),
          ),
          if (_enableReminder) ...[
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.access_time_rounded),
              title: Text('Reminder Time'),
              subtitle: Text(
                _reminderTime != null
                    ? _reminderTime!.format(context)
                    : 'Select time',
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded),
              onTap: _selectReminderTime,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(AppLocalizations.of(context).cancel),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveHabit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(AppLocalizations.of(context).createHabit),
          ),
        ),
      ],
    );
  }

  String _getLocalizedValue(String value) {
    switch (value) {
      case 'daily':
        return AppLocalizations.of(context).daily;
      case 'weekly':
        return AppLocalizations.of(context).weekly;
      case 'monthly':
        return AppLocalizations.of(context).monthly;
      case 'health':
        return AppLocalizations.of(context).healthFitness;
      case 'productivity':
        return AppLocalizations.of(context).productivity;
      case 'mindfulness':
        return AppLocalizations.of(context).mindfulness;
      case 'social':
        return AppLocalizations.of(context).socialLife;
      case 'low':
        return AppLocalizations.of(context).low;
      case 'medium':
        return AppLocalizations.of(context).medium;
      case 'high':
        return AppLocalizations.of(context).high;
      default:
        return value;
    }
  }

  Future<void> _openTemplateScreen() async {
    try {
      final selectedHabits = await Navigator.pushNamed(
        context,
        '/habit-templates',
      ) as List<String>?;

      if (selectedHabits != null && selectedHabits.isNotEmpty) {
        // For simplicity, use the first selected habit to populate the form
        final habitName = selectedHabits.first;
        _populateFormFromTemplate(habitName);
        
        SentryService.addBreadcrumb(
          message: 'template_selected',
          category: 'habit_template',
          data: {
            'template_name': habitName,
            'selected_count': selectedHabits.length,
          },
        );
      }
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  void _populateFormFromTemplate(String habitName) {
    // Map template names to form data
    final templateData = _getTemplateData(habitName);
    
    setState(() {
      _titleController.text = templateData['name'] ?? habitName;
      _descriptionController.text = templateData['description'] ?? '';
      _selectedCategory = templateData['category'] ?? _selectedCategory;
      _selectedPriority = templateData['priority'] ?? _selectedPriority;
      _targetCount = templateData['targetCount'] ?? _targetCount;
    });
  }

  Map<String, dynamic> _getTemplateData(String habitName) {
    // Template data mapping
    final templates = {
      'Drink 8 glasses of water': {
        'name': 'Drink 8 glasses of water',
        'description': 'Stay hydrated throughout the day by drinking 8 glasses of water',
        'category': 'health',
        'priority': 'medium',
        'targetCount': 8,
      },
      'Exercise for 30 minutes': {
        'name': 'Exercise for 30 minutes',
        'description': 'Daily physical activity for better health and fitness',
        'category': 'health',
        'priority': 'high',
        'targetCount': 1,
      },
      'Read for 30 minutes': {
        'name': 'Read for 30 minutes',
        'description': 'Daily reading habit for continuous learning and growth',
        'category': 'productivity',
        'priority': 'medium',
        'targetCount': 1,
      },
      'Meditate for 10 minutes': {
        'name': 'Meditate for 10 minutes',
        'description': 'Daily meditation practice for mindfulness and stress relief',
        'category': 'mindfulness',
        'priority': 'medium',
        'targetCount': 1,
      },
      'Call family/friends': {
        'name': 'Call family/friends',
        'description': 'Stay connected with loved ones through regular communication',
        'category': 'social',
        'priority': 'medium',
        'targetCount': 1,
      },
      // Add more template mappings as needed
    };

    return templates[habitName] ?? {
      'name': habitName,
      'description': 'Complete this habit daily',
      'category': 'health',
      'priority': 'medium',
      'targetCount': 1,
    };
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  Future<void> _saveHabit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      // Create habit as a recurring task
      final DateTime now = DateTime.now();
      final DateTime? reminderDateTime = _enableReminder && _reminderTime != null
          ? DateTime(now.year, now.month, now.day, _reminderTime!.hour, _reminderTime!.minute)
          : null;
      
      final task = Task(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        createdAt: now,
        category: _selectedCategory,
        priority: _selectedPriority,
        isRecurring: true,
        recurringPattern: _selectedFrequency,
        recurringInterval: 1,
        hasReminder: _enableReminder,
        reminderTime: reminderDateTime,
        status: 'pending',
      );
      
      await taskProvider.addTask(task);

      SentryService.addBreadcrumb(
        message: 'habit_created',
        category: 'habit',
        data: {
          'frequency': _selectedFrequency,
          'category': _selectedCategory,
          'priority': _selectedPriority,
          'hasReminder': _enableReminder,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Habit created successfully!'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      SentryService.captureException(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating habit'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }
  }
}
