// Platform-aware voice service that uses Vosk on mobile and Web Speech API on web
import 'dart:async';
import 'package:flutter/foundation.dart';

// For now, let's just focus on the iOS build with Vosk
// This file is not needed for the iOS build workflow

class PlatformVoiceService {
  static final PlatformVoiceService _instance = PlatformVoiceService._internal();
  factory PlatformVoiceService() => _instance;
  PlatformVoiceService._internal();

  // Simple placeholder - the actual VoiceService will be used directly
  bool _isInitialized = false;
  final StreamController<String> _controller = StreamController<String>.broadcast();

  // Platform detection
  bool get isWeb => kIsWeb;
  bool get isMobile => !kIsWeb;
  
  // Voice service type
  String get serviceType => isWeb ? 'Web Speech API' : 'Vosk Flutter (Offline)';
  
  // Capabilities
  bool get supportsOffline => isMobile; // Vosk works offline
  bool get requiresInternet => isWeb;   // Web Speech API needs internet

  Stream<String> get speechResultsStream => _controller.stream;
  bool get isInitialized => _isInitialized;
  bool get isListening => false;

  Future<bool> initialize() async {
    _isInitialized = true;
    return true;
  }

  Future<void> startListening() async {
    // Placeholder implementation
  }

  Future<void> stopListening() async {
    // Placeholder implementation
  }

  void dispose() {
    _controller.close();
    _isInitialized = false;
  }

  // Platform-specific information
  Map<String, dynamic> getPlatformInfo() {
    return {
      'platform': isWeb ? 'Web' : 'Mobile',
      'serviceType': serviceType,
      'supportsOffline': supportsOffline,
      'requiresInternet': requiresInternet,
      'isInitialized': isInitialized,
      'isListening': isListening,
    };
  }
}
