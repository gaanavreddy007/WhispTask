// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sentry_service.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/voice_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import 'leak_prevention_system.dart';
import 'error_recovery_system.dart';
import 'app_startup_validator.dart';
import 'final_app_validator.dart';

/// Ultimate bulletproof app system - ZERO TOLERANCE FOR ERRORS
class BulletproofAppSystem {
  static const String _tag = 'BulletproofAppSystem';
  static bool _isInitialized = false;
  static Timer? _healthCheckTimer;
  
  /// Initialize the bulletproof system
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) {
        return true;
      }
      
      SentryService.logUIEvent('bulletproof_system_initialization_start');
      
      // Start continuous health monitoring
      _startHealthMonitoring();
      
      _isInitialized = true;
      SentryService.logUIEvent('bulletproof_system_initialization_complete');
      
      return true;
      
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Critical error during bulletproof system initialization',
      );
      return false;
    }
  }
  
  /// Start continuous health monitoring
  static void _startHealthMonitoring() {
    try {
      // Cancel existing timer if any
      _healthCheckTimer?.cancel();
      
      // Start periodic health checks every 30 seconds
      _healthCheckTimer = Timer.periodic(
        const Duration(seconds: 30),
        (timer) async {
          await _performPeriodicHealthCheck();
        },
      );
      
      LeakPreventionSystem.registerTimer('health_check_timer', _healthCheckTimer!);
      
    } catch (e) {
      print('$_tag: Error starting health monitoring: $e');
    }
  }
  
  /// Perform periodic health check
  static Future<void> _performPeriodicHealthCheck() async {
    try {
      // Check for resource leaks
      final leakResults = await LeakPreventionSystem.performLeakCheck();
      
      // Log health status
      SentryService.logUIEvent('periodic_health_check', data: {
        'leak_results': leakResults.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Check for potential issues
      final warnings = leakResults['warnings'] as List<String>? ?? [];
      if (warnings.isNotEmpty) {
        SentryService.logUIEvent('health_check_warnings', data: {
          'warnings': warnings.join(', '),
        });
      }
      
    } catch (e) {
      print('$_tag: Error during periodic health check: $e');
    }
  }
  
  /// Comprehensive app validation with zero tolerance
  static Future<bool> performComprehensiveValidation(BuildContext context) async {
    try {
      SentryService.logUIEvent('comprehensive_validation_start');
      
      // Check if context is still mounted before async operations
      if (!context.mounted) {
        SentryService.logUIEvent('comprehensive_validation_failed', data: {
          'stage': 'context_not_mounted',
        });
        return false;
      }
      
      // 1. Startup validation
      final startupValid = await AppStartupValidator.validateAppStartup(context);
      if (!startupValid) {
        SentryService.logUIEvent('comprehensive_validation_failed', data: {
          'stage': 'startup_validation',
        });
        return false;
      }
      
      // Check context again after async operation
      if (!context.mounted) return false;
      
      // 2. Final app validation
      final appValid = await FinalAppValidator.performFinalValidation(context);
      if (!appValid) {
        SentryService.logUIEvent('comprehensive_validation_failed', data: {
          'stage': 'final_app_validation',
        });
        return false;
      }
      
      // Check context again after async operation
      if (!context.mounted) return false;
      
      // 3. Health check
      final healthResults = await ErrorRecoverySystem.performHealthCheck(context);
      final allHealthy = healthResults.values.every((isHealthy) => isHealthy);
      if (!allHealthy) {
        SentryService.logUIEvent('comprehensive_validation_warning', data: {
          'stage': 'health_check',
          'results': healthResults.toString(),
        });
        // Don't fail for health check issues, just log them
      }
      
      // 4. Leak check
      final leakResults = await LeakPreventionSystem.performLeakCheck();
      final warnings = leakResults['warnings'] as List<String>? ?? [];
      if (warnings.isNotEmpty) {
        SentryService.logUIEvent('comprehensive_validation_leak_warnings', data: {
          'warnings': warnings.join(', '),
        });
      }
      
      SentryService.logUIEvent('comprehensive_validation_complete');
      return true;
      
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error during comprehensive validation',
      );
      return false;
    }
  }
  
  /// Safe widget wrapper with bulletproof protection
  static Widget bulletproofWidget({
    required Widget child,
    required String widgetName,
    Widget? fallback,
  }) {
    return Builder(
      builder: (context) {
        try {
          // Register widget for tracking
          LeakPreventionSystem.registerResource(widgetName, 'widget');
          
          return child;
          
        } catch (e, stackTrace) {
          SentryService.captureException(
            e,
            stackTrace: stackTrace,
            hint: 'Bulletproof widget error',
            extra: {'widget_name': widgetName},
          );
          
          return fallback ?? _buildBulletproofErrorWidget(widgetName);
        }
      },
    );
  }
  
  /// Safe provider wrapper
  static Widget bulletproofProvider<T extends ChangeNotifier>({
    required T Function() create,
    required Widget child,
    required String providerName,
    bool lazy = false,
  }) {
    return ChangeNotifierProvider<T>(
      create: (context) {
        try {
          final provider = create();
          LeakPreventionSystem.registerResource(providerName, 'provider');
          
          SentryService.logUIEvent('provider_created', data: {
            'provider': providerName,
            'lazy': lazy.toString(),
          });
          
          return provider;
          
        } catch (e, stackTrace) {
          SentryService.captureException(
            e,
            stackTrace: stackTrace,
            hint: 'Provider creation error',
            extra: {'provider_name': providerName},
          );
          rethrow;
        }
      },
      lazy: lazy,
      child: child,
    );
  }
  
  /// Safe async operation with bulletproof protection
  static Future<T?> bulletproofAsyncOperation<T>({
    required Future<T> Function() operation,
    required String operationName,
    T? fallback,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final operationId = '${operationName}_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      LeakPreventionSystem.registerResource(operationId, 'async_operation');
      
      final result = await operation().timeout(
        timeout,
        onTimeout: () {
          SentryService.logUIEvent('async_operation_timeout', data: {
            'operation': operationName,
            'timeout_seconds': timeout.inSeconds.toString(),
          });
          throw TimeoutException('Operation timed out: $operationName', timeout);
        },
      );
      
      LeakPreventionSystem.unregisterResource(operationId, 'async_operation');
      
      SentryService.logUIEvent('async_operation_success', data: {
        'operation': operationName,
      });
      
      return result;
      
    } catch (e, stackTrace) {
      LeakPreventionSystem.unregisterResource(operationId, 'async_operation');
      
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Bulletproof async operation failed',
        extra: {'operation': operationName},
      );
      
      return fallback;
    }
  }
  
  /// Emergency system shutdown and cleanup
  static Future<void> emergencyShutdown() async {
    try {
      SentryService.logUIEvent('emergency_shutdown_start');
      
      // Cancel health monitoring
      _healthCheckTimer?.cancel();
      LeakPreventionSystem.cancelTimer('health_check_timer');
      
      // Perform emergency cleanup
      await LeakPreventionSystem.emergencyCleanup();
      
      _isInitialized = false;
      
      SentryService.logUIEvent('emergency_shutdown_complete');
      
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error during emergency shutdown',
      );
    }
  }
  
  /// Build bulletproof error widget
  static Widget _buildBulletproofErrorWidget(String widgetName) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield,
            color: Colors.blue[700],
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            'Protected Widget',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Bulletproof system active',
            style: TextStyle(
              color: Colors.blue[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get system status
  static Map<String, dynamic> getSystemStatus() {
    return {
      'initialized': _isInitialized,
      'health_monitoring_active': _healthCheckTimer?.isActive ?? false,
      'resource_stats': LeakPreventionSystem.getResourceStats(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Validate all critical app components
  static Future<bool> validateCriticalComponents(BuildContext context) async {
    try {
      SentryService.logUIEvent('critical_components_validation_start');
      
      final results = <String, bool>{};
      
      // Check AuthProvider
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        results['auth_provider'] = authProvider.isInitialized;
      } catch (e) {
        results['auth_provider'] = false;
      }
      
      // Check ThemeProvider
      try {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        results['theme_provider'] = themeProvider.isInitialized;
      } catch (e) {
        results['theme_provider'] = false;
      }
      
      // Check LanguageProvider
      try {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        results['language_provider'] = languageProvider.isInitialized;
      } catch (e) {
        results['language_provider'] = false;
      }
      
      // Check navigation
      try {
        Navigator.of(context);
        results['navigation'] = true;
      } catch (e) {
        results['navigation'] = false;
      }
      
      // Check theme
      try {
        Theme.of(context);
        results['theme'] = true;
      } catch (e) {
        results['theme'] = false;
      }
      
      // Check localization
      try {
        Localizations.localeOf(context);
        results['localization'] = true;
      } catch (e) {
        results['localization'] = false;
      }
      
      final allValid = results.values.every((isValid) => isValid);
      
      SentryService.logUIEvent('critical_components_validation_complete', data: {
        'results': results.toString(),
        'all_valid': allValid.toString(),
      });
      
      return allValid;
      
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error validating critical components',
      );
      return false;
    }
  }
}
