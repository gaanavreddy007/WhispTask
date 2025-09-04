// ignore_for_file: prefer_const_constructors, deprecated_member_use, duplicate_ignore, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../l10n/app_localizations.dart';
import '../services/sentry_service.dart';

class VoiceInputScreen extends StatefulWidget {
  const VoiceInputScreen({super.key});

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Log screen navigation
    SentryService.logScreenNavigation('VoiceInputScreen');
    
    try {
      _pulseController = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this,
      );
      _pulseAnimation = Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ));
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error initializing VoiceInputScreen animations',
        extra: {'screen': 'VoiceInputScreen'},
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    try {
      final voiceProvider = context.read<VoiceProvider>();
      
      if (voiceProvider.isListening) {
        SentryService.logUserAction('voice_stop_listening');
        voiceProvider.stopListening();
        _pulseController.stop();
      } else {
        SentryService.logUserAction('voice_start_listening');
        voiceProvider.startListening();
        _pulseController.repeat(reverse: true);
      }
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error toggling voice listening',
        extra: {'screen': 'VoiceInputScreen'},
      );
    }
  }

  // Manual test method for debugging parsing logic
  void _testCommand(String command) {
    final taskProvider = context.read<TaskProvider>();
    taskProvider.processVoiceTaskCommandEnhanced(command);
  }

  Future<void> _saveTask() async {
    return SentryService.wrapWithErrorTracking(
      () async {
        final voiceProvider = context.read<VoiceProvider>();
        final taskProvider = context.read<TaskProvider>();
        
        SentryService.logUserAction('voice_save_task_attempt', data: {
          'has_preview_task': (voiceProvider.previewTask != null).toString(),
          'is_valid': voiceProvider.isCurrentTaskValid().toString(),
        });
        
        if (voiceProvider.previewTask == null || !voiceProvider.isCurrentTaskValid()) {
          SentryService.addBreadcrumb(
            message: 'Invalid task validation failed',
            category: 'validation',
            level: 'warning',
          );
          _showSnackBar(AppLocalizations.of(context).pleaseProvideValidTask, isError: true);
          return;
        }

        await taskProvider.addTask(voiceProvider.previewTask!);
        
        SentryService.logUserAction('voice_task_saved_success', data: {
          'task_title': voiceProvider.previewTask!.title,
          'task_priority': voiceProvider.previewTask!.priority.toString(),
        });
        
        _showSnackBar(AppLocalizations.of(context).taskCreatedSuccessfully, isError: false);
        voiceProvider.clearSession();
      },
      operation: 'save_voice_task',
      description: 'Save task from voice input',
      extra: {'screen': 'VoiceInputScreen'},
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).voiceInput),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: Consumer<VoiceProvider>(
        builder: (context, voiceProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Text input for testing commands (bypass microphone)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(AppLocalizations.of(context).testCommandsTitle, 
                           style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context).testCommandsHint,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_textController.text.isNotEmpty) {
                            _testCommand(_textController.text);
                            _textController.clear();
                          }
                        },
                        child: Text(AppLocalizations.of(context).testCommand),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Voice button
                Center(
                  child: GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: voiceProvider.isListening ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: voiceProvider.isListening 
                                ? Theme.of(context).colorScheme.error 
                                : Theme.of(context).colorScheme.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: (voiceProvider.isListening 
                                    ? Theme.of(context).colorScheme.error 
                                    : Theme.of(context).colorScheme.primary).withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              voiceProvider.isListening ? Icons.stop : Icons.mic,
                              size: 40,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Status text
                Text(
                  voiceProvider.isListening 
                      ? AppLocalizations.of(context).listeningSpeak
                      : voiceProvider.isInitialized 
                          ? AppLocalizations.of(context).tapToSpeak 
                          : AppLocalizations.of(context).initializing,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: voiceProvider.isListening ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Error message
                if (voiceProvider.errorMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.error),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            voiceProvider.errorMessage,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Recognized text
                if (voiceProvider.recognizedText.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).youSaid,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          voiceProvider.recognizedText,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
                
                // Task preview
                if (voiceProvider.previewTask != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).taskPreview,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTaskPreview(voiceProvider.previewTask!),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: voiceProvider.clearSession,
                          icon: const Icon(Icons.clear),
                          label: Text(AppLocalizations.of(context).clear),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: voiceProvider.isCurrentTaskValid() ? _saveTask : null,
                          icon: const Icon(Icons.save),
                          label: Text(AppLocalizations.of(context).saveTask),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                const Spacer(),
                
                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).voiceCommandsExamples,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(AppLocalizations.of(context).voiceExample1),
                      Text(AppLocalizations.of(context).voiceExample2),
                      Text(AppLocalizations.of(context).voiceExample3),
                      Text(AppLocalizations.of(context).voiceExample4),
                      Text(AppLocalizations.of(context).voiceExample5),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskPreview(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.task_alt, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildPreviewChip(AppLocalizations.of(context).category, task.category, Theme.of(context).colorScheme.primary),
            _buildPreviewChip(AppLocalizations.of(context).priority, task.priority, _getPriorityColor(task.priority)),
            if (task.isRecurring && task.recurringPattern != null)
              _buildPreviewChip(AppLocalizations.of(context).recurring, task.recurringPattern!, Theme.of(context).colorScheme.secondary),
          ],
        ),
        if (task.dueDate != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, color: Theme.of(context).colorScheme.secondary, size: 16),
              const SizedBox(width: 4),
              Text(
                '${AppLocalizations.of(context).due}: ${_formatDateTime(task.dueDate!)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;
    
    if (difference == 0) {
      return '${AppLocalizations.of(context).today} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference == 1) {
      return '${AppLocalizations.of(context).tomorrow} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).voiceInputHelp),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context).howToUseVoiceInput, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).voiceStep1),
              Text(AppLocalizations.of(context).voiceStep2),
              Text(AppLocalizations.of(context).voiceStep3),
              Text(AppLocalizations.of(context).voiceStep4),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context).voiceFeatures, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).voiceFeatureTime),
              Text(AppLocalizations.of(context).voiceFeaturePriority),
              Text(AppLocalizations.of(context).voiceFeatureRecurring),
              Text(AppLocalizations.of(context).voiceFeatureCategories),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).gotIt),
          ),
        ],
      ),
    );
  }
}
