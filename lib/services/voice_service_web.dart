// Web-compatible voice service with Web Speech API integration
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter, duplicate_ignore, avoid_print

import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  bool _isInitialized = false;
  bool _isListening = false;
  html.SpeechRecognition? _speechRecognition;
  
  final StreamController<String> _speechResultsController = StreamController<String>.broadcast();
  Stream<String> get speechResultsStream => _speechResultsController.stream;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  Future<bool> initialize() async {
    if (kIsWeb) {
      try {
        // Check if Web Speech API is supported
        if (html.SpeechRecognition.supported) {
          _speechRecognition = html.SpeechRecognition();
          _speechRecognition!.continuous = false;
          _speechRecognition!.interimResults = true;
          _speechRecognition!.lang = 'en-US';
          
          // Set up event listeners
          _speechRecognition!.onResult.listen((html.SpeechRecognitionEvent event) {
            if (event.results != null && event.results!.isNotEmpty) {
              final result = event.results!.last;
              if (result.isFinal != null && result.isFinal!) {
                try {
                  final transcript = js.context['getTranscript'](result);
                  if (transcript != null) {
                    _speechResultsController.add(transcript.toString());
                  }
                } catch (e) {
                  // Fallback: use simple string conversion
                  _speechResultsController.add(result.toString());
                }
              }
            }
          });
          
          _speechRecognition!.onError.listen((html.SpeechRecognitionError error) {
            print('Speech recognition error: ${error.error}');
            _speechResultsController.add('Speech recognition error occurred');
            _isListening = false;
          });
          
          _speechRecognition!.onEnd.listen((_) {
            _isListening = false;
          });
          
          _isInitialized = true;
          return true;
        } else {
          // Fallback for browsers without Web Speech API
          _isInitialized = true;
          return true;
        }
      } catch (e) {
        print('Failed to initialize Web Speech API: $e');
        _isInitialized = true;
        return true;
      }
    }
    return false;
  }

  Future<void> startListening() async {
    if (kIsWeb) {
      try {
        if (_speechRecognition != null && html.SpeechRecognition.supported) {
          _isListening = true;
          _speechRecognition!.start();
        } else {
          // Fallback message for unsupported browsers
          _isListening = true;
          _speechResultsController.add("Web Speech API not supported in this browser. Please use Chrome, Edge, or Safari.");
          Future.delayed(Duration(seconds: 2), () {
            _isListening = false;
          });
        }
      } catch (e) {
        print('Failed to start speech recognition: $e');
        _speechResultsController.add("Failed to start voice recognition");
        _isListening = false;
      }
    }
  }

  Future<void> stopListening() async {
    if (kIsWeb && _speechRecognition != null) {
      try {
        _speechRecognition!.stop();
      } catch (e) {
        print('Failed to stop speech recognition: $e');
      }
    }
    _isListening = false;
  }

  void dispose() {
    _speechResultsController.close();
    _speechRecognition = null;
  }
}
