// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

// Voice command error codes
class VoiceErrorCodes {
  static const String VOICE_NOT_INITIALIZED = 'VOICE_NOT_INITIALIZED';
  static const String MICROPHONE_PERMISSION_DENIED = 'MICROPHONE_PERMISSION_DENIED';
  static const String SPEECH_RECOGNITION_ERROR = 'SPEECH_RECOGNITION_ERROR';
  static const String WAKE_WORD_NOT_DETECTED = 'WAKE_WORD_NOT_DETECTED';
  static const String COMMAND_NOT_RECOGNIZED = 'COMMAND_NOT_RECOGNIZED';
  static const String TASK_NOT_FOUND = 'TASK_NOT_FOUND';
  static const String MULTIPLE_TASKS_FOUND = 'MULTIPLE_TASKS_FOUND';
  static const String INVALID_COMMAND_FORMAT = 'INVALID_COMMAND_FORMAT';
  static const String TTS_NOT_AVAILABLE = 'TTS_NOT_AVAILABLE';
  static const String NETWORK_ERROR = 'NETWORK_ERROR';
  static const String TIMEOUT_ERROR = 'TIMEOUT_ERROR';
  static const String ACCENT_NOT_SUPPORTED = 'ACCENT_NOT_SUPPORTED';
  static const String VOICE_SERVICE_BUSY = 'VOICE_SERVICE_BUSY';
  static const String COMMAND_PROCESSING_FAILED = 'COMMAND_PROCESSING_FAILED';
  static const String TASK_UPDATE_FAILED = 'TASK_UPDATE_FAILED';
}

// Voice error class
class VoiceError {
  final String code;
  final String message;
  final String? details;
  final DateTime timestamp;
  final String? context;

  VoiceError({
    required this.code,
    required this.message,
    this.details,
    this.context,
  }) : timestamp = DateTime.now();

  // Factory constructors for common errors
  factory VoiceError.notInitialized() {
    return VoiceError(
      code: VoiceErrorCodes.VOICE_NOT_INITIALIZED,
      message: 'Voice service is not initialized. Please initialize the service first.',
      context: 'VoiceService.initialize()',
    );
  }

  factory VoiceError.microphonePermissionDenied() {
    return VoiceError(
      code: VoiceErrorCodes.MICROPHONE_PERMISSION_DENIED,
      message: 'Microphone permission is required for voice commands.',
      details: 'Please grant microphone permission in your device settings.',
      context: 'Permission.microphone.request()',
    );
  }

  factory VoiceError.speechRecognitionError(String error) {
    return VoiceError(
      code: VoiceErrorCodes.SPEECH_RECOGNITION_ERROR,
      message: 'Speech recognition failed.',
      details: error,
      context: 'SpeechToText.listen()',
    );
  }

  factory VoiceError.wakeWordNotDetected() {
    return VoiceError(
      code: VoiceErrorCodes.WAKE_WORD_NOT_DETECTED,
      message: 'Wake word "Hey Whisp" was not detected.',
      details: 'Please speak clearly and ensure you say "Hey Whisp" before your command.',
      context: 'WakeWordDetection',
    );
  }

  factory VoiceError.commandNotRecognized(String command) {
    return VoiceError(
      code: VoiceErrorCodes.COMMAND_NOT_RECOGNIZED,
      message: 'Voice command was not recognized.',
      details: 'Command: "$command"',
      context: 'VoiceParser.parseVoiceCommand()',
    );
  }

  factory VoiceError.taskNotFound(String taskIdentifier) {
    return VoiceError(
      code: VoiceErrorCodes.TASK_NOT_FOUND,
      message: 'No task found matching the description.',
      details: 'Task identifier: "$taskIdentifier"',
      context: 'TaskProvider.findTaskByVoiceIdentifier()',
    );
  }

  factory VoiceError.multipleTasksFound(int count, String taskIdentifier) {
    return VoiceError(
      code: VoiceErrorCodes.MULTIPLE_TASKS_FOUND,
      message: 'Multiple tasks found matching the description.',
      details: 'Found $count tasks for identifier: "$taskIdentifier"',
      context: 'TaskProvider.findTaskByVoiceIdentifier()',
    );
  }

  factory VoiceError.invalidCommandFormat(String command) {
    return VoiceError(
      code: VoiceErrorCodes.INVALID_COMMAND_FORMAT,
      message: 'Command format is not valid.',
      details: 'Command: "$command"',
      context: 'VoiceParser.parseVoiceCommand()',
    );
  }

  factory VoiceError.ttsNotAvailable() {
    return VoiceError(
      code: VoiceErrorCodes.TTS_NOT_AVAILABLE,
      message: 'Text-to-speech service is not available.',
      details: 'Please check if TTS is properly initialized.',
      context: 'TtsService.speak()',
    );
  }

  factory VoiceError.networkError(String error) {
    return VoiceError(
      code: VoiceErrorCodes.NETWORK_ERROR,
      message: 'Network error occurred during voice processing.',
      details: error,
      context: 'NetworkRequest',
    );
  }

  factory VoiceError.timeoutError(String operation) {
    return VoiceError(
      code: VoiceErrorCodes.TIMEOUT_ERROR,
      message: 'Operation timed out.',
      details: 'Operation: $operation',
      context: 'TimeoutHandler',
    );
  }

  factory VoiceError.accentNotSupported(String locale) {
    return VoiceError(
      code: VoiceErrorCodes.ACCENT_NOT_SUPPORTED,
      message: 'Accent or language not supported.',
      details: 'Locale: $locale',
      context: 'AccentDetection',
    );
  }

  factory VoiceError.serviceBusy() {
    return VoiceError(
      code: VoiceErrorCodes.VOICE_SERVICE_BUSY,
      message: 'Voice service is currently busy processing another command.',
      details: 'Please wait for the current operation to complete.',
      context: 'VoiceService.processCommand()',
    );
  }

  factory VoiceError.commandProcessingFailed(String command, String error) {
    return VoiceError(
      code: VoiceErrorCodes.COMMAND_PROCESSING_FAILED,
      message: 'Failed to process voice command.',
      details: 'Command: "$command", Error: $error',
      context: 'CommandProcessor',
    );
  }

  factory VoiceError.taskUpdateFailed(String taskId, String error) {
    return VoiceError(
      code: VoiceErrorCodes.TASK_UPDATE_FAILED,
      message: 'Failed to update task.',
      details: 'Task ID: $taskId, Error: $error',
      context: 'TaskProvider.updateTask()',
    );
  }

  // Get user-friendly error message
  String getUserFriendlyMessage() {
    switch (code) {
      case VoiceErrorCodes.VOICE_NOT_INITIALIZED:
        return 'Voice commands are not ready yet. Please try again in a moment.';
      
      case VoiceErrorCodes.MICROPHONE_PERMISSION_DENIED:
        return 'I need microphone permission to hear your voice commands. Please enable it in settings.';
      
      case VoiceErrorCodes.SPEECH_RECOGNITION_ERROR:
        return 'I had trouble hearing you. Please try speaking again.';
      
      case VoiceErrorCodes.WAKE_WORD_NOT_DETECTED:
        return 'Please start your command with "Hey Whisp" to get my attention.';
      
      case VoiceErrorCodes.COMMAND_NOT_RECOGNIZED:
        return 'I didn\'t understand that command. Try saying something like "Mark task as done" or "Create task buy groceries".';
      
      case VoiceErrorCodes.TASK_NOT_FOUND:
        return 'I couldn\'t find a task matching that description. Please try being more specific.';
      
      case VoiceErrorCodes.MULTIPLE_TASKS_FOUND:
        return 'I found multiple tasks with that description. Please be more specific about which task you mean.';
      
      case VoiceErrorCodes.INVALID_COMMAND_FORMAT:
        return 'That command format isn\'t quite right. Try commands like "Complete homework" or "Start project work".';
      
      case VoiceErrorCodes.TTS_NOT_AVAILABLE:
        return 'Voice feedback is temporarily unavailable.';
      
      case VoiceErrorCodes.NETWORK_ERROR:
        return 'Network connection issue. Please check your internet connection.';
      
      case VoiceErrorCodes.TIMEOUT_ERROR:
        return 'The operation took too long. Please try again.';
      
      case VoiceErrorCodes.ACCENT_NOT_SUPPORTED:
        return 'Having trouble with your accent. Try speaking more slowly and clearly.';
      
      case VoiceErrorCodes.VOICE_SERVICE_BUSY:
        return 'I\'m still processing your last command. Please wait a moment.';
      
      case VoiceErrorCodes.COMMAND_PROCESSING_FAILED:
        return 'Something went wrong processing your command. Please try again.';
      
      case VoiceErrorCodes.TASK_UPDATE_FAILED:
        return 'I couldn\'t update that task. Please try again or update it manually.';
      
      default:
        return 'Something went wrong with voice commands. Please try again.';
    }
  }

  // Get suggested actions for the error
  List<String> getSuggestedActions() {
    switch (code) {
      case VoiceErrorCodes.VOICE_NOT_INITIALIZED:
        return ['Wait a moment and try again', 'Restart the app if the problem persists'];
      
      case VoiceErrorCodes.MICROPHONE_PERMISSION_DENIED:
        return ['Go to Settings > Privacy > Microphone', 'Enable microphone access for this app'];
      
      case VoiceErrorCodes.SPEECH_RECOGNITION_ERROR:
        return ['Speak more clearly', 'Reduce background noise', 'Try again in a quieter environment'];
      
      case VoiceErrorCodes.WAKE_WORD_NOT_DETECTED:
        return ['Say "Hey Whisp" clearly before your command', 'Pause briefly after saying "Hey Whisp"'];
      
      case VoiceErrorCodes.COMMAND_NOT_RECOGNIZED:
        return [
          'Try: "Mark [task name] as done"',
          'Try: "Create task [task description]"',
          'Try: "Start working on [task name]"',
          'Tap the help button for more examples'
        ];
      
      case VoiceErrorCodes.TASK_NOT_FOUND:
        return [
          'Use more specific task names',
          'Try using the first few words of the task title',
          'Check your task list to see exact task names'
        ];
      
      case VoiceErrorCodes.MULTIPLE_TASKS_FOUND:
        return [
          'Be more specific about which task',
          'Use unique words from the task title',
          'Try saying "first task" or "second task"'
        ];
      
      case VoiceErrorCodes.ACCENT_NOT_SUPPORTED:
        return [
          'Speak more slowly',
          'Try using simpler words',
          'Consider switching to manual task management'
        ];
      
      default:
        return ['Try again', 'Check your internet connection', 'Restart the app if needed'];
    }
  }

  // Check if error is recoverable
  bool isRecoverable() {
    const nonRecoverableErrors = [
      VoiceErrorCodes.MICROPHONE_PERMISSION_DENIED,
      VoiceErrorCodes.TTS_NOT_AVAILABLE,
      VoiceErrorCodes.ACCENT_NOT_SUPPORTED,
    ];
    
    return !nonRecoverableErrors.contains(code);
  }

  // Get retry delay in seconds
  int getRetryDelaySeconds() {
    switch (code) {
      case VoiceErrorCodes.VOICE_SERVICE_BUSY:
        return 3;
      case VoiceErrorCodes.SPEECH_RECOGNITION_ERROR:
        return 2;
      case VoiceErrorCodes.NETWORK_ERROR:
        return 5;
      case VoiceErrorCodes.TIMEOUT_ERROR:
        return 3;
      default:
        return 1;
    }
  }

  @override
  String toString() {
    return 'VoiceError(code: $code, message: $message, details: $details, context: $context, timestamp: $timestamp)';
  }

  // Convert to JSON for logging
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'details': details,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// Voice error handler utility class
class VoiceErrorHandler {
  static final List<VoiceError> _errorHistory = [];
  static const int maxHistorySize = 50;

  // Log an error
  static void logError(VoiceError error) {
    _errorHistory.add(error);
    
    // Keep history size manageable
    if (_errorHistory.length > maxHistorySize) {
      _errorHistory.removeAt(0);
    }
    
    debugPrint('Voice Error: ${error.toString()}');
  }

  // Get recent errors
  static List<VoiceError> getRecentErrors({int limit = 10}) {
    final startIndex = _errorHistory.length > limit ? _errorHistory.length - limit : 0;
    return _errorHistory.sublist(startIndex);
  }

  // Check if error occurred recently
  static bool hasRecentError(String errorCode, {Duration within = const Duration(minutes: 5)}) {
    final cutoff = DateTime.now().subtract(within);
    return _errorHistory.any((error) => 
        error.code == errorCode && error.timestamp.isAfter(cutoff));
  }

  // Get error frequency
  static Map<String, int> getErrorFrequency() {
    final frequency = <String, int>{};
    for (final error in _errorHistory) {
      frequency[error.code] = (frequency[error.code] ?? 0) + 1;
    }
    return frequency;
  }

  // Clear error history
  static void clearHistory() {
    _errorHistory.clear();
  }

  // Handle error with appropriate response
  static Future<void> handleError(VoiceError error, {Function(String)? onSpeak}) async {
    logError(error);
    
    // Provide voice feedback if available
    if (onSpeak != null) {
      await onSpeak(error.getUserFriendlyMessage());
    }
    
    // Additional handling based on error type
    switch (error.code) {
      case VoiceErrorCodes.MICROPHONE_PERMISSION_DENIED:
        // Could trigger permission request dialog
        break;
      case VoiceErrorCodes.VOICE_SERVICE_BUSY:
        // Could implement retry logic
        break;
      default:
        break;
    }
  }
}
