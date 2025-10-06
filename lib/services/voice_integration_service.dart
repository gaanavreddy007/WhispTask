// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';

class VoiceIntegrationService {
  static bool _isInitialized = false;
  
  /// Simplified voice command integration
  static Future<void> initializeVoiceIntegration(BuildContext context) async {
    print('VoiceIntegration: Starting initialization...');
    
    if (_isInitialized) {
      print('VoiceIntegration: Already initialized, skipping');
      return;
    }
    
    try {
      // Get providers
      final voiceProvider = Provider.of<VoiceProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      print('VoiceIntegration: Providers obtained');
      
      // Set up voice command callback
      voiceProvider.setVoiceCommandCallback((command) async {
        print('VoiceIntegration: Processing command: $command');
        try {
          await taskProvider.processVoiceTaskCommandEnhanced(command);
          print('VoiceIntegration: Command processed successfully');
        } catch (e) {
          print('VoiceIntegration: Error processing command: $e');
        }
      });
      
      // Initialize enhanced voice
      await voiceProvider.initializeEnhancedVoice(authProvider);
      
      _isInitialized = true;
      print('VoiceIntegration: Integration complete');
      
    } catch (e) {
      print('VoiceIntegration: Failed to initialize: $e');
    }
  }
  
  /// Check if voice integration is initialized
  static bool get isInitialized => _isInitialized;
  
  /// Reset initialization state (for testing)
  static void reset() {
    _isInitialized = false;
  }
}
