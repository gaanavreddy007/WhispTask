// ignore_for_file: avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/sentry_service.dart';
import '../l10n/app_localizations.dart';

/// Comprehensive app startup validator to prevent runtime errors
class AppStartupValidator {
  static const String _tag = 'AppStartupValidator';
  
  /// Validate all critical app components before startup
  static Future<bool> validateAppStartup(BuildContext? context) async {
    try {
      SentryService.logUIEvent('app_startup_validation_start');
      
      // 1. Validate Firebase initialization
      if (!await _validateFirebase()) {
        SentryService.logUIEvent('app_startup_validation_failed', data: {
          'reason': 'firebase_not_initialized',
        });
        return false;
      }
      
      // 2. Validate localization if context is available
      if (context != null && !await _validateLocalization(context)) {
        SentryService.logUIEvent('app_startup_validation_failed', data: {
          'reason': 'localization_failed',
        });
        return false;
      }
      
      // 3. Validate Sentry service
      if (!await _validateSentryService()) {
        print('$_tag: Sentry validation failed, but continuing...');
        // Don't fail startup for Sentry issues
      }
      
      SentryService.logUIEvent('app_startup_validation_complete');
      return true;
      
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Critical error during app startup validation',
        extra: {'validator': 'AppStartupValidator'},
      );
      
      print('$_tag: Startup validation failed: $e');
      return false;
    }
  }
  
  /// Validate Firebase initialization
  static Future<bool> _validateFirebase() async {
    try {
      // Check if Firebase is already initialized
      final apps = Firebase.apps;
      if (apps.isNotEmpty) {
        SentryService.logUIEvent('firebase_validation_success', data: {
          'apps_count': apps.length.toString(),
        });
        return true;
      }
      
      SentryService.logUIEvent('firebase_validation_failed', data: {
        'reason': 'no_firebase_apps',
      });
      return false;
      
    } catch (e) {
      SentryService.logUIEvent('firebase_validation_error', data: {
        'error': e.toString(),
      });
      return false;
    }
  }
  
  /// Validate localization system
  static Future<bool> _validateLocalization(BuildContext context) async {
    try {
      // Attempt to get localization
      final localizations = AppLocalizations.of(context);
      
      // Test basic localization strings
      final testStrings = [
        localizations.loading,
        localizations.cancel,
      ];
      
      for (final testString in testStrings) {
        if (testString.isEmpty) {
          SentryService.logUIEvent('localization_validation_failed', data: {
            'reason': 'empty_localization_string',
          });
          return false;
        }
      }
      
      SentryService.logUIEvent('localization_validation_success');
      return true;
      
    } catch (e) {
      SentryService.logUIEvent('localization_validation_error', data: {
        'error': e.toString(),
      });
      return false;
    }
  }
  
  /// Validate Sentry service functionality
  static Future<bool> _validateSentryService() async {
    try {
      // Test basic Sentry functionality
      SentryService.logUIEvent('sentry_validation_test');
      
      // Test error capture (only in debug mode to avoid confusion)
      if (kDebugMode) {
        try {
          print('$_tag: Running Sentry validation test (debug mode only)...');
          throw Exception('Test exception for Sentry validation - This is intentional for testing error tracking');
        } catch (e, stackTrace) {
          await SentryService.captureException(
            e,
            stackTrace: stackTrace,
            hint: 'Sentry validation test exception - intentional test for error tracking system',
            extra: {
              'test': 'validation',
              'intentional': true,
              'debug_mode': true,
            },
          );
          print('$_tag: Sentry validation test completed successfully');
        }
      } else {
        print('$_tag: Sentry validation (production mode - skipping test exception)');
      }
      
      return true;
      
    } catch (e) {
      print('$_tag: Sentry validation failed: $e');
      return false;
    }
  }
  
  /// Safe app initialization with validation
  static Future<Widget> safeAppInitialization({
    required Widget Function() appBuilder,
    Widget? fallbackWidget,
  }) async {
    try {
      // Validate startup without context first
      final isValid = await validateAppStartup(null);
      
      if (!isValid) {
        SentryService.logUIEvent('app_initialization_failed_validation');
        return fallbackWidget ?? _buildFallbackApp();
      }
      
      // Build the main app
      final app = appBuilder();
      SentryService.logUIEvent('app_initialization_success');
      return app;
      
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Critical error during safe app initialization',
        extra: {'initializer': 'AppStartupValidator'},
      );
      
      return fallbackWidget ?? _buildFallbackApp();
    }
  }
  
  /// Build a minimal fallback app for critical failures
  static Widget _buildFallbackApp() {
    return MaterialApp(
      title: 'WhispTask',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const _FallbackScreen(),
    );
  }
}

/// Fallback screen for critical app failures
class _FallbackScreen extends StatelessWidget {
  const _FallbackScreen();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.task_alt,
                  size: 60,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'WhispTask',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Initializing app...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Attempt to restart the app
                  SentryService.logUIEvent('fallback_restart_attempted');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
