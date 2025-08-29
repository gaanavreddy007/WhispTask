// Create new file: lib/services/transcription_service.dart

// ignore_for_file: unused_import, avoid_print, deprecated_member_use

import 'package:speech_to_text/speech_to_text.dart';
import 'dart:io';

class TranscriptionService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _transcription = '';

  bool get isListening => _isListening;
  String get transcription => _transcription;

  Future<bool> initialize() async {
    try {
      return await _speechToText.initialize();
    } catch (e) {
      print('Error initializing speech recognition: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onError,
  }) async {
    if (!_speechToText.isAvailable) {
      onError?.call('Speech recognition not available');
      return;
    }

    _isListening = true;
    
    await _speechToText.listen(
      onResult: (result) {
        _transcription = result.recognizedWords;
        onResult(_transcription);
      },
      localeId: 'en_US',
      listenMode: ListenMode.confirmation,
      cancelOnError: false,
      partialResults: true,
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _speechToText.stop();
  }

  Future<String> transcribeAudioFile(String filePath) async {
    // Note: This is a basic implementation
    // For production, you'd integrate with a service like Google Cloud Speech-to-Text
    // or Azure Speech Services for file transcription
    
    try {
      // This would require additional setup with cloud services
      // For now, return a placeholder
      return "Transcription from audio file - implement with cloud service";
    } catch (e) {
      print('Error transcribing audio file: $e');
      return '';
    }
  }

  void dispose() {
    _speechToText.cancel();
  }
}