// Stub implementation for unsupported platforms
// ignore_for_file: avoid_print

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
    _isInitialized = true;
    return true;
  }

  Future<void> startListening() async {
    _isListening = true;
    _speechResultsController.add("Voice features not available on this platform");
    Future.delayed(const Duration(seconds: 2), () {
      _isListening = false;
    });
  }

  Future<void> stopListening() async {
    _isListening = false;
  }

  void dispose() {
    _speechResultsController.close();
  }

  // Stub methods for compatibility
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
      onResult("Voice not supported on web");
    }
    return false;
  }
}
