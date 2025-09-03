// ignore_for_file: deprecated_member_use, duplicate_ignore, avoid_print, prefer_const_constructors, unused_field, unused_import, unused_element, prefer_final_fields

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../providers/auth_provider.dart';
import 'voice_parser.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _speechEnabled = false;
  String _lastWords = '';
  AuthProvider? _authProvider;
  
  // Wake word detection properties
  bool _isWakeWordListening = false;
  Timer? _wakeWordTimer;
  StreamController<String>? _voiceCommandController;
  
  // Error tracking for exponential backoff and circuit breaker
  int _consecutiveErrors = 0;
  DateTime? _lastErrorTime;
  bool _isInErrorHandling = false;
  bool _circuitBreakerOpen = false;
  DateTime? _circuitBreakerOpenTime;
  static const int maxConsecutiveErrors = 3; // Reduced threshold
  static const Duration errorCooldownPeriod = Duration(minutes: 2);
  static const Duration circuitBreakerTimeout = Duration(minutes: 5);
  
  // Wake word configuration
  static const String wakeWord = 'hey whisp';
  static const Duration wakeWordTimeout = Duration(seconds: 5);
  
  // Multi-accent support
  List<LocaleName> _supportedLocales = [];
  String _currentLocale = 'en_US';
  final List<String> _supportedAccents = [
    'en_US', // American English
    'en_GB', // British English
    'en_AU', // Australian English
    'en_CA', // Canadian English
    'en_IN', // Indian English
  ];
  
  // Getters
  bool get isListening => _speechToText.isListening;
  bool get isEnabled => _speechEnabled;
  String get lastWords => _lastWords;
  bool get isWakeWordActive => _isWakeWordListening;
  Stream<String>? get voiceCommandStream => _voiceCommandController?.stream;

  // Premium voice features
  bool canUseCustomVoices() {
    return _authProvider?.isPremium == true;
  }

  List<String> getAvailableVoices() {
    if (canUseCustomVoices()) {
      return ['default', 'male', 'female', 'robotic', 'calm', 'energetic'];
    }
    return ['default'];
  }

  Future<void> setVoiceType(String voiceType) async {
    if (!canUseCustomVoices() && voiceType != 'default') {
      throw Exception('Custom voices are a premium feature. Upgrade to Pro!');
    }

    try {
      switch (voiceType) {
        case 'male':
          await _flutterTts.setVoice({"name": "en-us-x-sfg#male_1-local", "locale": "en-US"});
          break;
        case 'female':
          await _flutterTts.setVoice({"name": "en-us-x-sfg#female_1-local", "locale": "en-US"});
          break;
        case 'robotic':
          await _flutterTts.setPitch(0.5);
          await _flutterTts.setSpeechRate(0.3);
          break;
        case 'calm':
          await _flutterTts.setPitch(0.8);
          await _flutterTts.setSpeechRate(0.4);
          break;
        case 'energetic':
          await _flutterTts.setPitch(1.2);
          await _flutterTts.setSpeechRate(0.6);
          break;
        default:
          await _flutterTts.setPitch(1.0);
          await _flutterTts.setSpeechRate(0.5);
      }
    } catch (e) {
      print('Error initializing voice service: $e');
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('service', 'voice');
          scope.setTag('operation', 'initialize');
          scope.level = SentryLevel.error;
        },
      );
      _speechEnabled = false;
      rethrow;
    }
  }

  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  // Initialize speech recognition
  Future<bool> initialize() async {
    try {
      print('VoiceService: Initializing speech recognition...');
      
      // Check if speech recognition is available
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          print('VoiceService: Speech status: $status');
          if (status == 'listening') {
            _resetErrorCount();
            _isInErrorHandling = false;
          } else if (status == 'notListening' && _isWakeWordListening) {
            // Restart wake word listening if it stops unexpectedly
            Future.delayed(Duration(seconds: 1), () {
              if (_isWakeWordListening && !_speechToText.isListening) {
                _startListeningForWakeWord(_currentLocale);
              }
            });
          }
        },
        onError: (error) {
          print('VoiceService: Speech error: $error');
          _handleSpeechError(error);
        },
        debugLogging: false,
      );
      
      if (!available) {
        print('VoiceService: Speech recognition not available or permission denied');
        _speechEnabled = false;
        return false;
      }
      
      _speechEnabled = true;
      print('VoiceService: Speech recognition initialized successfully');
      
      // Initialize TTS
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5); // Normal speech rate
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      
      print('VoiceService: Initializing multi-accent support...');
      await _initializeMultiAccentSupport();
      
      print('VoiceService: Creating voice command controller...');
      _voiceCommandController = StreamController<String>.broadcast();
      
      print('VoiceService: Voice service initialized successfully: $_speechEnabled');
      return _speechEnabled;
    } catch (e) {
      print('VoiceService: Initialization failed: $e');
      return false;
    }
  }

  // Start listening for voice input
  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'en_US',
  }) async {
    if (!_speechEnabled) {
      debugPrint('Speech recognition not enabled');
      return;
    }

    await _speechToText.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        onResult(_lastWords);
        debugPrint('Voice input: $_lastWords');
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      // ignore: deprecated_member_use
      partialResults: true,
    );
  }

  // Start wake word detection
  Future<void> startWakeWordListening([String localeId = 'en_US']) async {
    if (!_speechEnabled) {
      print('VoiceService: Speech recognition not enabled');
      return;
    }

    _isWakeWordListening = true;
    print('VoiceService: Starting wake word detection...');
    
    _startListeningForWakeWord(localeId);
  }

  // Handle speech recognition errors with intelligent recovery
  void _onSpeechError(dynamic error) {
    print('Speech recognition error: $error');
    _consecutiveErrors++;
    _lastErrorTime = DateTime.now();
    
    // Handle specific error types with appropriate responses
    String userMessage = '';
    bool shouldRestart = true;
    String errorMsg = error.toString().toLowerCase();
    
    if (errorMsg.contains('no_match')) {
      userMessage = 'I didn\'t catch that. Please try speaking again.';
    } else if (errorMsg.contains('timeout')) {
      userMessage = 'Speech timeout. Please speak more clearly.';
    } else if (errorMsg.contains('audio')) {
      userMessage = 'Audio error detected. Checking microphone.';
      shouldRestart = false;
    } else if (errorMsg.contains('network')) {
      userMessage = 'Network error. Please check your connection.';
      shouldRestart = false;
    } else if (errorMsg.contains('busy')) {
      userMessage = 'Speech service is busy. Retrying in a moment.';
    } else if (errorMsg.contains('permission')) {
      userMessage = 'Microphone permission required. Please enable in settings.';
      shouldRestart = false;
    } else {
      userMessage = 'Voice recognition error. Please try again.';
    }
    
    // Exponential backoff for errors
    final backoffSeconds = math.min(2 * math.pow(2, _consecutiveErrors - 1).toInt(), 30);
    
    if (_consecutiveErrors >= 5) {
      // Stop listening after too many errors and implement cooldown
      _isWakeWordListening = false;
      _speechToText.stop();
      
      _provideFeedback('Voice recognition is having issues. Please try again in a few minutes.');
      
      // Implement 2-minute cooldown
      Timer(Duration(minutes: 2), () {
        _consecutiveErrors = 0;
        print('Error cooldown period ended. Voice recognition available again.');
      });
    } else if (shouldRestart) {
      // Provide user feedback
      _provideFeedback(userMessage);
      
      // Restart with backoff delay
      Timer(Duration(seconds: backoffSeconds), () {
        if (!_isWakeWordListening) {
          _startListeningForWakeWord(_currentLocale);
        }
      });
    } else {
      // For critical errors, stop and inform user
      _isWakeWordListening = false;
      _speechToText.stop();
      _provideFeedback(userMessage);
    }
  }

  // Additional error handling methods for comprehensive voice scenarios
  void _handleSpeechError(dynamic error) {
    print('VoiceService: Handling speech error: $error');
    _onSpeechError(error);
  }

  // Add missing methods to fix lint errors
  void stopWakeWordListening() {
    _isWakeWordListening = false;
    _wakeWordTimer?.cancel();
  }

  void stopListening() {
    _isWakeWordListening = false;
    _speechToText.stop();
  }


  void cancelListening() {
    _isWakeWordListening = false;
    _speechToText.cancel();
  }


  // Method to check if voice service is healthy
  bool isVoiceServiceHealthy() {
    return _speechEnabled && 
           _consecutiveErrors < 3 && 
           (_lastErrorTime == null || 
            DateTime.now().difference(_lastErrorTime!).inMinutes > 1);
  }

  // Method to get error status for UI feedback
  String getErrorStatus() {
    if (_consecutiveErrors == 0) return 'Voice service is working normally';
    if (_consecutiveErrors < 3) return 'Minor voice issues detected';
    if (_consecutiveErrors < 5) return 'Voice service experiencing problems';
    return 'Voice service temporarily unavailable';
  }

  // Method to manually retry voice service after errors
  Future<void> retryVoiceService() async {
    print('VoiceService: Manual retry requested');
    _consecutiveErrors = 0;
    _lastErrorTime = null;
    
    if (!_speechEnabled) {
      await initialize();
    }
    
    if (_speechEnabled && !_isWakeWordListening) {
      startWakeWordListening();
    }
  }

  // Reset error count on successful operation
  void _resetErrorCount() {
    if (_consecutiveErrors > 0) {
      print('VoiceService: Resetting error count (was $_consecutiveErrors)');
      _consecutiveErrors = 0;
      _lastErrorTime = null;
    }
  }

  // Start listening with circuit breaker pattern for stability
  void _startListeningForWakeWord(String localeId) {
    if (!_isWakeWordListening || !_speechEnabled || _speechToText.isListening) {
      return;
    }

    // Check circuit breaker state
    if (_circuitBreakerOpen) {
      if (_circuitBreakerOpenTime != null) {
        final timeSinceOpen = DateTime.now().difference(_circuitBreakerOpenTime!);
        if (timeSinceOpen < circuitBreakerTimeout) {
          print('VoiceService: Circuit breaker open - ${circuitBreakerTimeout.inMinutes - timeSinceOpen.inMinutes} minutes remaining');
          return;
        } else {
          // Reset circuit breaker
          print('VoiceService: Circuit breaker timeout expired, attempting reset');
          _circuitBreakerOpen = false;
          _circuitBreakerOpenTime = null;
          _consecutiveErrors = 0;
        }
      }
    }

    // Check if we're in error recovery mode
    if (_isInErrorHandling) {
      print('VoiceService: Cannot start - still in error recovery mode');
      return;
    }

    // Prevent rapid restarts after recent errors
    if (_lastErrorTime != null) {
      final timeSinceError = DateTime.now().difference(_lastErrorTime!);
      if (timeSinceError.inSeconds < 2) {
        print('VoiceService: Too soon after last error (${timeSinceError.inSeconds}s), waiting...');
        Future.delayed(Duration(seconds: 2 - timeSinceError.inSeconds), () {
          if (_isWakeWordListening) _startListeningForWakeWord(localeId);
        });
        return;
      }
    }

    print('VoiceService: Starting to listen for wake word...');
    
    try {
      _speechToText.listen(
        onResult: (result) {
          final words = result.recognizedWords.toLowerCase();
          if (words.trim().isNotEmpty) {
            print('VoiceService: Speech detected: "$words"');
            _resetErrorCount(); // Reset error count on successful speech detection
            // ULTRA-AGGRESSIVE: Process ANY meaningful speech as a potential command
            _processTaskUpdateCommand(words);
          }
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 10), // Reduced to prevent long timeouts
        pauseFor: const Duration(seconds: 2), // Shorter pause
        partialResults: false,
        cancelOnError: false, // Let our error handler manage this
      );
      
      // Reset error count on successful start
      _resetErrorCount();
    } catch (e) {
      print('VoiceService: Exception starting speech recognition: $e');
      _handleSpeechError(e);
    }
  }

  // Process task update commands with comprehensive validation
  void _processTaskUpdateCommand(String command) {
    _wakeWordTimer?.cancel();
    
    final lowerCommand = command.toLowerCase();
    print('VoiceService: Processing task update command: "$command"');
    
    // Parse command with full validation
    final parsedCommand = VoiceParser.parseVoiceCommand(command);
    
    // Handle validation errors
    if (parsedCommand['type'] == 'error') {
      print('VoiceService: Invalid command - ${parsedCommand['errorType']}: ${parsedCommand['suggestion']}');
      _provideFeedback(parsedCommand['suggestion'] ?? 'Please try again with a clearer command');
      
      // Restart listening after feedback
      Future.delayed(const Duration(seconds: 3), () {
        if (_isWakeWordListening) {
          _startListeningForWakeWord(_currentLocale);
        }
      });
      return;
    }
    
    // Handle ambiguous commands with confirmation
    if (_isAmbiguousCommand(command)) {
      _handleAmbiguousCommand(command);
      return;
    }
    
    // Send validated command to controller for processing
    if (_voiceCommandController != null && !_voiceCommandController!.isClosed) {
      print('VoiceService: Sending validated command to controller');
      _voiceCommandController!.add(command);
      print('VoiceService: Command sent to controller');
    }
    
    // Check if this matches our task update patterns
    if (VoiceParser.isTaskUpdateCommand(lowerCommand)) {
      print('VoiceService: Command matches task update patterns');
    }
    
    // Restart listening after processing
    Future.delayed(const Duration(seconds: 2), () {
      if (_isWakeWordListening) {
        _startListeningForWakeWord(_currentLocale);
      }
    });
  }
  
  // Check if command is ambiguous and needs clarification
  bool _isAmbiguousCommand(String command) {
    final lowerCommand = command.toLowerCase();
    
    // Check for multiple possible interpretations
    final ambiguousPatterns = [
      'buy homework', // Could be misheard "homework" or actual "buy"
      'call work', // Could be "call" action or "work" task
      'email today', // Could be "email" task or time reference
      'meeting tomorrow', // Could be task name or due date
    ];
    
    return ambiguousPatterns.any((pattern) => lowerCommand.contains(pattern));
  }
  
  // Handle ambiguous commands with user confirmation
  void _handleAmbiguousCommand(String command) {
    final lowerCommand = command.toLowerCase();
    
    if (lowerCommand.contains('buy homework') || lowerCommand.contains('bike homework')) {
      _provideFeedback('Did you mean create a homework task, or buy groceries? Say homework or groceries.');
      _waitForConfirmationResponse(command, ['homework', 'groceries']);
    } else if (lowerCommand.contains('call work')) {
      _provideFeedback('Did you mean call someone, or create a work task? Say call or work.');
      _waitForConfirmationResponse(command, ['call', 'work']);
    } else {
      _provideFeedback('That command was unclear. Please try again.');
      _restartListeningAfterDelay(3);
    }
  }
  
  // Wait for confirmation response from user
  void _waitForConfirmationResponse(String originalCommand, List<String> expectedResponses) {
    print('VoiceService: Waiting for confirmation response...');
    
    // Start listening for confirmation
    Future.delayed(Duration(seconds: 2), () async {
      if (!_speechToText.isListening) {
        try {
          await _speechToText.listen(
            onResult: (result) {
              final response = result.recognizedWords.toLowerCase().trim();
              print('VoiceService: Confirmation response: "$response"');
              
              // Check if response matches expected options
              for (String expected in expectedResponses) {
                if (response.contains(expected)) {
                  _processConfirmedCommand(originalCommand, expected);
                  return;
                }
              }
              
              // If no match, ask again
              _provideFeedback('Please say one of the options clearly.');
              _restartListeningAfterDelay(2);
            },
            listenFor: Duration(seconds: 5),
            localeId: _currentLocale,
          );
        } catch (e) {
          print('VoiceService: Error waiting for confirmation: $e');
          _restartListeningAfterDelay(2);
        }
      }
    });
  }
  
  // Process confirmed command based on user's clarification
  void _processConfirmedCommand(String originalCommand, String confirmation) {
    print('VoiceService: Processing confirmed command: "$originalCommand" with confirmation: "$confirmation"');
    
    String processedCommand = originalCommand;
    
    // Modify command based on confirmation
    if (confirmation == 'homework') {
      processedCommand = originalCommand.replaceAll(RegExp(r'\b(buy|bike)\b'), '').trim();
    } else if (confirmation == 'groceries') {
      processedCommand = 'buy groceries';
    } else if (confirmation == 'call') {
      processedCommand = 'call someone';
    } else if (confirmation == 'work') {
      processedCommand = 'work task';
    }
    
    // Send confirmed command to controller
    if (_voiceCommandController != null && !_voiceCommandController!.isClosed) {
      _voiceCommandController!.add(processedCommand);
    }
    
    _provideFeedback('Got it! Processing your command.');
    _restartListeningAfterDelay(2);
  }
  
  // Helper method to restart listening after a delay
  void _restartListeningAfterDelay(int seconds) {
    Future.delayed(Duration(seconds: seconds), () {
      if (_isWakeWordListening) {
        _startListeningForWakeWord(_currentLocale);
      }
    });
  }
  
  // Provide audio feedback to user
  void _provideFeedback(String message) {
    try {
      _flutterTts.speak(message);
    } catch (e) {
      print('VoiceService: TTS error: $e');
    }
  }

  // Extract task identifier from voice command
  String extractTaskIdentifier(String command) {
    final lowerCommand = command.toLowerCase();
    
    // Patterns to remove
    final patterns = [
      'mark as done', 'mark as complete', 'mark as finished',
      'mark complete', 'mark finished', 'mark done',
      'complete', 'finish', 'done',
      'set as done', 'set as complete',
      'task complete', 'task done',
      'the task', 'my task', 'task'
    ];

    String taskIdentifier = lowerCommand;
    
    // Remove command patterns
    for (String pattern in patterns) {
      taskIdentifier = taskIdentifier.replaceAll(pattern, '').trim();
    }

    // Clean up extra words
    taskIdentifier = taskIdentifier
        .replaceAll(RegExp(r'\b(the|my|a|an)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    debugPrint('Extracted task identifier: "$taskIdentifier"');
    return taskIdentifier;
  }

  // Comprehensive error recovery methods
  Future<bool> recoverFromError() async {
    print('VoiceService: Attempting error recovery...');
    
    try {
      // Stop all current operations
      if (_speechToText.isListening) {
        _speechToText.stop();
      }
      
      // Reset error state
      _consecutiveErrors = 0;
      _lastErrorTime = null;
      _isInErrorHandling = false;
      
      // Reinitialize speech service
      await initialize();
      
      if (_speechEnabled) {
        _provideFeedback('Voice service recovered. You can try again now.');
        return true;
      } else {
        _provideFeedback('Voice service could not be recovered. Please check microphone permissions.');
        return false;
      }
    } catch (e) {
      print('VoiceService: Error recovery failed: $e');
      _provideFeedback('Voice service recovery failed. Please restart the app.');
      return false;
    }
  }

  // Method to handle timeout scenarios specifically
  void _handleTimeout() {
    print('VoiceService: Handling timeout scenario');
    
    if (_consecutiveErrors < 2) {
      _provideFeedback('I\'m listening. Please speak your command.');
      _restartListeningAfterDelay(1);
    } else {
      _provideFeedback('Having trouble hearing you. Please speak louder and clearer.');
      _restartListeningAfterDelay(3);
    }
  }

  // Method to handle network errors specifically
  void _handleNetworkError() {
    print('VoiceService: Handling network error');
    _provideFeedback('Network connection issue. Voice commands may not work properly.');
    
    // Don't restart immediately for network errors
    _isWakeWordListening = false;
  }

  // Method to handle permission errors specifically
  void _handlePermissionError() {
    print('VoiceService: Handling permission error');
    _provideFeedback('Microphone permission is required. Please enable it in your device settings.');
    
    // Stop all voice operations
    _isWakeWordListening = false;
    _speechToText.stop();
  }


  // Get available locales
  Future<List<LocaleName>> getLocales() async {
    final locales = await _speechToText.locales();
    _supportedLocales = locales;
    return locales;
  }

  // Test accent compatibility
  Future<bool> testAccentCompatibility(String testPhrase, String localeId) async {
    if (!_speechEnabled) return false;

    bool testPassed = false;
    
    await _speechToText.listen(
      onResult: (result) {
        final recognizedText = result.recognizedWords.toLowerCase();
        if (recognizedText.contains(testPhrase.toLowerCase())) {
          testPassed = true;
        }
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 5),
      // ignore: deprecated_member_use
      partialResults: false,
    );

    await Future.delayed(const Duration(seconds: 6));
    return testPassed;
  }

  // Get command reliability score
  Future<double> getCommandReliabilityScore() async {
    // Test common commands with different accents
    final testCommands = [
      'hey whisp',
      'mark as done',
      'complete task',
      'finish grocery'
    ];

    int successCount = 0;
    for (String command in testCommands) {
      bool success = await testAccentCompatibility(command, 'en_US');
      if (success) successCount++;
      
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return successCount / testCommands.length;
  }

  // Enhanced initialization with multi-accent support
  Future<void> _initializeMultiAccentSupport() async {
    try {
      _supportedLocales = await _speechToText.locales();
      
      if (_supportedLocales.isNotEmpty) {
        // Find best English locale
        final englishLocales = _supportedLocales.where((locale) => 
          locale.localeId.toLowerCase().startsWith('en')).toList();
        
        if (englishLocales.isNotEmpty) {
          _currentLocale = englishLocales.first.localeId;
          print('VoiceService: Using English locale: $_currentLocale');
        } else if (_supportedLocales.isNotEmpty) {
          _currentLocale = _supportedLocales.first.localeId;
          print('VoiceService: Using default locale: $_currentLocale');
        } else {
          _currentLocale = 'en_US';
          print('VoiceService: No locales found, using fallback: $_currentLocale');
        }
        
        print('VoiceService: Multi-accent support initialized');
      }
    } catch (e) {
      print('VoiceService: Failed to initialize multi-accent support: $e');
      _currentLocale = 'en_US';
    }
  }

  // Get current speech recognition status
  String getStatus() {
    if (!_speechEnabled) return 'Speech not enabled';
    if (_isWakeWordListening) return 'Listening for commands';
    return 'Ready to listen';
  }

  // Test accent compatibility for a specific command
  Future<bool> testAccentWithLocale(String command, String localeId) async {
    if (!_speechEnabled) return false;

    try {
      bool commandDetected = false;
      
      await _speechToText.listen(
        onResult: (result) {
          final recognizedText = result.recognizedWords.toLowerCase();
          if (recognizedText.contains(command.toLowerCase())) {
            commandDetected = true;
          }
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 3),
        partialResults: false,
        cancelOnError: true,
      );

      await Future.delayed(const Duration(seconds: 4));
      return commandDetected;
    } catch (e) {
      debugPrint('Accent test error for locale $localeId: $e');
      return false;
    }
  }

  // Get available accent locales
  List<String> getAvailableAccentLocales() {
    if (_supportedLocales.isEmpty) return _supportedAccents;
    
    return _supportedLocales
        .where((locale) => _supportedAccents.any(
            (accent) => locale.localeId.startsWith(accent.replaceAll('_', '-'))))
        .map((locale) => locale.localeId)
        .toList();
  }

  // Switch to best accent locale
  Future<void> switchToBestAccentLocale() async {
    final availableAccents = getAvailableAccentLocales();
    
    for (String accentLocale in availableAccents) {
      bool isCompatible = await testAccentWithLocale('hey whisp', accentLocale);
      if (isCompatible) {
        _currentLocale = accentLocale;
        debugPrint('Switched to optimal accent locale: $_currentLocale');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    debugPrint('No optimal accent found, using default: $_currentLocale');
  }

  // Manual stop for voice listening
  void manualStop() {
    print('VoiceService: Manual stop requested');
    _isWakeWordListening = false;
    _resetErrorCount(); // Reset error count on manual stop
    _speechToText.stop();
  }

  // Manual test method for debugging parsing logic
  void testCommand(String testCommand) {
    print('VoiceService: Manual test command: "$testCommand"');
    _voiceCommandController?.add(testCommand);
  }

  // Dispose of the service
  void dispose() {
    try {
      _isWakeWordListening = false;
      _wakeWordTimer?.cancel();
      _voiceCommandController?.close();
      
      // Safely dispose speech recognition
      try {
        _speechToText.stop();
      } catch (e) {
        debugPrint('Error stopping speech recognition: $e');
      }
      
      try {
        _speechToText.cancel();
      } catch (e) {
        debugPrint('Error canceling speech recognition: $e');
      }
      
      debugPrint('Voice service disposed');
    } catch (e) {
      debugPrint('Error during voice service disposal: $e');
    }
  }
}