// Web-compatible voice service (placeholder)
import 'dart:async';
import 'package:flutter/foundation.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  bool _isInitialized = false;
  bool _isListening = false;
  
  final StreamController<String> _speechResultsController = StreamController<String>.broadcast();
  Stream<String> get speechResultsStream => _speechResultsController.stream;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  Future<bool> initialize() async {
    if (kIsWeb) {
      // Web doesn't support native voice recognition yet
      _isInitialized = true;
      return true;
    }
    return false;
  }

  Future<void> startListening() async {
    if (kIsWeb) {
      // Placeholder for web - could integrate Web Speech API later
      _isListening = true;
      _speechResultsController.add("Web voice recognition not available");
      return;
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
  }

  void dispose() {
    _speechResultsController.close();
  }
}
