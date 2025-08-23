import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  
  // Getters
  bool get isListening => _speechToText.isListening;
  bool get isEnabled => _speechEnabled;
  String get lastWords => _lastWords;

  // Initialize speech recognition
  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final permission = await Permission.microphone.request();
      if (permission != PermissionStatus.granted) {
        debugPrint('Microphone permission denied');
        return false;
      }

      _speechEnabled = await _speechToText.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
      );
      
      debugPrint('Voice service initialized: $_speechEnabled');
      return _speechEnabled;
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
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

  // Stop listening
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  // Cancel listening
  Future<void> cancelListening() async {
    await _speechToText.cancel();
  }

  // Get available locales
  Future<List<LocaleName>> getLocales() async {
    return await _speechToText.locales();
  }
}
