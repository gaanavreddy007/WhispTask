import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class VoiceInputScreen extends StatefulWidget {
  const VoiceInputScreen({Key? key}) : super(key: key);

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
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

    // Initialize voice provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    final voiceProvider = context.read<VoiceProvider>();
    
    if (voiceProvider.isListening) {
      voiceProvider.stopListening();
      _pulseController.stop();
    } else {
      voiceProvider.startListening();
      _pulseController.repeat(reverse: true);
    }
  }

  Future<void> _saveTask() async {
    final voiceProvider = context.read<VoiceProvider>();
    final taskProvider = context.read<TaskProvider>();
    
    if (voiceProvider.previewTask == null || !voiceProvider.isCurrentTaskValid()) {
      _showSnackBar('Please provide a valid task description', isError: true);
      return;
    }

    try {
      await taskProvider.addTask(voiceProvider.previewTask!);
      _showSnackBar('Task created successfully!', isError: false);
      voiceProvider.clearSession();
    } catch (e) {
      _showSnackBar('Failed to save task: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Input'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
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
                // Voice input button
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: voiceProvider.isListening ? _pulseAnimation.value : 1.0,
                        child: GestureDetector(
                          onTap: voiceProvider.isInitialized ? _toggleListening : null,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: voiceProvider.isListening 
                                  ? Colors.red.shade400 
                                  : const Color(0xFF1976D2),
                              boxShadow: [
                                BoxShadow(
                                  // ignore: deprecated_member_use
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              voiceProvider.isListening ? Icons.mic : Icons.mic_none,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Status text
                Text(
                  voiceProvider.isListening 
                      ? 'Listening... Speak now!'
                      : voiceProvider.isInitialized 
                          ? 'Tap to speak' 
                          : 'Initializing...',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: voiceProvider.isListening ? Colors.red : Colors.grey[600],
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
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            voiceProvider.errorMessage,
                            style: TextStyle(color: Colors.red.shade600),
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You said:',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.blue.shade700,
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
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Preview:',
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
                          label: const Text('Clear'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: voiceProvider.isCurrentTaskValid() ? _saveTask : null,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Task'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
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
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Commands Examples:',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('• "Remind me to buy groceries"'),
                      const Text('• "Call mom at 6 PM"'),
                      const Text('• "Important: Submit project tomorrow"'),
                      const Text('• "Exercise at the gym daily"'),
                      const Text('• "Pay bills high priority"'),
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
            Icon(Icons.task_alt, color: Colors.green.shade600, size: 20),
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
            _buildPreviewChip('Category', task.category, Colors.blue),
            _buildPreviewChip('Priority', task.priority, _getPriorityColor(task.priority)),
            if (task.isRecurring && task.recurringPattern != null)
              _buildPreviewChip('Recurring', task.recurringPattern!, Colors.purple),
          ],
        ),
        if (task.dueDate != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.purple.shade600, size: 16),
              const SizedBox(width: 4),
              Text(
                'Due: ${_formatDateTime(task.dueDate!)}',
                style: TextStyle(
                  color: Colors.purple.shade600,
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
          color: Colors.blue.shade700,  // or replace 'blue' with any MaterialColor you need
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
      return 'Today ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference == 1) {
      return 'Tomorrow ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Input Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How to use voice input:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('1. Tap the microphone button to start listening'),
              Text('2. Speak your task clearly'),
              Text('3. Review the parsed task'),
              Text('4. Tap "Save Task" to add it to your list'),
              SizedBox(height: 16),
              Text('Voice Features:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Time: "at 6 PM", "tomorrow"'),
              Text('• Priority: "urgent", "important", "low priority"'),
              Text('• Recurring: "daily", "weekly", "monthly"'),
              Text('• Categories: Auto-detected from keywords'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
