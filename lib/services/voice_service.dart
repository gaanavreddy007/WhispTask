// ignore_for_file: deprecated_member_use, duplicate_ignore, avoid_print, prefer_const_constructors, unused_field, unused_import, unused_element, prefer_final_fields, no_leading_underscores_for_local_identifiers, equal_keys_in_map

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
// Vosk import - now available with namespace fix
import 'package:vosk_flutter/vosk_flutter.dart';

import '../providers/auth_provider.dart';
import 'background_voice_service.dart';

// Vosk model configuration options
enum VoskModelType {
  fast,        // Small models for quick response
  balanced,    // Medium models for good accuracy/speed balance
  accurate,    // Large models for best accuracy
  hindi,       // Hindi language support
}

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  dynamic _voskPlugin;
  bool _speechEnabled = false;
  bool _voskEnabled = false;
  bool _useVosk = false;
  String _lastWords = '';
  AuthProvider? _authProvider;
  
  // Vosk configuration
  String? _voskModelPath;
  VoskModelType _currentModelType = VoskModelType.balanced; // Default to balanced
  StreamSubscription<String>? _voskSubscription;
  dynamic _speechService; // SpeechService for Android Vosk
  
  // Wake word detection properties
  bool _isWakeWordListening = false;
  Timer? _wakeWordTimer;
  StreamController<String>? _voiceCommandController;
  StreamController<String>? _speechResultsController; // For live speech results
  
  // Direct callback for when stream fails
  Function(String)? _directCommandCallback;
  
  // Error tracking for exponential backoff and circuit breaker
  int _consecutiveErrors = 0;
  DateTime? _lastErrorTime;
  bool _isInErrorHandling = false;
  bool _circuitBreakerOpen = false;
  DateTime? _circuitBreakerOpenTime;
  static const int maxConsecutiveErrors = 3; // Reduced threshold
  static const Duration errorCooldownPeriod = Duration(minutes: 2);
  static const Duration circuitBreakerTimeout = Duration(minutes: 5);
  
  // Enhanced wake word configuration with multiple variations
  static const List<String> wakeWords = [
    'hey whisp', 'hey whisper', 'hey wisp', 'hey whisk',
    'a whisp', 'hey whisps', 'whisp', 'whisper',
    'ok whisp', 'hello whisp', 'start whisp'
  ];
  static const Duration wakeWordTimeout = Duration(seconds: 8); // Increased timeout
  
  // Background service integration
  bool _backgroundServiceEnabled = false;
  
  // Multi-accent support
  List<LocaleName> _supportedLocales = [];
  String _currentLocale = 'en_US';
  final List<String> _supportedAccents = [
    'en_US', // American English
    'en_GB', // British English
    'en_AU', // Australian English
    'en_CA', // Canadian English
    'en_IN', // Indian English
    'en_ZA', // South African English
  ];

  /// Set Vosk model type for different performance/accuracy needs
  Future<bool> setVoskModelType(VoskModelType modelType) async {
    try {
      _currentModelType = modelType;
      
      // If Vosk is currently active, reinitialize with new model
      if (_voskEnabled && _voskPlugin != null) {
        await _stopVoskListening();
        final newModelPath = await _getVoskModelPath(modelType);
        if (newModelPath != null) {
          _voskModelPath = newModelPath;
          await _initializeVosk();
          print('VoiceService: Switched to ${modelType.name} model: $_voskModelPath');
          return true;
        }
      } else {
        print('VoiceService: Model type set to ${modelType.name} (will apply on next initialization)');
        return true;
      }
    } catch (e) {
      print('VoiceService: Failed to set model type: $e');
    }
    return false;
  }

  /// Get current Vosk model type
  VoskModelType get currentModelType => _currentModelType;

  /// Get available model types based on installed models
  Future<List<VoskModelType>> getAvailableModelTypes() async {
    List<VoskModelType> available = [];
    
    for (VoskModelType type in VoskModelType.values) {
      final paths = _getModelPathsByType(type);
      for (String path in paths) {
        if (await _checkModelExists(path)) {
          available.add(type);
          break;
        }
      }
    }
    
    return available;
  }

  // Enhanced speech recognition settings for better accuracy
  static const Duration enhancedListenDuration = Duration(seconds: 12);
  static const Duration enhancedPauseDuration = Duration(seconds: 3);
  static const double confidenceThreshold = 0.2; // Lower threshold for better recognition
  static const double highConfidenceThreshold = 0.7; // High confidence threshold
  
  // Fuzzy matching settings for better command recognition
  static const double fuzzyMatchThreshold = 0.6; // Similarity threshold for fuzzy matching
  static const int maxEditDistance = 3; // Maximum edit distance for fuzzy matching
  
  // Error handling variables
  int _errorCount = 0;
  static const int maxRetries = 5;
  bool _useOnDeviceRecognition = false;
  
  // Getters
  bool get isListening => _useVosk ? (_voskPlugin != null) : _speechToText.isListening;
  bool get isEnabled => _useVosk ? _voskEnabled : _speechEnabled;
  String get lastWords => _lastWords;
  bool get isWakeWordActive => _isWakeWordListening;
  Stream<String>? get voiceCommandStream => _voiceCommandController?.stream;
  bool get isVoskEnabled => _voskEnabled;
  bool get isUsingVosk => _useVosk;
  
  // Set direct callback for backup communication
  void setDirectCommandCallback(Function(String) callback) {
    _directCommandCallback = callback;
    print('VoiceService: Direct command callback registered');
  }
  Stream<String>? get speechResultsStream => _speechResultsController?.stream;

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

  /// Initialize voice service
  Future<void> initialize(AuthProvider authProvider) async {
    _authProvider = authProvider;
    
    // Initialize stream controllers first
    _voiceCommandController = StreamController<String>.broadcast();
    _speechResultsController = StreamController<String>.broadcast();
    print('VoiceService: ✅ Stream controllers initialized');
    print('VoiceService: Voice command stream ready: ${_voiceCommandController != null}');
    
    // Try to initialize Vosk first, fallback to SpeechToText
    await _initializeVosk();
    if (!_voskEnabled) {
      await _initializeSpeech();
    }
    await _initializeBackgroundService();
    
    print('VoiceService: ✅ Initialization complete (Vosk: $_voskEnabled, SpeechToText: $_speechEnabled)');
  }

  /// Initialize background service integration
  Future<void> _initializeBackgroundService() async {
    try {
      // Check if background service permissions are granted
      final hasPermissions = await BackgroundVoiceService.checkPermissions();
      if (hasPermissions) {
        _backgroundServiceEnabled = true;
        
        // Listen for background wake word detections
        final service = FlutterBackgroundService();
        service.on('wakeWordDetected').listen((event) {
          if (event != null && event['command'] != null) {
            print('Background wake word detected: ${event['command']}');
            _processVoiceCommand(event['command']);
          }
        });
        
        print('Background service integration initialized');
      } else {
        print('Background service permissions not granted');
      }
    } catch (e) {
      print('Error initializing background service: $e');
      Sentry.captureException(e);
    }
  }

  /// Start background wake word detection
  Future<void> startBackgroundService() async {
    if (_backgroundServiceEnabled) {
      try {
        await BackgroundVoiceService.startService();
        print('Background voice service started');
      } catch (e) {
        print('Error starting background service: $e');
        Sentry.captureException(e);
      }
    }
  }

  /// Stop background wake word detection
  Future<void> stopBackgroundService() async {
    try {
      await BackgroundVoiceService.stopService();
      print('Background voice service stopped');
    } catch (e) {
      print('Error stopping background service: $e');
      Sentry.captureException(e);
    }
  }

  /// Check if background service is running
  Future<bool> isBackgroundServiceRunning() async {
    return await BackgroundVoiceService.isServiceRunning();
  }

  /// Process stored background commands when app is opened
  Future<void> processStoredBackgroundCommands() async {
    try {
      final commands = await BackgroundVoiceService.getStoredCommands();
      for (final command in commands) {
        if (command['command'] != null) {
          print('Processing stored background command: ${command['command']}');
          _processVoiceCommand(command['command']);
        }
      }
    } catch (e) {
      print('Error processing stored background commands: $e');
      Sentry.captureException(e);
    }
  }

  /// Initialize Vosk speech recognition
  Future<void> _initializeVosk() async {
    try {
      print('VoiceService: Initializing Vosk...');
      
      // Check microphone permission first
      final micPermission = await Permission.microphone.status;
      if (!micPermission.isGranted) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          print('VoiceService: Microphone permission denied for Vosk');
          return;
        }
      }
      
      // Initialize Vosk plugin with dynamic loading
      try {
        // Try to dynamically load Vosk plugin
        final voskAvailable = await _checkVoskAvailability();
        if (voskAvailable) {
          _voskPlugin = await _initializeVoskPlugin();
          
          if (_voskPlugin != null) {
            // Initialize with English model using correct API
            final modelPath = await _getVoskModelPath();
            if (modelPath != null) {
              // Use correct Vosk 0.3.48 API methods
              final model = await _voskPlugin!.createModel(modelPath);
              final recognizer = await _voskPlugin!.createRecognizer(
                model: model,
                sampleRate: 16000,
              );
              
              // For Android, initialize speech service
              if (Platform.isAndroid) {
                _speechService = await _voskPlugin!.initSpeechService(recognizer);
                
                // Set up Vosk speech recognition streams
                _speechService.onPartial().listen(
                  (partial) {
                    print('VoiceService: Vosk partial result: $partial');
                  },
                );
                
                _speechService.onResult().listen(
                  (result) {
                    _handleVoskResult(result);
                  },
                  onError: (error) {
                    print('VoiceService: Vosk stream error: $error');
                    _handleVoskError(error);
                  },
                );
              }
              
              _voskEnabled = true;
              _useVosk = true;
              print('VoiceService: Vosk initialized successfully with model: $modelPath');
            } else {
              print('VoiceService: Vosk model not found, using SpeechToText fallback');
              _voskEnabled = false;
              _useVosk = false;
            }
          } else {
            print('VoiceService: Vosk plugin initialization failed, using SpeechToText fallback');
            _voskEnabled = false;
            _useVosk = false;
          }
        } else {
          print('VoiceService: Vosk package not available, using SpeechToText fallback');
          _voskEnabled = false;
          _useVosk = false;
        }
        
      } catch (e) {
        print('VoiceService: Vosk model initialization failed: $e');
        _voskEnabled = false;
        _useVosk = false;
      }
      
    } catch (e) {
      print('VoiceService: Vosk initialization failed: $e');
      _voskEnabled = false;
      _useVosk = false;
    }
  }
  
  /// Handle Vosk recognition results
  void _handleVoskResult(String result) {
    try {
      final Map<String, dynamic> resultMap = json.decode(result);
      
      if (resultMap.containsKey('text') && resultMap['text'] != null) {
        final recognizedText = resultMap['text'] as String;
        
        if (recognizedText.trim().isNotEmpty) {
          print('VoiceService: Vosk recognized: "$recognizedText"');
          _lastWords = recognizedText;
          
          // Send live results for UI
          _speechResultsController?.add(recognizedText);
          
          // Process the recognized text
          final preprocessedText = _preprocessVoiceInput(recognizedText);
          
          // Check for wake word and process
          if (_detectWakeWord(preprocessedText) || preprocessedText.length > 3) {
            print('VoiceService: Valid Vosk command detected');
            _processVoiceCommand(preprocessedText);
          }
        }
      }
      
      // Handle partial results for live feedback
      if (resultMap.containsKey('partial') && resultMap['partial'] != null) {
        final partialText = resultMap['partial'] as String;
        if (partialText.trim().isNotEmpty) {
          _speechResultsController?.add(partialText);
        }
      }
      
    } catch (e) {
      print('VoiceService: Error parsing Vosk result: $e');
    }
  }
  
  /// Handle Vosk errors
  void _handleVoskError(dynamic error) {
    print('VoiceService: Vosk error: $error');
    _consecutiveErrors++;
    
    // Fallback to SpeechToText if Vosk fails repeatedly
    if (_consecutiveErrors >= 3) {
      print('VoiceService: Too many Vosk errors, falling back to SpeechToText');
      _useVosk = false;
      _initializeSpeech();
    }
  }
  
  /// Check if Vosk package is available
  Future<bool> _checkVoskAvailability() async {
    try {
      // Vosk package is now installed, check if it can be initialized
      VoskFlutterPlugin.instance();
      return true;
    } catch (e) {
      print('VoiceService: Vosk availability check failed: $e');
      return false;
    }
  }
  
  /// Initialize Vosk plugin dynamically
  Future<dynamic> _initializeVoskPlugin() async {
    try {
      // Vosk package is now available
      return VoskFlutterPlugin.instance();
    } catch (e) {
      print('VoiceService: Vosk plugin initialization failed: $e');
      return null;
    }
  }
  
  /// Get model paths organized by type preference
  List<String> _getModelPathsByType(VoskModelType modelType) {
    switch (modelType) {
      case VoskModelType.fast:
        return [
          'assets/vosk-model-small-en-us-0.15',  // Small US English (15MB) - Fastest
          'assets/vosk-model-small-en-in-0.4',   // Small Indian English - Fast
        ];
      case VoskModelType.balanced:
        return [
          'assets/vosk-model-en-in-0.5',         // Indian English (medium) - Best for Indian accents
          'assets/vosk-model-small-en-in-0.4',   // Small Indian English - Good balance
          'assets/vosk-model-small-en-us-0.15',  // Small US English - Fast fallback
        ];
      case VoskModelType.accurate:
        return [
          'assets/vosk-model-en-us-0.22',        // Large US English (1.8GB) - Most accurate
          'assets/vosk-model-en-in-0.5',         // Indian English (medium) - Good accuracy
        ];
      case VoskModelType.hindi:
        return [
          'assets/vosk-model-small-hi-0.22',     // Small Hindi (45MB) - Hindi support
          'assets/vosk-model-en-in-0.5',         // Fallback to Indian English
        ];
    }
  }

  /// Get Vosk model path based on selected model type
  Future<String?> _getVoskModelPath([VoskModelType? modelType]) async {
    try {
      modelType ??= _currentModelType;
      
      // Get model paths based on type preference
      List<String> modelPaths = _getModelPathsByType(modelType);
      
      // Add fallback paths
      modelPaths.addAll([
        'assets/models/vosk-model-small-en-us-0.15', // Fallback location
        'vosk-model-small-en-us-0.15', // Default system model
      ]);
      
      // Check each path and return the first available one
      for (String path in modelPaths) {
        try {
          // Try to access the model path
          final modelExists = await _checkModelExists(path);
          if (modelExists) {
            print('VoiceService: Found Vosk model at: $path');
            return path;
          }
        } catch (e) {
          print('VoiceService: Model not found at $path: $e');
          continue;
        }
      }
      
      print('VoiceService: No Vosk models found in any standard location');
      return null;
    } catch (e) {
      print('VoiceService: Error getting Vosk model path: $e');
      return null;
    }
  }
  
  /// Check if a Vosk model exists at the given path
  Future<bool> _checkModelExists(String modelPath) async {
    try {
      // For asset models, check if they're bundled
      if (modelPath.startsWith('assets/')) {
        try {
          // Check for the main model file within the directory
          final modelFile = '$modelPath/final.mdl';
          await rootBundle.load(modelFile);
          print('VoiceService: Found Vosk model at: $modelPath');
          return true;
        } catch (e) {
          print('VoiceService: Asset model not found at $modelPath: $e');
          return false;
        }
      }
      
      // For system models, check if file exists
      try {
        final file = File(modelPath);
        final exists = await file.exists();
        if (exists) {
          print('VoiceService: System model found at $modelPath');
          return true;
        } else {
          print('VoiceService: System model not found at $modelPath');
          return false;
        }
      } catch (e) {
        print('VoiceService: Error checking system model at $modelPath: $e');
        return false;
      }
    } catch (e) {
      print('VoiceService: Error in model existence check: $e');
      return false;
    }
  }
  
  /// Start Vosk listening
  Future<void> _startVoskListening() async {
    if (!_voskEnabled || _speechService == null) {
      print('VoiceService: Vosk not available, falling back to SpeechToText');
      return;
    }
    
    try {
      await _speechService.start();
      print('VoiceService: Vosk listening started successfully');
      
      // Reset error count on successful start
      _resetErrorCount();
    } catch (e) {
      print('VoiceService: Error starting Vosk listening: $e');
      _handleVoskError(e);
    }
  }
  
  /// Stop Vosk listening
  Future<void> _stopVoskListening() async {
    if (_speechService != null) {
      try {
        await _speechService.stop();
        print('VoiceService: Vosk listening stopped successfully');
      } catch (e) {
        print('VoiceService: Error stopping Vosk listening: $e');
      }
    }
  }

  // PRODUCTION-READY: Initialize speech recognition with comprehensive error handling
  Future<void> _initializeSpeech() async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        print('VoiceService: 🎤 PRODUCTION INITIALIZATION ATTEMPT ${retryCount + 1}/$maxRetries');
        
        // CRITICAL: Check microphone permission with comprehensive handling
        final micPermission = await Permission.microphone.status;
        print('VoiceService: Microphone permission status: $micPermission');
        
        if (!micPermission.isGranted) {
          print('VoiceService: 🔐 Requesting microphone permission...');
          final result = await Permission.microphone.request();
          print('VoiceService: Microphone permission result: $result');
          
          if (!result.isGranted) {
            print('VoiceService: ❌ CRITICAL: Microphone permission denied!');
            _speechEnabled = false;
            _handlePermissionDenied();
            return;
          }
        }
        
        // PRODUCTION: Initialize with comprehensive error handling
        _speechEnabled = await _speechToText.initialize(
          onError: (error) => _onSpeechError(error),
          onStatus: (status) => _onSpeechStatus(status),
          debugLogging: false, // Disable debug logging in production
        );
        
        if (_speechEnabled) {
          // CRITICAL: Get available locales for better accent support
          try {
            _supportedLocales = await _speechToText.locales();
            print('VoiceService: 🌍 Found ${_supportedLocales.length} supported locales');
          } catch (localeError) {
            print('VoiceService: ⚠️ Failed to get locales, using default: $localeError');
            _supportedLocales = []; // Fallback to empty list
          }
          
          // PRODUCTION: Auto-detect best locale with fallback
          try {
            await _detectBestLocale();
          } catch (localeDetectionError) {
            print('VoiceService: ⚠️ Locale detection failed, using default: $localeDetectionError');
            _currentLocale = 'en_US'; // Safe fallback
          }
          
          // PRODUCTION: Initialize stream controllers with error handling
          try {
            _initializeStreamControllers();
          } catch (streamError) {
            print('VoiceService: ⚠️ Stream initialization failed: $streamError');
            // Continue without streams - will use direct callbacks
          }
          
          print('VoiceService: ✅ PRODUCTION INITIALIZATION SUCCESSFUL');
          print('VoiceService: 🎯 Selected locale: $_currentLocale');
          print('VoiceService: 🔊 Speech recognition ready for production use');
          
          // Success - break out of retry loop
          break;
        } else {
          print('VoiceService: ❌ Speech initialization failed - attempt ${retryCount + 1}');
          retryCount++;
          if (retryCount < maxRetries) {
            print('VoiceService: 🔄 Retrying in 2 seconds...');
            await Future.delayed(Duration(seconds: 2));
          }
        }
      } catch (e) {
        print('VoiceService: ❌ Error initializing speech (attempt ${retryCount + 1}): $e');
        retryCount++;
        _speechEnabled = false;
        
        if (retryCount < maxRetries) {
          print('VoiceService: 🔄 Retrying initialization in 3 seconds...');
          await Future.delayed(Duration(seconds: 3));
        } else {
          print('VoiceService: 💥 CRITICAL: All initialization attempts failed!');
          _speechEnabled = false;
        }
      }
    }
  }


  // PRODUCTION: Handle permission denied scenario
  void _handlePermissionDenied() {
    print('VoiceService: 🚫 PRODUCTION: Microphone permission denied - voice features disabled');
    _speechEnabled = false;
    // Could trigger UI notification to user about permission requirement
  }

  // PRODUCTION: Initialize stream controllers with error handling
  void _initializeStreamControllers() {
    try {
      _voiceCommandController?.close();
      _speechResultsController?.close();
      
      _voiceCommandController = StreamController<String>.broadcast();
      _speechResultsController = StreamController<String>.broadcast();
      
      print('VoiceService: 📡 Stream controllers initialized successfully');
    } catch (e) {
      print('VoiceService: ❌ Failed to initialize stream controllers: $e');
      rethrow;
    }
  }

  // Auto-detect best locale for user's accent/region
  Future<void> _detectBestLocale() async {
    try {
      // Check if user's preferred locales are available
      for (String accent in _supportedAccents) {
        bool isAvailable = _supportedLocales.any((locale) => locale.localeId == accent);
        if (isAvailable) {
          _currentLocale = accent;
          print('VoiceService: Auto-selected locale: $accent');
          break;
        }
      }
    } catch (e) {
      print('VoiceService: Error detecting locale: $e');
      _currentLocale = 'en_US'; // Fallback to US English
    }
  }

  // Handle speech status changes for better user feedback
  void _onSpeechStatus(String status) {
    print('VoiceService: Speech status changed to: $status');
    
    switch (status) {
      case 'listening':
        print('VoiceService: Now listening for speech...');
        BackgroundVoiceService.updateListeningStatus('listening');
        break;
      case 'notListening':
        print('VoiceService: Stopped listening');
        BackgroundVoiceService.updateListeningStatus('waiting');
        break;
      case 'done':
        print('VoiceService: Speech recognition completed');
        BackgroundVoiceService.updateListeningStatus('waiting');
        break;
      default:
        print('VoiceService: Unknown status: $status');
    }
  }

  // Enhanced fuzzy matching for better voice command recognition
  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    
    final aLower = a.toLowerCase();
    final bLower = b.toLowerCase();
    
    // Check for exact substring matches first
    if (aLower.contains(bLower) || bLower.contains(aLower)) {
      return 0.8;
    }
    
    // Calculate Levenshtein distance for fuzzy matching
    final distance = _levenshteinDistance(aLower, bLower);
    final maxLength = math.max(a.length, b.length);
    
    if (maxLength == 0) return 1.0;
    
    return 1.0 - (distance / maxLength);
  }

  // Calculate Levenshtein distance for fuzzy matching
  int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    
    final matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => 0),
    );
    
    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = math.min(
          math.min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1),
          matrix[i - 1][j - 1] + cost,
        );
      }
    }
    
    return matrix[a.length][b.length];
  }

  // Simplified wake word detection
  bool _detectWakeWord(String command) {
    final lowerCommand = command.toLowerCase();
    
    // Simple wake word patterns
    final simpleWakeWords = [
      'hey whisp', 'whisp', 'hey whisper', 'whisper',
      'hey wisp', 'wisp', 'ok whisp'
    ];
    
    for (String wakeWord in simpleWakeWords) {
      if (lowerCommand.contains(wakeWord)) {
        print('VoiceService: Wake word detected: "$wakeWord"');
        return true;
      }
    }
    
    return false;
  }

  // Enhanced voice feedback system for better user guidance - DISABLED FOR USER PREFERENCE
  Future<void> _provideVoiceFeedback(String message) async {
    // Voice announcements disabled - only log the message
    print('VoiceService: Would provide voice feedback: "$message" (announcements disabled)');
    return;
    
    // Original code commented out to disable voice announcements
    /*
    try {
      if (isError) {
        await _flutterTts.setVoice({"name": "en-US-language", "locale": "en-US"});
        await _flutterTts.setSpeechRate(0.6); // Slightly slower for errors
        await _flutterTts.setPitch(0.9); // Lower pitch for errors
      } else {
        await _flutterTts.setVoice({"name": "en-US-language", "locale": "en-US"});
        await _flutterTts.setSpeechRate(0.7); // Normal speed for confirmations
        await _flutterTts.setPitch(1.1); // Higher pitch for success
      }
      
      await _flutterTts.speak(message);
      print('VoiceService: Voice feedback provided: "$message"');
    } catch (e) {
      print('VoiceService: Error providing voice feedback: $e');
    }
    */
  }

  // Enhanced voice feedback with confidence-based responses
  Future<void> _handleConfidenceBasedResponse(String command, double confidence) async {
    try {
      // Configure TTS for clearer, slower speech
      await _flutterTts.setSpeechRate(0.4); // Slower speech rate
      await _flutterTts.setPitch(1.0); // Normal pitch
      await _flutterTts.setVolume(0.8); // Clear volume
      
      if (confidence >= 0.9) {
        // High confidence - immediate confirmation
        await _provideVoiceFeedback('Got it!');
      } else if (confidence >= 0.7) {
        // Medium confidence - ask for confirmation
        await _provideVoiceFeedback('Is that correct?');
        await _startConfirmationListening(command);
      } else {
        // Low confidence - ask for repetition
        await _provideVoiceFeedback('Could you repeat that?');
        await _startRetryListening();
      }
    } catch (e) {
      print('VoiceService: Error in confidence-based response: $e');
      await _startRetryListening();
    }
  }

  // Start listening for confirmation (yes/no) responses
  Future<void> _startConfirmationListening(String originalCommand) async {
    try {
      await Future.delayed(Duration(milliseconds: 500)); // Brief pause after TTS
      
      _speechToText.listen(
        onResult: (result) {
          final response = result.recognizedWords.toLowerCase();
          print('VoiceService: Confirmation response: "$response"');
          
          if (_isPositiveResponse(response)) {
            print('VoiceService: User confirmed command');
            _processVoiceCommand(originalCommand);
          } else if (_isNegativeResponse(response)) {
            print('VoiceService: User rejected command');
            _provideVoiceFeedback("Okay, please say your command again.");
            _startRetryListening();
          } else {
            // Unclear response, ask again
            _provideVoiceFeedback("Please say yes or no.");
            _startConfirmationListening(originalCommand);
          }
        },
        listenFor: Duration(seconds: 5), // Shorter timeout for confirmation
        pauseFor: Duration(seconds: 2),
        localeId: _currentLocale,
        partialResults: false,
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      print('VoiceService: Error in confirmation listening: $e');
      await _startRetryListening();
    }
  }

  // Start listening for retry after user says repeat
  Future<void> _startRetryListening() async {
    try {
      await Future.delayed(Duration(milliseconds: 500)); // Brief pause after TTS
      
      _speechToText.listen(
        onResult: (result) {
          final recognizedWords = result.recognizedWords;
          if (recognizedWords.isNotEmpty) {
            final text = recognizedWords;
            _lastWords = text;
            
            print('VoiceService: Raw speech input: "$text"');
            
            // Preprocess the input to handle speech recognition errors
            final preprocessedText = _preprocessVoiceInput(text);
            print('VoiceService: Preprocessed text: "$preprocessedText"');
            
            // Check if this contains a wake word
            if (_detectWakeWord(preprocessedText)) {
              print('VoiceService: ✅ WAKE WORD DETECTED in: "$preprocessedText"');
              _processVoiceCommand(preprocessedText);
            } else {
              print('VoiceService: ❌ No wake word found in: "$preprocessedText"');
              if (preprocessedText.length > 10) {
                // For longer phrases without wake word, provide guidance
                print('VoiceService: Long phrase without wake word detected');
                _provideFeedback('Please start your command with "Hey Whisp"');
              }
            }
          }
        },
        listenFor: enhancedListenDuration,
        pauseFor: enhancedPauseDuration,
        localeId: _currentLocale,
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      );
    } catch (e) {
      print('VoiceService: Error in retry listening: $e');
    }
  }

  // Check if response is positive (yes, correct, right, etc.)
  bool _isPositiveResponse(String response) {
    final positiveWords = [
      'yes', 'yeah', 'yep', 'correct', 'right', 'true', 'ok', 'okay', 
      'sure', 'absolutely', 'definitely', 'confirm', 'confirmed'
    ];
    
    return positiveWords.any((word) => response.contains(word));
  }

  // Check if response is negative (no, wrong, incorrect, etc.)
  bool _isNegativeResponse(String response) {
    final negativeWords = [
      'no', 'nope', 'wrong', 'incorrect', 'false', 'not right', 'nah',
      'negative', 'cancel', 'stop'
    ];
    
    return negativeWords.any((word) => response.contains(word));
  }

  // Voice command retry mechanism with user guidance
  Future<void> _handleVoiceCommandRetry(String originalCommand) async {
    await _provideVoiceFeedback("Let me help you with voice commands. Try saying: Hey Whisp, add homework, or Hey Whisp, mark done buy groceries");
    
    // Provide examples based on common command patterns
    final suggestions = [
      "To create a task, say: Hey Whisp, add [task name]",
      "To mark complete, say: Hey Whisp, mark done [task name]", 
      "To delete a task, say: Hey Whisp, delete [task name]",
      "To update a task, say: Hey Whisp, change [task name] to [new name]"
    ];
    
    // Pick a relevant suggestion based on the original command
    String suggestion = suggestions.first;
    if (originalCommand.toLowerCase().contains('done') || originalCommand.toLowerCase().contains('complete')) {
      suggestion = suggestions[1];
    } else if (originalCommand.toLowerCase().contains('delete') || originalCommand.toLowerCase().contains('remove')) {
      suggestion = suggestions[2];
    } else if (originalCommand.toLowerCase().contains('change') || originalCommand.toLowerCase().contains('update')) {
      suggestion = suggestions[3];
    }
    
    await Future.delayed(Duration(seconds: 1));
    await _provideVoiceFeedback(suggestion);
    
    // Continue listening after providing guidance
    await _startRetryListening();
  }

  // Advanced voice input preprocessing for better recognition
  String _preprocessVoiceInput(String input) {
    if (input.isEmpty) return input;
    
    String processed = input;
    
    // 1. Normalize common speech recognition errors
    final commonErrors = {
      'havells': 'hey whisp',
      'heaviest': 'hey whisp', 
      'heaves': 'hey whisp',
      'he was': 'hey whisp',
      'he west': 'hey whisp',
      'he wrist': 'hey whisp',
      'levels': 'hey whisp',
      'a whisp': 'hey whisp',
      'bhai whisp': 'hey whisp',
      'buy whisp': 'hey whisp',
      'by whisp': 'hey whisp',
    };
    
    for (var entry in commonErrors.entries) {
      processed = processed.replaceAll(RegExp(entry.key, caseSensitive: false), entry.value);
    }
    
    // 2. Clean up extra spaces and punctuation
    processed = processed.replaceAll(RegExp(r'\s+'), ' ').trim();
    processed = processed.replaceAll(RegExp(r'[^\w\s]'), '');
    
    // 3. Remove duplicate consecutive words (enhanced)
    final words = processed.split(' ');
    final cleanedWords = <String>[];
    String? lastWord;
    
    for (String word in words) {
      if (word.isNotEmpty && word != lastWord) {
        cleanedWords.add(word);
        lastWord = word;
      }
    }
    
    // 4. Remove common speech artifacts
    final artifacts = {'um', 'uh', 'like', 'you know', 'well', 'so', 'actually', 'basically'};
    cleanedWords.removeWhere((word) => artifacts.contains(word.toLowerCase()));
    
    // 5. Handle number words to digits for better task recognition
    final numberWords = {
      'one': '1', 'two': '2', 'three': '3', 'four': '4', 'five': '5',
      'six': '6', 'seven': '7', 'eight': '8', 'nine': '9', 'ten': '10'
    };
    
    for (int i = 0; i < cleanedWords.length; i++) {
      final word = cleanedWords[i].toLowerCase();
      if (numberWords.containsKey(word)) {
        cleanedWords[i] = numberWords[word]!;
      }
    }
    
    final result = cleanedWords.join(' ');
    
    if (result != input) {
      print('VoiceService: Preprocessed "$input" -> "$result"');
    }
    
    return result;
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
      onResult: (result) => onResult(result.recognizedWords),
      listenFor: const Duration(seconds: 60), // Increased from 30 to 60 seconds
      pauseFor: const Duration(seconds: 5), // Increased from 3 to 5 seconds
      // ignore: deprecated_member_use
      partialResults: true,
      cancelOnError: false, // Don't cancel on minor errors
      listenMode: ListenMode.confirmation, // More robust listening mode
    );
  }

  // Start wake word detection
  Future<void> startWakeWordListening([String localeId = 'en_US']) async {
    if (_useVosk && _voskEnabled) {
      print('VoiceService: Starting Vosk wake word detection...');
      _isWakeWordListening = true;
      await _startVoskListening();
    } else if (_speechEnabled) {
      print('VoiceService: Starting SpeechToText wake word detection...');
      _isWakeWordListening = true;
      _startListeningForWakeWord(localeId);
    } else {
      print('VoiceService: No speech recognition available');
      return;
    }
  }

  // Handle speech recognition errors with intelligent recovery
  void _onSpeechError(dynamic error) {
    print('VoiceService: Speech error: $error');
    
    _errorCount++;
    
    // Enhanced error handling based on error type
    if (error.toString().contains('network')) {
      print('VoiceService: Network error detected - switching to on-device recognition');
      // Switch to on-device recognition for network issues
      _useOnDeviceRecognition = true;
    } else if (error.toString().contains('no_match')) {
      print('VoiceService: No speech detected - continuing to listen');
      // This is normal, just continue listening
    } else if (error.toString().contains('audio') || error.toString().contains('microphone')) {
      print('VoiceService: Audio/Microphone error - check permissions and hardware');
      _provideFeedback('Microphone issue detected. Check permissions and try again.');
      _isWakeWordListening = false;
      _speechToText.stop();
      
      _provideFeedback('Voice recognition is having issues. Please try again in a few minutes.');
      
      // Try to reinitialize speech recognition
      Future.delayed(Duration(seconds: 2), () async {
        print('VoiceService: Attempting to reinitialize speech recognition...');
        await _initializeSpeech();
      });
    } else if (error.toString().contains('permission')) {
      print('VoiceService: Permission error - microphone access denied');
      _provideFeedback('Microphone permission required. Please grant access in settings.');
    }
    
    // Restart listening after error with exponential backoff
    if (_errorCount < maxRetries && _isWakeWordListening) {
      final delay = Duration(seconds: _errorCount * 2); // Exponential backoff
      print('VoiceService: Restarting listening in ${delay.inSeconds} seconds (attempt $_errorCount/$maxRetries)');
      
      Future.delayed(delay, () {
        if (_isWakeWordListening) {
          _startListeningForWakeWord(_currentLocale);
        }
      });
    } else if (_errorCount >= maxRetries) {
      print('VoiceService: Max retries reached, stopping wake word detection');
      _isWakeWordListening = false;
      _provideFeedback('Voice recognition stopped. Please check microphone and restart.');
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
    if (_useVosk && _voskEnabled) {
      _stopVoskListening();
    } else {
      _speechToText.stop();
    }
  }

  void cancelListening() {
    _isWakeWordListening = false;
    if (_useVosk && _voskEnabled) {
      _stopVoskListening();
    } else {
      _speechToText.cancel();
    }
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
    
    if (!_speechEnabled && _authProvider != null) {
      await initialize(_authProvider!);
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
  Future<void> _startListeningForWakeWord(String localeId) async {
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
        }
      }
    }

    if (_lastErrorTime != null) {
      final timeSinceError = DateTime.now().difference(_lastErrorTime!);
      final minWaitTime = Duration(seconds: _consecutiveErrors * 2);
      
      if (timeSinceError < minWaitTime) {
        print('VoiceService: Too soon after last error (${timeSinceError.inSeconds}s), waiting...');
        Future.delayed(minWaitTime - timeSinceError, () {
          if (_isWakeWordListening) {
            _startListeningForWakeWord(localeId);
          }
        });
        return;
      }
    }

    print('VoiceService: Starting to listen for wake word...');

    // Add a small delay to ensure microphone is ready
    await Future.delayed(const Duration(milliseconds: 500));

    if (!_speechToText.isAvailable || !_isWakeWordListening) {
      print('VoiceService: Speech not available or wake word listening stopped');
      return;
    }

    try {
      _speechToText.listen(
        onResult: (result) {
          final words = result.recognizedWords;
          if (words.isNotEmpty) {
            _lastWords = words;
            print('VoiceService: Raw speech input: "$words" (confidence: ${result.confidence})');
            
            // Preprocess the input to handle speech recognition errors
            final preprocessedText = _preprocessVoiceInput(words);
            print('VoiceService: Preprocessed text: "$preprocessedText"');
            
            if (_detectWakeWord(preprocessedText)) {
              print('VoiceService: WAKE WORD DETECTED in: "$preprocessedText"');
              _processVoiceCommand(words);
            } else {
              print('VoiceService: No wake word found in: "$preprocessedText"');
              print('VoiceService: Continuing to listen for wake word...');
            }
          }
        },
        listenFor: Duration(seconds: 10), // Even longer listening duration
        pauseFor: Duration(seconds: 2), // Shorter pause to catch complete phrases
        localeId: 'en_US', // Force US English for consistency
        // ignore: deprecated_member_use
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.confirmation, // Better for command recognition
        onDevice: true, // Use on-device for faster response
        onSoundLevelChange: (level) {
          // Enhanced sound level feedback for better user experience
          print('VoiceService: Audio level: $level (${level > 0.5 ? 'GOOD' : 'LOW'})');
          if (level > 0.5) {
            print('VoiceService: Good audio level detected: $level');
          } else if (level > 0.0) {
            print('VoiceService: Weak audio detected: $level - speak louder');
          } else {
            print('VoiceService: No audio detected: $level - check microphone');
          }
        },
      );
      
      // Reset error count on successful start
      _resetErrorCount();
    } catch (e) {
      print('VoiceService: Error starting wake word listener: $e');
      _onSpeechError(e);
    }
  }

  // Normalize task commands to fix common speech recognition errors
  String _normalizeTaskCommand(String command) {
    String normalized = command.toLowerCase().trim();
    
    // First, remove duplicate words (fix "do do do homework" -> "do homework")
    normalized = _removeDuplicateWords(normalized);
    
    // Remove common speech artifacts
    normalized = _cleanSpeechArtifacts(normalized);
    
    // Comprehensive speech recognition error mappings for all task types
    final Map<String, String> corrections = {
      // Shopping & Grocery tasks
      'grocery': 'groceries',
      'grocers': 'groceries',
      'grocer': 'groceries',
      'grocery store': 'groceries',
      'shopping': 'shop',
      'shop for': 'buy',
      'purchase': 'buy',
      'get some': 'buy',
      
      // Buy variations
      'bike': 'buy',
      'by': 'buy',
      'bye': 'buy',
      'buy buy': 'buy',
      'pi': 'buy',
      'pie': 'buy',
      
      // Call variations
      'call': 'call',
      'col': 'call',
      'cool': 'call',
      'calling': 'call',
      'phone': 'call',
      'ring': 'call',
      'contact': 'call',
      
      // Meeting variations
      'meeting': 'meeting',
      'meet': 'meeting',
      'meat': 'meeting',
      'meting': 'meeting',
      'conference': 'meeting',
      'appointment': 'meeting',
      'schedule': 'schedule meeting',
      
      // Work tasks
      'work on': 'work on',
      'working': 'work on',
      'complete': 'finish',
      'finish': 'finish',
      'submit': 'submit',
      'send': 'send',
      'email': 'send email',
      'mail': 'send email',
      
      // Health & Medical
      'exercise': 'exercise',
      'workout': 'workout',
      'appointment': 'book appointment',
      'doctor': 'doctor',
      'medicine': 'take medicine',
      'medication': 'take medication',
      'pills': 'take medicine',
      
      // Travel & Transport
      'book flight': 'book flight',
      'book ticket': 'book ticket',
      'travel': 'plan travel',
      'trip': 'plan trip',
      'vacation': 'plan vacation',
      'hotel': 'book hotel',
      
      // Home & Personal
      'clean': 'clean',
      'wash': 'wash',
      'laundry': 'do laundry',
      'dishes': 'wash dishes',
      'cook': 'cook',
      'prepare': 'prepare',
      'fix': 'fix',
      'repair': 'repair',
      
      // Study & Learning
      'study': 'study',
      'read': 'read',
      'learn': 'learn',
      'practice': 'practice',
      'homework': 'do homework',
      'assignment': 'complete assignment',
      
      // Common misheard words
      'rha sharif': 'groceries',
      'rajshahi': 'groceries',
      'sharif': 'groceries',
      'rha': '',
      'bike rha': 'buy',
      
      // Family & relationships
      'mom': 'mom',
      'mum': 'mom',
      'mother': 'mom',
      'dad': 'dad',
      'father': 'dad',
      'sister': 'sister',
      'brother': 'brother',
      'friend': 'friend',
      'wife': 'wife',
      'husband': 'husband',
      
      // Time-related
      'today': 'today',
      'tomorrow': 'tomorrow',
      'tonight': 'tonight',
      'morning': 'morning',
      'evening': 'evening',
      'afternoon': 'afternoon',
      
      // Clean up extra words
      'the ': '',
      'a ': '',
      'an ': '',
      'some ': '',
      'my ': '',
    };
    
    // Apply corrections
    for (String wrong in corrections.keys) {
      normalized = normalized.replaceAll(wrong, corrections[wrong]!);
    }
    
    // Clean up multiple spaces and trim
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // If command is too short or unclear, provide a default
    if (normalized.length < 3 || normalized.isEmpty) {
      normalized = 'add task';
    }
    
    return normalized;
  }

  // Simplified command processing
  Future<void> _processVoiceCommand(String command) async {
    print('VoiceService: Processing voice command: "$command"');
    
    // Clean the command
    String cleanedCommand = _cleanCommand(command);
    print('VoiceService: Cleaned command: "$cleanedCommand"');
    
    if (cleanedCommand.isEmpty) {
      print('VoiceService: Empty command after cleaning');
      return;
    }
    
    // Send to stream
    if (_voiceCommandController != null && !_voiceCommandController!.isClosed) {
      print('VoiceService: Adding to stream: "$cleanedCommand"');
      _voiceCommandController!.add(cleanedCommand);
    } else {
      print('VoiceService: Stream not available, reinitializing...');
      _voiceCommandController = StreamController<String>.broadcast();
      _voiceCommandController!.add(cleanedCommand);
    }
    
    // Use direct callback as backup
    if (_directCommandCallback != null) {
      print('VoiceService: Using direct callback');
      _directCommandCallback!(cleanedCommand);
    }
  }
  
  // Clean and normalize voice commands
  String _cleanCommand(String command) {
    String cleaned = command.toLowerCase().trim();
    
    // Remove wake words
    final wakeWords = ['hey whisp', 'whisp', 'hey whisper', 'whisper', 'hey wisp', 'wisp'];
    for (String wake in wakeWords) {
      if (cleaned.startsWith('$wake ')) {
        cleaned = cleaned.substring(wake.length + 1).trim();
        break;
      }
    }
    
    // Basic cleanup
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned;
  }
  
  // Helper method for fuzzy string matching
  bool _fuzzyMatch(String input, String target) {
    if (input.length < 3 || target.length < 3) return false;
    
    // Simple fuzzy matching - check if most characters match
    int matches = 0;
    int minLength = input.length < target.length ? input.length : target.length;
    
    for (int i = 0; i < minLength; i++) {
      if (i < input.length && i < target.length && input[i] == target[i]) {
        matches++;
      }
    }
    
    // Consider it a match if 70% of characters match
    return (matches / minLength) >= 0.7;
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
              bool _hasWakeWord(String text) {
                final lowerText = text.toLowerCase();
                
                // Check for "Hey Whisp" at the start
                if (lowerText.startsWith('hey whisp')) {
                  return true;
                }
                
                // Check for "Hey Whisp" in the middle (with word boundaries)
                if (lowerText.contains(' hey whisp ') || 
                    lowerText.contains(' hey whisp,') ||
                    lowerText.contains(' hey whisp.')) {
                  return true;
                }
                
                // Check for just "whisp" as a standalone word
                final words = lowerText.split(' ');
                if (words.contains('whisp')) {
                  return true;
                }
                
                // Add fallback wake words for speech recognition variations
                if (lowerText.startsWith('bhai whisp') || 
                    lowerText.startsWith('hey whisper') ||
                    lowerText.startsWith('a whisp') ||
                    words.contains('bhai') && words.contains('whisp')) {
                  return true;
                }
                
                return false;
              }
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
  
  // Provide audio feedback to user - DISABLED FOR USER PREFERENCE
  Future<void> _provideFeedback(String message) async {
    // Voice announcements disabled - only log the message
    print('VoiceService: Would provide feedback: "$message" (announcements disabled)');
    return;
    
    // Original code commented out to disable voice announcements
    /*
    try {
      await _flutterTts.setSpeechRate(0.4); // Slower speech for clarity
      await _flutterTts.setPitch(1.0); // Normal pitch
      await _flutterTts.setVolume(0.8); // Clear volume
      await _flutterTts.speak(message);
    } catch (e) {
      print('VoiceService: TTS error: $e');
    }
    */
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
      if (_authProvider != null) {
        await initialize(_authProvider!);
      }
      
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


  // Get available accent locales
  List<String> getAvailableAccentLocales() {
    if (_supportedLocales.isEmpty) return _supportedAccents;
    
    return _supportedLocales
        .where((locale) => _supportedAccents.any(
            (accent) => locale.localeId.startsWith(accent.replaceAll('_', '-'))))
        .map((locale) => locale.localeId)
        .toList();
  }


  // Manual stop for voice listening
  void manualStop() {
    print('VoiceService: Manual stop requested');
    _isWakeWordListening = false;
    _resetErrorCount(); // Reset error count on manual stop
    _speechToText.stop();
  }


  // Remove duplicate consecutive words (fix "do do do homework" -> "do homework")
  String _removeDuplicateWords(String text) {
    List<String> words = text.split(' ');
    List<String> cleanWords = [];
    
    for (int i = 0; i < words.length; i++) {
      String currentWord = words[i].toLowerCase();
      
      // Skip if this word is the same as the previous word
      if (cleanWords.isEmpty || cleanWords.last.toLowerCase() != currentWord) {
        cleanWords.add(words[i]);
      }
    }
    
    return cleanWords.join(' ');
  }

  // Clean common speech recognition artifacts
  String _cleanSpeechArtifacts(String text) {
    String cleaned = text;
    
    // Remove common speech artifacts
    final artifacts = [
      RegExp(r'\b(um|uh|er|ah)\b', caseSensitive: false),
      RegExp(r'\b(like|you know)\b', caseSensitive: false),
      RegExp(r'\b(well|so)\s+', caseSensitive: false),
      RegExp(r'\s+(please|thanks?)\s*$', caseSensitive: false),
    ];
    
    for (RegExp artifact in artifacts) {
      cleaned = cleaned.replaceAll(artifact, ' ');
    }
    
    // Remove extra punctuation and clean spaces
    cleaned = cleaned.replaceAll(RegExp(r'[.,!?]+$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned;
  }

  // Dispose of the service
  void dispose() {
    try {
      _isWakeWordListening = false;
      _wakeWordTimer?.cancel();
      _voiceCommandController?.close();
      _speechResultsController?.close();
      
      // Dispose Vosk resources
      if (_useVosk && _voskPlugin != null) {
        _voskSubscription?.cancel();
        _stopVoskListening();
      }
      
      // Safely dispose speech recognition
      _speechToText.stop();
      _speechToText.cancel();
      
      debugPrint('Voice service disposed (Vosk: $_voskEnabled, SpeechToText: $_speechEnabled)');
    } catch (e) {
      debugPrint('Error during voice service disposal: $e');
    }
  }
}