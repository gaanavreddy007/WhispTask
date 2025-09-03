import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;

  // TTS Configuration
  double _volume = 1.0; // Max volume
  double _rate = 1.0; // Faster speech rate
  double _pitch = 1.0;
  String _language = 'en-US';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  double get volume => _volume;
  double get rate => _rate;
  double get pitch => _pitch;
  String get language => _language;

  // Initialize TTS service
  Future<bool> initialize() async {
    try {
      _flutterTts = FlutterTts();
      
      // Set up handlers
      _flutterTts!.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('TTS: Started speaking');
      });

      _flutterTts!.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('TTS: Completed speaking');
      });

      _flutterTts!.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
      });

      _flutterTts!.setCancelHandler(() {
        _isSpeaking = false;
        debugPrint('TTS: Cancelled');
      });

      // Configure TTS settings
      await _configureTts();
      
      _isInitialized = true;
      debugPrint('TTS Service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('TTS initialization error: $e');
      _isInitialized = false;
      return false;
    }
  }

  // Configure TTS settings
  Future<void> _configureTts() async {
    if (_flutterTts == null) return;

    await _flutterTts!.setVolume(_volume);
    await _flutterTts!.setSpeechRate(_rate);
    await _flutterTts!.setPitch(_pitch);
    await _flutterTts!.setLanguage(_language);
    
    // Set shared instance for iOS
    await _flutterTts!.setSharedInstance(true);
    
    // Set iOS audio session category
    await _flutterTts!.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [IosTextToSpeechAudioCategoryOptions.allowBluetooth],
    );
  }

  // Speak text with optional parameters
  Future<void> speak(String text, {
    double? volume,
    double? rate,
    double? pitch,
    String? language,
  }) async {
    if (!_isInitialized || _flutterTts == null) {
      debugPrint('TTS not initialized, cannot speak: $text');
      return;
    }

    try {
      // Stop current speech if any
      if (_isSpeaking) {
        await stop();
      }

      // Apply temporary settings if provided
      if (volume != null) await _flutterTts!.setVolume(volume);
      if (rate != null) await _flutterTts!.setSpeechRate(rate);
      if (pitch != null) await _flutterTts!.setPitch(pitch);
      if (language != null) await _flutterTts!.setLanguage(language);

      debugPrint('TTS: Speaking - "$text"');
      await _flutterTts!.speak(text);

      // Restore default settings if temporary ones were used
      if (volume != null || rate != null || pitch != null || language != null) {
        await _configureTts();
      }
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _isSpeaking = false;
    }
  }

  // Stop current speech
  Future<void> stop() async {
    if (_flutterTts != null && _isSpeaking) {
      await _flutterTts!.stop();
      _isSpeaking = false;
    }
  }

  // Pause current speech
  Future<void> pause() async {
    if (_flutterTts != null && _isSpeaking) {
      await _flutterTts!.pause();
    }
  }

  // Update TTS settings
  Future<void> updateSettings({
    double? volume,
    double? rate,
    double? pitch,
    String? language,
  }) async {
    if (!_isInitialized) return;

    if (volume != null) _volume = volume;
    if (rate != null) _rate = rate;
    if (pitch != null) _pitch = pitch;
    if (language != null) _language = language;

    await _configureTts();
  }

  // Voice feedback methods for task operations
  Future<void> speakTaskCreated(String taskTitle) async {
    await speak("Task '$taskTitle' has been created successfully.");
  }

  Future<void> speakTaskCompleted(String taskTitle) async {
    await speak("Great job! Task '$taskTitle' has been marked as complete.");
  }

  Future<void> speakTaskStarted(String taskTitle) async {
    await speak("Started working on '$taskTitle'. Good luck!");
  }

  Future<void> speakTaskPaused(String taskTitle) async {
    await speak("Task '$taskTitle' has been paused.");
  }

  Future<void> speakTaskCancelled(String taskTitle) async {
    await speak("Task '$taskTitle' has been cancelled.");
  }

  Future<void> speakTaskDeleted(String taskTitle) async {
    await speak("Task '$taskTitle' has been deleted.");
  }

  Future<void> speakPriorityChanged(String taskTitle, String priority) async {
    await speak("Priority for '$taskTitle' has been changed to $priority.");
  }

  Future<void> speakTaskNotFound(String taskIdentifier) async {
    await speak("Sorry, I couldn't find a task matching '$taskIdentifier'. Please try again with a different description.");
  }

  Future<void> speakMultipleTasksFound(int count, String taskIdentifier) async {
    await speak("I found $count tasks matching '$taskIdentifier'. Please be more specific.");
  }

  Future<void> speakVoiceCommandError() async {
    await speak("Sorry, I didn't understand that command. Please try again.");
  }

  Future<void> speakListeningStarted() async {
    await speak("Voice commands activated. Say 'Hey Whisp' followed by your command.");
  }

  Future<void> speakListeningStopped() async {
    await speak("Voice commands deactivated.");
  }

  Future<void> speakWakeWordDetected() async {
    await speak("Yes, I'm listening. What would you like me to do?", rate: 1.0);
  }

  Future<void> speakCommandProcessing() async {
    await speak("Processing your command...", rate: 1.1); // Slightly faster for responsiveness
  }

  Future<void> speakHelp() async {
    await speak(
      "You can say commands like: Mark task as done, Start working on project, "
      "Create task buy groceries, or Change priority to high. "
      "Always start with 'Hey Whisp' to get my attention.",
      rate: 1.0,
    );
  }

  // Get available languages
  Future<List<String>> getAvailableLanguages() async {
    if (_flutterTts == null) return [];
    try {
      final languages = await _flutterTts!.getLanguages;
      return languages?.cast<String>() ?? [];
    } catch (e) {
      debugPrint('Error getting languages: $e');
      return [];
    }
  }

  // Get available voices
  Future<List<Map<String, String>>> getAvailableVoices() async {
    if (_flutterTts == null) return [];
    try {
      final voices = await _flutterTts!.getVoices;
      return voices?.cast<Map<String, String>>() ?? [];
    } catch (e) {
      debugPrint('Error getting voices: $e');
      return [];
    }
  }

  // Set specific voice
  Future<void> setVoice(Map<String, String> voice) async {
    if (_flutterTts != null) {
      await _flutterTts!.setVoice(voice);
    }
  }

  // Test TTS functionality
  Future<void> testTts() async {
    await speak("Text to speech is working correctly!", rate: 1.0);
  }

  // Dispose resources
  Future<void> dispose() async {
    if (_flutterTts != null) {
      await stop();
      _flutterTts = null;
    }
    _isInitialized = false;
    debugPrint('TTS Service disposed');
  }
}
