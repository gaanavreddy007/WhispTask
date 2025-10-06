// ignore_for_file: prefer_const_constructors, deprecated_member_use, duplicate_ignore, use_build_context_synchronously, unused_import, unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import '../models/task.dart';
import '../l10n/app_localizations.dart';
import '../services/sentry_service.dart';
import '../utils/safe_context_helper.dart';
// ignore: unused_import
import '../widgets/loading_splash_overlay.dart';

class VoiceInputScreen extends StatefulWidget {
  const VoiceInputScreen({super.key});

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Log screen navigation
    SentryService.logScreenNavigation('VoiceInputScreen');
    
    try {
      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 800), // Faster animation
        vsync: this,
      );
      _pulseAnimation = Tween<double>(
        begin: 1.0,
        end: 1.1, // Reduced scale for better performance
      ).animate(CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ));

      _waveController = AnimationController(
        duration: const Duration(milliseconds: 1500), // Faster wave animation
        vsync: this,
      );

      _slideController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ));
      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
      ));

      _slideController.forward();
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
    _waveController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    if (!mounted) return;
    
    try {
      final voiceProvider = context.read<VoiceProvider>();
      final authProvider = context.read<AuthProvider>();
      
      if (voiceProvider.isListening) {
        SentryService.logUserAction('voice_stop_listening');
        voiceProvider.stopListening();
        _pulseController.stop();
        _waveController.stop();
      } else {
        SentryService.logUserAction('voice_start_listening');
        voiceProvider.startListening(authProvider);
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
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

  Future<void> _saveTask() async {
    if (!mounted) return;
    
    return SentryService.wrapWithErrorTracking(
      () async {
        final voiceProvider = context.read<VoiceProvider>();
        final taskProvider = context.read<TaskProvider>();
        
        SentryService.logUserAction('voice_save_task_attempt', data: {
          'has_preview_task': (voiceProvider.previewTask != null).toString(),
          'is_valid': voiceProvider.isCurrentTaskValid().toString(),
          'is_recurring': (voiceProvider.previewTask?.isRecurring ?? false).toString(),
          'recurring_pattern': voiceProvider.previewTask?.recurringPattern ?? 'none',
          'recurring_interval': voiceProvider.previewTask?.recurringInterval?.toString() ?? 'none',
        });
        
        if (voiceProvider.previewTask == null || !voiceProvider.isCurrentTaskValid()) {
          SentryService.addBreadcrumb(
            message: 'Invalid task validation failed',
            category: 'validation',
            level: 'warning',
          );
          _showSnackBar(SafeContextHelper.getLocalizedText(
            context, 
            (l) => l.pleaseProvideValidTask, 
            'Please provide a valid task'
          ), isError: true);
          return;
        }

        await taskProvider.addTask(voiceProvider.previewTask!);
        
        SentryService.logUserAction('voice_task_saved_success', data: {
          'task_title': voiceProvider.previewTask!.title,
          'task_priority': voiceProvider.previewTask!.priority.toString(),
          'task_category': voiceProvider.previewTask!.category,
          'is_recurring': voiceProvider.previewTask!.isRecurring.toString(),
          'recurring_pattern': voiceProvider.previewTask!.recurringPattern ?? 'none',
          'recurring_interval': voiceProvider.previewTask!.recurringInterval?.toString() ?? 'none',
          'has_due_date': (voiceProvider.previewTask!.dueDate != null).toString(),
        });
        
        _showSnackBar(SafeContextHelper.getLocalizedText(
          context, 
          (l) => l.taskCreatedSuccessfully, 
          'Task created successfully'
        ), isError: false);
        voiceProvider.clearSession();
        
        // Navigate back to task list screen after successful save
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
      operation: 'save_voice_task',
      description: 'Save task from voice input',
      extra: {'screen': 'VoiceInputScreen'},
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    SafeContextHelper.showSafeSnackBar(
      context,
      message,
      backgroundColor: isError ? Colors.red : Colors.green.shade600,
    );
  }

  // Helper method for safe localized text
  String _getSafeText(String Function(AppLocalizations) getter, String fallback) {
    return SafeContextHelper.getLocalizedText(context, getter, fallback);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          SafeContextHelper.getLocalizedText(
            context, 
            (l) => l.voiceInput, 
            'Voice Input'
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2), // Blue header
        elevation: 0,
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.help_outline, size: 22),
              onPressed: () => _showHelpDialog(),
              style: IconButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                    const Color(0xFFCBD5E1),
                  ],
          ),
        ),
        child: SafeArea(
          child: Consumer<VoiceProvider>(
            builder: (context, voiceProvider, child) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Voice button with wave animation
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer wave rings
                                if (voiceProvider.isListening) ...[
                                  for (int i = 0; i < 3; i++)
                                    AnimatedBuilder(
                                      animation: _waveController,
                                      builder: (context, child) {
                                        final delay = i * 0.3;
                                        final animation = Tween<double>(
                                          begin: 0.5,
                                          end: 2.0,
                                        ).animate(CurvedAnimation(
                                          parent: _waveController,
                                          curve: Interval(delay, 1.0, curve: Curves.easeOut),
                                        ));
                                        return Transform.scale(
                                          scale: animation.value,
                                          child: Container(
                                            width: 160,
                                            height: 160,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: (isDarkMode ? Colors.cyanAccent : Colors.blue)
                                                    .withOpacity(0.3 * (1 - animation.value / 2)),
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                                
                                // Main voice button
                                GestureDetector(
                                  onTap: _toggleListening,
                                  child: AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: voiceProvider.isListening ? _pulseAnimation.value : 1.0,
                                        child: _buildCustomVoiceButton(voiceProvider, theme, isDarkMode),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Status text with enhanced styling
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        voiceProvider.isListening 
                            ? _getSafeText((l) => l.listeningSpeak, 'Listening... Speak now')
                            : voiceProvider.isInitialized 
                                ? _getSafeText((l) => l.tapToSpeak, 'Tap to speak') 
                                : _getSafeText((l) => l.initializing, 'Initializing...'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: voiceProvider.isListening 
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Content area
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            // Error message with enhanced styling
                            if (voiceProvider.errorMessage.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [theme.colorScheme.errorContainer.withOpacity(0.3), theme.colorScheme.errorContainer.withOpacity(0.5)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.error.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.error.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        voiceProvider.errorMessage,
                                        style: TextStyle(
                                          color: theme.colorScheme.onErrorContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Recognized text with glassmorphism effect
                            if (voiceProvider.recognizedText.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: isDarkMode 
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDarkMode 
                                      ? Colors.white.withOpacity(0.2)
                                      : theme.colorScheme.primary.withOpacity(0.2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
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
                                            gradient: LinearGradient(
                                              colors: isDarkMode 
                                                ? [Colors.cyan.shade400, Colors.cyan.shade600]
                                                : [theme.colorScheme.primary.withOpacity(0.8), theme.colorScheme.primary],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.record_voice_over, color: theme.colorScheme.onPrimary, size: 16),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _getSafeText((l) => l.youSaid, 'You said:'),
                                          style: TextStyle(
                                            color: isDarkMode ? Colors.cyan.shade300 : theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      voiceProvider.recognizedText,
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.5,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                            ],
                            
                            // Task preview with enhanced design
                            if (voiceProvider.previewTask != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDarkMode 
                                      ? [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.1)]
                                      : [Colors.green.shade50, Colors.green.shade100],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
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
                                            gradient: LinearGradient(
                                              colors: [Colors.green.withOpacity(0.8), Colors.green],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.preview, color: Colors.white, size: 16),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _getSafeText((l) => l.taskPreview, 'Task Preview'),
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTaskPreview(voiceProvider.previewTask!),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Action buttons with modern styling
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: voiceProvider.clearSession,
                                        icon: const Icon(Icons.refresh_rounded, size: 20),
                                        label: Text(
                                          _getSafeText((l) => l.clear, 'Clear'),
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.colorScheme.surfaceVariant,
                                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: voiceProvider.isCurrentTaskValid() 
                                          ? LinearGradient(
                                              colors: isDarkMode 
                                                ? [Colors.cyan.shade400, Colors.cyan.shade600]
                                                : [theme.colorScheme.primary.withOpacity(0.9), theme.colorScheme.primary],
                                            )
                                          : null,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: voiceProvider.isCurrentTaskValid() ? [
                                          BoxShadow(
                                            color: (isDarkMode ? Colors.cyan : theme.colorScheme.primary).withOpacity(0.3),
                                            blurRadius: 15,
                                            offset: const Offset(0, 6),
                                          ),
                                        ] : null,
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: voiceProvider.isCurrentTaskValid() ? _saveTask : null,
                                        icon: const Icon(Icons.save_rounded, size: 20),
                                        label: Text(
                                          _getSafeText((l) => l.saveTask, 'Save Task'),
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: voiceProvider.isCurrentTaskValid() 
                                            ? Colors.transparent 
                                            : Colors.grey.shade400,
                                          foregroundColor: theme.colorScheme.onPrimary,
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 32),
                            ],
                            
                            // Instructions with modern card design
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDarkMode 
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDarkMode 
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isDarkMode ? Colors.orange.shade800 : Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.lightbulb_outline,
                                          color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        AppLocalizations.of(context).voiceCommandsExamples,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildExampleItem(AppLocalizations.of(context).voiceExample1),
                                  _buildExampleItem(AppLocalizations.of(context).voiceExample2),
                                  _buildExampleItem(AppLocalizations.of(context).voiceExample3),
                                  _buildExampleItem(AppLocalizations.of(context).voiceExample4),
                                  _buildExampleItem(AppLocalizations.of(context).voiceExample5),
                                  // Reminder examples
                                  _buildExampleItem("\"Call mom tomorrow and remind me at 3pm\""),
                                  _buildExampleItem("\"Buy groceries today, set reminder 30 minutes before\""),
                                  _buildExampleItem("\"Meeting with client, notify me 1 hour before\""),
                                  _buildExampleItem("\"Take medicine daily, remind me every morning\""),
                                  // Description examples
                                  _buildExampleItem("\"Finish project with description prepare presentation slides\""),
                                  _buildExampleItem("\"Doctor appointment with notes bring insurance card\""),
                                  // Color examples
                                  _buildExampleItem("\"Urgent task in red color\""),
                                  _buildExampleItem("\"Work meeting in blue color\""),
                                  // Repeat days examples
                                  _buildExampleItem("\"Exercise weekly on Monday Wednesday Friday\""),
                                  _buildExampleItem("\"Team meeting every Tuesday and Thursday\""),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExampleItem(String text) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 12),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade600,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskPreview(Task task) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.task_alt, color: Colors.green, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildPreviewChip(AppLocalizations.of(context).category, task.category, theme.colorScheme.primary),
            _buildPreviewChip(AppLocalizations.of(context).priority, task.priority, _getPriorityColor(task.priority)),
            if (task.isRecurring && task.recurringPattern != null)
              _buildPreviewChip(
                AppLocalizations.of(context).recurring, 
                '${task.recurringPattern}${task.recurringInterval != null && task.recurringInterval! > 1 ? ' (every ${task.recurringInterval})' : ''}', 
                Colors.purple
              ),
            if (task.hasReminder && task.reminderTime != null)
              _buildPreviewChip(
                'Reminder', 
                '${_formatDateTime(task.reminderTime!)} (${task.reminderType})', 
                Colors.amber
              ),
          ],
        ),
        if (task.dueDate != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.indigo.shade900.withOpacity(0.3) : Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.indigo.shade400.withOpacity(0.3) : Colors.indigo.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: isDarkMode ? Colors.indigo.shade300 : Colors.indigo.shade600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${AppLocalizations.of(context).due}: ${_formatDateTime(task.dueDate!)}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.indigo.shade300 : Colors.indigo.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewChip(String label, String value, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(isDarkMode ? 0.2 : 0.1),
            color.withOpacity(isDarkMode ? 0.3 : 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: isDarkMode ? color.withOpacity(0.8) : color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      const Color(0xFF1a1a2e),
                      const Color(0xFF16213e),
                    ]
                  : [
                      const Color(0xFFF8FAFC),
                      const Color(0xFFE2E8F0),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode 
                      ? [Colors.cyan.shade400, Colors.cyan.shade600]
                      : [theme.colorScheme.primary.withOpacity(0.9), theme.colorScheme.primary],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.help_outline, color: theme.colorScheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).voiceInputHelp,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // How to use section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context).howToUseVoiceInput,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildHelpStep("1", AppLocalizations.of(context).voiceStep1),
                            _buildHelpStep("2", AppLocalizations.of(context).voiceStep2),
                            _buildHelpStep("3", AppLocalizations.of(context).voiceStep3),
                            _buildHelpStep("4", AppLocalizations.of(context).voiceStep4),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Features section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.purple.shade800 : Colors.purple.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    size: 16,
                                    color: isDarkMode ? Colors.purple.shade300 : Colors.purple.shade700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context).voiceFeatures,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDarkMode ? Colors.purple.shade300 : Colors.purple.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildFeatureItem(Icons.schedule, AppLocalizations.of(context).voiceFeatureTime),
                            _buildFeatureItem(Icons.priority_high, AppLocalizations.of(context).voiceFeaturePriority),
                            _buildFeatureItem(Icons.repeat, AppLocalizations.of(context).voiceFeatureRecurring),
                            _buildFeatureItem(Icons.category, AppLocalizations.of(context).voiceFeatureCategories),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Footer
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.cyan.shade600 : theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).gotIt,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpStep(String stepNumber, String text) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode 
                  ? [Colors.cyan.shade400, Colors.cyan.shade600]
                  : [theme.colorScheme.primary.withOpacity(0.8), theme.colorScheme.primary],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.purple.shade800.withOpacity(0.3) : Colors.purple.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isDarkMode ? Colors.purple.shade300 : Colors.purple.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomVoiceButton(VoiceProvider voiceProvider, ThemeData theme, bool isDarkMode) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: voiceProvider.isListening 
            ? [
                Colors.red.shade400,
                Colors.red.shade600,
                Colors.red.shade800,
              ]
            : isDarkMode 
              ? [
                  const Color(0xFF00BCD4), // Cyan 500
                  const Color(0xFF0097A7), // Cyan 700
                  const Color(0xFF006064), // Cyan 900
                ]
              : [
                  const Color(0xFF2196F3), // Blue 500
                  const Color(0xFF1976D2), // Blue 700
                  const Color(0xFF0D47A1), // Blue 900
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: voiceProvider.isListening 
              ? Colors.red.withOpacity(0.4)
              : (isDarkMode ? const Color(0xFF00BCD4) : const Color(0xFF2196F3)).withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: voiceProvider.isListening 
              ? Colors.red.withOpacity(0.2)
              : (isDarkMode ? const Color(0xFF00BCD4) : const Color(0xFF2196F3)).withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: -5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(60),
          onTap: _toggleListening,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  voiceProvider.isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  key: ValueKey(voiceProvider.isListening),
                  size: 48,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}