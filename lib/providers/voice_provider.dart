// ignore_for_file: await_only_futures, avoid_print

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/voice_service.dart';
import '../services/voice_parser.dart';
import '../services/sentry_service.dart';
import '../providers/auth_provider.dart';

class VoiceProvider extends ChangeNotifier {
  final VoiceService _voiceService = VoiceService();
  
  bool _isInitialized = false;
  bool _isListening = false;
  String _recognizedText = '';
  String _liveRecognizedText = ''; // For real-time speech feedback
  Task? _previewTask;
  String _errorMessage = '';
  Timer? _throttleTimer; // Timer to throttle UI updates
  
  // Voice UI state management
  bool _isVoiceListening = false;
  bool _isProcessingVoiceCommand = false;
  String _voiceStatus = 'Tap to activate voice commands';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;
  String get liveRecognizedText => _liveRecognizedText;
  Task? get previewTask => _previewTask;
  String get errorMessage => _errorMessage;
  
  // Voice UI state getters
  bool get isVoiceListening => _isVoiceListening;
  bool get isProcessingVoiceCommand => _isProcessingVoiceCommand;
  String get voiceStatus => _voiceStatus;

  // Update live recognized text (for real-time transcript display)
  void setLiveRecognizedText(String text) {
    SentryService.logVoiceOperation('live_text_update', data: {
      'text_length': text.length.toString(),
      'has_content': text.isNotEmpty.toString(),
    });
    _liveRecognizedText = text;
    notifyListeners();
  }

  // Initialize voice service
  Future<void> initialize(AuthProvider authProvider) async {
    if (_isInitialized) {
      SentryService.logVoiceOperation('initialize_skipped_already_initialized');
      return;
    }
    
    await SentryService.wrapWithComprehensiveTracking(
      () async {
        SentryService.logVoiceOperation('voice_provider_initialization_start');
        await _voiceService.initialize(authProvider);
        _isInitialized = true;
        _errorMessage = '';
        SentryService.logVoiceOperation('voice_provider_initialization_success');
      },
      operationName: 'voice_provider_initialize',
      description: 'Initialize VoiceProvider with AuthProvider',
      category: 'voice',
      extra: {
        'user_id': authProvider.user?.uid ?? 'anonymous',
        'is_authenticated': (authProvider.user != null).toString(),
      },
    ).catchError((e) {
      _isInitialized = false;
      _errorMessage = 'Voice initialization error: $e';
      SentryService.logVoiceOperation('voice_provider_initialization_failed', data: {
        'error': e.toString(),
      });
    });
    
    notifyListeners();
  }

  // Start voice recognition
  Future<void> startListening([AuthProvider? authProvider]) async {
    if (!_isInitialized) {
      if (authProvider != null) {
        await initialize(authProvider);
      }
      if (!_isInitialized) return;
    }

    _recognizedText = '';
    _previewTask = null;
    _errorMessage = '';
    _isListening = true;
    notifyListeners();

    try {
      await _voiceService.startListening(
        onResult: (text) {
          _recognizedText = text;
          if (text.isNotEmpty) {
            _previewTask = VoiceParser.createTaskFromSpeech(text);
          }
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Error starting voice recognition: $e';
      _isListening = false;
      notifyListeners();
    }
  }

  // Stop voice recognition
  void stopListening() {
    try {
      _voiceService.stopListening();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error stopping voice recognition: $e';
      notifyListeners();
    }
  }

  // Cancel voice recognition
  void cancelListening() {
    try {
      _voiceService.cancelListening();
      _isListening = false;
      _recognizedText = '';
      _previewTask = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error canceling voice recognition: $e';
      notifyListeners();
    }
  }

  // Clear current session
  void clearSession() {
    _recognizedText = '';
    _previewTask = null;
    _errorMessage = '';
    notifyListeners();
  }

  // Validate current task
  bool isCurrentTaskValid() {
    return _previewTask != null && VoiceParser.isValidTask(_previewTask!);
  }


  // Callback for handling voice commands
  Function(String)? _onVoiceCommand;
  
  // Set callback for voice command handling
  void setVoiceCommandCallback(Function(String) callback) {
    SentryService.logVoiceOperation('voice_command_callback_set');
    _onVoiceCommand = callback;
  }

  // Simplified voice provider initialization
  Future<void> initializeEnhancedVoice(AuthProvider authProvider) async {
    await SentryService.wrapWithComprehensiveTracking(
      () async {
        SentryService.logVoiceOperation('enhanced_voice_initialization_start');
        print('VoiceProvider: Initializing enhanced voice...');
        
        await _voiceService.initialize(authProvider);
        SentryService.logVoiceOperation('voice_service_initialized');
        
        await _voiceService.startWakeWordListening();
        SentryService.logVoiceOperation('wake_word_listening_started');
        
        // Set up direct callback for immediate processing
        _voiceService.setDirectCommandCallback((command) {
          SentryService.logVoiceOperation('direct_callback_received', data: {
            'command_length': command.length.toString(),
            'has_callback': (_onVoiceCommand != null).toString(),
          });
          print('VoiceProvider: Direct callback received: $command');
          if (_onVoiceCommand != null) {
            _onVoiceCommand!(command);
          }
        });
        
        // Listen for voice command stream
        _voiceService.voiceCommandStream?.listen(
          (command) {
            SentryService.logVoiceOperation('stream_command_received', data: {
              'command_length': command.length.toString(),
              'has_callback': (_onVoiceCommand != null).toString(),
            });
            print('VoiceProvider: Stream received: $command');
            _liveRecognizedText = '';
            if (_onVoiceCommand != null) {
              _onVoiceCommand!(command);
            }
            notifyListeners();
          },
          onError: (error) {
            SentryService.captureException(
              error,
              hint: 'Voice command stream error',
              extra: {'provider': 'VoiceProvider'},
            );
            print('VoiceProvider: Stream error: $error');
            _errorMessage = 'Voice command error: $error';
            notifyListeners();
          },
        );

        // Listen for live speech results
        _voiceService.speechResultsStream?.listen(
          (text) {
            SentryService.logVoiceOperation('speech_results_received', data: {
              'text_length': text.length.toString(),
            });
            _liveRecognizedText = text;
            notifyListeners();
          },
          onError: (error) {
            SentryService.captureException(
              error,
              hint: 'Speech results stream error',
              extra: {'provider': 'VoiceProvider'},
            );
            print('VoiceProvider: Speech results error: $error');
          },
        );
        
        SentryService.logVoiceOperation('enhanced_voice_initialization_complete');
        print('VoiceProvider: Enhanced voice initialized successfully');
      },
      operationName: 'enhanced_voice_initialization',
      description: 'Initialize enhanced voice with wake word listening',
      category: 'voice',
      extra: {
        'user_id': authProvider.user?.uid ?? 'anonymous',
        'has_user': (authProvider.user != null).toString(),
      },
    ).catchError((e) {
      SentryService.logVoiceOperation('enhanced_voice_initialization_failed', data: {
        'error': e.toString(),
      });
      print('VoiceProvider: Error initializing enhanced voice: $e');
      _errorMessage = 'Voice initialization failed: $e';
      notifyListeners();
    });
  }

  // Voice UI state management methods
  void setVoiceListening(bool listening) {
    if (_isVoiceListening != listening) {
      SentryService.logVoiceOperation('voice_listening_state_changed', data: {
        'previous_state': _isVoiceListening.toString(),
        'new_state': listening.toString(),
      });
      _isVoiceListening = listening;
      notifyListeners();
    }
  }
  
  void setProcessingVoiceCommand(bool processing) {
    if (_isProcessingVoiceCommand != processing) {
      SentryService.logVoiceOperation('voice_processing_state_changed', data: {
        'previous_state': _isProcessingVoiceCommand.toString(),
        'new_state': processing.toString(),
      });
      _isProcessingVoiceCommand = processing;
      notifyListeners();
    }
  }
  
  void setVoiceStatus(String status) {
    if (_voiceStatus != status) {
      SentryService.logVoiceOperation('voice_status_changed', data: {
        'previous_status': _voiceStatus,
        'new_status': status,
      });
      _voiceStatus = status;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    SentryService.logProviderStateChange('VoiceProvider', 'dispose_start');
    
    try {
      _throttleTimer?.cancel();
      SentryService.logVoiceOperation('throttle_timer_cancelled');
      
      _voiceService.dispose();
      SentryService.logVoiceOperation('voice_service_disposed');
      
      super.dispose();
      SentryService.logProviderStateChange('VoiceProvider', 'dispose_complete');
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error disposing VoiceProvider',
        extra: {'provider': 'VoiceProvider'},
      );
      super.dispose();
    }
  }
}