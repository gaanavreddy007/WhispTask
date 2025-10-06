// lib/widgets/auth_wrapper.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Providers
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';

// Screens
import '../screens/login_screen.dart';
import '../screens/task_list_screen.dart';
import '../screens/biometric_lock_screen.dart';

// Services
import '../services/voice_integration_service.dart';
import '../services/biometric_service.dart';

// Utils
import '../utils/final_app_validator.dart';
import '../utils/error_recovery_system.dart';

// Localization
import '../l10n/app_localizations.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  static const platform = MethodChannel('com.example.whisptask/main');
  bool _needsBiometricAuth = false;
  bool _biometricAuthCompleted = false;
  DateTime? _appPausedTime;
  static const Duration _biometricTimeout = Duration(seconds: 30); // Only require biometric after 30 seconds in background
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize auth immediately for instant startup
    Future.microtask(() async {
      if (!mounted) return;
      
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.initializeAuth();
        
        if (!mounted) return;
        
        // Check if biometric authentication is enabled and required
        await _checkBiometricRequirement(authProvider);
        
        // Add a small delay and check again to ensure user data is fully loaded
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          await _checkBiometricRequirement(authProvider);
        }
        
        // Mark that the app has been initialized (not a resume from background)
        _appPausedTime = null;
        
        // Wait a bit for providers to be ready, then initialize voice integration
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!mounted) return;
        
        await VoiceIntegrationService.initializeVoiceIntegration(context);
        
        if (!mounted) return;
        
        // Check for intent extras from background service
        await _checkForVoiceScreenIntent();
      } catch (e) {
        print('AuthWrapper: Error during initialization: $e');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('AuthWrapper: App lifecycle state changed to: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('AuthWrapper: App resumed from background');
        
        // Only require biometric auth if app was in background for sufficient time
        if (_appPausedTime != null) {
          final timeInBackground = DateTime.now().difference(_appPausedTime!);
          print('AuthWrapper: App was in background for: ${timeInBackground.inSeconds} seconds');
          
          if (timeInBackground >= _biometricTimeout) {
            print('AuthWrapper: Background time exceeded threshold - checking biometric requirement');
            _resetBiometricAuth();
          } else {
            print('AuthWrapper: Background time too short - not requiring biometric auth');
          }
          
          _appPausedTime = null; // Reset the pause time
        }
        break;
        
      case AppLifecycleState.paused:
        print('AuthWrapper: App paused - recording pause time');
        _appPausedTime = DateTime.now();
        break;
        
      case AppLifecycleState.inactive:
        print('AuthWrapper: App inactive - not recording pause time (temporary state)');
        // Don't record pause time for inactive state as it's often temporary
        break;
        
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        print('AuthWrapper: App detached/hidden');
        break;
    }
  }

  // Check if biometric authentication is required
  Future<void> _checkBiometricRequirement(AuthProvider authProvider) async {
    try {
      if (authProvider.isLoggedIn && authProvider.user != null) {
        final user = authProvider.user!;
        
        // Check both user privacy settings and user preferences
        bool biometricEnabled = false;
        
        // First check user privacy settings
        if (user.privacySettings != null) {
          biometricEnabled = user.privacySettings!.biometricAuth;
          print('AuthWrapper: Biometric setting from privacy settings: $biometricEnabled');
        } else {
          print('AuthWrapper: Privacy settings are null, checking user preferences...');
          
          // Fallback to user preferences if privacy settings are null
          final userPreferences = authProvider.userPreferences;
          if (userPreferences != null) {
            biometricEnabled = userPreferences.biometricAuth;
            print('AuthWrapper: Biometric setting from user preferences: $biometricEnabled');
          } else {
            print('AuthWrapper: Both privacy settings and user preferences are null - biometric disabled');
          }
        }
        
        if (biometricEnabled) {
          print('AuthWrapper: Biometric auth is enabled for user');
          final isAvailable = await BiometricService.isBiometricAvailable();
          print('AuthWrapper: Biometric available: $isAvailable');
          if (isAvailable) {
            setState(() {
              _needsBiometricAuth = true;
              _biometricAuthCompleted = false;
            });
            print('AuthWrapper: Set _needsBiometricAuth = true');
          }
        } else {
          print('AuthWrapper: Biometric auth is disabled for user');
        }
      }
    } catch (e) {
      print('AuthWrapper: Error checking biometric requirement: $e');
    }
  }

  // Handle successful biometric authentication
  void _onBiometricAuthenticated() {
    setState(() {
      _biometricAuthCompleted = true;
      _needsBiometricAuth = false;
    });
  }

  // Reset biometric authentication when app resumes from background
  void _resetBiometricAuth() {
    print('AuthWrapper: _resetBiometricAuth called');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn && authProvider.user != null) {
      final user = authProvider.user!;
      
      // Check both user privacy settings and user preferences
      bool biometricEnabled = false;
      
      // First check user privacy settings
      if (user.privacySettings != null) {
        biometricEnabled = user.privacySettings!.biometricAuth;
        print('AuthWrapper: Biometric setting from privacy settings: $biometricEnabled');
      } else {
        print('AuthWrapper: Privacy settings are null, checking user preferences...');
        
        // Fallback to user preferences if privacy settings are null
        final userPreferences = authProvider.userPreferences;
        if (userPreferences != null) {
          biometricEnabled = userPreferences.biometricAuth;
          print('AuthWrapper: Biometric setting from user preferences: $biometricEnabled');
        } else {
          print('AuthWrapper: Both privacy settings and user preferences are null - biometric disabled');
        }
      }
      
      print('AuthWrapper: User logged in: ${authProvider.isLoggedIn}');
      print('AuthWrapper: User ID: ${user.uid}');
      print('AuthWrapper: Privacy settings: ${user.privacySettings}');
      print('AuthWrapper: User preferences: ${authProvider.userPreferences}');
      print('AuthWrapper: Final biometric enabled: $biometricEnabled');
      
      if (biometricEnabled) {
        setState(() {
          _needsBiometricAuth = true;
          _biometricAuthCompleted = false;
        });
        print('AuthWrapper: Set _needsBiometricAuth = true, _biometricAuthCompleted = false');
      } else {
        print('AuthWrapper: Biometric auth is disabled, not requiring authentication');
      }
    } else {
      print('AuthWrapper: User not logged in or user is null');
    }
  }

  // Check if app was opened with voice screen intent from background service
  Future<void> _checkForVoiceScreenIntent() async {
    try {
      final result = await platform.invokeMethod('getIntentExtras');
      if (result != null && result is Map) {
        final openVoiceScreen = result['openVoiceScreen'] as bool?;
        final voiceCommand = result['voiceCommand'] as String?;
        
        if (openVoiceScreen == true) {
          print('AuthWrapper: App opened with voice screen intent, command: "$voiceCommand"');
          
          // Wait for auth to complete, then navigate to voice screen
          await Future.delayed(const Duration(milliseconds: 1000));
          
          if (!mounted) return;
          
          try {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            if (authProvider.isLoggedIn) {
              // Navigate to voice input screen
              Navigator.of(context).pushNamed('/voice-input');
              
              // If there's a voice command, process it automatically
              if (voiceCommand != null && voiceCommand.isNotEmpty) {
                if (!mounted) return;
                
                final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                await Future.delayed(const Duration(milliseconds: 500));
                
                if (!mounted) return;
                
                await taskProvider.processVoiceTaskCommandEnhanced(voiceCommand);
              }
            }
          } catch (e) {
            print('AuthWrapper: Error processing voice intent: $e');
          }
        }
      }
    } catch (e) {
      print('AuthWrapper: Error checking intent extras: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String loadingText;
    try {
      loadingText = AppLocalizations.of(context).loading;
    } catch (e) {
      loadingText = 'Loading...';
    }
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while initializing
        if (!authProvider.isInitialized) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(loadingText),
                ],
              ),
            ),
          );
        }

        // Show appropriate screen based on auth state
        if (authProvider.isLoggedIn && authProvider.user != null) {
          print('AuthWrapper: User logged in. _needsBiometricAuth: $_needsBiometricAuth, _biometricAuthCompleted: $_biometricAuthCompleted');
          // Check if biometric authentication is required
          if (_needsBiometricAuth && !_biometricAuthCompleted) {
            print('AuthWrapper: Showing BiometricLockScreen');
            return BiometricLockScreen(
              onAuthenticated: _onBiometricAuthenticated,
            );
          }
          print('AuthWrapper: Showing TaskListScreen');
          return const TaskListScreen();
        } else {
          print('AuthWrapper: User not logged in, showing LoginScreen');
          return const LoginScreen();
        }
      },
    );
  }
}