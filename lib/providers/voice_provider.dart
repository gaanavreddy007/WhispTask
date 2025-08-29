import 'package:flutter/foundation.dart';
import '../services/voice_service.dart';
import '../services/voice_parser.dart';
import '../models/task.dart';

class VoiceProvider extends ChangeNotifier {
  final VoiceService _voiceService = VoiceService();
  
  bool _isInitialized = false;
  bool _isListening = false;
  String _recognizedText = '';
  Task? _previewTask;
  String _errorMessage = '';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;
  Task? get previewTask => _previewTask;
  String get errorMessage => _errorMessage;

  // Initialize voice service
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _isInitialized = await _voiceService.initialize();
      _errorMessage = _isInitialized ? '' : 'Failed to initialize voice recognition';
    } catch (e) {
      _isInitialized = false;
      _errorMessage = 'Voice initialization error: $e';
    }
    notifyListeners();
  }

  // Start voice recognition
  Future<void> startListening() async {
    if (!_isInitialized) {
      await initialize();
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
            _previewTask = VoiceParser.parseVoiceToTask(text);
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
  Future<void> stopListening() async {
    try {
      await _voiceService.stopListening();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error stopping voice recognition: $e';
      notifyListeners();
    }
  }

  // Cancel voice recognition
  Future<void> cancelListening() async {
    try {
      await _voiceService.cancelListening();
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

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }
}