// Web-compatible voice service with simplified implementation
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter, duplicate_ignore, avoid_print

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
      try {
        // Simplified web initialization - just mark as initialized
        // Web Speech API integration can be added later if needed
        _isInitialized = true;
        return true;
      } catch (e) {
        print('Failed to initialize Web Voice Service: $e');
        _isInitialized = true;
        return true;
      }
    }
    return false;
  }

  Future<void> startListening() async {
    if (kIsWeb) {
      try {
        // Simplified web implementation - simulate voice input
        _isListening = true;
        _speechResultsController.add("Web Speech API not fully supported. Voice features work on mobile apps.");
        Future.delayed(const Duration(seconds: 2), () {
          _isListening = false;
        });
      } catch (e) {
        print('Failed to start speech recognition: $e');
        _speechResultsController.add("Failed to start voice recognition");
        _isListening = false;
      }
    }
  }

  Future<void> stopListening() async {
    if (kIsWeb) {
      try {
        _isListening = false;
      } catch (e) {
        print('Failed to stop speech recognition: $e');
      }
    }
  }

  void dispose() {
    _speechResultsController.close();
  }

  // Additional methods for compatibility
  Future<void> initializeVosk() async {}
  Future<void> setVoskModel(dynamic modelType) async {}
  Future<void> startVoskListening() async {}
  Future<void> stopVoskListening() async {}
  Future<void> speak(String text) async {}
  Future<void> setAuthProvider(dynamic authProvider) async {}
  Future<void> initializeEnhancedVoice() async {}
  Future<void> startWakeWordListening() async {}
  Future<void> stopWakeWordListening() async {}
  Future<void> cancelListening() async {}
  void setDirectCommandCallback(Function? callback) {}
  
  // Additional getters and streams
  bool get isWakeWordActive => false;
  Stream<String> get voiceCommandStream => const Stream.empty();
  
  // Speech to text compatibility
  Future<bool> listen({Function? onResult}) async {
    if (onResult != null) {
      onResult("Web Speech API not fully supported. Voice features work on mobile apps.");
    }
    return false;
  }
}
