// ignore_for_file: avoid_print, unused_import, deprecated_member_use

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

@pragma('vm:entry-point')
class BackgroundVoiceService {
  static const String _notificationChannelId = 'whisptask_voice_notification';
  static const MethodChannel _channel = MethodChannel('whisptask/notification');
  
  // Wake word variations (same as main voice service)
  static const List<String> _wakeWords = [
    'hey whisp', 'hey whisper', 'hey wisp', 'hey whisk',
    'bhai whisp', 'buy whisp', 'a whisp', 'he whisp',
    'he was add', 'he was update', 'he was delete', 'he was complete', 'he was finish',
    'he was call', 'he was buy', 'he was visit', 'he was book', 'he was send', 'he was remove',
    'he was gym', 'he was exercise', 'he was workout', 'he was homework',
    'havells add', 'havells update', 'havells delete', 'havells complete', 'havells finish',
    'havells call', 'havells buy', 'havells visit', 'havells book', 'havells send', 'havells remove',
    'havells gym', 'havells exercise', 'havells workout', 'havells homework',
    'he was', 'he west', 'he wrist', 'he twist', 'he list',
    'havells by', 'heaviest by', 'heaves by',
    'hey west', 'hey wrist', 'hey twist', 'hey list',
    'whisp', 'whisper', 'hey',
    'havells', 'heaviest', 'heaves'
  ];

  static const List<String> _fallbackKeywords = [
    'add', 'create', 'new', 'make', 'schedule',
    'remove', 'delete', 'cancel', 'clear',
    'update', 'edit', 'change', 'modify',
    'complete', 'done', 'finish', 'finished',
    'gym', 'exercise', 'workout', 'fitness',
    'homework', 'study', 'assignment', 'project',
    'call', 'phone', 'contact',
    'buy', 'purchase', 'shopping', 'shop',
    'visit', 'go to', 'meet',
    'book', 'appointment', 'reservation'
  ];

  /// Create notification channel for Android
  @pragma('vm:entry-point')
  static Future<void> _createNotificationChannel() async {
    try {
      await _channel.invokeMethod('createNotificationChannel', {
        'channelId': _notificationChannelId,
        'channelName': 'WhispTask Voice Service',
        'channelDescription': 'Background voice recognition service for WhispTask',
        'importance': 2, // IMPORTANCE_LOW
      });
    } catch (e) {
      print('Error creating notification channel: $e');
      // Continue without channel creation - fallback to default
    }
  }

  /// Update notification with current status and listening indicator
  static void _updateNotification({String? listeningStatus, String? lastCommand}) {
    try {
      final service = FlutterBackgroundService();
      
      String title = 'WhispTask Voice Assistant';
      String content = 'Background voice detection active';
      
      if (listeningStatus != null) {
        switch (listeningStatus) {
          case 'listening':
            title = '🎤 WhispTask - Listening';
            content = 'Say "Hey Whisp" followed by your command';
            break;
          case 'processing':
            title = '⚡ WhispTask - Processing';
            content = lastCommand != null ? 'Processing: $lastCommand' : 'Processing voice command...';
            break;
          case 'waiting':
            title = '👂 WhispTask - Ready';
            content = 'Waiting for "Hey Whisp" wake word';
            break;
          case 'error':
            title = '❌ WhispTask - Error';
            content = 'Voice recognition error - Tap to retry';
            break;
        }
      }
      
      service.invoke('updateNotification', {
        'title': title,
        'content': content,
      });
      print('BackgroundVoiceService: Notification updated - $title: $content');
    } catch (e) {
      print('BackgroundVoiceService: Error updating notification: $e');
    }
  }

  // Update notification to show listening status
  static void updateListeningStatus(String status, {String? command}) {
    _updateNotification(listeningStatus: status, lastCommand: command);
  }

  /// Initialize the background service
  @pragma('vm:entry-point')
  static Future<void> initializeService() async {
    // Create notification channel first
    await _createNotificationChannel();
    
    // Add delay to ensure channel is registered
    await Future.delayed(const Duration(milliseconds: 500));
    
    final service = FlutterBackgroundService();
    
    // Configure the service
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true, // Re-enabled with proper notification channel
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'WhispTask Voice Assistant',
        initialNotificationContent: 'Listening for wake words...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false, // Changed to false
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Start the background service
  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (!isRunning) {
      service.startService();
    }
  }

  /// Stop the background service
  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  /// Check if background service is running
  static Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  /// Main entry point for the background service
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    
    print('Background Voice Service Started');
    
    // Set as foreground service with proper notification channel
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }
    
    // Enable speech recognition for continuous background listening
    print('Background Voice Service: Initializing speech recognition for continuous listening');
    
    bool serviceRunning = true;
    SpeechToText? speechToText;
    
    try {
      speechToText = SpeechToText();
      bool speechAvailable = await speechToText.initialize(
        onError: (error) => print('Background Speech Error: $error'),
        onStatus: (status) => print('Background Speech Status: $status'),
      );
      
      if (speechAvailable) {
        print('Background Voice Service: Speech recognition initialized successfully');
        _startContinuousListening(speechToText, service);
      } else {
        print('Background Voice Service: Speech recognition not available');
      }
    } catch (e) {
      print('Background Voice Service: Error initializing speech: $e');
    }

    // Periodic task to keep service alive and update notification
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (serviceRunning) {
        print('Background Voice Service: Still running (speech disabled)...');
        
        // Update notification with current time
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "WhispTask Voice Assistant",
            content: "Listening for 'Hey Whisp'... (${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')})",
          );
        }
      }
    });

    // Handle service commands
    service.on('stopService').listen((event) {
      serviceRunning = false;
      service.stopSelf();
    });

    // Update notification periodically
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: "WhispTask Voice Assistant",
            content: "Listening for 'Hey Whisp'... (${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')})",
          );
        }
      }
      
      if (!serviceRunning) {
        timer.cancel();
      }
    });
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    
    // iOS has limited background processing, so we'll do minimal wake word detection
    print('iOS Background Voice Service Running');
    return true;
  }

  /// Start continuous listening for wake words in background
  @pragma('vm:entry-point')
  static void _startContinuousListening(SpeechToText speechToText, ServiceInstance service) async {
    print('Background Voice Service: Starting continuous listening...');
    
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        if (!speechToText.isListening) {
          await speechToText.listen(
            onResult: (result) {
              if (result.recognizedWords.isNotEmpty) {
                print('Background Voice Recognition: ${result.recognizedWords}');
                _processVoiceResult(result.recognizedWords, service);
              }
            },
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 1),
            partialResults: true,
            cancelOnError: false,
            localeId: 'en_US',
          );
        }
      } catch (e) {
        print('Background listening error: $e');
        // Continue trying after error
      }
    });
  }

  /// Process voice recognition results
  @pragma('vm:entry-point')
  static void _processVoiceResult(String recognizedText, ServiceInstance service) {
    print('Background Voice Recognition: $recognizedText');
    
    bool wakeWordDetected = false;
    String detectedWakeWord = '';
    
    // Check for wake words
    for (String wakeWord in _wakeWords) {
      if (recognizedText.contains(wakeWord)) {
        wakeWordDetected = true;
        detectedWakeWord = wakeWord;
        break;
      }
    }
    
    // Fallback: Check for task-related keywords
    if (!wakeWordDetected) {
      for (String keyword in _fallbackKeywords) {
        if (recognizedText.contains(keyword)) {
          wakeWordDetected = true;
          detectedWakeWord = 'fallback: $keyword';
          break;
        }
      }
    }
    
    if (wakeWordDetected) {
      print('Wake word detected in background: $detectedWakeWord');
      
      // Send wake word detection to main app
      service.invoke('wakeWordDetected', {
        'command': recognizedText,
        'wakeWord': detectedWakeWord,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Auto-open the app and navigate to voice input screen
      _openAppWithVoiceScreen(recognizedText);
      
      // Update notification
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "WhispTask - Wake Word Detected!",
          content: "Processing: '$recognizedText'",
        );
      }
      
      // Store command for when app is opened
      _storeBackgroundCommand(recognizedText, detectedWakeWord);
    }
  }

  /// Open app and navigate to voice input screen
  @pragma('vm:entry-point')
  static Future<void> _openAppWithVoiceScreen(String command) async {
    try {
      // Use platform channel to open app with specific intent
      await _channel.invokeMethod('openAppWithVoiceScreen', {
        'command': command,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      print('Background Service: Requested app to open with voice screen');
    } catch (e) {
      print('Background Service: Error opening app: $e');
      // Fallback: just store the command for when app opens
    }
  }

  /// Store background command for later processing
  static Future<void> _storeBackgroundCommand(String command, String wakeWord) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commands = prefs.getStringList('background_commands') ?? [];
      
      final commandData = {
        'command': command,
        'wakeWord': wakeWord,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      commands.add(commandData.toString());
      await prefs.setStringList('background_commands', commands);
      
      print('Stored background command: $command');
    } catch (e) {
      print('Error storing background command: $e');
      Sentry.captureException(e);
    }
  }

  /// Get and clear stored background commands
  static Future<List<Map<String, dynamic>>> getStoredCommands() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commands = prefs.getStringList('background_commands') ?? [];
      
      // Clear stored commands
      await prefs.remove('background_commands');
      
      // Parse commands (simplified parsing for demo)
      List<Map<String, dynamic>> parsedCommands = [];
      for (String commandStr in commands) {
        // In a real implementation, you'd use proper JSON serialization
        parsedCommands.add({
          'command': commandStr.split('command: ')[1].split(',')[0],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
      
      return parsedCommands;
    } catch (e) {
      print('Error getting stored commands: $e');
      Sentry.captureException(e);
      return [];
    }
  }

  /// Check and request necessary permissions
  static Future<bool> checkPermissions() async {
    // Check microphone permission
    var microphoneStatus = await Permission.microphone.status;
    if (!microphoneStatus.isGranted) {
      microphoneStatus = await Permission.microphone.request();
    }

    // Check notification permission (Android 13+)
    var notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      notificationStatus = await Permission.notification.request();
    }

    return microphoneStatus.isGranted && notificationStatus.isGranted;
  }
}
