// ignore_for_file: avoid_print, await_only_futures, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sentry_service.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/voice_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';

/// Comprehensive error recovery system for runtime issues
class ErrorRecoverySystem {
  static const String _tag = 'ErrorRecoverySystem';
  
  /// Recover from provider-related errors
  static Future<bool> recoverProviderError(
    BuildContext context,
    String providerName,
    dynamic error,
  ) async {
    try {
      SentryService.logUIEvent('provider_error_recovery_start', data: {
        'provider': providerName,
        'error': error.toString(),
      });
      
      switch (providerName.toLowerCase()) {
        case 'authprovider':
          return await _recoverAuthProvider(context);
        case 'taskprovider':
          return await _recoverTaskProvider(context);
        case 'voiceprovider':
          return await _recoverVoiceProvider(context);
        case 'themeprovider':
          return await _recoverThemeProvider(context);
        case 'languageprovider':
          return await _recoverLanguageProvider(context);
        default:
          return await _genericProviderRecovery(context, providerName);
      }
      
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error during provider recovery',
        extra: {
          'original_provider': providerName,
          'original_error': error.toString(),
        },
      );
      return false;
    }
  }
  
  /// Recover AuthProvider errors
  static Future<bool> _recoverAuthProvider(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Clear error state
      authProvider.clearError();
      
      SentryService.logUIEvent('auth_provider_recovery_success');
      return true;
      
    } catch (e) {
      SentryService.logUIEvent('auth_provider_recovery_failed', data: {
        'error': e.toString(),
      });
      return false;
    }
  }
  
  /// Recover TaskProvider errors
  static Future<bool> _recoverTaskProvider(BuildContext context) async {
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      // Clear error state and refresh tasks
      taskProvider.clearError();
      await taskProvider.refreshTasks();
      
      SentryService.logUIEvent('task_provider_recovery_success');
      return true;
      
    } catch (e) {
      SentryService.logUIEvent('task_provider_recovery_failed', data: {
        'error': e.toString(),
      });
      return false;
    }
  }
  
  /// Recover VoiceProvider errors
  static Future<bool> _recoverVoiceProvider(BuildContext context) async {
    try {
      final voiceProvider = Provider.of<VoiceProvider>(context, listen: false);
      
      // Stop any ongoing voice operations
      voiceProvider.stopListening();
      
      // Re-initialize voice service
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await voiceProvider.initializeEnhancedVoice(authProvider);
      
      SentryService.logUIEvent('voice_provider_recovery_success');
      return true;
      
    } catch (e) {
      SentryService.logUIEvent('voice_provider_recovery_failed', data: {
        'error': e.toString(),
      });
      return false;
    }
  }
  
  /// Recover ThemeProvider errors
  static Future<bool> _recoverThemeProvider(BuildContext context) async {
    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      
      // Reset to system theme
      await themeProvider.setThemeMode(ThemeMode.system);
      
      SentryService.logUIEvent('theme_provider_recovery_success');
      return true;
      
    } catch (e) {
      SentryService.logUIEvent('theme_provider_recovery_failed', data: {
        'error': e.toString(),
      });
      return false;
    }
  }
  
  /// Recover LanguageProvider errors
  static Future<bool> _recoverLanguageProvider(BuildContext context) async {
    try {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      
      // Reset to English
      await languageProvider.changeLanguage('en');
      
      SentryService.logUIEvent('language_provider_recovery_success');
      return true;
      
    } catch (e) {
      SentryService.logUIEvent('language_provider_recovery_failed', data: {
        'error': e.toString(),
      });
      return false;
    }
  }
  
  /// Generic provider recovery
  static Future<bool> _genericProviderRecovery(
    BuildContext context,
    String providerName,
  ) async {
    try {
      SentryService.logUIEvent('generic_provider_recovery_attempted', data: {
        'provider': providerName,
      });
      
      // For unknown providers, just log and continue
      print('$_tag: Generic recovery for $providerName');
      return true;
      
    } catch (e) {
      SentryService.logUIEvent('generic_provider_recovery_failed', data: {
        'provider': providerName,
        'error': e.toString(),
      });
      return false;
    }
  }
  
  /// Recover from navigation errors
  static Future<bool> recoverNavigationError(
    BuildContext context,
    String route,
    dynamic error,
  ) async {
    try {
      SentryService.logUIEvent('navigation_error_recovery_start', data: {
        'route': route,
        'error': error.toString(),
      });
      
      // Navigate to safe route
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/auth-wrapper',
        (route) => false,
      );
      
      SentryService.logUIEvent('navigation_error_recovery_success');
      return true;
      
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error during navigation recovery',
        extra: {
          'original_route': route,
          'original_error': error.toString(),
        },
      );
      return false;
    }
  }
  
  /// Recover from localization errors
  static Future<bool> recoverLocalizationError(
    BuildContext context,
    dynamic error,
  ) async {
    try {
      SentryService.logUIEvent('localization_error_recovery_start', data: {
        'error': error.toString(),
      });
      
      // Reset to English locale
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      await languageProvider.changeLanguage('en');
      
      SentryService.logUIEvent('localization_error_recovery_success');
      return true;
      
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error during localization recovery',
        extra: {'original_error': error.toString()},
      );
      return false;
    }
  }
  
  /// Show user-friendly error dialog with recovery options
  static void showErrorRecoveryDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onRestart,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.orange[700],
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'The app encountered an issue but is working to recover automatically.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          if (onRestart != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRestart();
              },
              child: const Text('Restart'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              SentryService.logUIEvent('error_dialog_dismissed');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
  
  /// Comprehensive app health check
  static Future<Map<String, bool>> performHealthCheck(BuildContext context) async {
    final results = <String, bool>{};
    
    try {
      SentryService.logUIEvent('app_health_check_start');
      
      // Check providers
      results['auth_provider'] = await _checkProviderHealth<AuthProvider>(context);
      results['task_provider'] = await _checkProviderHealth<TaskProvider>(context);
      results['voice_provider'] = await _checkProviderHealth<VoiceProvider>(context);
      results['theme_provider'] = await _checkProviderHealth<ThemeProvider>(context);
      results['language_provider'] = await _checkProviderHealth<LanguageProvider>(context);
      
      // Check navigation
      results['navigation'] = true; // Navigator is always available
      
      // Check localization
      results['localization'] = await _checkLocalizationHealth(context);
      
      SentryService.logUIEvent('app_health_check_complete', data: {
        'results': results.toString(),
      });
      
      return results;
      
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error during app health check',
      );
      
      return {'health_check': false};
    }
  }
  
  /// Check individual provider health
  static Future<bool> _checkProviderHealth<T extends ChangeNotifier>(
    BuildContext context,
  ) async {
    try {
      Provider.of<T>(context, listen: false);
      return true; // Provider is available if no exception thrown
    } catch (e) {
      return false;
    }
  }
  
  /// Check localization health
  static Future<bool> _checkLocalizationHealth(BuildContext context) async {
    try {
      Localizations.localeOf(context);
      return true; // Localizations available if no exception thrown
    } catch (e) {
      return false;
    }
  }
}
